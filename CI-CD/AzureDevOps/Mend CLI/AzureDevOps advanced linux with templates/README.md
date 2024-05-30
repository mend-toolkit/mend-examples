# Azure DevOps pipeline sample using templates

This pipeline is designed for demonstration purposes. You may modify it to fit your specific scanning and pipeline requirements. 

This example takes advantage of Azure DevOps pipeline templates, making it easier to use, read, and reuse across different pipelines.
The templates (`mend-*-template.yml`) need to be placed in a location accessible to all pipelines requiring their use. In this sample, a repository in a global Azure DevOps project is used (`mend-resources/mend-pipeline-templates`). You may change it to a [different preferred method](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops&pivots=templates-includes#reference-template-paths).

The template (`mend-scan-template.yml`) uses the [Mend CLI](https://docs.mend.io/bundle/integrations/page/scan_with_the_mend_cli.html) to run:
* **Software Composition Analysis (SCA)** scan using package managers (and file system scanning [optional]) to detect open-source components
* **Static Application Security Testing (SAST)** scan to detect languages and frameworks used in your projects and report code weaknesses
* **Mend container image** scan to detect secrets and vulnerabilities in image layers (Operating System and application open-source packages) 

Optionally, it uses (`mend-reports-template.yml`) to generate post-scan SCA reports:
* SBOM report
* Risk report
* Inventory report
* Due diligence report

Running the Mend scans and generating post-scan SCA reports is done in a **single step** via the `mend-scan-template.yml` template (make sure it is run AFTER the package manager(s) build step(s)):
```yaml
- template: mend-scan-template.yml@templates
    parameters:
      appName: #Name of of the Mend application where results wil be uplodaed to
      projectName: #Name of of the Mend project where results wil be uplodaed to
      scanTypeList: #OPTIONAL - Comma-separated list containing any of: SCA,SAST,IMAGE,ALL (Default: "SCA,SAST")
      postScanSCAReports: #OPTIONAL - Comma-separated list containing any of: SBOM,RISK,INVENTORY,DUE_DILIGENCE,ALL (Default: "")
      imagesToScan: #OPTIONAL - File name containing a list of images to scan (Default: "")
```
