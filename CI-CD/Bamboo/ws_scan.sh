# Variables are taken from the job Variables List
# For Example:
# WS_PRODUCTNAME = ${bamboo.planKey}
# WS_PROJECTNAME = ${bamboo.buildPlanName}
# WS_WSS_URL = https://saas.whitesourcesoftware.com/agent
# WS_APIKEY = {MASKED_APIKEY}
# WS_USERKEY = {MASKED_USERKEY}

# Download Unified Agent
echo Downloading WhiteSource Unified Agent
curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
if [[ "$(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256)" != "$(sha256sum wss-unified-agent.jar)" ]] ; then
    echo "Integrity Check Failed"
else
    echo "Integrity Check Passed"
    echo "Starting WhiteSource Scan"
    java -jar wss-unified-agent.jar
fi

# Scan with Unified Agent
java -jar wss-unified-agent.jar 