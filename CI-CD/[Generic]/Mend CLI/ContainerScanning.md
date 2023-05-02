# Examples by CI/CD Tool
Image scanning can be run within the same pipeline as SCA and SAST, but this is not typical due to how docker images are usually built.

The current iteration of the Mend CLI container scanning is meant for [locally scanning](https://docs.mend.io/bundle/cli/page/scan_container_images_locally_using_mend_cli.html) an image after it is built or by pulling it from a registry.

There are two types of builds. 

Bash example of scanning an image after building using ```docker build```
```shell
# Mend Containers will automatically pull the container defined and scan for open source components and secrets 
#
# Download the Mend CLI and give write access
echo "Downloading Mend CLI"
curl -LJO https://downloads.mend.io/production/unified/latest/linux_amd64/mend && chmod +x mend

# Add environment variables for SCA and Container scanning
export MEND_EMAIL=your-email
export MEND_USER_KEY=your-mend-sca-userkey
export MEND_URL="https://saas.mend.io"

# Build your image (basic docker example below)
export IMAGENAME=mydockerimage
export IMAGETAG=1.0
docker build . -t $IMAGENAME:$IMAGETAG

# Run a Mend Container Image Scan
echo "Run a Mend Container Image Scan"
./mend image $IMAGENAME:$IMAGETAG
```

TODO: Bash example of scanning an image after building using ```docker compose```

TODO: Bash example of scanning an intermediary container with SCA and the built image with image scan 
