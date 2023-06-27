module.exports = {
	"packageRules": [{
		"matchManagers": ["maven"],
		"registryUrls": ["https://<artifactory_instance>.jfrog.io/artifactory/libs-release", "https://<artifactory_instance>.jfrog.io/artifactory/libs-snapshot"]
	}],
	"hostRules": [
		{
			"hostType": "maven",
			"matchHost": "https://<artifactory_instance>.jfrog.io/artifactory",
			"username": "<artifactory_username>",
			"password": "<artifactory_password_not_encrypted>"
		}
	]
}
