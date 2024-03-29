#!/bin/bash

usage() {
  usage="Usage:
noise.sh <required arguments> [optional arguments]

required arguments
-n, --num=    :  numerator  entry
-d, --den=    :  denominator entry
optional arguments:
-t, --tit=    : Histrogram Title
    --ymin=   : Histrogram ymin
    --ymax=   : Histrogram ymax
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
num=1693995797848
den=1674571888676 # 2023 Winter reference February
den=1693373840983
tit="Pulser HV on (Nominal) / Pulser HV 50%"
ymin=0.95
ymax=1.05

# ===| parse command line options |=============================================
OPTIONS=$(getopt -l "num:,den:,tit:,ymin:,ymax:help" -o "n:d:t:" -n "noise.sh" -- "$@")

if [ $? != 0 ] ; then
  usageAndExit
fi

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    --) shift; break;;
    -n|--num) num=$2; shift 2;;
    -d|--den) den=$2; shift 2;;
    -t|--tit) tit=$2; shift 2;;    
    -h|--help) usageAndExit;;
     *) echo "Internal error! #" ; exit 1 ;;
   esac
done

# ===| check for required arguments |===========================================
if [[ -z "$inputFile" ]]; then
  usageAndExit
fi

# ===| command building and execution |=========================================
cmd="root.exe -l -n -x ./pulserRatioCCDB.C++g'($num,$den,\"${tit}\", $ymin,$ymax, \"Pulser\", \"Pulser\",false,\"https://alice-ccdb.cern.ch\")' "

echo "running: $cmd"
eval $cmd
