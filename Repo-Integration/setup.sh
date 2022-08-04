#!/bin/bash
#Prereqs - sudo yum install wget jq
# export ws_key='<your-activation-key>'

SCM=$1
BASE_DIR=$HOME/mend/$SCM
REPO_INTEGRATION_DIR=$(pwd)

rm -rf $BASE_DIR && mkdir -p $BASE_DIR


# Fetch Integration
case $SCM in
    gls)
    AGENT_PATH="Agent-for-GitLab-Enterprise"
    AGENT_TAR="agent-4-gitlab-server.tar.gz"
    ;;

    bb)
    AGENT_PATH="Agent-for-BitBucket"
    AGENT_TAR="agent-4-bitbucket.tar.gz"
    ;;

    ghe)
    AGENT_PATH="Agent-for-GitHub-Enterprise"
    AGENT_TAR="agent-4-github-enterprise.tar.gz"
    ;;

esac

# Dowload agent file and copy to latest
wget https://integrations.mend.io/release/$AGENT_PATH/$AGENT_TAR -P $BASE_DIR
AGENT_FILE=$(basename $AGENT_TAR .tar.gz)
echo "$AGENT_FILE is the agent"
mkdir $BASE_DIR/untar 
tar -xvf $BASE_DIR/$AGENT_TAR -C $BASE_DIR/untar
cd $BASE_DIR/untar
AGENT_LATEST=$(ls -d */)
echo "$AGENT_LATEST is agent latest"
cd $BASE_DIR
mkdir $BASE_DIR/latest
mv $BASE_DIR/untar/$AGENT_LATEST* $BASE_DIR/latest
rm -rf $BASE_DIR/untar


# Copy License Key
jq --arg ws_key $ws_key '(.properties[] | select(.propertyName=="bolt.op.activation.key")).propertyValue |= $ws_key' ${BASE_DIR}/latest/wss-configuration/config/prop.json > ${BASE_DIR}/prop.json

## Grab scanner tags
TAG=$(grep -v ^\# ${BASE_DIR}/latest/build.sh | grep . | awk -F "[ ]" 'NR==1 {print $4}' | awk -F ":" '{print $2}')
SCANNER=$(grep -v ^\# ${BASE_DIR}/latest/build.sh | grep . | awk -F "[ ]" 'NR==2 {print $4}'| awk -F ":" '{print $2}')
rm -rf ${REPO_INTEGRATION_DIR}/.env
echo "TAG=${TAG}" >> ${REPO_INTEGRATION_DIR}/.env
echo "SCANNER=${SCANNER}" >> ${REPO_INTEGRATION_DIR}/.env
echo "BASE_DIR=${BASE_DIR}" >> ${REPO_INTEGRATION_DIR}/.env
echo "SCM=$SCM" >> ${REPO_INTEGRATION_DIR}/.env
