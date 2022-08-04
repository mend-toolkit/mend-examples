# Introduction
Planning and implementing source code branching is a complex topic.  When done properly, it’s easy to manage, otherwise it can be a nightmare.  The same applies to how you manage your Mend organizations.  With proper planning and implementation, finding results and knowing what you have in production can be easy.

## Multi-Organizational Pipeline or (multi-org)

### Pipeline Integration Notes
Two options to store the “key” information

* Global Properties
* Local Pipeline script in the “environment” section

** The examples shown use the global properties.  Make sure you create the following keys and populate their values:
* APIKEY (Integration -> Organization APIKEY from your production organization)
* DEV_APIKEY (Integration -> Organization APIKEY from your development organization)
* USERKEY (User Profile -> User Keys section from your production organization)
* DEV_USERKEY (User Profile -> User Keys section from your development organization)
* WSURL (https://&lt;WhiteSource URL&gt;/agent)
