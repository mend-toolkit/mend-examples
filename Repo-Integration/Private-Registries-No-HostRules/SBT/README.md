## 10) Scala (SBT)

SBT (Scala Build Tool) by default resolves dependencies from Maven Central and sbt community plugin repositories. 
To comply with private-registry-only policies, configure Mend to resolve Scala/SBT dependencies solely through your private Artifactory repositories.

---

### Create Environment Variables

Add to your `.env` or directly under `environment:` in `docker-compose.yml`:

```dotenv
# Scanner credentials
SBT_USER=<artifactory_user_or_token>
SBT_PASS=<password_or_access_token>
SBT_REALM=Artifactory Realm
SBT_REGISTRY_HOST=<artifactory_domain>                      # e.g. rivernetm.jfrog.io  (NO https://)
SBT_BASE_URL=https://<artifactory_domain>/artifactory
SBT_RELEASES=https://<artifactory_domain>/artifactory/libs-release
SBT_SNAPSHOTS=https://<artifactory_domain>/artifactory/libs-snapshot
SBT_PLUGIN_RELEASES=https://<artifactory_domain>/artifactory/sbt-plugins

# Renovate (Remediate) credentials
RENOVATE_HOST=<artifactory_domain>                          # bare domain, no scheme
RENOVATE_USER=<artifactory_user_or_token>
RENOVATE_PASS=<password_or_access_token>
RENOVATE_MAVEN_REGISTRY=https://<artifactory_domain>/artifactory/libs-release
RENOVATE_IVY_REGISTRY=https://<artifactory_domain>/artifactory/sbt-plugins
RENOVATE_GRADLE_PLUGINS=https://<artifactory_domain>/artifactory/gradle-plugins
```

---

### Package Manager Settings

Create the following files on the host and map them into the scanner container:

**`~/.sbt/repositories`**
```ini
[repositories]
local
private-releases: ${SBT_RELEASES}
private-snapshots: ${SBT_SNAPSHOTS}
private-sbt-plugins: ${SBT_PLUGIN_RELEASES},   [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]
```

**`~/.sbt/1.0/credentials.sbt`**
```scala
import scala.sys.env

credentials += Credentials(
  env.getOrElse("SBT_REALM", "Artifactory Realm"),
  env.getOrElse("SBT_REGISTRY_HOST", ""),  // e.g. rivernetm.jfrog.io
  env.getOrElse("SBT_USER", ""),
  env.getOrElse("SBT_PASS", "")
)
```

**`~/.sbt/1.0/global.sbt`** — recommended to ensure dependency resolution during scans:
```scala
ThisBuild / useCoursier := false                      // or configure COURSIER_* env if you prefer Coursier
ThisBuild / update / aggregate := true
Compile / compile := (Compile / compile).dependsOn(Compile / update).value
Test    / compile := (Test    / compile).dependsOn(Test    / update).value
ThisBuild / evictionErrorLevel := Level.Info
```

---

### Remediate/Renovate Configuration

Provide `config.js` for Renovate so private repos are used for Scala artifacts:

```js
module.exports = {
  hostRules: [
    {
      hostType: "maven",
      matchHost: process.env.RENOVATE_HOST,
      username: process.env.RENOVATE_USER,
      password: process.env.RENOVATE_PASS
    },
    {
      hostType: "ivy",
      matchHost: process.env.RENOVATE_HOST,
      username: process.env.RENOVATE_USER,
      password: process.env.RENOVATE_PASS
    }
  ],
  packageRules: [
    {
      matchManagers: ["maven", "gradle"],
      registryUrls: [process.env.RENOVATE_MAVEN_REGISTRY]
    },
    {
      matchManagers: ["gradle"],
      additionalRegistryUrls: [process.env.RENOVATE_GRADLE_PLUGINS]
    },
    {
      matchManagers: ["sbt"],
      registryUrls: [
        process.env.RENOVATE_MAVEN_REGISTRY,
        process.env.RENOVATE_IVY_REGISTRY
      ]
    }
  ],
  prConcurrentLimit: 5,
  prHourlyLimit: 3
};
```

Mount it into the remediate container at `/usr/src/app/config.js`.

---

### Map Files and Variables

**Scanner container (docker-compose):**
```yaml
environment:
  SBT_OPTS: "-Dsbt.override.build.repos=true"
  SBT_USER: ${SBT_USER}
  SBT_PASS: ${SBT_PASS}
  SBT_REALM: ${SBT_REALM}
  SBT_REGISTRY_HOST: ${SBT_REGISTRY_HOST}
  SBT_BASE_URL: ${SBT_BASE_URL}
  SBT_RELEASES: ${SBT_RELEASES}
  SBT_SNAPSHOTS: ${SBT_SNAPSHOTS}
  SBT_PLUGIN_RELEASES: ${SBT_PLUGIN_RELEASES}

volumes:
  - ./SBT/repositories:/home/wss-scanner/.sbt/repositories:ro
  - ./SBT/credentials.sbt:/home/wss-scanner/.sbt/1.0/credentials.sbt:ro
  - ./SBT/global.sbt:/home/wss-scanner/.sbt/1.0/global.sbt:ro
```

**Remediate container (docker-compose):**
```yaml
environment:
  RENOVATE_HOST: ${RENOVATE_HOST}
  RENOVATE_USER: ${RENOVATE_USER}
  RENOVATE_PASS: ${RENOVATE_PASS}
  RENOVATE_MAVEN_REGISTRY: ${RENOVATE_MAVEN_REGISTRY}
  RENOVATE_IVY_REGISTRY: ${RENOVATE_IVY_REGISTRY}
  RENOVATE_GRADLE_PLUGINS: ${RENOVATE_GRADLE_PLUGINS}

volumes:
  - ./SBT/config.js:/usr/src/app/config.js:ro
```

---

### Block Public Registries

Prevent fallback to public registries (optional once Artifactory virtuals are confirmed):
```yaml
extra_hosts:
  - "repo.maven.apache.org:127.0.0.1"
  - "repo1.maven.org:127.0.0.1"
  - "repo2.maven.org:127.0.0.1"
  - "repo.scala-sbt.org:127.0.0.1"
  - "repo.typesafe.com:127.0.0.1"
```
