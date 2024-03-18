module.exports = {
	"packageRules": [{
		"matchManagers": ["maven", "maven-wrapper"],
		"registryUrls": [ process.env.MVN_RELEASE, process.env.MVN_SNAPSHOT ]
	}],
	"hostRules": [
		{
			"hostType": "maven",
			"matchHost": process.env.MVN_BASE_URL,
			"username": process.env.MVN_USER,
			"password": process.env.MVN_PASS
		}
	]
}
