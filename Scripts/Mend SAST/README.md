# Mend SAST Scripts
This folder contains scripts for use with the Mend SAST platform.

## SAST Scan CleanUp Utility

This simple python script will delete any scans that are older than 21 days by default.

<br>

**Prerequisites**

Python 3.8+

**Execution**

```
python3 cleanup_tool_sast.py <yourSASTapiToken> <numberofdaystodelete>
```