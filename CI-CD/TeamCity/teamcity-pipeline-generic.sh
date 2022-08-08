# # Define the parameters:
# Go to the build settings and click on "Parameters".
# Define the following variables:
# env.WS_APIKEY={Your apiKey here}
# env.WS_PRODUCTNAME=TC_%system.teamcity.projectName%
# env.WS_PROJECTNAME=%system.teamcity.buildType.id%
# env.WS_WSS_URL=https://saas.whitesourcesoftware.com

# Create the following build step:
# Runner type: Commandline
# Step Name: Mend SCA Scan
# Run: Custom Script

echo "Downloading Mend"
if ! [ -f ./wss-unified-agent.jar ]; then
    curl -fSL -R -JO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
    if [[ "${'$'}(curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256)" != "${'$'}(sha256sum wss-unified-agent.jar)" ]]; then
       echo "Integrity Check Failed"
    fi
fi
echo "Execute Mend"
java -jar wss-unified-agent.jar