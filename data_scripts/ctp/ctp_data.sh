#!/bin/bash

usage() {
  usage="Usage:
noise.sh <required arguments> [optional arguments]

required arguments
-r ,--run =    :  Runnumber
-f ,--fill =   :  Fillnumber
-t : Test
optional arguments:
-h,--help : Show this help
"
  echo "$usage"
}

usageAndExit() {
  usage
  if [[ "$0" =~ drawPulser.sh ]]; then
    exit 0
  else
    return 0
  fi
}

# ===| default variable values |================================================
#num=1698605174847
run=545367
fill=9319
test=1

# ===| parse command line options |=============================================
OPTIONS=$(getopt -l "run:,fill:,help" -o "r:f:,th" -n "ctp_data.sh" -- "$@")

if [ $? != 0 ] ; then
  usageAndExit
fi

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    --) shift; break;;
    -r|--run) run=$2; shift 2;;
    -f|--fill) fill=$2; shift 2;;
    -t) test=true; shift 1;;
    -h|--help) usageAndExit;;
     *) echo "Internal error! #" ; exit 1 ;;
   esac
done

# ===| check for required arguments |===========================================
if [[ -z "$run" ]]; then
  usageAndExit
fi

# ===| command building and execution |=========================================
cmd="root.exe -l -n -q -x ~/tpc_flp_scripts/data_scripts/ctp/GetScalersForRun.C++sk'($run,$fill,1)'"

echo "running: $cmd"
eval $cmd
