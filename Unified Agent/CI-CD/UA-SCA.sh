#!/bin/bash
# Generic example for scanning for dependencies with the Mend Unified Agent 

export WS_APIKEY=<your-api-key>
export WS_USERKEY=<your-user-key>
export WS_PRODUCTNAME=<your-product-name>
export WS_PROJECTNAME=<your-project-name>
export WS_WSS_URL=https://saas.mend.io/agent
curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
echo Mend Unified Agent downloaded successfully
if [[ "$(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256)" != "$(sha256sum wss-unified-agent.jar)" ]] ; then
    echo "Integrity Check Failed"
else
    echo "Integrity Check Passed"
    echo Starting Mend Scan
    java -jar wss-unified-agent.jar
fi