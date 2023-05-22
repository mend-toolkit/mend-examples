# ******** Mend Unified CLI Template for Atlassian Bamboo ********
#
# You may wish to alter this file to override the build tool and the Mend scanning technologies used (SCA, SAST or Conatiner).
#
# For more configeration options, please check the technical documentation portal:
# 📚 https://docs.mend.io/bundle/cli/page/scan_with_mend_s_unified_cli.html 
#
# ******** Description ********
# Mend SCA will automatically use package managers and file system scanning to detect open source components. 
# Mend SAST will automatically detect languages and frameworks used in your projects to scan for code weaknesses.

# Variables are taken from the job Variables List
# For Example:
# SCA:
# MEND_EMAIL: ${MEND_SCA_EMAIL}
# MEND_USER_KEY: ${MEND_SCA_USERKEY}
# MEND_URL: https://saas.mend.io
# SAST:
# MEND_SAST_SERVER_URL: https://saas.mend.io/sast
# MEND_SAST_API_TOKEN: ${MEND_SAST_API_TOKEN}
# MEND_SAST_ORGANIZATION: ${MEND_SAST_ORGANIZATION}

# The Mend SCA CLI scan should be called AFTER a package manager build step such as "mvn clean install -DskipTests=true" or "npm install --only=prod"

# Create a Script build step and paste the following:

### SCA Environment Variables ###
export MEND_EMAIL=${bamboo_MEND_SCA_EMAIL}
export MEND_USER_KEY=${bamboo_MEND_SCA_USERKEY}
export MEND_URL=${bamboo_MEND_URL}
### SAST Environment Variables ###
export MEND_SAST_SERVER_URL=${bamboo_MEND_SAST_SERVER_URL}
export MEND_SAST_API_TOKEN=${bamboo_MEND_SAST_API}
export MEND_SAST_ORGANIZATION=${bamboo_MEND_SAST_ORGANIZATION}
### Download the Mend Unified CLI ###
echo "Download Mend CLI"
curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
curl https://downloads.mend.io/production/unified/latest/linux_amd64/mend -o /usr/local/bin/mend && chmod +x /usr/local/bin/mend
### Run SCA scan ###
echo "Start Mend SCA Scan"
mend sca -u
### Run SAST scan ###
echo "Start Mend SAST Scan"
mend sast
