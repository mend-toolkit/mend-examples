# 10) SBT

This guide explains how to set up and run no-host-rule private registry configuration for SBT (Scala) package manager.

## **📂 Structure**

Your setup includes the following important files:

- **docker-compose.yaml** → Defines the Renovate container and volume mappings
- **config.js** → Renovate configuration (registries, host rules)
- **global.sbt** → Global SBT settings for dependency resolvers
- **credentials** → Artifactory credentials for SBT
- **repositories** → SBT repositories configuration
- **.env** → Environment varialbes for config.js
- **credentials.properties** → Coursier credentials

## **⚙️ Configuration**

1. Docker-compose.yaml

   Adjust the paths according to your actual setup.

```
services:
  remediate:
    image: wss-remediate:25.8.1
    container_name: remediate-server
    env_file:
      - .env
    ports:
      - "8080:8080"
    volumes:
      - "/home/ubuntu/agent-4-github-enterprise-25.8.1.2/wss-configuration/config/prop.json:/etc/usr/local/whitesource/conf/prop.json"
      - "/home/ubuntu/SBT/config.js:/usr/src/app/config.js"
    restart: always
    logging:
      driver: local
      options:
        max-size: 1m
        max-file: "5"
  app:
    build:
      context: /home/ubuntu/agent-4-github-enterprise-25.8.1.2/wss-ghe-app/docker
    image: wss-ghe-app:25.8.1.2
    container_name: wss-ghe-app
    env_file:
      - .env
    ports:
      - "9494:9494"
      - "5678:5678"
    volumes:
      - "/home/ubuntu/agent-4-github-enterprise-25.8.1.2/wss-configuration/config/prop.json:/etc/usr/local/whitesource/conf/prop.json"
    restart: always
    logging:
      driver: local
      options:
        max-size: 1m
        max-file: "5"
  scanner:
    build:
      context: /home/ubuntu/agent-4-github-enterprise-25.8.1.12/wss-scanner/docker
      dockerfile: Dockerfilefull
    image: wss-scanner:25.8.1.1
    container_name: wss-scanner-ghe
    env_file:
    - .env
    ports:
      - "9393:9393"
    volumes:
      - "/home/ubuntu/agent-4-github-enterprise-25.8.1.2/wss-configuration/config/prop.json:/etc/usr/local/whitesource/conf/prop.json"
      # SBT repositories
      - "/home/ubuntu/SBT/repositories:/home/wss-scanner/.sbt/repositories:ro"
      # Ivy credentials
      - "/home/ubuntu/SBT/.credentials:/home/wss-scanner/.ivy2/.credentials:ro"
      # Global sbt settings
      - "/home/ubuntu/SBT/global.sbt:/home/wss-scanner/.sbt/1.0/global.sbt:ro"
      # Coursier credentials
      - "/home/ubuntu/SBT/credentials.properties:/home/wss-scanner/.config/coursier/credentials.properties:ro"
      # Writable caches
      - "./sbt-cache/coursier:/home/wss-scanner/.cache/coursier:rw"
      - "./sbt-cache/ivy2:/home/wss-scanner/.ivy2:rw"
      - "./sbt-cache/boot:/home/wss-scanner/.sbt/boot:rw"
      - "./sbt-cache/containerbase:/tmp/containerbase/cache:rw"
    environment:
      SBT_CREDENTIALS: "/home/wss-scanner/.ivy2/.credentials"
      SBT_OPTS: >
        -Dfile.encoding=utf-8
        -Djline.terminal=off
        -Dsbt.log.noformat=true
        -Dsbt.repository.config=/home/wss-scanner/.sbt/repositories
        -Dsbt.global.base=/home/wss-scanner/.sbt
        -Dsbt.boot.directory=/home/wss-scanner/.sbt/boot
        -Dsbt.ivy.home=/home/wss-scanner/.ivy2
        -Dsbt.override.build.repos=true
        -Dsbt.ivy.home=/home/wss-scanner/.ivy2
        -Dsbt.boot.credentials=/home/wss-scanner/.ivy2/.credentials
      COURSIER_CACHE: /home/wss-scanner/.cache/coursier
      COURSIER_NO_DEFAULT: "true"
      SBT_HOME: /home/wss-scanner/.sbt
      JAVA_OPTS: >-
        --add-opens java.base/java.util=ALL-UNNAMED
        --add-opens java.base/sun.reflect.generics.reflectiveObjects=ALL-UNNAMED
    extra_hosts:
      # Block Maven Central repositories
      - "repo.maven.apache.org:127.0.0.1"
      - "repo1.maven.org:127.0.0.1"
      - "repo2.maven.org:127.0.0.1"
      - "repo.scala-sbt.org:127.0.0.1"
      - "dl.bintray.com:127.0.0.1"
      - "oss.sonatype.org:127.0.0.1"
      - "s01.oss.sonatype.org:127.0.0.1"
      - "repo.typesafe.com:127.0.0.1"
    restart: always
    logging:
      driver: local
      options:
        max-size: 1m
        max-file: "5"
volumes:
  sbt-coursier-cache:
  sbt-ivy-cache:
  sbt-boot-cache:
  sbt-containerbase-cache:
networks:
  default:
    name: my_bridge
```



