![Logo](https://mend-toolkit-resources-public.s3.amazonaws.com/img/mend-io-logo-horizontal.svg)  

> [!Warning]  
**This should only be used for Proof of Concepts (PoC) as it does not implement many aspects of a production-ready integration including scaling, load balancing, and fault tolerance.  For production rollout it is recommended to deploy using kubernetes.  Please contact your Customer Success Manager to engage with the Field Engineering team to learn more**  

> [!IMPORTANT]  
** The Graylog logging solution will prevent the startup of the Repo Integration containers until Graylog is set up. If the `docker compose up` seems to hang or never complete, please follow the instructions under [Execution](#execution) to set up the integration properly.**

# Self-Managed Repository Integration Automation Scripts
When used, these scripts will download the latest [repository integration](https://docs.mend.io/bundle/integrations/page/repo_integrations.html) and run via docker compose:
- Remediate Server
- Controller
- Scanner

## Supported Operating Systems
- **Linux (Bash):**	Ubuntu

## Prerequisites
- Docker, Docker Compose, git, wget, SCM Repository instance up and running
- Make sure that Ports 9000 and 5678 are open and accessible on the machine you will be running the integration on.  Netcat(```nc```) is required for the port_check section of the setup script to properly run and provide feedback

## Steps for a fast setup in AWS EC2
1) Provision a new EC2 instance with the following characteristics:
   - AMI: Ubuntu Server 22.04 LTS (HVM)
   - Type: r4.xlarge or larger
   - Storage: 200GiB (gp2) or higher
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
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```
   - Setup up Docker for use as [non-root user](https://docs.docker.com/engine/install/linux-postinstall)
   ```shell
   newgrp docker
   sudo usermod -aG docker $USER
   ```
   - Ensure docker & docker compose work as the current user with ```docker version && docker compose version``` 
   - Continue with the steps below
    		
## Options
```
Usage: setup.sh <scm> [-v <version>] [-g]
-v      The version of the integration you would like to use. (Optional - Default: latest)
-g      Specify to not use graylog when spinning up the integration.

Integration Options:
        ghe - GitHub Enterprise
        gls - GitLab Server
        bb - BitBucket Server
```

For custom CA information, please see the [certificate readme](./certs.md)

## Execution
Execution instructions:  

- Clone the repository & give setup.sh permissions to run

```shell
git clone https://github.com/mend-toolkit/mend-examples.git 
cd mend-examples/Repo-Integration/Self-Managed 
chmod +x setup.sh
```
- Add the following environment variables which will be copied to the .env file that is created by setup.sh
  - WS_KEY: Activation key which is obtained from the Mend User Interface Integration page
  - GITHUB_COM_TOKEN: which is important for Remediate and Renovate to prevent Gitbub rate-limiting imposed on non-authenticated requests
  - GRAYLOG_ROOT_PASSWORD: If using graylog, this is the password used to login to the Graylog platform after the intial setup

```shell
export ws_key='your activation key between single quotes'
export github_com_token='replace-with-your-github-token-inside-single-quotes'
export graylog_root_password='the password you would like to use to login to graylog'
```

- Run the setup.sh script for your appropriate source control management system as shown in options above

- If using graylog, run the following commands to increase your memory map count for graylog's elasticsearch.

```shell
sudo sh -c 'echo "vm.max_map_count=262144" >> /etc/sysctl.conf'
sudo sysctl -p
```

- If using graylog, follow these steps to make the docker engine API listen on TCP Port 2375.
  - Use the command: ``find /etc/systemd -name "docker.service"`` to get the path of the docker.service file.
  - Edit the file and add the following to the ExecStart command: ``-H tcp://0.0.0.0:2375`` (This is used to get container healthchecks)
  - Run: ``sudo systemctl daemon-reload && sudo systemctl restart docker`` to restart docker.  

- When first running ``docker compose up``, the graylog container will start with `waiting` state, navigate to: `http://{YOUR_IP}:9000`, login and perform the inital setup of the CA.
- To add the [dynamic tool installation mechanism](https://docs.mend.io/bundle/integrations/page/dynamic_tool_installation_mechanism.html) you must perform the following
  - Manually edit the Dockerfilefull found in ```~/mend/$SCM/$VERSION/wss-scanner/docker/Dockerfilefull``` as shown in the documentation
  - Edit the .env with the necessary groups or organizations needed for ```RUNINSTALL_MATCH``` variable
  - If you are not configuring AWS Cloudwatch it is recommended to add ```RUNINSTALL_DEBUG=true```
- Run docker compose in detached mode for your desired setup. Options defined -
  - SCA only ```docker compose up -d```
  - SCA and SAST ```docker compose -f docker-compose-sast.yaml up -d```
    - **Note: this is currently only supported for GHE** [(a dedicated SAST scanner container for GHE)](https://docs.mend.io/bundle/integrations/page/deploy_with_docker.html#Target-Machine:-Run-the-Containers) **and GLS** [(a dedicated SAST scanner container for GLS)](https://docs.mend.io/integrations/latest/installation-prerequisites-mend-for-gitlab#InstallationPrerequisites-MendforGitLab-DedicatedSASTConfiguration).

- After running this, wait until all containers are created.  Do not be concerned if the self-managed-graylog container has errored out as unhealthy.  This will occur until the manual setup below been performed.  If this occurs, you will need to rerun the ```docker compose up``` commmand.  The Mend repo integration containers will not start unless the Graylog healthcheck passes which runs every 30 secs which occurs on every startup.
  - Run `docker compose logs --follow` in a terminal to get the username and password for first time login
  - Navigate to http://your-host-ip-address:9000 and log in with username: `admin` and password: `the password shown in the graylog logs`
  - Follow the setup steps and keep all of the defaults.  Be sure to go through all the steps of creating and installing a CA.
  - After clicking "resume setup" all containers should be created and healthy and Graylog will automatically install the Mend Content Pack and start accepting input from the integrations which will also start  
  - Log into the platform with with the username: admin and the password you set in `$graylog_root_password`  
  - Click the Dashboards link at the top and view the Controller, Scanner, and Remediate Search Dashboards to ensure the integration is running, and Graylog is ingesting messages from the integration
    - Search for ```Controller Startup Checks``` in the Controller Search Dashbord to see the Mend Repo Integration Startup table


- Features of the Mend Graylog Content Pack  
  - An input for all of the repo integration logs  
    - Extractors that allow for easy parsing of the repo integration logs  
  - Inputs for container stats (CPU/Memory usage)
  - Pipelines to calculate CPU/Memory Usage
  - Alerts for Controller stats + Scan Queue
  - Two inputs that send API requests periodically for the Scanner and Remediate containers healthcheck endpoints  
  - Dashboards for searching the integration containers individually  
  - Dashboards showing statistics pulled from the healthcheck API inputs  

## Stopping the Integration

In the event that the integration needs to be stopped, please use the command: `docker compose -f <docker-compose.yaml file> down` to stop the integration. This will ensure that graylog stops gracefully and no data corruption occurs.

## Basic Troubleshooting for Graylog
Removing Graylog volumes
```shell
docker compose down
docker volume rm $(docker volume ls | grep graylog | cut -d ' ' -f6)
docker volume rm self-managed_mongodb_data
```
