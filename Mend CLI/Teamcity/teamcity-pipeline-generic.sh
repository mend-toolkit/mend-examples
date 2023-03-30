# # Define the parameters:
# Go to the build settings and click on "Parameters".
# Define the following variables:
# SCA
# env.MEND_EMAIL="YOUR EMAIL"
# env.MEND_USER_KEY="YOUR SCA USERKEY"
# env.MEND_URL="https://saas.mend.io"
# SAST
# env.MEND_SAST_SERVER_URL="https://saas.mend.io/sast"
# env.MEND_SAST_API_TOKEN="YOUR SAST API KEY"
# env.MEND_SAST_ORGANIZATION="YOUR SAST ORG"

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
echo "Mend Container Scan"
./mend image ubuntu:22.10
