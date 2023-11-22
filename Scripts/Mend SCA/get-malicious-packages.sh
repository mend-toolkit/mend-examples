#!/bin/bash
# Prerequisites:
# apt install jq curl
# MEND_USER_KEY - An administrator's userkey
# MEND_EMAIL - The administrator's email
# WS_APIKEY - API Key for organization (optional)
# MEND_URL - e.g. https://api-saas.mend.io/api/v2.0

# If API Key was not specified then exclude from Login request body.
if [ -z "$WS_APIKEY" ]
then
        LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\" }"
else
        LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\", \"orgToken\": \"$WS_APIKEY\"}"
fi

# Log into API 2.0 and get the JWT Token and Organization UUID
LOGIN_RESPONSE=$(curl -s -X POST --location "$MEND_URL/login" --header 'Content-Type: application/json' --data-raw $LOGIN_BODY)

JWT_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.retVal.jwtToken')
WS_APIKEY=$(echo $LOGIN_RESPONSE | jq -r '.retVal.orgUuid')

# Get all products
PRODUCT_API_RESPONSE=$(curl -s --location "$MEND_URL/orgs/$WS_APIKEY/products?pageSize=10000&page=0" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
NUM_PRODUCTS=$(echo $PRODUCT_API_RESPONSE | jq -r '.additionalData.totalItems' )
PRODUCTS=$(echo $PRODUCT_API_RESPONSE | jq '.retVal')

OUTPUT="[]"

# Loop through each product in $PRODUCTS and get the uuid associated with it.
for (( i=0; i<=$NUM_PRODUCTS-1; i++ ))
do
        CURRENT_PRODUCT_TOKEN=$(echo $PRODUCTS | jq -r ".[$i].uuid" )
        echo "Getting Malicious Packages for Product $(($i+1))/$NUM_PRODUCTS: $CURRENT_PRODUCT_TOKEN"

        # Get all security alerts that have "MSC" in the name
        CURRENT_OUTPUT=$(curl -s --location "$MEND_URL/products/$CURRENT_PRODUCT_TOKEN/alerts/security?pageSize=10000&page=0&search=vulnerabilityName%3ALIKE%3AMSC" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN" | jq '.retVal')

        # Add the current value to $OUTPUT
        OUTPUT=$(echo "$OUTPUT $CURRENT_OUTPUT" | jq -s add)
done

# Extract all the information we need for an alert
OUTPUT=$(echo $OUTPUT | jq '[.[] | {productName: .product.name, projectName: .project.name, vulnId: .name, libraryName: .component.name, vulnScore: .vulnerability.vulnerabilityScoring }]')
echo -e "\nMalicious Packages: \n$OUTPUT"
