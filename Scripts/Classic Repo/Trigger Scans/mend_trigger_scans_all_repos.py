#!/usr/bin/env python3
"""
Combined Mend Script to pull repo tags, deduplicate, and process repositories

This script:
1. Pulls all repoFullName and remoteUrl values from the tags of Mend Projects
2. Removes duplicate repository URLs
3. Loops through all unique repositories for further processing

For more information on the APIs used, please check our REST API documentation page:
https://docs.mend.io/bundle/mend-api-2-0/page/index.html

Prerequisites:
pip install requests
MEND_USER_KEY - An administrator's userkey
MEND_EMAIL - The administrator's email
WS_APIKEY - API Key for organization (optional)
MEND_URL - e.g. https://saas.mend.io
MEND_ONLY_UPDATED_REPOS - true/false (optional)
SCM - Source control prefix such as https://github.com
AZURE_ORG - Azure DevOps organization name (required if SCM contains 'azure')
SCAN_TYPE - Type of scan to perform: SCA or SAST
"""

import os
import re
import sys
import json
import time
import atexit
import shutil
import stat
import tempfile
import subprocess
from datetime import datetime, timedelta
from collections import defaultdict

# Global variable to track the temporary directory for cleanup
_temp_dir = None


def remove_readonly(func, path, excinfo):
    """Error handler for shutil.rmtree to handle read-only files on Windows."""
    # Clear the read-only flag and retry
    os.chmod(path, stat.S_IWRITE)
    func(path)


def cleanup_temp_dir():
    """Clean up the temporary directory on exit."""
    global _temp_dir
    if _temp_dir and os.path.isdir(_temp_dir):
        print(f"\nCleaning up temporary directory: {_temp_dir}")
        try:
            shutil.rmtree(_temp_dir, onerror=remove_readonly)
            print("  ✓ Cleanup complete")
        except Exception as e:
            print(f"  ✗ Failed to clean up temporary directory: {e}")

try:
    import requests
except ImportError:
    print("Please install requests: pip install requests")
    sys.exit(1)


def get_env_var(name: str, required: bool = True) -> str | None:
    """Get environment variable, exit if required and not set."""
    value = os.environ.get(name)
    if required and not value:
        print(f"Please export the {name} environment variable")
        sys.exit(1)
    return value


def reformat_mend_url(mend_url: str) -> str:
    """Reformat MEND_URL for the API to https://api-<env>/api/v2.0"""
    return re.sub(r'(saas|app)(.*)', r'api-\1\2/api/v2.0', mend_url)


def login_to_api(api_url: str, email: str, user_key: str, api_key: str | None) -> tuple[str, str]:
    """Log into API 2.0 and get the JWT Token and Organization UUID."""
    login_body = {
        "email": email,
        "userKey": user_key
    }
    
    if api_key:
        print("\nLogging in with provided API key.\n")
        login_body["orgToken"] = api_key
    else:
        print("\nWS_APIKEY environment variable was not provided.")
        print("The Login API will default to the last organization this user accessed in the Mend UI.\n")
    
    response = requests.post(
        f"{api_url}/login",
        headers={"Content-Type": "application/json"},
        json=login_body
    )
    response.raise_for_status()
    
    result = response.json()
    jwt_token = result["retVal"]["jwtToken"]
    org_uuid = result["retVal"]["orgUuid"]
    
    return jwt_token, org_uuid


def get_all_entities(api_url: str, org_uuid: str, jwt_token: str) -> list:
    """Get all project entities with pagination."""
    print("Retrieving Projects from Organization")
    
    all_entities = []
    page_counter = 0
    is_last_page = False
    
    while not is_last_page:
        response = requests.get(
            f"{api_url}/orgs/{org_uuid}/entities",
            params={"pageSize": 10000, "page": page_counter},
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {jwt_token}"
            }
        )
        response.raise_for_status()
        
        result = response.json()
        entities = result.get("retVal", [])
        all_entities.extend(entities)
        
        is_last_page = result.get("additionalData", {}).get("isLastPage", True)
        page_counter += 1
    
    return all_entities


