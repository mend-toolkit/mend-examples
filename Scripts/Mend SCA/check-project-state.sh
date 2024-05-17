#!/bin/bash

# NOTE: It is currently recommended to use the MEND CLI over the Mend Unified Agent.
# The Mend CLI will automatically wait for the project to finish processing on the mend server
# before printing results, and so with that utility this script is not required.
#
# ******** Mend Script to List Policy Violations after a Unified Agent Scan ********
# 
# Users should edit this file to change the behavior of the script as needed.
#
# ******** Description ********
# This script will continually check with Mend Servers to determine whether the scan has finished
# Processing on Mend Servers. Once the process has finished, then it will exit without error.

# Prerequisites:
# apt install jq
# WS_GENERATEPROJECTDETAILSJSON: true
# WS_USERKEY
# WS_WSS_URL
# WS_APIKEY
# WS_GRADLE_AGGREGATEMODULES or WS_MAVEN_AGGREGATEMODULES - If used Maven and Grade

checkFreq=5
[[ -z $checkFreq ]] && checkFreq=5
WS_PROJECTTOKEN=$(jq -r '.projects | .[] | .projectToken' ./whitesource/scanProjectDetails.json)
WS_API_URL="$(echo "$WS_WSS_URL" | sed 's|agent|api/v1.3|')"
REQUEST_TOKEN=$(curl -s -X POST -H "Content-Type: application/json" -d '{"requestType":"getProjectLastModification", "userKey": "'$WS_USERKEY'", "projectToken":"'$WS_PROJECTTOKEN'"}' $WS_API_URL | jq -r '.projectLastModifications[0].extraData.requestToken')

ready=false
while [[ $ready = "false" ]] ; do
	resProcess="$(curl -s -X POST -H "Content-Type: application/json" -d '{"requestType":"getRequestState", "userKey": "'$WS_USERKEY'", "orgToken":"'$WS_APIKEY'", "requestToken":"'$REQUEST_TOKEN'"}' $WS_API_URL)"
	repStatus="$(echo "$resProcess" | jq -r '.requestState')"

  if [[ $repStatus = "FINISHED" ]] ; then
		ready=true
		echo "Project information has been uploaded successfullly\!"
  elif [[ $repStatus = "IN_PROGRESS" ]] ; then
		echo "Scan is still processing..."
    sleep $checkFreq
	fi
done
