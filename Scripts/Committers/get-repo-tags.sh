#!/bin/bash
#
# ******** Mend Script to pull the repoFullName and remoteUrl values from the tags of Mend Projects integrated with the repository integration or Unified CLI ********
# 
# Users should edit this file to add any steps for consuming the information provided by the API requests however needed.
# 
# For more information on the APIs used, please check our REST API documentation page:
# ?? https://docs.mend.io/bundle/mend-api-2-0/page/index.html
#
# ******** Description ********
# This script pulls all of the projects in an organization and then retrieves the tags for each and grabs the repoFullName and remoteUrl
# Afterwards the scripts combines all of the data pulled for each project.
# 
# The WS_API_KEY environment variable is optional. If this is not specified in the script, then the Login API will
# authenticate to the last organization the user accessed in the Mend UI.
# 
# MEND_ONLY_UPDATED_REPOS environment variable is optional. If this is set to true, Mend will only retrieve repos that have been updated in the last 90 days according to the Mend UI Last Scan Date
#
# Prerequisites:
# apt install jq curl
# MEND_USER_KEY - An administrator's userkey
# MEND_EMAIL - The administrator's email
# WS_APIKEY - API Key for organization (optional)
# MEND_URL - e.g. https://saas.mend.io
# MEND_ONLY_UPDATED_REPOS - true/false (optional)

# Reformat MEND_URL for the API to https://api-<env>/api/v2.0
MEND_API_URL=$(echo "${MEND_URL}" | sed -E 's/(saas|app)(.*)/api-\1\2\/api\/v2.0/g')

# If API Key was not specified then exclude from Login request body.
if [ -z "$WS_APIKEY" ]
then
	echo "\nWS_APIKEY environment variable was not provided."
       	echo -e "The Login API will default to the last organization this user accessed in the Mend UI.\n"
        LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\" }"
else
	echo -e "\nLogging in with provided API key.\n"
        LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\", \"orgToken\": \"$WS_APIKEY\"}"
fi

# Log into API 2.0 and get the JWT Token and Organization UUID
LOGIN_RESPONSE=$(curl -s -X POST --location "$MEND_API_URL/login" --header 'Content-Type: application/json' --data-raw "${LOGIN_BODY}")

JWT_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.retVal.jwtToken')
WS_APIKEY=$(echo $LOGIN_RESPONSE | jq -r '.retVal.orgUuid')

# Get all project entities
echo "Retrieving Projects from Organization"
ISLASTPAGE=false
PAGE_COUNTER=0
ALL_ENTITIES=()
while [ $ISLASTPAGE = "false" ]; do
	ENTITY_RESPONSE=$(curl -s --location "$MEND_API_URL/orgs/$WS_APIKEY/entities?pageSize=10000&page=$PAGE_COUNTER" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
 
  	ENTITIES=$(echo $ENTITY_RESPONSE | jq '.retVal')
	ISLASTPAGE=$(echo $ENTITY_RESPONSE | jq -r '.additionalData.isLastPage' )
	ALL_ENTITIES=$(jq -s 'add' <(echo "$ALL_ENTITIES") <(echo "$ENTITIES"))
	((PAGE_COUNTER++))
done

PROJECT_ENTITIES=$(echo $ALL_ENTITIES | jq -r '[.[] | select(has("project")) | .project]')
if [ "$MEND_ONLY_UPDATED_REPOS" = "true" ]; then

  echo "Filtering Projects that have not been scanned in 90 days"
	NINETY_DAYS_AGO=$( (date -j -v-91d +%s 2>/dev/null || date -d "91 days ago" +%s) )
  NO_SCAN_DATE=$(echo $PROJECT_ENTITIES | jq '[.[] | select(has("lastScanned") | not)]')
	PROJECT_ENTITIES=$(echo $PROJECT_ENTITIES | jq -r --argjson cutoff $NINETY_DAYS_AGO  '[.[] | select((.lastScanned | fromdateiso8601? // 0) > $cutoff)]')
  if [ -n "$NO_SCAN_DATE" ]; then
    NO_DATE_PROJECT_NAMES=$(echo $NO_SCAN_DATE | jq -r ".[].name" )
    echo -e "\n\nProjects with no Last Scan Date"
    echo "-----------------"
    printf '%s\n' "${NO_DATE_PROJECT_NAMES[@]}"
    # Optional - save to text file
    echo "${NO_DATE_PROJECT_NAMES[@]}" >> no_scan_Date.txt
  fi
fi
NUM_ENTITIES=$(echo $PROJECT_ENTITIES | jq 'length' )

# These output variable starts with nothing, and will get populated with data as we pull the tags for each project.
REPOFULLNAME=()
REMOTEURL=()

echo -e "\n\nGetting Tags"
echo "-----------------"
# Loop through each entity in $PROJECT_ENTITIES and get the tag repoFullName.

: > repos.txt

# Loop through each entity in $PROJECT_ENTITIES and get the tag repoFullName.
for (( i=0; i<=$NUM_ENTITIES-1; i++ ))
do
        CURRENT_PROJECT_NAME=$(echo $PROJECT_ENTITIES | jq -r ".[$i].name" )
        echo "Getting TAGS for PROJECT $(($i+1))/$NUM_ENTITIES: $CURRENT_PROJECT_NAME"
		
    	CURRENT_PROJECT_TAGS=$(echo $PROJECT_ENTITIES | jq ".[$i].tags" )

        REPOFULLNAME_TAG=$(echo $CURRENT_PROJECT_TAGS | jq -r '.[] | select(.key | startswith("repoFullName")) | .value')
        if [[ -n "$REPOFULLNAME_TAG" ]]; then
             REPOFULLNAME_TAG=${REPOFULLNAME_TAG// /%20}
             REPOFULLNAME+=("$REPOFULLNAME_TAG")
        fi

        REMOTEURL_TAG=$(echo $CURRENT_PROJECT_TAGS | jq -r '.[] | select(.key | startswith("remoteUrl")) | .value')
        if [[ -n "$REMOTEURL_TAG" ]]; then
            REMOTEURL_TAG=${REMOTEURL_TAG// /%20}
            REMOTEURL+=("$REMOTEURL_TAG")
        fi
done




# Extract all the information we need for an alert
echo -e "\n\nAll repoFullName Repositories"
echo "-----------------"
printf '%s\n' "${REPOFULLNAME[@]}"

echo -e "\n\nAll remoteUrl Repositories"
echo "-----------------"
printf '%s\n' "${REMOTEURL[@]}"


# Optional - save to text file
echo "${REPOFULLNAME[@]}" >> repos.txt
echo "${REMOTEURL[@]}" >> repos.txt
