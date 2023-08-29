// ******** Mend Unified CLI Template for Jenkins ********
// You may wish to alter this file to override the build tool and Mend scanning technologies.
//
// For more configuration options, please check the technical documentation portal:
// https://docs.mend.io/bundle/integrations/page/scan_with_the_mend_cli.html
//
// ******** Description ********
// mend dep will automatically use package managers and file system scanning to detect open source components.
// mend code will automatically detect languages and frameworks used in your projects to scan for code weaknesses.

// If you are NOT using a service user, and have multiple organizations, don't forget to scall the scope -s parameter to set the organization

pipeline {
    agent any

    environment {
        // Authentication Variables
        MEND_EMAIL = "${MEND_SCA_EMAIL}"
        MEND_USER_KEY = "${MEND_SCA_USERKEY}"
        MEND_URL = "https://saas.mend.io"
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
                    sh 'curl https://downloads.mend.io/cli/linux_amd64/mend -o /usr/local/bin/mend && chmod +x /usr/local/bin/mend'
                }
            }
        }

        stage('Run Mend CLI') {
            steps {
                echo 'Run Mend Dependency (SCA) Scan'
                sh 'mend dep -u --no-color'
                echo 'Run Mend code (SAST) Scan'
                sh 'mend code --no-color'
            }
        }
    }
}
