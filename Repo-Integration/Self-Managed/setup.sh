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
USE_GRAYLOG=1

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

    if [[ $USE_GRAYLOG -eq 1 ]]; then
        # Add Graylog Password and Secret
        GRAYLOG_PASSWORD_SECRET="$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 64; echo)"
        GRAYLOG_ROOT_PASSWORD_SHA2="$(echo -n ${graylog_root_password} | shasum -a 256 | cut -d ' ' -f 1)"

        # Move Graylog Content Pack to Mend directory
        rm -rf ${MEND_DIR}/graylog
        mkdir -p ${MEND_DIR}/graylog
        cp ${REPO_INTEGRATION_DIR}/mend-graylog-content-pack.json ${MEND_DIR}/graylog/mend-graylog-content-pack.json
    fi

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
    echo "MEND_ADVANCED_MERGE_CONFIDENCE_ENABLED=true" >> ${REPO_INTEGRATION_DIR}/.env
    echo "LOG_FORMAT=json" >> ${REPO_INTEGRATION_DIR}/.env

    if [[ $USE_GRAYLOG -eq 1 ]]; then
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
    fi

    ## use for versions < 23.10.2 ## https://whitesource.atlassian.net/wiki/spaces/MEND/pages/2524153813/Advanced+Technical+Information ##
    ## echo "WS_UA_LOG_IN_CONSOLE=true" >> ${REPO_INTEGRATION_DIR}/.env

    ##  SAST related settings
    rm -rf ${REPO_INTEGRATION_DIR}/.env-sast
    echo "WS_SAST_SCAN_PREFIX=SAST_" >> ${REPO_INTEGRATION_DIR}/.env-sast

    echo "${grn}Download Success!!!${end}"

    echo -e "\n${cyn}Please run the following commands on your system to make appropriate memory changes for graylog:${end}"
    echo "${cyn}sudo sh -c 'echo \"vm.max_map_count=262144\" >> /etc/sysctl.conf'${end}"
    echo "${cyn}sudo sysctl -p${end}"
    echo "${cyn}You will also want to edit the docker.service file under /etc/systemd and add this to the ExecStart command:${end}"
    echo "${cyn}-H tcp://0.0.0.0.:2375"
}

function env_check(){
    ## Check if operatins system is Ubuntu
    if [[ $(lsb_release -is) -ne "Ubuntu" ]]; then
        echo "This script is only supported on Ubuntu distributions"
        exit 1
    fi

    ## Check if docker version > 18
    DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' | cut -d '.' -f 1)
    if [[ $DOCKER_VERSION -gt 18 ]]; then
        echo "Docker version is greater than 18."
    else
        echo "Docker version is not greater than 18.  Please install docker by following the README"
        exit 1
    fi

    ## Check if docker compose version >= 2
    DOCKER_COMPOSE_VERSION=$(docker compose version --short | cut -d '.' -f 1)
    if [[ $DOCKER_COMPOSE_VERSION -ge 2 ]]; then
        echo "Docker Compose version is greater than or equal to 2."
    else
        echo "Docker Compose version is less than 2.  Please install docker compose by following the README"
        exit 1
    fi
}

function port_check(){
    echo -e "\nChecking all required ports are available"
    # Get public IP address
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)

    # Define the array of externally facing ports to check
    if [[ $USE_GRAYLOG == 1 ]]; then
        EXTERNAL_PORTS=(5678 9000)  # Replace with your desired ports
    else
        EXTERNAL_PORTS=(5678)

    for PORT in "${EXTERNAL_PORTS[@]}"; do

      # Start listener on port 5678 in the background, storing the process ID
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

    echo
}

function key_check(){
    ## Look for Activation Key and github.com token
    if [ -z "${ws_key}" ] && [ -z "${WS_KEY}" ]; then
        echo "${red}Please set your Activation Key as an environment variable using the following command in order to create the prop.json${end}"
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

    scm
}

if [[ "$2" == "--no-graylog" ]]; then
    echo "Moving docker-compose-no-graylog.yaml to docker-compose.yaml"
    mv docker-compose.yaml docker-compose-graylog.yaml
    mv docker-compose-no-graylog.yaml docker-compose.yaml
    USE_GRAYLOG=0
fi

if [ -z "$1" ]; then
    echo "${red}Please pass an scm variable such as gls, bb, or ghe${end}"
else
    if [ "$1" = "gls" ] || [ "$1" = "bb" ] || [ "$1" = "ghe" ]; then
        ## Check if environment has prereqs
        env_check
        ## Check if ports are open
        port_check
        ## Check for valid key and start the process
        key_check
    else
        echo "${red}Please pass an scm variable such as gls, bb, or ghe${end}"
        exit
    fi
fi
