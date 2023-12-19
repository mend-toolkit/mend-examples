// ******** Mend Unified Agent Template for Jenkins ********
// You may wish to alter this file to override the build tool and the Mend scanning technologies

// You may wish to alter this file to override the build tool and Mend scanning technologies.
//
// For more configuration options, please check the technical documentation portal:
// https://docs.mend.io/bundle/unified_agent/page/getting_started_with_the_unified_agent.html
// https://docs.mend.io/bundle/unified_agent/page/unified_agent_configuration_parameters.html

// ******** Description ********
// The following values should be added as environment variables.
//    WS_APIKEY: the api key found on the integrate tab of the Mend User Interface
//    WS_USERKEY: the user key found under my profile for the user you wish to scan with

pipeline {
  agent any

  environment {
    // update with the Server URL + /agent found on the integrate tab 
    WS_WSS_URL = "https://saas.mend.io/agent"
    WS_PRODUCTNAME = "${JOB_NAME}"
    WS_MAVEN_AGGREGATEMODULES = "true"
    WS_GRADLE_AGGREGATEMODULES = "true"
    WS_SBT_AGGREGATEMODULES = "true"
    WS_OCAML_AGGREGATEMODULES = "true"
    WS_GENERATEPROJECTDETAILSJSON = "true"
    // the following parameter updates the default exclusion to remove binary matching
    WS_EXCLUDES = "**/.*,**/node_modules,**/src/test,**/testdata,**/*sources.jar,**/*javadoc.jar,**/*.jar,**/*.war,**/*.ear,**/*.aar,**/*.dll,**/*.exe,**/*.msi,**/*.nupkg,**/*.egg,**/*.whl,**/*.tar.gz,**/*.gem,**/*.deb,**/*.udeb,**/*.dmg,**/*.drpm,**/*.rpm,**/*.pkg.tar.xz,**/*.apk,**/*.swf,**/*.swc,**/*.air,**/*.apk,**/*.zip,**/*.gzip,**/*.tar.bz2,**/*.tgz"

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
// The Unified Agent scan should be called AFTER a package manager build step such as "mvn clean install -DskipTests=true" or "npm install --only=prod"

    stage('Run Unified Agent') {
      steps {
          sh '''
            if ! command -v java &> /dev/null
            then
              echo "Java is not installed on this system, and is required for a Unified Agent scan"
              exit 1
            else
              echo "Java is installed"
            fi
            echo Downloading Unified Agent
            curl -LJO https://unified-agent.s3.amazonaws.com/wss-unified-agent.jar
            echo Set project name
            export repo=$(basename -s .git $(git config --get remote.origin.url))
            export branch=$(git rev-parse --abbrev-ref HEAD)
            export WS_PROJECTNAME=${repo}_${branch}
            java -jar wss-unified-agent.jar
          '''
          }
        }
    }
    stage('Generate Mend Dependency Reports') {
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
          sh '''
            export WS_PROJECTTOKEN=$(jq -r '.projects | .[] | .projectToken' ./whitesource/scanProjectDetails.json)
            export MEND_URL=$(echo $WS_WSS_URL | awk -F "agent" '{print $1}')
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
          archiveArtifacts artifacts: "riskreport.pdf, inventoryreport.xlsx, duediligencereport.xlsx", fingerprint: true
                }
            }
      }

}

