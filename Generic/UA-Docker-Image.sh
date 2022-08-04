#!/bin/bash
# Generic example for scanning docker images with the WhiteSource Unified Agent
# Glob patterns used scan all pulled images with repository name containing "ubuntu"
# Scans only the pulled immage "maven:3.8-openjdk-8"
# See docker.includes & docker.excludes sections section for more detail - https://whitesource.atlassian.net/wiki/spaces/WD/pages/1544880156/Unified+Agent+Configuration+Parameters#Docker-Images
# Scans are only done on repository name, tag version, or image id.  Not repositoryname + tag
# For specific scans Image ID is recommended using the following - replace maven:3.8-openjdk-8 with your repository name + tag
# export WS_DOCKER_INCLUDES=$(docker images maven:3.8-openjdk-8 -q)

docker pull ubuntu:latest 
docker pull maven:3.8-openjdk-8

export WS_APIKEY=<your-api-key>
export WS_USERKEY=<your-user-key>
export WS_PRODUCTNAME=<your-product-name>
export WS_PROJECTNAME=doesnotmatter
export WS_WSS_URL=https://saas.whitesourcesoftware.com/agent
export WS_DOCKER_INCLUDES=.*ubuntu.*
export WS_DOCKER_SCANIMAGES=true
export WS_DOCKER_LAYERS=true
export WS_DOCKER_PROJECTNAMEFORMAT=repositoryNameAndTag
export WS_ARCHIVEEXTRACTIONDEPTH=2
export WS_ARCHIVEINCLUDES='**/*war **/*ear **/*zip **/*whl **/*tar.gz **/*tgz **/*tar **/*car **/*jar'
curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
echo Unified Agent downloaded successfully
if [[ "$(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256)" != "$(sha256sum wss-unified-agent.jar)" ]] ; then
    echo "Integrity Check Failed"
else
    echo "Integrity Check Passed"
    echo Starting WhiteSource Scan
    java -jar wss-unified-agent.jar
fi