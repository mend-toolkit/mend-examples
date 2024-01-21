#!/bin/bash
#
# ******** Mend Script to Generate a Report Asynchronously ********
# 
# Users should edit this file to change any required behavior.
# 
# For more information on the APIs used, please check our REST API documentation page:
# 📚 https://docs.mend.io/bundle/api_sca/page/http_api_v1_3_and_v1_4.html
#
# ******** Description ********
# This script submits a request to asynchronously geneate a Mend Report and then downloads it when ready.
#
# The MEND_ORG_UUID environment variable is required. 
# If the new Mend Unified Platform is not in use, then the user can get the Organization UUID for a specific organization by running the following API request:
# 📚 https://docs.mend.io/bundle/mend-api-2-0/page/index.html#tag/Access-Management-Organizations/operation/getUserDomains 
#
#
# Prerequisites:
# apt install jq curl
# MEND_URL - e.g. https://saas.mend.io/agent
# MEND_USER_KEY - An administrator's userkey
# MEND_ORG_UUID - API Key for organization (optional)
# MEND_PRODUCT_UUID or MEND_PROJECT_UUID depending on the report scope
#
# ******** Usage ********
# To run this script, a user should set the following environment variables:
# export MEND_REPORTTYPE=<exampleReport>
#   Comments: Lists of accepted values for 'reportType' are avialable here:
#       - Organization: https://docs.mend.io/bundle/api_sca/page/reports_api_-_asynchronous.html#generateOrganizationReportAsync
#       - Product:      https://docs.mend.io/bundle/api_sca/page/reports_api_-_asynchronous.html#generateProductReportAsync
#       - Project:      https://docs.mend.io/bundle/api_sca/page/reports_api_-_asynchronous.html#generateProjectReportAsync%C2%A0
# export MEND_REPORTSCOPE=[ Organization | Product | Project ]
# export MEND_REPORTFORMAT=[ xlsx | json | xml | pdf ]
#   Comments:   Not all reports support all formats.
#               Refer to the Asynchronous Reports API documentation for available formats:
#               https://docs.mend.io/bundle/api_sca/page/reports_api_-_asynchronous.html
# export MEND_REPORTFILTER='{"key1": "value1", "key2": "value2"}'
#   Comments:   Refer to the Asynchronous Reports API documentation for full reference on available report filters:
#               https://docs.mend.io/bundle/api_sca/page/reports_api_-_asynchronous.html
# export MEND_REPORTCHECKFREQ=5
#   Comments:   Interval (in seconds) for checking whether the report is ready.
# export MEND_STANDARD=[ CycloneDx | spdx ]

# After setting the above environment variables, the user should run:
# chmod +x ./generate-async-report.sh && ./generate-async-report.sh

# Example 1
# MEND_REPORTTYPE=OrgInventoryReport
# MEND_REPORTSCOPE=Organization
# MEND_REPORTFORMAT=xlsx
# MEND_REPORTFILTER='{}'

# Example 2
# export MEND_REPORTTYPE=ProductAttributionReport
# export MEND_REPORTSCOPE=Product
# # export MEND_REPORTFORMAT=json
# export MEND_REPORTFILTER='{
# 	"reportTitle": "'"$reportScope Attribution Report - ProductName"'",
# 	"reportHeader": "Example Header Text",
# 	"reportFooter": "Example Footer Text",
# 	"reportingScope": "SUMMARY, LICENSES, COPYRIGHTS, NOTICES, PRIMARY_ATTRIBUTES",
# 	"reportingAggregationMode": "BY_COMPONENT",
# 	"missingLicenseDisplayOption": "BLANK",
# 	"licenseReferenceTextPlacement": "LICENSE_SECTION",
# 	"exportFormat": "HTML"
# }'

# Example 3
# export MEND_REPORTTYPE=RiskReport
# export MEND_REPORTSCOPE=Product
# export MEND_REPORTFORMAT=pdf

# Example 4
# export MEND_REPORTTYPE=ProjectSBOMReport
# export MEND_REPORTSCOPE=Project
# export MEND_REPORTFORMAT=json
# export MEND_STANDARD=CycloneDx

# Example 5
# export MEND_REPORTTYPE=ProjectSBOMReport
# export MEND_REPORTSCOPE=Project
# export MEND_REPORTFORMAT=json
# export MEND_STANDARD=spdx

#------------------------------------------------