def filter_project_entities(entities: list, only_updated: bool) -> list:
    """Filter entities to get projects, optionally filtering by last scan date."""
    project_entities = [
        entity["project"] for entity in entities 
        if "project" in entity
    ]
    
    if only_updated:
        print("Filtering Projects that have not been scanned in 90 days")
        cutoff_date = datetime.now() - timedelta(days=91)
        
        no_scan_date = []
        filtered_projects = []
        
        for project in project_entities:
            if "lastScanned" not in project:
                no_scan_date.append(project)
            else:
                try:
                    last_scanned = datetime.fromisoformat(
                        project["lastScanned"].replace("Z", "+00:00")
                    )
                    if last_scanned.replace(tzinfo=None) > cutoff_date:
                        filtered_projects.append(project)
                except (ValueError, TypeError):
                    filtered_projects.append(project)
        
        if no_scan_date:
            print("\n\nProjects with no Last Scan Date")
            print("-----------------")
            no_date_names = [p.get("name", "Unknown") for p in no_scan_date]
            for name in no_date_names:
                print(name)
            
            # Optional - save to text file
            with open("no_scan_date.txt", "w") as f:
                f.write("\n".join(no_date_names))
        
        return filtered_projects
    
    return project_entities


def extract_tags(project_entities: list) -> tuple[list, list]:
    """Extract repoFullName and remoteUrl tags from projects."""
    repo_fullnames = []
    remote_urls = []
    
    print("\n\nGetting Tags")
    print("-----------------")
    
    num_entities = len(project_entities)
    
    for i, project in enumerate(project_entities):
        project_name = project.get("name", "Unknown")
        print(f"Getting TAGS for PROJECT {i + 1}/{num_entities}: {project_name}")
        
        tags = project.get("tags", [])
        
        for tag in tags:
            key = tag.get("key", "")
            value = tag.get("value", "")
            
            if key.startswith("repoFullName") and value:
                repo_fullnames.append(value)
            elif key.startswith("remoteUrl") and value:
                remote_urls.append(value)
    
    return repo_fullnames, remote_urls


def process_and_deduplicate_repos(repo_fullnames: list, remote_urls: list, scm: str) -> list:
    """Process and deduplicate repository URLs."""
    print("\n\nAll repoFullName Repositories")
    print("-----------------")
    for repo in repo_fullnames:
        print(repo)
    
    print("\n\nAll remoteUrl Repositories")
    print("-----------------")
    for repo in remote_urls:
        print(repo)
    
    all_repos = repo_fullnames + remote_urls
    
    print("\n\nProcessing and deduplicating repositories")
    print("-----------------")
    
    processed_urls = []
    
    for repo in all_repos:
        if repo:
            # Remove @branchname from repoFullName results and replace with .git
            url = re.sub(r'@.*', '.git', repo)
            
            # Add SCM prefix if not already an https URL
            if not url.startswith("https://"):
                url = f"{scm}/{url}"
            
            # Handle Azure DevOps URL format
            # Azure URLs need to be in format: {SCM}/{org}/_git/{repo}
            if "azure" in scm.lower():
                # Remove SCM prefix to get repo path
                repo_path = url.replace(scm.rstrip('/') + '/', '', 1)
                slash_count = repo_path.count('/')
                if slash_count == 1:
                    org_name, repo_name = repo_path.split('/', 1)
                    url = f"{scm.rstrip('/')}/{org_name}/_git/{repo_name}"
            
            processed_urls.append(url)
    
    # Remove duplicates while preserving order
    seen = set()
    unique_repos = []
    for url in processed_urls:
        if url not in seen:
            seen.add(url)
            unique_repos.append(url)
    
    # Sort by organization name (4th field when split by '/')
    unique_repos.sort(key=lambda x: x.split('/')[3] if len(x.split('/')) > 3 else "")
    
    print(f"\n\nDeduplicated Repositories ({len(unique_repos)} total)")
    print("-----------------")
    for repo in unique_repos:
        print(repo)
    
    return unique_repos


