#!/bin/bash

#### Prerequisite commands & installs
# apt-get update
# apt-get install -y curl git openjdk-8-jdk nano

#### Clone your repo & run script
# git clone <your repository> && cd ./<your repository>
# chmod +x ./prioritize.sh
# ./prioritize.sh

#### Build application & check JAVA_HOME
echo  JAVA_HOME:$JAVA_HOME
./gradlew build -x test

#### Run WS Prioritize
curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
echo Unified Agent downloaded successfully
if [[ "$(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256)" != "$(sha256sum wss-unified-agent.jar)" ]] ; then
    echo "Integrity Check Failed"
else
    echo "Integrity Check Passed"
fi
# replace .war with .ear or the following for WARFILE if needed
# JARFILE=$(find ./build/libs -type f -wholename "*.jar" ! -wholename "*javadoc*" ! -wholename "*groovydoc*" ! -wholename "*sources*")
export WARFILE=$(find ./build/libs -type f -wholename "*.war")
echo $WARFILE will be added to appPath
echo Starting WhiteSource Prioritize Scan
export WS_APIKEY=<your-api-key>
export WS_USERKEY=<your-user-key>
export WS_WSS_URL=https://saas.mend.io/agent
export WS_ENABLEIMPACTANALYSIS=true
export WS_RESOLVEALLDEPENDENCIES=false
export WS_GRADLE_RESOLVEDEPENDENCIES=true
export WS_GRADLE_AGGREGATEMODULES=true
export WS_FILESYSTEMSCAN=false
export WS_PRODUCTNAME=$(git config --get remote.origin.url | awk -F "/" '{print $4}')
export WS_PROJECTNAME=$(git config --get remote.origin.url | awk -F "/" '{print $5}' | awk -F "." '{print $1}')-Prioritize
java -jar wss-unified-agent.jar -appPath $WARFILE -d ./
