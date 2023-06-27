## Configuring Private Registries without Host Rules For Self-Hosted Repository Integrations

There are often security policies among many organizations that restrict reaching out to public registries such as Maven Central. This is the default repository for downloading dependencies with Maven. In instances such as this, Mend provides the ability to specify host rules inside of the repository.

For Self-hosted Repository Integrations, there is another way of specifying host rules without any need to specify Host Rules inside of the repo, or even at the global level. This can be configured at the container level for ease of configuration, privacy, and to prevent tampering.

### Steps:
1. Create sensible environment variables. In the example [docker-compose.yml](./docker-compose.yml) file, we use MVN_USER, MVN_PASS, MVN_RELEASES, and MVN_SNAPSHOTS to specify credentials and URL's respectively.
2. Create a package manager settings file such as a [settings.xml](./settings.xml) where these environment variables can get injected. In the example above, we can access these environment variables with `${env.<VARIABLE_NAME>}`.
3. For Remediate/Renovate specifically, you can create a [config.js](./config.js) to direct Remediate/Renovate to your desired registry. In this file, we can use `module.exports` to specify the remediate configuration just as if it were in a global configuration. The great thing about this configuration is that the password does not need to be encrypted. You can keep it as plaintext as it remains on the container and never leaves.
4. Map the appropriate files and variables to the scanner and remediate container. This is demonstrated in the [docker-compose.yml](./docker-compose.yml).
5. In both the scanner and the remediate container, specify extra_hosts with the default public registry pointing to 127.0.0.1. This will effectively block the public registry from being used by the container.
