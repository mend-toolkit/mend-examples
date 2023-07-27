import requests, csv, sys
from datetime import datetime, timedelta

def get_organization_product_vitals(url, org_token, user_key, include_request_token=False):
    url = 'https://{}/api/v1.4'.format(url)

    request_data = {
        "orgToken": org_token,
        "requestType": "getOrganizationProductVitals",
        "userKey": user_key,
        "includeRequestToken": include_request_token
    }

    headers = {
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(url, json=request_data, headers=headers)
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



if len(sys.argv) != 5:
    sys.exit(1)

url = sys.argv[1]
org_token = sys.argv[2]
user_key = sys.argv[3]
number_of_days = int(sys.argv[4])
include_request_token = True


product_vitals = get_organization_product_vitals(url, org_token, user_key, include_request_token)

if product_vitals:
    current_date = str(datetime.now())
    curr_date_obj = datetime.strptime(current_date[:-16], "%Y-%m-%d")
    seven_days_ago = curr_date_obj - timedelta(days=number_of_days)

    csv_filename = "request-history.csv"
    NoData = True
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
                    NoData = False
                    writer.writerow({"Product Name": name, "Last Scan Time": date_obj})
        csvfile.close()

        if NoData:
            print("[!] No Products within the provided timeframe of {} day(s)".format(number_of_days))
