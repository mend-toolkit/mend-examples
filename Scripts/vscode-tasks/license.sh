#!/bin/bash

# ******** Mend script to find projects inventory with unknown libraries  ********
# 
# Users should edit this file to change the behavior of the script as needed.

# Prerequisites:
# apt install jq curl
# MEND_EMAIL - Should be the email for the userKey used below
# MEND_USER_KEY
# MEND_URL
# MEND_ORG_UUID - optional for selecting a different organization

#GLOBALS
# echo colors you can use these by adding ${<color>} in your echo commands.
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

arg1=$1

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
    MEND_ORG_NAME=$(echo "$LOGIN_RESPONSE" | jq -r '.retVal.domainName')
}

function get_unknown_libs() {
    ORG_ENTITIES_RESPONSE=$(curl -s --location "$MEND_API_URL/projects/$arg1/libraries?search=numberOfLicenses:EQUALS:0" --header "Content-Type: application/json" --header "Authorization: Bearer $JWT_TOKEN")
    #echo $ORG_ENTITIES_RESPONSE | jq '.retVal[] '
    echo "${cyn}Unknown Libraries that should be marked as proprietary or commerical at"
    echo "$MEND_URL/app/orgs/$MEND_ORG_NAME/applications/sbom?project=$arg1 ${end}"
    LIBS=$(echo $ORG_ENTITIES_RESPONSE | jq -r '.retVal[] | .name ')
    if [ -z "${LIBS}" ]; then
        echo "${grn}There are no unknown libraries${end}"
      else
        echo $LIBS
    fi
    echo
    
}

function get_commercial() {
    ORG_ENTITIES_RESPONSE=$(curl -s --location "$MEND_API_URL/projects/$arg1/libraries?search=license:LIKE:commercial" --header "Content-Type: application/json" --header "Authorization: Bearer $JWT_TOKEN")
    echo "${cyn}The following libraries have already been distinguished as commercial ${end}"
    LIBS=$(echo $ORG_ENTITIES_RESPONSE | jq -r '.retVal[] | .name ')
    if [ -z "${LIBS}" ]; then
        echo "${grn}There are no commercial libraries${end}"
      else
        echo $LIBS
    fi
    echo
}

function get_multi_license() {
    ORG_ENTITIES_RESPONSE=$(curl -s --location "$MEND_API_URL/projects/$arg1/libraries?search=numberOfLicenses:GT:1" --header "Content-Type: application/json" --header "Authorization: Bearer $JWT_TOKEN")
    echo "${cyn}The following libraries have multiple licenses and require a decision at"
    echo "$MEND_URL/app/orgs/$MEND_ORG_NAME/applications/sbom?project=$arg1 ${end}"
    LIBS=$(echo $ORG_ENTITIES_RESPONSE | jq -r '.retVal[] | .name ')
    if [ -z "${LIBS}" ]; then
        echo "${grn}There are no libraries with multiple licenses${end}"
      else
        echo $ORG_ENTITIES_RESPONSE | jq -r '.retVal[] | .name '
    fi
    echo
}

login
get_unknown_libs
get_commercial
get_multi_license

