def call() { 
      echo 'Downloading Mend CLI'
      sh 'curl -LJO https://downloads.mend.io/production/unified/latest/linux_amd64/mend && chmod +x mend'
}
