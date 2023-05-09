**Warning** the files in [configs](./) may change in the future.  It is only recommended to point directly to them for a limited time while testing the solution.  For production usage, it is recommended to maintain these files in your own repository.

In all .whitesource file update examples, you should replace the inherited organization from "myorganization" to the organization/project where the whitesource-config repository is located.

# SCA
## Renovate
In order to disable Remediate and turn on Renovate, update a repository's .whitesource file with the following information
```
{
  "settingsInheritedFrom": "myorganization/whitesource-config@main",
  "remediateSettings": {
    "workflowRules": {
      "enabled": false
    },
    "enableRenovate": true,
    "dependencyDashboard": true,
    "extends": [
       "config:base"
       "github>whitesource/merge-confidence:beta",
       "github>mend-toolkit/mend-examples//Repo-Integration/Renovate/smart-merge",
      ]
  }
}
```

# SAST
## Java 2x Engine
In order to use the Java 2x engine, update a repository's .whitesource file with the following information

```
{
  "settingsInheritedFrom": "myorganization/whitesource-config@main",
  "scanSettingsSAST": {
    "configExternalURL": "https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Repo-Integration/configs/SAST/Java2x/mendsastcli-config.json"
  }
}
```