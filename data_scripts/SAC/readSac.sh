#!/bin/bash

#usage() {
#  usage="Usage:
#readSac.sh  [optional arguments]
#
#required arguments

#optional arguments:
#-o, --outputDir=          : set output directory for (default: ./)
#
#  echo "$usage"
#}

usageAndExit() {
  usage
  if [[ "$0" =~ preparePedestalFiles.sh ]]; then
    exit 0
  else
    return 0
  fi
}

# ===| default variable values |================================================
outputDir="./"

# ===| parse command line options |=============================================
#OPTIONS=$(getopt -l "outputDir:" -o "o" -n "readSac.sh" -- "$@")

if [ $? != 0 ] ; then
  usageAndExit
fi

#eval set -- "$OPTIONS"



# ===| check for required arguments |===========================================
if [[ -z "$inputFile" ]]; then
  usageAndExit
fi

# ===| command building and execution |=========================================
cmd="root.exe -b -q -l -n -x ./src/loadSACs.C"
echo "running: $cmd"
eval $cmd
