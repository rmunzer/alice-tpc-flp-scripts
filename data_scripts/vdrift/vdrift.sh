#!/bin/bash

usage() {
  usage="Usage:
preparePedestalFiles.sh <required arguments> [optional arguments]

required arguments
-i, --inputRun=    :  input run

optional arguments:
-o, --outputDir=          : set output directory for (default: ./)"
  echo "$usage"
}

usageAndExit() {
  usage
  if [[ "$0" =~ preparePedestalFiles.sh ]]; then
    exit 0
  else
    return 0
  fi
}

# ===| default variable values |================================================
inputRun=543437
outRun=

# ===| parse command line options |=============================================
OPTIONS=$(getopt -l "inputRun:,outputDir:,help" -o "i:o:h" -n "vdrift.sh" -- "$@")

if [ $? != 0 ] ; then
  usageAndExit
fi

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    --) shift; break;;
    -i|--inputFile) inputRun=$2; shift 2;;
    -o|--outputDir) outRun=$2; shift 2;;
    -h|--help) usageAndExit;;
     *) echo "Internal error!" ; exit 1 ;;
   esac
done

# ===| check for required arguments |===========================================
if [[ -z "$inputFile" ]]; then
  usageAndExit
fi

# ===| command building and execution |=========================================
cmd="root.exe -l -n -x drawVDTgl.C+g'($inputRun)'"
echo "running: $cmd"
eval $cmd
