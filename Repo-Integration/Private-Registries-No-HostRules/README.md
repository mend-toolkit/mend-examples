# Configuring Private Registries without Host Rules For Self-Managed Repository Integrations

Many organizations have security policies that restrict access to public registries like Maven Central, the default repository used by Maven to download dependencies. Mend addresses this by allowing you to specify private registry credentials directly within the repository for each Mend-Hosted repository integration. This is supported for integrations with ([Github.com](https://docs.mend.io/bundle/integrations/page/mend_for_github_com.html), [Azure Repos](https://docs.mend.io/bundle/integrations/page/using_mend_for_azure_repos.html), [Bitbucket Cloud](https://docs.mend.io/bundle/integrations/page/installation_of_mend_for_bitbucket_cloud.html)). 

For Self-Managed Repository Integrations, there's an alternative approach to specifying host rules without modifying the repository or using global settings. This container-level configuration enhances ease of use, privacy, and tamper prevention. However, this setup is only applicable if the following criteria apply to your organization:

- The organization uses one private registry source per package manager type for all teams.
- Individual teams cannot use a different private registry.

> [!TIP]  
Examples for each package manager may be found in this directory. Customer's may pick from individual ones and combine these configurations to suit their needs.

### Steps:

1. **Create Environment Variables:**
   - Define sensible environment variables. The example provided in the `./Maven/docker-compose.yml` file uses `MVN_USER`, `MVN_PASS`, `MVN_RELEASES`, and `MVN_SNAPSHOTS` for credentials and URLs. However these could differ across package managers. 

2. **Package Manager Settings:**
   - Create a package manager settings file (e.g., `settings.xml`) to inject these environment variables. In the provided Maven example, these variables are accessible using `${env.<VARIABLE_NAME>}`.

3. **Remediate/Renovate Configuration (Optional):**
   - Create a `config.js` file (located in `./Maven/config.js` in the example) to direct Remediate/Renovate to your desired registry. Use `module.exports` to specify the Remediate configuration similar to a global configuration. The password can remain in plain text within the container as it is never exposed to the public directly.

4. **Map Files and Variables:**
   - Map the relevant files and variables to the scanner and remediate containers (demonstrated in the `./Maven/docker-compose.yml` file).

5. **Block Public Registry (Optional):**
   - In both containers, specify `extra_hosts` with the default public registry pointing to `127.0.0.1`. This effectively blocks the container from using the public registry.

### Explanations by Package Manager:

1. **Maven**:

   - Add environment variables to `settings.xml` using `${env.<environment_variable_name>}`.

   - Set server and credential environment variables when starting the container.

   - For the scanner, map `settings.xml` to the `$HOME/.m2` directory.

   - For the remediate container, map `config.js` to `/usr/src/app` directory and set environment variables accordingly.

> [!NOTE]  
The POM file in a repository shouldn't specify registry handling, and should defer to the container configuration.

2. **NPM**:
 
   - The scanner requires the NPM Auth Token from Artifactory, while the remediate container needs the username and password.

   - For the scanner a ``.npmrc`` file should be included that looks like:
     ```
     email = ${NPM_EMAIL}
     always-auth = true
     registry = ${NPM_REGISTRY}
     ```

   - The environment variables required for the scanner are:
     ```
     NPM_REGISTRY: "https://<artifactory_instance>.jfrog.io/artifactory/api/npm/<npm_registry>"
     NPM_EMAIL: "<email_username_for_authentication>"
     NPM_CONFIG_//<artifactory_instance>.jfrog.io/artifactory/api/npm/<npm_registry>:_auth: "<NPM_AUTH_TOKEN>"
     ```

> [!WARNING]  
The Auth Token environment variable must be specified in a source that allows special characters in the variable name. For the purpose of these examples, a ``docker-compose.yaml`` file can store this information, but cannot be specified in a ``.env`` file due to how docker compose processes those files.

3. **Pip**:

   - For the scanner, use an environment variable like:

     ```
     PIP_INDEX_URL: https://<username>:<user_password>@<artifactory_instance>.jfrog.io/artifactory/api/pypi/default-pypi/simple
     ```

     If your username is an email address, then you should url encode the "@" symbol. For ``user.example@test.org`` you would specify ``user.example%40test.org``

> [!NOTE]  
Pip prioritizes environment variables over workspace files. Refer to [https://pip.pypa.io/en/stable/topics/configuration/](https://pip.pypa.io/en/stable/topics/configuration/#precedence-override-order) for details.

   No ``pip.conf`` file is required for the scanner or remediate container; it uses the environment variable.

4. **Poetry**:

   - Poetry specifies which repository it references in the ``pyproject.toml`` as well as the ``poetry.lock`` files. Therefore, the name of the repository in the pyproject.toml **MUST** match the name of the repository in the environment variables.  
     For instance, if you have the following in your ``pyproject.toml``:
     ```
     [[tool.poetry.source]]
     name = "main"
     url = "https://<private registry url>"
     priority = "primary"
     ```

     Then you must also set the environment variables on the scanner with relation to the name "main". For instance:
     ```
     POETRY_REPOSITORIES_MAIN_URL: "https://<private registry url>"
     POETRY_HTTP_BASIC_MAIN_USERNAME: "<username>"
     POETRY_HTTP_BASIC_MAIN_PASSWORD: "<password>"
     ```

> [!NOTE]  
If the registry for poetry is also shared with PIP, then you can consolidate this for the remediate server/worker containers to only specify the PIP registry/username/password, and then add the ``poetry`` and ``pep621`` managers to the config.js.

5. **Go**:

   - For both scanner and remediate containers, use an environment variable similar to Pip's:

     ```
     GOPROXY: https://<user_email>:<user_password>@<artifactory_instance>.jfrog.io/artifactory/api/go/default-go
     ```

> [!NOTE]  
Go's `datasource` in Renovate doesn't support private registries; use `GOPROXY`. Refer to this [link](https://docs.renovatebot.com/modules/datasource/go/) for details.

6. **Gradle**:

   Mend offers two methods for resolving private registries with Gradle: Groovy and Kotlin.

   **Groovy**:

   1. An `init.gradle` file is created to execute before project resolution.
   2. The script searches for `gradle.properties` files in the project root and user's Gradle directory (`~/.gradle`).
   3. Properties (`repositoryUrl`, `repositoryUsername`, `repositoryPassword`, etc.) are loaded from these files (with project-level properties taking precedence).
   4. The script sets these properties in a `SettingsEvaluated` section of `init.gradle`.

   Map a `gradle.properties` file to the `/home/wss-scanner/.gradle` directory or use one directly in the project to specify repository credentials.

   **Kotlin**:

   Similar to Groovy, a `init.gradle.kts` file loads repositories before resolving projects. It follows the same logic as the Groovy script, allowing you to map a `gradle.properties` file for credentials.

   The `gradle.properties` file requires specific property names:

   ```properties
   repositoryUrl=<registry_url>
   repositoryUsername=<registry_user>
   repositoryPassword=<registry_password>

   pluginRepositoryUrl=<plugin_repository_url>
   pluginRepositoryUsername=<plugin_repository_user>
   pluginRepositoryPassword=<plugin_repository_password>
   ```

   For the remediate container, match the `gradle` and `gradle-wrapper` managers for both `repositoryUrl` and `pluginRepositoryUrl`.

7. **NuGet**:

   - Create a `NuGet.Config` file that references environment variables for the Artifactory registry.
   - The password is the one provided by Artifactory with the specification `ClearTextPassword` in the `NuGet.Config` file.

> [!WARNING]  
Map the file into the container as `NuGet.Config` with the correct capitalization. This is because the container already creates this file when installing the dotnet CLI, and needs to be overridden.

8. **Conda**:

   - For the environment variables you need two different usernames, two different URLs, and the password:
      - `CONDA_REGISTRY: https://<artifactory-instance>.jfrog.io/artifactory/api/conda/<conda_registry>`
      - `CONDA_CHANNEL: <artifactory-instance>.jfrog.io/artifactory/api/conda/<conda_registry>`
      - `CONDA_USER: user.name@domain.com`
      - `CONDA_USER_ENCODED: user.name%40domain.com`
      - `CONDA_PASS: <password>`

   - For the scanner container, the Unified Agent runs ``conda create env -f <environment>.yml`` to create an environment based off of the file provided in the repository. It then resolves the dependencies based off of that.  
   **NOTE**: Due to conda's behavior, it will fail if it resolves packages that have not been added to the private registry already for that  OS. Please make sure that the packages have been resolved already in the private registry for linux-64.
   - Add the following [.condarc](./Conda/.condarc) file as a volume map into the home directory: `/path/to/.condarc:/home/wss-scanner/.condarc`
   - In the scanner container set the environment variables for: `CONDA_CHANNEL`, `CONDA_USER_ENCODED`, `CONDA_PASS`

   - For your config.js use the `CONDA_REGISTRY` environment variable and then use `CONDA_USER` and `CONDA_PASS` for the credentials.

9. **Docker**:

   - The integration itself doesn't perform image scans.
   - Only Remediate/Renovate require credentials.
   - Use a `config.js` file and specify the required environment variables:
   - For the "matchHost", use only the registry domain name without a path: (e.g. ``https://<artifactory-instance>.jfrog.io``)

   ```javascript
   module.exports = {
     "hostRules": [{
         "hostType": "docker",
         "matchHost": process.env.DOCKER_REGISTRY,
         "userName": process.env.DOCKER_USER,
         "password": process.env.DOCKER_PASS
     }]
   }
   ```

   Then, simply map in the necessary environment variables.

> [!IMPORTANT]  
The host rule provided in the ``config.js`` file will not force Remediate/Renovate to use this registry for every image. If a Dockerfile specifies an image as ``ubuntu:latest`` then it will attempt to pull it from DockerHub (if DockerHub is blocked, then the resolution for this image will simply fail). Therefore, to force the integration to only use the private registry specified, every instance of an image must point to the repository (e.g. ``FROM <artifactory-instance>.jfrog.io/<repository>/ubuntu:latest``)

> [!NOTE]  
Many packages don't follow the "SemVer" versioning scheme, which is the default for the ``docker`` manager. Refer to [https://docs.renovatebot.com/docker/#version-compatibility](https://docs.renovatebot.com/docker/#version-compatibility) for details on changing versioning for specific packages. This can be handled directly in the repository and does not need to be handled at the container level. Refer to [https://docs.renovatebot.com/modules/versioning/](https://docs.renovatebot.com/modules/versioning/) for more information on supported versioning schemes and custom versioning.

9. **Ruby**:

   - Does not have any configuration files. Although a ``.gemrc`` file can be used, there is no need with the use of environment variables.
   - Specifying URL/credentials are different for the scanner and remediate. Both will be specified in this section.
   - For Renovate, the hostType must be set to "rubygems", and the URL must be in the format: ``https://<artifactory_instance>.jfrog.io/artifactory/<ruby_repository>``.
      - The credentials are username and password, where the password is the token generated when using Artifactory's "Set Me Up" function.
   - For the Scanner, set the following environment variables:
      - ``GEM_HOST: https://<artifactory_instance>.jfrog.io/artifactory/api/gems/<ruby_repository>``
      - ``GEM_API_KEY: <artifactory_api_key>``

> [!NOTE]
The Artifactory API Key for your ruby registry can be found by navigating to: ``https://<artifactory_instance>.jfrog.io/artifactory/api/gems/<ruby_repository>/api/v1/api_key.yaml`` in your browser and logging in. After doing so, a file will be downloaded that contains the API key, which you can then copy and paste the value into the environment variable. The value should not include "Basic" or any other form of HTTP Authentication prefixes.
