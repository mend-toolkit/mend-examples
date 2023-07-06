module.exports = {
	{
		"matchManagers": [ "poetry" ],
		"registryUrls": [ process.env.PIP_REGISTRY ]
	}],
	"hostRules": [
		{
			"matchHost": process.env.PIP_REGISTRY,
			"username": process.env.PIP_USER,
			"password": process.env.PIP_PASS
		}
	]
}
