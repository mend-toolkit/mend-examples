# Custom CA Setup For Mend.io Self Managed SCM Integration

**As of v23.8.1**

Use the following instructions to enable Mend.io self-hosted repo integration to connect to a self-hosted SCM system (e.g, GitHub Enterprise) which uses a non-public certificate.

## Overview

1. Configure docker host system with custom CA certs
   * Confirm with successful ```curl``` to SCM system
2. On docker host, export certs using:
   * On RPM-based distros (CentOS, RHEL, Amazon, etc):
     * ```update-ca-trust extract``` (system & java keystore)
       * https://www.linux.org/docs/man8/update-ca-trust.html
   * On Debian-based distros (Ubuntu, etc):
     * ```update-ca-certificates``` (system)
     * ```update-java-ca-certificates``` (java keystore - [Download link](https://raw.githubusercontent.com/mend-toolkit/mend-examples/6c0461b1ca3431aea0c656606ecbf2a059d04af8/Repo-Integration/Binaries/update-java-ca-certificates/update-java-ca-certificates) and [Instructions](#appendix-update-java-ca-certificates-usage))
3. Add cert volume mappings and environment variable to docker-compose.yaml or helm charts (see next section).


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
      - /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem:/etc/ssl/certs/ca-certificates.crt
      # containerbase java install symlinks /opt/containerbase/ssl/cacerts into the jre security folder
      - /etc/pki/ca-trust/extracted/java/cacerts:/opt/containerbase/ssl/cacerts
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
      - /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem:/etc/ssl/certs/ca-certificates.crt
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
      # containerbase java install symlinks /opt/containerbase/ssl/cacerts into the jre security folder
      - /etc/ssl/java/cacerts:/opt/containerbase/ssl/cacerts
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

#### Appendix: update-java-ca-certificates usage

This utility is created by: https://github.com/swisscom/update-java-ca-certificates.
The purpose of this utility is to create a keystore at /etc/ssl/java/cacerts without the need for Java. Here are the following steps to run this:

1. Make sure you have added the certificate to the /usr/local/share/ca-certificates  directory and run: ``sudo update-ca-certificates``
2. The certificate should now be added to your /etc/ssl/certs directory. To confirm you can run: ``ls -al /etc/ssl/certs | grep <your_cert_name>``
3. Run the update-java-ca-certificates utility with super user privileges: 

```shell
if [ ! -d "/etc/ssl/java/" ]; then
  mkdir -p /etc/ssl/java
sudo update-java-ca-certificates -c /etc/ssl/certs/ca-certificates.crt /etc/ssl/java/cacerts
```
