![Logo](https://mend-toolkit-resources-public.s3.amazonaws.com/img/mend-io-logo-horizontal.svg)  

# Mend SCA Scripts
This folder contains scripts for use with the Mend SCA platform and Unified agent scanning within a CI/CD pipeline.

- [Reports Within a Pipeline](#reports-within-a-pipeline)
- [SBOM Report Generation](#sbom-report-generation)
- [Get all Users that are part of Organizations which are a part of a Global Organization](#get-all-users-that-are-part-of-organizations-which-are-a-part-of-a-global-organization)
- [Get all libraries where the used version is older than X days](#get-all-libraries-where-the-used-version-is-older-than-x-days)
- [Get all malicious packages in an organization](#get-all-malicious-packages-in-an-organization)
- [Group Permissions](#group-permissions)
- [Scan Errors](#scan-errors)
- [Get All Policies in an Organization](#get-all-organization-policies)

### Unified Agent Scripts  
The following scripts are designed to be used with the Unified Agent. Currently, it is recommended to use the Mend CLI for scanning purposes. However, these scripts can be used to bridge the gap between the Mend Unified Agent and the CLI in cases where the Unified Agent is required.

- [Cache the Latest Version of the Unified Agent](#cache-the-latest-version-of-the-unified-agent)
- [Display Vulnerabilities Affecting a Project](#display-vulnerabilities-affecting-a-project)
- [Display Policy Violations Following a Scan](#display-policy-violations-following-a-scan)
- [Export a Product's Last Scan Date](#export-a-products-last-scan-date)
- [Reports Within a Pipeline for UA](#reports-within-a-pipeline-for-ua)
- [Feature Branch Scan](#feature-branch-scan)

<hr/>


## [SBOM Report Generation](https://github.com/mend-toolkit/Mend-SBOM-Export-CLI)

An example using the sbom-export-cli with Mend Unified CLI can be found in the [AzureDevOps Advanced example](../../CI-CD/AzureDevOps/Mend%20CLI/AzureDevOps-advanced-linux.yml)

<br>
<hr>

## Pending task cleanup

[pending-task-cleanup.sh](pending-task-cleanup.sh)  

This script allows the user to cleanup outstanding [Pending Tasks](https://docs.mend.io/bundle/wsk/page/ui_-_request_history_report_and_pending_tasks.html) in the Mend SCA UI, when this process is no longer required. Please ensure the setting '[Open pending tasks for new libraries](https://docs.mend.io/bundle/wsk/page/ui_-_request_history_report_and_pending_tasks.html)' is disabled under the Integrate, Advanced Settings area. In addition, also ensure that their are no [Policies](https://docs.mend.io/bundle/sca_user_guide/page/managing_automated_policies.html#Applying-Actions-to-a-Library) that are 'Reassign' or 'Condition', which could create new tasks. 

The [pending-task-cleanup.sh](pending-task-cleanup.sh) script is designed to be executed one time per organization to clean up historic pending requests the Mend SCA UI. 

<br>

**Prerequisites:**  

* `jq` and `curl` must be installed
* The tasks within Mend should be assigned to a user and not to a group (Edit policy->Reasssign->Assign to User) as the getDomainPendingTasks API is based off of tasks assigned to a user

<br>

**Execution:**  

```
export MEND_URL=https://saas.mend.io
export WS_APIKEY=x
export MEND_USER_KEY=x
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Mend%20SCA/pending-task-cleanup.sh 
chmod +x ./pending-task-cleanup.sh && ./pending-task-cleanup.sh
```


## Get all libraries where the used version is older than X days

[get-library-ages.py](get-library-ages.py)  

This script allows the retrieval of all libraries in a product or organization that were released longer than X days ago. This allows a user to check the age of a library and make sure it is the version they want.

The [get-library-ages.py](get-library-ages.py) script can be added to the CI/CD pipeline on a static/hosted build agent (prior to the Unified Agent scan task), or triggered independently, manually or by a scheduled task.  

<br>

**Prerequisites:**  

* ``pip3 install requests python-dateutil``
* ``export MEND_USER_KEY='<MEND_USER_KEY>'``
* ``export MEND_URL='<MEND_URL>``
* ``export MEND_EMAIL='<MEND_EMAIL>'``

<br>

**Execution:**  

```
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Mend%20SCA/get-library-ages.py
python3 ./get-library-ages.py
```

<br>
<hr>

## Get all malicious packages in an organization

[get-malicious-packages.sh](get-malicious-packages.sh)  

This script allows a user to retrieve all malicious packages in an organization for reporting purposes.

The [get-malicious-packages.sh](get-malicious-packages.sh) script can be added to the CI/CD pipeline on a static/hosted build agent (prior to the Unified Agent scan task), or triggered independently, manually or by a scheduled task.  

<br>

**Prerequisites:**  

* ``sudo apt-get install jq curl``
* ``export MEND_USER_KEY`` - An administrator's userkey
* ``MEND_EMAIL`` - The administrator's email
* ``MEND_ORG_UUID`` - API Key for organization (optional)
* ``MEND_URL`` - e.g. https://saas.mend.io/

<br>

**Execution:**  

```
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Mend%20SCA/get-malicious-packages.sh
chmod +x ./get-malicious-packages.sh && ./get-malicious-packages.sh
```

<br>
<hr>

## Group Permissions

[group-permissions.sh](group-permissions.sh)  

This script allows an admin to update organization groups with specific permissions.  The default will update an organization group to have read only(user) permissions.
Role permissions are visible in the API documentation for [addGroupRoles](https://docs.mend.io/bundle/mend-api-2-0/page/index.html#tag/User-Management-Groups/operation/addGroupRoles)

<br>

**Prerequisites:**  

* ``sudo apt-get install jq curl``
* ``export MEND_USER_KEY`` - An administrator's userkey
* ``export MEND_EMAIL`` - The administrator's email
* ``export MEND_ORG_UUID`` - API Key for organization (optional)
* ``export MEND_URL`` - e.g. https://saas.mend.io/

<br>

**Execution:**  

```
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Mend%20SCA/group-permissions.sh
chmod +x ./group-permissions.sh && ./group-permissions.sh my-group-name role-permissions
```

<br>
<hr>

## Scan Errors

[scanerrors.sh](scanerrors.sh)  

This script allows an admin to to find projects with scanError tags.  This is useful when troublehshooting [hostRules](https://docs.mend.io/bundle/wsk/page/hostrules_implementation_examples.html) within the Mend repository integration.

<br>

**Prerequisites:**  

* ``sudo apt-get install jq curl``
* ``export MEND_USER_KEY`` - An administrator's userkey
* ``export MEND_EMAIL`` - The administrator's email
* ``export MEND_ORG_UUID`` - API Key for organization (optional)
* ``export MEND_URL`` - e.g. https://saas.mend.io/

<br>

**Execution:**  

```
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Mend%20SCA/scanerrors.sh
chmod +x ./scanerrors.sh && ./scanerrors.sh
```

<br>
<hr>

## Get All Organization Policies

[get-all-policies.sh](get-all-policies.sh)  

This script allows a user to retrieve all policies from an organization at every level in the organization hierarchy (Organization, Product, and Project)
<br>

**Prerequisites:**  

* ``sudo apt-get install jq curl``
* ``export MEND_USER_KEY`` - An administrator's userkey
* ``export MEND_EMAIL`` - The administrator's email
* ``export MEND_ORG_UUID`` - API Key for organization (optional)
* ``export MEND_URL`` - e.g. https://saas.mend.io/

<br>

**Execution:**  

```
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Mend%20SCA/get-all-policies.sh
chmod +x ./get-all-policies.sh && ./get-all-policies.sh
```

<br>
<hr>


# Unified Agent Only Scripts

**All scripts & snippets besides [Cache Unified Agent](#cache-the-latest-version-of-the-unified-agent) in this section that are utilized in a pipeline should call [check-project-state.sh](check-project-state.sh) before running to ensure that the scan has completed.**

It is also assumed that the following environment variables are set when running the Unified Agent as they are required to perform a scan
- WS_APIKEY
- WS_PRODUCTNAME
- WS_PROJECTNAME

## Cache the Latest Version of the Unified Agent

[cache-ua.sh](cache-ua.sh)  

This script allows caching of the [WhiteSource Unified Agent](https://whitesource.atlassian.net/wiki/spaces/WD/pages/1140852201/Getting+Started+with+the+Unified+Agent), so you can periodically check for updates and download the latest version only if needed, rather than redundantly downloading prior to every scan.  

The [cache-ua.sh](cache-ua.sh) script can be added to the CI/CD pipeline on a static/hosted build agent (prior to the Unified Agent scan task), or triggered independently, manually or by a scheduled task.  

<br>

**Prerequisites:**  

* `jq` and `curl` must be installed

<br>

**Execution:**  

```
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Mend%20SCA/cache-ua.sh
chmod +x ./cache-ua.sh && ./cache-ua.sh
```

See additional examples for implementation within a build pipeline under [CI-CD](../CI-CD/README.md#caching-the-unified-agent) (`*-cached-ua.yml`).  


<br>
<hr>

## Display Vulnerabilities Affecting a Project

[list-project-alerts.sh](list-project-alerts.sh)  

This script can be added to the CI/CD pipeline (or executed independently) following the WhiteSource Unified Agent scan, to list vulnerabilities affecting the last scanned project(s).  

This script parses the `scanProjectDetails.json` file to get the `name` and `projectToken` of the project(s) created/updated during the last scan, and then uses WhiteSource's [getProjectAlertsByType](https://whitesource.atlassian.net/wiki/spaces/WD/pages/1651769359/Alerts+API#Project.2) API request to retrieve all the vulnerability alerts associated with that project. It then prints them to the standard output (`stdout`), sorted by severity and optionally color-coded.  

<br>

**Prerequisites:**  

* Check that the project state is [finished](check-project-state.sh)
* `jq` and `curl` must be installed
* ENV variables must be set
  * `WS_GENERATEPROJECTDETAILSJSON: true`
  * `WS_USERKEY` (admin assignment is required)
  * `WS_WSS_URL`
  * `WS_UPDATEINVENTORY: true` (defaults to true)

<br>

**Execution:**  

```
./list-project-alerts.sh
```
**Sample Output:**  
```
Alerts for project: vulnerable-node
Alerts: 10 High, 4 Medium, 2 Low

[H] CVE-2017-16138 - mime-1.3.4.tgz
[H] CVE-2015-8858 - uglify-js-2.3.0.tgz
[H] CVE-2017-1000228 - ejs-0.8.8.tgz
[H] CVE-2017-1000048 - qs-4.0.0.tgz
[H] CVE-2020-8203 - lodash-4.17.11.tgz
[H] CVE-2021-23337 - lodash-4.17.11.tgz
[H] CVE-2019-5413 - morgan-1.6.1.tgz
[H] CVE-2019-10744 - lodash-4.17.11.tgz
[H] CVE-2017-16119 - fresh-0.3.0.tgz
[H] CVE-2015-8857 - uglify-js-2.3.0.tgz
[M] CVE-2020-28500 - lodash-4.17.11.tgz
[M] CVE-2017-16137 - debug-2.2.0.tgz
[M] CVE-2019-14939 - mysql-2.12.0.tgz
[M] WS-2018-0080 - mysql-2.12.0.tgz
[L] WS-2018-0589 - nwmatcher-1.3.9.tgz
[L] WS-2017-0280 - mysql-2.12.0.tgz
```

See known limitations [here](list-project-alerts.sh).  

<br>
<hr>

## Display Policy Violations Following a Scan

[list-policy-violations.sh](list-policy-violations.sh)  

This script parses the `policyRejectionSummary.json` file, following a WhiteSource Unified Agent scan, and prints to the standard output (`stdout`) the policies that where violated, as well as the libraries that violated them.  

The `policyRejectionSummary.json` file is created automatically under the agent log directory (`./whitesource`) during a scan that's configured to check policies.  
Every policy check overwrites this file, so this list is always specific to the last scan (that had policy check enabled).  

<br>

**Prerequisites:**  

* Check that the project state is [finished](check-project-state.sh)
* `jq` must be installed
* ENV variables must be set
  * `WS_CHECKPOLICIES: true`

<br>

**Execution:**  

```
./list-policy-violations.sh [-p|--includePath]
```
**Sample Outputs:**  
```
$ ./list-policy-violations.sh

WhiteSource Policy Violations
=============================
Product: vulnerable-node
Project: master
Total Rejected Libraries: 9

Policy Name: Reject Vuln CVSS 9+
Policy Type: VULNERABILITY_SCORE
Rejected Libraries:
  morgan-1.6.1.tgz
  pg-5.1.0.tgz
  ejs-2.7.4.tgz
  lodash-4.17.11.tgz
  ejs-0.8.8.tgz

Policy Name: Review BSD2
Policy Type: LICENSE
Rejected Libraries:
  semver-4.3.2.tgz
  source-map-0.1.43.tgz
  qs-4.0.0.tgz
  uglify-js-2.3.0.tgz

```

```
$ ./list-policy-violations.sh --includePath

WhiteSource Policy Violations
=============================
Product: easybuggy
Project: master
Total Rejected Libraries: 6

Policy Name: Reject Vuln CVSS 9+
Policy Type: VULNERABILITY_SCORE
Rejected Libraries:
  log4j-1.2.13.jar  (/build/gl/easybuggy/target/easybuggy-1-SNAPSHOT/WEB-INF/lib/log4j-1.2.13.jar)
  commons-fileupload-1.3.1.jar  (/build/gl/easybuggy/target/easybuggy-1-SNAPSHOT/WEB-INF/lib/commons-fileupload-1.3.1.jar)
  derby-10.8.3.0.jar  (/home/gl/.m2/repository/org/apache/derby/derby/10.8.3.0/derby-10.8.3.0.jar)

Policy Name: Review LGPL
Policy Type: LICENSE
Rejected Libraries:
  xom-1.2.5.jar  (/build/gl/easybuggy/target/easybuggy-1-SNAPSHOT/WEB-INF/lib/xom-1.2.5.jar)
  bsh-core-2.0b4.jar  (/build/gl/easybuggy/target/easybuggy-1-SNAPSHOT/WEB-INF/lib/bsh-core-2.0b4.jar)
  javassist-3.12.1.GA.jar  (/build/gl/easybuggy/target/easybuggy-1-SNAPSHOT/WEB-INF/lib/javassist-3.12.1.GA.jar)

```

<br>
<hr>

## Reports Within a Pipeline for UA

Any report can also be published as a part of the pipeline.  
Add the following snippet after calling the Unified Agent in any pipeline file to save reports from the scanned project to the `./whitesource` logs folder.  
Then use your pipeline's [publish feature](../../CI-CD/README.md#publishing-mends-logs-from-a-pipeline) to save the `whitesource` log folder as an artifact.  

<br>

**Prerequisites:**  
* Check that the project state is [finished](check-project-state.sh)
* `jq` and `awk` must be installed
* ENV variables must be set
  * WS_GENERATEPROJECTDETAILSJSON: true
  * WS_USERKEY
  * WS_WSS_URL

<br>

**Execution:**  

```
export WS_PROJECTTOKEN=$(jq -r '.projects | .[] | .projectToken' ./whitesource/scanProjectDetails.json)
export WS_URL=$(echo $WS_WSS_URL | awk -F "agent" '{print $1}')

## Risk Report
curl -o ./whitesource/riskreport.pdf -X POST "${WS_URL}/api/v1.4" -H "Content-Type: application/json" \
-d '{"requestType":"getProjectRiskReport","userKey":"'${WS_USERKEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'

## Inventory Report
curl -o ./whitesource/inventoryreport.xlsx -X POST "${WS_URL}/api/v1.4" -H "Content-Type: application/json" \
-d '{"requestType":"getProjectInventoryReport","userKey":"'${WS_USERKEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'

## DueDiligence Report
curl -o ./whitesource/duediligencereport.xlsx -X POST "${WS_URL}/api/v1.4" -H "Content-Type: application/json" \
-d '{"requestType":"getProjectDueDiligenceReport","userKey":"'${WS_USERKEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'
```

<br>
<hr>

## Feature Branch Scan

The Unified Agent always uploads a project/scan to the user interface unlike the Mend CLI which has the ability to scan and provide rich output without creating a new project.  To replicate this feature the following should be performed with the UA.  This is most commonly used when scanning feature branches or pull requests as these scans should not be retained in the user interface for long periods of time.

**Prerequisites:**  
* Check that the project state is [finished](check-project-state.sh)
* `jq` and `awk` must be installed
* ENV variables must be set
  * MEND_EMAIL
    * Should be the email for the userKey used below
  * WS_GENERATEPROJECTDETAILSJSON=true
  * WS_USERKEY
  * WS_WSS_URL
  * WS_GENERATESCANREPORT=true
    * alternatively, a risk report could be generated as shown in [Reports Within a Pipeline for UA](#reports-within-a-pipeline-for-ua)


<br>

**Execution:**  

```
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Mend%20SCA/delete-ua-proj.sh
chmod +x ./delete-ua-proj.sh && ./delete-ua-proj.sh

```
