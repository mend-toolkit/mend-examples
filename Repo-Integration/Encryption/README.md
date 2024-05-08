## Encrypting Private Registry Credentials for hostRule Configurations

Mend Repository Integration customers often require encrypted credentials to access private registries for package resolution.

Typically, users can encrypt credentials through the following methods:

- **Cloud-Hosted Integrations:** [Mend Repo Integration Encryption page](https://mend-resources.mend.io/index-gh.html)
- **Self-Hosted Repository Integrations:** Using a page with a public key created by the user
- **Renovate:** [Renovate Encryption page](https://app.renovatebot.com/encrypt)

This script provides an alternative to these methods for encryption.

Usage:
```
usage: encrypt_credentials.py [-h] -o ORGANIZATION [-r REPOSITORY] -v SECRET_VALUE [-k PUBLIC_KEY_FILE | -rk | --renovate-key | --no-renovate-key]

A script replacement for the Mend.io Host Rule encryption web pages

optional arguments:
  -h, --help            show this help message and exit
  -o ORGANIZATION, --organization ORGANIZATION
                        Organization Name (Environment Variable: ORGANIZATION)
  -r REPOSITORY, --repository REPOSITORY
                        Repository Name (Optional) (Environment Variable: REPOSITORY)
  -v SECRET_VALUE, --secret-value SECRET_VALUE
                        Secret Value (Environment Variable: SECRET_VALUE)
  -k PUBLIC_KEY_FILE, --public-key-file PUBLIC_KEY_FILE
                        Public Key File (Optional, Default: Cloud Repository Integration Public Key) (Environment Variable: PUBLIC_KEY_FILE)
  -rk, --renovate-key, --no-renovate-key
                        Whether to use the Renovate Public key for renovate.json files (default: False)
```

Output:

The script outputs the encrypted credentials in the following format:
```
Encrypted Secret Value:
wcBMA8xOaBJvzJNbAQxxxxxxxxxxxxxxxxxxxxxxxx...
```
