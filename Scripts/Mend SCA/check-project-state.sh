#!/bin/bash
# Prerequisites:
# apt install jq
# WS_GENERATEPROJECTDETAILSJSON: true
# WS_USERKEY
# WS_WSS_URL
# WS_APIKEY

WS_PROJECTTOKEN=$(jq -r '.projects | .[] | .projectToken' ./whitesource/scanProjectDetails.json)
WS_URL=$(echo $WS_WSS_URL | awk -F "/agent" '{print $1}')
REQUEST_TOKEN=$(curl -s -X POST -H "Content-Type: application/json" -d '{"requestType":"getProjectLastModification", "userKey": "'$WS_USERKEY'", "projectToken":"'$WS_PROJECTTOKEN'"}' $WS_URL/api/v1.3 | jq -r '.projectLastModifications[0].extraData.requestToken')
IFS="|"
scan_status=true
pass_status=("UPDATED"${IFS}"FINISHED")
fail_status=("UNKNOWN"${IFS}"FAILED")
while $scan_status
do
  new_status=$(curl -s -X POST -H "Content-Type: application/json" -d '{"requestType":"getRequestState", "userKey": "'$WS_USERKEY'", "orgToken":"'$WS_APIKEY'", "requestToken":"'$REQUEST_TOKEN'"}' $WS_URL/api/v1.3 | jq -r '.requestState')
  if [[ "${IFS}${pass_status[*]}${IFS}" =~ "${IFS}${new_status}${IFS}" ]];
  then
    scan_status=false
    echo "Project information has been uploaded successfully!"
  else
    echo "Scan is still processing..."
    sleep 10
  fi
  if [[ "${IFS}${fail_status[*]}${IFS}" =~ "${IFS}${new_status}${IFS}" ]];
  then
    echo "Scan failed to upload...exiting program"
    exit 1
  fi
done
unset IFS