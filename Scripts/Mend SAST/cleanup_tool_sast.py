import http.client
import json
import sys
from datetime import timedelta, datetime

args = sys.argv[1:]
if len(args) == 0:
   print("Api Token is required to run this script, please provide the token as a command line argument.")
   exit()     

conn = http.client.HTTPSConnection("saas.mend.io")
headers = {
  'X-Auth-Token': args[0]
}
ids_to_remove = []
has_ids_to_remove = True
page_size = 100
page_num = 1
days_to_remove = int(args[1]) if len(args) > 1 else 21
archive_date = datetime.utcnow() - timedelta(days=days_to_remove)
print("Getting scans to remove...")
while has_ids_to_remove:
    conn.request("GET", "/sast/api/scans?order=ascend&limit={}&page={}&summary=true".format(page_size, page_num), '', headers)
    res = conn.getresponse()
    data = res.read()
    get_response_string = data.decode("utf-8")
    get_response_obj = json.loads(get_response_string)
    if "success" in get_response_obj:
        print("There was an issue with the request: " + get_response_obj["message"])
    else:
        id_batch = [x["id"] for x in get_response_obj if archive_date > datetime.strptime(x["createdTime"],'%Y-%m-%dT%H:%M:%S.%fZ')]
        if len(id_batch) > 0:
            ids_to_remove.extend(id_batch)
        page_num += 1
        if len(id_batch) != page_size:
            has_ids_to_remove = False

if not ids_to_remove or len(ids_to_remove) == 0:
    print("No scans older than {} were found".format(archive_date))
    exit()

print("Found {} scans to older than {}, removing scans...".format(len(ids_to_remove), archive_date))
for id in ids_to_remove:
    conn.request("DELETE", "/sast/api/scans/{}".format(id), '', headers)
    res = conn.getresponse()
    data = res.read()
    delete_response_string = data.decode("utf-8")
    delete_response_obj = json.loads(delete_response_string)
    if delete_response_obj["success"] == False:
        print("There was an issue with the request: " + delete_response_obj["message"])
        break

print("Scans Deleted")