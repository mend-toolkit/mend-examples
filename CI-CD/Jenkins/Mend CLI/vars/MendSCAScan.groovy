def call(Map args = [:]) { 
    boolean reachability = args.get('reachability', false)
    echo 'Run Mend dependencies scan'

    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
        def reachabilityFlag = reachability ? "-r" : ""

        sh """
        export repo=\$(basename -s .git \$(git config --get remote.origin.url))
        export branch=\$(git rev-parse --abbrev-ref HEAD)

        ./mend dep -u ${reachabilityFlag} -s "*//\${JOB_NAME}//\${repo}_\${branch}" --fail-policy --non-interactive --export-results dep-results.txt
        
        dep_exit=\$?
        if [[ "\$dep_exit" == "9" ]]; then
            echo "[warning] Dependency scan policy violation"
        else
            echo "No policy violations found in dependencies scan"
        fi
        """
    }
    archiveArtifacts artifacts: "dep-results.txt", fingerprint: true
}
