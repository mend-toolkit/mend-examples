module.exports = {
	"packageRules": [{
		"matchManagers": ["bundler", "puppet", "ruby-version"],
		"registryUrls": ["process.env.RUBY_REGISTRY"]
	}],
	"hostRules": [{
		"hostType": "rubygems",
		"matchHost": process.env.RUBY_REGISTRY,
		"username": process.env.RUBY_USER,
		"password": process.env.RUBY_PASS
	}]
}
