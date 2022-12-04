echo "Downloading Mend Unified Agent"
if ! [ -f ./wss-unified-agent.jar ]; then
  curl -fSL -R -JO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
  if [[ "$(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256)" != "$(sha256sum wss-unified-agent.jar)" ]]; then
    echo "Integrity Check Failed"
    exit -7
  fi
fi
echo "Exceute Mend Unified Agent"
export WS_APIKEY=${APIKEY} #Taken from Jenkins Global Environment Variables
export WS_USERKEY=${USERKEY} #Taken from Jenkins Global Environment Variables
export WS_WSS_URL="https://saas.whitesourcesoftware.com/agent"
export WS_PRODUCTNAME=Jenkins
export WS_PROJECTNAME=${JOB_NAME}
java -jar wss-unified-agent.jar