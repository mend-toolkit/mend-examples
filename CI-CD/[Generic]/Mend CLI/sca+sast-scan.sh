#!/usr/bin/env bash

# Download the Mend CLI and give execute permissions
echo "Downloading Mend CLI"
curl -LJO https://downloads.mend.io/production/unified/latest/linux_amd64/mend && chmod +x mend

# Add environment variables for SCA and Container scanning
export MEND_EMAIL=your-email
export MEND_USER_KEY=your-mend-sca-userkey
export MEND_URL="https://saas.mend.io"
# Add environment variables for SAST scanning
export MEND_SAST_SERVER_URL="https://saas.mend.io/sast"
export MEND_SAST_API_TOKEN=your-sast-api-token
export MEND_SAST_ORGANIZATION=your-sast-organization-id

# Add your package manager build (see Maven and NPM examples below)
##  mvn clean install
##  npm install --only=prod

# The Mend SCA CLI scan should be called AFTER a package manager build step such as "mvn clean install -DskipTests=true" or "npm install --only=prod"
# Run a Mend Software Composition Analysis Scan
echo "Start Mend SCA Scan"
./mend sca -u

# Run a Mend Static Application Security Analysis Scan
echo "Start Mend SAST Scan"
./mend sast