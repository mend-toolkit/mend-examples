# SCA and SAST Policy Check
Policy Check can be added as part of the SCA and SAST.
> **_NOTE:_** 
We recommend to avoid breaking builds unless you have carefully defined your policies and change management processes, as this can cause significant disruptions to existing workflows and create opposition to these changes.

When the scan fails on a Policy Check, for both SCA and SAST, the exit code for the CLI execution changed from `0`  to `9`

## SCA Policy Check
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
## SAST Policy Check
SAST Policy Check is defined based on the results of the scan using thresholds.
The thresholds definition can be found [here](https://docs.mend.io/bundle/integrations/page/configure_the_mend_cli_for_sast.html#Mend-CLI-SAST---Threshold-parameters)

Example for setting threshold to return failure exit code if one ore more high findings is found with the ```mend code``` command
```shell
export MEND_SAST_THRESHOLD_HIGH=1
```
Once a threshold is matched, the following will be added to the scan stdout:
```shell
Warning: Scan contains 10 high severity findings, but threshold is set to 1. Scan exited with return code 9
```