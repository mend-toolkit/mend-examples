module.exports = {
  packageRules: [
    {
      // Main Maven registry for sbt dependencies
      matchManagers: ["sbt"],
      matchDatasources: ["maven"],
      registryUrls: ["https://<artifactory>.jfrog.io/artifactory/libs-release"]
    },
    {
      // SBT plugins 
      matchManagers: ["sbt"],
      matchDatasources: ["maven"],
      registryUrls: ["https://<artifactory>.jfrog.io/artifactory/sbt-plugins"]
    },
  ],
  hostRules: [
    {
      hostType: "maven",
      matchHost: "<artifactory>.jfrog.io",
      username: process.env.SBT_USER || "",
      password: process.env.SBT_PASS || ""
    }
  ]
};
