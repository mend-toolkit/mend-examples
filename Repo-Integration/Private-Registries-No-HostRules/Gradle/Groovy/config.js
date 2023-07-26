module.exports = {
	"packageRules": [{
		"matchManagers": [ "gradle", "gradle-wrapper" ],
		"registryUrls": [ process.env.MAVEN_REGISTRY, process.env.GRADLE_PLUGIN_REGISTRY ]
	}],
	"hostRules" : [
		{
			"hostType": "maven",
			"matchHost": process.env.MVN_BASE_URL,
			"username": process.env.MVN_USER,
			"password": process.env.MVN_PASS
		},
		{
			"hostType": "maven",
			"matchHost": process.env.GRADLE_PLUGIN_REGISTRY,
			"username": process.env.GRADLE_PLUGIN_USER,
			"password": process.env.GRADLE_PLUGIN_PASS
		}
	]
}
