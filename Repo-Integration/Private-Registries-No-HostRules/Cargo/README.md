# Cargo (Rust) — Private Registry Configuration

This directory contains configuration for using Mend Scanner and Remediate/Renovate with a private JFrog Artifactory Cargo registry. Rust dependencies are resolved through Artifactory using authenticated access.

> [!NOTE]
> This example applies to **Self-Managed Repository Integrations** only. It assumes your organization uses a single private Artifactory registry for all teams.

---

## Files in This Directory

| File | Maps to (in container) | Purpose |
|---|---|---|
| `docker-compose.yaml` | — | Full stack deployment template |
| `config.js` | `/usr/src/app/config.js` (remediate) | Routes Cargo packages to Artifactory and sets credentials |
| `config.toml` | `/home/wss-scanner/.cargo/config.toml` (scanner) | Tells Cargo to use Artifactory instead of crates.io |
| `credentials.toml.example` | `/home/wss-scanner/.cargo/credentials.toml` (copy to `credentials.toml`) | Scanner authentication credentials template |

---

## Environment Variables

| Variable | Description | Example |
|---|---|---|
| `CARGO_REGISTRY` | Full URL to your Artifactory Cargo registry (trailing slash required) | `https://mycompany.jfrog.io/artifactory/api/cargo/cargo-dev/` |
| `CARGO_REGISTRY_HOST` | Artifactory hostname (no path) | `mycompany.jfrog.io` |
| `CARGO_USER` | Artifactory username | `john.doe@company.com` |
| `CARGO_PASS` | Artifactory password or API key | `AKCp...` |

---

## Setup Steps

### 1. Create the Artifactory Cargo Repository

1. Log in to your JFrog Artifactory instance.
2. Go to **Administration → Repositories → Create Repository → Remote**.
3. Set **Package Type** to **Cargo**, and set a **Repository Key** (e.g. `cargo-dev`).
4. Set **URL** to `https://github.com/rust-lang/crates.io-index`.
5. Under **Advanced**, enable **Sparse Index** (requires Artifactory 7.47+ and Cargo 1.68+).
6. Save. Your registry URL will be:
   ```
   https://<artifactory_instance>.jfrog.io/artifactory/api/cargo/<cargo_registry>/
   ```
7. Go to **Administration → Security → General** and uncheck **Allow Anonymous Access**.

### 2. Configure `config.toml`

Replace the placeholders with your Artifactory instance and registry key:

```toml
[source.crates-io]
replace-with = "artifactory"

[registries.artifactory]
index = "sparse+https://mycompany.jfrog.io/artifactory/api/cargo/cargo-dev/index/"
```

> **Note:** The `replace-with = "artifactory"` entry silently redirects all crates.io lookups to Artifactory. No changes are needed to any repository's `Cargo.toml`.

### 3. Create `credentials.toml` for the Scanner

```bash
cp credentials.toml.example credentials.toml
chmod 600 credentials.toml
```

The token must be Base64-encoded `username:password`. Generate it:

```bash
echo -n "john.doe@company.com:AKCp..." | base64
```

Edit `credentials.toml` and fill in the encoded value:

```toml
[registries.artifactory]
token = "Basic <base64_encoded_username:password>"
```

> [!WARNING]
> Do not commit `credentials.toml` to source control. Add it to `.gitignore`.

### 4. Configure `docker-compose.yaml`

Replace all placeholders:

- `/path/to/prop.json` → absolute path to your `prop.json`
- `/path/to/Cargo/` → absolute path to this directory
- `<artifactory_instance>`, `<cargo_registry>` → your registry details
- `<username>`, `<password>` → your Artifactory credentials

### 5. Start the Stack

```bash
docker compose up -d
docker compose ps
# Expected: remediate-server, wss-ghe-app, wss-scanner-ghe — all Up
```

---

## References

- [Cargo Source Replacement](https://doc.rust-lang.org/cargo/reference/source-replacement.html)
- [Cargo Registry Authentication](https://doc.rust-lang.org/cargo/reference/registry-authentication.html)
- [JFrog Artifactory Cargo Repository](https://jfrog.com/help/r/jfrog-artifactory-documentation/cargo-registry)
- [JFrog Cargo Sparse Index](https://jfrog.com/help/r/jfrog-artifactory-documentation/index-cargo-repositories-using-sparse-indexing)
- [Renovate Cargo Manager](https://docs.renovatebot.com/modules/manager/cargo/)
