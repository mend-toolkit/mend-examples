# Examples by CI/CD Tool
This repository contains tool specific examples of how to scan using the Mend [Unified CLI](https://docs.mend.io/bundle/cli/page/scan_with_mend_s_unified_cli.html) within a CI/CD pipeline.  

*JDK 8/11 is NOT required to scan with the Mend CLI*

The Mend CLI authentication environment variables are explained within the [product documentation](https://docs.mend.io/bundle/cli/page/login_to_the_mend_cli_with_a_script.html).  


- [Atlassian Bamboo](./Atlassian_Bamboo.sh)
- [Azure DevOps](./AzureDevOps.yaml)
  - [Additional Azure DevOps examples](../Unified%20Agent/CI-CD/AzureDevOpsBuilds.md)
- [Bitbucket](./Bitbucket.yaml)
- [CircleCI](./CircleCI.yaml)
- [GitHub](./GitHub.yaml)
  - [Additional GitHub build examples](../Unified%20Agent/CI-CD/GitHubBuilds.md)
- [GitLab](./GitLab.yaml)
- [Jenkins](./Jenkins.groovy)
- [TeamCity](./Teamcity.sh)

Bash example
```shell
# Download the Mend CLI and give write access
echo "Downloading Mend CLI"
curl -LJO https://downloads.mend.io/production/unified/latest/linux_amd64/mend && chmod +x mend

# Add environment variables for SCA and Container scanning
export MEND_EMAIL=your-email
export MEND_USER_KEY=your-mend-sca-userkey
export MEND_URL="https://saas.mend.io"
# Add environment variables for SAST scanning
export MEND_SAST_SERVER_URL="https://saas.mend.io/sast"
export MEND_SAST_API_TOKEN=your-sast-api-token
export MEND_SAST_ORGANIZATION=your-sast-organization-id

# Add your package manager build (see Maven and NPM examples below)
##  mvn clean install
##  npm install --only=prod

# The Mend SCA CLI scan should be called AFTER a package manager build step such as "mvn clean install -DskipTests=true" or "npm install --only=prod"
# Run a Mend Software Composition Analysis Scan
echo "Start Mend SCA Scan"
./mend sca -u

# Run a Mend Static Application Security Analysis Scan
echo "Start Mend SAST Scan"
./mend sast
```

## Container Scanning 
Container/Image scanning is detailed in seperate [README](./ContainerScanning.md)

## Pipeline Log Publishing

* Publish the `.mend/logs` folder with logs & reports by adding the following commands depending on each pipeline
  * SAST logs are currently located in ```.mend/storage/sast/logs```

### Azure DevOps Pipelines

* Windows:
```
- publish: c:\users\VssAdministrator\.mend\logs
  artifact: "Mend CLI Logs"
```
* Linux:
```
- publish: ../../../.mend/logs
  artifact: "Mend CLI logs"
```

### GitHub Actions

```
- name: 'Upload Mend CLI Logs if failure'
    uses: actions/upload-artifact@v2
    with:
        name: "Mend CLI Logs"
        path: ~/.mend/logs
        retention-days: 1
- name: 'Upload Mend CLI Logs if failure'
    uses: actions/upload-artifact@v2
    if: failure()
    with:
        name: "Mend CLI Logs"
        path: ~/.mend/logs
        retention-days: 1
```