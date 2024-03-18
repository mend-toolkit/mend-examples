module.exports = {
  "packageRules": [{
    "matchManagers": [ "nuget" ],
    "registryUrls":  [ process.env.NUGET_REGISTRY ]
  }],
  "hostRules": [
    {
      "hostType": "nuget",
      "matchHost": process.env.NUGET_REGISTRY,
      "userName": process.env.NUGET_USER,
      "password": process.env.NUGET_PASS
    }
  ]
}
