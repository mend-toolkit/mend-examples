module.exports = {
	"packageRules": [{
		"matchManagers": ["swift"],
		"registryUrls": [process.env.SPM_REGISTRY]
	}],
	"hostRules": [{
		"hostType": "swift",
		"matchHost": process.env.SPM_REGISTRY_HOST,
		"username": process.env.SPM_USER,
		"password": process.env.SPM_PASS
	}]
};
