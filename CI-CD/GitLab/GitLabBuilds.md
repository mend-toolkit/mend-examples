You can utilize the yaml files in this folder as templates and [include](https://docs.gitlab.com/ee/ci/yaml/index.html#include) them in your .gitlab-ci.yml pipelines.  This can be done locally or by pointing them to a remote location.

Please bear in mind that we reserve to right to change the template files at any time, and recommend to self host the files for informed change management.  
### Local
Modify your .gitlab-ci.yml file with the following and add the appropriate template file to your local repo
```yaml
## Change default image to a relevant image for your build, it must include JDK 8/11/17 for the unified agent to scan ##
default:
  image: timbru31/java-node:latest

### use the below setting to include the template in the local repository https://docs.gitlab.com/ee/ci/yaml/index.html#includelocal ###
include:
  - local: 'gitlab-mend-ua-scan-template.yml'
```

### Remote
Modify your .gitlab-ci.yml file with the following.
```yaml
## Change default image to a relevant image for your build, it must include JDK 8/11/17 for the unified agent to scan ##
default:
  image: timbru31/java-node:latest

### use the below setting to include the template in the local repository https://docs.gitlab.com/ee/ci/yaml/index.html#includeremote ###
include:
  - remote: 'https://raw.githubusercontent.com/mend-toolkit/mend-examples/main/CI-CD/GitLab/Unified%20/Agent/gitlab-mend-ua-scan-template.yml'
```