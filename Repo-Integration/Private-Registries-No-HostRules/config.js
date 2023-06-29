module.exports = {
	"packageRules": [{
		"matchManagers": ["maven"],
		"registryUrls": [ process.env.MVN_RELEASE, process.env.MVN_SNAPSHOT ]
	},
	{
		"matchManagers": ["npm"],
		"registryUrls": [ process.env.NPM_REGISTRY ]
	},
	{
		"matchManagers": [ "pip-compile", "pip_requirements", "pip_setup", "pipenv", "poetry", "setup-cfg" ],
		"registryUrls": [ process.env.PIP_REGISTRY ]
	}],
	"hostRules": [
		{
			"hostType": "maven",
			"matchHost": process.env.MVN_BASE_URL,
			"username": process.env.MVN_USER,
			"password": process.env.MVN_PASS
		},
		{
			"hostType": "npm",
			"matchHost": process.env.NPM_REGISTRY,
			"username": process.env.NPM_EMAIL,
			"password": process.env.NPM_PASS
		},
		{
			"matchHost": process.env.PIP_REGISTRY,
			"username": process.env.PIP_USER,
			"password": process.env.PIP_PASS
		}
	]
}
