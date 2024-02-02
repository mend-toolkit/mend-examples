#!/bin/bash
#
# ******** Mend Script to clone git repositories and obtain committer data ********

# ******** Description ********
# This script clones git repositories from a text file and then runs a git command to determine what email addresses committed to the codebase within the last year
#
# Prerequisites:
# apt install -y git sed

# Login with git credentials

# Update with your desired date to start from
BEGIN_DATE="01 Jan 2023"
# Update with your desired source control manager prefix
SCM=https://github.com
workdir=$PWD

if [ -z "$1" ]
then
    echo "Please pass a text file to read repositories from such as repos.txt"
    exit
else
    file=$1
    lines=`cat ${file}`
fi

for line in $lines; do
    cd $workdir
    # Removes @branchname from repoFullName results and replaces with .git
    url=$(echo "$line" | sed 's|@.*|.git|')
    
    # Adds the $SCM variable as a prefix to repoFullName results
    if [[ ! $url =~ ^https:// ]]; then
        url="$SCM/$url"
    fi
    echo "Cloning $url"
    git clone $url $workdir/currentrepo

    # Handle error if the repo no longer exists
    if [ $? -ne 0 ]
    then
        echo "[ERROR] Git repository at $url was not cloned"
    else
        cd $workdir/currentrepo

        # Pull the committers emails based on the $BEGIN_DATE variable
        COMMITTERS=$(git shortlog -sce --since="$BEGIN_DATE" | sed 's/^ *\([0-9]*\) \(.*\) <\([^>]*\)>$/\3/')
        echo "Found the following committers"
        echo "-----------------"
        printf '%s\n' $COMMITTERS

        # Saves the committers emails to a file for later use
        printf '%s\n' $COMMITTERS >> $workdir/committers.txt

        # Cleans up cloned directory
        cd $workdir && rm -rf $workdir/currentrepo
    fi

done

# Optional filter to remove blank lines and noreply@github.com results
# grep -v "noreply@github.com" committers.txt | sed '/^$/d' > committers_filtered.txt

# The following command gives a quick line count for spot checking
# wc -l committers_filtered.txt