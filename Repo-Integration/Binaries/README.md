![Logo](https://mend-toolkit-resources-public.s3.amazonaws.com/img/mend-io-logo-horizontal.svg)  

# MEND Self-Hosted Repository Integration Binaries
This folder contains supplemental binaries for the Self-Hosted Repository Integrations to simplify any needed processes.

- [Update Java Ca-certificates keystore without using keytool](#update-java-ca-certificates)

<hr />

## [Update Java ca-certificates](./update-java-ca-certificates)

This utility is created by: https://github.com/swisscom/update-java-ca-certificates.
The purpose of this utility is to create a keystore at /etc/ssl/java/cacerts without the need for Java. Here are the following steps to run this:

1. Download update-java-ca-certificates binary with the command: ``curl https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/Repo-Integration/Binaries/update-java-ca-certificates -o /usr/local/bin/update-java-ca-certificates``
2. Make sure you have added the certificate to the /usr/local/share/ca-certificates  directory and run: ``sudo update-ca-certificates``
3. The certificate should now be added to your /etc/ssl/certs directory. To confirm you can run: ``ls -al /etc/ssl/certs | grep <your_cert_name>``
4. Run the update-java-ca-certificates utility with super user privileges: ``sudo update-java-ca-certificates --certificate-bundle /etc/ssl/certs/ca-certificates.crt /etc/ssl/java/cacerts``
