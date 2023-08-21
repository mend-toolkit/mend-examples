module.exports = {
	"packageRules": [{
		"matchManagers": [ "gomod" ],
		"registryUrls": [ process.env.GO_REGISTRY ]
	}],
	"hostRules": [
		{
			"matchHost": process.env.GO_REGISTRY,
			"username": process.env.GO_USER,
			"password": process.env.GO_PASS
		}
	]
}