def extract_organizations(unique_repos: list) -> tuple[list, dict]:
    """Extract unique organizations from repository URLs."""
    print("\n\nExtracting organizations")
    print("-----------------")
    
    org_repos = defaultdict(list)
    
    for repo_url in unique_repos:
        if repo_url:
            parts = repo_url.split('/')
            if len(parts) > 3:
                org_name = parts[3]
                org_repos[org_name].append(repo_url)
    
    organizations = sorted(org_repos.keys())
    
    print(f"Found {len(organizations)} organizations:")
    for org in organizations:
        print(org)
    
    return organizations, dict(org_repos)


def run_git_command(args: list, cwd: str = None) -> tuple[bool, str]:
    """Run a git command and return success status and output."""
    try:
        result = subprocess.run(
            ["git"] + args,
            cwd=cwd,
            capture_output=True,
            text=True
        )
        return result.returncode == 0, result.stdout + result.stderr
    except Exception as e:
        return False, str(e)


def clone_or_fetch_repo(scm: str, org: str, temp_dir: str, azure_org: str | None = None) -> str | None:
    """Clone or update the whitesource-config repository.
    
    Returns the path to the cloned directory on success, None on failure.
    """
    # Handle Azure DevOps URL format
    if "azure" in scm.lower() and azure_org:
        ws_config_repo = f"{scm.rstrip('/')}/{azure_org}/_git/whitesource-config"
        ws_config_dir = os.path.join(temp_dir, f"whitesource-config-{azure_org}")
    else:
        ws_config_repo = f"{scm}/{org}/whitesource-config.git"
        ws_config_dir = os.path.join(temp_dir, f"whitesource-config-{org}")
    
    print(f"  Cloning/updating whitesource-config repository: {ws_config_repo}")
    
    if os.path.isdir(ws_config_dir):
        success, _ = run_git_command(["pull", "origin", "main"], cwd=ws_config_dir)
        if not success:
            success, _ = run_git_command(["pull", "origin", "master"], cwd=ws_config_dir)
        return ws_config_dir if success else None
    else:
        success, _ = run_git_command(["clone", ws_config_repo, ws_config_dir])
        return ws_config_dir if success else None


def create_scan_json(ws_config_dir: str, repo_batch: list, scan_type: str) -> None:
    """Create the scan.json file with repository configurations."""
    scan_file = os.path.join(ws_config_dir, "scan.json")
    
    scan_data = {
        "repositories": [
            {
                "fullName": repo,
                "scanType": scan_type
            }
            for repo in repo_batch
        ]
    }
    
    with open(scan_file, 'w') as f:
        json.dump(scan_data, f, indent=2)


def commit_scan_file(ws_config_dir: str, batch_count: int, org: str, num_repos: int, max_retries: int = 3) -> bool:
    """Commit the scan.json file with retry logic."""
    commit_msg = f"Add scan configuration batch {batch_count} for {org} ({num_repos} repositories)"
    
    for attempt in range(1, max_retries + 1):
        print("  Fetching latest changes before committing...")
        run_git_command(["fetch", "origin"], cwd=ws_config_dir)
        
        success, output = run_git_command(["add", "scan.json"], cwd=ws_config_dir)
        if not success:
            if attempt < max_retries:
                print(f"  ✗ Commit attempt {attempt}/{max_retries} failed to add scan.json: {output}")
                print(f"  Retrying in 5 seconds...")
                time.sleep(5)
                continue
            else:
                print(f"  ✗ Commit attempt {attempt}/{max_retries} failed to add scan.json: {output}")
                print(f"  ✗ All {max_retries} commit attempts failed")
                return False
        
        success, output = run_git_command(["commit", "-m", commit_msg], cwd=ws_config_dir)
        if success:
            return True
        
        if attempt < max_retries:
            print(f"  ✗ Commit attempt {attempt}/{max_retries} failed: {output}")
            print(f"  Retrying in 5 seconds...")
            time.sleep(5)
        else:
            print(f"  ✗ Commit attempt {attempt}/{max_retries} failed: {output}")
            print(f"  ✗ All {max_retries} commit attempts failed")
    
    return False


