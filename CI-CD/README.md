![Logo](https://mend-toolkit-resources-public.s3.amazonaws.com/img/mend-io-logo-horizontal.svg)  

# CI/CD Examples
This repository contains tool specific examples of how to deploy the [Mend Unified Agent](https://docs.mend.io/bundle/unified_agent/page/overview_of_the_unified_agent.html), the [Mend CLI](https://docs.mend.io/bundle/cli/page/scan_with_mend_s_unified_cli.html) and other tools, within a CI/CD pipeline.  


- [Generic Examples](#generic-examples)
- [Examples by CI/CD Tool](#examples-by-cicd-tool)
- [Additional Tips](#additional-tips)
  - [Caching the Unified Agent](#caching-the-unified-agent)
  - [Publishing Mend's Logs From a Pipeline](#publishing-mends-logs-from-a-pipeline)
    - [Azure DevOps Pipelines](#azure-devops-pipelines)
    - [GitHub Actions](#github-actions)

>**Note:** When scanning using the [Mend Unified Agent](https://docs.mend.io/bundle/unified_agent/page/overview_of_the_unified_agent.html), ensure first that JDK 8/11 is installed on the pipeline image.

<br/>

## Generic Examples
  - [Mend CLI](./%5BGeneric%5D/Mend%20CLI/)
    - [SCA and SAST Scan](./%5BGeneric%5D/Mend%20CLI/sca%2Bsast-scan.sh)
    - [Container/Image Scan](./%5BGeneric%5D/Mend%20CLI/ContainerScanning.md)
  - [Unified Agent](./%5BGeneric%5D/Unified%20Agent/)
    - [Policy Check](./%5BGeneric%5D/Unified%20Agent/Policy-Check/)
    - [Prioritize](./%5BGeneric%5D/Unified%20Agent/Prioritize/)

## Examples by CI/CD Tool
  - [AzureDevOps](./AzureDevOps)
  - [Bamboo](./Bamboo)
  - [Bitbucket](./Bitbucket)
  - [CircleCI](./CircleCI)
  - [CloudBuild](./CloudBuild)
  - [CodeBuild](./CodeBuild)
  - [CodeFresh](./CodeFresh)
  - [GitHub](./GitHub)
  - [GitLab](./GitLab)
  - [Jenkins](./Jenkins)
  - [TeamCity](./TeamCity)

## Additional Tips

### Caching the Unified Agent
The best practice with all of the above pipeline integrations is to have the [Unified Agent](https://docs.mend.io/bundle/unified_agent/page/getting_started_with_the_unified_agent.html#GettingStartedwiththeUnifiedAgent-DownloadingtheUnifiedAgent) downloaded onto the build's workspace during the build job, so that you always use the latest version.  

It is possible to utilize your CI tool's built-in caching functionality, so that you only download the latest version of the agent once every release.

In the following examples, the `wss-unified-agent.jar` artifact is stored in the pipeline's cache, and the Mend pipeline task first checks whether a newer version of the agent was published since the last time the agent was cached, and if so, it downloads the latest version to be cached instead, before proceeding to the scan itself.  

**Examples:**  

* [Generic Example](../../Scripts/Mend%20SCA/README.md#cache-the-latest-version-of-the-unified-agent)
* [GitLab Pipelines](./GitLab/Unified%20Agent/GitLab-cached-ua.yml)