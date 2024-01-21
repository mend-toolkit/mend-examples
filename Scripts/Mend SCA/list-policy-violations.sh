#!/bin/bash

# NOTE: It is currently recommended to use the MEND CLI over the Mend Unified Agent.
# The Mend CLI will automatically list policy violations, and so with that utility
# this script is not required.
#
# ******** Mend Script to List Policy Violations after a Unified Agent Scan ********
# 
# Users should edit this file to change the behavior of the script as needed.
#
# ******** Description ********
# This script parses the policyRejectionSummary.json file, following a Mend Unified Agent scan, and prints to the stdout the policies
# that where violated, as well as the libraries that violated them.
# The policyRejectionSummary.json file is created automatically under the agent log directory (./whitesource) during a scan that's configured
# to check policies. Every policy check overwrites this file, so this list is always specific to the last scan (that had policy check enabled).

# Prerequisites:
# apt install jq
# WS_CHECKPOLICIES: true
# MEND_PRODUCTNAME: <product_name>
# MEND_PROJECTNAME: <project_name>

jsonFile="./whitesource/policyRejectionSummary.json"

ShowLibSystemPath=false
if [[ "$1" =~ ^(--includePath|-p)$ ]] ; then
    ShowLibSystemPath=true
fi

echo ""
echo "Mend Policy Violations"
echo "============================="
if [[ ! -f $jsonFile ]] ; then
    echo "[ERROR] File not found: $jsonFile"
    echo "Make sure to specify the correct working directory and that the last agent scan had WS_CHECKPOLICIES=true"
    exit
fi

if [[ -v WS_PRODUCTNAME ]]; then echo "Product: $WS_PRODUCTNAME" ; fi
if [[ -v WS_PROJECTNAME ]]; then echo "Product: $WS_PROJECTNAME" ; fi

libCount="$(cat $jsonFile | jq -r '.summary.totalRejectedLibraries')"
if (($libCount == 0)) ; then
    echo "All dependencies conform with open source policies."
    echo ""
    exit
fi
echo "Total Rejected Libraries: $libCount"
echo ""

cat $jsonFile | jq -c '.rejectingPolicies[]' | while read oPolicy; do
    for policy in "${oPolicy[@]}" ; do
        echo "Policy Name: $(echo "${policy//\\/\\\\}" | jq -r '(.policyName)')"
        echo "Policy Type: $(echo "${policy//\\/\\\\}" | jq -r '(.filterType)')"
        echo "Rejected Libraries:"
        if $ShowLibSystemPath ; then
            echo "$(echo "${policy//\\/\\\\}" | jq -r '.rejectedLibraries[] | ("  " + .name + "  (" + .systemPath + ")")')"
        else
            echo "$(echo "${policy//\\/\\\\}" | jq -r '.rejectedLibraries[] | ("  " + .name)')"
        fi
        echo ""
    done
done
