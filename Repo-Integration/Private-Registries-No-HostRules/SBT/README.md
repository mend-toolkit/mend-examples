# How the Files Work & How to Use Them

---

## What each file does

### 1) `repositories`
**Purpose:** Defines the ONLY repositories SBT is allowed to use inside the scanner container.  
**Effect:** Combined with `-Dsbt.override.build.repos=true`, project-level resolvers are ignored.

- Mapped to: `/home/wss-scanner/.sbt/repositories`
- Contains:
  - `private-releases`: private Maven-style repo (e.g., libs-release)
  - `private-snapshots`: private Maven-style repo (e.g., libs-snapshot)
  - `private-sbt-plugins`: private proxy for sbt-plugin-releases (Ivy pattern)
- If you enabled `extra_hosts` in `docker-compose.yaml`, public hosts (Maven Central, repo.scala-sbt.org, etc.) are blocked.

### 2) `credentials.sbt`
**Purpose:** Provides authentication to your private registry for all SBT operations.  
**How:** Reads environment variables (e.g., `SBT_USER`, `SBT_PASS`, `SBT_REGISTRY_HOST`, `SBT_REALM`) and registers global `Credentials(...)`.

- Mapped to: `/home/wss-scanner/.sbt/1.0/credentials.sbt`
- No secrets are stored in the file; values come from container environment variables.

### 3) `config.js`
**Purpose:** Configures Remediate/Renovate to resolve SBT dependencies through your private registry and authenticate against the same host.

- Mapped to: `/usr/src/app/config.js` (in the remediate container)
- Key settings:
  - `packageRules` with `matchManagers: ["sbt"]` and your `registryUrls`
  - `hostRules` with `hostType: "maven"` and `matchHost = <your-domain>` (domain only, no path)

### 4) `docker-compose.yaml`
**Purpose:** Wires the system together. Passes environment variables, mounts files, and (optionally) blocks public registries.

- Sets `SBT_OPTS=-Dsbt.override.build.repos=true` for the scanner
- Mounts:
  - `repositories` and `credentials.sbt` into the **scanner** container
  - `config.js` into the **remediate** container
- Optional: `extra_hosts` to block public registries

### 4) `.env`
**Purpose:** Holds secrets and URLs (e.g., `SBT_USER`, `SBT_PASS`, `SBT_RELEASES`, etc.).  

