#!/bin/bash

#GLOBALS
# echo colors you can use these by adding ${<color>} in your echo commands.
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'


# These are variables that are set by get_commandline_flags() Do not set these here.
VERSION=""
SCM=""
USE_GRAYLOG=1
AGENT_PATH=""
AGENT_TAR=""
MEND_DIR=""
BASE_DIR=""
SHELLTYPE=""

REPO_INTEGRATION_DIR=$(pwd)

# GetOpts commandline flag parsing in Bash isn't great, so we can't have it in a function
SCM="$1"
shift 1

while getopts "h:v:g" flag; do
case $flag in
    h)
	print_usage
	exit 1
	;;
    v)
	VERSION="$OPTARG"
	;;
    g)
	USE_GRAYLOG=0
	;;
esac
done

function print_usage() {
    echo "${red}Usage: $0 <scm> [-v] [-g]"
    echo -e "-v\t\tThe version of the integration you would like to use."
    echo -e "-g\t\tSpecify to not use graylog when spinning up the integration."

    echo -e "\nIntegration Options:"
    echo -e "\tghe - GitHub Enterprise"
    echo -e "\tgls - GitLab Server"
    echo -e "\tbb - BitBucket Server${end}"
}


function get_commandline_flags(){
    if [[ "$VERSION" != "" ]]; then
        VERSION="-$VERSION"
    fi

    case $SCM in
        ghe)
            AGENT_PATH="Agent-for-GitHub-Enterprise"
            AGENT_TAR="agent-4-github-enterprise$VERSION.tar.gz"
            ;;
        bb)
            AGENT_PATH="Agent-for-BitBucket"
            AGENT_TAR="agent-4-bitbucket$VERSION.tar.gz"
            ;;
        gls)
            AGENT_PATH="Agent-for-GitLab-Enterprise"
            AGENT_TAR="agent-4-gitlab-server$VERSION.tar.gz"
            ;;
        *)
            print_usage
            exit 1
            ;;
    esac

    if [[ "$VERSION" != "" ]]; then
        VERSION=${VERSION:1}
    else
        VERSION="latest"
    fi

    # Reference Directories
    MEND_DIR=$HOME/mend
    BASE_DIR=$MEND_DIR/$SCM
}

function env_port_check() {
    ## Check if operating system is Ubuntu
    lsb_release 2>&1 >/dev/null

    if [[ $? -ne 0 ]] || [[ $(lsb_release -is | grep Ubuntu) -ne "Ubuntu" ]]; then
        if [[ $(uname | grep -o ^MINGW64_NT) == "MINGW64_NT" ]]; then
          echo gitbash
          exit 1
        else
          echo "This script is only supported on Ubuntu and Git Bash for Windows distributions"
          exit 1
        fi
    fi

    ## Check if docker version > 18
    DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' | cut -d '.' -f 1)
    if [[ $DOCKER_VERSION -le 18 ]]; then
        echo "Docker version is not greater than 18. Please install docker by following the README"
        exit 1
    fi

    ## Check if docker compose version >= 2
    DOCKER_COMPOSE_VERSION=$(docker compose version --short | cut -d '.' -f 1)
    if [[ $DOCKER_COMPOSE_VERSION -lt 2 ]]; then
        echo "Docker Compose version is less than 2. Please install docker compose by following the README"
        exit 1
    fi

    # Get public IP Address
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)

    # Define the array of externally facing ports to check
    EXTERNAL_PORTS=(5678)

    if [[ $USE_GRAYLOG -eq 1 ]]; then
        EXTERNAL_PORTS+=(9000)
    fi

    for PORT in "${EXTERNAL_PORTS[@]}"; do
        # Start a listener on the designated port in the background, storing the process ID
        echo "Listening on: $PORT"
        nc -lp $PORT &

        # Check for connection success
        echo "Testing connection to: $PUBLIC_IP:$PORT"
        nc -z $PUBLIC_IP $PORT

        # Store the connection check result
        CONNECTION_RESULT=$?
        if [[ $CONNECTION_RESULT -ne 0 ]]; then
            echo "Connection Failed. Exiting..."
            exit 1
        else
            echo "Connection Result: Success"
        fi
    done
}

function env_variable_check(){
    # Look for Activation Key / Github.com token / Graylog Root Password
    if [ -z "${ws_key}" ] && [ -z "${WS_KEY}" ]; then
        echo "${red}Please set your Activation Key as an environment variable using the following command.${end}"
        echo "${cyn}export WS_KEY='replace-with-your-activation-key-inside-single-quotes'${end}"
        exit
    fi

    if [ -z "${ws_key}" ]; then
        ws_key=${WS_KEY}
    fi

    if [ -z "${github_com_token}" ] && [ -z "${GITHUB_COM_TOKEN}" ]; then
        echo "${red}Please set your github.com access token as an environment variable using the following command:${end}"
        echo "${cyn}export GITHUB_COM_TOKEN='replace-with-your-github-token-inside-single-quotes'${end}"
        exit
    fi

    if [ -z "${github_com_token}" ]; then
        github_com_token=${GITHUB_COM_TOKEN}
    fi

    if [[ $USE_GRAYLOG -eq 1 ]]; then
        if [ -z "${graylog_root_password}" ] && [ -z "${GRAYLOG_ROOT_PASSWORD}" ]; then
            echo "${red}Please set your Graylog Root Password by using the following command. This will be used to log in as admin after creating the instance:${end}"
            echo "${cyn}export GRAYLOG_ROOT_PASSWORD='replace-with-your-desired-password-inside-single-quotes'${end}"
            exit
        fi

        if [ -z "${graylog_root_password}" ]; then
            graylog_root_password=${GRAYLOG_ROOT_PASSWORD}
        fi
    fi
}

