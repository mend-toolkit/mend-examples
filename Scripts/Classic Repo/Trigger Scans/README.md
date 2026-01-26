# Mend Repository Manual Scan Script

A Python script that automates triggering Mend scans across multiple repositories by pulling repository information from Mend project tags and creating scan configurations.

> [!WARNING]
> This script is presented as is and will not be actively maintained. This script was tested with the Classic [Mend for Github.com](https://docs.mend.io/integrations/latest/mend-for-github-com) and [Azure DevOps](https://docs.mend.io/integrations/latest/mend-for-azure-repos) Integrations. It does not work on [Developer Platform](https://docs.mend.io/integrations/latest/mend-developer-platform) Integrations.

## Overview

1. **Pulls repository tags** - Retrieves all `repoFullName` and `remoteUrl` values from Mend project tags via the API
2. **Deduplicates repositories** - Removes duplicate repository URLs and organizes them by organization
3. **Triggers scans** - Creates and pushes `scan.json` files to each organization's `whitesource-config` repository

## Prerequisites

### Python Requirements

- Python 3.10 or higher
- `requests` library

```bash
pip install requests

```

### Git

Git must be installed and configured with credentials to clone and push to your repositories.

### Global Mend Configuration

A [whitesource-config](https://docs.mend.io/integrations/latest/global-repo-configuration) repository must be present in the Github Organzation. 

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MEND_USER_KEY` | Yes | An administrator's user key |
| `MEND_EMAIL` | Yes | The administrator's email address |
| `MEND_URL` | Yes | Mend instance URL (e.g., `https://saas.mend.io`) |
| `SCM` | Yes | Source control prefix (e.g., `https://github.com`) |
| `SCAN_TYPE` | Yes | Type of scan to perform: `SCA` or `SAST` |
| `WS_APIKEY` | No | API Key for organization. If not provided, defaults to the last organization accessed in the Mend UI |
| `MEND_ONLY_UPDATED_REPOS` | No | Set to `true` to only process repositories scanned within the last 90 days |
| `AZURE_ORG` | Conditional | Azure DevOps organization name. Required if `SCM` contains 'azure' |

## Usage

### Setting Environment Variables

**Windows (Command Prompt):**
```cmd
set MEND_USER_KEY=your-user-key
set MEND_EMAIL=your-email@example.com
set MEND_URL=https://saas.mend.io
set SCM=https://github.com
set SCAN_TYPE=SCA
set WS_APIKEY=your-api-key
```

**Linux/macOS:**
```bash
export MEND_USER_KEY="your-user-key"
export MEND_EMAIL="your-email@example.com"
export MEND_URL="https://saas.mend.io"
export SCM="https://github.com"
export SCAN_TYPE="SCA"
export WS_APIKEY="your-api-key"
```

**For Azure DevOps:**
```bash
export SCM="https://dev.azure.com"
export AZURE_ORG="your-azure-org"
```

### Running the Script

```bash
python mend_trigger_scans_all_repos.py
```

## How It Works

### 1. Authentication
The script logs into the Mend API 2.0 using your credentials and retrieves a JWT token.

### 2. Project Discovery
Retrieves all projects from your organization with pagination support (10,000 projects per page).

### 3. Tag Extraction
Extracts `repoFullName` and `remoteUrl` tags from each project to identify associated repositories.

### 4. Deduplication
- Removes duplicate repository URLs
- Normalizes URLs (adds SCM prefix, removes branch suffixes)
- Groups repositories by organization

### 5. Scan Configuration
For each organization:
- Clones the `whitesource-config` repository into a temporary directory
- Creates `scan.json` files with up to 10 repositories per batch
- Commits and pushes the configuration
- Waits for the scan to complete (verifies `scan.json` is removed)

### 6. Cleanup
Automatically removes the temporary directory containing cloned repositories on exit.

## Features

### Retry Logic
- **Commit operations**: Retry up to 3 times with 5-second delays
- **Push operations**: Retry up to 3 times with 5-second delays
- Script exits if all retries fail

### Batch Processing
Repositories are processed in batches of 10 to avoid overwhelming the scan system.

### Scan Verification
For batches of 10+ repositories, the script waits and verifies that `scan.json` has been processed (removed from the repository) before proceeding to the next batch.

### Automatic Cleanup
- Creates a temporary directory in the current working directory
- Automatically cleans up on exit (normal completion, errors, or interruption)
- Handles Windows read-only file permissions (common with Git repositories)

### 90-Day Filter
When `MEND_ONLY_UPDATED_REPOS=true`, only repositories that have been scanned within the last 90 days are processed. Projects without a scan date are logged to `no_scan_date.txt`.

## Output Files

| File | Description |
|------|-------------|
| `no_scan_date.txt` | List of projects without a last scan date (created when using `MEND_ONLY_UPDATED_REPOS=true`) |
| `mend_scan_*` | Temporary directory containing cloned repositories (automatically cleaned up) |

## scan.json Format

The script creates `scan.json` files with the following structure:

```json
{
  "repositories": [
    {
      "fullName": "org/repo-name",
      "scanType": "SCA"
    }
  ]
}
```

The `scanType` value is determined by the `SCAN_TYPE` environment variable (either `SCA` or `SAST`).

## Error Handling

- **Missing environment variables**: Script exits with an error message
- **API errors**: HTTP errors are raised and will stop execution
- **Git failures**: Commit/push failures trigger retries; script exits after 3 failed attempts
- **Cleanup failures**: Logged but don't prevent script completion

## API Documentation

For more information on the Mend APIs used by this script, see:
https://docs.mend.io/bundle/mend-api-2-0/page/index.html

## Troubleshooting

### Access Denied on Cleanup (Windows)
The script handles Windows read-only file permissions automatically. If you still encounter issues, ensure no other process is accessing the temporary directory.

### Git Authentication
Ensure your Git credentials are configured. You may need to:
- Set up SSH keys
- Configure a credential helper
- Use a personal access token

### API Connection Issues
Verify your `MEND_URL` is correct and accessible from your network.
