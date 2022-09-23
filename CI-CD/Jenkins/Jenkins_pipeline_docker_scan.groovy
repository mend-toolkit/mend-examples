pipeline {
  agent any

  environment {
       WS_APIKEY = "${APIKEY}" //Taken from Jenkins Global Environment Variables 
       WS_WSS_URL = "${WSURL}" //Taken from Jenkins Global Environment Variables
       WS_USERKEY = "${USERKEY}" //Taken from Jenkins Global Environment Variables
       WS_PRODUCTNAME = "Jenkins_Pipeline"
       WS_PROJECTNAME = "${JOB_NAME}"
       myImage = "myImage"
  }

  tools {
    maven "mvn_3.6.3"
  }

  stages {

    stage('Some docker build') {
      steps {
        sh 'docker build -t ${myImage} .'
      }
    }

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
      environment{
        /*
        The following command uses the image name provided in the environment section and provides its Image ID.
        This is the image ID which will be scanned be Mend in case having multiple images with same prefix.
        */
            WS_DOCKER_INCLUDES = 
            """
            #!/bin/bash
            docker images --filter=reference="${myImage}" -q
            """
            ).trim()
            WS_DOCKER_SCANIMAGES = true
            WS_DOCKER_LAYERS = true
            WS_DOCKER_PROJECTNAMEFORMAT = repositoryNameAndTag
            WS_ARCHIVEEXTRACTIONDEPTH = 2
            WS_ARCHIVEINCLUDES = '**/*war **/*ear **/*zip **/*whl **/*tar.gz **/*tgz **/*tar **/*car **/*jar'
        }
      steps {
        sh 'java -jar wss-unified-agent.jar'
      }
    }
  }
}
