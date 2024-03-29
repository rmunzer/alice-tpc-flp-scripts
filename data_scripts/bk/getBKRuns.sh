#!/bin/bash
# =========================================================================
# Get summary of ALICE runs from BKP
#
# Author: R.Divia`, CERN/ALICE
# Version: v1 13/06/2023
# =========================================================================
# Temporary files used to cache the detailed data
DATA="/tmp/json-`basename $0`.$$"
DATA_CTP="/tmp/json_ctp-`basename $0`.$$"

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
   printf "   -f Date\tStarting date/time (default: 7 days ago)\n"
   printf "   -t Date\tEnding date/time (default: NOW)\n"
   printf "   -F FillNo\tNumber of the fill(s) (comma-separated) (disables date/time-based selection)\n"
   printf "   -D seconds\tMinimum run duration (in seconds)\n"
   printf "   -s selection\tfields selection (comma-separated)\n"
   printf "   -c get ctp information\n"
   printf "   -g \tgood runs only\n"
}

from="-7 days"
to="now"
dbg=0
minDuration=0
fillNo=0
selection=""
goodOnly=0
getCTP=0
while getopts f:t:F:D:s:gdhc? flag; do
   case "${flag}" in
      f) from="${OPTARG}";;
      t) to="${OPTARG}";;
      F) fillNo="${OPTARG}";;
      D) minDuration="${OPTARG}";;
      d) dbg=1;;
      s) selection="${OPTARG}";;
      g) goodOnly=1;;
	  c) getCTP=1;;
      h|*) usage; exit 1;;
   esac
done

# Selection by FILL NUMBER overrides any time-based selection
if (( fillNo > 0 )); then
   from=""
   to=""
fi

if (( dbg )); then
   printf "`basename $0` starting\t"
   printf "\tfrom:'%s' to:'%s' fillNo:'%d'\n" "${from}" "${to}" "${fillNo}"
fi >&2

O=""
if [ "${from}${to}" ]; then
   O="filter[o2start][from]=`date --date=\"${from}\" +%s`000&filter[o2start][to]=`date --date=\"${to}\" +%s`999"
fi

if (( fillNo > 0 )); then
   O="filter[fillNumbers]=${fillNo}"   
fi

URL="https://ali-bookkeeping.cern.ch/api/runs?$O&page[offset]=0&page[limit]=999"
#(( dbg )) && 
printf "URL:\"%s\"\n" "${URL}" >&2
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

LINE+=$(printf "Run Number${SEP}")
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
LINE+=$(printf "Fill scheme${SEP}")
LINE+=$(printf "Stable Beams duration${SEP}")
LINE+=$(printf "Period${SEP}")
LINE+=$(printf "PDP workflow parameters${SEP}")
LINE+=$(printf "EOR reasons(s)${SEP}")
LINE+=$(printf "# Detectors${SEP}")
LINE+=$(printf "# FLPs${SEP}")
LINE+=$(printf "# EPNs${SEP}")
LINE+=$(printf "CTF File Size${SEP}")
LINE+=$(printf "TF File Size${SEP}")
LINE+=$(printf "ZDC Trigger${SEP}")
LINE+=$(printf "Mu${SEP}")
LINE+=$(printf "ZDC Rate${SEP}")
for d in ${DETS}; do
   LINE+=$(printf "$d IN${SEP}")
done
LINE+=$(printf "\n")

if [ x"$selection" = "x" ]; then
    echo $LINE | tr "$SEP" "${SEP_CSV}"
else
    echo $LINE | cut -d"$SEP" -f $selection | tr "$SEP" "${SEP_CSV}"
fi

RUNS="`jq .data[].runNumber ${DATA} | tac`"
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
   printf "${SEP}"
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


