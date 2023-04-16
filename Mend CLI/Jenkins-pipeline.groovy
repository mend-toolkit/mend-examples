// ******** Mend Unified CLI Template for Azure DevOps ********
// You may wish to alter this file to override the build tool and the Mend scanning technologies used (SCA, SAST or Conatiner).

// For more configeration options, please check the technical documentation portal:
// 📚 https://docs.mend.io/bundle/cli/page/scan_with_mend_s_unified_cli.html

// ******** Description ********
// Mend SCA will automatically use package managers and file system scanning to detect open source components. 
// Mend SAST will automatically detect languages and frameworks used in your projects to scan for code weaknesses.
// Mend Containers will automatically pull the container defined and scan for open source components. 

pipeline {
    agent any

    environment {
        // SCA and Container Environment Variables
        MEND_EMAIL = "${MEND_SCA_EMAIL}"
        MEND_USER_KEY = "${MEND_SCA_USERKEY}"
        MEND_URL = "https://saas.mend.io"
        // SAST Environment Variables
        MEND_SAST_SERVER_URL = "https://saas.mend.io/sast"
        MEND_SAST_API_TOKEN = "${MEND_SAST_API}"
        MEND_SAST_ORGANIZATION = "${MEND_SAST_ORGANIZATION}"
    }

    tools {
        maven 'mvn_3.6.3'
        jdk 'jdk8'
    }

    stages {
        stage('Cloning Git') {
            steps {
                git branch: 'main', changelog: false, poll: false, url: 'https://github.com/someOrg/someRepo'
            }
        }

        stage('Install dependencies') {
            steps {
            // sh 'mvn clean install -DskipTests'
            // sh 'npm install'
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

        stage('Run Mend CLI') {
            steps {
                echo 'Start Mend SCA Scan'
                sh './mend sca -u'
                echo 'Start Mend SAST Scan'
                sh './mend sast'
                echo 'Start Mend Container Scan'
                sh './mend image ubuntu:22.10'
            }
        }
    }
}
