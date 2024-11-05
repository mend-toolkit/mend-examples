// ******** Mend Unified CLI Template for Jenkins ********
// You may wish to alter this file to override the build tool and the Mend scanning technologies

//This pipeline utilizes shared libraries to make it easier to implement Mend into several pipelines.
//For more information on shared libraries, please check the official Jenkins documentation:
// 📚 https://www.jenkins.io/doc/book/pipeline/shared-libraries/

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

//update with the name of your shared library
@Library("my-shared-library") _
pipeline {
    agent any

    environment {
        MEND_SAST_THRESHOLD_ONLY_NEW = "true"
        // Set diff thresholds from the base scan
        // MEND_SAST_THRESHOLD_HIGH = 1
        // MEND_SAST_THRESHOLD_MEDIUM = 1
        // MEND_SAST_THRESHOLD_LOW = 1

        // update with the Server URL found on the integrate tab
        MEND_URL = 'https://saas.mend.io'
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
               DownloadMendCLI()
            }
        }
        
        stage('Run Mend SCA') {
            steps {
                echo "SCA Reachability enabled"
                MendSCAScan(reachability: true)
                echo "SCA Reachability disabled"
                MendSCAScan(reachability: false)
            }
        }
        stage('Run SCA Reports') {
            steps {
               GenerateSCAReports()
            }
        }
        stage('Run SAST Scan') {
            steps {
               MendSASTScan()
            }
        }
    }
}
