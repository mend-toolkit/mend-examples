# Variables are taken from the job Variables List
# For Example:
# WS_PRODUCTNAME = ${bamboo.planKey}
# WS_PROJECTNAME = ${bamboo.buildPlanName}
# WS_WSS_URL = https://saas.mend.io/agent
# WS_APIKEY = {MASKED_APIKEY}
# WS_USERKEY = {MASKED_USERKEY}
# Create a Script build step and paste the following:

# Download Unified Agent
export WS_APIKEY=${bamboo_WS_APIKEY}
export WS_WSS_URL=${bamboo_WS_WSS_URL}
export WS_PRODUCTNAME=${bamboo_WS_PRODUCTNAME}
export WS_PROJECTNAME=${bamboo_WS_PROJECTNAME}
echo Downloading Mend Unified Agent
curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
if [[ "$(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256)" != "$(sha256sum wss-unified-agent.jar)" ]] ; then
    echo "Integrity Check Failed"
else
    echo "Integrity Check Passed"
    echo "Starting Mend Scan"
    java -jar wss-unified-agent.jar
fi

# Scan with Mend Unified Agent
java -jar wss-unified-agent.jar 