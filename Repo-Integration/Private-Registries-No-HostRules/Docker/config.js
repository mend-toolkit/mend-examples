module.exports = {
  "packageRules": [
    {
      // This is an example of specifying custom versioning for a package. Each package in docker typically has its own versioning scheme.
      // So if a specific package needs to be checked for updates, then this can be added to config.js or to renovate configuration inside of the repository.
      "matchDatasources": [ "docker" ],
      "matchPackageNames": [ "repository/package" ],
      "versioning": "semver"
    }],
  "hostRules": [
    {
      "hostType": "docker",
      "matchHost": process.env.DOCKER_REGISTRY,
      "username": process.env.DOCKER_USER,
      "password": process.env.DOCKER_PASS
    }
  ]
}
