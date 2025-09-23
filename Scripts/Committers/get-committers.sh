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
    echo "Please pass a text file to read repositories from such as deduprepos.txt"
    exit
else
    file=$1
    lines=`cat ${file}`
fi

while IFS= read -r line; do
    cd $workdir
    echo "Cloning $line"
    git clone --filter=blob:none --no-checkout $line $workdir/currentrepo

    # Handle error if the repo no longer exists
    if [ $? -ne 0 ]
    then
        echo "[ERROR] Git repository at $line was not cloned"
        printf '%s\n' $line >> $workdir/uncloned.txt
    else
        cd $workdir/currentrepo

        default_ref=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/HEAD)
        # Pull the committers emails based on the $BEGIN_DATE variable
        COMMITTERS=$(git shortlog -sce --since="$BEGIN_DATE" "$default_ref" | sed 's/^ *\([0-9]*\) \(.*\) <\([^>]*\)>$/\3/')
        echo "Found the following committers"
        echo "-----------------"
        printf '%s\n' $COMMITTERS

        # Saves the committers emails to a file for later use
        printf '%s\n' $COMMITTERS >> $workdir/committers.txt

        # Cleans up cloned directory
        cd $workdir && rm -rf $workdir/currentrepo
  fi

done < "$file"
