# ******** Mend Unified CLI Template for Atlassian Bamboo ********
#
# You may wish to alter this file to override the build tool and Mend scanning technologies.
#
# For more configuration options, please check the technical documentation portal:
# 📚 https://docs.mend.io/bundle/integrations/page/scan_with_the_mend_cli.html
#
# ******** Description ********
# mend dep will automatically use package managers and file system scanning to detect open source components.
# mend code will automatically detect languages and frameworks used in your projects to scan for code weaknesses.

# If you are NOT using a service user, and have multiple organizations, don't forget to scall the scope -s parameter to set the organization

# Variables are taken from the job Variables List
# For Example:
# MEND_EMAIL: ${MEND_SCA_EMAIL}
# MEND_USER_KEY: ${MEND_SCA_USERKEY}
# MEND_URL: https://saas.mend.io

# The mend dep scan should be called AFTER a package manager build step such as "mvn clean install -DskipTests=true" or "npm install --only=prod"

# Create a Script build step and paste the following:

### Authentication Variables ###
export MEND_EMAIL=${bamboo_MEND_SCA_EMAIL}
export MEND_USER_KEY=${bamboo_MEND_SCA_USERKEY}
export MEND_URL=${bamboo_MEND_URL}

### Download the Mend Unified CLI ###
echo "Download Mend CLI"
curl https://downloads.mend.io/cli/linux_amd64/mend -o /usr/local/bin/mend && chmod +x /usr/local/bin/mend
### Run a Mend Software Composition Analysis Scan
echo "Run Mend dependencies (SCA) Scan"
mend dep -u
### Run a Mend Static Application Security Analysis Scan
echo "Run Mend code (SAST) scan"
mend code