### **config.js**

Renovate is configured to fetch dependencies from JFrog Artifactory:

```2. Global SBT Settings (
module.exports = {
  packageRules: [
    {
      matchManagers: ["sbt"],
      matchDatasources: ["maven"],
      registryUrls: ["https://<artifactory>.jfrog.io/artifactory/libs-release"]
    },
    {
      matchManagers: ["sbt"],
      matchDatasources: ["maven"],
      registryUrls: ["https://<artifactory>.jfrog.io/artifactory/sbt-plugins"]
    }
  ],
  hostRules: [
    {
      hostType: "maven",
      matchHost: "rivernetm.jfrog.io",
      username: process.env.SBT_USER || "",
      password: process.env.SBT_PASS || ""
    }
  ]
};
```

### **global.sbt**

Contains repository resolvers and ensures SBT uses Artifactory:

```
credentials += Credentials(Path.userHome / ".sbt" / "1.0" / "credentials")
```

### **credentials**

Defines SBT authentication for Artifactory:

```
realm=Artifactory Realm
host=<artifactory>.jfrog.io
user=<username>
password=<access token>
```

### **repositories**

Configures where SBT fetches dependencies:

```
[repositories]
  local
  my-ivy-proxy-releases: https://<artifactory>.jfrog.io/artifactory/sbt-plugins/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]
  my-maven-proxy-releases: https://<artifactory>.jfrog.io/artifactory/libs-release/
```

An example for the repositories in the artifactory:

| **Virtual Repository** | **Remote Repository**       | **URL**                                                  | **Purpose**                                                  |
| ---------------------- | --------------------------- | -------------------------------------------------------- | ------------------------------------------------------------ |
| sbt-plugins            | sbt-plugins-releases-remote | http://repo.scala-sbt.org/scalasbt/sbt-plugin-releases/  | Main source for sbt plugins.                                 |
| sbt-plugins            | sbt-ivy-remote              | http://repo.typesafe.com/typesafe/ivy-releases/          | Legacy/Typesafe Ivy repo for sbt plugins and older artifacts. |
| libs-release           | sbt-maven-remote            | https://repo.scala-sbt.org/scalasbt/maven-releases       | sbt artifacts published in Maven style.                      |
| libs-release           | sbt-plugin-remote           | https://repo.scala-sbt.org/scalasbt/sbt-plugin-releases/ | sbt plugin artifacts published in Maven style (redundant but safe to keep). |
| libs-release           | maven-central-remote        | https://repo1.maven.org/maven2/                          | Standard Maven Central repository.                           |



### **.env**

Add Artifactory credentials:

```
# .env
SBT_REGISTRY=https://<artifactory>.jfrog.io/artifactory/libs-release
SBT_USER=<artifactory username>
SBT_PASS=<access token>
```

After creating all the files and making sure the paths and credentials are correct run on your host:

```
sudo mkdir -p ./sbt-cache/.sbt-boot ./sbt-cache/coursier ./sbt-cache/tmp /home/ubuntu/.ivy2
sudo chown -R 1000:1000 ./sbt-cache /home/ubuntu/.ivy2
```

This ensures volumes are writable by wss-scanner user.

**Run docker compose up -d**
