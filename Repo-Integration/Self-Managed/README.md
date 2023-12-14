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

## Steps for a fast setup in AWS EC2
1) Provision a new EC2 instance with the following characteristics:
   - AMI: Ubuntu Server 22.04 LTS (HVM)
   - Type: c4.xlarge or larger
   - Storage: 40GiB (gp2) or higher
   - Security group: See [here](https://docs.mend.io/bundle/integrations/page/advanced_technical_information.html#Required-Open-Ports) for integration requirements
2) Launch and remote into instance (ssh or console)
3) Install Docker ([using the apt repository](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository))
   - Set up the Docker repository
   ```shell
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    ```     
   - Install Docker
   ```shell
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```
   - Setup up Docker for use as [non-root user](https://docs.docker.com/engine/install/linux-postinstall)
   ```shell
   sudo usermod -aG docker $USER
   newgrp docker
   ```
   - Ensure docker works as the current user with ```docker version``` 
   - Continue with the steps below
    		
## Options
`setup.sh` options: **ghe**, **gls**, **bb** *optional* **version**

Options Defined:  
**ghe** - GitHub Enterprise

**gls** - GitLab (self-hosted)

**bb** - Bitbucket Server

**version** - If left blank, the latest version is installed. [Available versions](https://docs.mend.io/bundle/integrations/page/mend_developer_integrations_release_notes.html)

For custom CA information, please see the [certificate readme](./certs.md)

## Execution
Execution instructions:  

- Clone the repository & give setup.sh permissions to run

```git clone https://github.com/mend-toolkit/mend-examples.git && cd mend-examples/Repo-Integration/Self-Managed && chmod +x setup.sh```
- Add the following environment variables which will be copied to the .env file that is created by setup.sh
```export ws_key='your activation key between single quotes'```

- Add your Github.com access token. This is important for Remediate and Renovate to prevent Gitbub rate-limiting imposed on non-authenticated requests.
`export github_com_token='replace-with-your-github-token-inside-single-quotes'`

- Add a password to log into the graylog platform as admin.
`export graylog_root_password='the password you would like to use to login to graylog'`

- Run the setup.sh script for your appropriate source control management system as shown in options above

- Run the following commands to increase your memory map count for graylog's elasticsearch.
```shell
sudo sh -c 'echo "vm.max_map_count=262144" >> /etc/sysctl.conf'
sudo sysctl -p
```

- Run docker compose in detached mode depending on how it was installed. Options defined -
  - SCA only  - docker-compose.yaml
  - SCA and SAST - docker-compose-sast.yaml
    - **Note: this is currently only supported for GHE** [(a dedicated SAST scanner container)](https://docs.mend.io/bundle/integrations/page/deploy_with_docker.html#Target-Machine:-Run-the-Containers).

```docker compose -f <compose file> up```

- After running this, graylog will start, and the integration will wait until graylog has been fully configured to accept input from the integration. 
  - Run `docker compose logs --follow` in a terminal to get the username and password for first time login
  - Navigate to http://localhost:9000 and log in with username: `admin` and password: `the password shown in the graylog logs`
  - Follow the setup steps and keep all of the defaults.
  - After setup is finished. Log into the platform with with the username: admin and the password you set in `$graylog_root_password`
  - Go to `System -> Content Packs` and upload and install the `mend-graylog-content-pack.json` included in this repo. NOTE: uploading and installing are two different steps.
  - After the content pack is installed and a brief delay, the Mend Repo Integration should start and automatically pipe all logs to the graylog server.

- Features of the Mend Graylog Content Pack
  - An input for all of the repo integration logs.
    - Extractors that allow for easy parsing of the repo integration logs.
  - Two inputs that send API requests periodically for the Scanner and Remediate containers healthcheck endpoints.
  - Dashboards for searching the integration containers individually.
  - Dashboards showing statistics pulled from the healthcheck API inputs.

## Stopping the Integration

In the event that the integration needs to be stopped, please use the command: `docker compose -f <docker-compose.yaml file> down` to stop the integration. This will ensure that graylog stops gracefully and no data corruption occurs.

## Basic Troubleshooting
Removing graylog volumes
```shell
docker compose down
docker volume rm $(docker volume ls | grep graylog | cut -d ' ' -f6)
```
Graylog also has some anonymous containers for the certificates that are installed.  If problems occuring during the installation it is recommended to remove all dangling containers and restart the installation
```shell
docker compose down
docker volume rm $(docker volume ls -qf dangling=true)
```
