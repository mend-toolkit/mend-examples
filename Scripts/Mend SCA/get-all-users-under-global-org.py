import requests
import json
import os
import sys

REQUEST_HEADERS = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
}

# Purpose: Get all of the users that are inside of a global organization
# Requirements:
#   Environment Variables: 
#       WS_URL
#       WS_APIKEY
#       WS_USERKEY
#       WS_EMAIL
#       WS_GLOBAL_ORG_TOKEN

def login_rest_api(url: str, userkey: str, orgToken: str, email: str) -> str:
    payload = json.dumps({
        "email": email,
        "orgToken": orgToken,
        "userKey": userkey
    })

    if "https://api-" not in url:
        url = f"https://api-{url[8:]}"

    if "/api/v2.0/login" not in url:
        url = f"{url}/api/v2.0/login"


    response = requests.post(url, headers=REQUEST_HEADERS, data=payload)
    if response.content:
        return response.json()['retVal']['jwtToken']
    else:
        response = requests.post(url, headers=REQUEST_HEADERS, data=payload)
        return response.json()['retVal']['jwtToken']





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




def run_rest_request_get(base_url: str, extra_args: str, jwt_token: str) -> dict:
    req_headers = REQUEST_HEADERS.copy()
    req_headers['Authorization'] = f"Bearer {jwt_token}"
    del req_headers['Content-Type']

    payload={}

    if "/api/v2.0" not in base_url:
        base_url = f"{base_url}/api/v2.0"

    if "/" in extra_args[0]:
        extra_args = extra_args[1:]


    full_url = f"{base_url}/{extra_args}"

    response = requests.get(full_url, headers=req_headers, data=payload)
    response_object = response.json()

    return response_object




def get_all_organizations(base_url: str, user_key: str, global_org_token: str) -> list:
    extra_args = { "globalOrgToken": global_org_token }
    
    response = run_api_1_4_request(base_url, "getAllOrganizations", user_key, extra_request_args=extra_args)

    if "organizations" in response:
        return response['organizations']
    else:
        print(f"Request Failed: {json.dumps(response)}")
        sys.exit(-1)




def get_organization_users(base_url: str, org_token: str, jwt_token: str) -> dict:
    extra_args = f"orgs/{org_token}/users"

    response = run_rest_request_get(base_url, extra_args, jwt_token)
    return response['retVal']




def switch_organization_context(base_url: str, current_org_token: str, new_org_token: str, jwt_token: str) -> str:
    extra_args = f"orgs/{current_org_token}/changeOrganization/{new_org_token}"

    response = run_rest_request_get(base_url, extra_args, jwt_token)
    return response['retVal']['jwtToken']





def main():
    ws_email = os.getenv('WS_EMAIL')                           # Your Mend User's Email
    ws_url = os.getenv('WS_URL')                            # URL of your Mend environment
    ws_apikey = os.getenv('WS_APIKEY')                      # Your Mend Organization Token
    ws_userkey = os.getenv('WS_USERKEY')                    # Your Mend Userkey
    ws_global_org_token = os.getenv('WS_GLOBAL_ORG_TOKEN')  # Your Mend Global Organization Token

    jwt_token = login_rest_api(ws_url, ws_userkey, ws_apikey, ws_email) # Get our JWT login token

    all_orgs = get_all_organizations(ws_url, ws_userkey, ws_global_org_token) # Get all organizations connected with "WS_GLOBAL_ORG_TOKEN"
    previous_org_token = ""
    user_list = set()

    for org in all_orgs:
        if previous_org_token:
            jwt_token = switch_organization_context(ws_url, previous_org_token, org['orgToken'], jwt_token)

        response = get_organization_users(ws_url, org['orgToken'], jwt_token)

        for user in response:
            user_list.add(user['email'])

        previous_org_token = org['orgToken']

    print(user_list)


if __name__ == "__main__":
    main()
