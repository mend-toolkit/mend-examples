module.exports = {
	"packageRules": [{
		"matchManagers": ["cargo"],
		"registryUrls": [process.env.CARGO_REGISTRY]
	}],
	"hostRules": [{
		"hostType": "cargo",
		"matchHost": process.env.CARGO_REGISTRY_HOST,
		"username": process.env.CARGO_USER,
		"password": process.env.CARGO_PASS
	}]
};
