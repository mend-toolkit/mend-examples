object Mend_CLITemplate : Template({
    name = "MendCLITemplate"

    params {
        param("env.MEND_URL", "https://saas.mend.io")
        param("env.HOME", "/home/teamcity/agent")
        param("env.MEND_EMAIL", "")
        param("env.MEND_USER_KEY", "")
    }

    steps {
        script {
            name = "DownloadMendCLI"
            id = "DownloadMendCLI"
            scriptContent = """
                echo "Downloading Mend CLI"
                curl https://downloads.mend.io/cli/linux_amd64/mend -o %env.HOME%/mend && chmod +x %env.HOME%/mend
            """.trimIndent()
        }
        script {
            name = "MendSCASCAN"
            id = "MendSCASCAN"
            scriptContent = """
                echo "Run Mend dependencies scan"
                echo "Clean Up Logs if using a persisent runner"
                rm -rf %env.HOME%/.mend/logs
                ${'$'}HOME/mend dep -u --export-results dep-results.txt
            """.trimIndent()
        }
        script {
            name = "MendSCAReport"
            id = "MendSCAReport"
            scriptContent = """
                ### Collect projectToken and download riskreport
                export WS_PROJECTTOKEN=${'$'}(grep -oP "(?<=token=)[^&]+" ./dep-results.txt)
                curl -o %env.HOME%/.mend/logs/riskreport.pdf -X POST "${'$'}{MEND_URL}/api/v1.4" -H "Content-Type: application/json" \
                -d '{"requestType":"getProjectRiskReport","userKey":"'${'$'}{MEND_USER_KEY}'","projectToken":"'${'$'}{WS_PROJECTTOKEN}'"}'
            """.trimIndent()
        }
        script {
            name = "MendSASTScan"
            id = "MendSASTScan"
            scriptContent = """
                echo "Run Mend code scan"
                ${'$'}HOME/mend code
            """.trimIndent()
        }
    }
})