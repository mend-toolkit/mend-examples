module.exports = {
  // Auth for your Artifactory
  hostRules: [
    {
      hostType: "maven",
      matchHost: process.env.RENOVATE_HOST,     // e.g., rivernetm.jfrog.io
      username: process.env.RENOVATE_USER,
      password: process.env.RENOVATE_PASS
    },
    {
      hostType: "ivy",
      matchHost: process.env.RENOVATE_HOST,
      username: process.env.RENOVATE_USER,
      password: process.env.RENOVATE_PASS
    }
  ],

  // Force managers to use your virtual repos (not public)
  packageRules: [
    {
      matchManagers: ["maven", "gradle"],
      registryUrls: [process.env.RENOVATE_MAVEN_REGISTRY] // e.g. https://<host>/artifactory/libs-release
    },
    {
      matchManagers: ["sbt"],
      registryUrls: [
        process.env.RENOVATE_MAVEN_REGISTRY, // many sbt deps are on Maven
        process.env.RENOVATE_IVY_REGISTRY    // sbt plugin releases (Ivy)
      ]
    }
  ],

  // (Optional) keep PRs manageable
  prConcurrentLimit: 5,
  prHourlyLimit: 3
};
