#!/bin/bash

# ******** Mend script to add organization user role to a group  ********
# 
# Users should edit this file to change the behavior of the script as needed.

# Prerequisites:
# apt install jq curl
# MEND_EMAIL - Should be the email for the userKey used below
# MEND_USER_KEY
# MEND_URL
# MEND_ORG_UUID - optional for selecting a different organization

group_name=$1
group_role=$2



function login() {
    MEND_API_URL="$(echo "${MEND_URL}" | sed -E 's/(saas|app)(.*)/api-\1\2\/api\/v2.0/g')"

    if [ -z "${MEND_EMAIL}" ]; then
      echo "MEND_EMAIL is not set. Please set it before proceeding."
      exit 1
    fi
    
    if [ -z "${MEND_USER_KEY}" ]; then
      echo "MEND_USER_KEY is not set. Please set it before proceeding."
      exit 1
    fi

    if [ -z "${MEND_URL}" ]; then
      echo "MEND_URL is not set. Please set it before proceeding."
      exit 1
    fi

    if [ -z "$MEND_ORG_UUID" ]; then
        echo "MEND_ORG_UUID environment variable was not provided."
        echo -e "The Login API will default to the last organization this user accessed in the MEND UI.\n"
        LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\" }"
    else
        echo -e "Logging in with provided API key.\n"
        LOGIN_BODY="{\"email\": \"$MEND_EMAIL\", \"userKey\": \"$MEND_USER_KEY\", \"orgToken\": \"$MEND_ORG_UUID\"}"
    fi

    # Log into API 2.0 and get the JWT Token, Organization UUID, and Organization Name
    LOGIN_RESPONSE=$(curl -s -X POST --location "$MEND_API_URL/login" --header 'Content-Type: application/json' --data-raw "${LOGIN_BODY}")

    JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.retVal.jwtToken')
    MEND_ORG_UUID=$(echo "$LOGIN_RESPONSE" | jq -r '.retVal.orgUuid')
    MEND_ORG_NAME=$(echo "$LOGIN_RESPONSE" | jq -r '.retVal.orgName')
}

function find_group() {
    GROUPS_RESPONSE=$(curl -s --location "$MEND_API_URL/orgs/$MEND_ORG_UUID/groups" --header "Content-Type: application/json" --header "Authorization: Bearer $JWT_TOKEN")
    GROUPS_ERROR=$(echo "$GROUPS_RESPONSE" | jq '.retVal.errorMessage')
    if [ -z "$GROUPS_ERROR" ]; then
        list_groups
    else
        echo "Error getting list of organization groups - $GROUPS_ERROR"
        exit 1
    fi    
    
}

function list_groups(){
    if [ -z "$group_name" ]; then
        echo "Please add a group name from the list when calling the script."
        echo "Example:  ./group-permissions.sh mygroupname"
        echo "$GROUPS_RESPONSE" | jq -r '.retVal[] | {name: .name, uuid: .uuid}'
        exit 1
    else
        set_permissions
    fi
}

function set_permissions() {
    GROUP_UUID=$(echo "$GROUPS_RESPONSE" | jq --arg name_to_find $group_name -r '.retVal[] | select(.name == $name_to_find) .uuid')
    if [ -z "$group_role" ]; then
        echo "group_role not set, USER role will be used by default, set a desired role other than USER as the 2nd variable"
        echo "https://docs.mend.io/bundle/mend-api-2-0/page/index.html#tag/User-Management-Groups/operation/addGroupRoles"
        group_role="USER"
        
    fi

    echo "Adding organization level $group_role permissions to group $group_name with uuid of $GROUP_UUID"
    ADDROLE_BODY="{\"contextType\": \"orgs\", \"contextToken\": \"$MEND_ORG_UUID\", \"role\": \"$group_role\"}"
    ADDROLE_RESPONSE=$(curl -s --location "$MEND_API_URL/orgs/$MEND_ORG_UUID/groups/$GROUP_UUID/roles" --header "Content-Type: application/json" --header "Authorization: Bearer $JWT_TOKEN" -d "${ADDROLE_BODY}")
    echo $ADDROLE_RESPONSE | jq .
    
}


login

find_group
