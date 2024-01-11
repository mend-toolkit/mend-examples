#!/bin/bash
#
# ******** Mend Script to cache the latest version of the Unified Agent for pipeline efficiency ********
# 
# Users should edit this file to change behavior however needed
# For more information on the Unified Agent users can access the following URL:
# 📚 https://docs.mend.io/bundle/unified_agent/page/getting_started_with_the_unified_agent.html#Downloading-the-Unified-Agent
# 
# ******** Description ********
# This script pulls the latest version of the Unified Agent and stores it in a directory specified by "UADir". 
# Any subsequent runs will determine if the current version is the latest version, and if not then it is replaced.

# Prerequisites:
# apt install jq curl
# export UNIFIED_AGENT_DIR - (/path/to/directory/containing/wss-unified-agent/)

latestUAPath="$(find $UNIFIED_AGENT_DIR -name "wss-unified-agent.jar")"

if [ -f "$latestUAPath" ]; then
    curVerDate="$(stat -c %Y $latestUAPath)"
    if [[ "$(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256 | cut -d " " -f 1)" != "$(sha256sum $UNIFIED_AGENT_DIR/wss-unified-agent.jar | cut -d " " -f 1)" ]] ; then
        echo "No newer versions"
        exit 0
    fi
fi

latestVersion="$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/whitesource/unified-agent-distribution/releases" | jq -rs '.[] | sort_by(.published_at) | last | .tag_name')"
echo "Downloading the latest version of Mend Unified Agent -  ($latestVersion)"
curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar -o $UNIFIED_AGENT_DIR/wss-unified-agent.jar
if [[ "$(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256 | cut -d " " -f 1)" != "$(sha256sum $UNIFIED_AGENT_DIR/wss-unified-agent.jar | cut -d " " -f 1)" ]] ; then
    echo "Integrity Check Failed"
    exit 1
else
    echo "Integrity Check Passed"
    echo "Starting Mend Scan"
fi
