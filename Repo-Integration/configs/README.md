**Warning** the files in [configs](./) may change in the future.  It is only recommended to point directly to them for a limited time while testing the solution.  For production usage, it is recommended to maintain these files in your own repository.

In all .whitesource file update examples, you should replace the inherited organization from "myorganization" to the organization/project where the whitesource-config repository is located.

# SCA
## [Remediate & Renovate](https://docs.mend.io/bundle/integrations/page/mend_remediate_and_renovate.html)

### Renovate + [Smart Merge Control](https://docs.mend.io/bundle/integrations/page/boost_your_pull_request_confidence_using_mend_renovate_s_smart_merge_control.html)
- Do NOT enable Remediate "workflowRules" with this setting as Security fixes may sit in the dependency dashboard due to low and neutral confidence
```
{
  "settingsInheritedFrom": "myorganization/whitesource-config@main",
  "remediateSettings": {
    "workflowRules": {
      "enabled": false
    },
    "enableRenovate": true,
    "extends": [
       "config:base",
       "github>whitesource/merge-confidence:beta",
       "github>mend-toolkit/mend-examples//Repo-Integration/Renovate/smart-merge"
      ]
  }
}
```
## Reachability Analysis
- This feature is currently in closed beta and should not be enabled without Mend Field Engineering assistance.
```
{
  "settingsInheritedFrom": "myorganization/whitesource-config@main",
  "scanSettings": {
      "enableReachability": true
  },
  "checkRunSettings": {
    "strictMode": "warning"
  }
}
```

# SAST
## [Java Engine Generation 2](https://docs.mend.io/bundle/integrations/page/configure_the_mend_cli_for_sast.html#Mend-CLI-SAST---General-scan-parameters)
The below configuration is the same as running ```mend sast -j 2``` with the CLI
```
{
  "settingsInheritedFrom": "myorganization/whitesource-config@main",
  "scanSettingsSAST": {
    "configExternalURL": "https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Repo-Integration/configs/SAST/java-engine-generation/mendsastcli-config.json"
  }
}
```
## Increase Timeout
The below configuration increases the perFile timeout to 300 seconds, but leaves the default of 480 minutes per language.  See [timeout parameters](https://docs.mend.io/bundle/mend_sast/page/cli_parameters.html#Timeouts) for more information.
```
{
  "settingsInheritedFrom": "myorganization/whitesource-config@main",
  "scanSettingsSAST": {
    "configExternalURL": "https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Repo-Integration/configs/SAST/IncreaseTimeout/mendsastcli-config.json"
  }
}
```
