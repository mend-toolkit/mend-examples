# Swift Package Manager (SPM) — Private Registry Configuration

This directory contains configuration for using Mend Scanner and Remediate/Renovate with a private JFrog Artifactory Swift Package Registry. Swift dependencies are resolved through Artifactory using authenticated access.

> [!NOTE]
> This example applies to **Self-Managed Repository Integrations** only. It assumes your organization uses a single private Artifactory registry for all teams.

---

## Files in This Directory

| File                             | Maps to (in container)                                     | Purpose                                                   |
| -------------------------------- | ---------------------------------------------------------- | --------------------------------------------------------- |
| `docker-compose.yaml`            | —                                                          | Full stack deployment template                            |
| `config.js`                      | `/usr/src/app/config.js` (remediate)                       | Routes Swift packages to Artifactory and sets credentials |
| `swiftpm-config/registries.json` | `/home/wss-scanner/.swiftpm/configuration/registries.json` | Tells SwiftPM to use Artifactory as the default registry  |
| `.netrc.example`                 | `/home/wss-scanner/.netrc` (copy to `.netrc`)              | Scanner authentication credentials template               |

---

## Environment Variables

| Variable            | Description                                                           | Example                                                           |
| ------------------- | --------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `SPM_REGISTRY`      | Full URL to your Artifactory Swift registry (trailing slash required) | `https://mycompany.jfrog.io/artifactory/api/swift/default-swift/` |
| `SPM_REGISTRY_HOST` | Artifactory hostname (no path)                                        | `mycompany.jfrog.io`                                              |
| `SPM_USER`          | Artifactory username                                                  | `john.doe@company.com`                                            |
| `SPM_PASS`          | Artifactory password or API key                                       | `AKCp...`                                                         |

---

## Setup Steps

### 1. Create the Artifactory Swift Repository

1. Log in to your JFrog Artifactory instance.
2. Go to **Administration → Repositories → Create Repository → Remote**.
3. Set **Package Type** to **Swift**, and set a **Repository Key** (e.g. `default-swift`).
4. Set **URL** to `https://github.com` (Artifactory proxies Swift packages from GitHub).
5. Save. Your registry URL will be:
   ```
   https://<artifactory_instance>.jfrog.io/artifactory/api/swift/<swift_registry>/
   ```
6. Go to **Administration → Security → General** and uncheck **Allow Anonymous Access**.

### 2. Configure `swiftpm-config/registries.json`

Replace the placeholders with your Artifactory instance and registry key:

```json
{
  "registries": {
    "[default]": {
      "url": "https://mycompany.jfrog.io/artifactory/api/swift/default-swift/",
      "supportsAvailability": false
    }
  },
  "authentication": {
    "mycompany.jfrog.io": {
      "type": "basic"
    }
  },
  "version": 1
}
```

### 3. Create `.netrc` for the Scanner

```bash
cp .netrc.example .netrc
chmod 600 .netrc
```

Edit `.netrc` and fill in your credentials:

```
machine mycompany.jfrog.io
login john.doe@company.com
password AKCp...
```

> [!WARNING]
> Do not commit `.netrc` to source control. Add it to `.gitignore`.

### 4. Configure `docker-compose.yaml`

Replace all placeholders:

- `/path/to/prop.json` → absolute path to your `prop.json`
- `/path/to/SPM/` → absolute path to this directory
- `<artifactory_instance>`, `<swift_registry>` → your registry details
- `<username>`, `<password>` → your Artifactory credentials

### 5. Start the Stack

```bash
docker compose up -d
docker compose ps
# Expected: remediate-server, wss-ghe-app, wss-scanner-ghe — all Up
```

---
