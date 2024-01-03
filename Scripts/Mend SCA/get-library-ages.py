import requests
import os
import sys
import json
import re
import argparse
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
pip3 install requests python-dateutil
python3 get-library-ages.py -o <output_file>.json -a <max_age_in_days>

Optional Arguments: the only optional arguments for this script are WS_API_KEY and MEND_PRODUCT_TOKEN. 
If WS_API_KEY is not specified then the Mend API will log in to the last organization accessed from the Mend Platform.
If MEND_PRODUCT_TOKEN is not specified then it will pull everything in the organizaiton.

Pre-requisites:
apt-get install python3.9
pip install requests python-dateutil
export MEND_USER_KEY='<MEND_USER_KEY>'
export MEND_URL='<MEND_URL>
export MEND_EMAIL='<MEND_EMAIL>'
export WS_API_KEY='<WS_API_KEY>' <-- Optional
export MEND_PRODUCT_TOKEN='<PRODUCT_TOKEN>' <-- Optional
"""

MEND_USER_KEY = ""
MEND_EMAIL = ""
MEND_URL = ""
MEND_API_KEY = ""
MEND_PRODUCT_TOKEN = ""
OUTPUT_FILE = ""
MAX_LIBRARY_AGE = 0
HEADERS = {'Content-Type': 'application/json'}
SESSION = requests.Session()
CURRENT_DATE = datetime.now(timezone.utc)

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--outputFile', dest='output_file')
    parser.add_argument('-a', '--libraryAge', dest='library_age')
    return parser.parse_args()

def validate_env() -> bool:
    global MEND_USER_KEY
    global MEND_URL
    global MEND_EMAIL
    global OUTPUT_FILE
    global MEND_API_KEY
    global MEND_PRODUCT_TOKEN
    global MAX_LIBRARY_AGE
    
    config = parse_args()
    
    try:
        MEND_URL = os.environ['MEND_URL']
        MEND_URL = re.sub(r'^(.*?)(saas|app)(.*)', r'\1api-\2\3/api/v2.0', MEND_URL, 1)
        MEND_USER_KEY = os.environ['MEND_USER_KEY']
        MEND_EMAIL = os.environ["MEND_EMAIL"]
        
        OUTPUT_FILE = config.output_file
        if OUTPUT_FILE == None:
            raise Exception("-o/--outputFile")
        
        library_age = config.library_age
        if library_age == None:
            raise Exception("-a/--libraryAge")
        MAX_LIBRARY_AGE = int(library_age)
        
    except KeyError as err:
        print(f"{err.args[0]} environment variable not found. Please set this environment variable and try again.")
        return False
    except Exception as err:
        print(f"{err} flag was not set. Please set this flag and try again.")
        return False
    
    if "WS_API_KEY" in os.environ and os.environ['WS_API_KEY'] != '':
        MEND_API_KEY = os.environ['WS_API_KEY']
        
    if "MEND_PRODUCT_TOKEN" in os.environ and os.environ['MEND_PRODUCT_TOKEN'] != '':
        MEND_PRODUCT_TOKEN = os.environ['MEND_PRODUCT_TOKEN']
    
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
    global MEND_PRODUCT_TOKEN
    global SESSION
    global MAX_LIBRARY_AGE
    
    # Get Products    
    if MEND_PRODUCT_TOKEN !='':
        product_resp = SESSION.get(f"{MEND_URL}/products/{MEND_PRODUCT_TOKEN}")
        products = [json.loads(product_resp.content)['retVal']]
        num_products = 1
    else:
        product_resp = SESSION.get(f"{MEND_URL}/orgs/{MEND_API_KEY}/products?pageSize=10000&page=0")
        product_response_object = json.loads(product_resp.content)
        num_products = product_response_object['additionalData']['totalItems']
        products = product_response_object['retVal']
        
    libraries = []
    
    for product_index, product in enumerate(products):
        current_product_token = product['uuid']
        
        # Run an API request to get all direct dependencies in product
        print(f"\033[2KGetting all direct dependencies for Product {product_index+1}/{num_products}: {current_product_token}")
        libraries.append(get_product_data(current_product_token))
    
    return libraries


def get_product_data(product_uuid: str) -> list:
    global SESSION
    global MEND_URL
    global CURRENT_DATE
    # Run an API request to get all direct dependencies in product
    
    ret_libraries = []

    current_libraries_resp = SESSION.get(f"{MEND_URL}/products/{product_uuid}/libraries?pageSize=10000&page=0&search=directDependency:LIKE:true").content
    current_libraries_content = json.loads(current_libraries_resp)
    
    # If the jwtToken has expired, get a new one and run again.
    if "retVal" not in current_libraries_content:
        api_login(get_login_body())
        current_libraries_resp = SESSION.get(f"{MEND_URL}/products/{product_uuid}/libraries?pageSize=10000&page=0&search=directDependency:LIKE:true").content
        current_libraries_content = json.loads(current_libraries_resp)
        
    
    current_libraries = current_libraries_content['retVal']
    num_libraries = current_libraries_content['additionalData']['totalItems']
    
    # Loop through returned libraries and get versions with release dates.
    for library_index, library in enumerate(current_libraries):
        library_name = library['artifactId'] if 'artifactId' in library else ""        
        print(f"\033[2KGetting Release Date for library {library_index+1}/{num_libraries}: {library_name}\r", end="")
        ret_libraries.append(process_library(library))
    return ret_libraries

def process_library(library: dict):
    global SESSION
    global MEND_URL
    global MEND_API_KEY
    global MAX_LIBRARY_AGE
    
    library_name = library['artifactId'] if 'artifactId' in library else ""
    library_version = library['version'] if 'version' in library else ""
    library_uuid = library['uuid']
    
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
    else:
        tzinfos={"Z": 0000}
        release_date_object = parse(release_date, tzinfos=tzinfos)
        diff = CURRENT_DATE - release_date_object
        
        if int(diff.total_seconds()) > MAX_LIBRARY_AGE * 60 * 60:
            product = library['project']['path']
            project = library['project']['name']
        else:
            return
    
    # Build out the library object and append to list.
    new_library = {}
    new_library['libraryName'] = library_name
    new_library['libraryVersion'] = library_version
    new_library['productName'] = product
    new_library['projectName'] = project
    new_library['releaseDate'] = release_date
    return new_library
            
    
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