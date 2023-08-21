module.exports = {
	"packageRules": [{
		"matchManagers": ["npm"],
		"registryUrls": [ process.env.NPM_REGISTRY ]
	}],
	"hostRules": [
		{
			"hostType": "npm",
			"matchHost": process.env.NPM_REGISTRY,
			"username": process.env.NPM_EMAIL,
			"password": process.env.NPM_PASS
		}
	]
}
