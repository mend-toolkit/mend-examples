module.exports = {
	"packageRules": [{
		"matchManagers": ["maven"],
		"registryUrls": [process.env.MVN_RELEASE, process.env.MVN_SNAPSHOT]
	},
	{
		"matchManagers": ["npm"],
		"registryUrls": [ process.env.NPM_REGISTRY ]
	}],
	"hostRules": [
		{
			"hostType": "maven",
			"matchHost": process.env.MVN_BASE_URL,
			"username": process.env.MAVEN_USER,
			"password": process.env.MAVEN_PASS
		},
		{
			"hostType": "npm",
			"matchHost": process.env.NPM_REGISTRY,
			"username": process.env.NPM_EMAIL,
			"password": process.env.NPM_PASS
		}
	]
}
