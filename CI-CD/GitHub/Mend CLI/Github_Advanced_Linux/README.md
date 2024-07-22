# GH Actions CLI Templates

This pipeline is designed for demonstration purposes. You may modify it to fit your specific scanning and pipeline requirements. 

This example takes advantage of [GH Templates](https://docs.github.com/en/actions/using-workflows/creating-starter-workflows-for-your-organization), making it easier to use, read, and reuse across different pipelines.

The template (`mend-scan.yaml`) uses the [Mend CLI](https://docs.mend.io/bundle/integrations/page/scan_with_the_mend_cli.html) to run:
* **Software Composition Analysis (SCA)** scan using package managers (and file system scanning [optional]) to detect open-source components with report creating of:
    * SBOM Export
    * Risk report
    * Inventory report
    * Due diligence report

* **Static Application Security Testing (SAST)** scan to detect languages and frameworks used in your projects and report code weaknesses and creates `sarif` report

### Create a Template Repo

If you don't already have a template repo, create one and give it access from from the Repo where you are running the the pipeline, for example:
`mend-examples/mend-toolkit/.github/workflows/mend-scan-template.yaml@scan-templates`

Copy the `mend-scan-template.yaml` to `.github/workflows` folder

### Use the template

In your GH Actions, place the `mend-scan.yaml` add define the parameters:
```yaml
call-template:
    uses: mend-examples/mend-toolkit/.github/workflows/mend-scan-template.yaml@scan-templates
    with:
      MEND_URL: "https://saas-eu.mend.io"
      # MEND_URL: "https://saas.mend.io"
      SCA: true
      SCA_Reachability: true # Whether to run SCA Reachability, supported for Java and JS: https://docs.mend.io/bundle/sca_user_guide/page/sca_reachability_in_the_mend_cli.html
      SAST: true
      CN: false # TODO add steps to template
      SCA_Reports: 'ALL'
      ### Allowed values:
      ### Comma-separated list containing any of: SBOM,RISK,INVENTORY,DUE_DILIGENCE,ALL
    secrets:
      MEND_EMAIL: ${{ secrets.MEND_EMAIL }}
      MEND_USER_KEY: ${{ secrets.MEND_USER_KEY }}
```

