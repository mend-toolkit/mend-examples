def call() { 
   echo 'Start Mend Code Scan'
   catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
      sh '''
      export repo=$(basename -s .git $(git config --get remote.origin.url))
      export branch=$(git rev-parse --abbrev-ref HEAD)
      ./mend code --non-interactive -s *//${JOB_NAME}//${repo}_${branch}
      '''
 }
}
