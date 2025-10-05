#!/bin/bash
# The purpose of this script is to reassign projects to a specified product, creating the product if it does not exist.

# This scripts requires the product name and project name are provided in a csv with the following format.

# ProductA,ProjectA
# ProductA,ProjectC
# ProductB,ProjectB

# A Mend user is required in order to run the script. The user needs to have Administrator level permissions in order to create the needed products. Mend recommends leveraging a service user(https://docs.mend.io/legacy-sca/latest/managing-service-users) for this script.

#
# Once this script is executed, there is no way to undo the projects that have been moved without changing the CSV or manually though the UI. It is advised to test the script on a single project before implementing at scale.


# To run this script the following environment variables need to be provided:
# 1. CSV file name - CSV_FILE
# 2. Mend User Key - USER_KEY
# 3. Organization Token/API Key - ORG_TOKEN (This can be found by going to the integrate tab within Mend)
# 4. User Email - USER_EMAIL
# 5. Mend Environment URL (without https://) - MEND_URL e.g saas.mend.io

 if [ -z $CSV_FILE ]; then
    echo "Error: Missing CSV_FILE variable."
    exit 1
  fi
   if [ -z $USER_KEY ]; then
    echo "Error: Missing USER_KEY variable."
    exit 1
  fi
   if [ -z $ORG_TOKEN ]; then
    echo "Error: Missing ORG_TOKEN variable."
    exit 1
  fi
   if [ -z $USER_EMAIL ]; then
    echo "Error: Missing USER_EMAIL variable."
    exit 1
  fi
   if [ -z $MEND_URL ]; then
    echo "Error: Missing MEND_URL variable."
    exit 1
  fi


get_jwt_token() {
  local response
  response=$(curl -s -X POST "https://api-${MEND_URL}/api/v2.0/login" \
    -H "Content-Type: application/json" \
    -d "{\"userKey\": \"${USER_KEY}\", \"orgToken\": \"${ORG_TOKEN}\", \"email\": \"${USER_EMAIL}\"}")

  
  echo "$response" | jq -r '.retVal.jwtToken'
}


JWT_TOKEN=$(get_jwt_token)
if [[ "$JWT_TOKEN" == "null" || -z "$JWT_TOKEN" ]]; then
  echo "Error: Failed to retrieve JWT token. Exiting."
  exit 1
fi

echo "Successfully retrieved JWT token."


while IFS=',' read -r productName projectName projectOwner; do
  echo "Processing product: $productName"

  #Create Product

  payload=$(cat <<EOF
{
  "productName": "$productName",
  "description": ""
}
EOF
)


  productResponse=$(curl -s -X POST "https://api-${MEND_URL}/api/v2.0/orgs/${ORG_TOKEN}/products" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${JWT_TOKEN}" \
    -d "$payload")


  productToken=$(echo "$productResponse" | jq -r '.retVal.uuid')

  if [[ "$productToken" == "null" || -z "$productToken" ]]; then
    echo "Error: Failed to create product $productName. Response: $productResponse"
    continue
  fi

  created=$(echo "$productResponse" | jq -r '.additionalData.created')
  if $created; then
    echo "Created product $productName"
  else
    echo "Product $productName already exists. Using existing product token."
  fi

  #Reassign Project
  if [[ -n "$projectName" ]]; then
    echo "Searching for project: $projectName"

    # Call Get Product Projects
    projectResponse=$(curl -s -X GET "https://api-${MEND_URL}/api/v2.0/orgs/${ORG_TOKEN}/projects" \
      -H "Authorization: Bearer ${JWT_TOKEN}")
      

    # Find the projectToken matching the projectName
    projectToken=$(echo "$projectResponse" | jq -r --arg name "$projectName" '.retVal[] | select(.name == $name) | .uuid')
    

    if [[ -z "$projectToken" ]]; then
      echo "Error: Project '$projectName' not found. Skipping reassignment."
      continue
    fi

    echo "Found project '$projectName'"
       
    
    existingProductUuid=$(echo "$projectResponse" | jq -r --arg name "$projectName" '.retVal[] | select(.name == $name) | .productUuid')

    if [[ $existingProductUuid == $productToken ]]; then
      echo "$projectName already exists in $productName. Skipping reassignment."
      continue
    fi
    
    # Reassign Project
    reassignResponse=$(curl -s -X PUT "https://api-${MEND_URL}/api/v2.0/projects/${projectToken}/reassign/${productToken}" \
      -H "Authorization: Bearer ${JWT_TOKEN}")

    if [[ "$reassignResponse" == *"error"* ]]; then
      echo "Error: Failed to reassign project '$projectName' to product '$productName'. Response: $reassignResponse"
    else
      echo "Successfully reassigned project '$projectName' to product '$productName'."
    fi
    

  fi

done < "$CSV_FILE"
