# Examples by CI/CD Tool
This repository contains tool specific examples of how to scan using the Mend [Unified Agent](https://docs.mend.io/bundle/unified_agent/page/overview_of_the_unified_agent.html) within a CI/CD pipeline.  

Ensure that JDK 8/11 is installed in the pipeline image before the Unified Agent scan.


* [AWSCodeBuild](./AWSCodeBuild_buildspec.yml)
* [AzureDevOps](./azure-pipelines.yml)
  * [Windows](./azure-pipelines_windows.yml)
  * [Additional AzureDevOps build examples](./AzureDevOpsBuilds.md)
* [Bamboo](./Bamboo.sh)
* [Bitbucket](./Bitbucket.yml)
* [CodeFresh](./CodeFresh.yml)
* [CircleCI](./CircleCI.yaml)
* [Generic](./UA-SCA.sh)
* [GitHub](./GitHub.yml)
  * [Additional GitHub build examples](./GitHubBuilds.md)
* [GitLab](./GitLab.yml)
* [GoogleCloudBuild](./GoogleCloudBuild.yaml)
* [Jenkins](./Jenkins.groovy)
* [TeamCity](./TeamCity.yml)

## Caching the Unified Agent
The best practice with all of the above pipeline integrations is to have the [Unified Agent](https://docs.mend.io/bundle/unified_agent/page/getting_started_with_the_unified_agent.html#GettingStartedwiththeUnifiedAgent-DownloadingtheUnifiedAgent) downloaded onto the build's workspace during the build job, so that you always use the latest version.  

It is possible to utilize your CI tool's built-in caching functionality, so that you only download the latest version of the agent once every release.

In the following examples, the `wss-unified-agent.jar` artifact is stored in the pipeline's cache, and the Mend pipeline task first checks whether a newer version of the agent was published since the last time the agent was cached, and if so, it downloads the latest version to be cached instead, before proceeding to the scan itself.  
* [Caching the Unified Agent - GitLab Pipelines](./GitLab-cached-ua.yml)
* Generic example - [Cache the Latest Version of the Unified Agent](../../Scripts/Mend%20SCA/README.md#cache-the-latest-version-of-the-unified-agent)

## [Multi-Org](./MultiOrg/)

## [Mend Reports Within a Pipeline](../../Scripts/Mend%20SCA/README.md)

## Pipeline Log Publishing

* Publish the `whitesource` folder with logs & reports by adding the following commands depending on each pipeline

### Azure DevOps Pipelines

```
- publish: $(System.DefaultWorkingDirectory)/whitesource
  artifact: Whitesource
```
### GitHub Actions

```
- name: 'Upload WhiteSource folder'
  uses: actions/upload-artifact@v2
  with:
    name: WhiteSource
    path: whitesource
    retention-days: 1
- name: 'Upload WhiteSource folder if failure'
  uses: actions/upload-artifact@v2
  if: failure()
  with:
    name: WhiteSource
    path: whitesource
    retention-days: 1
```
