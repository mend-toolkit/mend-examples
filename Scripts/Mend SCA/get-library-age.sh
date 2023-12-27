#!/bin/bash
#
# ******** Mend Script to get the Age for Libraries in an Organization ********
#
# Users should edit this file to add any steps for consuming the information provided by the API requests however needed.
# The user can also edit this script to only do this for a single product if needed.
#
# For more information on the APIs used, please check our REST API documentation page:
# 📚 https://docs.mend.io/bundle/mend-api-2-0/page/index.html
#
# ******** Description ********
# This script pulls all of the products in an organization and then retrieves the direct dependencies for each product 
# where the release date for the version is greater than the specified amount.
#
# Out of the box, this script does not perform the lookup for transitive dependencies due to the fact that
# with most languages updating transitive libraries is either difficult or impossible. With the languages that do
# allow upgrading transitive dependencies, this can cause errors inside of the final product, and is typically not 
# a good practice.
#
# Afterwards the scripts combines all of the data pulled for each product and displays it in JSON format.
#
# The WS_API_KEY environment variable is optional. If this is not specified in the script, then the Login API will
# authenticate to the last organization the user accessed in the Mend UI.

# Prerequisites:
# apt install jq curl
# MEND_USER_KEY - An administrator's userkey
# MEND_EMAIL - The administrator's email
# WS_APIKEY - API Key for organization (optional)
# MEND_URL - e.g. https://saas.mend.io/
# MAX_AGE_IN_DAYS - The number of days ago that a library version can be released before getting added to the output.

# Reformat MEND_URL for the API to https://api-<env>/api/v2.0
MEND_API_URL=$(echo "${MEND_URL}" | sed -E 's/(saas|app)(.*)/api-\1\2\/api\/v2.0/g')

# If API Key was not specified then exclude from Login request body.
if [ -z "$WS_APIKEY" ]
then
	echo "WS_APIKEY environment variable was not provided."
	echo "The Login API will default to the last organization this user accessed in the Mend UI."
	LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\" }"
else
	echo "Logging in with provided API key."
	LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\", \"orgToken\": \"$WS_APIKEY\"}"
fi

# Log into API 2.0 and get the JWT Token and Organization UUID
LOGIN_RESPONSE=$(curl -s -X POST --location "$MEND_API_URL/login" --header 'Content-Type: application/json' --data-raw "${LOGIN_BODY}")

JWT_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.retVal.jwtToken')
WS_APIKEY=$(echo $LOGIN_RESPONSE | jq -r '.retVal.orgUuid')

