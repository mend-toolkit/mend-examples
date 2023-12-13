#!/bin/bash

SCM=$1
VERSION=$2
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

if [ -z $VERSION ]; then
        VERSION="latest"
    else
        DASH_VERSION="-$VERSION"
fi

echo "${blu}Version requested: $SCM:$VERSION${end}"

# Fetch Integration
case $SCM in
    gls)
    AGENT_PATH="Agent-for-GitLab-Enterprise"
    AGENT_TAR="agent-4-gitlab-server$DASH_VERSION.tar.gz"
    ;;

    bb)
    AGENT_PATH="Agent-for-BitBucket"
    AGENT_TAR="agent-4-bitbucket$DASH_VERSION.tar.gz"
    ;;

    ghe)
    AGENT_PATH="Agent-for-GitHub-Enterprise"
    AGENT_TAR="agent-4-github-enterprise$DASH_VERSION.tar.gz"
    ;;

esac

## Dowload agent file and copy to version
wget https://integrations.mend.io/release/$AGENT_PATH/$AGENT_TAR -P $BASE_DIR
if [ $? -ne 0 ]; then
	echo "${red}Download failed: Check if requested version exists, network issues, or other probelms.${end}"
	exit
fi
AGENT_FILE=$(basename $AGENT_TAR .tar.gz)
echo "${grn}$AGENT_FILE is the agent${end}"
mkdir $BASE_DIR/untar
tar -xvf $BASE_DIR/$AGENT_TAR -C $BASE_DIR/untar
rm $BASE_DIR/$AGENT_TAR
cd $BASE_DIR/untar
DOWNLOADED_VERSION=$(ls -d */)
echo "${grn}$DOWNLOADED_VERSION is the agent version${end}"
cd $BASE_DIR
mkdir $BASE_DIR/$VERSION
mv $BASE_DIR/untar/$DOWNLOADED_VERSION* $BASE_DIR/$VERSION
rm -rf $BASE_DIR/untar


# Copy Activation Key & update with fake value
cp ${BASE_DIR}/$VERSION/wss-configuration/config/prop.json ${BASE_DIR}/prop.json
sed -i 's/your-activation-key/fakevalue/1' ${BASE_DIR}/prop.json
echo "${grn}${MEND_DIR}/prop.json created successfully${end}"

# Add Graylog Password and Secret
GRAYLOG_PASSWORD_SECRET="$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 64; echo)"
GRAYLOG_ROOT_PASSWORD_SHA2="$(echo -n ${GRAYLOG_ROOT_PASSWORD} | shasum -a 256 | cut -d ' ' -f 1)"

## Grab scanner tags
CONTROLLER=$(grep -v ^\# ${BASE_DIR}/$VERSION/build.sh | grep . | awk -F "[ ]" 'NR==1 {print $4}' | awk -F ":" '{print $2}')
SCANNER=$(grep -v ^\# ${BASE_DIR}/$VERSION/build.sh | grep . | awk -F "[ ]" 'NR==2 {print $4}'| awk -F ":" '{print $2}')
REMEDIATE=$(grep -v ^\# ${BASE_DIR}/$VERSION/build.sh | grep . | awk -F "[ ]" 'NR==3 {print $4}' | awk -F ":" '{print $2}')
rm -rf ${REPO_INTEGRATION_DIR}/.env
echo "CONTROLLER=${CONTROLLER}" >> ${REPO_INTEGRATION_DIR}/.env
echo "SCANNER=${SCANNER}" >> ${REPO_INTEGRATION_DIR}/.env
echo "REMEDIATE=${REMEDIATE}" >> ${REPO_INTEGRATION_DIR}/.env
echo "MEND_DIR=${MEND_DIR}" >> ${REPO_INTEGRATION_DIR}/.env
echo "BASE_DIR=${BASE_DIR}" >> ${REPO_INTEGRATION_DIR}/.env
echo "VERSION=$VERSION" >> ${REPO_INTEGRATION_DIR}/.env
echo "SCM=$SCM" >> ${REPO_INTEGRATION_DIR}/.env
echo "WS_ACTIVATION_KEY=${ws_key}" >> ${REPO_INTEGRATION_DIR}/.env
echo "GITHUB_COM_TOKEN=${github_com_token}" >> ${REPO_INTEGRATION_DIR}/.env
echo "EXTERNAL_LOG_IN_CONSOLE=true" >> ${REPO_INTEGRATION_DIR}/.env
echo "LOG_FORMAT=json" >> ${REPO_INTEGRATION_DIR}/.env
echo "GRAYLOG_PASSWORD_SECRET=${GRAYLOG_PASSWORD_SECRET}" >> ${REPO_INTEGRATION_DIR}/.env
echo "GRAYLOG_ROOT_PASSWORD_SHA2=${GRAYLOG_ROOT_PASSWORD_SHA2}" >> ${REPO_INTEGRATION_DIR}/.env

## use for versions < 23.10.2 ## https://whitesource.atlassian.net/wiki/spaces/MEND/pages/2524153813/Advanced+Technical+Information ##
## echo "WS_UA_LOG_IN_CONSOLE=true" >> ${REPO_INTEGRATION_DIR}/.env

##  SAST related settings
rm -rf ${REPO_INTEGRATION_DIR}/.env-sast
echo "WS_SAST_SCAN_PREFIX=SAST_" >> ${REPO_INTEGRATION_DIR}/.env-sast

echo "${grn}Download Success!!!${end}"

}

function key_check(){
## Look for Activation Key and github.com token
if [ -z "${ws_key}" ] && [ -z "${WS_KEY}" ]
then
    echo "${red}Please set your Activation Key as an environment variable using the following command in order to create the prop.json${end}"
    echo "${cyn}export WS_KEY='replace-with-your-activation-key-inside-single-quotes'${end}"
    exit
fi

if [ -z "${ws_key}" ]
then
    ws_key=${WS_KEY}
fi

if [ -z "${github_com_token}" ] && [ -z "${GITHUB_COM_TOKEN}" ]
then
    echo "${red}Please set your github.com access token as an environment variable using the following command:${end}"
    echo "${cyn}export GITHUB_COM_TOKEN='replace-with-your-github-token-inside-single-quotes'${end}"
    exit
fi

if [ -z "${github_com_token}" ]
then
    github_com_token=${GITHUB_COM_TOKEN}
fi

if [ -z "${graylog_root_password}" ] && [ -z "${GRAYLOG_ROOT_PASSWORD}" ]
then
    echo "${red}Please set your Graylog Root Password by using the following command. This will be used to log in as admin after creating the instance:${end}"
    echo "${cyn}export GRAYLOG_ROOT_PASSWORD='replace-with-your-desired-password-inside-single-quotes'${end}"
    exit
fi

if [ -z "${graylog_root_password}" ]
then
    graylog_root_password=${GRAYLOG_ROOT_PASSWORD}
fi

scm

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


