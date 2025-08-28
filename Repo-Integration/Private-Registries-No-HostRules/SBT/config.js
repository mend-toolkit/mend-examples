module.exports = {
  packageRules: [
    {
      matchManagers: ["sbt"],
      // Prefer your private repos when Renovate resolves dependencies
      registryUrls: [
        process.env.SBT_RELEASES,
        process.env.SBT_SNAPSHOTS,
        process.env.SBT_PLUGIN_RELEASES
      ]
    }
  ],
  hostRules: [
    {
      hostType: "maven",
      matchHost: process.env.SBT_REGISTRY_HOST, // e.g. "<artifactory_instance>.jfrog.io"
      username: process.env.SBT_USER,
      password: process.env.SBT_PASS
    }
  ]
}
