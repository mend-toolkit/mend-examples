![Logo](https://mend-toolkit-resources-public.s3.amazonaws.com/img/mend-io-logo-horizontal.svg)  

# Mend SCA Scripts
This folder contains scripts for use with the Mend SCA platform and Unified agent scanning within a CI/CD pipeline.

- [Reports Within a Pipeline](#reports-within-a-pipeline)
- [SBOM Report Generation](#sbom-report-generation)
- [Display Policy Violations Following a Scan](#display-policy-violations-following-a-scan)
- [Cache the Latest Version of the Unified Agent](#cache-the-latest-version-of-the-unified-agent)
- [Get all Users that are part of Organizations which are a part of a Global Organization](#get-all-users-that-are-part-of-organizations-which-are-a-part-of-a-global-organization)
- [Get all libraries where the used version is older than X days](#get-all-libraries-where-the-used-version-is-older-than-x-days)
- [Get all malicious packages in an organization](#get-all-malicious-packages-in-an-organization)

<hr/>

**All scripts & snippets that are utilized in a pipeline should call [check-project-state.sh](check-project-state.sh) before running to ensure that the scan has completed.**
<hr/>


## Reports Within a Pipeline

Any report can also be published as a part of the pipeline.  
Add the following snippet after calling the Unified Agent in any pipeline file to save reports from the scanned project to the `./whitesource` logs folder.  
Then use your pipeline's [publish feature](../../CI-CD/README.md#publishing-mends-logs-from-a-pipeline) to save the `whitesource` log folder as an artifact.  

<br>

**Prerequisites:**  

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

## [SBOM Report Generation](https://github.com/mend-toolkit/Mend-SBOM-Export-CLI)

An example using the sbom-export-cli with Mend Unified CLI can be found in the [AzureDevOps Advanced example](../../CI-CD/AzureDevOps/Mend%20CLI/AzureDevOps-advanced-linux.yml)

<br>
<hr>

## Display Policy Violations Following a Scan

[list-policy-violations.sh](list-policy-violations.sh)  

This script parses the `policyRejectionSummary.json` file, following a WhiteSource Unified Agent scan, and prints to the standard output (`stdout`) the policies that where violated, as well as the libraries that violated them.  

The `policyRejectionSummary.json` file is created automatically under the agent log directory (`./whitesource`) during a scan that's configured to check policies.  
Every policy check overwrites this file, so this list is always specific to the last scan (that had policy check enabled).  

<br>

**Prerequisites:**  

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
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/cache-ua.sh
chmod +x ./cache-ua.sh && ./cache-ua.sh
```

See additional example for implementation within a build pipeline under [CI-CD](../CI-CD/README.md#caching-the-unified-agent) (`*-cached-ua.yml`).  


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
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/pending-task-cleanup.sh 
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
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/get-library-ages.py
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
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/get-malicious-packages.sh
chmod +x ./get-malicious-packages.sh && ./get-malicious-packages.sh
```

<br>
<hr>