Yaml files should be customized with proper steps for specific builds.  Below are a few examples for common Azure DevOps build types.

# DOTNET
```yml
- script: dotnet build --configuration Release
  displayName: 'dotnet build Release'
```
# Gradle
```yml
- task: Gradle@2
  inputs:
    workingDirectory: ''
    gradleWrapperFile: 'gradlew'
    gradleOptions: '-Xmx3072m'
    publishJUnitResults: false
    testResultsFiles: '**/TEST-*.xml'
    tasks: 'build'
```
# Maven
```yml
- task: Maven@3
  inputs:
    mavenPomFile: 'pom.xml'
    goals: 'clean install'
    mavenOptions: -DskipTests=true
    publishJUnitResults: false
    javaHomeOption: 'JDKVersion'
    jdkVersionOption: '1.11'
    mavenVersionOption: 'Default'
    mavenAuthenticateFeed: false
    effectivePomSkip: false
    sonarQubeRunAnalysis: false
```

# NPM
```yml
- task: NodeTool@0
  inputs:
    versionSpec: '12.x'
  displayName: 'Install Node.js'
- task: Npm@1
  displayName: 'NPM Install'
  inputs:
    customCommand: install --package-lock
```


# Publishing Mend Unified Agent Logs From a Pipeline

Publish the `whitesource` folder with logs & reports by adding one the following commands, depending on your platform


```yaml
- publish: $(System.DefaultWorkingDirectory)/whitesource
  artifact: Whitesource
```

# Publishing Mend CLI Logs From a Pipeline

* Publish the `.mend/logs` folder with logs & reports by adding the following commands depending on each pipeline
  * SAST logs are currently located in ```.mend/storage/sast/logs```

* Windows:
```yaml
- publish: c:\users\VssAdministrator\.mend\logs
  artifact: "Mend CLI Logs"
```
* Linux:
```yaml
- publish: ../../../.mend/logs
  artifact: "Mend CLI logs"
```