if [ $getCTP = 1 ];
then
	n=${NRUNS}
	ctpruns=`echo $RUNS | sed -e "s/\s\+/,/g"`
	runarray=(${RUNS})
	
	echo ctp_data.sh -r $ctpruns -f $fillNo
	ctp_data.sh -r $ctpruns -f $fillNo > ${DATA_CTP}
	rate=`grep "ZNC:" ${DATA_CTP}| cut -d" " -f 1 | cut -d: -f3 `
	integral=`grep "ZNC:" ${DATA_CTP} | cut -d" " -f 2 | cut -d: -f2 `
	mu=`grep "ZNC:" ${DATA_CTP} | cut -d" " -f 3 | cut -d: -f2 `
	echo "[" > vals.json
	RUNS2="`jq .data[].runNumber ${DATA}`"
	n=${NRUNS}
	for runNumber  in $RUNS2 ; do
	   n=$((n-1))
	   
	   rate_temp=`echo $rate | cut -f$((n+1)) -d" "`
	   integral_temp=`echo $integral | cut -f$((n+1)) -d" "`
	   mu_temp=`echo $mu | cut -f$((n+1)) -d" "`
	   #echo $n $runNumber $rate_temp $integral_temp $mu_temp
	   echo "{\"rate\": \"$rate_temp\",\"trigger\": \"$integral_temp\",\"mu\": \"$mu_temp\",\"runNumber\": $runNumber" >> vals.json
	   if [ $n = 0 ]; then
			echo "}" >> vals.json
	   else
			echo "}," >> vals.json
		fi
	done 
	echo "]" >> vals.json
	selection=$selection,24,25,26 
cat > merge.jq << EOF 
def dict(f):
  reduce .[] as \$o ({}; .[\$o | f | tostring] = \$o ) ;

(\$bar | dict(.runNumber)) as \$dict
| .data |= map(. + (\$dict[.runNumber|tostring] ))
EOF

jq -f merge.jq --argfile bar vals.json ${DATA} > ${DATA}_tmp2
cat ${DATA}_tmp2 > ${DATA}
rm ${DATA}_tmp2 
rm merge.jq
rm vals.json

fi


for runNumber  in ${RUNS}; do
   n=$((n-1))
   
   (( dbg )) && echo "=============================================================================" >&2
   (( dbg )) && jq .data[$n] ${DATA} >&2
   if (( `jq .data[$n].runNumber ${DATA}` != runNumber )); then
     printf "Run number mismatch, fatal error\n" >&2
     exit 1
   fi

   runDefinition=$(jq .data[$n].definition ${DATA} | tr -d "\"")
   (( dbg )) && echo "$runDefinition" >&2
   if [ x"$runDefinition" != "xPHYSICS" -a x"$runDefinition" != "xCOSMICS" ]; then
      continue;
   fi

   runQuality=$(jq .data[$n].runQuality ${DATA} | tr -d "\"")
   (( dbg )) && echo "$runQuality" >&2
   if (( $goodOnly == 1 )); then
      if [ x"$runQuality" != "xgood" ]; then
         continue;
      fi
   fi

   nDetectors=$(( `jq .data[$n].nDetectors ${DATA}` ))
   
   runDuration=$(( `jq .data[$n].runDuration ${DATA}` / 1000 ))
   
#printf "nDetectors:%d runDuration:%d\n" ${nDetectors} ${runDuration} >&2
   (( nDetectors < 2 )) && continue
   
   (( runDuration < minDuration )) && continue

