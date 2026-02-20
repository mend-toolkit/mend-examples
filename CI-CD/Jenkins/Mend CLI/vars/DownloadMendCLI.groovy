def call() { 
      echo 'Downloading Mend CLI'
      sh 'curl -LJO https://downloads.mend.io/cli/linux_amd64/mend && chmod +x mend'
}
