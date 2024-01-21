import requests, csv, sys, os, argparse
from datetime import datetime, timedelta

"""
******** Mend Script to get all products and their last scan date ********

Users should feel free to edit this file to make appropriate changes for desired behavior.

******** Description ********
This script retrieves the last scan time for each product in a Mend Organization and exports that for reporting purposes.

******** Usage ********
Make sure to install the appropriate dependencies before running this script and set all required environment variables. You can run the script with:
pip3 install requests
python3 get-all-users-under-global-org.py

If the new Mend Unified Platform is not in use, then the user can get the Organization Uuid for a specific organization by running the following API Request: 
📚 https://docs.mend.io/bundle/mend-api-2-0/page/index.html#tag/Access-Management-Organizations/operation/getUserDomains 

Pre-requisites:
apt-get install python3.9
pip install requests
export MEND_URL='<MEND_URL>' (e.g https://saas.mend.io)
export MEND_USER_KEY='<MEND_USER_KEY>'
"""

MEND_URL=""
MEND_ORG_UUID=""
MEND_USER_KEY=""
MEND_NUM_DAYS=0
INCLUDE_REQUEST_TOKEN=True
HEADERS={'Content-Type': 'application/json'}

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument('-k', '--orgUuid', dest='org_uuid')
    parser.add_argument('-n', '--numDays', dest='num_days')
    parser.add_argument('-i', '--includeRequestToken', dest='include_request_token', default=True)
    return parser.parse_args()

def validate_env() -> bool:
    global MEND_URL, MEND_ORG_UUID, MEND_USER_KEY, MEND_NUM_DAYS, INCLUDE_REQUEST_TOKEN 
    
    config = parse_args()
    
    try:
        MEND_URL = os.environ['MEND_URL']
        MEND_URL = f"{MEND_URL}/api/v1.4"
        MEND_USER_KEY = os.environ['MEND_USER_KEY']
        
        MEND_ORG_UUID = config.org_uuid
        if MEND_ORG_UUID == None:
            raise Exception("-k/--orgUuid")
        
        MEND_NUM_DAYS = int(config.num_days)
        if MEND_NUM_DAYS == None:
            raise Exception("-n/--numDays")
        
        INCLUDE_REQUEST_TOKEN = config.include_request_token if bool(config.include_request_token) else True
        
    except KeyError as err:
        print(f"{err.args[0]} environment variable not found. Please set this environment variable and try again.")
        return False
    except Exception as err:
        print(f"{err} flag was not set. Please set this flag and try again.")
        return False
    
    return True
        
    
def get_organization_product_vitals():
    global MEND_URL, MEND_ORG_UUID, MEND_USER_KEY, INCLUDE_REQUEST_TOKEN, HEADERS
    
    request_data = {
        "orgToken": MEND_ORG_UUID,
        "requestType": "getOrganizationProductVitals",
        "userKey": MEND_USER_KEY,
        "includeRequestToken": INCLUDE_REQUEST_TOKEN
    }

    try:
        response = requests.post(MEND_URL, json=request_data, headers=HEADERS)
        response_json = response.json()

        # Handling the response
        if response.status_code == 200:
            product_vitals = response_json["productVitals"]
            # Process product_vitals or perform other actions with the data
            return product_vitals
        else:
            print("API request failed with status code:", response.status_code)
            print("Response JSON:", response_json)
            return None

    except requests.exceptions.RequestException as e:
        print("Error sending API request:", e)
        return None


def main():
    global MEND_NUM_DAYS
    
    if not validate_env():
        sys.exit(1)

    product_vitals = get_organization_product_vitals()

    if product_vitals:
        current_date = str(datetime.now())
        curr_date_obj = datetime.strptime(current_date[:-16], "%Y-%m-%d")
        seven_days_ago = curr_date_obj - timedelta(days=MEND_NUM_DAYS)

        csv_filename = "request-history.csv"
        no_data = True
        with open(csv_filename, mode="w", newline="", encoding="utf-8") as csvfile:
            fieldnames = ["Product Name", "Last Scan Time"]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()

            for product in product_vitals:
                last_updated_date_str = product.get("lastUpdatedDate")
                if last_updated_date_str:
                    name = product.get("name")
                    last_updated_date_str = product.get("lastUpdatedDate")
                    date_obj = datetime.strptime(last_updated_date_str[:-15], "%Y-%m-%d")
                    formatted_date_str = date_obj.strftime("%Y-%m-%d")
                    formatted_date = datetime.strptime(formatted_date_str, "%Y-%m-%d")
                    if formatted_date >= seven_days_ago:
                        no_data = False
                        writer.writerow({"Product Name": name, "Last Scan Time": date_obj})
            csvfile.close()

            if no_data:
                print("[!] No Products within the provided timeframe of {} day(s)".format(MEND_NUM_DAYS))
            else:
                print("[+] Created CSV: {} with products from the last {} day(s)".format(csv_filename, MEND_NUM_DAYS))
            
            
if __name__ == "__main__": 
    main()