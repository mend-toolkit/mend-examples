pipeline {
  agent any

  environment {
       WS_APIKEY = "${APIKEY}" //Taken from Jenkins Global Environment Variables 
       WS_WSS_URL = "${WSURL}" //Taken from Jenkins Global Environment Variables
       WS_USERKEY = "${USERKEY}" //Taken from Jenkins Global Environment Variables
       WS_PRODUCTNAME = "Jenkins_Pipeline"
       WS_PROJECTNAME = "${JOB_NAME}"
       WS_FILESYSTEMSCAN = false
   }
// Add your build tool, clone & build step (maven example shown below)
  tools {
    maven "mvn_3.6.3"
  }

  stages {

    stage('Cloning Git') {
      steps {
        git 'https://github.com/someorg/java_repo.git'
      }
    }

    stage('Install dependencies') {
      steps {
        sh 'mvn clean install -DskipTests'
      }
    }
// end maven example
// The Unified Agent scan should be called AFTER a package manager build step such as "mvn clean install -DskipTests=true" or "npm install --only=prod"

    stage('Download Mend Script') {
      steps {
              script {
                    echo "Downloading Mend Unified Agent and Checking Integrity"
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
                       
    stage('Run Mend Script') {
      steps { 
        sh 'java -jar wss-unified-agent.jar'
      }
    }
  }
} 
