#!/bin/bash

# NOTE: It is currently recommended to use the MEND CLI over the Mend Unified Agent.
# The Mend CLI will automatically update each time it runs and scan with the latest 
# information, and so with that utility, this script is not required.

# ******** Mend Script to Gather Scanner Information from Projects ********
# 
# Users should edit this file to change the behavior of the script as needed.
#
# ******** Description ********
# This script scours a Mend Organization for all projects that have been scanned,
# and then gathers information concerning the version of the scanner. This script
# should not be used in a pipeline with a Unified Agent scan as it gathers information
# for all projects in an organization. It then outputs the results to an output.json file.
#
# NOTE: If the last scan date and/or plugin name/version show as null, then the
# last scan date was too long ago and Mend no longer stores this information. This
# information is only stored for a limited period of time after a scan.

# Prerequisites:
# apt install jq curl
# MEND_URL (i.e. https://saas.mend.io)
# MEND_ORG_UUID - (optional)
# MEND_EMAIL - Administrator's email address
# MEND_USER_KEY (admin assignment is required)

# Examples:
# ./get-project-scan-info.sh output.json

function login() {
    MEND_API_URL="$(echo "${MEND_URL}" | sed -E 's/(saas|app)(.*)/api-\1\2\/api\/v2.0/g')"

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

function getAPIData() {
    LAST_PAGE=false
    CURRENT_PAGE=0
    OUTPUT={"\"projectInfo\": []}"
    while ! $LAST_PAGE; do
        CURRENT_PROJECT=$(curl -s --location "$MEND_API_URL/orgs/$MEND_ORG_UUID/entities?pageSize=1&page=$CURRENT_PAGE" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")

        TOTAL_ITEMS=$(echo "$CURRENT_PROJECT" | jq -r '.additionalData.totalItems')

        echo -ne "Retrieved Item $((CURRENT_PAGE+1))/$TOTAL_ITEMS"\\r

        LAST_PAGE=$(echo "$CURRENT_PROJECT" | jq -r '.additionalData.isLastPage')
        if ! $LAST_PAGE; then
            CURRENT_PAGE=$((CURRENT_PAGE+1))
        fi

        # Retrieve information for a row of information
        PROJECT_UUID=$(echo "$CURRENT_PROJECT" | jq -r '.retVal.[0].project.uuid')
        PROJECT_NAME=$(echo "$CURRENT_PROJECT" | jq -r '.retVal.[0].project.name')
        PRODUCT_NAME=$(echo "$CURRENT_PROJECT" | jq -r '.retVal.[0].product.name')
        LAST_SCAN_DATE=$(echo "$CURRENT_PROJECT" | jq -r '.retVal.[0].project | select(.lastScanned != null) | .lastScanned')

        if [ -z $LAST_SCAN_DATE ]; then
            LAST_SCAN_DATE="null"
        fi

        # Get Project Vitals
        CURRENT_PROJECT_VITALS=$(curl -s --location "$MEND_API_URL/projects/$PROJECT_UUID/vitals" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
        if [[ $(echo "$CURRENT_PROJECT_VITALS" | jq -r '.status') -eq "401" ]]; then
            login
            CURRENT_PROJECT_VITALS=$(curl -s --location "$MEND_API_URL/projects/$PROJECT_UUID/vitals" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
        fi

        # Get Plugin Version / Name from the vitals
        PLUGIN_NAME=$(echo "$CURRENT_PROJECT_VITALS" | jq -r '.retVal.pluginName')
        PLUGIN_VERSION=$(echo "$CURRENT_PROJECT_VITALS" | jq -r '.retVal.pluginVersion')

        PROJECT_INFO=$(jq --null-input \
            --arg organization "$MEND_ORG_NAME" \
            --arg product "$PRODUCT_NAME" \
            --arg project "$PROJECT_NAME" \
            --arg lastScan "$LAST_SCAN_DATE" \
            --arg pluginName "$PLUGIN_NAME" \
            --arg pluginVersion "$PLUGIN_VERSION" \
            '[{"orgName": $organization, "productName": $product, "projectName": $project, "lastScanDate": $lastScan, "pluginName": $pluginName, "pluginVersion", $pluginVersion}]')

        OUTPUT=$(echo $OUTPUT | jq ".projectInfo |= . + $PROJECT_INFO")
    done
}


if [ -z $1 ]; then
    echo "Please specify the file that you would like this script to output to."
    exit -1
fi


login

getAPIData

# Get all projects under each product and get vitals for each

echo $OUTPUT | jq '.'  > $1

echo -e "\nProject vitals have been written to: $1"

# $OUTPUT can now be used in any process that can consume JSON. The format of $OUTPUT will be:
# {
#   "projectInfo": [
#       {
#           "orgName": "organization name",
#           "productName": "product name",
#           "projectName": "project name",
#           "lastScanDate": "scan date",
#           "pluginName": "plugin name",
#           "pluginVersion": "plugin version"
#       },
#       {
#           ...
#       }
#   ]
# }
