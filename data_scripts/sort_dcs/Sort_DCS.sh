#!/bin/bash

usage() {
  usage="Usage:
	Sort_DCS.sh <required arguments> [optional arguments]
required arguments
	-i, --inputFile=    :  input file"
  echo "$usage"
}

usageAndExit() {
  usage
  if [[ "$0" =~ Sort_DCS.sh ]]; then
    exit 0
  else
    return 0
  fi
}

# ===| default variable values |================================================

# ===| parse command line options |=============================================
OPTIONS=$(getopt -l "inputFile:help" -o "i:h" -n "Sort_DCS.sh" -- "$@")

if [ $? != 0 ] ; then
  usageAndExit
fi

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    --) shift; break;;
    -i|--inputFile) inputFile=$2; shift 2;;
    -h|--help) usageAndExit;;
     *) echo "Internal error!" ; exit 1 ;;
   esac
done

# ===| check for required arguments |===========================================

# ===| command building and execution |=========================================
# # . ~/.bashrc
if [[ -z "$inputFile" ]]; then
  usageAndExit
fi
echo processs: $inputFile
cmd="root.exe -l -n -q -x ~/alice-tpc-flp-scripts/data_scripts/sort_dcs/Sort_DCS.C+g'(\"$inputFile\")'"
echo "running: $cmd"
eval $cmd
