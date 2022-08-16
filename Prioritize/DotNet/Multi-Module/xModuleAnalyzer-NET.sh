#!/bin/bash
# Modify SEARCHDIR & RELEASEDIR before running in pipeline
SEARCHDIR=$(pwd)
RELEASEDIR='/bin/'

# Finds all the .csproject file in the SEARCHDIR excluding names with build, test, host, & migration
for csproject in  $(find $SEARCHDIR -type f \( -wholename "*.csproj" ! -wholename "*build*" ! -wholename "*test*" ! -wholename "*host*" ! -wholename "*migration*" \))
do
# For each .csproject found it takes the basename
# example: fastapp.csproject becomes fastapp
echo "Found" $csproject 
CSPROJ=$(basename $csproject .csproj)
# For each basename of the .csproject, find a dll with the same name in the release directory excluding names with build, test, host, & migration
find ./ -type f \( -wholename "$RELEASEDIR$CSPROJ.dll" ! -wholename "*build*" ! -wholename "*test*" ! -wholename "*host*" ! -wholename "*migration*" \) -print >> multi-module.txt
done

# Writes all the found .dlls to a multi-module.txt file in the same directory 
file="./multi-module.txt"
dlls=`cat $file`

for DLL in $dlls;
do
# For each dll in the above list, print out the variables that will be used for the prioritize scan
echo "appPath:" $DLL
DIR="$(echo "$DLL" | awk -F "$RELEASEDIR" '{print $1}')"
echo "directory:" $DIR
PROJECT=$(basename $DLL .dll)
echo "PROJECT:" $PROJECT
# Run a WSS prioritize scan for each DLL in the multi-module.txt file
java -jar wss-unified-agent.jar -appPath "$DLL" -d "$DIR" -project "$PROJECT"
done
