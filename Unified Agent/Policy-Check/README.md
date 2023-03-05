# Mend Unified Agent(UA) Policy Check Examples

## [Video Explanation](https://youtu.be/LlK2ZADW0gk)

## Prerequisites 
- Use environment variables or a blank config file with only the necessary changes in order to utiliize Mend Unified Agent defaults as shown on the [Getting Starting with Unified Agent documentation](https://docs.mend.io/bundle/unified_agent/page/getting_started_with_the_unified_agent.html#Setting-Up-the-Unified-Agent)

- The most important policy should always be first in the priority list since policies are triggered per library

## Recommendations
When using the default [UA parameters](https://docs.mend.io/bundle/unified_agent/page/unified_agent_configuration_parameters.html#Policies) the below paramaters should be added to a blank config file or as environment variables to achieve the desired affects

### Main or Default Branch
Even though updateInventory=true by default the UA exits with a fail so the blocked results will **NOT** be in the user interface.   Violations will need to be viewed in the policyRejectionSummary.json & checkPolicies-json.txt within the whitesource folder

- To block/reject only on newly added dependencies add the following parameter: ```WS_CHECKPOLICIES=TRUE```

- To block/reject all dependencies add the following parameters:
```
WS_CHECKPOLICIES=TRUE
WS_FORCECHECKALLDEPENDENCIES=true
```

### Feature, Hotfix, or Development branch
- Use the same product and project name as the default branch, the below script is useful when an environment variable is not available in your CI/CD system such as github action's ```${{github.event.repository.default_branch}}```
```
export WS_PROJECTNAME=$(git remote show $(git remote) | grep 'HEAD branch' | cut -d' ' -f5)
```

- Block only newly added dependencies and do not update default branch project
```
WS_CHECKPOLICIES=TRUE
WS_UPDATEINVENTORY=FALSE
```


### Additional Configurations
Useful for Proof of Concepts, but not recommended in production

- View new & existing library scan results in the UI for a broken build
```
WS_CHECKPOLICIES=true
WS_FORCECHECKALLDEPENDENCIES=true
WS_FORCEUPDATE=true
WS_FORCEUPDATE_FAILBUILDONPOLICYVIOLATION=true
```