#!/bin/bash
#
# ******** Mend Script to Pull Malicious Package Alerts for Notifications ********
# 
# Users should edit this file to add any steps for consuming the information provided by the API requests however needed.
# 
# For more information on the APIs used, please check our REST API documentation page:
# 📚 https://docs.mend.io/bundle/mend-api-2-0/page/index.html
#
# ******** Description ********
# This script pulls all of the products in an organization and then retrieves the Malicious Packages for each.
# Mend marks any malicious packages with a Vulnerability ID starting with: "MSC".
# A good way to get this information is to return all alerts for a product with the search filter: "search=vulnerabilityName:LIKE:MSC"
# Afterwards the scripts combines all of the data pulled for each product.
# 
# The MEND_ORG_UUID environment variable is optional. If this is not specified in the script, then the Login API will
# authenticate to the last organization the user accessed in the Mend UI.
# If the new Mend Unified Platform is not in use, then the user can get the Organization UUID for a specific organization by running the following API request:
# 📚 https://docs.mend.io/bundle/mend-api-2-0/page/index.html#tag/Access-Management-Organizations/operation/getUserDomains 

# Prerequisites:
# apt install jq curl
# MEND_USER_KEY - An administrator's userkey
# MEND_EMAIL - The administrator's email
# MEND_ORG_UUID - API Key for organization (optional)
# MEND_URL - e.g. https://saas.mend.io/

# Reformat MEND_URL for the API to https://api-<env>/api/v2.0
MEND_API_URL=$(echo "${MEND_URL}" | sed -E 's/(saas|app)(.*)/api-\1\2\/api\/v2.0/g')

# If API Key was not specified then exclude from Login request body.
if [ -z "$MEND_ORG_UUID" ]
then
	echo "MEND_ORG_UUID environment variable was not provided."
       	echo -e "The Login API will default to the last organization this user accessed in the Mend UI.\n"
        LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\" }"
else
	echo -e "Logging in with provided API key.\n"
        LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\", \"orgToken\": \"$MEND_ORG_UUID\"}"
fi

# Log into API 2.0 and get the JWT Token and Organization UUID
LOGIN_RESPONSE=$(curl -s -X POST --location "$MEND_API_URL/login" --header 'Content-Type: application/json' --data-raw "${LOGIN_BODY}")

JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.retVal.jwtToken')
MEND_ORG_UUID=$(echo "$LOGIN_RESPONSE" | jq -r '.retVal.orgUuid')

# Get all products
echo "Retrieving Products from Organization"
PRODUCT_API_RESPONSE=$(curl -s --location "$MEND_API_URL/orgs/$MEND_ORG_UUID/products?pageSize=10000&page=0" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
NUM_PRODUCTS=$(echo "$PRODUCT_API_RESPONSE" | jq -r '.additionalData.totalItems' )
PRODUCTS=$(echo "$PRODUCT_API_RESPONSE" | jq '.retVal')


# This output variable starts with nothing, and will get populated with data as we pull the alerts for each product.
OUTPUT="[]"

# Loop through each product in $PRODUCTS and get the uuid associated with it.
for (( i=0; i<=NUM_PRODUCTS-1; i++ ))
do
        CURRENT_PRODUCT_TOKEN=$(echo "$PRODUCTS" | jq -r ".[$i].uuid" )
        echo "Getting Malicious Packages for Product $((i+1))/$NUM_PRODUCTS: $CURRENT_PRODUCT_TOKEN"

        # Get all security alerts that have "MSC" in the name
        CURRENT_OUTPUT=$(curl -s --location "$MEND_API_URL/products/$CURRENT_PRODUCT_TOKEN/alerts/security?pageSize=10000&page=0&search=vulnerabilityName%3ALIKE%3AMSC" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN" | jq '.retVal' )

        if [[ "$CURRENT_OUTPUT" =~ "errorMessage" ]]; then
                ERROR_MESSAGE=$(echo "$CURRENT_OUTPUT" | jq '.errorMessage')
                echo -e "ERROR: $ERROR_MESSAGE\nUnable to get malicious packages. Continuing..."
                continue
        fi

        # This takes the current output and merges it with what is already in $OUTPUT, allowing for one JSON object to get returned for easy parsing.
        OUTPUT=$(echo "$OUTPUT $CURRENT_OUTPUT" | jq -s add)
done

# Extract all the information we need for an alert
OUTPUT=$(echo "$OUTPUT" | jq '[.[] | {productName: .product.name, projectName: .project.name, vulnId: .name, libraryName: .component.name, vulnScore: .vulnerability.vulnerabilityScoring }]')
echo -e "\nMalicious Packages: \n$OUTPUT"

# $OUTPUT can now be used in any notification process such as an email, consume it in another alerting system.
# The format of $OUTPUT will be:
# [
# 	{
# 		"productName": "productX",
#		"projectName": "projectX",
#		"vulnId": "MSC-xxxx-yyyyy",
#		"libraryName": "libraryX",
#		"vulnScore": {
#			...
#		}
# 	},
#	{
#		...
#	}
# ]
