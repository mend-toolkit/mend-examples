#!/bin/bash

# ******** Mend Unified CLI Template for Bash ********
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

# Download the Mend CLI and give execute permissions
echo "Downloading Mend CLI"
curl https://downloads.mend.io/cli/linux_amd64/mend -o /usr/local/bin/mend && chmod +x /usr/local/bin/mend

# Add environment variables for authentication
export MEND_EMAIL=your-email
export MEND_USER_KEY=your-mend-user-key
export MEND_URL="https://saas.mend.io"

# Add your package manager build (see Maven and NPM examples below)
##  mvn clean install
##  npm install --only=prod

# The mend dep scan should be called AFTER a package manager build step such as "mvn clean install -DskipTests=true" or "npm install --only=prod"
# Run a Mend Software Composition Analysis Scan
echo "Run Mend dependencies (SCA) scan"
mend dep -u

# Run a Mend Static Application Security Analysis Scan
echo "Run Mend code (SAST) scan"
mend code

# Build your image (basic docker example below)
export IMAGENAME=mydockerimage
export IMAGETAG=1.0
docker build . -t $IMAGENAME:$IMAGETAG 

# Run a Mend Container Image Scan
echo "Run a Mend image scan"
mend image $IMAGENAME:$IMAGETAG