[[ -z $MEND_CHECKFREQ ]] && MEND_CHECKFREQ=5
MEND_REPORTFILTER="$(echo "$MEND_REPORTFILTER" | tr -d '\t' | tr -d '\n')"
[[ -z $MEND_USER_KEY ]] && echo "No MEND_USER_KEY specified" && exit
[[ -z $MEND_ORG_UUID ]] && echo "No MEND_ORG_UUID specified" && exit
[[ -z $MEND_URL ]] && echo "No MEND_URL specified" && exit
if [[ $MEND_URL == */agent ]]; then
	export MEND_API_URL="$(echo "$MEND_URL" | sed 's|agent|api/v1.4|')"
else
    echo "MEND_URL variable does not end with '/agent'" && exit
fi


if [[ "$MEND_REPORTSCOPE" = "Organization" ]] ; then
	[[ -z $MEND_ORG_UUID ]] && echo "No MEND_ORG_UUID specified and MEND_REPORTSCOPE=Organization" && exit
	tokenScope=org
	token=$MEND_ORG_UUID
elif [[ "$MEND_REPORTSCOPE" = "Product" ]] ; then
	[[ -z $WS_PRODUCTTOKEN ]] && echo "No WS_PRODUCTTOKEN specified and MEND_REPORTSCOPE=Product" && exit
	tokenScope=product
	token=$WS_PRODUCTTOKEN
elif [[ "$MEND_REPORTSCOPE" = "Project" ]] ; then
	[[ -z $WS_PROJECTTOKEN ]] && echo "No WS_PROJECTTOKEN specified and MEND_REPORTSCOPE=Project" && exit
	tokenScope=project
	token=$WS_PROJECTTOKEN
fi

# Generate Report
reqBody='"requestType":"generate'$MEND_REPORTSCOPE'ReportAsync","'$tokenScope'Token":"'$token'","userKey":"'$MEND_USER_KEY'","reportType":"'$reportType'", "standard":"'$MEND_STANDARD'"'
[[ -n $MEND_REPORTFORMAT ]] && reqBody="$reqBody"',"format":"'$MEND_REPORTFORMAT'"'
[[ -n $MEND_REPORTFILTER ]] && reqBody="$reqBody"',"filter":'"$MEND_REPORTFILTER"
reqBody='{'"$reqBody"'}'
resGenerate=$(curl -s -X POST -H 'Content-Type:application/json' --data-raw "$reqBody" $MEND_API_URL)
#TODO: Add error handling
echo "Report generation call sent for MEND_REPORTTYPE=$reportType and MEND_REPORTSCOPE=$MEND_REPORTSCOPE"
procId="$(echo "$resGenerate" | jq -r '.asyncProcessStatus.uuid')"
contextType="$(echo "$resGenerate" | jq -r '.asyncProcessStatus.contextType')"
processType="$(echo "$resGenerate" | jq -r '.asyncProcessStatus.processType')"

# Check Status
reqBody='{"requestType":"getAsyncProcessStatus","orgToken":"'$MEND_ORG_UUID'","userKey":"'$MEND_USER_KEY'","uuid":"'$procId'"}'
ready=false
while [[ $ready = "false" ]] ; do
	resProcess="$(curl -s -X POST -H 'Content-Type:application/json' --data-raw "$reqBody" $MEND_API_URL)"
	repStatus="$(echo "$resProcess" | jq -r '.asyncProcessStatus.status')"
	if [[ $repStatus = "FAILED" ]] ; then
		echo "Report FAILED"
		echo "$resProcess" | jq .
		exit 1
	elif [[ $repStatus = "SUCCESS" ]] ; then
		ready=true
		repType="$(echo "$resProcess" | jq -r '.asyncProcessStatus.processType')"
		reportFile="$(pwd)/$repType.zip"

		# Download the Report
		echo "Downloading report..."
		reqBody='{"requestType":"downloadAsyncReport","orgToken":"'$MEND_ORG_UUID'","userKey":"'$MEND_USER_KEY'","reportStatusUUID":"'$procId'"}'
		# resProcess="$(curl -s -X POST -H 'Content-Type: application/json' --data-raw "$reqBody" --output "reportFile" $MEND_API_URL)"
		curl -s -X POST -H 'Content-Type:application/json' --data-raw "$reqBody" --output "$reportFile" "$MEND_API_URL"
	else
		sleep $MEND_CHECKFREQ
	fi
done
reportDir="$(pwd)/mendreports"
unzip $reportFile -d $reportDir && rm $reportFile

# Publish the mendreports folder according to your pipeline instructions