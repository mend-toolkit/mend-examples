SCM=https://github.com
if [ -z "$1" ]
then
    echo "Please pass a text file to read repositories from such as repos.txt"
    exit
else
    file=$1
    lines=`cat ${file}`
fi

for line in $lines; do
    # Removes @branchname from repoFullName results and replaces with .git
    url=$(echo "$line" | sed 's|@.*|.git|')
    
    # Adds the $SCM variable as a prefix to repoFullName results
    if [[ ! $url =~ ^https:// ]]; then
        url="$SCM/$url"
    fi
        printf '%s\n' $url  >> urlfix.txt

done

awk '!seen[$0]++' urlfix.txt >> deduprepos.txt
rm urlfix.txt