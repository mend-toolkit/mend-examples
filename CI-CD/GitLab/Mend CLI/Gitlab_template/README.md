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

### Gitlab CI/CD Artifacts vs Cache

Gitlab supports two types of mechanim to carry on data between build stages:
- Artifacts: Files are stored on the GitLab after a job is executed. Subsequent jobs will download the artifact before script execution, this is useful when there are many small files, for example NPM the Mend CLI to carry over it various build steps.
- Cache: It's a set of files that a job can download before running and upload after execution, usually using a distriuted cache, like Amazon S3. This is useful for carry over big files over stages.

### Create a Template Repo

If you don't already have a template repo in your Gitlab, create one in the desired group (for `templates/mend-templates`) and make sure all other repos have access to it, and copy the `mend.yaml` and optionally the `README.md` to this repo for reference

### Use the template

If you do not have a .gitlab-ci.yml, [create one](https://docs.gitlab.com/ee/ci/quick_start/).
In your Gitlab CI, use the stages which are described in the `.gitlab-ci.yml` add define the parameters:

```yaml
# replace templates below with your group or path to templates
include:
  project: templates/mend-templates
  file: 
    - mend.yml

# Vars for build projects
variables:
  MAVEN_OPTS: -Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository
  MAVEN_CLI_OPTS: -DskipTests

before_script:
  - GRADLE_USER_HOME="$(pwd)/.gradle"
  - export GRADLE_USER_HOME


stages:
  - build # See example below and replace the stage name accordingly
  - download
  - mend_scan
  - mend_reports

### Maven Example
## Cache example for Maven
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .m2/repository
    - target
  policy: pull-push


## Maven example - replace with your builds steps
maven_build:
   image: maven:3.8-openjdk-11
   stage: build
   script: mvn $MAVEN_OPTS clean install $MAVEN_CLI_OPTS
   cache:
     key: ${CI_COMMIT_REF_SLUG}
     paths:
       - .m2/repository
       - target
     policy: push
   tags:
     - docker # Depends on your runner tag , for gitlab.com hosted tags, see: https://docs.gitlab.com/ee/ci/runners/hosted_runners/linux.html#machine-types-available-for-linux---x86-64

### Gradle Example
## Cache example for Gradle
 cache:
    ey: "$CI_COMMIT_REF_NAME"
    policy: pull-push
    paths:
      - build
      - .gradle

## Gradle example - replace with your builds steps
gradle_build:
  stage: build
  script: ./gradlew build
  cache:
    key: "$CI_COMMIT_REF_NAME"
    policy: pull-push
    paths:
      - build
      - .gradle
  tags:
    - docker

### NPM Example
## Cache example for NPM
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
  policy: pull-push

## NPM example - replace with your builds steps
npm_build:
  image: node:18.18.0-alpine
  stage: build
  script: npm i
  artifacts:
    paths:
      - node_modules/
  tags:
    - docker

### Python Example
## Cache example for Python
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - venv/
  policy: pull-push

## Python example - replace with your builds steps
python_bulild:
  stage: build
  script: |
    pip install virtualenv
    virtualenv venv
    source venv/bin/activate
    pip install -r requirements.txt
  artifacts:
    paths:
      - venv
  tags:
    - docker

# Call Mend from Template
.download_mend:
  stage: download 
  extends: download_mend
  tags:
    - docker 

.mend_sca:
  stage: mend_scan
  extends: mend_sca
  allow_failure: true
  cache: # Download the cache from build steps
    key: "$CI_COMMIT_REF_NAME"
    policy: pull
    paths:
      - build # Gradle
      - .gradle # Gradle
      - node_modules # NPM
      - .m2/repository # Maven
      - target # Maven
      # Python uses artifacts and activates venv
  parallel:
    matrix:
      - INSTANCE: 1 # Used for parallel scans of SCA & SAST concurrently as those scans are independent
  tags:
    - docker


.mend_reports:
  stage: mend_reports
  extends: mend_reports
```

### Add Mend build variables
Before triggering the pipeline, add the following to your [GitLab CI/CD variables in the project settings](https://docs.gitlab.com/ee/ci/variables/#define-a-cicd-variable-in-the-ui):
```bash
MEND_EMAIL: your_email@company.com or serviceuser@company.com
MEND_USER_KEY: User Key from Mend UI
MEND_URL: Your base Mend URL (e.g: https://saas.mend.io)
```

### Getting Mend Artifacts
All scan logs, from all Mend stages including the reports are uploaded to each build stage as Artifacts

### Modify the default scan steps
The template executes SCA, SAST and generate all reports which described above.
If you wish to change it from the template or when you run the pipeline manually.

