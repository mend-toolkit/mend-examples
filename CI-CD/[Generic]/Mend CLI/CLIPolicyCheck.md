# SCA and SAST Policy Check
Policy Check can be added as part of the dependencies(dep) and code scans.
> **_NOTE:_** 
We recommend to avoid breaking builds unless you have carefully defined your policies and change management processes, as this can cause significant disruptions to existing workflows and create opposition to these changes.

When the scan fails on a Policy Check, for both dep and code, the exit code for the CLI execution changes from `0`  to `9`

## [Dependencies Policy Check](https://docs.mend.io/bundle/integrations/page/use_the_mend_cli_sca_policy_check_for_build_control.html)
After defining the policies in Mend SCA UI, use the following command to trigger a policy check:
```shell
mend dep --fail-policy # without upload scan to Mend User Interface
or
mend dep -u --fail-policy # with upload scan to Mend User Interface
```
The output for the run will be:
```shell
Detected 1 Policy violation
+----------------------------------+---------------------+-------------------------------------------------------+
|             LIBRARY              |     POLICY TYPE     |                    POLICY NAME                        |
+----------------------------------+---------------------+-------------------------------------------------------+
| javax.mail-1.5.1.jar             | License             |              [License] [ORG] Block GPL                |
+----------------------------------+---------------------+-------------------------------------------------------+
```
## Code Policy Check
The code Policy Check is defined based on the results of the scan using thresholds.
The thresholds definition can be found [here](https://docs.mend.io/bundle/integrations/page/configure_the_mend_cli_for_sast.html#Mend-CLI-SAST---Threshold-parameters)

Example for setting threshold to return failure exit code if one ore more high findings is found with the ```mend code``` command
```shell
export MEND_SAST_THRESHOLD_HIGH=1
```
Once a threshold is matched, the following will be added to the scan stdout:
```shell
Warning: Scan contains 10 high severity findings, but threshold is set to 1. Scan exited with return code 9
```

## Handle the Exit Code
It is the user's responsibility to capture and handle the exit code that is returned from the Mend Unified CLI.  Below is a quick generic example followed by a more advanced example for Azure DevOps.

### Generic Example
```shell
echo "Downloading Mend CLI"
curl https://downloads.mend.io/cli/linux_amd64/mend -o /usr/local/bin/mend && chmod +x /usr/local/bin/mend
echo "Run Mend dependencies scan"
mend dep -u
export dep_exit=$?
if [[ "$dep_exit" == "9" ]]; then
    echo "Dependency scan policy violation"
    ### Add error handling logic here
else
    echo "No policy violations found in dependencies scan"
fi
echo "Start Mend code scan"
mend code
export code_exit=$?
if [[ "$code_exit" == "9" ]]; then
    echo "Code scan threshold violation"
    ### Add error handling logic here
else
    echo "No policy violations found in code scan"
fi
```

### [Azure DevOps Example](../../AzureDevOps/Mend%20CLI/AzureDevOps-advanced-linux.yml)
Notice in the AzDO example that the pipeline has a command to surface warnings instead of errors.  This is recommended to alert developers of security vulnerabilities vs breaking the pipeline with ```exit=1``` or a similar fashion