# Examples by CI/CD Tool
This repository contains tool specific examples of how to scan using the Mend [Unified CLI](https://docs.mend.io/bundle/cli/page/scan_with_mend_s_unified_cli.html) within a CI/CD pipeline.


* [AzureDevOps](AzureDevOps)
* [Bamboo](Bamboo)
* [Bitbucket](Bitbucket)
* [CircleCI](CircleCI)
* [GitHub](GitHub)
* [GitLab](GitLab)
* [Jenkins](Jenkins)
* [TeamCity](TeamCity)

## Caching the Unified CLI
The CLI is a lightweight wrapper which can be cached if required.
Before every execution of the CLI, the CLI auto-updates itself to the latest version.
In order to manually update it, you can run:
```
mend update 
```

## Pipeline Log Publishing

* Publish the `.mend/logs` folder with logs & reports by adding the following commands depending on each pipeline

### Azure DevOps Pipelines
## SCA

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
## SAST
```
- publish: c:\users\VssAdministrator\.mend\storage\sast\logs
  artifact: "Mend CLI Logs"
```
* Linux:
```
- publish: ../../../.mend/storage/sast/logs
  artifact: "Mend CLI logs"
```
### GitHub Actions

## SCA
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
## SAST
```
- name: 'Upload Mend CLI Logs if failure'
    uses: actions/upload-artifact@v2
    with:
        name: "Mend CLI Logs"
        path: ~/.mend/storage/sast/logs
        retention-days: 1
- name: 'Upload Mend CLI Logs if failure'
    uses: actions/upload-artifact@v2
    if: failure()
    with:
        name: "Mend CLI Logs"
        path: ~/.mend/storage/sast/logs
        retention-days: 1
```