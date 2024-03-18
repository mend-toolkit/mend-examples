/*
# ******** Mend Unified CLI Kotlin Template for JetBrains TeamCity ********
#
# You may wish to alter this file to override the build tool and Mend scanning technologies.
#
# For more configuration options, please check the technical documentation portal:
# 📚 https://docs.mend.io/bundle/integrations/page/scan_with_the_mend_cli.html
#
# ******** Description ********
# mend dep will automatically use package managers and file system scanning to detect open source components.
# mend code will automatically detect languages and frameworks used in your projects to scan for code weaknesses.
# mend image will scan the local image:tag for open source components and secrets.

# If you are NOT using a service user, and have multiple organizations, don't forget to set the organization in the scope parameter
# The following values should be added as environment variables with email and userKey being secrets
#    MEND_URL: the mend url that you login to - (https://saas.mend.io) for example
#    MEND_EMAIL: the user email for the mend platform account you wish to scan with
#    MEND_USER_KEY: the user key found under my profile for the user you wish to scan with

### Define these General Settings
# Publish Artifacts - even if build fails
# Artifact paths - %env.HOME%/.mend/logs => mend

### Add a custom report tab - https://www.jetbrains.com/help/teamcity/including-third-party-reports-in-the-build-results.html
### Edit the project and add a new build report tab on the project named Mend SCA Results
### Set Start Page as mend/riskreport.pdf
### In Administration -> Global Settings update the Artifacts URL to serve build aritfacts from - https://www.jetbrains.com/help/teamcity/2023.11/?TeamCity+Configuration+and+Maintenance#artifacts-url
### An insecure solution would be to disable isolation protection to see if your artifact is displaying in the reports tab

# The mend dep scan should be called AFTER a package manager build step such as "mvn clean install -DskipTests=true" or "npm install --only=prod"

## Many Team City runners do not have access to /usr/local/bin which the recommended download for the CLI according to the documentation, use %env.HOME% instead
## Package managers are not always available on the PATH due to default Team City installations methods - https://youtrack.jetbrains.com/issue/TW-67369/Default-Maven-is-not-available-in-Command-Line-build-i.e.-mvn-command-not-found
*/
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
            name = "CloneAndBuildRepo"
            id = "CloneAndBuildRepo"
            scriptContent = """
				//Replace with Repo URL and build steps
                git clone <Repo URL>
                npm install
            """.trimIndent()
        }
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