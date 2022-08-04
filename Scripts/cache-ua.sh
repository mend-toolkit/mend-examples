#!/bin/bash

# Prerequisites:
# apt install jq curl

UADir="/path/to/existing/wss-unified-agent/"

res="$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/whitesource/unified-agent-distribution/releases")"
latestRelease="$(echo "$res" | jq -s '.[] | sort_by(.published_at) | last')"

latestVer="$(echo "$latestRelease" | jq -rs '.[] | .tag_name')"
latestVerDate="$(date -d "$(echo "$latestRelease" | jq -rs '.[] | .published_at')" +%s)"
curVerDate="$(stat -c %Y "$(find $UADir -name "wss-unified-agent.jar")")"

if [ $latestVerDate -gt $curVerDate ] ; then
    echo "Downloading the latest version ($latestVer)"
    curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
    if [[ "$(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256)" != "$(sha256sum wss-unified-agent.jar)" ]] ; then
    echo "Integrity Check Failed"
    else
        echo "Integrity Check Passed"
        echo "Starting WhiteSource Scan"
    fi
else
    echo "No newer versions"
fi
