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
   printf "   -a Use cosmcis runs (default: 0)"
}

dbg=0
fillNo=0
selection=""
CalibFill=""
calibandenv=0
from="-120 days"
to="-39 days"
cosmics=0;
redoil=0
env_folder="/home/rc/environments"
while getopts F:s:f:t:dhcea? flag; do
   case "${flag}" in
      F) fillNo="${OPTARG}";;
      d) dbg=1;;
      c) CalibFill="C";;
      s) selection="${OPTARG}";;
      e) calibandenv=1;;
      f) from="${OPTARG}";;
      t) to="${OPTARG}";;
	  a) cosmics=1;;
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

if [[ $cosmics == 1 ]]; then
	URL="https://ali-bookkeeping.cern.ch/api/runs?filter[definitions]=COSMICS&filter[o2start][from]=`date --date=\"$from\" +%s`000&filter[o2start][to]=`date --date=\"$to\" +%s`999&token=${BK_TOKEN}"
fi

URL2="https://ali-bookkeeping.cern.ch/api/environments?token=${BK_TOKEN}"
echo $URL
echo $URL2
hostname=`hostname`
if [[ $hostname == *"alio2-cr1"* ]]; then
	(( dbg )) && echo "Run internally"
	declare -x http_proxy="10.161.69.44:8080"
	declare -x https_proxy="10.161.69.44:8080"
	(( dbg )) && echo wget -q "${URL}" --no-check-certificate -O ${DATA}
	wget -q "${URL}" --no-check-certificate -O ${DATA}
	declare -x http_proxy=""
	declare -x https_proxy=""
else
	(( dbg )) && echo "Run externally"
	wget -q "${URL}"  -O ${DATA}
	wget -q "${URL2}" -O ${DATA2}
fi





LINE=""