def push_scan_file(ws_config_dir: str, max_retries: int = 3) -> bool:
    """Push the scan.json file to the remote repository with retry logic."""
    for attempt in range(1, max_retries + 1):
        success, output = run_git_command(["push", "origin", "main"], cwd=ws_config_dir)
        if not success:
            success, output = run_git_command(["push", "origin", "master"], cwd=ws_config_dir)
        
        if success:
            return True
        
        if attempt < max_retries:
            print(f"  ✗ Push attempt {attempt}/{max_retries} failed: {output}")
            print(f"  Retrying in 5 seconds...")
            time.sleep(5)
        else:
            print(f"  ✗ Push attempt {attempt}/{max_retries} failed: {output}")
            print(f"  ✗ All {max_retries} push attempts failed")
    
    return False


def verify_scan_json(ws_config_dir: str) -> bool:
    """
    Verify scan.json exists in the repository.
    Returns True if scan.json is NOT found (success), False if it still exists.
    """
    print("  Fetching latest changes to verify scan.json presence...")
    
    success, _ = run_git_command(["fetch", "origin"], cwd=ws_config_dir)
    if not success:
        print("  ✗ Failed to fetch latest changes from repository")
        return False
    
    # Try to reset to main, then master
    success, _ = run_git_command(["reset", "--hard", "origin/main"], cwd=ws_config_dir)
    if not success:
        success, _ = run_git_command(["reset", "--hard", "origin/master"], cwd=ws_config_dir)
    
    if not success:
        print("  ✗ Failed to reset to latest remote state")
        return False
    
    scan_file = os.path.join(ws_config_dir, "scan.json")
    if os.path.isfile(scan_file):
        print("  ✗ scan.json present in repository")
        return False
    else:
        print("  ✓ scan.json not found in repository")
        return True


def process_organizations(organizations: list, org_repos: dict, scm: str, temp_dir: str, scan_type: str, azure_org: str | None = None) -> None:
    """Process each organization and its repositories."""
    print("\n\nProcessing each organization")
    print("-----------------")
    
    for org in organizations:
        print(f"\n=== Processing Organization: {org} ===")
        
        repos = org_repos.get(org, [])
        print(f"Repositories in {org} ({len(repos)} total):")
        
        ws_config_dir = clone_or_fetch_repo(scm, org, temp_dir, azure_org)
        
        if not ws_config_dir:
            print(f"  Failed to clone/update whitesource-config for {org}")
            continue
        
        # Process repositories in batches of 10
        repo_batch = []
        batch_count = 1
        
        for i, repo_url in enumerate(repos):
            if repo_url:
                # Extract full repository name from URL
                if "azure" in scm.lower():
                    # Azure DevOps URL format: {SCM}/{org}/{project}/_git/{repo}
                    # Extract project (group 2) and repo (group 4)
                    match = re.search(r'([^/]+)/([^/]+)/([^/]+)/([^/]+?)(?:\.git)?$', repo_url)
                    if match:
                        repo_fullname = f"{match.group(2)}/{match.group(4)}"
                        repo_batch.append(repo_fullname)
                else:
                    # Standard URL format: {SCM}/{org}/{repo}.git
                    match = re.search(r'.*/([^/]+/[^/]+)\.git$', repo_url)
                    if match:
                        repo_fullname = match.group(1)
                        repo_batch.append(repo_fullname)
                
                # When we reach 10 repos or it's the last repo, create scan.json
                if len(repo_batch) == 10 or i == len(repos) - 1:
                    if repo_batch:
                        print(f"  Creating scan file: scan.json ({len(repo_batch)} repositories, batch {batch_count})")
                        
                        create_scan_json(ws_config_dir, repo_batch, scan_type)
                        
                        if not commit_scan_file(ws_config_dir, batch_count, org, len(repo_batch)):
                            print("  ✗ Commit failed. Exiting application.")
                            sys.exit(1)
                        
                        if not push_scan_file(ws_config_dir):
                            print("  ✗ Push failed after all retries. Exiting application.")
                            sys.exit(1)
                        
                        # Verification process: Only perform for batches with 10 or more repositories
                        if len(repo_batch) >= 10:
                            print("  Waiting 30 seconds before verifying scan.json commit...")
                            time.sleep(30)
                            
                            # Verify scan.json and repeat if present
                            while not verify_scan_json(ws_config_dir):
                                print("  scan.json found - waiting 30 more seconds and checking again...")
                                time.sleep(30)
                        else:
                            print(f"  Skipping verification for batch with {len(repo_batch)} repositories (less than 10)")
                        
                        # Reset for next batch
                        repo_batch = []
                        batch_count += 1
        
        print(f"  Completed processing {org}: Created {batch_count - 1} scan file(s)")
        
        # For Azure DevOps, verify scan.json is processed before moving to the next organization
        if "azure" in scm.lower() and ws_config_dir and batch_count > 1:
            print("  Azure DevOps: Verifying scan.json is processed before next organization...")
            time.sleep(30)
            while not verify_scan_json(ws_config_dir):
                print("  scan.json found - waiting 30 more seconds and checking again...")
                time.sleep(30)
            print("  ✓ Ready to proceed to next organization")


