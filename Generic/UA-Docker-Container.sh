#!/bin/bash
# Generic example for scanning docker containers with the Mend Unified Agent
# Glob patterns used scan all pulled images with repository name containing "ubuntu"
# See docker.containerIncludes & docker.containerExcludes sections for more detail - https://docs.mend.io/bundle/unified_agent/page/unified_agent_configuration_parameters.html#Docker-Containers
# For specific scans container ID is recommended

docker pull ubuntu:latest 
docker run --name ubuntu-scan -i -d ubuntu:latest

export WS_APIKEY=<your-api-key>
export WS_USERKEY=<your-user-key>
export WS_PRODUCTNAME=<your-product-name>
export WS_PROJECTNAME=doesnotmatter
export WS_WSS_URL=https://saas.whitesourcesoftware.com/agent
export WS_DOCKER_CONTAINERINCLUDES=.*ubuntu.*
export WS_DOCKER_SCANCONTAINERS=true
export WS_ARCHIVEEXTRACTIONDEPTH=2
export WS_ARCHIVEINCLUDES='**/*war **/*ear **/*zip **/*whl **/*tar.gz **/*tgz **/*tar **/*car **/*jar'
curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
echo Mend Unified Agent downloaded successfully
if [[ "$(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256)" != "$(sha256sum wss-unified-agent.jar)" ]] ; then
    echo "Integrity Check Failed"
else
    echo "Integrity Check Passed"
    echo Starting Mend Scan
    java -jar wss-unified-agent.jar
fi

docker stop ubuntu-scan