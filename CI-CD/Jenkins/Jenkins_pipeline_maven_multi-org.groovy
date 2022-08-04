pipeline {
    agent any

    environment {
       WS_WSS_URL = "${WSURL}" //Taken from Jenkins Global Environment Variables
       WS_PRODUCTNAME = "Jenkins_Pipeline"
       WS_PROJECTNAME = "${JOB_NAME}"
       WS_PRODUCTION_BRANCH = "main"
    }

    tools {
        // Install the Maven version configured as "M3" and add it to the path.
        maven "M3"
    }

    stages {
        stage('Build') {
            steps {
                // Get some code from a GitHub repository
                git 'https://github.com/k-tamura/easybuggy.git'

                // Run Maven on a Unix agent.
                sh "mvn -Dmaven.test.failure.ignore=true clean package"
            }
        }
        
        stage('Set Result Environment') {
            steps {
                script {
                    //get the branch information from Git
                    GIT_COMMIT_BRANCH = sh (script:"git branch | grep \\* | cut -d ' ' -f2",,returnStdout:true).trim()

                    if ( "${WS_PRODUCTION_BRANCH}" == "${GIT_COMMIT_BRANCH}" ) {
                            echo "Working in the production branch"
                            WORKING_USERKEY = "${USERKEY}"
                            WORKING_APIKEY = "${APIKEY}"
                        } else {
                            echo "Working in the dev branch"
                            WORKING_USERKEY = "${DEV_USERKEY}"
                            WORKING_APIKEY = "${DEV_APIKEY}"
                        }
                }
            }
        }   
        
        stage('Download WS Script') {
          steps {
              script {
                    echo "Downloading WhiteSource Unified Agent and Checking Integrity"
                    sh 'curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar'
                    ua_jar_checksum=sh(returnStdout: true, script: "sha256sum 'wss-unified-agent.jar'")
                    ua_integrity_file=sh(returnStdout: true, script: "curl -sL https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar.sha256")
                    if ("${ua_integrity_file}" == "${ua_jar_checksum}") {
                        echo "Integrity Check Passed"
                    } else {
                        echo "Integrity Check Failed"
                        }
                  }
             }
        }
        
        stage('Run WS Script') {
             steps { 
               script {
                   withEnv(["WS_USERKEY=${WORKING_USERKEY}", "WS_APIKEY=${WORKING_APIKEY}", "WS_PROJECTNAME=${JOB_NAME}-${GIT_COMMIT_BRANCH}"]) {
                   sh 'java -jar wss-unified-agent.jar'
                   }
               }
          }
        }            
    }
}