def main():
    global _temp_dir
    
    # Check for required environment variables
    scm = get_env_var("SCM")
    mend_url = get_env_var("MEND_URL")
    mend_email = get_env_var("MEND_EMAIL")
    mend_user_key = get_env_var("MEND_USER_KEY")
    ws_apikey = get_env_var("WS_APIKEY", required=False)
    only_updated_repos = get_env_var("MEND_ONLY_UPDATED_REPOS", required=False) == "true"
    
    # Get and validate scan type
    scan_type = get_env_var("SCAN_TYPE")
    scan_type = scan_type.upper()
    if scan_type not in ("SCA", "SAST"):
        print(f"SCAN_TYPE must be either 'SCA' or 'SAST', got: {scan_type}")
        sys.exit(1)
    print(f"Scan type: {scan_type}")
    
    # Azure-specific: Get Azure organization name if SCM is Azure DevOps
    azure_org = None
    if "azure" in scm.lower():
        azure_org = get_env_var("AZURE_ORG")
        print(f"Azure DevOps detected. Using Azure organization: {azure_org}")
    
    # Create temporary directory for cloned repositories in the current working directory
    _temp_dir = tempfile.mkdtemp(prefix="mend_scan_", dir=".")
    print(f"Created temporary directory: {_temp_dir}")
    
    # Register cleanup handler to run on exit
    atexit.register(cleanup_temp_dir)
    
    # Reformat MEND_URL for the API
    api_url = reformat_mend_url(mend_url)
    
    # Log into API 2.0
    jwt_token, org_uuid = login_to_api(api_url, mend_email, mend_user_key, ws_apikey)
    
    # Get all entities
    all_entities = get_all_entities(api_url, org_uuid, jwt_token)
    
    # Filter to project entities
    project_entities = filter_project_entities(all_entities, only_updated_repos)
    
    # Extract tags
    repo_fullnames, remote_urls = extract_tags(project_entities)
    
    # Process and deduplicate
    unique_repos = process_and_deduplicate_repos(repo_fullnames, remote_urls, scm)
    
    # Extract organizations
    organizations, org_repos = extract_organizations(unique_repos)
    
    # Process each organization
    process_organizations(organizations, org_repos, scm, _temp_dir, scan_type, azure_org)
    
    print("\n\nScript completed successfully!")


if __name__ == "__main__":
    main()

