def call(Map args = [:]) { 
    boolean reachability = args.get('reachability', false)
    echo 'Run Mend dependencies scan'

    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
        def reachabilityFlag = reachability ? "-r" : ""

        sh """
        export repo=\$(basename -s .git \$(git config --get remote.origin.url))
        export branch=\$(git rev-parse --abbrev-ref HEAD)
        ./mend dep -u ${reachabilityFlag} -s "*//\${JOB_NAME}//\${repo}_\${branch}" --fail-policy --non-interactive --export-results dep-results.txt
        """
    }
    archiveArtifacts artifacts: "dep-results.txt", fingerprint: true
}
