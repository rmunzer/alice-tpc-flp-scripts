#!/bin/bash

usage() {
  usage="Usage:
	lumi.sh <required arguments> [optional arguments]"

  echo "$usage"
}

usageAndExit() {
  usage
  if [[ "$0" =~ vertex.sh ]]; then
    exit 0
  else
    return 0
  fi
}

# ===| default variable values |================================================


# ===| parse command line options |=============================================
OPTIONS=$(getopt -l "help" -o "h" -n "vdrift.sh" -- "$@")

if [ $? != 0 ] ; then
  usageAndExit
fi

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    --) shift; break;;
    -h|--help) usageAndExit;;
     *) echo "Internal error!" ; exit 1 ;;
   esac
done

# ===| check for required arguments |===========================================

# ===| command building and execution |=========================================
# # . ~/.bashrc

cmd="root.exe -l -n -q -x ~/alice-tpc-flp-scripts/data_scripts/lumi_analysis/Lumi.C+g'()'"
echo "running: $cmd"
eval $cmd
