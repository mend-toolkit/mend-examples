## Encrypting Private Registry Credentials for hostRule Configurations

Mend Repository Integration customers often require encrypted credentials to access private registries for package resolution.

Typically, users can encrypt credentials through the following methods:

- **Cloud-Hosted Integrations:** [Mend Repo Integration Encryption page](https://mend-resources.mend.io/index-gh.html)
  - Relevant Integrations: [Github.com](https://docs.mend.io/bundle/integrations/page/configure_mend_for_github_com_to_resolve_your_private_dependencies.html), [Azure Repos](https://docs.mend.io/bundle/integrations/page/configure_mend_for_azure_repos_to_resolve_your_private_dependencies.html), [BitBucket Cloud](https://docs.mend.io/bundle/integrations/page/installation_of_mend_for_bitbucket_cloud.html#Handling-Private-Registries-and-Authenticated-Repositories)
- **Self-Hosted Repository Integrations:** Using a page with a public key created by the user
  - Relevant Integrations: [GitHub Enterprise](https://docs.mend.io/bundle/integrations/page/configure_mend_for_github_enterprise_to_resolve_your_private_dependencies.html), [BitBucket Datacenter](https://docs.mend.io/bundle/integrations/page/mend_for_bitbucket_server_and_data_center.html#Handling-Private-Registries-and-Authenticated-Repositories), [Gitlab Server](https://docs.mend.io/bundle/integrations/page/installing_mend_for_gitlab.html#Handling-Private-Registries-and-Authenticated-Repositories)
- **Renovate:** [Renovate Encryption page](https://app.renovatebot.com/encrypt)
  - Documentation: [Renovate Encryption](https://docs.renovatebot.com/getting-started/private-packages/#encryption-and-the-mend-renovate-app)

This script provides an alternative to these methods for encryption.

Requirements:
```
Python 3.9+
```

Installation steps:
```
pip install -r pgpy==0.6.0
```


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

Examples:  

Create encrypted credentials for the self-hosted repository integration
```
python3 encrypt_credentials.py -o "<Organization Name>" -r "<Repository Name>" -v "<Secret Value>"
```

Create encrypted credentials for a self-hosted integration
```
python3 encrypt_credentials.py -o "<Organization Name>" -r "<Repository Name>" -v "<Secret Value>" -k "./secret_key.pem"
```

Create encrypted credentials for Renovate-specific configurations in a ``renovate.json``
```
python3 encrypt_credentials.py -o "<Organization Name>" -r "<Repository Name>" -v "<Secret Value>" -rk
```

<hr />
Output:

The script outputs the encrypted credentials in the following format:
```
Encrypted Secret Value:
wcBMA8xOaBJvzJNbAQxxxxxxxxxxxxxxxxxxxxxxxx...
```
