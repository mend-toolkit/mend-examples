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
                sh './mend deps -u --no-color'
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