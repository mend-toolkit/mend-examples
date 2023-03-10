import http.client
import json
import argparse
import re
import os
from datetime import timedelta, datetime
from distutils.util import strtobool

def valid_date(s):
    try:
        return datetime.strptime(s, "%Y-%m-%d")
    except ValueError:
        msg = "not a valid date: {0!r}".format(s)
        raise argparse.ArgumentTypeError(msg)
    
parser = argparse.ArgumentParser(description="Mend Sast Clean up tool")
parser.add_argument('-k', '--apiToken', help="Mend API token", dest='mend_api_token', required=True) 
parser.add_argument('-a', '--mendUrl', help="Mend URL", dest='mend_url', required=True)
parser.add_argument('-t', '--reportFormat', help="Report format to generate. Supported formats (csv, pdf, html, xml, json, sarif)", dest='report_format', default="csv")
parser.add_argument('-o', '--outputDir', help="Output directory", dest='output_dir', default=os.getcwd() + "\\Mend\\Reports\\")
parser.add_argument('-r', '--daysToKeep', help="Number of days to keep (overridden by --dateToKeep)", dest='days_to_keep', type=int, default=21)
parser.add_argument('-d', '--dateToKeep', help="Date of latest scan to keep in YYYY-MM-DD format ", dest='date_to_keep', type=valid_date)
parser.add_argument('-y', '--dryRun', help="Whether to run the tool without performing anything", dest='dry_run', type=strtobool, default=False)
parser.add_argument('-s', '--skipReportGeneration', help="Skip Report Generation", dest='skip_report_generation', type=strtobool, default=False)
parser.add_argument('-j', '--skipScanDeletion', help="Skip Scan Deletion", dest='skip_scan_deletion', type=strtobool, default=False)
conf = parser.parse_args()

headers = {
  'X-Auth-Token': conf.mend_api_token
}

api_connection = http.client.HTTPSConnection(conf.mend_url)

def generate_report(id):
    print("Generating reports for scan {}".format(id))
    reportBuilt = False
    
    payload = json.dumps({
        "format": conf.report_format,
        "input": {},
        "reportLevel": "technical",
        "reportType": "Default",
        "scanId": id
    })
    api_connection.request("POST", "/sast/api/reports", payload, headers)
    createResponseObj = json.loads(api_connection.getresponse().read().decode("utf-8"))
    if createResponseObj["success"] == False:
        print("There was an generating a report for scan id {}: {} ".format(id, createResponseObj["message"]))
        return
    
    print("Searching for Report")
    while not reportBuilt:
        api_connection.request("GET", "/sast/api/reports?page=1&limit=10&sort=createdTime&order=descend", '', headers)
        reportListRes = api_connection.getresponse()
        reportListResdata = reportListRes.read()
        reports_list_obj = json.loads(reportListResdata.decode("utf-8"))
        reportBuilt = reports_list_obj[0]["storagePath"] != "" and id in reports_list_obj[0]["storagePath"]
        if reportBuilt:
            print("Report Found")
            print("Retrieving Report")
            api_connection.request("GET", "/sast/api/reports/{}".format(reports_list_obj[0]["id"]), '', headers)
            reportRes = api_connection.getresponse()
            reportResdata = reportRes.read()
            print("Writing File")
            if not os.path.exists(conf.output_dir):
                print("Making directory" + conf.output_dir)
                os.makedirs(conf.output_dir)
            filename = re.sub('[:/]', '-', reports_list_obj[0]["name"])
            report = open(conf.output_dir + filename + '.' + reports_list_obj[0]["format"] , "wb")
            report.write(reportResdata)
            report.close()
            print("File written to " + conf.output_dir + filename + '.' + reports_list_obj[0]["format"])

def delete_scan(id):
    api_connection.request("DELETE", "/sast/api/scans/{}".format(id), '', headers)
    delete_response_obj = json.loads(api_connection.getresponse().read().decode("utf-8"))
    if delete_response_obj["success"] == False:
        print("There was an issue with the request: " + delete_response_obj["message"])
        return

def get_scans(page_size, page_num):
    api_connection.request("GET", "/sast/api/scans?order=ascend&limit={}&page={}&summary=true".format(page_size, page_num), '', headers)
    get_response_obj = json.loads(api_connection.getresponse().read().decode("utf-8"))
    if "success" in get_response_obj:
        print("There was an issue with the request: " + get_response_obj["message"])
    else:
        return [x["id"] for x in get_response_obj if archive_date > datetime.strptime(x["createdTime"],'%Y-%m-%dT%H:%M:%S.%fZ')]
        
def get_ids_to_remove():
    ids_to_remove = []
    has_ids_to_remove = True
    page_size = 100
    page_num = 1
    while has_ids_to_remove:
        id_batch = get_scans(page_size, page_num)
        if len(id_batch) > 0:
            ids_to_remove.extend(id_batch)
        
        has_ids_to_remove = len(id_batch) == page_size
        page_num += 1
    return ids_to_remove

if conf.date_to_keep is None:
    archive_date = datetime.utcnow() - timedelta(days=conf.days_to_keep)
else:
    archive_date = conf.date_to_keep

print("Deleting scans older than: {}".format(archive_date))
print("Getting scans to remove...")

ids_to_remove = get_ids_to_remove()
if not ids_to_remove or len(ids_to_remove) == 0:
    print("No scans older than {} were found".format(archive_date))
    exit()

print("Found {} scans to older than {}, generating reports and removing scans...".format(len(ids_to_remove), archive_date))

if not conf.dry_run:
    
    for id in ids_to_remove:
        if not conf.skip_report_generation:
            generate_report(id)
        else:
            print("skipReportGeneration set to true, skipping reports")
        
        if not conf.skip_scan_deletion:
            delete_scan(id)
        else:
            print("skipScanDeletion set to true, skipping deletion")
        
print("SAST clean up has been finished")