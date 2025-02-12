#!/bin/bash
# =========================================================================
# Get summary of ALICE runs from BKP
#
# Author: R.Divia`, CERN/ALICE
# Version: v1 13/06/2023
# =========================================================================
# Temporary files used to cache the detailed data
DATA="/tmp/`basename $0`.$$"
DATA2="/tmp/`basename $0`-env.$$"

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
   printf "   -c Fill was used for calibration runs"
   printf "   -e Environment and Calibration stats"
   printf "   -f Start period (default: -7 days)"
   printf "   -t Finish period (default: now)"
}

dbg=0
fillNo=0
selection=""
CalibFill=""
calibandenv=0
from="-50 days"
to="-14 days"
while getopts F:s:f:t:dhce? flag; do
   case "${flag}" in
      F) fillNo="${OPTARG}";;
      d) dbg=1;;
      c) CalibFill="C";;
      s) selection="${OPTARG}";;
      e) calibandenv=1;;
      f) from="${OPTARG}";;
      t) to="${OPTARG}";;
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


URL="https://ali-bookkeeping.cern.ch/api/runs?filter[definitions]=SYNTHETIC&filter[o2start][from]=`date --date=\"$from\" +%s`000&filter[o2start][to]=`date --date=\"$to\" +%s`999&token=${BK_TOKEN}"
URL2="https://ali-bookkeeping.cern.ch/api/environments?token=${BK_TOKEN}"
echo $URL
hostname=`hostname`
if [[ $hostname == *"alio2-cr1"* ]]; then
	(( dbg )) && echo "Run internally"
	declare -x http_proxy="10.161.69.44:8080"
	declare -x https_proxy="10.161.69.44:8080"
	(( dbg )) && echo wget -q "${URL}" --no-check-certificate -O ${DATA}
	wget -q "${URL}" --no-check-certificate -O ${DATA}
	wget -q "${URL2}" --no-check-certificate -O ${DATA2}
	declare -x http_proxy=""
	declare -x https_proxy=""
else
	(( dbg )) && echo "Run externally"
	wget -q "${URL}"  -O ${DATA}
	wget -q "${URL2}" -O ${DATA2}
fi





LINE=""

RUNS="`jq .data[].runNumber ${DATA}`"
ENVS="`jq .data[].createdAt ${DATA2}`"
if [[ $dbg -gt 0 ]];then echo $RUNS;fi
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


e=-1
good_env=0;
failed_env=0;
sbStartloc=`date --date="$from" +%s`000
sbStartlocshift=$(( sbStart - 3600000 ))
sbEndloc=`date --date="$to" +%s`999
endofCalib=0
startofCalib=$sbEndloc
calibfound=0;
first_physics_env=0;
first_physics_env_time=0;
first_physics_env_status=0;
first_physics_env_run=0;
first_physics_run=""
first_physics_start=0
frist_physics_quality=""
first_physics_eor=""
first_physics_id=""
calib_detectors=""
run_before=0
dbgt=1

for env in ${ENVS}; do
	e=$((e+1))
	envStartloc=$env
	(( $env > $sbEndloc )) && continue
	
	id=$(jq ".data[$e].id" ${DATA2})
	(( $env < $sbStartloc )) && run_before=$(( run_before + 1))
	(( run_before > 10 )) && break
	(( run_before > 10 )) && break
	envRuns=$(jq ".data[$e].runs[].runNumber" ${DATA2})
	NenvRuns=$(( `echo "${envRuns}" | wc -l` ))	
	if [[ $envRuns != "" ]];
	then
		runN=$(jq ".data[$e].runs[].runNumber" ${DATA2})
		n=-1
		for runNumber in ${RUNS}; do
			n=$((n+1))
			if [[ $runNumber == $runN ]];
			then
				nDetectors=$(( `jq .data[$n].nDetectors ${DATA}` ))
				runDefinition=$(jq .data[$n].definition ${DATA})
				readoutCfgUri=$(jq .data[$n].readoutCfgUri ${DATA})
				
				if  [[ "$runDefinition" == *"SYNTHETIC"* ]] && [[ $nDetectors > 10 ]];then
					histlist_short=
					time_standby=0
					time_deployed=0
					time_configured=0
					time_stopping=0
					time_stopped=0
					time_destroyed=0
					time_running=0
					error_found=0
					h=-1
					hist=$(jq ".data[$e].historyItems[].status" ${DATA2})
					for hi in ${hist}; do
						h=$((h+1))
						if [[ "$hi" == *"STANDBY"* ]];
						then
							(( time_standby == 0)) && time_standby=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
						fi
						if [[ "$hi" == *"DEPLOYED"* ]];
						then
							(( time_deployed == 0)) && time_deployed=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
						fi
						if [[ "$hi" == *"CONFIGURED"* ]];
						then
							(( time_configured == 0)) && time_configured=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
							(( time_running > 0)) && time_stopped=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
						fi
						if [[ "$hi" == *"RUNNING"* ]];
						then
							(( time_running == 0)) && time_running=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
						fi
						if [[ "$hi" == *"ERROR"* ]];
						then
							error_found=1
						fi
						if [[ "$hi" == *"DESTROYED"* ]] || [[ "$hi" == *"DONE"* ]];
						then
							(( time_destroyed == 0)) && time_destroyed=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
						fi
	
					done
					startofRun=$(jq .data[$n].timeO2Start ${DATA})
					endofRun=$(jq .data[$n].timeO2End ${DATA})
					nEPN=$(jq ".data[$n].nEpns" ${DATA})
					nFLP=$(jq ".data[$n].nFlps" ${DATA})
					startClickTime=$(jq ".data[$n].timeO2Start" ${DATA}) 
					(( time_stopped == 0 )) && time_stopped=$endofRun
					
					time_to_deploy_loc=$(( (time_deployed-time_standby)/1000 ))
					time_to_configured_local=$(( (time_configured-time_deployed)/1000))
					time_to_running_local=$(( (time_running-startofRun)/1000))
					time_to_stopping_local=$(( (time_stopped-endofRun)/1000))
					time_to_shutdown_local=$(( (time_destroyed-time_stopped)/1000))


					if [[ "$readoutCfgUri" == *"LHC2"* ]];then 
						(( dbgt )) && echo $id,,$(timeToDate $env),$runN,$nEPN,$nFLP,"REPLAY",$(timeToDate $time_stopped),$(timeToDate $startofRun),$(timeToDate $endofRun),$time_to_deploy_loc,$time_to_configured_local,$time_to_running_local,$time_to_stopping_local,$time_to_shutdown_local,$error_found
					else
						(( dbgt )) && echo $id,,$(timeToDate $env),$runN,$nEPN,$nFLP,${runDefinition},$(timeToDate $startClickTime),$(timeToDate $startofRun),$(timeToDate $endofRun),$time_to_deploy_loc,$time_to_configured_local,$time_to_running_local,$time_to_stopping_local,$time_to_shutdown_local,$error_found
					fi
				fi
			fi
		done
	fi


done

#rm -f ${DATA}
