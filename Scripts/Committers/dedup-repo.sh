#!/bin/bash
if [ -z "$SCM" ]
then
    echo "Please export the SCM variable with your source control prefix such as https://github.com"
    exit
else
    file=$1
    lines=`cat ${file}`
fi

if [ -z "$1" ]
then
    echo "Please pass a text file to read repositories from such as repos.txt"
    exit
else
    file=$1
    lines=`cat ${file}`
fi

: > urlfix.txt
: > deduprepos.txt

#for line in "$lines"; do
while IFS= read -r line; do

    # Strip @branch part if present
    url=$(printf '%s' "$line" | sed 's|@.*||')
    
    # Add .git only if not already present
    if [[ ! "$url" =~ \.git$ ]]; then
      url="${url}.git"
    fi
    
    # Adds the $SCM variable as a prefix to repoFullName results
    if [[ ! $url =~ ^https:// ]]; then
        url="$SCM/$url"
    fi
       
        
   # Azure-specific handling
  if [[ "$SCM" == *"azure"* ]]; then
    repo_path="${url#"$SCM"/}"
    slash_count=$(grep -o "/" <<< "$repo_path" | wc -l)
    if [[ $slash_count -eq 1 ]]; then
      org="${repo_path%%/*}"
      repo="${repo_path#*/}"
      url="${SCM%/}/$org/_git/$repo"
    fi
  fi
  
   printf '%s\n' "$url"  >> urlfix.txt

done < "$file"

awk '!seen[$0]++' urlfix.txt >> deduprepos.txt
rm urlfix.txt