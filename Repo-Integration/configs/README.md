**Warning** the files in [configs](./) may change in the future.  It is only recommended to point directly to them for a limited time while testing the solution.  For production usage, it is recommended to maintain these files in your own repository.

In all .whitesource file update examples, you should replace the inherited organization from "myorganization" to the organization/project where the whitesource-config repository is located.

# SCA
## [Remediate & Renovate](https://docs.mend.io/bundle/integrations/page/mend_remediate_and_renovate.html)

### [Least Vulnerable Package](https://docs.mend.io/bundle/integrations/page/least_vulnerable_packages_feature.html) and Renovate + Smart Merge Control
```
{
  "settingsInheritedFrom": "myorganization/whitesource-config@main",
  "remediateSettings": {
    "workflowRules": {
      "enabled": true,
      "minVulnerabilitySeverity": "LOW"
    },
    "enableRenovate": true,
    "extends": [
       "config:base",
       "github>whitesource/merge-confidence:beta",
       "github>mend-toolkit/mend-examples//Repo-Integration/Renovate/smart-merge-lvp"
      ]
  },
  "leastVulnerablePackageSettings": {
    "enabled": true
    }
}
```

### Renovate + Smart Merge Control
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

# SAST
## [Java Engine Generation 2](https://docs.mend.io/bundle/integrations/page/configure_the_mend_cli_for_sast.html#Mend-CLI-SAST---General-scan-parameters)
```
{
  "settingsInheritedFrom": "myorganization/whitesource-config@main",
  "scanSettingsSAST": {
    "configExternalURL": "https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Repo-Integration/configs/SAST/java-engine-generation/mendsastcli-config.json"
  }
}
```
## Increase Timeout
```
{
  "settingsInheritedFrom": "myorganization/whitesource-config@main",
  "scanSettingsSAST": {
    "configExternalURL": "https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Repo-Integration/configs/SAST/IncreaseTimeout/mendsastcli-config.json"
  }
}
```
