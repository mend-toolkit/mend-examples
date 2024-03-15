## Configuring Private Registries without Host Rules For Self-Managed Repository Integrations

There are often security policies among many organizations that restrict reaching out to public registries such as Maven Central. This is the default repository for downloading dependencies with Maven. In instances such as this, Mend provides the ability to specify private registry credentials inside of the repository for each Mend-Hosted repository integration([Github.com](https://docs.mend.io/bundle/integrations/page/configure_mend_for_github_com_to_resolve_your_private_dependencies.html), [Azure Repos](https://docs.mend.io/bundle/integrations/page/installation_of_mend_for_azure_repos.html#Handling-Private-Registries-and-Authenticated-Repositories), [Bitbucket Cloud](https://docs.mend.io/bundle/integrations/page/installation_of_mend_for_bitbucket_cloud.html#Handling-Private-Registries-and-Authenticated-Repositories)).

For Self-Managed Repository Integrations, there is another way of specifying host rules without any need to specify Host Rules inside of the repo, or even at the global level. This can be configured at the container level for ease of configuration, privacy, and to prevent tampering. This type of setup only works if the following criteria apply to the organization using the Repository Integration:
- The organization uses one private registry source per package manager type for all teams.
- Each team does not have the option to use another private registry.

### Steps:
1. Create sensible environment variables. In the example [docker-compose.yml](./Maven/docker-compose.yml) file, we use MVN_USER, MVN_PASS, MVN_RELEASES, and MVN_SNAPSHOTS to specify credentials and URL's respectively.
2. Create a package manager settings file such as a [settings.xml](./Maven/settings.xml) where these environment variables can get injected. In the example above, we can access these environment variables with `${env.<VARIABLE_NAME>}`.
3. For Remediate/Renovate specifically, you can create a [config.js](./Maven/config.js) to direct Remediate/Renovate to your desired registry. In this file, we can use `module.exports` to specify the remediate configuration just as if it were in a global configuration. The great thing about this configuration is that the password does not need to be encrypted. You can keep it as plaintext as it remains on the container and never leaves.
4. Map the appropriate files and variables to the scanner and remediate container. This is demonstrated in the [docker-compose.yml](./Maven/docker-compose.yml).
5. In both the scanner and the remediate container, specify extra_hosts with the default public registry pointing to 127.0.0.1. This will effectively block the public registry from being used by the container.


### Explanations:
1. [Maven](./README.md#Maven)
2. [NPM](./README.md#NPM)
3. [Pip](./README.md#Pip)
4. [GO](./README.md#Go)
5. [Gradle](./README.md#Gradle)
6. [NuGet](./README.md#NuGet)
7. [Docker](./README.md#Docker)

#### Maven
With Maven, adding environment variables to the settings.xml is as easy as ``${env.<environment_variable_name>}``. If you take any generic settings.xml and set the servers and credentials to environment variables, then this can be handled when starting up the container by adding the environment variables either to the docker command with ``-e`` or by using the ``environment:`` option when specifying the container in a ``docker-compose.yml`` file, or another secret manager.  

For the scanner, all you need to do is map the ``settings.xml`` into the ``$HOME/.m2`` directory.  

For the remediate container, you need to map the config.js file into the `/usr/src/app` directory and set the environment variables accordingly. For the config.js, you can access environment variables by using the directive ``process.env.<variable_name>``  

> [!NOTE]  
Any attempt in the POM file to specifically reach out to Maven Central will supercede the settings.xml that you map into the container. Therefore, no registry handling should be specified by the project itself, and rather should leave the container to deal with it.

#### NPM
NPM makes use of scoped environment variables to provide the credentials to the package managers. The setup between the remediate container and the scanner are different.  
For the scanner you need a ``.npmrc`` file that looks like:
```
email = ${NPM_EMAIL}
always-auth = true
registry = ${NPM_REGISTRY}
```

And then you need the following environment variables:
```
NPM_REGISTRY: "https://<artifactory_instance>.jfrog.io/artifactory/api/npm/<npm_registry>"
NPM_EMAIL: "<email_username_for_authentication>"
NPM_CONFIG_//<artifactory_instance>.jfrog.io/artifactory/api/npm/<npm_registry>:_auth: "<NPM_AUTH_TOKEN>"
```

The NPM Auth Token is a hexadecimal string provided by artifactory for this purpose.

> [!WARNING]  
The Auth Token environment variable must be specified in a source that allows special characters in the variable name. For the purpose of these examples, a ``docker-compose.yaml`` file can store this information, but due to how ``.env`` files are processed, this cannot be specified in an equivalent ``.env`` file.

For the Remediate Container, you will need the following environment variables:
```
NPM_REGISTRY: "https://<artifactory_instance>.jfrog.io/artifactory/api/npm/<npm_registry>"
NPM_EMAIL: "<email_username_for_authentication>"
NPM_PASS: "<your_cleartext_password>"
```
This password is provided by Artifactory as well, but is not the NPM Auth Token.

#### Pip
Pip has a simple method of connecting to private registries. For the scanner, all you need is an environment variable that looks like:
```
PIP_INDEX_URL: https://<user_email>:<user_password>@<artifactory_instance>.jfrog.io/artifactory/api/pypi/default-pypi/simple
```

> [!NOTE]  
As you can probably tell, you do not need a pip.conf file for configuration as you do with the other package managers. Pip will automatically pick up the environment variable and use that, even as priority over any workspace files. There is documentation [here](https://pip.pypa.io/en/stable/topics/configuration/#precedence-override-order) showing how this works.

For the remediate container, you need to match the registry to these 5 managers: ``pip-compile``, ``pip-requirements``, ``pip_setup``, ``pipenv``, ``setup-cfg``

#### Go
Go has a very simple method for connecting to private registries as well. For both the scanner and the remediate container, all you need is an environment variable that looks much like Pip's:
```
GOPROXY: https://<user_email>:<user_password>@<artifactory_instance>.jfrog.io/artifactory/api/go/default-go
```
> [!WARNING]  
The "go" datasource in Renovate does not support private registries. Therefore, GOPROXY must be used, and hostRules do not work. More information on this topic is here: https://docs.renovatebot.com/modules/datasource/go/

#### Gradle
For Gradle, we created two different methods of resolving Private Registries. With Groovy, and Kotlin.  

**Groovy**  
With groovy, we created an init.gradle file that gets executed before resolving any projects. Here is the flow of the script:
1. If it exists, get the `gradle.properties` file in the project root directory.
2. If it exists, get the `gradle.properties` file in the `~/.gradle` directory.
3. Load the properties from these two files, the root project gradle.properties file takes precedence.
4. Get the "repositoryUrl", "repositoryUsername", "repositoryPassword" properties from the file and store it in variables.
5. Get the 'pluginRepositoryUrl", "pluginRepositoryUsername", "pluginRepositoryPassword" properties from the file and store those in variables.
6. Set all of these in a SettingsEvaluated section in the init.gradle

Using this, you can map in a gradle.properties file into the `/home/wss-scanner/.gradle` directory, or use one directly in the project, and specify the repository credentials. These will get loaded before resolving the project dependencies.

**Kotlin**  
With kotlin, we have the same resolution as groovy, but we have a init.gradle.kts file that loads the repositories before resolving projects. Here is the flow of the script:
1. If it exists, get the `gradle.properties` file in the project root directory.
2. If it exists, get the `gradle.properties` file in the `~/.gradle` directory.
3. Load the properties from these two files, the root project gradle.properties file takes precedence.
4. Get the "repositoryUrl", "repositoryUsername", "repositoryPassword" properties from the file and store it in variables.
5. Get the 'pluginRepositoryUrl", "pluginRepositoryUsername", "pluginRepositoryPassword" properties from the file and store those in variables.
6. Set all of these in a SettingsEvaluated section in the init.gradle

Again, with this you can map in a gradle.properties file into the `/home/wss-scanner/.gradle` directory, or use one directly in the project, and specify the repository credentials.

The properties in the gradle.properties file must have the following names for these scripts to work:
```properties
repositoryUrl=<registry_url>
repositoryUsername=<registry_user>
repositoryPassword=<registry_password>

pluginRepositoryUrl=<plugin_repository_url>
pluginRepositoryUsername=<plugin_repository_user>
pluginRepositoryPassword=<plugin_repository_password>
```
For the remediate container, you need to match the ``gradle`` and ``gradle-wrapper`` managers for both the repositoryUrl, and the pluginRepositoryUrl.

#### NuGet
For NuGet, we create a ``NuGet.Config`` file which will house references to environment variables for the artifactory registry. There are multiple different URLs that Artifactory suggests. The one we want to use is: ``https://<artifactory_instance>.jfrog.io/artifactory/api/nuget/<nuget-registry-name>`` and then the password will be the password provided by Artifactory with the specification ``ClearTextPassword`` in the NuGet.Config file.

> [!WARNING]
The file must be mapped into the container as: ``NuGet.Config`` with the appropriate capitalization because when installing the dotnet CLI on the container, this file is already created and we want to override it.

#### Docker
For Docker, the integration itself does not perform Image scans, and so the only credentials that are required are for Remediate/Renovate. Therefore, this can be done simply with the config.js and mapping in some environment variables:
```javascript
module.exports = [{
  "hostRules": [{
      "hostType": "docker",
      "matchHost": process.env.DOCKER_REGISTRY,
      "userName": process.env.DOCKER_USER,
      "password": process.env.DOCKER_PASS
  }]
}]
```

From there you just simply need to map in the required environment variables.

> [!NOTE]  
Many packages do not follow the "SemVer" versioning scheme, as they follow their own versioning scheme. You can get more information on how to change versioning for a specific package [here](https://docs.renovatebot.com/docker/#version-compatibility). Click [here](https://docs.renovatebot.com/modules/versioning/) for more information on supported versioning schemes and custom versioning.
