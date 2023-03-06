#!/bin/bash

#### Prerequisite commands & installs
# apt-get update
# apt-get install -y curl git openjdk-8-jdk nano

#### Install Maven
# curl -LJO https://mirrors.ocf.berkeley.edu/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
# tar -xvf ./apache-maven-3.6.3-bin.tar.gz -C /opt
# ln -s /opt/apache-maven-3.6.3 /opt/maven
# rm ./apache-maven-3.6.3-bin.tar.gz 
# nano /etc/profile.d/maven.sh

## Add the following into the maven.sh file and change jdk
# export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
# export M2_HOME=/opt/maven
# export MAVEN_HOME=/opt/maven
# export PATH=${M2_HOME}/bin:${PATH}
# export MAVEN_CONFIG=/root/.m2

## Make the script runable
# chmod +x /etc/profile.d/maven.sh
# source /etc/profile.d/maven.sh
# mvn -version

#### Clone your repo & run script
# git clone <your repository> && cd ./<your repository>
# chmod +x ./prioritize.sh
# ./prioritize.sh

#### Build application & check JAVA_HOME
echo JAVA_HOME: $JAVA_HOME
mvn clean install -DskipTests=true

#### Run WS Prioritize
curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
echo Unified Agent downloaded successfully
# replace .war with .jar or .ear if needed
export WARFILE=$(find ./ -type f -wholename "*/target/*.war")
echo $WARFILE will be added to appPath
export WS_APIKEY=<your-api-key>
export WS_USERKEY=<your-user-key>
export WS_WSS_URL=https://saas.mend.io/agent
export WS_ENABLEIMPACTANALYSIS=true
export WS_RESOLVEALLDEPENDENCIES=false
export WS_MAVEN_RESOLVEDEPENDENCIES=true
export WS_MAVEN_AGGREGATEMODULES=true
export WS_FILESYSTEMSCAN=false
export WS_PRODUCTNAME=$(git config --get remote.origin.url | awk -F "/" '{print $4}')
export WS_PROJECTNAME=$(git config --get remote.origin.url | awk -F "/" '{print $5}' | awk -F "." '{print $1}')-Prioritize
java -jar wss-unified-agent.jar -appPath $WARFILE -d ./
