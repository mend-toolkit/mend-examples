#!/bin/bash
#
# ******** Mend Script to pull all vulnerabilities for a Scanned Container Image ********
# 
# Users should edit this file to chane any headings in the resulting CSV file that are not needed.
# 
# For more information on the APIs used, please check our REST API documentation page:
# 📚 https://docs.mend.io/bundle/mend-api-2-0/page/index.html
# 📚 https://docs.mend.io/bundle/mend-container-image-api-2-0/page/index.html
#
# ******** Description ********
# This script pulls all of the images in a Mend Container Image Organization and then retrieves vulnerabilities, outputting them in a .csv file
# The process for this is relatively simple. 1. Log into the Mend API. 
# 2. Get all images associated with an organization. 
# 3. Then get all vulnerabilitie associated with each image.
# 
# The WS_API_KEY environment variable is optional. If this is not specified in the script, then the Login API will
# authenticate to the last organization the user accessed in the Mend UI.

# Prerequisites:
# apt install jq curl
# MEND_USER_KEY - An administrator's userkey
# MEND_EMAIL - The administrator's email
# WS_APIKEY - API Key for organization (optional)
# MEND_URL - e.g. https://saas.mend.io/

MEND_API_URL=$(echo "${MEND_URL}" | sed -E 's/(saas|app)(.*)/api-\1\2\/api\/v2.0/g')

# If the API Key was not specificed then exclude from Login Request body.
if [ -z "$WS_APIKEY" ]
then
	echo "WS_APIKEY environment variable was not provided."
	echo -e "The login API will default to the last organization this user accessed in the Mend UI.\n"
	LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\" }"
else
	echo -e "Logging in with the provided API key.\n"
	LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\", \"orgToken\": \"$WS_APIKEY\"}"
fi

# Log into API 2.0 and get the JWT Token and Organization UUID
LOGIN_RESPONSE=$(curl -s -X POST --location "$MEND_API_URL/login" --header 'Content-Type: application/json' --data-raw "${LOGIN_BODY}")

# echo $LOGIN_RESPONSE | jq '.'

JWT_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.retVal.jwtToken')
WS_APIKEY=$(echo $LOGIN_RESPONSE | jq -r '.retVal.orgUuid')

MEND_CN_API_URL=$(echo "${MEND_API_URL}" | sed -E 's/(\/)(api\/v2.0)/\1cn\/\2/g')

# Get all images in Container Organization
IMAGES_RESPONSE=$(curl -s --location "$MEND_CN_API_URL/orguuid/$WS_APIKEY/images?page=0&size=10000" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
NUM_IMAGES=$(echo $IMAGES_RESPONSE | jq -r '.additionalInfo.totalItems' )
IMAGES=$(echo $IMAGES_RESPONSE | jq '.data')


# This starts as empty but will get added to as we pull vulnerabilities from each image.
OUTPUT="[]"

for (( i=0; i<$NUM_IMAGES; i++ ))
do
	CURRENT_IMAGE_UUID=$(echo $IMAGES | jq -r ".[$i].uuid" )
	
	echo "Getting vulnerabilities for Image $(($i+1))/$NUM_IMAGES: $CURRENT_IMAGE_UUID"

	# Get all vulnerabilities for this image
	CURRENT_OUTPUT=$(curl -s --location "$MEND_CN_API_URL/orguuid/$WS_APIKEY/images/$CURRENT_IMAGE_UUID/vulnerabilities" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN" | jq '.data')

	# Combine with OUTPUT
	OUTPUT=$(echo "$OUTPUT $CURRENT_OUTPUT" | jq -s add)
done

# Define headers and then output as csv format. Users can remove whichever headers are necessary. Note: the CWEs object is an array, so outputting that to CSV is not handled well by jq
echo $OUTPUT | jq --raw-output '["vulnerabilityId", "description", "epss", "publishedDate", "lastModifiedDated", "packageName", "sourcePackageName", "packageVersion", "packageType", "foundInLayer", "isFromBaseLayer", "layerNumber", "cvss", "severity", "fixVersion", "hasFix", "referenceUrls", "type", "vendorSeverity", "risk", "score"] as $headers | ( $headers, ( .[] | [ .vulnerabilityId, .description, .epss, .publishedDate, .lastModifiedDate, .packageName, .sourcePackageName, .packageVersion, .packageType, .foundInLayer, .isFromBaseLayer, .layerNumber, .cvss, .severity, .fixVersion, .hasFix,.referenceUrls, .type, .vendorSeverity, .risk, .score ] ) ) | @csv' > vulnerabilities.csv

