# Renovate Examples by CI/CD Tool
This repository contains examples of a Self-hosted instance of [Renovate](https://docs.renovatebot.com/) to generate automatic pull requests as part of various pipelines.

**Important Note - The following step is required for all integrations** 

It is highly recommend to configure a GitHub.com [Personal Access Token](https://github.com/settings/tokens) (with the scope repos) as GITHUB_COM_TOKEN so that your bot can make authenticated requests to GitHub.com for changelog retrieval as well as for any dependency that uses GitHub tags (without such a token, GitHub.com's API will rate limit requests and make such lookups unreliable).

## [GitLab pipelines](https://docs.gitlab.com/ee/ci/pipelines/)
The gitlab [renovate runner](https://docs.renovatebot.com/getting-started/running/#gitlab-runner) can implemented using the following steps:
* Create a [Personal Access Token](https://gitlab.com/-/profile/personal_access_tokens) (PAT) for the runner to use (scopes: read_user, api and write_repository).
* Create a new project to host the runner (e.g. renovate-runner-host).
* Add the following variables to [CI/CD Variables](https://docs.gitlab.com/ee/ci/variables/) in the runner project.
  * GITHUB_COM_TOKEN = a PAT for Github
  * RENOVATE_TOKEN = a PAT created above for Gitlab
* Create a new main pipeline for the desired project and replace contents with the [.gitlab-ci.yml](.gitlab-ci.yml) file in this folder.
* Adjust RENOVATE_EXTRA_FLAGS parameters to indicate what projects Renovate should run against
  * If you wish for your bot to run against any project which the RENOVATE_TOKEN PAT has access to, but already has been onboarded
    *  ```--autodiscover=true```
        * Projects will not receive an onboarding PR with this setting and require a renovate.json or similar config
    * We recommend you apply an autodiscoverFilter value like the following so that the bot does not run on any stranger's project it gets invited to
      * ```--autodiscover=true --autodiscover-filter=group1/*```
        * group1 is the target gitlab project group
  * If you wish for your bot to run against every project which the RENOVATE_TOKEN PAT has access to, and onboard any projects which don't yet have a config
    * ```--autodiscover=true --onboarding=true --autodiscover-filter=group1/*```
    * If you wish to manually specify which projects that your bot runs again, use a space-delimited set of project names
      * ```--autodiscover-filter=group1/repo5 user3/repo1```
* Set up a schedule (CI / CD > Schedules) to run Renovate regularly
  - A good practise is to run it hourly. The following runs Renovate on the third minute every hour ```3 * * * *``` 
