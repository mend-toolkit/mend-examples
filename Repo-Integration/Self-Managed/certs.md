# Custom CA Setup For Mend.io Self Managed SCM Integration

**As of v23.8.1**

## Overview

1. Configure host with custom CA certs
   * Confirm with successful ```curl``` to SCM system
2. On docker host, export certs using:
   * On RPM-based distros (CentOS, RHEL, Amazon, etc):
     * ```update-ca-trust extract``` (system & java keystore)
       * https://www.linux.org/docs/man8/update-ca-trust.html
   * On Debian-based distros (Ubuntu, etc):
     * ```update-ca-certificates``` (system)
     * ```update-java-ca-certificates``` (java keystore) - contact Mend for CLI utility
3. Add cert volume mappings and environment variable to docker-compose.yaml or helm charts

## Container Configurations

### RPM-Based Host (e.g. RHEL, CentOS, Amazon)

After exporting custom CA certs on the host (see above), add the following volume mappings to the Mend container services:

Example docker-compose.yaml snippet:

#### Controller (wss-app)

```
  app:
    # ...
    volumes:
      # handles certs for most system utilities and git
      - /etc/pki/ca-trust/extracted/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt
      # containerbase java install symlinks /opt/buildpack/ssl/cacerts into the jre security folder
      - /etc/pki/ca-trust/extracted/java/cacerts:/opt/buildpack/ssl/cacerts
    # ...
```

#### Scanner (wss-scanner)

```
  scanner:
    # ...
    volumes:
      # handles certs for most system utilities and git
      - /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem:/etc/ssl/certs/ca-certificates.crt
      # containerbase java install symlinks /opt/containerbase/ssl/cacerts into all jdk installs 
      - /etc/pki/ca-trust/extracted/java/cacerts:/opt/containerbase/ssl/cacerts
    # ...
```

#### Remediate (wss-remediate)

```
  remediate:
    # ...
    volumes:
      # handles certs for most system utilities and git
      - /etc/pki/ca-trust/extracted/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt
      # containerbase java install symlinks /opt/containerbase/ssl/cacerts into the jre security folder
      - /etc/pki/ca-trust/extracted/java/cacerts:/opt/containerbase/ssl/cacerts

    environment:
      # configures Node to use custom certs exported from host
      - NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
      # ...
```

### Debian-Based Host (e.g. Ubuntu, etc)

After exporting custom CA certs on the host (see above), add the following volume mappings to the Mend container services:

Example docker-compose.yaml snippet:

#### Controller (wss-app)

```
  app:
    # ...
    volumes:
      # handles certs for most system utilities and git
      - /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt
      # containerbase java install symlinks /opt/buildpack/ssl/cacerts into the jre security folder
      - /etc/ssl/java/cacerts:/opt/buildpack/ssl/cacerts
    # ...
```

#### Scanner (wss-scanner)

```
  scanner:
    # ...
    volumes:
      # handles certs for most system utilities and git
      - /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt
      # containerbase java install symlinks /opt/containerbase/ssl/cacerts into the jre security folder
      - /etc/ssl/java/cacerts:/opt/containerbase/ssl/cacerts
    # ...
```

#### Remediate (wss-remediate)

```
  remediate:
    # ...
    volumes:
      # handles certs for most system utilities and git
      - /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt
      # containerbase java install symlinks /opt/containerbase/ssl/cacerts into the jre security folder
      - /etc/ssl/java/cacerts:/opt/containerbase/ssl/cacerts

    environment:
      # configures Node to use custom certs exported from host
      - NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
    # ...
```

