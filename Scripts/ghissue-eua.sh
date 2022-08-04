#!/bin/bash
# Prerequisites:
# apt install jq curl
# WS_GENERATEPROJECTDETAILSJSON: true
# WS_PRODUCTNAME
# WS_PROJECTNAME
# WS_USERKEY
# WS_WSS_URL

# TODO - Add ERROR handling

WS_PROJECTTOKEN=$(jq -r '.projects | .[] | .projectToken' ./whitesource/scanProjectDetails.json)
WS_URL=$(echo $WS_WSS_URL | awk -F "/agent" '{print $1}')
echo "variables for local debugging"
echo "export WS_APIKEY=<add your key>"
echo "export WS_USERKEY=<add your key>"
echo "export WS_PRODUCTNAME="$WS_PRODUCTNAME
echo "export WS_PROJECTNAME="$WS_PROJECTNAME
echo "export WS_PROJECTTOKEN="$WS_PROJECTTOKEN
echo "export WS_URL="$WS_URL

### getProjectAlertsbyType
curl --request POST $WS_URL'/api/v1.3' --header 'Content-Type: application/json' --header 'Accept-Charset: UTF-8'  --data-raw '{   'requestType' : 'getProjectAlertsByType',   'userKey' : '$WS_USERKEY', 'alertType': 'SECURITY_VULNERABILITY',  'projectToken': '$WS_PROJECTTOKEN','format' : 'json'}' | jq '.alerts[]' >>alerts.json
echo "saving alerts.json"

### getProjectSecurityAlertsbyVulnerabilityReport - finds Red Shields
curl --request POST $WS_URL'/api/v1.3' -H 'Content-Type: application/json' \
-d '{ 'requestType' : 'getProjectSecurityAlertsByVulnerabilityReport', 'userKey' : '$WS_USERKEY', 'projectToken': '$WS_PROJECTTOKEN', 'format' : 'json'}' \
| jq -r '.alerts[] | select(.euaShield=="RED") | .vulnerabilityId' >> redshields.txt
echo 'saving redshields.txt'
cat redshields.txt && echo "cat of redshields"

redshieldlist=`cat redshields.txt`
### Get CVE by Red Shield
for REDSHIELDVULN in $redshieldlist
do
echo "REDSHIELDVULN:"$REDSHIELDVULN

## Get Github issue number by CVE
GHISSUE=$(gh issue list -S "$REDSHIELDVULN in:title,body" --json number --jq '.[] | .number ')
echo "GHISSUE:"$GHISSUE

### Get keyUuid
KEYUUID=$(jq -r --arg REDSHIELDVULN $REDSHIELDVULN '. | select(.vulnerability.name==$REDSHIELDVULN) | .library.keyUuid' alerts.json)
echo "KEYUIID:" $KEYUUID

PROJECTID=$(jq -r --arg REDSHIELDVULN $REDSHIELDVULN '. | select(.vulnerability.name==$REDSHIELDVULN) | .projectId' alerts.json)
echo "PROJECTID:" $PROJECTID

### Construct Link
EUALINK="$WS_URL/Wss/WSS.html#!libraryVulnerabilities;uuid=$KEYUUID;project=$PROJECTID"
echo $EUALINK

gh issue comment $GHISSUE --body "Red Shield Alert: $REDSHIELDVULN - An effective vulnerability has been found in your open-source code demanding urgent remediation steps.  $EUALINK"

done
