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

## Dowload agent file and copy to latest
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

# Copy Activation Key
jq --arg ws_key $ws_key '(.properties[] | select(.propertyName=="bolt.op.activation.key")).propertyValue |= $ws_key' ${BASE_DIR}/latest/wss-configuration/config/prop.json > ${BASE_DIR}/prop.json
echo "${grn}${MEND_DIR}/prop.json created successfully${end}"

## Grab scanner tags
CONTROLLER=$(grep -v ^\# ${BASE_DIR}/latest/build.sh | grep . | awk -F "[ ]" 'NR==1 {print $4}' | awk -F ":" '{print $2}')
SCANNER=$(grep -v ^\# ${BASE_DIR}/latest/build.sh | grep . | awk -F "[ ]" 'NR==2 {print $4}'| awk -F ":" '{print $2}')
REMEDIATE=$(grep -v ^\# ${BASE_DIR}/latest/build.sh | grep . | awk -F "[ ]" 'NR==3 {print $4}' | awk -F ":" '{print $2}')
rm -rf ${REPO_INTEGRATION_DIR}/.env
echo "CONTROLLER=${CONTROLLER}" >> ${REPO_INTEGRATION_DIR}/.env
echo "SCANNER=${SCANNER}" >> ${REPO_INTEGRATION_DIR}/.env
echo "REMEDIATE=${REMEDIATE}" >> ${REPO_INTEGRATION_DIR}/.env
echo "MEND_DIR=${MEND_DIR}" >> ${REPO_INTEGRATION_DIR}/.env
echo "BASE_DIR=${BASE_DIR}" >> ${REPO_INTEGRATION_DIR}/.env
echo "SCM=$SCM" >> ${REPO_INTEGRATION_DIR}/.env

## Create Docker Network
DNETWORK=$(docker network ls -f name=${SCM}_bridge -q)
if [ -z "$DNETWORK" ]
then
    echo "${yel}Docker Network does not exist${end}"
    docker network create -d bridge ${SCM}_bridge
    echo "${cyn}Docker Network ${SCM}_bridge created${end}"
else
    echo "${cyn}Docker Network ${SCM}_bridge already exists with Network ID ${DNETWORK}${end}"
fi

echo "${grn}Download Success!!!${end}"

}

function key_check(){
## Look for Activation Key
if [ -z "${ws_key}" ]
then
    echo "${red}Please set your Activation Key as an environment variable using the following command in order to create the prop.json${end}"
    echo "${cyn}export ws_key='replace-with-your-activation-key-inside-single-quotes'${end}"
    exit
else
    jq_exists
fi

}

function jq_exists(){
## Check if jq exists on the machine
. /etc/os-release
OS=$(echo "$NAME")
PKG="jq"
if [ "$OS" = "Ubuntu" ]
then 
    DEBIAN_CHECK=$(dpkg-query -W --showformat='${Status}\n' $PKG|grep "install ok installed")
        if [ "" = "$DEBIAN_CHECK" ]
        then
            echo "${red}jq could not be found please install with the following command${end}"
            echo "${cyn}sudo apt install jq${end}"
        else
            scm
        fi

elif [ "$OS" = "Amazon Linux" ]
then
    RPM_CHECK=$(rpm -qa | grep ${PKG})
        if [ -z "$RPM_CHECK" ]
        then
            echo "${red}jq could not be found please install with one the following command${end}"
            echo "${cyn}sudo yum install jq${end}"
        else
            scm
        fi
else
    echo "${red}Your OS is not supported, please open a Github issue${end}"
    exit
fi
}

if [ -z "$1" ]
then
    echo "${red}Please pass an scm variable such as gls, bb, or ghe${end}"
else
    if [ "$1" = "gls" ] || [ "$1" = "bb" ] || [ "$1" = "ghe" ]
        then 
            ## Check for valid key and start the process
            key_check
        else
            echo "${red}Please pass an scm variable such as gls, bb, or ghe${end}"
            exit
        fi
fi


