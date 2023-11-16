module.exports = {
	"packageRules": [{
		"matchManagers": [ "pip-compile", "pip_requirements", "pip_setup", "pipenv", "setup-cfg" ],
		"registryUrls": [ process.env.PIP_REGISTRY ]
	}],
	"hostRules": [
		{
			"hostType": "pypi",
			"matchHost": process.env.PIP_REGISTRY,
			"username": process.env.PIP_USER,
			"password": process.env.PIP_PASS
		}
	]
}
