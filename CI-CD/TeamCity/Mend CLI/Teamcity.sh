# ******** Mend Unified CLI Template for JetBrains TeamCity ********
#
# You may wish to alter this file to override the build tool and the Mend scanning technologies used (SCA, SAST or Conatiner).
#
# For more configeration options, please check the technical documentation portal:
# 📚 https://docs.mend.io/bundle/cli/page/scan_with_mend_s_unified_cli.html 
#
# ******** Description ********
# Mend SCA will automatically use package managers and file system scanning to detect open source components. 
# Mend SAST will automatically detect languages and frameworks used in your projects to scan for code weaknesses.

# # Define the parameters:
# Go to the build settings and click on "Parameters".
# Define the following variables:
### SCA Environment Variables ###
# env.MEND_EMAIL="YOUR EMAIL"
# env.MEND_USER_KEY="YOUR SCA USERKEY"
# env.MEND_URL="https://saas.mend.io"
### SAST Environment Variables ###
# env.MEND_SAST_SERVER_URL="https://saas.mend.io/sast"
# env.MEND_SAST_API_TOKEN="YOUR SAST API KEY"
# env.MEND_SAST_ORGANIZATION="YOUR SAST ORG"

# The Mend SCA CLI scan should be called AFTER a package manager build step such as "mvn clean install -DskipTests=true" or "npm install --only=prod"

# Create the following build step:
# Runner type: Commandline
# Step Name: Mend Scan
# Run: Custom Script

echo "Downloading Mend CLI"
curl -LJO https://downloads.mend.io/production/unified/latest/linux_amd64/mend && chmod +x mend
echo "Execute Mend CLI"
echo "Mend SCA Scan"
./mend sca -u
echo "Mend SAST Scan"
./mend sast