RUNS="`jq .data[].runNumber ${DATA}`"
(( dbg )) && echo $RUNS
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
(( dbg )) && echo $ENVS
n=-1
for runNumber in ${RUNS}; do
	n=$((n+1))
	URL2="https://ali-bookkeeping.cern.ch/api/environments?filter[runNumbers]=${runNumber}&token=${BK_TOKEN}"
	if [[ $hostname == *"alio2-cr1"* ]]; then
		declare -x http_proxy="10.161.69.44:8080"
		declare -x https_proxy="10.161.69.44:8080"
	fi
	wget -q "${URL2}" --no-check-certificate -O ${DATA2}
	if [[ $hostname == *"alio2-cr1"* ]]; then	
		declare -x http_proxy=""
		declare -x https_proxy=""
	fi
	runN=$(jq ".data[$e].runs[].runNumber" ${DATA2})
	(( dbg )) && echo RunNumber: $runN - $runNumber
	if [[ $runNumber == $runN ]];
	then
		nDetectors=$(( `jq .data[$n].nDetectors ${DATA}` ))
		runDefinition=$(jq .data[$n].definition ${DATA})
		readoutCfgUri=$(jq .data[$n].readoutCfgUri ${DATA})
		e=0
		env=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
		id=$(jq ".data[$e].id" ${DATA2})
		id=`echo $id | tr -d '"'`
		
		if   [[ $nDetectors > 10 ]];then
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
				if [[ "$hi" == *"STANDBY"* ]]; then
					(( time_standby == 0)) && time_standby=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
				fi
				if [[ "$hi" == *"DEPLOYED"* ]]; then
					(( time_deployed == 0)) && time_deployed=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
				fi
				if [[ "$hi" == *"CONFIGURED"* ]]; then
					(( time_configured == 0)) && time_configured=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
					(( time_running > 0)) && time_stopped=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
				fi
				if [[ "$hi" == *"RUNNING"* ]]; then
					(( time_running == 0)) && time_running=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
				fi
				if [[ "$hi" == *"ERROR"* ]]; then
					error_found=1
				fi
				if [[ "$hi" == *"DESTROYED"* ]] || [[ "$hi" == *"DONE"* ]]; then
					(( time_destroyed == 0)) && time_destroyed=$(jq ".data[$e].historyItems[$h].createdAt" ${DATA2})
				fi
			done
			env_file="$env_folder/env_time_${id}.dat"
			if [ ! -e $env_file ] || [ $redoil == 1 ] ; then
				(( dbg )) && echo " $env_file  does not exist -> retrieve it"
				/home/rc/alice-tpc-flp-scripts/data_scripts/il/il_extract.sh ${id}
			fi
			il_r=`grep "CREATE" $env_file`
			if [ -z "$il_r"  ]; then
				(( dbg )) && echo " $env_file ->  empty try again"
				/home/rc/alice-tpc-flp-scripts/data_scripts/il/il_extract.sh ${id}
			fi
			il_create_time=`grep "CREATE" $env_file | cut -d"-" -f 4`
			il_create_time=`echo "scale=0; $il_create_time *1000" | bc | cut -d"." -f 1`
			(( dbg )) && echo  "READY TO START"
			il_rts=`grep "READY TO START"  $env_file`	
			(( dbg )) && echo  "READY TO START"		
			if [ ! -z "${il_rts}" ]; then 
				il_ready_to_start_time=`echo ${il_rts} | cut -d"-" -f 5`
				il_ready_to_start_time=`echo "scale=0; $il_ready_to_start_time *1000" | bc | cut -d"." -f 1`
			else
				echo "READY TO START" not found in $env_file
				echo "/home/rc/alice-tpc-flp-scripts/data_scripts/il/il_extract.sh ${id} &"
			fi	
			(( dbg )) && echo  "CLICKED START"
			il_csta=`grep "CLICKED START" $env_file`	
			if [ ! -z "${il_csta}" ]; then 
				il_clicked_start_time=`echo ${il_csta} | cut -d"-" -f 5`
				il_clicked_start_time=`echo "scale=0; $il_clicked_start_time *1000" | bc | cut -d"." -f 1`
			else
				echo "CLICKED START"  not found in $env_file
				echo "/home/rc/alice-tpc-flp-scripts/data_scripts/il/il_extract.sh ${id} &"
			fi		
			(( dbg )) && echo  "RUNNING"	
			il_run=`grep "RUNNING"    $env_file`
			il_rerr=`grep "RUN ERROR"  $env_file`		
			if [ ! -z "${il_run}" ]; then 
				il_runnung_time=`echo ${il_run} | cut -d"-" -f 5`
				il_runnung_time=`echo "scale=0; $il_runnung_time *1000" | bc | cut -d"." -f 1`
			elif [ ! -z "${il_rerr}" ]; then 
				(( dbg )) && echo   "GO ERROR"			
				il_run_stopped_time=`echo ${il_rerr} | cut -d"-" -f 5`
				il_run_stopped_time=`echo "scale=0; $il_run_stopped_time *1000" | bc | cut -d"." -f 1`
				il_shut=`grep "DESTROY START"   $env_file`
				if [ ! -z "${il_shut}" ]; then 
					il_shutdown_time=`echo ${il_shut} | cut -d"-" -f 5`
					il_shutdown_time=`echo "scale=0; $il_shutdown_time *1000" | bc | cut -d"." -f 1`
				else 
					echo "DESTROY START" not found in $env_file
					echo "/home/rc/alice-tpc-flp-scripts/data_scripts/il/il_extract.sh ${id} &"
				fi
			fi	
			(( dbg )) && echo   "CLICKED STOP"	
			il_csto=`grep "CLICKED STOP"  $env_file`
			if [ ! -z "${il_csto}" ]; then 
				il_clicked_stop_time=`echo ${il_csto} | cut -d"-" -f 5`
				il_clicked_stop_time=`echo "scale=0; $il_clicked_stop_time *1000" | bc | cut -d"." -f 1`
			elif [ ! -z "${il_rerr}" ]; then 
					(( dbg )) && echo   "GO ERROR"			
					il_run_stopped_time=`echo ${il_rerr} | cut -d"-" -f 5`
					il_run_stopped_time=`echo "scale=0; $il_run_stopped_time *1000" | bc | cut -d"." -f 1`
					il_shut=`grep "DESTROY START"   $env_file`
					if [ ! -z "${il_shut}" ]; then 
						il_shutdown_time=`echo ${il_shut} | cut -d"-" -f 5`
						il_shutdown_time=`echo "scale=0; $il_shutdown_time *1000" | bc | cut -d"." -f 1`
					else 
						echo "DESTROY START" not found in $env_file
						echo "/home/rc/alice-tpc-flp-scripts/data_scripts/il/il_extract.sh ${id} &"
					fi
			else
				echo "CLICKED STOP" not found in $env_file
				echo "/home/rc/alice-tpc-flp-scripts/data_scripts/il/il_extract.sh ${id} &"
			fi
			(( dbg )) && echo  "RUN STOPPED"
			il_rsto=`grep "RUN STOPPED"  $env_file`
			il_rerr=`grep "RUN ERROR"  $env_file`
			if [ ! -z "${il_rsto}" ]; then 
				il_run_stopped_time=`echo ${il_rsto} | cut -d"-" -f 5`
				il_run_stopped_time=`echo "scale=0; $il_run_stopped_time *1000" | bc | cut -d"." -f 1`
				
				(( dbg )) && echo  "SHUTDOWN START"
				il_shut=`grep "SHUTDOWN START"   $env_file`
				if [ ! -z "${il_shut}" ]; then 
					il_shutdown_time=`echo ${il_shut} | cut -d"-" -f 5`
					il_shutdown_time=`echo "scale=0; $il_shutdown_time *1000" | bc | cut -d"." -f 1`
				elif [ ! -z "${il_rerr}" ]; then 
					(( dbg )) && echo   "GO ERROR"			
					il_run_stopped_time=`echo ${il_rerr} | cut -d"-" -f 5`
					il_run_stopped_time=`echo "scale=0; $il_run_stopped_time *1000" | bc | cut -d"." -f 1`
					il_shut=`grep "DESTROY START"   $env_file`
					if [ ! -z "${il_shut}" ]; then 
						il_shutdown_time=`echo ${il_shut} | cut -d"-" -f 5`
						il_shutdown_time=`echo "scale=0; $il_shutdown_time *1000" | bc | cut -d"." -f 1`
					else 
						echo "DESTROY START" not found in $env_file
						echo "/home/rc/alice-tpc-flp-scripts/data_scripts/il/il_extract.sh ${id} &"
					fi
				else
					echo "SHUTDOWN START" not found in $env_file
					echo "/home/rc/alice-tpc-flp-scripts/data_scripts/il/il_extract.sh ${id} &"
				fi
			elif [ ! -z "${il_rerr}" ]; then 
				(( dbg )) && echo   "GO ERROR"			
				il_run_stopped_time=`echo ${il_rerr} | cut -d"-" -f 5`
				il_run_stopped_time=`echo "scale=0; $il_run_stopped_time *1000" | bc | cut -d"." -f 1`
				il_shut=`grep "DESTROY START"   $env_file`
				if [ ! -z "${il_shut}" ]; then 
					il_shutdown_time=`echo ${il_shut} | cut -d"-" -f 5`
					il_shutdown_time=`echo "scale=0; $il_shutdown_time *1000" | bc | cut -d"." -f 1`
				else 
					echo "DESTROY START" not found in $env_file
					echo "/home/rc/alice-tpc-flp-scripts/data_scripts/il/il_extract.sh ${id} &"
				fi
			fi
			(( dbg )) && echo  "SHUTDOWN END"
			il_end=`grep "SHUTDOWN END"   $env_file`
			if [ ! -z "${il_end}" ]; then 
				il_shutdown_end_time=`echo ${il_end} | cut -d"-" -f 5`
				il_shutdown_end_time=`echo "scale=0; $il_shutdown_end_time *1000" | bc | cut -d"." -f 1`
			else 
				echo "SHUTDOWN END" not found in $env_file
				echo "/home/rc/alice-tpc-flp-scripts/data_scripts/il/il_extract.sh ${id} &"
			fi
		



			startofTrigger=$(jq .data[$n].timeTrgStart ${DATA})
			endofTrigger=$(jq .data[$n].timeTrgEnd ${DATA})
			startofRun=$(jq .data[$n].timeO2Start ${DATA})
			endofRun=$(jq .data[$n].timeO2End ${DATA})
			nEPN=$(jq ".data[$n].nEpns" ${DATA})
			nFLP=$(jq ".data[$n].nFlps" ${DATA})
			startClickTime=$(jq ".data[$n].timeO2Start" ${DATA}) 
			(( time_stopped == 0 )) && time_stopped=$endofRun
		
			(( dbg )) && echo time_StartofTrigger:$(timeToDate $startofTrigger)
			(( dbg )) && echo time_endofTrigger:$(timeToDate $endofTrigger)
			(( $startofTrigger == 0 )) && startofTrigger=$startofRun
			(( $endofTrigger == 0 )) && endofTrigger=$endofRun			
			time_to_deploy_loc=$(( (time_deployed-time_standby)/1000 ))
			time_to_configured_local=$(( (time_configured-time_deployed)/1000))
			time_to_running_local=$(( (time_running-time_configured)/1000))
			time_to_stopping_local=$(( (time_stopped-il_clicked_stop_time)/1000))
			time_to_shutdown_local=$(( (time_destroyed-time_stopped)/1000))	
			(( dbg )) && echo time_creation:$(timeToDate $env) - $(timeToDate $il_create_time) 
			(( dbg )) && echo time_standby:$(timeToDate $time_standby)
			(( dbg )) && echo time_deployed:$(timeToDate $time_deployed)
			(( dbg )) && echo time_configured:$(timeToDate $time_configured) - $(timeToDate $il_ready_to_start_time) 
			(( dbg )) && echo time_StartofRun:$(timeToDate $startofRun) - $(timeToDate $il_clicked_start_time) 
			(( dbg )) && echo time_StartofTrigger:$(timeToDate $startofTrigger) - $(timeToDate $il_runnung_time)
			(( dbg )) && echo time_running:$(timeToDate $time_running)
			(( dbg )) && echo time_endofRun:$(timeToDate $endofRun)
			(( dbg )) && echo time_endofTrigger:$(timeToDate $endofTrigger) - $(timeToDate $il_clicked_stop_time)
			(( dbg )) && echo time_stopped:$(timeToDate $time_stopped)
			(( dbg )) && echo time_detroyed:$(timeToDate $time_destroyed) - $(timeToDate $il_shutdown_end_time)
			if [[ "$readoutCfgUri" == *"LHC2"* ]];then 
				(( dbgt )) && echo $id,,$(timeToDate $env),$runN,$nEPN,$nFLP,"REPLAY",$(timeToDate $time_stopped),$(timeToDate $il_runnung_time),$(timeToDate $il_clicked_stop_time),$time_to_deploy_loc,$time_to_configured_local,$time_to_running_local,$time_to_stopping_local,$time_to_shutdown_local,$error_found
			else
				(( dbgt )) && echo $id,,$(timeToDate $env),$runN,$nEPN,$nFLP,${runDefinition},$(timeToDate $time_stopped),$(timeToDate $il_runnung_time),$(timeToDate $il_clicked_stop_time),$time_to_deploy_loc,$time_to_configured_local,$time_to_running_local,$time_to_stopping_local,$time_to_shutdown_local,$error_found
			fi
		fi
	fi
done

#rm -f ${DATA}
