**Warning** the files in this folder may change in the future.  It is only recommended to point directly to them for a limited time while testing the solution.  For production usage, it is recommended to maintain these files in your own repository.

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
       "config:recommended",
       "mergeConfidence:all-badges",
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