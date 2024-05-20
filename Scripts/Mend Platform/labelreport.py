import requests
import json
from openpyxl import Workbook
import argparse
import datetime

parser = argparse.ArgumentParser('labelreport.py','This allows you to supply a label or labels applicable to Mend.io projects, and reports on security vulnerability totals for only those projects with one of the supplied labels. Supply labels as a comma-separated list with no spaces.')
parser.add_argument('-l', '--labels')
parser.add_argument('-e', '--email')
parser.add_argument('-u', '--userKey')
args = parser.parse_args()
# print('Here it is:' + args.labels)

email = args.email
userKey = args.userKey
label = args.labels


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

projectsUrl = 'https://saas.mend.io/bff/api/orgs/' + orgUuid + '/projects/summaries/total?search=labels:IN:' + label
projectsHeaders = dict()
projectsHeaders['authorization'] = 'Bearer ' + jwtToken
projectsHeaders['Content-Type'] = 'application/json'
projectsr = requests.post(projectsUrl, data='{"projects":[],"products":[]}', headers=projectsHeaders)
projectsr.raise_for_status()
#print(json.dumps(projectsr.json(), indent=2))

vulnsresp = json.loads(projectsr.text)

wb = Workbook()
ws = wb.active
ws.append(['Vulnerability totals for projects with label(s): ' + args.labels + ' at ' + str(datetime.datetime.now())])
xlHeader = ['Total Vulns','Total Critical Vulns','Total High Vulns','Total Medium Vulns','Total Low Vulns','SCA Vulns','SCA Critical Vulns','SCA High Vulns','SCA Medium Vulns','SCA Low Vulns','SAST Vulns','SAST High Vulns','SAST Medium Vulns','SAST Low Vulns','Image Vulns','Image Critical Vulns','Image High Vulns','Image Medium Vulns','Image Low Vulns']
ws.append(xlHeader)


scaCritical = int(vulnsresp['retVal']['totalSummary']['vulnerabilities']['critical'])
scaHigh = int(vulnsresp['retVal']['totalSummary']['vulnerabilities']['high'])
scaMedium = int(vulnsresp['retVal']['totalSummary']['vulnerabilities']['medium'])
scaLow = int(vulnsresp['retVal']['totalSummary']['vulnerabilities']['low'])
scaTotal = scaCritical+scaHigh+scaMedium+scaLow

sastHigh = int(vulnsresp['retVal']['totalSummary']['sastVulnerabilities']['high'])
sastMedium = int(vulnsresp['retVal']['totalSummary']['sastVulnerabilities']['medium'])
sastLow = int(vulnsresp['retVal']['totalSummary']['sastVulnerabilities']['low'])
sastTotal = sastHigh+sastMedium+sastLow

imgCritical = int(vulnsresp['retVal']['totalSummary']['imgScan']['critical'])
imgHigh = int(vulnsresp['retVal']['totalSummary']['imgScan']['high'])
imgMedium = int(vulnsresp['retVal']['totalSummary']['imgScan']['medium'])
imgLow = int(vulnsresp['retVal']['totalSummary']['imgScan']['low'])
imgTotal = imgCritical+imgHigh+imgMedium+imgLow

#note we do NOT pull the Unified totals from the summary response like we do for each scan type above, because as of 5/20/2024 the Unified total is off by one
#the MP UI must sum the individual engine counts itself as well, because its totals are correct

unifiedCritical = scaCritical+imgCritical
unifiedHigh = scaHigh+sastHigh+imgHigh
unifiedMedium = scaMedium+sastMedium+imgMedium
unifiedLow = scaLow+sastLow+imgLow
unifiedTotal = unifiedCritical+unifiedHigh+unifiedMedium+unifiedLow

ws.append([unifiedTotal,unifiedCritical,unifiedHigh,unifiedMedium,unifiedLow,scaTotal,scaCritical,scaHigh,scaMedium,scaLow,sastTotal,sastHigh,sastMedium,sastLow,imgTotal,imgCritical,imgHigh,imgMedium,imgLow])

wb.save(orgName+".xlsx")