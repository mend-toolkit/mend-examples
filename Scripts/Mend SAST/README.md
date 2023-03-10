# Mend SAST Scripts
This folder contains scripts for use with the Mend SAST platform.

## SAST Scan CleanUp Utility

Python script delete any scans older than the specified date and generate reports before deletion.
* The reports are saved in the designated location as follows: _[WORKING_DIRECTORY]/Mend/Reports/[REPORT NAME]
	* This can be overridden by specifying _-o /--outputDir_
* To review the outcome before actual deletion use _-y true_ / _--dryRun=True_ flag. It will _NOT_ delete any project nor create reports 
* By default, the tool generates csv reports. By specifying _-t_ / _--reportFormat=_ it is possible to specify different formats. See flags below for all support formats
* The full parameters list is available below

<br>

**Prerequisites**

Python 3.8+

**Execution**

```
python3 cleanup_tool_sast.py -k <yourSASTapiToken> -a <yourMendUrl> -r <numberofdaystokeep>
```

** Full Usage flags: **
```shell
usage: python3 cleanup_tool_sast.py -k API_TOKEN -a MEND_URL [-t REPORT_FORMAT] [-o OUTPUT_DIR] [-r DAYS_TO_KEEP] [-y DRY_RUN] [-s SKIP_REPORT_GENERATION] [-j SKIP_PROJECT_DELETION]

cleanup_tool_sast.py -k apiToken

required arguments:
	-k MEND_API_TOKEN, --apiToken
                    Mend SAST Api Token
	-a MEND_URL, --mendUrl
                    Mend URL				
					
optional arguments:
  -t REPORT_FORMAT, --reportFormat
                    Report format to generate. Supported formats (csv, pdf, html, xml, json, sarif)
					default csv
  -o OUTPUT_DIR, --outputDir
                    Output directory
					default [Working_Directory]/Mend/Reports
  -r DAYS_TO_KEEP, --DaysToKeep
                    Number of days to keep (overridden by --dateToKeep)
  -d DATE_TO_KEEP, --dateToKeep
                    Date of latest scan to keep in YYYY-MM-DD format
  -y DRY_RUN, --DryRun
                    Logging the projects that are supposed to be deleted without deleting and creating reports
                    default False
  -s SKIP_REPORT_GENERATION, --SkipReportGeneration
                    Skip report generation step
                    default True
  -j SKIP_PROJECT_DELETION, --SkipProjectDeletion
                    Skip project deletion step
                    default False                                                
```

**note:** The optimal cleanup scope is derived from the size of the environment, Mend scope size (memory and CPU) allocated for the server, and runtime time constraints.   