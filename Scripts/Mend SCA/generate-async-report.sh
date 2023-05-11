#!/bin/bash

# Description:
# This script submits an asynchronous request for generating a Mend report
# and downloads it when ready.

# Prerequisites:
# apt install curl jq

# Required Environment Variables:
# WS_APIKEY or WS_PRODUCTTOKEN or WS_PROJECTTOKEN
# WS_USERKEY
# WS_WSS_URL

# Parameters:
#================================================
# Name:     reportType
# Type:     enum
# Value:    
# Example:  reportType=ProductAttributionReport
# Comments: Lists of accepted values for 'reportType' are avialable here:
#           - Organization: https://docs.mend.io/bundle/api/page/reports_api_-_asynchronous.html#generateOrganizationReportAsync
#           - Product:      https://docs.mend.io/bundle/api/page/reports_api_-_asynchronous.html#generateProductReportAsync
#           - Project:      https://docs.mend.io/bundle/api/page/reports_api_-_asynchronous.html#generateProjectReportAsync
#------------------------------------------------
# Name:     reportScope
# Type:     enum
# Value:    [ Organization | Product | Project ]
# Example:  reportScope=Product
# Comments: 
#------------------------------------------------
# Name:     reportFormat=xlsx
# Type:     enum
# Value:    [ xlsx | json | xml | pdf ]
# Example:  reportFormat=xlsx
# Comments: Not all reports support all formats.
#           reportFormat=pdf is only supported for reportType=RiskReport.
#           Refer to the 'Reports API - Synchronous' documentation for full reference on available report formats:
#           https://docs.mend.io/bundle/api/page/reports_api_-_synchronous.html
#------------------------------------------------
# Name:     reportFilter
# Type:     json (string)
# Value:    {}
# Example:  reportFilter='{
#                           "reportingScope": "SUMMARY, LICENSES, COPYRIGHTS",
#                           "reportingAggregationMode": "BY_PROJECT"
#                         }'
# Comments: Refer to the 'Reports API - Synchronous' documentation for full reference on available report filters:
#           https://docs.mend.io/bundle/api/page/reports_api_-_synchronous.html
#------------------------------------------------
# Name:     checkFreq
# Type:     int
# Value:    1-60
# Example:  checkFreq=5
# Comments: Interval (in seconds) for checking whether the report is ready 
#------------------------------------------------


# Example 1
reportType=OrgInventoryReport
reportScope=Organization
reportFormat=xlsx
reportFilter='{}'

# Example 2
# reportType=ProductAttributionReport
# reportScope=Product
# # reportFormat=json
# reportFilter='{
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
# reportType=RiskReport
# reportScope=Product
# reportFormat=pdf

# Example 4
# reportType=ProjectSPDXReport
# reportScope=Project
# reportFormat=json

#------------------------------------------------

[[ -z $checkFreq ]] && checkFreq=5
reportFilter="$(echo "$reportFilter" | tr -d '\t' | tr -d '\n')"
[[ -z $WS_USERKEY ]] && echo "No WS_USERKEY specified" && exit
[[ -z $WS_WSS_URL ]] && echo "No WS_WSS_URL specified" && exit



if [[ "$reportScope" = "Organization" ]] ; then
	tokenScope=org
	token=$WS_APIKEY
elif [[ "$reportScope" = "Product" ]] ; then
	tokenScope=product
	token=$WS_PRODUCTTOKEN
elif [[ "$reportScope" = "Project" ]] ; then
	tokenScope=project
	token=$WS_PROJECTTOKEN
fi

# Generate Report
reqBody='"requestType":"generate'$reportScope'ReportAsync","'$tokenScope'Token":"'$token'","userKey": "'$WS_USERKEY'","reportType":"'$reportType'"'
[[ -n $reportFormat ]] && reqBody="$reqBody"',"format":"'$reportFormat'"'
[[ -n $reportFilter ]] && reqBody="$reqBody"',"filter":'"$reportFilter"
reqBody='{'"$reqBody"'}'

procId="$(echo "$resGenerate" | jq -r '.asyncProcessStatus.uuid')"
contextType="$(echo "$resGenerate" | jq -r '.asyncProcessStatus.contextType')"
processType="$(echo "$resGenerate" | jq -r '.asyncProcessStatus.processType')"

# Check Status
reqBody='{"requestType":"getAsyncProcessStatus","'$tokenScope'Token":"'$token'","userKey":"'$WS_USERKEY'","uuid":"'$procId'"}'

ready=false
while [[ $ready = "false" ]] ; do
	resProcess="$(curl -s -X POST -H 'Content-Type: application/json' --data-raw "$reqBody" $WS_WSS_URL/api/v1.3)"
	repStatus="$(echo "$resProcess" | jq -r '.asyncProcessStatus.status')"

	if [[ $repStatus = "FAILED" ]] ; then
		echo "Report FAILED"
		echo "$resProcess" | jq .
		exit 1
	elif [[ $repStatus = "SUCCESS" ]] ; then
		ready=true
		repType="$(echo "$resProcess" | jq -r '.asyncProcessStatus.processType')"
		reportFile="~/Temp/$repType.zip"

		# Download the Report
		echo "Downloading report..."
		reqBody='{"requestType":"downloadAsyncReport","'$tokenScope'Token":"'$token'","userKey":"'$WS_USERKEY'","reportStatusUUID":"'$procId'"}'
		# resProcess="$(curl -s -X POST -H 'Content-Type: application/json' --data-raw "$reqBody" --output "reportFile" $WS_WSS_URL/api/v1.3)"
		curl -s -X POST -H 'Content-Type: application/json' --data-raw "$reqBody" --output "reportFile" "$WS_WSS_URL/api/v1.3"
	else
		sleep $checkFreq
	fi
done
