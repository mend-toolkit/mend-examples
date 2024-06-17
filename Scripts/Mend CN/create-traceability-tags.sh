#!/bin/bash
#
# ******** Mend Script to add Traceability labels to Dockerfiles that are to be scanned ********
#
# Users should edit this file to change any behavior with the labels that is needed.
#
# ******** Description ********
# This script should be run at the root of a repository to add labels to Dockerfiles required for
# traceability in Mend Container Image scanning. This script can be added into any pipeline 
# to automatically add this information before building a container and running a scan.
#
# Requirements:
# sed

# Function to check for and add labels
check_and_add_labels() {
  local dockerfile_path="$1"
  echo $dockerfile_path

  grep -Eq 'LABEL io\.mend\.image\.dockerfile\.path=.*' "$dockerfile_path"
  mend_label=$?

  if [[ $mend_label -eq 0 ]]; then
    echo "Mend Label already exists in $dockerfile_path"
  else
    source_dir=${dockerfile_path:2}
    sed -i  "1i LABEL io.mend.image.dockerfile.path=$source_dir" "$dockerfile_path"
  fi

  grep -Eq 'LABEL org\.opencontainers\.image\.source=.*' "$dockerfile_path"
  oci_label=$?

  if [[ $oci_label -eq 0 ]]; then
    echo "OCI Label already exist in $dockerfile_path"
  else
    source_url=$(git config --get remote.origin.url 2>/dev/null)
    sed -i "1i LABEL org.opencontainers.image.source=$source_url" "$dockerfile_path"
  fi

  echo "Labels added to $dockerfile_path"
}

# Find all Dockerfiles
find . -name Dockerfile -type f -print | while read -r dockerfile_path; do
  check_and_add_labels "$dockerfile_path"
done

echo "Finished processing Dockerfiles"
