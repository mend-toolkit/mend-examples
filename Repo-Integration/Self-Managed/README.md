![Logo](https://mend-toolkit-resources-public.s3.amazonaws.com/img/mend-io-logo-horizontal.svg)  

> [!Warning]  
**This should only be used for Proof of Concepts (PoC) as it does not implement many aspects of a production-ready integration including scaling, log management, and load balancing.**  

# Self-Managed Repository Integration Automation Scripts
When used, these scripts will download the latest [repository integration](https://docs.mend.io/bundle/integrations/page/repo_integrations.html) and run via docker compose:
- Remediate Server
- Controller
- Scanner

## Supported Operating Systems
- **Linux (Bash):**	CentOS, Debian, Ubuntu, RedHat

## Prerequisites
- Docker, Docker Compose, git, wget, SCM Repository instance up and running

## Options
`setup.sh` options: **ghe**, **gls**, **bb** *optional* **version**

Options Defined:  
**ghe** - GitHub Enterprise

**gls** - GitLab (self-hosted)

**bb** - Bitbucket Server

**version** - If left blank, latest version is installed. [Available versions](https://docs.mend.io/bundle/integrations/page/mend_developer_integrations_release_notes.html)

For custom CA information, please see the [certificate readme](./certs.md)

## Execution
Execution instructions:  

- Clone the repository & give setup.sh permissions to run

```git clone https://github.com/mend-toolkit/mend-examples.git && cd mend-examples/Repo-Integration/Self-Managed && chmod +x setup.sh```
- Add your the following environment variables which will be copied to the .env file that is created by setup.sh

```
export ws_key='your activation key between single quotes'
export github_com_token='your github.com token'
export graylog_root_password='the password you would like to use to login to graylog'
```

- Run the setup.sh script for your appropriate source control management system as shown in options above

- Run docker compose depending on how it was installed. Options defined -
  - SCA only  - docker-compose.yaml
  - SCA and SAST - docker-compose-sast.yaml
    - **Note: this is currently only supported for GHE** [(a dedicated SAST scanner container)](https://docs.mend.io/bundle/integrations/page/deploy_with_docker.html#Target-Machine:-Run-the-Containers).

```docker-compose -f <compose file> up```

- Run docker compose in detached mode depending on how it was installed.

```docker-compose -f <compose file> up -d```

- After running this, graylog will start, and the integration will wait until graylog has been fully configured to accept input from the integration. 
  - Run `docker-compose logs --follow` in a terminal to get the username and password for first time login
  - Navigate to http://localhost:9000 and log in with username: `admin` and password: `the password shown in the graylog logs`
  - Follow the setup steps and keep all of the defaults.
  - After setup is finished. Log into the platform with with the username: admin and the password you set in `$GRAYLOG_ROOT_PASSWORD`
  - Go to `System -> Content Packs` and upload and install the `mend-graylog-content-pack.json` included in this repo. NOTE: uploading and installing are two different steps.
  - After the content pack is installed and a brief delay, the Mend Repo Integration should start and automatically pipe all logs to the graylog server.

- Features of the Mend Graylog Content Pack
  - An input for all of the repo integration logs.
    - Extractors that allow for easy parsing of the repo integration logs.
  - Two inputs that send API requests periodically for the Scanner and Remediate containers healthcheck endpoints.
  - Dashboards for searching the integration containers individually.
  - Dashboards showing statistics pulled from the healthcheck API inputs.