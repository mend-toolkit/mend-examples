# GitLab CI CLI Templates

This pipeline is designed for demonstration purposes. You may modify it to fit your specific scanning and pipeline requirements. 

This example takes advantage of [GitLab Templates](https://docs.gitlab.com/ee/ci/components/index.html#cicd-catalog), making it easier to use, read, and reuse across different pipelines.

The template (`mend.yaml`) uses the [Mend CLI](https://docs.mend.io/bundle/integrations/page/scan_with_the_mend_cli.html) to run:
* **Software Composition Analysis (SCA)** scan using package managers (and file system scanning [optional]) to detect open-source components with report creating of:
    * SBOM Export
    * Risk report
    * Inventory report
    * Due diligence report

* **Static Application Security Testing (SAST)** scan to detect languages and frameworks used in your projects and report code weaknesses and creates `sarif` report

### Create a Template Repo

If you don't already have a template repo in your Gitlab, create one (for example `templates/templates`) and make sure all other repos have access to it, and copy the `mend.yaml` to this repo

### Use the template

In your Gitlab CI, use the stages which are described in the `.gitlab-ci.yaml` add define the parameters:
```yaml
include:
  - remote: 'https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/GitLab/Mend%20CLI/Gitlab_template/mend.yml'

stages:
  - build
  - download
  - mend_scan
  - mend_reports

build:
  stage: build
  script: BUILD STEPS

# Call Mend from Template
.download_mend:
  stage: download 
  extends: download_mend
  tags:
    - docker

.mend_sca:
  stage: mend_scan
  extends: mend_sca

.mend_reports:
  image: python:3.9-slim-bullseye
  stage: mend_reports
extends: mend_reports
```

### Bonus
By default, the template executes SCA, SAST and generate all reports which described above.
If you wish to change it from the template or when you run the pipeline manually.
In addition, all scan logs and reports are uploaded to each build stage.
