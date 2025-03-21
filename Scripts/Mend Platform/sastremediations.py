import requests
import json
from openpyxl import Workbook
import argparse
import datetime

parser = argparse.ArgumentParser('remediations.py','This script creates an XLS spreadsheet containing the SAST vulnerabilities that were remediated within a supplied scan date range.\n       -p is the UUID of the project. Dates must be in 20250314 format.')
parser.add_argument('-p', '--projectuuid', required=True)
parser.add_argument('-s', '--startdate', required=True)
parser.add_argument('-f', '--finishdate', required=True)
parser.add_argument('-e', '--email', required=True)
parser.add_argument('-u', '--userkey', required=True)
args = parser.parse_args()

email = args.email
userKey = args.userkey
startDate = datetime.datetime.fromisoformat(args.startdate)
finishDate = datetime.datetime.fromisoformat(args.finishdate)
projectUuid = args.projectuuid


loginpayload = dict()
loginpayload['email'] = email
#loginpayload['orgUuid'] = orgUuid
loginpayload['userKey'] = userKey
loginheaders = {
    'Content-Type': 'application/json'
}
loginr = requests.post('https://api-saas.mend.io/api/v3.0/login', data=json.dumps(loginpayload), headers=loginheaders)
loginr.raise_for_status()
#print(loginr.status_code)
loginresp = json.loads(loginr.text)
refreshToken = loginresp['response']['refreshToken']

tokenheaders = dict()
tokenheaders['wss-refresh-token'] = refreshToken
tokenr = requests.post('https://api-saas.mend.io/api/v3.0/login/accessToken', headers=tokenheaders)
tokenr.raise_for_status()
tokenresp = json.loads(tokenr.text)
jwtToken = tokenresp['response']['jwtToken']
defaultOrgUuid = tokenresp['response']['orgUuid']
defaultOrgName = tokenresp['response']['orgName']
orgUuid = defaultOrgUuid
orgName = defaultOrgName

scansUrl = 'https://saas.mend.io/bff/api/orgs/' + orgUuid + '/scans/summaries?page=0&search=scanType:IN:SAST&scanTime:EQUALS:6_months&pageSize=50&sort=scanTime'
scansHeaders = dict()
scansHeaders['authorization'] = 'Bearer ' + jwtToken
scansHeaders['Content-Type'] = 'application/json'
scansr = requests.post(scansUrl, data='{"projects":["' + projectUuid + '"],"products":[]}', headers=scansHeaders)
scansr.raise_for_status()
#print(json.dumps(scansr.json(), indent=2))

scansresp = json.loads(scansr.text)

numScans = int(scansresp['additionalData']['totalItems'])

#print("Number of scans: " + str(numScans))

scannum = 0
uuids = set()
scans= set()
newuuids = set()
allfindings = dict()
remediations = set()


for scan in scansresp['retVal']:
  newuuids.clear()
  thisscanid = scan['uuid']
  scanTime = datetime.datetime.fromisoformat(scan['scanTime'])
  scanTimeNaive = scanTime.replace(tzinfo=None)
  # print("Scan "+thisscanid+" has datetime "+str(scanTimeNaive))
  if scanTimeNaive >= startDate and scanTimeNaive <= finishDate:
    # print(thisscanid+" processed; inside of date range. ")
    resultsHeaders = dict()
    resultsHeaders['authorization'] = 'Bearer ' + jwtToken
    resultsHeaders['Content-Type'] = 'application/json'
    resultsUrl = 'https://saas.mend.io/bff/api/projects/' + projectUuid + '/sast/scans/' + scan['uuid'] + '/results'
    resultsr = requests.post(resultsUrl, headers=resultsHeaders, data='{"startRow": 0, "endRow": 9999, "rowGroupCols": [], "valueCols": [], "pivotCols": [], "pivotMode": false, "groupKeys": [], "filterModel": {}, "sortModel": [ { "sort": "desc", "colId": "severity" } ] }')
    resultsr.raise_for_status()
    resultsresp = json.loads(resultsr.text)

    if scannum == 0:
      for finding in resultsresp['retVal']['rows']:
        thisuuid = finding['vulnerability']['uuid']
        uuids.add(thisuuid)
        allfindings[thisuuid] = thisscanid
    else:
      for finding in resultsresp['retVal']['rows']:
        thisuuid = finding['vulnerability']['uuid']
        newuuids.add(thisuuid)
        allfindings[thisuuid] = thisscanid
      thisremediations = uuids.difference(newuuids)
      remediations.update(thisremediations)
      # print("Remediations: " + str(remediations))
      newones = newuuids.difference(uuids)
      # print("New ones: " + str(newones))
      uuids.update(newones)
    scannum += 1
    print(".", end='', flush=True)
  #else:
    #print("Scan "+thisscanid+" skipped; outside of date range. ")

wb = Workbook()
ws = wb.active
ws.append(["SAST Remediations for Project with UUID " + projectUuid])
ws.append(["Vuln UUID","Vuln Type","Vuln Language","Vuln Created Time","Vuln Severity","Sink function name","Sink File","Sink Line Number"])

for foo in remediations:
  # print("foo: " + foo)
  # print(" --- allfindings[foo]: " + allfindings[foo])
  remedsUrl = 'https://saas.mend.io/bff/api/projects/' + projectUuid + '/sast/scans/' + allfindings[foo] + '/findings/' + foo
  # 	https://saas.mend.io/bff/api/projects/de94d8d0-9f97-4f05-bebd-53ee1c8b5572/sast/scans/3943a076-ddde-4cfe-838e-93db6df4a3d3/findings/122883d7-4f0b-4acb-b38c-a4969ea1a7ac
  # print(remedsUrl)
  remedsr = requests.get(remedsUrl, headers=resultsHeaders)
  remedsr.raise_for_status()
  remedsresp = json.loads(remedsr.text)
  id = remedsresp['retVal']['id']
  type = remedsresp['retVal']['type']['name']
  language = remedsresp['retVal']['type']['language']
  createdTime = remedsresp['retVal']['createdTime']
  severity = remedsresp['retVal']['severity']
  name = remedsresp['retVal']['sharedStep']['name']
  file = remedsresp['retVal']['sharedStep']['file']
  line = str(remedsresp['retVal']['sharedStep']['line'])
  remedline = [id,type,language,createdTime,severity,name,file,line]
  ws.append(remedline)
  #print(remedline)
  print(".", end='', flush=True)


wb.save("SASTRemediations.xlsx")
print("\nSpreadsheet SASTRemediations.xlsx created in current directory.")