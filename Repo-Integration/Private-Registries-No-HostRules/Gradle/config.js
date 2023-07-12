module.exports = {
  "packageRules": [{
    "matchManagers": [ "gradle", "gradle-wrapper" ]
    "registryUrls": [ process.env.GRADLE_REGISTRY ]
  }],
  "hostRules": [
    {
      "hostType": "maven",
      "matchHost": process.env.GRADLE_REGISTRY,
      "username": process.env.GRADLE_USER,
      "password": process.env.GRADLE_PASS
    }]
}
