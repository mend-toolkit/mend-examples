#!/bin/bash
## The following script is an example of using the Mend Policy engine for license compliance and creating Security Gates outside of the policy system.
## The script then downloads all relevant reports such as the risk, due dilligence, inventory, and SBOM reports and saves to a folder for publishing in a pipeline.

MEND_URL=https://saas.mend.io
MEND_EMAIL=<your service user email>
MEND_USER_KEY=<your service user token>

REPORT_DIR=${PWD}/mendreports

# Check for mendreports folder and create
create_folder() {
if [ ! -d "${REPORT_DIR}" ]; then
  mkdir -p ${REPORT_DIR}
  echo "Folder created: ${REPORT_DIR}"
else
  rm -rf ${REPORT_DIR} && mkdir -p ${REPORT_DIR}
  echo "Folder recreated: ${REPORT_DIR}"
fi
}

# Parse the Mend CLI output from from scanresults.txt and check for critical severity
check_critical_severity() {
critvulns=$(grep -i "critical" ${REPORT_DIR}/scanresults.txt | grep -i "upgrade")
if [ -n "$critvulns" ]; then
    echo "The following critical vulnerabilities were found."
    echo "$critvulns"
    echo "Please fix these vulnerabilities, you can use the dependency table in ${PWD}/mendreports/scanresults.txt to see the dependency hierachy"
    exit 1
else 
    echo " No critical vulnerabilities were found in your scan"
fi
}

# Parse the Mend CLI output from from scanresults.txt and check for fixable high severity
check_high_severity() {
highvulns=$(grep -i "high" ${REPORT_DIR}/scanresults.txt | grep -i "upgrade")
if [ -n "$highvulns" ]; then
    echo "The following high vulnerabilities were found."
    echo "$highvulns"
    echo "Please fix these vulnerabilities, you can use the dependency table in ${REPORT_DIR}/scanresults.txt to see the dependency hierachy"
    exit 1
else 
    echo "No high vulnerabilities were found in your scan"
fi
}

# Create reports
create_reports() {
WS_PROJECTTOKEN=$(grep -oP "(?<=token=)[^&]+" ${PWD}/mendreports/scanresults.txt)
echo "Creating Project Risk Report"
curl -o ${REPORT_DIR}/riskreport.pdf -X POST "${MEND_URL}/api/v1.4" -H "Content-Type: application/json"  -d '{"requestType":"getProjectRiskReport","userKey":"'${MEND_USER_KEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'
echo "Creating Project Inventory Report"
curl -o ${REPORT_DIR}/inventoryreport.xlsx -X POST "${MEND_URL}/api/v1.4" -H "Content-Type: application/json"  -d '{"requestType":"getProjectInventoryReport","userKey":"'${MEND_USER_KEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'
echo "Creating Project Due Diligence Report"
curl -o ${REPORT_DIR}/duediligencereport.xlsx -X POST "${MEND_URL}/api/v1.4" -H "Content-Type: application/json"  -d '{"requestType":"getProjectDueDiligenceReport","userKey":"'${MEND_USER_KEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'
}

create_sbom() {
WS_PROJECTTOKEN=$(grep -oP "(?<=token=)[^&]+" ${PWD}/mendreports/scanresults.txt)
WS_APIKEY=$(grep -o '"OrgUuid": "[^"]*' ~/.mend/config/settings.json | awk -F'"' '{print $4}')

#Generate Report
get_proj_resp=$(curl -s -X POST -H "Content-Type:application/json" -d '{"requestType":"generateProjectReportAsync","projectToken":"'$WS_PROJECTTOKEN'","userKey":"'$MEND_USER_KEY'","reportType":"ProjectSBOMReport", "standard":"spdx" , "format":"json"}' $MEND_URL/api/v1.4)
echo "Report generation call sent for ProjectSBOMReport"

# Get info from response
procId="$(echo "$get_proj_resp" | jq -r '.asyncProcessStatus.uuid')"
contextType="$(echo "$get_proj_resp" | jq -r '.asyncProcessStatus.contextType')"
processType="$(echo "$get_proj_resp" | jq -r '.asyncProcessStatus.processType')"

# Check Status
ready=false
while [[ $ready = "false" ]] ; do
	resProcess=$(curl -s -X POST -H "Content-Type:application/json" -d '{"requestType":"getAsyncProcessStatus","orgToken":"'$WS_APIKEY'","userKey":"'$MEND_USER_KEY'","uuid":"'$procId'"}' $MEND_URL/api/v1.4)
	repStatus="$(echo "$resProcess" | jq -r '.asyncProcessStatus.status')"
	if [[ $repStatus = "FAILED" ]] ; then
		echo "Report FAILED"
		echo "$resProcess" | jq .
		exit 1
	elif [[ $repStatus = "SUCCESS" ]] ; then
		ready=true
		repType="$(echo "$resProcess" | jq -r '.asyncProcessStatus.processType')"
		reportFile="${PWD}/$repType.zip"

		# Download the Report
		echo "Downloading report..."
		curl -s -X POST -H "Content-Type:application/json" -d '{"requestType":"downloadAsyncReport","orgToken":"'$WS_APIKEY'","userKey":"'$MEND_USER_KEY'","reportStatusUUID":"'$procId'"}' --output "$reportFile" $MEND_URL/api/v1.4
	else
		sleep 5
	fi
done
reportDir="${PWD}/mendreports"
unzip $reportFile -d $reportDir && rm $reportFile
# Publish the mendreports folder according to your pipeline instructions
}

create_folder
# Scan with Mend Dependency
mend deps -u --fail-policy --no-color > ${REPORT_DIR}/scanresults.txt
create_reports
create_sbom
check_critical_severity
check_high_severity