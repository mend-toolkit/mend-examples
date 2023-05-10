#!/bin/bash
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

  if [[ $repStatus = "FINISHED" || $repStatus = "UPDATED" ]] ; then
		ready=true
		echo "Project information has been uploaded successfullly\!"
  elif [[ $repStatus = "IN_PROGRESS" ]] ; then
		echo "Scan is still processing..."
    sleep $checkFreq
	fi
done