import requests
import json
from openpyxl import Workbook
import argparse
import datetime

parser = argparse.ArgumentParser('remediations.py','help goes here')
parser.add_argument('-p', '--projectuuid')
parser.add_argument('-s', '--startdate')
parser.add_argument('-f', '--finishdate')
parser.add_argument('-e', '--email')
parser.add_argument('-u', '--userkey')
args = parser.parse_args()

email = args.email
userKey = args.userkey
startDate = args.startdate
finishDate = args.finishdate
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

print("Number of scans: " + str(numScans))

scannum = 0
uuids = set()
newuuids = set()
#types = []
#files = []
#lines = []
remediations = set()

for scan in scansresp['retVal']:
  print(scan['uuid'])
  resultsUrl = 'https://saas.mend.io/bff/api/projects/' + projectUuid + '/sast/scans/' + scan['uuid'] + '/results'
  resultsHeaders = dict()
  resultsHeaders['authorization'] = 'Bearer ' + jwtToken
  resultsHeaders['Content-Type'] = 'application/json'
  resultsr = requests.post(resultsUrl, headers=resultsHeaders, data='{"startRow": 0, "endRow": 9999, "rowGroupCols": [], "valueCols": [], "pivotCols": [], "pivotMode": false, "groupKeys": [], "filterModel": {}, "sortModel": [ { "sort": "desc", "colId": "severity" } ] }')
  resultsr.raise_for_status()
  resultsresp = json.loads(resultsr.text)

  if scannum == 0:
    for finding in resultsresp['retVal']['rows']:
      # print(finding['vulnerability']['uuid'] + " " + finding['vulnerability']['type'] + " " + finding['vulnerability']['file'] + " " + str(finding['vulnerability']['line']))
      uuids.add(finding['vulnerability']['uuid'])
      #types.append(finding['vulnerability']['type'])
      #files.append(finding['vulnerability']['file'])
      #lines.append(finding['vulnerability']['line'])
    #print(len(uuids))
    #for i in range(len(uuids)):
      #print(uuids[i] + " " + types[i] + " " + files[i] + " " + str(lines[i]))
  else:
    for finding in resultsresp['retVal']['rows']:
      newuuids.add(finding['vulnerability']['uuid'])
    remediations.update(uuids.difference(newuuids))
    print("Remediations: " + str(remediations))
    newones = newuuids.difference(uuids)
    print("New ones: " + str(newones))
    uuids.update(newones)
      # if finding['vulnerability']['uuid'] in uuids:
      #   print("Found " + finding['vulnerability']['uuid'])
      # else:
      #   remediations.append(finding['vulnerability']['uuid'])
  scannum += 1


# wb = Workbook()
# ws = wb.active
# ws.append(['Vulnerability totals for projects with label(s): ' + args.labels + ' at ' + str(datetime.datetime.now())])
# xlHeader = ['Total Vulns','Total Critical Vulns','Total High Vulns','Total Medium Vulns','Total Low Vulns','SCA Vulns','SCA Critical Vulns','SCA High Vulns','SCA Medium Vulns','SCA Low Vulns','SAST Vulns','SAST High Vulns','SAST Medium Vulns','SAST Low Vulns','Image Vulns','Image Critical Vulns','Image High Vulns','Image Medium Vulns','Image Low Vulns']
# ws.append(xlHeader)


# scaCritical = int(vulnsresp['retVal']['totalSummary']['vulnerabilities']['critical'])
# scaHigh = int(vulnsresp['retVal']['totalSummary']['vulnerabilities']['high'])
# scaMedium = int(vulnsresp['retVal']['totalSummary']['vulnerabilities']['medium'])
# scaLow = int(vulnsresp['retVal']['totalSummary']['vulnerabilities']['low'])
# scaTotal = scaCritical+scaHigh+scaMedium+scaLow

# sastHigh = int(vulnsresp['retVal']['totalSummary']['sastVulnerabilities']['high'])
# sastMedium = int(vulnsresp['retVal']['totalSummary']['sastVulnerabilities']['medium'])
# sastLow = int(vulnsresp['retVal']['totalSummary']['sastVulnerabilities']['low'])
# sastTotal = sastHigh+sastMedium+sastLow

# imgCritical = int(vulnsresp['retVal']['totalSummary']['imgScan']['critical'])
# imgHigh = int(vulnsresp['retVal']['totalSummary']['imgScan']['high'])
# imgMedium = int(vulnsresp['retVal']['totalSummary']['imgScan']['medium'])
# imgLow = int(vulnsresp['retVal']['totalSummary']['imgScan']['low'])
# imgTotal = imgCritical+imgHigh+imgMedium+imgLow

# #note we do NOT pull the Unified totals from the summary response like we do for each scan type above, because as of 5/20/2024 the Unified total is off by one
# #the MP UI must sum the individual engine counts itself as well, because its totals are correct

# unifiedCritical = scaCritical+imgCritical
# unifiedHigh = scaHigh+sastHigh+imgHigh
# unifiedMedium = scaMedium+sastMedium+imgMedium
# unifiedLow = scaLow+sastLow+imgLow
# unifiedTotal = unifiedCritical+unifiedHigh+unifiedMedium+unifiedLow

# ws.append([unifiedTotal,unifiedCritical,unifiedHigh,unifiedMedium,unifiedLow,scaTotal,scaCritical,scaHigh,scaMedium,scaLow,sastTotal,sastHigh,sastMedium,sastLow,imgTotal,imgCritical,imgHigh,imgMedium,imgLow])

# wb.save(orgName+".xlsx")