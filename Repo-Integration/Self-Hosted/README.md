![Logo](https://mend-toolkit-resources-public.s3.amazonaws.com/img/mend-io-logo-horizontal.svg)  

# Self-Hosted Repository Integration Automation Scripts
When used, these scripts will download the latest repository integration run via docker compose:
- Remediate Server
- Controller
- Scanner

## Supported Operating Systems
- **Linux (Bash):**	CentOS, Debian, Ubuntu, RedHat

## Prerequisites
- Docker, Docker Compose, git, wget, SCM Repository instance up and running

## Options
`setup.sh` options: **ghe**, **gls**, **bb**

Options Defined:  
**ghe** - GitHub Enterprise

**gls** - GitLab (self-hosted)

**bb** - Bitbucket Server

Supplying a self-signed or other unverifiable PK cert for GitHub, GitLab, or Bitbucket:

`setup.sh <option> <certificate_file.crt>`  **Note:** Certificate file **must** have an extension of .crt and have a first line equal to `-----BEGIN CERTIFICATE-----`

## Execution
Execution instructions:  

- Clone the repository & give setup.sh permissions to run

```git clone https://github.com/mend-toolkit/mend-examples.git && cd mend-examples/Repo-Integration && chmod +x setup.sh```
- Add your activation key as an environment variable which will be copied to the .env file which is created by setup.sh

```export ws_key='your activation key between single quotes'```
- Run the setup.sh script for your appropriate source control management system as shown in options above

```./setup.sh <option>```, or ```./setup.sh <option> <certificate_file.crt>``` if supplying a self-signed or other cert.
- Run docker compose depending on how it was installed

```docker-compose up``` 

- Run docker compose in detached mode depending on how it was installed.

```docker-compose up -d```