function download_file() {
    mkdir -p $BASE_DIR/$VERSION
    curl -s -o $BASE_DIR/$AGENT_TAR  https://integrations.mend.io/release/$AGENT_PATH/$AGENT_TAR 

    if [[ $? -ne 0 ]]; then
        echo "${red}Download failed: Check if requested version exists, network issues, or other problems.${end}"
        exit
    fi

    tar -xf $BASE_DIR/$AGENT_TAR --strip-components=1 -C $BASE_DIR/$VERSION
    rm -rf $BASE_DIR/$AGENT_TAR
}

function create_env_file() {

    ## Grab container tags
    CONTROLLER=$(grep -v ^\# ${BASE_DIR}/$VERSION/build.sh | grep . | awk -F "[ ]" 'NR==1 {print $4}' | awk -F ":" '{print $2}')
    SCANNER=$(grep -v ^\# ${BASE_DIR}/$VERSION/build.sh | grep . | awk -F "[ ]" 'NR==2 {print $4}'| awk -F ":" '{print $2}')
    REMEDIATE=$(grep -v ^\# ${BASE_DIR}/$VERSION/build.sh | grep . | awk -F "[ ]" 'NR==3 {print $4}' | awk -F ":" '{print $2}')

    ## Copy prop.json to $BASE_DIR
    cp $BASE_DIR/$VERSION/wss-configuration/config/prop.json $BASE_DIR

    rm -rf $REPO_INTEGRATION_DIR/.env

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
    echo "MEND_ADVANCED_MERGE_CONFIDENCE_ENABLED=true" >> ${REPO_INTEGRATION_DIR}/.env

    if [[ $USE_GRAYLOG -eq 1 ]]; then
        # Add Graylog Password and Secret
        GRAYLOG_PASSWORD_SECRET="$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 64; echo)"
        GRAYLOG_ROOT_PASSWORD_SHA2="$(echo -n ${graylog_root_password} | shasum -a 256 | cut -d ' ' -f 1)"

        # Move Graylog Content Pack to Mend directory
        rm -rf ${MEND_DIR}/graylog
        mkdir -p ${MEND_DIR}/graylog
        cp ${REPO_INTEGRATION_DIR}/mend-graylog-content-pack.json ${MEND_DIR}/graylog/mend-graylog-content-pack.json

        echo "LOG_FORMAT=json" >> ${REPO_INTEGRATION_DIR}/.env
	echo "LOG_FORMAT_JSON=true" >> ${REPO_INTEGRATION_DIR}/.env
	echo "LOG_JSON_LEVEL=DEBUG" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_NODE_ID_FILE=/usr/share/graylog/data/data/node_id" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_HTTP_BIND_ADDRESS=0.0.0.0:9000" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_HTTP_EXTERNAL_URI=http://localhost:9000/" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_MONGODB_URI=mongodb://mongodb:27017/graylog" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_MESSAGE_JOURNAL_DIR=journal" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_CONTENT_PACKS_AUTO_INSTALL=mend-graylog-content-pack.json" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_CONTENT_PACKS_DIR=data/contentpacks" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_CONTENT_PACKS_LOADER_ENABLED=true" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_PASSWORD_SECRET=${GRAYLOG_PASSWORD_SECRET}" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_ROOT_PASSWORD_SHA2=${GRAYLOG_ROOT_PASSWORD_SHA2}" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_DATANODE_NODE_ID_FILE=/var/lib/graylog-datanode/node-id" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_DATANODE_PASSWORD_SECRET=${GRAYLOG_PASSWORD_SECRET}" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_DATANODE_ROOT_PASSWORD_SHA2=${GRAYLOG_ROOT_PASSWORD_SHA2}" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_DATANODE_MONGODB_URI=mongodb://mongodb:27017/graylog" >> ${REPO_INTEGRATION_DIR}/.env
        echo "GRAYLOG_DATANODE_DATA_DIR=/var/lib/graylog-datanode" >> ${REPO_INTEGRATION_DIR}/.env
    else
        echo "Moving docker-compose-no-graylog.yaml to docker-compose.yaml"
        mv docker-compose.yaml docker-compose-graylog.yaml
        mv docker-compose-no-graylog.yaml docker-compose.yaml
    fi

    ##  SAST related settings
    rm -rf ${REPO_INTEGRATION_DIR}/.env-sast
    echo "WS_SAST_SCAN_PREFIX=SAST_" >> ${REPO_INTEGRATION_DIR}/.env-sast
}

## Parse Command Line Flags
get_commandline_flags

## Check if environment has prerequisite binaries and ports open
echo "${mag}Checking Ports for availability${end}"
env_port_check

## Check if the appropriate environment variables are set
echo "${mag}Checking environment variables${end}"
env_variable_check

## Download the integration and unzip it
echo "${mag}Downloading Integration Archive${end}"
download_file

## Create the environment variable file
echo "${mag}Creating .env file${end}"
create_env_file

echo "${grn}Setup Success!!!${end}"

if [[ $USE_GRAYLOG -eq 1 ]]; then
    echo -e "\n${cyn}Please run the following commands on your system to make appropriate memory changes for graylog:${end}"
    echo "${cyn}sudo sh -c 'echo \"vm.max_map_count=262144\" >> /etc/sysctl.conf'${end}"
    echo "${cyn}sudo sysctl -p${end}"
    echo "${cyn}You will also want to edit the docker.service file under /etc/systemd and add this to the ExecStart command:${end}"
    echo "${cyn}-H tcp://0.0.0.0.:2375"
fi
