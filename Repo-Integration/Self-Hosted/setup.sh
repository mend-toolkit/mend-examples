#!/bin/bash

SCM=$1
if [ "$2" ]
then
    CERTFILE=`readlink -f $2`
fi
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


# Copy Activation Key & update with fake value
cp ${BASE_DIR}/latest/wss-configuration/config/prop.json ${BASE_DIR}/prop.json
sed -i 's/your-activation-key/fakevalue/1' ${BASE_DIR}/prop.json
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
echo "WS_ACTIVATION_KEY=${ws_key}" >> ${REPO_INTEGRATION_DIR}/.env
echo "WS_UA_LOG_IN_CONSOLE=true" >> ${REPO_INTEGRATION_DIR}/.env


echo "${grn}Download Success!!!${end}"

}

function cert_add(){
    if [ -z $CERTFILE ]
        then  echo "No .crt file supplied as 2nd argument. Integration will be prepared with no additional certs."
        else
            if [[ $CERTFILE != *.crt ]]
                then
                    echo Argument 2 to this script must be a certificate file whose name ends in ".crt";
                    return;
            fi
            if !(grep -ne "-----BEGIN CERTIFICATE-----" $CERTFILE | grep -q '^1:');
                then
                    echo File supplied as 2nd argument must be a .crt file with first line equal to "-----BEGIN CERTIFICATE-----";
                    return;
                else
                    if !(grep -nF 'COPY docker-image/ /' ${BASE_DIR}/latest/wss-$SCM-app/docker/Dockerfile | grep -q '^27:');
                        then
                            echo wss-$SCM-app Dockerfile not in expected format.  Leaving all files unchanged.
                            return;
                    fi
                    if !(grep -nF 'COPY docker-image/ /' ${BASE_DIR}/latest/wss-scanner/docker/Dockerfile | grep -q '^334:');
                        then
                            echo wss-scanner Dockerfile not in expected format.  Leaving all files unchanged.
                            return;
                    fi
                    if !(grep -nF 'COPY package.json yarn.lock ./' ${BASE_DIR}/latest/wss-remediate/docker/Dockerfile | grep -q '^129:');
                        then
                            echo wss-remediate Dockerfile not in expected format.  Leaving all files unchanged.
                            return;
                    fi
            fi
            cp $CERTFILE ${BASE_DIR}/latest/wss-$SCM-app/docker/docker-image
            cp $CERTFILE ${BASE_DIR}/latest/wss-scanner/docker/docker-image
            cp $CERTFILE ${BASE_DIR}/latest/wss-remediate/docker
            CERTFILE_BASE=`basename $CERTFILE`
            sed -i '27a\
COPY docker-image/'"$CERTFILE_BASE"' /usr/local/share/ca-certificates\
\
RUN /opt/buildpack/tools/java/8.0.342+7/bin/keytool -import -keystore /opt/buildpack/tools/java/8.0.342+7/jre/lib/security/cacerts -storepass changeit -noprompt -alias Mend -file '"$CERTFILE_BASE"'\
RUN /opt/buildpack/tools/java/8.0.342+7/bin/keytool -import -keystore /opt/buildpack/ssl/cacerts -storepass changeit -noprompt -alias Mend -file '"$CERTFILE_BASE"'\
RUN update-ca-certificates' ${BASE_DIR}/latest/wss-$SCM-app/docker/Dockerfile
            sed -i '359a\
COPY docker-image/'"$CERTFILE_BASE"' /usr/local/share/ca-certificates\
\
RUN /opt/buildpack/tools/java/17.0.7+7/bin/keytool -import -keystore /opt/buildpack/tools/java/17.0.7+7/lib/security/cacerts -storepass changeit -noprompt -alias Mend -file '"$CERTFILE_BASE"'\
RUN /opt/buildpack/tools/java/17.0.7+7/bin/keytool -import -keystore /opt/buildpack/ssl/cacerts -storepass changeit -noprompt -alias Mend -file '"$CERTFILE_BASE"'\
RUN /opt/buildpack/tools/java/11.0.19+7/bin/keytool -import -keystore /opt/buildpack/tools/java/11.0.19+7/lib/security/cacerts -storepass changeit -noprompt -alias Mend -file '"$CERTFILE_BASE"'\
RUN /opt/buildpack/tools/java/8.0.342+7/bin/keytool -import -keystore /opt/buildpack/tools/java/8.0.342+7/jre/lib/security/cacerts -storepass changeit -noprompt -alias Mend -file '"$CERTFILE_BASE"'\
RUN update-ca-certificates' ${BASE_DIR}/latest/wss-scanner/docker/Dockerfile
            sed -i '129a\
COPY '"$CERTFILE_BASE"' ./\
COPY '"$CERTFILE_BASE"' /usr/local/share/ca-certificates\
\
ENV NODE_EXTRA_CA_CERTS='"$CERTFILE_BASE"'\
RUN /opt/containerbase/tools/java/11.0.19+7/bin/keytool -import -keystore /opt/containerbase/ssl/cacerts -storepass changeit -noprompt -alias Mend -file '"$CERTFILE_BASE"'\
RUN update-ca-certificates\
' ${BASE_DIR}/latest/wss-remediate/docker/Dockerfile
            echo Supplied certfile $CERTFILE has been copied to the appropriate places and Dockerfiles have been modified, so that TLS operations in the containers will trust this certificate.
    fi
}

function key_check(){
## Look for Activation Key
if [ -z "${ws_key}" ]
then
    echo "${red}Please set your Activation Key as an environment variable using the following command in order to create the prop.json${end}"
    echo "${cyn}export ws_key='replace-with-your-activation-key-inside-single-quotes'${end}"
    exit
else
    scm;
    cert_add;
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


