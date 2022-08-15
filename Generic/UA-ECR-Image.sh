#!/bin/bash
# Generic example for scanning docker images with the Mend Unified Agent from Amazon Elastic Container Registry
# Glob patterns used scans & pulls all images with repositoryName containing "ubuntu"
# docker.pull.tags can be used instead of docker.pull.images - the default pulls all tags with associated images
# See docker.includes & docker.excludes sections for more detail - https://docs.mend.io/bundle/unified_agent/page/unified_agent_configuration_parameters.html#Docker-Images

# Ensure the aws cli is configured with the correct login information - https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
# aws configure

# Ensure docker is logged in to AWS - # https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html
# aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com

# default images pulled is 10 - uncomment and change below value for more
# export WS_DOCKER_PULL_MAXIMAGES=10 

# docker pull commands are not run with sudo by default - uncomment below if sudo is needed
#export WS_DOCKER_LOGIN_SUDO=true

IMAGES=.*ubuntu.*
export WS_APIKEY=<your-api-key>
export WS_USERKEY=<your-user-key>
export WS_PRODUCTNAME=<your-product-name>
export WS_PROJECTNAME=doesnotmatter
export WS_WSS_URL=https://saas.whitesourcesoftware.com/agent
export WS_DOCKER_AWS_ENABLE=true
export WS_DOCKER_PULL_ENABLE=true
export WS_DOCKER_PULL_IMAGES=$IMAGES
export WS_DOCKER_AWS_REGISTRYID=<your-aws-account-id>
export WS_DOCKER_INCLUDES=$IMAGES
export WS_DOCKER_SCANIMAGES=true
export WS_DOCKER_LAYERS=true
export WS_DOCKER_PROJECTNAMEFORMAT=repositoryNameAndTag
export WS_FILESYSTEMSCAN=false
export WS_ARCHIVEEXTRACTIONDEPTH=2
export WS_ARCHIVEINCLUDES='**/*war **/*ear **/*zip **/*whl **/*tar.gz **/*tgz **/*tar **/*car **/*jar'
curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
echo Unified Agent downloaded successfully
if [[ "$(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256)" != "$(sha256sum wss-unified-agent.jar)" ]] ; then
    echo "Integrity Check Failed"
else
    echo "Integrity Check Passed"
    echo Starting Mend Scan
    java -jar wss-unified-agent.jar
fi 