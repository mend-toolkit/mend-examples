#!/bin/bash

# ******** Mend script to find projects with scan error tags  ********
# 
# Users should edit this file to change the behavior of the script as needed.

# Prerequisites:
# apt install jq curl
# MEND_EMAIL - Should be the email for the userKey used below
# MEND_USER_KEY
# MEND_URL
# MEND_ORG_UUID - optional for selecting a different organization


function login() {
    MEND_API_URL="$(echo "${MEND_URL}" | sed -E 's/(saas|app)(.*)/api-\1\2\/api\/v2.0/g')"

    if [ -z "${MEND_EMAIL}" ]; then
      echo "MEND_EMAIL is not set. Please set it before proceeding."
      exit 1
    fi
    
    if [ -z "${MEND_USER_KEY}" ]; then
      echo "MEND_USER_KEY is not set. Please set it before proceeding."
      exit 1
    fi

    if [ -z "${MEND_URL}" ]; then
      echo "MEND_URL is not set. Please set it before proceeding."
      exit 1
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
}

function find_scan_errors() {
    ORG_ENTITIES_RESPONSE=$(curl -s --location "$MEND_API_URL/orgs/$MEND_ORG_UUID/entities" --header "Content-Type: application/json" --header "Authorization: Bearer $JWT_TOKEN")
    echo $ORG_ENTITIES_RESPONSE | jq '.retVal[] | select(.project.tags[]? | select(.key == "scanError")) | {projectname: .project.name, scanError: (.project.tags[] | select(.key == "scanError").value)}'
}


login

find_scan_errors
