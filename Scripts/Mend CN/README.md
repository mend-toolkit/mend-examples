![Logo](https://mend-toolkit-resources-public.s3.amazonaws.com/img/mend-io-logo-horizontal.svg)  

# Mend CN Scripts
This folder contains scripts for use alongside Mend Container Scanning within a CI/CD pipeline using the Mend CLI.

- [Get Image Vulnerabilities](#get-image-vulnerabilities)
- [Create Traceability Tags](#create-traceability-tags)

## Get Image Vulnerabilities

[get-image-vulnerabilities.sh](get-image-vulnerabilities.sh)  

This script pulls all of the image scans inside of a Mend Organization and then retrieves all vulnerabilities for each. The results is a ``.csv`` file that has the following columns:  
- Image Name
- Image Tag
- Vulnerability ID
- Description
- EPSS
- Published Date
- Last Modified Date
- Package Name
- Source Package Name
- Package Version
- Package Type
- Found In Layer
- Is From Base Layer (boolean)
- Layer Number
- CVSS Score
- CVSS Severity
- Fix Version
- Has Fix (boolean)
- Reference Urls
- Type
- Vendor Severity
- Risk
- Score

Feel free to edit the script to remove the columns unnecessary for your needs.
<br>

**Prerequisites:**  

* `jq` and `curl` must be installed
* Environment Variables:
  - MEND_USER_KEY
  - MEND_EMAIL
  - WS_APIKEY
  - MEND_URL

<br>

**Execution:**  

```
export MEND_URL=https://saas.mend.io
export WS_APIKEY=x
export MEND_USER_KEY=x
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Mend CN/get-image-vulnerabilities.sh
chmod +x ./get-image-vulnerabilities.sh && ./get-image-vulnerabilities.sh
```


## Create Traceability Tags

[create-traceability-tags.sh](create-traceability-tags.sh)  

This script adds ``LABEL`` directives to each Dockerfile in a repository that is found. Requirements:
1. The project must be a repository.
2. Only files named "Dockerfile" will get edited.

This script gets the ``origin`` remote from the Git Repository, as well as the relative path to each Dockerfile, and adds that as labels in each in the following format:
```Dockerfile
LABEL org.opencontainers.image.source=<repo_url>
LABEL io.mend.image.dockerfile.path=<dockerfile_path>
```

> [!NOTE]
> The results of this should be committed as this script is run on the fly, and does not make any lasting changes on the repository.

<br>

**Prerequisites:**  

- apt-get install sed git

<br>

**Execution:**  

```sh
cd $PROJECT_DIR
curl -LJO https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Scripts/Mend%20CN/create-traceability-tags.sh
chmod +x ./create-traceability-tags.sh && ./create-traceability-tags.sh
```

<br>
<hr>
