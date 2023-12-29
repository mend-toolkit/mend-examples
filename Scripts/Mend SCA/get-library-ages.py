import requests
import os
import sys
import json
import re
from datetime import datetime, timezone
from dateutil.parser import parse


"""
******** Mend Script to Report on Libraries Released After a Period of Time ********

Users can feel free to edit this file to make appropriate changes for desired behavior.

For more information on the Mend CLI and how to generate a file for this script, please check our documentation page:
📚 https://docs.mend.io/bundle/integrations/page/configure_the_mend_cli_for_sca.html

******** Description ********
This script takes an organization and loops through each product, getting each direct dependency and then getting the age of the library.
If the age > MAX_LIBRARY_AGE then it will add it to a json array which is then written to a file. This can be used or re-formatted for reporting purposes appropriately.

The execution process looks like:
1. Log into the API and get all products under the desired organization.
2. Get all direct dependencies in the product and then get the date that version was released.
3. If the age of that library > MAX_LIBRARY_AGE then add it to the output
4. Write the JSON array to a file

******** Usage ********
Make sure to install the appropriate dependencies before running this script and set all required environment variables. Afterwards, you can run the script with:
python3 get-library-ages.py

Optional Arguments: the only optional argument for this script is WS_API_KEY. If this is not specified then the Mend API will log in to the last organization accessed from the Mend Platform.

Pre-requisites:
apt-get install python39
pip install requests python-dateutil
export MEND_USER_KEY='<MEND_USER_KEY>'
export MEND_URL='<MEND_URL>
export MEND_EMAIL='<MEND_EMAIL>'
export OUTPUT_FILE='<OUTPUT_FILE>.json'
export MAX_LIBRARY_AGE='<MAX_AGE_IN_DAYS>'
export WS_API_KEY='<WS_API_KEY>' <-- Optional
"""

MEND_USER_KEY = ""
MEND_EMAIL = ""
MEND_URL = ""
MEND_API_KEY = ""
OUTPUT_FILE = ""
MAX_LIBRARY_AGE = 0
HEADERS = {'Content-Type': 'application/json'}
SESSION = requests.Session()


def validate_env() -> bool:
    global MEND_USER_KEY
    global MEND_URL
    global MEND_EMAIL
    global OUTPUT_FILE
    global MEND_API_KEY
    global MAX_LIBRARY_AGE
    
    error_message = "environment variable not found. Please set this environment variable."
    
    if os.environ['MEND_USER_KEY'] == '':
        print(f"MEND_USER_KEY {error_message}")
        return False
    MEND_USER_KEY = os.environ['MEND_USER_KEY']
    
    if os.environ['MEND_URL'] == '':
        print("MEND_URL {error_message}")
        return False
    MEND_URL = os.environ['MEND_URL']
    MEND_URL = re.sub(r'^(.*?)(saas|app)(.*)', r'\1api-\2\3/api/v2.0', MEND_URL, 1)
    
    if os.environ['MEND_EMAIL'] == '':
        print("MEND_EMAIL {error_message}")
        return False
    MEND_EMAIL = os.environ['MEND_EMAIL']
    
    if os.environ['OUTPUT_FILE'] == '':
        print("OUTPUT_FILE {error_message}")
        return False
    OUTPUT_FILE = os.environ['OUTPUT_FILE']
    
    if os.environ['MAX_LIBRARY_AGE'] == '':
        print("OUTPUT_FILE {error_message}")
        return False
    MAX_LIBRARY_AGE = int(os.environ['MAX_LIBRARY_AGE'])
    
    if "WS_API_KEY" in os.environ and os.environ['WS_API_KEY'] != '':
        MEND_API_KEY = os.environ['WS_API_KEY']
    
    return True


def get_login_body() -> str:
    global MEND_API_KEY
    
    login_body = {
        "userKey": os.environ['MEND_USER_KEY'],
        "email": os.environ['MEND_EMAIL'],
    }
    
    if MEND_API_KEY != '':
        login_body['apiKey'] = MEND_API_KEY
    
    return json.dumps(login_body)
    

