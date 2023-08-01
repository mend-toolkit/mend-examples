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




def check_api_error(response: dict) -> bool:
    if "errorCode" in response:
        print(f"Error in request: \n{json.dumps(response, indent=4)}")
        sys.exit(-1)

    return True




def get_result_from_api_response(response: dict, object_to_get: str) -> list:
    return_object = []
    if object_to_get in response:
        return_object = response[object_to_get]

    return return_object



def send_api_1_4_request(url: str, request: dict) -> dict:
    payload = json.dumps(request);

    if "/api" not in url:
        url = f"{url}/api/v1.4"

    response = requests.post(url, headers=REQUEST_HEADERS, data=payload)
    response_object = response.json()

    return response_object




def create_get_all_organizations_request(user_key: str, global_org_token: str) -> dict:
    request_dict = { 
        "requestType": "getAllOrganizations",
        "userKey": user_key,
        "globalOrgToken": global_org_token
    }

    return request_dict
    



def create_get_organization_users_request(user_key: str, org_token: str) -> dict:
    request_dict = {
        "requestType": "getAllUsers",
        "userKey": user_key,
        "orgToken": org_token
    }

    return request_dict




def main():
    mend_url = os.getenv('MEND_URL')                            # URL of your Mend environment
    mend_userkey = os.getenv('MEND_USER_KEY')                    # Your Mend Userkey
    mend_global_org_token = os.getenv('MEND_GLOBAL_ORG_TOKEN')  # Your Mend Global Organization Token

    print("Getting all organizations under global organization")
    all_org_request = create_get_all_organizations_request(mend_userkey, mend_global_org_token)
    all_orgs_response_object = send_api_1_4_request(mend_url, all_org_request) # Get all organizations connected with "MEND_GLOBAL_ORG_TOKEN"
    check_api_error(all_orgs_response_object)
    list_of_orgs = get_result_from_api_response(all_orgs_response_object, "organizations")

    user_list = set()

    print("Getting each user associated with each organization")
    for org in list_of_orgs:
        all_users_request = create_get_organization_users_request(mend_userkey, org['orgToken'])
        all_users_response_object = send_api_1_4_request(mend_url, all_users_request)
        check_api_error(all_users_response_object)
        list_of_users = get_result_from_api_response(all_users_response_object, "users")

        for user in list_of_users:
            user_list.add(user['email'])

    print("List of Users: ")
    print('\n\t'.join(user_list))




if __name__ == "__main__":
    main()
