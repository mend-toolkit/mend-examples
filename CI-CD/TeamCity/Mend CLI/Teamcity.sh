# ******** Mend Unified CLI Template for JetBrains TeamCity ********
#
# You may wish to alter this file to override the build tool and Mend scanning technologies.
#
# For more configuration options, please check the technical documentation portal:
# 📚 https://docs.mend.io/bundle/integrations/page/scan_with_the_mend_cli.html
#
# ******** Description ********
# mend dep will automatically use package managers and file system scanning to detect open source components.
# mend code will automatically detect languages and frameworks used in your projects to scan for code weaknesses.
# mend image will scan the local image:tag for open source components and secrets.

# If you are NOT using a service user, and have multiple organizations, don't forget to scall the scope -s parameter to set the organization

# # Define the parameters:
# Go to the build settings and click on "Parameters".
# Define the following variables:
### Authentication Variables ###
# env.MEND_EMAIL="YOUR EMAIL"
# env.MEND_USER_KEY="YOUR SCA USERKEY"
# env.MEND_URL="https://saas.mend.io"


# The mend dep scan should be called AFTER a package manager build step such as "mvn clean install -DskipTests=true" or "npm install --only=prod"

# Create the following build step:
# Runner type: Commandline
# Step Name: Mend Scan
# Run: Custom Script

echo "Downloading Mend CLI"
curl https://downloads.mend.io/cli/linux_amd64/mend -o /usr/local/bin/mend && chmod +x /usr/local/bin/mend
echo "Execute Mend CLI"
echo "Run Mend dependencies (SCA) scan"
mend dep -u
echo "Run Mend code (SAST) scan"
mend code
