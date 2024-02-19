**Warning** the files in this folder may change in the future.  It is only recommended to point directly to them for a limited time while testing the solution.  For production usage, it is recommended to maintain these files in your own repository.

In all .whitesource file update examples, you should replace the inherited organization from "myorganization" to the organization/project where the whitesource-config repository is located.

# SAST
## [2nd Generation Engines](https://docs.mend.io/bundle/integrations/page/configure_the_mend_cli_for_sast.html#Mend-CLI-SAST---General-scan-parameters)
The below configuration is the same as running ```mend sast -j 2 --js 2 --cs 2``` with the CLI
```json
{
  "settingsInheritedFrom": "myorganization/whitesource-config@main",
  "scanSettingsSAST": {
    "configExternalURL": "https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Repo-Integration/configs/SAST/2nd-gen-engines/mendsastcli-config.json"
  }
}
```
## Increase Timeout
The below configuration increases the perFile timeout to 300 seconds, but leaves the default of 480 minutes per language.  See [timeout parameters](https://docs.mend.io/bundle/mend_sast/page/cli_parameters.html#Timeouts) for more information.
```json
{
  "settingsInheritedFrom": "myorganization/whitesource-config@main",
  "scanSettingsSAST": {
    "configExternalURL": "https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Repo-Integration/configs/SAST/IncreaseTimeout/mendsastcli-config.json"
  }
}
```
