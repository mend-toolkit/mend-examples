

# Multi-Organizational Pipeline or (multi-org)
The [jenkins example](./Jenkins_pipeline_maven_multi-org.groovy) in this folder shows an example implementation of the concepts discussing in the [Organization/Product/Project Mapping Best Practices documentation](https://docs.mend.io/bundle/wsk/page/organization_product_project_mapping_best_practices.html#Pipeline-Integration-Example).

## Pipeline Integration Notes
Two options to store the “key” information

* Global Properties
* Local Pipeline script in the “environment” section

** The examples shown use the global properties.  Make sure you create the following keys and populate their values:
* APIKEY (Integration -> Organization APIKEY from your production organization)
* DEV_APIKEY (Integration -> Organization APIKEY from your development organization)
* USERKEY (User Profile -> User Keys section from your production organization)
* DEV_USERKEY (User Profile -> User Keys section from your development organization)
* WSURL (https://&lt;Mend URL&gt;/agent)
