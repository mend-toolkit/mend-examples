The following scripts can be used to gather data from the Mend.io application and different Source Control Management systems in order to understand how many developers are currently working on repositories throughout the calendar year.

> [!IMPORTANT]
The project tags repoFullName and remoteUrl are only populated by the [Unified CLI](https://docs.mend.io/bundle/integrations/page/scan_with_the_mend_cli.html) and [repository integration](https://docs.mend.io/bundle/integrations/page/repo_integrations.html) scans.  [Unified Agent](https://docs.mend.io/bundle/unified_agent/page/getting_started_with_the_unified_agent.html) and [Developer Platform](https://docs.mend.io/bundle/platform/page/mend_developer_platform.html) users will need to provide a list of repositories manually to run the [get-committers.sh](./get-committers.sh) script.



- For more information on the APIs used, please check our REST API documentation page: 📚 https://docs.mend.io/bundle/mend-api-2-0/page/index.html
- Users should edit these files to add any steps for consuming the information provided by the API requests however needed.

# Supported Operating Systems
- **Linux (Bash):**	Debian, Ubuntu
- **MacOs (zshell):** Sonoma

# Prerequisites
```shell
# Linux
apt install -y jq curl git

# MacOS
brew install -y jq git
```
# [get-repo-tags.sh](./get-repo-tags.sh)
This script pulls all of the projects in an organization and then retrieves the tags for each and grabs the values for repoFullName and remoteUrl.  
Afterwards the scripts combines all of the data pulled for each project, prints to the screen and also saves to a repos.txt

The WS_API_KEY environment variable is optional. If this is not specified in the script, then the Login API will authenticate to the last organization the user accessed in the Mend UI.

MEND_ONLY_UPDATED_REPOS is an optional environment variable that will only retrieve repos that have been scanned in the last 90 days
## Usage
```shell
export MEND_USER_KEY="An administrator's userkey"
export MEND_EMAIL="The administrator's email"
export MEND_URL="https://saas.mend.io"
# Optional - if performing for multiple organizations with the same administrator
export WS_APIKEY="API Key for organization"

curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Committers/get-repo-tags.sh
chmod +x get-repo-tags.sh
./get-repo-tags.sh
```

# [dedup-repo.sh](./dedup-repo.sh)
It is recommended to review the repos.txt, cleanup duplicates, and add source control management prefixes before running the [get-committers.sh](./get-committers.sh) script.  The dedup-repo.sh script can also be modified to accomplish this.

## Usage
```shell
# modify with the appropriate prefix for your source control
export SCM=https://github.com

curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Committers/dedup-repo.sh
chmod +x dedup-repo.sh
./dedup-repo.sh repos.txt

```

# [get-committers.sh](./get-committers.sh)
This script clones git repositories from a text file and then runs the ```git shortlog``` command to determine what email addresses committed to the codebase within the last year.
The output is a committers.txt file with committer email addresses and an uncloned.txt with any repositories that were not cloned.

## Prerequisites
- Update the script with your preferred BEGIN_DATE if different than Jan 1, 2023
- Git credentials should be able to clone all repositories in the list
- Use a git credential manager or use the following command to cache your credentials
```shell
git config --global credential.helper 'cache --timeout=9999'
```

## Usage
```shell
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Committers/get-committers.sh
chmod +x get-committers.sh
./get-committers.sh deduprepos.txt
```
### Post Processing Cleanup Options
- The following commands can be used to cleanup the committer.txt output.
```shell
# Optional filter to remove blank lines and noreply@github.com results
grep -v "noreply@github.com" committers.txt | sed '/^$/d' > committers_filtered.txt

# The following command gives a quick line count for spot checking
wc -l committers_filtered.txt

# Use the following command to print all unique values to a new text file
awk '!seen[$0]++' committers_filtered.txt >> committers_dedup.txt
```