#printf "Passed\n" >&2

   LINE=""
   
   LINE+=$(printf "${runNumber}${SEP}")   # Par: 1
     
   LINE+=$(timeToDate `jq .data[$n].timeO2Start ${DATA}`) # Par: 2
   LINE+=$(timeToDate `jq .data[$n].timeO2End ${DATA}`) # Par: 3
     
   LINE+=$(timeToDate `jq .data[$n].startTime ${DATA}`) # Par: 4
   LINE+=$(timeToDate `jq .data[$n].endTime ${DATA}`) # Par: 5
     
   LINE+=$(timeToDate `jq .data[$n].timeTrgStart ${DATA}`) # Par: 6
   LINE+=$(timeToDate `jq .data[$n].timeTrgEnd ${DATA}`) # Par: 7
     
   #(( runDuration > 0 )) && printf "%d" ${runDuration}
   LINE+=$(printf '%02d:%02d:%02d' $((runDuration/3600)) $((runDuration%3600/60)) $((runDuration%60))) # Par: 8
   LINE+=$(printf "${SEP}") 
     
   #printf "%s${SEP}" "`jq .data[$n].environmentId ${DATA}`"
   LINE+=$(printStr `jq .data[$n].environmentId ${DATA}`)  # Par: 9
     
   #printf "%s${SEP}" "`jq .data[$n].runType.name ${DATA}`"
   LINE+=$(printStr `jq .data[$n].runType.name ${DATA}`) # Par: 10
     
   #printf "%s${SEP}" "`jq .data[$n].definition ${DATA}`"
   LINE+=$(printStr `jq .data[$n].definition ${DATA}`) # Par: 11
     
   #printf "%s${SEP}" "`jq .data[$n].runQuality ${DATA}`"
   LINE+=$(printStr `jq .data[$n].runQuality ${DATA}`) # Par: 12
     
   LINE+=$(printNum `jq .data[$n].fillNumber ${DATA}`) # Par: 13
   LINE+=$(printStr `jq .data[$n].lhcFill.fillingSchemeName ${DATA}`) # Par: 14
     
   LINE+=$(printNum `jq .data[$n].lhcFill.stableBeamsDuration ${DATA}`) # Par: 15
   stableBeamsDuration=$(( `jq .data[$n].stableBeamsDuration ${DATA}` / 1000 ))
   #printf '%02d:%02d:%02d' $((stableBeamsDuration/3600)) $((stableBeamsDuration%3600/60)) $((stableBeamsDuration%60))
   #printf "${SEP}"
     
   #printf "%s${SEP}" "`jq .data[$n].lhcPeriod ${DATA}`"
   LINE+=$(printStr `jq .data[$n].lhcPeriod ${DATA}`) # Par: 16
     
   LINE+=$(printf "%s${SEP}" "`jq .data[$n].pdpWorkflowParameters ${DATA}`") 
     
   eorReasons="`jq .data[$n].eorReasons ${DATA}`"
   LINE+=$(printf "\"%s\"${SEP}" "`sanitize ${eorReasons}`")

   LINE+=$(printf "%d${SEP}" ${nDetectors})
     
   #printf "%d${SEP}" `jq .data[$n].nFlps ${DATA}`
   LINE+=$(printNum `jq .data[$n].nFlps ${DATA}`)
     
   #printf "%d${SEP}" `jq .data[$n].nEpns ${DATA}`
   LINE+=$(printNum `jq .data[$n].nEpns ${DATA}`)
     
   LINE+=$(printNum `jq .data[$n].ctfFileSize ${DATA}`)  # Par: 22
     
   LINE+=$(printNum `jq .data[$n].tfFileSize ${DATA}`) # Par: 23
   

   LINE+=$(printNum `jq .data[$n].trigger ${DATA}`)  # Par: 24
   LINE+=$(printNum `jq .data[$n].mu ${DATA}`) # Par: 25 
   LINE+=$(printNum `jq .data[$n].rate ${DATA}`)  # Par: 26
     
   detectors="`jq .data[$n].detectors ${DATA}`"
   for d in ${DETS}; do
     if echo "${detectors}" | grep -qn $d; then
       LINE+=$(printf "1${SEP}")
     else
       LINE+=$(printf "0${SEP}")
     fi
   done

   LINE+=$(printf "\n")

   if [ x"$selection" = "x" ]; then
       echo $LINE | tr "$SEP" "${SEP_CSV}"
   else
	   echo $LINE | cut -d"$SEP" -f $selection | tr "$SEP" "${SEP_CSV}"
   fi
   
done

rm -f ${DATA}

