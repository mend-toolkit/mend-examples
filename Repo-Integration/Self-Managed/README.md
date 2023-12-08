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
2) Lunch and remote into instance (ssh or console)
3) Install Docker ([using the apt repository](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository))

      a. Set up the Docker repository

       ````bash
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
       ````

      b. Install Docker
      
       ```bash
       sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
       ```
  
      c. Setup up Docker for use as non-root user
   
       ```bash
       sudo usermod -aG docker $USER
       newgrp docker
       ```
  
      d. Continue with steps below
    		
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
- Add your activation key as an environment variable which will be copied to the .env file which is created by setup.sh

```export ws_key='your activation key between single quotes'```

- Add your Github.com access token. This is important for Remediate and Renovate to prevent Gitbub rate-limiting imposed on non-authenticated requests.

`export GITHUB_COM_TOKEN='replace-with-your-github-token-inside-single-quotes'`
  
- Run the setup.sh script for your appropriate source control management system as shown in options above

- Run docker compose depending on how it was installed. Options defined -
  - SCA only  - docker-compose.yaml
  - SCA and SAST - docker-compose-sast.yaml
    - **Note: this is currently only supported for GHE** [(a dedicated SAST scanner container)](https://docs.mend.io/bundle/integrations/page/deploy_with_docker.html#Target-Machine:-Run-the-Containers).

```docker compose -f <compose file> up```

- Run docker compose in detached mode depending on how it was installed.

```docker compose -f <compose file> up -d```