def api_login(request_body: str) -> None:
    global MEND_URL
    global MEND_API_KEY
    global HEADERS
    global SESSION
    
    resp = SESSION.post(f"{MEND_URL}/login", request_body, headers=HEADERS)
    
    response = json.loads(resp.content)
    mend_auth_token = response['retVal']['jwtToken']
    HEADERS['Authorization'] = f"Bearer {mend_auth_token}"
    SESSION.headers.update(HEADERS)
    MEND_API_KEY = response['retVal']['orgUuid']
    

def get_data() -> list:
    global MEND_URL
    global MEND_API_KEY
    global SESSION
    global MAX_LIBRARY_AGE
    
    # Get Products
    current_date = datetime.now(timezone.utc)
    product_resp = SESSION.get(f"{MEND_URL}/orgs/{MEND_API_KEY}/products?pageSize=10000&page=0")
    product_response_object = json.loads(product_resp.content)
    num_products = product_response_object['additionalData']['totalItems']
    products = product_response_object['retVal']
    libraries = []
    
    for product_index, product in enumerate(products):
        current_product_token = product['uuid']
        
        # Run an API request to get all direct dependencies in product
        print(f"\033[2KGetting all direct dependencies for Product {product_index+1}/{num_products}: {current_product_token}")
        current_libraries_resp = SESSION.get(f"{MEND_URL}/products/{current_product_token}/libraries?pageSize=10000&page=0&search=directDependency:LIKE:true").content
        current_libraries_content = json.loads(current_libraries_resp)
        
        # If the jwtToken has expired, get a new one and run again.
        if "retVal" not in current_libraries_content:
            api_login(get_login_body())
            current_libraries_resp = SESSION.get(f"{MEND_URL}/products/{current_product_token}/libraries?pageSize=10000&page=0&search=directDependency:LIKE:true").content
            current_libraries_content = json.loads(current_libraries_resp)
            
        
        current_libraries = current_libraries_content['retVal']
        num_libraries = current_libraries_content['additionalData']['totalItems']
        
        # Loop through returned libraries and get versions with release dates.
        for library_index, library in enumerate(current_libraries):
            library_name = library['artifactId'] if 'artifactId' in library else ""
            library_version = library['version'] if 'version' in library else ""
            library_uuid = library['uuid']
            
            print(f"\033[2KGetting Release Date for library {library_index+1}/{num_libraries}: {library_name}\r", end="")
            version_resp = SESSION.get(f"{MEND_URL}/orgs/{MEND_API_KEY}/libraries/{library_uuid}/versions?ignoreManualData=false").content
            version_content = json.loads(version_resp)
            
            # If the jwtToken has expired, get a new one and run again.
            if "retVal" not in version_content:
                api_login(get_login_body())
                version_resp = SESSION.get(f"{MEND_URL}/orgs/{MEND_API_KEY}/libraries/{library_uuid}/versions?ignoreManualData=false").content
                version_content = json.loads(version_resp)
                
            release_date = ""
            for version in version_content['retVal']:
                if version['version'] == library_version:
                    release_date = version['lastUpdatedAt']
                    break
            
            # If there is missing data, then the user will need to review this manually.
            # This can happen if a dependency was resolved through source files.
            if library_name == "" or library_version == "" or release_date == "":
                release_date = "Not stored in Mend index, please check this manually"
                project = library['project']['name']
                product = library['project']['path']
                new_library = {
                    "libraryName": library_name,
                    "libraryVersion": library_version,
                    "productName": product,
                    "projectName": project,
                    "releaseDate": release_date
                }
                libraries.append(new_library)
            else:
                tzinfos={"Z": 0000}
                release_date_object = parse(release_date, tzinfos=tzinfos)
                diff = current_date - release_date_object
                
                if  int(diff.total_seconds()) > MAX_LIBRARY_AGE * 60 * 60:
                    product = library['project']['path']
                    project = library['project']['name']
                    new_library = {
                        "libraryName": library_name,
                        "libraryVersion": library_version,
                        "productName": product,
                        "projectName": project,
                        "releaseDate": release_date
                    }
                    libraries.append(new_library)
    
    return libraries
                    
            
    
def main():
    global OUTPUT_FILE
    global SESSION
    
    if not validate_env():
        sys.exit(1)
    
    
    login_request_body = get_login_body()
    api_login(login_request_body)
    libraries = get_data()
    
    SESSION.close()
    
    with open(OUTPUT_FILE, 'w') as file:
        json.dump(libraries, file, indent=4)
        
    
if __name__ == "__main__":
    main()