[![Logo](https://mend-toolkit-resources-public.s3.amazonaws.com/img/mend-io-logo-horizontal.svg)](https://www.mend.io)  

# Mend 3rd Party Result Consumption Example
This script demonstrates how to convert third-party SAST findings into a format compatible with [Mend CLI](https://docs.mend.io/platform/latest/download-the-mend-cli). It shows how to transform JSON output from [Brakeman](https://github.com/presidentbeef/brakeman) into Mend's standardized format that can be consumed by the Mend CLI.

# Requirements

- Mend requires access to the code base in order to import 3rd party results. Access to the code base will allow Mend to keep track of suppressed vulnerabilities as well as generate snippets like a regular Mend scan.

- In order to import results, the file to be imported must a pre-defined schema found in the [Mend documentation](https://docs.mend.io/platform/latest/integrate-third-party-code-scan-results-into-mend-#Integratethird-partyCodeScanResultsintoMendSAST-JSONSchema). 
Below is the minumum viable input file. Each field in the JSON below is required.
> [!NOTE]  
> Each CWE must have a unique name. If a duplicate name is provided, the all types of the same name will be reported under the last read CWE with that name.

```json
{
  "tool": {
    "name": "Brakeman",
    "version": "x.x.x"
  },
  "run": {
    "language": "Ruby",
    "findings": [
      {
        "type": {
          "name": "SQL Injection Check - SQL Injection",
          "severity": "unknown",
          "cwe": 89
        },
        "description": "Potential SQL injection vulnerability",
        "sink": {
          "name": "User.find_by_name",
          "file": "app/models/user.rb",
          "line": 42
        }
      }
    ]
  }
}
```
# Running the Example

This script was tested by running brakeman to generate results against [Railsgoat](https://github.com/OWASP/railsgoat).

## Prerequisites

- `jq` JSON processor
- `xargs` command line tool
    - Installed by default on most Unix-like systems
- A Brakeman output file in JSON format
    - One is provided in the repo.
- A Mend user account to [authenticate to the Mend CLI](https://docs.mend.io/platform/latest/authenticate-your-login-for-the-mend-cli)

### Installation

```bash
# Install jq
apt install -y jq
mend auth login
```

## Usage

```bash
./mend_convert_brakeman.sh <input_file> <output_file>
```

Example:
```bash
./mend_convert_brakeman.sh results.json converted_results.json
mend image import --input-file converted_results --scope "<my_application>//<my_project>"
```


## Note

The script uses `xargs` for parallel processing of 3rd party findings, with the number of parallel processes calculated as 75% of available CPU cores. 
