# mend-integration-schemas
This document describes how to reference the [Mend Repository Integrations JSON schema](https://githubusercontent.com/mend-toolkit/mend-examples/main/Repo-Integration/Schemas/ghc-integration-schema.json) in your ``.whitesource`` or ``repo-config.json`` files. Referencing the schema enables IDE validation using the VSCode JSON Language Service.

### Prerequisites
- A ``.whitesource`` or ``repo-config.json`` file for your Mend integration configuration.
- An IDE that supports the VSCode JSON Language Service, such as VS Code or Neovim.

Referencing the Schema

Two reference the schema, the configuration file should include a ``$schema`` property at the root of the file.  
For example:  
```json
{
  "$schema": "https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Repo-Integration/Schemas/ghc_integration_schema.json",
  // Your configuration properties here
}
```
In this example, the ``$schema`` property points directly to the Mend Integrations Schema URL. This instructs the IDE to use the referenced schema for validation purposes.

### IDE Setup
Once you've referenced the schema in your configuration file, your IDE should automatically pick it up and provide validation for the contents of your ``.whitesource`` or ``repo-config.json`` file. This can include features like syntax highlighting, error checking, and autocompletion based on the schema definitions.

Additional Notes:
- Ensure your IDE has proper support for referencing external JSON schemas. Refer to your IDE's documentation for configuration options related to JSON schema validation.
- The Mend integrations schema contains specific definitions for the Mend Github.com integration configuration. Make sure to consult the Mend documentation for details on the expected structure and properties within the schema. There are also descriptions on each property explaining its purpose.
