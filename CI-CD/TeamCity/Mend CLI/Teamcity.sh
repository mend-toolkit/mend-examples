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

# If you are NOT using a service user, and have multiple organizations, don't forget to set the organization in the scope parameter
# The following values should be added as environment variables with email and userKey being secrets
#    MEND_URL: the mend url that you login to - (https://saas.mend.io) for example
#    MEND_EMAIL: the user email for the mend platform account you wish to scan with
#    MEND_USER_KEY: the user key found under my profile for the user you wish to scan with

# # Define the parameters:
# Go to the build settings and click on "Parameters".
# Define the following environment variables:
### Authentication Variables ###
# env.MEND_EMAIL="YOUR EMAIL"
# env.MEND_USER_KEY="YOUR MEND USERKEY"
# env.MEND_URL="https://saas.mend.io"


# The mend dep scan should be called AFTER a package manager build step such as "mvn clean install -DskipTests=true" or "npm install --only=prod"

# Create the following build step:
# Runner type: Commandline
# Step Name: Mend Scan
# Run: Custom Script

## Many Team City runners do not have access to /usr/local/bin which the recommended download for the CLI according to the documentation, use $HOME instead
## Package managers are not always available on the PATH due to default Team City installations methods - https://youtrack.jetbrains.com/issue/TW-67369/Default-Maven-is-not-available-in-Command-Line-build-i.e.-mvn-command-not-found

echo "Downloading Mend CLI"
curl https://downloads.mend.io/cli/linux_amd64/mend -o $HOME/mend && chmod +x $HOME/mend
echo "Set installed package manager on the PATH"
### Maven example
export PATH="%teamcity.tool.maven.DEFAULT%/bin":${PATH}
mvn -version
echo "Execute Mend CLI"
echo "Run Mend dependencies scan"
$HOME/mend dep -u
echo "Run Mend code scan"
$HOME/mend code
