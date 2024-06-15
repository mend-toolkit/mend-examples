#!/bin/bash

# ******** Mend Script to Delete a Project after a Unified Agent Scan ********
# 
# Users should edit this file to change the behavior of the script as needed.

# Prerequisites:
# apt install jq curl awk
# MEND_EMAIL - Should be the email for the userKey used below
# WS_GENERATEPROJECTDETAILSJSON=true
# WS_USERKEY
# WS_WSS_URL
# WS_GENERATESCANREPORT=true
#   alternatively, a risk report could be generated as shown in [Reports Within a Pipeline for UA](#reports-within-a-pipeline-for-ua)


WS_PROJECTTOKEN=$(jq -r '.projects | .[] | .projectToken' ./whitesource/scanProjectDetails.json)
MEND_URL=$(echo $WS_WSS_URL | awk -F "/agent" '{print $1}')


function login() {
    MEND_API_URL="$(echo "${MEND_URL}" | sed -E 's/(saas|app)(.*)/api-\1\2\/api\/v2.0/g')"

    if [[ -n "${WS_USERKEY}" ]]; then
        MEND_USER_KEY="${WS_USERKEY}"
    else
        echo "Error: WS_USERKEY or MEND_USER_KEY is not set. Please set it before proceeding."
    fi

    if [ -z "$MEND_ORG_UUID" ]; then
        echo "MEND_ORG_UUID environment variable was not provided."
        echo -e "The Login API will default to the last organization this user accessed in the MEND UI.\n"
        LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\" }"
    else
        echo -e "Logging in with provided API key.\n"
        LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\", \"orgToken\": \"$MEND_ORG_UUID\"}"
    fi

    # Log into API 2.0 and get the JWT Token, Organization UUID, and Organization Name
    LOGIN_RESPONSE=$(curl -s -X POST --location "$MEND_API_URL/login" --header 'Content-Type: application/json' --data-raw "${LOGIN_BODY}")

    JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.retVal.jwtToken')
    MEND_ORG_UUID=$(echo "$LOGIN_RESPONSE" | jq -r '.retVal.orgUuid')
    MEND_ORG_NAME=$(echo "$LOGIN_RESPONSE" | jq -r '.retVal.orgName')
}

function delete_project() {
    curl -s --request DELETE --location "$MEND_API_URL/projects/$WS_PROJECTTOKEN" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN"
    echo "Successfully deleted project with projectToken ${WS_PROJECTTOKEN}"
}


login

delete_project