# Get all products
echo "Retrieving Products from Organization"
PRODUCT_API_RESPONSE=$(curl -s --location "$MEND_API_URL/orgs/$WS_APIKEY/products?pageSize=10000&page=0" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
NUM_PRODUCTS=$(echo $PRODUCT_API_RESPONSE | jq -r '.additionalData.totalItems' )
PRODUCTS=$(echo $PRODUCT_API_RESPONSE | jq '.retVal')

# This output variable starts with nothing, and will get populated with data as we pull the information needed.
OUTPUT="[]"

# Loop throught each product in $PRODUCTS and get all libraries. Get the UUID for each library and then get the releaseDate information from each.
for (( i=0; i<=$NUM_PRODUCTS-1; i++ ))
do
	CURRENT_PRODUCT_TOKEN=$(echo $PRODUCTS | jq -r ".[$i].uuid" )
	echo  "Getting all direct dependencies for Product $(($i+1))/$NUM_PRODUCTS: $CURRENT_PRODUCT_TOKEN"

	# Get all direct dependencies for the current product in loop
	CURRENT_LIBRARIES_RESPONSE=$(curl -s --location "$MEND_API_URL/products/$CURRENT_PRODUCT_TOKEN/libraries?pageSize=10000&page=0&search=directDependency:LIKE:true" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN") 
	CURRENT_LIBRARIES=$(echo $CURRENT_LIBRARIES_RESPONSE | jq '.retVal')
	NUM_LIBRARIES=$(echo $CURRENT_LIBRARIES_RESPONSE | jq -r '.additionalData.totalItems')

	for (( j=0; j<=$NUM_LIBRARIES-1; j++ ))
	do
		CURRENT_LIBRARY=$(echo $CURRENT_LIBRARIES | jq ".[$j]")
		DIRECT_DEPENDENCY=$(echo $CURRENT_LIBRARY | jq -r ".directDependency")

		LIBRARY_NAME=$(echo $CURRENT_LIBRARY | jq -r ".groupId")
		LIBRARY_UUID=$(echo $CURRENT_LIBRARY | jq -r ".uuid")
		LIBRARY_VERSION=$(echo $CURRENT_LIBRARY | jq -r ".version")

		# Get the release date for a library version using the library versions API
		echo -ne "\033[2KGetting Release Date for library $(($j+1))/$NUM_LIBRARIES: $LIBRARY_NAME:$LIBRARY_VERSION\r"
		VERSION_RESPONSE=$(curl -s --location "$MEND_API_URL/orgs/$WS_APIKEY/libraries/$LIBRARY_UUID/versions?ignoreManualData=false" --header 'Content-Type: application/json' --header "Authorization: Bearer $JWT_TOKEN")
		RELEASE_DATE=$(echo $VERSION_RESPONSE | jq -r ".retVal[] | select(.version == \"$LIBRARY_VERSION\") | .lastUpdatedAt")
		
		# If release date is not returned by the API, then the user should check it manually
		if [ -z "$RELEASE_DATE" ]
		then
			RELEASE_DATE="Not stored in Mend index, please check this manually"
		else
			RELEASE_DATE_FORMATTED=$(echo $RELEASE_DATE | date -d $RELEASE_DATE '+%s')
			CURRENT_DATE_FORMATTED=$(date '+%s')
			DIFF=$(($CURRENT_DATE_FORMATTED - $RELEASE_DATE_FORMATTED))
		fi
		
		# If the library needs to be reviewed later then get all relevant information and add to output
		if [ $DIFF -gt $(($MAX_AGE_IN_DAYS*60*60)) ] || [ "$RELEASE_DATE" == "Not stored in Mend index, please check this manually" ]
		then
			LIBRARY_PROJECT=$(echo $CURRENT_LIBRARY | jq -r ".project.name")
			LIBRARY_PRODUCT=$(echo $CURRENT_LIBRARY | jq -r ".project.path")
			RETURN_LIBRARY=$(jq --null-input \
				--arg libraryName "$LIBRARY_NAME" \
				--arg libraryVersion "$LIBRARY_VERSION" \
				--arg directDependency "$DIRECT_DEPENDENCY" \
				--arg product "$LIBRARY_PRODUCT" \
				--arg project "$LIBRARY_PROJECT" \
				--arg releaseDate "$RELEASE_DATE" \
				'[{"libraryName": $libraryName, "libraryVersion": $libraryVersion, "directDependency": $directDependency, "product": $product, "project": $project, "releaseDate": $releaseDate}]')
			
			# This adds the current library to the list of libraries that need to be reported
			OUTPUT=$(echo "$OUTPUT $RETURN_LIBRARY" | jq -s add)
		fi
	done

	echo "" 
done

echo -e "Output: \n$(echo $OUTPUT | jq '.')"

# $OUTPUT can now be used to generate a report however needed, such as converting to CSV, XLSX, or PDF format with other utilities.
# The format of $OUTPUT will be:
# [
# 	{
#		"libraryName": "<library_name>",
#		"libraryVersion": "<library_version>",
#		"directDependency": "<true|false>",
#		"product": "<product_name>",
#		"project": "<project_name>",
#		"releaseDate": "<release_date>"
#	},
#	{
#		...
#	}
# ]
