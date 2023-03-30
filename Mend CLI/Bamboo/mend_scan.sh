# Variables are taken from the job Variables List
# For Example:
# SCA:
# MEND_EMAIL: ${MEND_SCA_EMAIL}
# MEND_USER_KEY: ${MEND_SCA_USERKEY}
# MEND_URL: https://saas.mend.io
# SAST:
# MEND_SAST_SERVER_URL: https://saas.mend.io/sast
# MEND_SAST_API_TOKEN: ${MEND_SAST_API}
# MEND_SAST_ORGANIZATION: ${MEND_SAST_ORGANIZATION}
# Create a Script build step and paste the following:

# SCA
export MEND_EMAIL=${bamboo_MEND_SCA_EMAIL}
export MEND_USER_KEY=${bamboo_MEND_SCA_USERKEY}
export MEND_URL=${bamboo_MEND_URL}
# SAST
export MEND_SAST_SERVER_URL=${bamboo_MEND_SAST_SERVER_URL}
export MEND_SAST_API_TOKEN=${bamboo_MEND_SAST_ORGANIZATION}
export MEND_SAST_ORGANIZATION=${bamboo_MEND_SAST_ORGANIZATION}
echo "Download Mend CLI"
curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
curl https://downloads.mend.io/production/unified/latest/linux_amd64/mend -o /usr/local/bin/mend && chmod +x /usr/local/bin/mend
echo "Run Mend SCA Scan"
mend sca -u
echo "Run Mend SAST Scan"
mend sast