module.exports = {
	"packageRules": [{
		"matchManagers": [ "poetry", "pep621" ] 			// PEP621 is used for poetry core version and more
		"registryUrls": [ process.env.POETRY_REPOSITORIES_MAIN_URL ]
	}],
	"hostRules": [{
		"hostType": "pypi",
		"matchHost": process.env.POETRY_REPOSITORIES_MAIN_URL,
		"username": process.env.POETRY_HTTP_BASIC_MAIN_USERNAME,
		"password": process.env.POETRY_HTTP_BASIC_MAIN_PASSWORD
	}]
}
