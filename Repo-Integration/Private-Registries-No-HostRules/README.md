## Configuring Private Registries without Host Rules For Self-Hosted Repository Integrations

There are often security policies among many organizations that restrict reaching out to public registries such as Maven Central. This is the default repository for downloading dependencies with Maven. In instances such as this, Mend provides the ability to specify host rules inside of the repository.

For Self-hosted Repository Integrations, there is another way of specifying host rules without any need to specify Host Rules inside of the repo, or even at the global level. This can be configured at the container level for ease of configuration, privacy, and to prevent tampering.

### Steps:
1. Create sensible environment variables. In the example [docker-compose.yml](./docker-compose.yml) file, we use MVN_USER, MVN_PASS, MVN_RELEASES, and MVN_SNAPSHOTS to specify credentials and URL's respectively.
2. Create a package manager settings file such as a [settings.xml](./settings.xml) where these environment variables can get injected. In the example above, we can access these environment variables with `${env.<VARIABLE_NAME>}`.
3. For Remediate/Renovate specifically, you can create a [config.js](./config.js) to direct Remediate/Renovate to your desired registry. In this file, we can use `module.exports` to specify the remediate configuration just as if it were in a global configuration. The great thing about this configuration is that the password does not need to be encrypted. You can keep it as plaintext as it remains on the container and never leaves.
4. Map the appropriate files and variables to the scanner and remediate container. This is demonstrated in the [docker-compose.yml](./docker-compose.yml).
5. In both the scanner and the remediate container, specify extra_hosts with the default public registry pointing to 127.0.0.1. This will effectively block the public registry from being used by the container.


### Explanations:
1. [Maven](./README.md#Maven)
2. [NPM](./README.md#NPM)
3. [Pip](./README.md#Pip)
4. [Poetry](./README.md#Poetry)
5. [GO](./README.md#Go)
6. [Gradle](./README.md#Gradle)

#### Maven
With Maven, adding environment variables to the settings.xml is as easy as ${env.<environment_variable_name>}. Therefore, if you take any generic settings.xml, and set the servers and credentials to environment variables. Then this can be handled when starting up the container by adding the environment variables either to the docker command with `-e` or by using the `environment:` option when specifying the container in a docker-compose.yml file. For the scanner, all you need to do is map the settings.xml into the .m2 directory. For the remediate container, you need to map the config.js file into the `/usr/src/app` directory and set the environment variables accordingly. For the config.js, you can access environment variables by using the directive `process.env.<variable_name>`

> **_NOTE_**: Any attempt in the POM file to specifically reach out to Maven Central will supercede the settings.xml that you map into the container. Therefore, no registry handling should be specified by the project itself, and rather should leave the container to deal with it.

#### NPM
NPM is not too different than maven. The major difference is that, you need different credentials for the scanner and for the Remediate container. For the scanner, you need the NPM Auth Token that is provided by Artifactory. For the Remediate container, you need the username and password provided by Artifactory. The only other difference is that for environment variables in the .npmrc file, you can just specify ${<variable_name>}. Below is an image showing the NPM Password and the NPM Auth Token.

![Artifactory Credentials Example](./JFrog-Artifactory-Credentials.png)

#### Pip
Pip is probably the most simple method of connecting to private registries. For the scanner, all you need is an environment variable that looks like:
```
PIP_INDEX_URL: https://<user_email>:<user_password>@<artifactory_instance>.jfrog.io/artifactory/api/pypi/default-pypi/simple
```

> **_NOTE_**: As you can probably tell, you do not need a pip.conf file for configuration as you do with the other package managers. Pip will automatically pick up the environment variable and use that, even as priority over any workspace files. There is documentation [here](https://pip.pypa.io/en/stable/topics/configuration/#precedence-override-order) showing how this works.

For the remediate container, you need to match the registry to these 5 managers: ``pip-compile``, ``pip-requirements``, ``pip_setup``, ``pipenv``, ``setup-cfg``

#### Poetry
As of the current writing, the Poetry package manager that is used in the scanner container is version 1.1.12. Due to this, there does not seem to be a good way to manage a private registry with Go without using host rules.

#### Go
Go has a very simple method for connecting to private registries as well. For the scanner, all you need is an environment variable that looks much like Pip's:
```
GOPROXY: https://<user_email>:<user_password>@<artifactory_instance>.jfrog.io/artifactory/api/go/default-go
```
For the remediate container, you only need to match the registry to the ``go`` manager.

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

The properties in the gradle.properties file must have the following names for the script to work:
```properties
repositoryUrl=<registry_url>
repositoryUsername=<registry_user>
repositoryPassword=<registry_password>

pluginRepositoryUrl=<plugin_repository_url>
pluginRepositoryUsername=<plugin_repository_user>
pluginRepositoryPassword=<plugin_repository_password>
```
For the remediate container, you need to match the ``gradle`` and ``gradle-wrapper`` managers for both the repositoryUrl, and the pluginRepositoryUrl.
