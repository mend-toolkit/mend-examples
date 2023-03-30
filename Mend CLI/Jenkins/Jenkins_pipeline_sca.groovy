pipeline {
  agent any

  environment {
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
        sh 'mvn clean install -DskipTests'
      }
    }

    stage('Download Mend CLI') {
      steps {
        script {
          echo "Downloading Mend CLI"
          sh 'curl -LJO https://downloads.mend.io/production/unified/latest/linux_amd64/mend && chmod +x mend'
        }
      }
    }

    stage('Run Mend CLI') {
      steps {
        echo "Start Mend SCA Scan"
        sh './mend sca -u'
      }
    }
  }
}