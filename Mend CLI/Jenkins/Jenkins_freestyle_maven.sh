echo "Downloading Mend CLI"
curl -LJO https://downloads.mend.io/production/unified/latest/linux_amd64/mend && chmod +x mend
echo "Execute Mend CLI"
#SCA
export MEND_EMAIL="${MEND_SCA_EMAIL}" #Taken from Jenkins Global Environment Variables
export MEND_USER_KEY="${MEND_SCA_USERKEY}" #Taken from Jenkins Global Environment Variables
export MEND_URL="https://saas.mend.io"
#SAST
export MEND_SAST_SERVER_URL="https://saas.mend.io/sast"
export MEND_SAST_API_TOKEN="${MEND_SAST_API}" #Taken from Jenkins Global Environment Variables
export MEND_SAST_ORGANIZATION="${MEND_SAST_ORGANIZATION}" #Taken from Jenkins Global Environment Variables
./mend sca -u
./mend sast