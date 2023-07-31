import requests
import json
import os
import sys

# Purpose: Get all of the users that are inside of a global organization
# Requirements:
#   Environment Variables: 
#       MEND_URL
#       WS_APIKEY
#       MEND_USER_KEY
#       MEND_EMAIL
#       MEND_GLOBAL_ORG_TOKEN

REQUEST_HEADERS = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
}




def run_api_1_4_request(url: str, request: str, userKey: str, extra_request_args: dict = {}) -> dict:
    request_object = {
        "requestType": request,
        "userKey": userKey
    }

    for key in extra_request_args:
        request_object[key] = extra_request_args[key]

    payload = json.dumps(request_object);

    if "/api/v1.4" not in url:
        url = f"{url}/api/v1.4"

    response = requests.post(url, headers=REQUEST_HEADERS, data=payload)
    response_object = response.json()

    return response_object




def get_all_organizations(base_url: str, user_key: str, global_org_token: str) -> list:
    extra_args = { "globalOrgToken": global_org_token }
    
    response = run_api_1_4_request(base_url, "getAllOrganizations", user_key, extra_request_args=extra_args)

    if "organizations" in response:
        return response['organizations']
    else:
        print(f"Request Failed: {json.dumps(response, indent=4)}")
        sys.exit(-1)




def get_organization_users(base_url: str, user_key: str, org_token: str) -> list:
    extra_args = { "orgToken": org_token }

    response = run_api_1_4_request(base_url, "getAllUsers", user_key, extra_args)
    if 'users' in response:
        return response['users']
    else:
        print(f"Request Failed: {json.dumps(response, indent=4)}")
        sys.exit(-1)




def main():
    mend_email = os.getenv('MEND_EMAIL')                        # Your Mend User's Email
    mend_url = os.getenv('MEND_URL')                            # URL of your Mend environment
    mend_apikey = os.getenv('WS_APIKEY')                      # Your Mend Organization Token
    mend_userkey = os.getenv('MEND_USER_KEY')                    # Your Mend Userkey
    mend_global_org_token = os.getenv('MEND_GLOBAL_ORG_TOKEN')  # Your Mend Global Organization Token

    print("Getting all organizations under global organization")
    all_orgs = get_all_organizations(mend_url, mend_userkey, mend_global_org_token) # Get all organizations connected with "MEND_GLOBAL_ORG_TOKEN"
    user_list = set()

    print("Getting each user associated with each organization")
    for org in all_orgs:
        response = get_organization_users(mend_url, mend_userkey, org['orgToken'])

        for user in response:
            user_list.add(user['email'])

    print("List of Users: ")
    print(user_list)




if __name__ == "__main__":
    main()
