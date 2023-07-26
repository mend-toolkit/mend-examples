#!/bin/bash

# Check if MEND_URL is set in the environment
if [ -z "$MEND_URL" ]; then
  echo "Warning: MEND_URL is not set in the environment."
  echo "Please set it to something similar to 'https://saas.mend.io'"
  exit 1
fi

# Set your base API endpoint URLs
API_VERSION="v1.4"

# Check if WS_APIKEY is set in the environment
if [ -z "$WS_APIKEY" ]; then
  echo "Warning: WS_APIKEY is not set in the environment."
  exit 1
fi

# Check if MEND_USER_KEY is set in the environment
if [ -z "$MEND_USER_KEY" ]; then
  echo "Warning: MEND_USER_KEY is not set in the environment."
  exit 1
fi

# Set other request parameters
INCLUDE_REQUEST_TOKEN=true

# Make the API request using curl for getDomainPendingTasks
GET_TASKS_API="$MEND_URL/api/$API_VERSION"
GET_TASKS_PAYLOAD=$(cat <<EOF
{
  "orgToken": "$WS_APIKEY",
  "requestType": "getDomainPendingTasks",
  "userKey": "$MEND_USER_KEY",
  "includeRequestToken": $INCLUDE_REQUEST_TOKEN
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
    "orgToken": "$WS_APIKEY",
    "requestType": "closePendingTask",
    "userKey": "$MEND_USER_KEY",
    "includeRequestToken": $INCLUDE_REQUEST_TOKEN
  }
EOF
  )

  # Make the API request using curl for closePendingTask
  close_response=$(curl -X POST -H "Content-Type: application/json" -d "$CLOSE_TASK_PAYLOAD" "$CLOSE_TASK_API")

  # Print the response for each closePendingTask
  echo "Response for uuid: $uuid"
  echo "$close_response"
done
