// ******** Mend Unified CLI Template for Jenkins********
// You may wish to alter this file to override the build tool and the Mend scanning technologies used (Deps, Code or Image).

// For more configeration options, please check the technical documentation portal:
// 📚 https://docs.mend.io/bundle/cli/page/scan_with_mend_s_unified_cli.html

// ******** Description ********
// mend deps will automatically use package managers and file system scanning to detect open source components. 
// mend code will automatically detect languages and frameworks used in your projects to scan for code weaknesses.
// The following Global Environment Variables should be set
// MEND_EMAIL = <your mend user email>
// MEND_USER_KEY= <your mend user key>
// MEND_URL = <your mend instance base url>
// MEND_SAST_API_TOKEN = <your mend SAST API Token >
// MEND_SAST_ORGANIZATION < your mend SAST Organization ID >

pipeline {
    agent any

    environment {
        MEND_SAST_SERVER_URL = "${env.MEND_URL}/sast"
        MEND_SAST_THRESHOLD_ONLY_NEW = "true"
        
    }
    
// The following tools are only required because the example application is a Java repository.
    tools {
        maven 'Maven-3.9.3'
        jdk 'JDK11'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
// The below is an example and can be replaced with your git repository and branch
        stage('Git Clone') {
            steps {
                checkout changelog: false, poll: false, scm: scmGit(branches: [[name: 'refs/tags/v8.1.0']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/WebGoat/WebGoat.git']])
            }
        }
// The above repository is a Java example so a build is initiated here
        stage('Install dependencies') {
            steps {
            sh 'mvn clean install -DskipTests'
            }
        }

        stage('Download Mend CLI') {
            steps {
                script {
                    echo 'Downloading Mend CLI'
                    sh 'curl -LJO https://downloads.mend.io/production/unified/latest/linux_amd64/mend && chmod +x mend'
                }
            }
        }

        stage('Run Mend Deps') {
            steps {
                echo 'Start Mend Dependency Scan'
                sh './mend deps -u --no-color > scanresults.txt'
                archiveArtifacts artifacts: "scanresults.txt", fingerprint: true
            }
        }

        stage('Generate Mend Dependency Reports') {
            steps {
                sh '''
                WS_PROJECTTOKEN=$(grep -oP "(?<=token=)[^&]+" ${PWD}/scanresults.txt)
                echo "Creating Project Risk Report"
                curl -o ${PWD}/riskreport.pdf -X POST "${MEND_URL}/api/v1.4" -H "Content-Type: application/json"  -d '{"requestType":"getProjectRiskReport","userKey":"'${MEND_USER_KEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'
                echo "Creating Project Inventory Report"
                curl -o ${PWD}/inventoryreport.xlsx -X POST "${MEND_URL}/api/v1.4" -H "Content-Type: application/json"  -d '{"requestType":"getProjectInventoryReport","userKey":"'${MEND_USER_KEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'
                echo "Creating Project Due Diligence Report"
                curl -o ${PWD}/duediligencereport.xlsx -X POST "${MEND_URL}/api/v1.4" -H "Content-Type: application/json"  -d '{"requestType":"getProjectDueDiligenceReport","userKey":"'${MEND_USER_KEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'
                '''
                archiveArtifacts artifacts: "riskreport.pdf, inventoryreport.xlsx, duediligencereport.xlsx, spdxreport.json", fingerprint: true
            }
        }

        stage('Generate Mend SBOM Report') {
            steps {
                script {
                    sh '''
                        WS_PROJECTTOKEN=$(grep -oP "(?<=token=)[^&]+" ${PWD}/scanresults.txt)
                        WS_APIKEY=$(grep -o '"OrgUuid": "[^"]*' /var/jenkins_home/.mend/config/settings.json | awk -F'"' '{print $4}')
                        get_proj_resp=$(curl -s -X POST -H "Content-Type:application/json" -d '{"requestType":"generateProjectReportAsync","projectToken":"'$WS_PROJECTTOKEN'","userKey":"'$MEND_USER_KEY'","reportType":"ProjectSBOMReport", "standard":"spdx" , "format":"json"}' $MEND_URL/api/v1.4)
                        echo "Report generation call sent for ProjectSBOMReport"
                        procId="$(echo "$get_proj_resp" | jq -r '.asyncProcessStatus.uuid')"
                        contextType="$(echo "$get_proj_resp" | jq -r '.asyncProcessStatus.contextType')"
                        processType="$(echo "$get_proj_resp" | jq -r '.asyncProcessStatus.processType')"
                        ready=false
                        while [[ $ready = "false" ]] ; do
	                        resProcess=$(curl -s -X POST -H "Content-Type:application/json" -d '{"requestType":"getAsyncProcessStatus","orgToken":"'$WS_APIKEY'","userKey":"'$MEND_USER_KEY'","uuid":"'$procId'"}' $MEND_URL/api/v1.4)
	                        repStatus="$(echo "$resProcess" | jq -r '.asyncProcessStatus.status')"
	                        if [[ $repStatus = "FAILED" ]] ; then
		                        echo "Report FAILED"
		                        echo "$resProcess" | jq .
		                        exit 1
	                        elif [[ $repStatus = "SUCCESS" ]] ; then
		                        ready=true
		                        repType="$(echo "$resProcess" | jq -r '.asyncProcessStatus.processType')"
		                        reportFile="${PWD}/$repType.zip"
		                        echo "Downloading report..."
		                        curl -s -X POST -H 'Content-Type:application/json' -d '{"requestType":"downloadAsyncReport","orgToken":"'$WS_APIKEY'","userKey":"'$MEND_USER_KEY'","reportStatusUUID":"'$procId'"}' --output "$reportFile" $MEND_URL/api/v1.4
	                        else
		                        sleep 5
	                        fi
                        done
                        unzip $reportFile -d ${PWD} && rm $reportFile
                    '''
                }
                archiveArtifacts artifacts: "**/*project-SPDX-report.json", fingerprint: true
            }
        }

        stage('Evaluate Dependency Scan') {
            steps {
                echo 'Evaluate Dependency Scan'
                script {
                    env.CRIT_VULNS = sh(returnStdout: true, script: "grep -i 'critical' scanresults.txt | grep -i 'upgrade'").trim()
                    env.DEP_TABLE = sh(returnStdout: true, script: "sed -n '/Paths at risk/,\$p' scanresults.txt | sed '1d'").trim()
                }
                echo "Critical vulnerabilities are below"
                echo "${env.CRIT_VULNS}"
                echo "Dependency Table is below"
                echo "${env.DEP_TABLE}"
                script {
                    if (env.CRIT_VULNS)
                        error('Please fix the critical vulnerabilities shown above.')
                    }
                echo "No critical vulnerabilities were found in your scan"
            }
        }

        stage('Run Mend Code') {
            steps {
                echo 'Start Mend Code Scan'
                sh './mend code -j 2 --no-color'
            }
        }
    }
}