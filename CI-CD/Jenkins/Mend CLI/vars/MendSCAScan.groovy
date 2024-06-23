def call() { 
      echo 'Run Mend dependencies scan'
      catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
            sh '''
            export repo=$(basename -s .git $(git config --get remote.origin.url))
            export branch=$(git rev-parse --abbrev-ref HEAD)
            ./mend dep -u -s "*//${JOB_NAME}//${repo}_${branch} --fail-policy" --non-interactive --export-results dep-results.txt
            if [[ "$dep_exit" == "9" ]]; then
                  echo "[warning]  Dependency scan policy violation"
            else
                  echo "No policy violations found in dependencies scan"
            fi          
            '''
      }
      archiveArtifacts artifacts: "dep-results.txt", fingerprint: true

}
