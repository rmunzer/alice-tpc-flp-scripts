#!/bin/bash
# =========================================================================
# Get summary of ALICE runs from BKP
#
# Author: R.Divia`, CERN/ALICE
# Version: v1 13/06/2023
# =========================================================================
# Temporary files used to cache the detailed data
DATA="/tmp/`basename $0`.$$"

# List of ALICE detectors
# DETS="CPV EMC FDD FT0 FV0 HMP ITS MCH MFT MID PHS TOF TPC TRD TST ZDC"
DETS="CPV EMC FDD FT0 FV0 HMP ITS MCH MFT MID PHS TOF TPC TRD ZDC"

# Separator for the CSV output
SEP_CSV=","
SEP="|"

# =========================================================================
usage() {
   printf "Usage: %s [OPTION...]\n" "`basename $0`"
   printf "   -d     \tDebug\n"
   printf "   -F FillNo\tNumber of the fill\n"
   printf "   -s selection\tfields selection (comma-separated)\n"
}

dbg=0
fillNo=0
selection=""
while getopts F:s:dh? flag; do
   case "${flag}" in
      F) fillNo="${OPTARG}";;
      d) dbg=1;;
      s) selection="${OPTARG}";;
      h|*) usage; exit 1;;
   esac
done

if (( dbg )); then
   printf "`basename $0` starting\t"
   printf "\tfrom:'%s' to:'%s' fillNo:'%d'\n" "${from}" "${to}" "${fillNo}"
fi >&2

O=""
if [ "${from}${to}" ]; then
   O=""
fi

if (( fillNo > 0 )); then
   O="filter[fillNumbers]=${fillNo}"   
fi
URL="https://ali-bookkeeping.cern.ch/api/lhcFills/$fillNo"
hostname=`hostname`
if [[ $hostname == *"alio2-cr1"* ]]; then
	echo "Run internally"
	declare -x http_proxy="10.161.69.44:8080"
	declare -x https_proxy="10.161.69.44:8080"
	echo wget -q "${URL}" --no-check-certificate -O ${DATA}
	wget -q "${URL}" --no-check-certificate -O ${DATA}
	declare -x http_proxy=""
	declare -x https_proxy=""
else
	echo "Run externally"
	wget -q "${URL}"  -O ${DATA}
fi



#(( dbg )) && 
#printf "URL:\"%s\"\n" "${URL}" >&2

#wget -q "${URL}" -O ${DATA}

LINE+=$(printf "Fill Number${SEP}")
LINE+=$(printf "O2 start${SEP}")
LINE+=$(printf "O2 end${SEP}")
LINE+=$(printf "Start time${SEP}")
LINE+=$(printf "End time${SEP}")
LINE+=$(printf "TRG start${SEP}")
LINE+=$(printf "TRG end${SEP}")
LINE+=$(printf "Run duration${SEP}")
LINE+=$(printf "Env ID${SEP}")
LINE+=$(printf "Run type${SEP}")
LINE+=$(printf "Definition${SEP}")
LINE+=$(printf "Run quality${SEP}")
LINE+=$(printf "Fill #${SEP}")
LINE+=$(printf "Stable Beams duration${SEP}")
LINE+=$(printf "Period${SEP}")
LINE+=$(printf "PDP workflow parameters${SEP}")
LINE+=$(printf "EOR reasons(s)${SEP}")
LINE+=$(printf "# Detectors${SEP}")
LINE+=$(printf "# FLPs${SEP}")
LINE+=$(printf "# EPNs${SEP}")
LINE+=$(printf "TF File Size${SEP}")
LINE+=$(printf "CTF File Size${SEP}")
for d in ${DETS}; do
   LINE+=$(printf "$d IN${SEP}")
done
LINE+=$(printf "\n")

if [ x"$selection" = "x" ]; then
    echo $LINE | tr "$SEP" "${SEP_CSV}"
else
    echo $LINE | cut -d"$SEP" -f $selection | tr "$SEP" "${SEP_CSV}"
fi

LINE=""

RUNS="`jq .data.runs[].runNumber ${DATA}`"
echo $RUNS
NRUNS=$(( `echo "${RUNS}" | wc -l` ))
if (( NRUNS > 998 )); then
   echo "Too many runs, please reduce the time range" >&2
   exit 1
fi

sanitize() {
   printf "%s" "$*" | tr "${SEP}" "_"
}

isNum() {
  [ "$*" != "" -a "${*//[0-9]/}" = "" ]
}

timeToDate() {
   local t=$(($* / 1000))
   (( t > 0 )) && printf "%s" "`date --date "@$t" +'%m/%d/%Y %T'`"
}

