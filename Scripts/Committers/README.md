The following scripts can be used to gather data from the Mend.io application and different Source Control Management systems in order to understand how many developers are currently working on repositories throughout the calendar year.

For more information on the APIs used, please check our REST API documentation page: 📚 https://docs.mend.io/bundle/mend-api-2-0/page/index.html
Users should edit these files to add any steps for consuming the information provided by the API requests however needed.

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

# [dedup-repo.sh]
It is recommended to review the repos.txt, cleanup duplicates, and add source control management prefixes before running the [get-committers.sh](./get-committers.sh) script.  The dedup-repo.sh script can also be modified to accomplish this.
- Update the script with the appriopriate SCM prefix

## Usage
```shell
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Committers/dedup-repo.sh
chmod +x dedup-repo.sh
./dedup-repo.sh repos.txt

```

# [get-committers.sh](./get-committers.sh)
This script clones git repositories from a text file and then runs the ```git shortlog``` command to determine what email addresses committed to the codebase within the last year.

## Prerequisites
- Update the script with your preferred BEGIN_DATE
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