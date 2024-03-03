#!/bin/bash
#
# ******** Mend Script to cleanup all Pending Tasks in an organization ********
# 
# Users should edit this file to change any behavior as needed.
# 
# For more information on the APIs used, please check our REST API documentation page:
# 📚 https://docs.mend.io/bundle/api_sca/page/http_api_v1_3_and_v1_4.html
#
# ******** Description ********
# This script pulls all of open pending tasks for an organization and calls the "closePendingTask" 
# API request for each task to ensure they are all closed.

# This script utilizes the Mend Org UUID to call the API Requests.
# If the new Mend Unified Platform is not in use, then the user can get the Organization UUID for a specific organization by running the following API request:
# 📚 https://docs.mend.io/bundle/mend-api-2-0/page/index.html#tag/Access-Management-Organizations/operation/getUserDomains 

# Prerequisites:
# apt install jq curl
# MEND_USER_KEY - An administrator's userkey
# MEND_ORG_UUID - API Key for organization (optional)
# MEND_URL - e.g. https://saas.mend.io/

# Check if MEND_URL is set in the environment
if [ -z "$MEND_URL" ]; then
  echo "Warning: MEND_URL is not set in the environment."
  echo "Please set it to something similar to 'https://saas.mend.io'"
  exit 1
fi

# Set your base API endpoint URLs
API_VERSION="v1.4"

# Check if WS_APIKEY is set in the environment
if [ -z "$MEND_ORG_UUID" ]; then
  echo "Warning: WS_APIKEY is not set in the environment."
  exit 1
fi

# Check if MEND_USER_KEY is set in the environment
if [ -z "$MEND_USER_KEY" ]; then
  echo "Warning: MEND_USER_KEY is not set in the environment."
  exit 1
fi

# Make the API request using curl for getDomainPendingTasks
GET_TASKS_API="$MEND_URL/api/$API_VERSION"
GET_TASKS_PAYLOAD=$(cat <<EOF
{
  "orgToken": "$MEND_ORG_UUID",
  "requestType": "getDomainPendingTasks",
  "userKey": "$MEND_USER_KEY",
  "includeRequestToken": "true"
}
EOF
)

response=$(curl -X POST -H "Content-Type: application/json" -d "$GET_TASKS_PAYLOAD" "$GET_TASKS_API")

# Check if there was an error with jq
if [ $? -ne 0 ]; then
  echo "Error: Unable to parse the API response using jq."
  exit 1
fi

# Extract uuids from the response
uuids=$(echo "$response" | jq -r '.pendingTaskInfos[].uuid')

# Check if uuids are null or empty
if [ -z "$uuids" ]; then
  echo "Warning: No uuids found in the API response."
  exit 1
fi

# Loop through the uuids and call closePendingTask for each uuid
CLOSE_TASK_API="$MEND_URL/api/$API_VERSION"
for uuid in $uuids; do
  CLOSE_TASK_PAYLOAD=$(cat <<EOF
  {
    "taskUUID": "$uuid",
    "orgToken": "$MEND_ORG_UUID",
    "requestType": "closePendingTask",
    "userKey": "$MEND_USER_KEY",
    "includeRequestToken": "true"
  }
EOF
  )

  # Make the API request using curl for closePendingTask
  close_response=$(curl -X POST -H "Content-Type: application/json" -d "$CLOSE_TASK_PAYLOAD" "$CLOSE_TASK_API")

  # Print the response for each closePendingTask
  echo "Response for uuid: $uuid"
  echo "$close_response"
done
