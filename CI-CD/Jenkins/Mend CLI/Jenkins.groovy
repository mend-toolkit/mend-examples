// ******** Mend Unified CLI Template for Jenkins ********
// You may wish to alter this file to override the build tool and the Mend scanning technologies

// For more configeration options, please check the technical documentation portal:
// 📚 https://docs.mend.io/bundle/cli/page/scan_with_mend_s_unified_cli.html

// ******** Description ********
// mend deps will automatically use package managers and file system scanning to detect open source components. 
// mend code will automatically detect languages and frameworks used in your projects to scan for code weaknesses.
// mend image will automatically scan an image for vulnerabilities with Operating System packages, Open Source vulnerabilities, and for secrets.

// If you are NOT using a service user, and have multiple organizations, don't forget to set the organization in the scope parameter
// The following values should be added as environment variables
//    MEND_EMAIL: the user email for the mend platform account you wish to scan with
//    MEND_USER_KEY: the user key found under my profile for the user you wish to scan with


pipeline {
    agent any

    environment {
        MEND_SAST_THRESHOLD_ONLY_NEW = "true"
        // update with the Server URL found on the integrate tab
        MEND_URL = "https://saas.mend.io"
        
    }

    tools {
        maven 'Maven-3.9.6'
        jdk 'JDK11'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Git Clone') {
            steps {
                // replace branch and url with your repository information
                checkout changelog: false, poll: false, scm: scmGit(branches: [[name: 'refs/tags/v8.1.0']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/WebGoat/WebGoat.git']])
            }
        }
        // Build the application with your required package manager.  The below example is for maven: ###
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
                echo 'Run Mend dependencies scan'
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
                sh '''
                export repo=$(basename -s .git $(git config --get remote.origin.url))
                export branch=$(git rev-parse --abbrev-ref HEAD)
                ./mend dep -u -s *//${JOB_NAME}//${repo}_${branch} --fail-policy --non-interactive --export-results dep-results.txt
                '''
                archiveArtifacts artifacts: "dep-results.txt", fingerprint: true
                }
            }
        }

        stage('Generate Mend Dependency Reports') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
                sh '''
                WS_PROJECTTOKEN=$(grep -oP "(?<=token=)[^&]+" ${PWD}/dep-results.txt)
                if [ -z "$WS_PROJECTTOKEN" ];
                then
                    echo " No project token found, reports will not be generated" >&2
                else
                    echo "Creating Project Risk Report"
                    curl -o ${PWD}/riskreport.pdf -X POST "${MEND_URL}/api/v1.4" -H "Content-Type: application/json"  -d '{"requestType":"getProjectRiskReport","userKey":"'${MEND_USER_KEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'
                    echo "Creating Project Inventory Report"
                    curl -o ${PWD}/inventoryreport.xlsx -X POST "${MEND_URL}/api/v1.4" -H "Content-Type: application/json"  -d '{"requestType":"getProjectInventoryReport","userKey":"'${MEND_USER_KEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'
                    echo "Creating Project Due Diligence Report"
                    curl -o ${PWD}/duediligencereport.xlsx -X POST "${MEND_URL}/api/v1.4" -H "Content-Type: application/json"  -d '{"requestType":"getProjectDueDiligenceReport","userKey":"'${MEND_USER_KEY}'","projectToken":"'${WS_PROJECTTOKEN}'"}'
                fi
                '''
                archiveArtifacts artifacts: "riskreport.pdf, inventoryreport.xlsx, duediligencereport.xlsx, spdxreport.json", fingerprint: true
                }
            }
        }


        stage('Run Mend Code') {
            steps {
                echo 'Start Mend Code Scan'
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
                sh '''
                export repo=$(basename -s .git $(git config --get remote.origin.url))
                export branch=$(git rev-parse --abbrev-ref HEAD)
                ./mend code --non-interactive -s *//${JOB_NAME}//${repo}_${branch}
                '''
                }
            }
        }
    }
}