printNum() {
   [ "$*" != "null" ] && printf "%s" "$*" | tr -d "\""
   [ "$*" = "null" ] && printf "0"
   printf "${SEP}"
}

printStr() {
   printf "%s" "$*" | tr -d "\""
   printf "${SEP}"
}

LINE+=$(printNum $(jq ".data.fillNumber" ${DATA}))

#jq ".data.stableBeamsStart" ${DATA}
sbStart=$(jq ".data.stableBeamsStart" ${DATA})
sbEnd=$(jq ".data.stableBeamsEnd" ${DATA})
LINE+=$(timeToDate $sbStart)

sbDuration=$(jq ".data.stableBeamsDuration" ${DATA})

echo $LINE
echo $sbDuration
printf '%02d:%02d:%02d\n' $((sbDuration/3600)) $((sbDuration%3600/60)) $((sbDuration%60))

nGood=0
goodDuration=0
goodStart=0
goodEnd=0

#echo ${NRUNS}

n=-1
for runNumber in ${RUNS}; do
   n=$((n+1))
   
   curRun=$(jq .data.runs[$n].runNumber ${DATA})

   echo "$n  $curRun  $runNumber"
   
   if (( curRun != runNumber )); then
     printf "Run number mismatch, fatal error\n" >&2
     exit 1
   fi

   runDefinition=$(jq .data.runs[$n].definition ${DATA} | tr -d "\"")
   (( dbg )) && echo "$runDefinition" >&2
   if [ x"$runDefinition" != "xPHYSICS" ]; then
      continue;
   fi

   runQuality=$(jq .data.runs[$n].runQuality ${DATA} | tr -d "\"")
   (( dbg )) && echo "$runQuality" >&2
   if [ x"$runQuality" != "xgood" ]; then
      continue;
   fi

   nGood=$((nGood+1))

   runDuration=$(jq .data.runs[$n].runDuration ${DATA})
   runDurationSec=$((runDuration/1000))
   goodDuration=$((goodDuration+runDuration))

   printf '%02d  %06d  %08d  %02d:%02d:%02d\n' $n $runNumber $runDurationSec $((runDurationSec/3600)) $((runDurationSec%3600/60)) $((runDurationSec%60))

   if (( goodStart == 0 )); then
      goodStart=$(jq .data.runs[$n].timeTrgStart ${DATA})
   fi

   goodEnd=$(jq .data.runs[$n].timeTrgEnd ${DATA})

done

lossEnd=0
if (( goodEnd > sbEnd )); then
   goodDuration=$((goodDuration+sbEnd-goodEnd))
else
   lossEnd=$((sbEnd-goodEnd))
fi

effEnd=$(echo "scale=2; $lossEnd/$sbDuration/10" | bc -l)


meanDuration=$((goodDuration/nGood))
meanDurationSec=$((meanDuration/1000))
echo $meanDuration
meanDurationPerc=$(echo "scale=2; $meanDuration/$sbDuration/10" | bc -l)

goodDurationSec=$((goodDuration/1000))
echo $goodDurationSec
printf '%02d:%02d:%02d\n' $((goodDurationSec/3600)) $((goodDurationSec%3600/60)) $((goodDurationSec%60))


beforeFirst=$((goodStart-sbStart))
beforeFirstSec=$((beforeFirst/1000))
printf '%02d:%02d:%02d\n' $((beforeFirstSec/3600)) $((beforeFirstSec%3600/60)) $((beforeFirstSec%60))
beforeFirstPerc=$(echo "scale=2; $beforeFirst/$sbDuration/10" | bc -l)
echo "$beforeFirstPerc%"

eff=$(echo "scale=2; $goodDuration/$sbDuration/10" | bc -l)
echo "$eff%"


echo -n "$fillNo,$eff%"
printf ',%02d:%02d:%02d' $((meanDurationSec/3600)) $((meanDurationSec%3600/60)) $((meanDurationSec%60))
echo -n ",${meanDurationPerc}%,${beforeFirstPerc}%"
printf ',%02d:%02d:%02d' $((beforeFirstSec/3600)) $((beforeFirstSec%3600/60)) $((beforeFirstSec%60))
echo -n ",${effEnd}%,,$(timeToDate $sbStart)"
printf ',%02d:%02d:%02d' $((sbDuration/3600)) $((sbDuration%3600/60)) $((sbDuration%60))
printf ',%02d:%02d:%02d' $((goodDurationSec/3600)) $((goodDurationSec%3600/60)) $((goodDurationSec%60))
echo ",,,$(jq ".data.fillingSchemeName" ${DATA} | tr -d "\"")"


#rm -f ${DATA}
