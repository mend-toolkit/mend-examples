#!/bin/bash

SCM=$1
MEND_DIR=$HOME/mend
BASE_DIR=$MEND_DIR/$SCM
REPO_INTEGRATION_DIR=$(pwd)

rm -rf $BASE_DIR && mkdir -p $BASE_DIR

# echo error colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'


function scm(){
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
echo "${grn}$AGENT_FILE is the agent${end}"
mkdir $BASE_DIR/untar
tar -xvf $BASE_DIR/$AGENT_TAR -C $BASE_DIR/untar
rm $BASE_DIR/$AGENT_TAR
cd $BASE_DIR/untar
AGENT_LATEST=$(ls -d */)
echo "${grn}$AGENT_LATEST is the latest agent${end}"
cd $BASE_DIR
mkdir $BASE_DIR/latest
mv $BASE_DIR/untar/$AGENT_LATEST* $BASE_DIR/latest
rm -rf $BASE_DIR/untar


## Grab scanner tags
TAG=$(grep -v ^\# ${BASE_DIR}/latest/build.sh | grep . | awk -F "[ ]" 'NR==1 {print $4}' | awk -F ":" '{print $2}')
SCANNER=$(grep -v ^\# ${BASE_DIR}/latest/build.sh | grep . | awk -F "[ ]" 'NR==2 {print $4}'| awk -F ":" '{print $2}')
rm -rf ${REPO_INTEGRATION_DIR}/.env
echo "TAG=${TAG}" >> ${REPO_INTEGRATION_DIR}/.env
echo "SCANNER=${SCANNER}" >> ${REPO_INTEGRATION_DIR}/.env
echo "MEND_DIR=${MEND_DIR}" >> ${REPO_INTEGRATION_DIR}/.env
echo "BASE_DIR=${BASE_DIR}" >> ${REPO_INTEGRATION_DIR}/.env
echo "SCM=$SCM" >> ${REPO_INTEGRATION_DIR}/.env

## Create Docker Network
DNETWORK=$(docker network ls -f name=${SCM}_bridge)
if [ -z "$DNETWORK" ]
then
    echo "${yel}Docker Network does not exist${end}"
    docker network create -d bridge ${SCM}_bridge
    echo "${cyn}Docker Network ${SCM}_bridge created${end}"
else
    echo "${cyn}Docker Network ${SCM}_bridge already exists${end}"
fi

echo "${grn}Download Success!!!  Please use the following command to add your activation key to a local repo_settings.env file${end}"
echo "${cyn}echo \"WS_ACTIVATION_KEY=replace-with-your-activation-key\" > ${MEND_DIR/${SCM}_settings.env${end}"

}

if [ -z "$1"]
then 
    echo "${red}Please pass an scm variable such as gls, bb, or ghe${end}"
else
    scm
fi