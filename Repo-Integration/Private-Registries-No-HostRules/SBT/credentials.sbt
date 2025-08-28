# Reads credentials from environment and registers them globally for SBT.

import scala.util.Properties

def need(k: String) = Properties.envOrNone(k).getOrElse(
  sys.error(s"Missing required env var: $k")
)

val realm = Properties.envOrElse("SBT_REALM", "Artifactory Realm")
val host  = Properties.envOrElse("SBT_REGISTRY_HOST", new java.net.URL(need("SBT_BASE_URL")).getHost)

credentials += Credentials(
  realm,
  host,
  need("SBT_USER"),
  need("SBT_PASS")
)
