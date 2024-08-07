#!/bin/bash
#
# ******** Mend Script to Pull All policies from all hierarchy levels in a Mend Organization********
# 
# Users should edit this file to add any steps for consuming the information provided by the API requests however needed.
# 
# For more information on the APIs used, please check our REST API documentation page:
# 📚 https://docs.mend.io/bundle/mend-api-2-0/page/index.html
#
# ******** Description ********
# This script pulls all policies at the organization, product, and project level. 
# Afterwards the scripts combines all of the data pulled for each level of hierarchy.
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
# MEND_CSV - true (optional)

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
MEND_ORG_NAME=$(echo "$LOGIN_RESPONSE" | jq -r '.retVal.orgName')
MEND_ORG_UUID=$(echo "$LOGIN_RESPONSE" | jq -r '.retVal.orgUuid')

OUTPUT="{\"orgName\": \"${MEND_ORG_NAME}\", \"orgUuid\": \"$MEND_ORG_UUID\", \"policies\": [], \"products\": []}"

# Get Organization Policies
echo "Getting policies for Organization: $MEND_ORG_NAME"
ORG_POLICY_RESPONSE=$(curl -s --location "$MEND_API_URL/orgs/$MEND_ORG_UUID/policies" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
NUM_POLICIES=$(echo $ORG_POLICY_RESPONSE | jq '.retVal | length')

# Add all policies into the root level
ORG_POLICIES="[]"
for (( i=0; i<=NUM_POLICIES-1; i++ )); do
    POLICY_NAME=$(echo $ORG_POLICY_RESPONSE | jq -r ".retVal[$i].name")
    POLICY_OWNER=$(echo $ORG_POLICY_RESPONSE | jq -r ".retVal[$i].owner.email")
    ORG_POLICIES=$(echo $ORG_POLICIES | jq ". |= . + [{\"policyName\": \"$POLICY_NAME\", \"policyOwner\": \"$POLICY_OWNER\"}]")
done

# The jq expression |= allows appending an item to an array
OUTPUT=$(echo $OUTPUT | jq ".policies |= . + $ORG_POLICIES")

# Get all products
echo "Retrieving Products from Organization"
PRODUCT_API_RESPONSE=$(curl -s --location "$MEND_API_URL/orgs/$MEND_ORG_UUID/products?pageSize=10000&page=0" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
NUM_PRODUCTS=$(echo "$PRODUCT_API_RESPONSE" | jq -r '.additionalData.totalItems' )
PRODUCTS=$(echo "$PRODUCT_API_RESPONSE" | jq '.retVal')

# For each product, get the policies for it, and then get all projects and get their policies. Combine them all together at the end.
for (( i=0; i<=NUM_PRODUCTS-1; i++ )); do
        PRODUCT_NAME=$(echo $PRODUCTS | jq -r ".[$i].name")
        PRODUCT_UUID=$(echo $PRODUCTS | jq -r ".[$i].uuid")

        echo -e "\tRetrieving policies for Product: $PRODUCT_NAME"
        PRODUCT_POLICY_RESPONSE=$(curl -s --location "$MEND_API_URL/products/$PRODUCT_UUID/policies" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
        NUM_PRODUCT_POLICIES=$(echo $PRODUCT_POLICY_RESPONSE | jq '.retVal | length')

        # Our beginning product data object.
        PRODUCT_DATA="{\"productName\": \"$PRODUCT_NAME\", \"productUuid\": \"$PRODUCT_UUID\", \"policies\": [], \"projects\": []}"

        # Our beginning policy array. We combine all of the policies into one array for this iteration and then add them at the end to the larger data structure
        PRODUCT_POLICIES="[]"
        for (( j=0; j<NUM_PRODUCT_POLICIES; j++ )); do
                POLICY_NAME=$(echo $PRODUCT_POLICY_RESPONSE | jq -r ".retVal[$j].name")
                POLICY_OWNER=$(echo $PRODUCT_POLICY_RESPONSE | jq -r ".retVal[$j].owner.email")
                PRODUCT_POLICIES=$(echo $PRODUCT_POLICIES | jq ". |= . + [{\"policyName\": \"$POLICY_NAME\", \"policyOwner\": \"$POLICY_OWNER\"}]")
        done

        # Get all projects in product
        echo -e "\tRetrieving projects from product: $PRODUCT_NAME"
        PROJECT_API_RESPONSE=$(curl -s --location "$MEND_API_URL/products/$PRODUCT_UUID/projects?pageSize=10000&page=0" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
        NUM_PROJECTS=$(echo "$PROJECT_API_RESPONSE" | jq -r '.additionalData.totalItems')
        PROJECTS=$(echo "$PROJECT_API_RESPONSE" | jq '.retVal')

        for (( j=0; j<NUM_PROJECTS; j++ )); do
                PROJECT_NAME=$(echo $PROJECTS | jq -r ".[$j].name")
                PROJECT_UUID=$(echo $PROJECTS | jq -r ".[$j].uuid")
                echo -e "\t\tRetrieving policies for project: $PROJECT_NAME"
                PROJECT_POLICY_RESPONSE=$(curl -s --location "$MEND_API_URL/projects/$PROJECT_UUID/policies" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
                NUM_PROJECT_POLICIES=$(echo $PROJECT_POLICY_RESPONSE | jq '.retVal | length')

                # Our beginning project data object.
                PROJECT_DATA="{\"projectName\": \"$PROJECT_NAME\", \"projectUuid\": \"$PROJECT_UUID\", \"policies\": []}"

                # Our beginning project policy object. We combine all of the policies into one array for this iteration and then add them to the end to the larger data structure
                PROJECT_POLICIES="[]"
                for (( k=0; k<NUM_PROJECT_POLICIES; k++ )); do
                        POLICY_NAME=$(echo $PROJECT_POLICY_RESPONSE | jq -r ".retVal[$k].name")
                        POLICY_OWNER=$(echo $PROJECT_POLICY_RESPONSE | jq -r ".retVal[$k].owner.email")
                        PROJECT_POLICIES=$(echo $PROJECT_POLICIES | jq ". |= . + [{\"policyName\": \"$POLICY_NAME\", \"policyOwner\": \"$POLICY_OWNER\"}]")
                done

                PROJECT_DATA=$(echo $PROJECT_DATA | jq ".policies |= . + $PROJECT_POLICIES")
                
                # If no policies were resolved, then we skip this. We don't want to output empty data
                if [ $NUM_PROJECT_POLICIES -eq 0 ]; then
                        continue
                fi

                PRODUCT_DATA=$(echo $PRODUCT_DATA | jq ".projects |= . + [$PROJECT_DATA]")
        done

        PRODUCT_DATA=$(echo $PRODUCT_DATA | jq ".policies |= . + $PRODUCT_POLICIES")

        # Get if there were any project policies, used for the next if statement
        TOTAL_PROJECTS=$(echo $PRODUCT_DATA | jq '.projects | length')

        # If there were no project, or product policies, then skip outputting this product
        if [ $NUM_PRODUCT_POLICIES -eq 0 ] && [ $TOTAL_PROJECTS -eq 0 ]; then
                continue
        fi

        OUTPUT=$(echo $OUTPUT | jq ".products |= . + [$PRODUCT_DATA]")
done

echo -e "\n"
if [ "$MEND_CSV" = "true" ]; then
        POLICIES_OUTPUT="mend_policies.csv"
        echo "Type,PolicyName,PolicyOwner,ProductName,ProjectName" > "$POLICIES_OUTPUT"
        echo $OUTPUT | jq -r '.policies[] | "ORG,\(.policyName),\(.policyOwner),,"' >> "$POLICIES_OUTPUT"
        echo $OUTPUT | jq -r '.products[] | . as $product | .policies[] | "PRODUCT,\(.policyName),\(.policyOwner),\($product.productName)," '>> "$POLICIES_OUTPUT"
        echo $OUTPUT | jq -r '.products[] | .projects[] | . as $project | .policies[] | "PROJECT,\(.policyName),\(.policyOwner),\($project.projectName)"' >> "$POLICIES_OUTPUT"
        echo "Results CSV can be found at $(realpath $POLICIES_OUTPUT)"
else
        echo "Result: "
        echo $OUTPUT | jq '.'
fi
