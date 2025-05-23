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
DATA3="/tmp/`basename $0`-all_env.$$"

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
   printf "   -e Environment stats"
   printf "   -k Calibration stats"
}

dbg=0
fillNo=0
selection=""
CalibFill=""
calibandenv=0
calibandenv2=0
while getopts F:s:dhcek? flag; do
   case "${flag}" in
      F) fillNo="${OPTARG}";;
      d) dbg=1;;
      c) CalibFill="C";;
      s) selection="${OPTARG}";;
      e) calibandenv=1;;
      k) calibandenv2=1;;
      h|*) usage; exit 1;;
   esac
done

if (( dbg )); then
   printf "`basename $0` starting\t"
   printf "\tfrom:'%s' to:'%s' fillNo:'%d'\n" "${from}" "${to}" "${fillNo}"
fi >&2
# Get delivery from masi file:
massi_folder="/home/rc/massi-files/$fillNo"
if [ ! -d "$massi_folder" ]; then
  echo "$massi_folder does not exist."
  mkdir -v $massi_folder
fi
massi_summary="${fillNo}_summary_ALICE.txt"
if [ ! -e "$massi_folder/$massi_summary" ]; then
	echo "$massi_folder/$massi_summary does not exist -> retrieve it"
	scp lhcif:/data/massiFiles.bck/$fillNo/${massi_summary} $massi_folder
fi
massi_detail="${fillNo}_lumi_ALICE.txt"
if [ ! -e "$massi_folder/$massi_detail" ]; then
	echo "$massi_folder/$massi_detail does not exist -> retrieve it"
	scp lhcif:/data/massiFiles.bck/$fillNo/${massi_detail} ${massi_folder}
fi

delivered_lumi=`cat $massi_folder/$massi_summary | cut -f 4 | sed '1p;d'`
delivered_lumi=`echo "scale=7; $delivered_lumi /1000" | bc`
peak_lumi=`cat $massi_folder/$massi_summary | cut -f 3 | sed '1p;d'`
(( dbg )) && echo Delivery Lumi from summary: ${delivered_lumi}
delivered_lumi_2=`cat $massi_folder/${massi_detail} | cut -f 3 | awk '{s+=$1} END {print s}'`
delivered_lumi_2=`echo "scale=7; $delivered_lumi_2 *60/1000" | bc`
(( dbg )) && echo Delivery Lumi from single files: ${delivered_lumi_2}
O=""
if [ "${from}${to}" ]; then
   O=""
fi
if (( fillNo > 0 )); then
   O="filter[fillNumbers]=${fillNo}"   
fi
URL="https://ali-bookkeeping.cern.ch/api/lhcFills/$fillNo?token=${BK_TOKEN}"
URL2="https://ali-bookkeeping.cern.ch/api/environments?token=${BK_TOKEN}"
hostname=`hostname`
if [[ $hostname == *"alio2-cr1"* ]]; then
	(( dbg )) && echo "Run internally"
	declare -x http_proxy="10.161.69.44:8080"
	declare -x https_proxy="10.161.69.44:8080"
	(( dbg )) && echo wget -q "${URL}" --no-check-certificate -O ${DATA}
	(( $calibandenv2 == 1 )) &&  wget -q "${URL2}" --no-check-certificate -O ${DATA3} 
	wget -q "${URL}" --no-check-certificate -O ${DATA}
	declare -x http_proxy=""
	declare -x https_proxy=""
else
	(( dbg )) && echo "Run externally"
	wget -q "${URL}"  -O ${DATA}
	wget -q "${URL2}" -O ${DATA3}
fi
(( $calibandenv2 == 1 )) &&  ENVS="`jq .data[].createdAt ${DATA3}`"



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
 if [[ $dbg -gt 0 ]];then    echo $LINE | tr "$SEP" "${SEP_CSV}";fi
else
 if [[ $dbg -gt 0 ]];then    echo $LINE | cut -d"$SEP" -f $selection | tr "$SEP" "${SEP_CSV}";fi
fi

LINE=""

RUNS="`jq .data.runs[].runNumber ${DATA}`"

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

LINE+=$(printNum $(jq ".data.fillNumber" ${DATA}))

#jq ".data.stableBeamsStart" ${DATA}
sbStart=$(jq ".data.stableBeamsStart" ${DATA})
sbEnd=$(jq ".data.stableBeamsEnd" ${DATA})
sbDuration=$(jq ".data.stableBeamsDuration" ${DATA})

LINE+=$(timeToDate $sbStart)

endofCalib=0
startofCalib=$sbEndloc

e=-1
n=-1
good_env=0;
failed_env=0;
sbStartloc=$sbStart
sbStartlocshift=$(( sbStart - 3600000 ))
sbEndloc=$sbEnd
endofCalib=0
startofCalib=1;
if [[ $calibandenv == 1 ]] || [[ $calibandenv2 == 1 ]]; then  startofCalib=0; fi;
calibfound=0;
first_env=-1;
last_env=-1;
first_physics_env=0;
first_physics_env_time=-1;
if [[ $calibandenv == 1 ]] || [[ $calibandenv2 == 1 ]]; then first_physics_env_time=0; first_env=0; last_env=0; fi;
first_physics_env_status=0;
first_physics_env_run=0;
first_physics_run=""
first_physics_start=0
frist_physics_quality=""
first_physics_eor=""
first_physics_id=""
calib_detectors=
run_before=0
dbgt=1
firstrun=1;
nGood=0;
goodDuration=0;
goodStart=0;
goodEnd=0;
lossEnd=0

for runNumber in ${RUNS}; do
	
	n=$((n+1))
	URL2="https://ali-bookkeeping.cern.ch/api/environments?filter[runNumbers]=${runNumber}&token=${BK_TOKEN}"
	if [[ $hostname == *"alio2-cr1"* ]]; then
		declare -x http_proxy="10.161.69.44:8080"
		declare -x https_proxy="10.161.69.44:8080"
	fi
	 echo "" > ${DATA2}
	if [[ $calibandenv == 1 ]] || [[ $calibandenv2 == 1 ]]; then  wget -q "${URL2}" --no-check-certificate -O ${DATA2}; fi;

	if [[ $hostname == *"alio2-cr1"* ]]; then	
		declare -x http_proxy=""
		declare -x https_proxy=""
	fi
	id=$(jq ".data[$e].id" ${DATA2})
	env=$(jq ".data[$e].createdAt" ${DATA2})
	id=$(jq ".data[$e].id" ${DATA2})
	curRun=$(jq .data.runs[$n].runNumber ${DATA})
	runDefinition=$(jq .data.runs[$n].definition ${DATA})
	nDecRun=$(jq .data.runs[$n].nDetectors ${DATA})
	tags=`jq .data.runs[$n].tags[].text ${DATA} | tac` 
	runQuality=$(jq .data.runs[$n].runQuality ${DATA} | tr -d "\"")
	goodtag=0
	(( first_env == 0 )) && first_env=$env
	last_env=$env
   if  [[ $tags == *System* ]]; then goodtag=1; fi
   if  [[ $tags == *Special* ]] && [[ $nDecRun -gt 2 ]]; then goodtag=1; fi
	(( dbg )) && echo " ---------------------- Run $runNumber ($runDefinition - $goodtag) - $id - $env ($first_physics_env_time) -----------------------------"
	if  [[ "$runDefinition" == *"PHYSICS"* ]] ||[[ $goodtag == 1 ]]  ;then
		(( $first_physics_env_time == 0 )) && first_physics_env_time=$env && first_physics_env=$id
		startofRun=$(jq .data.runs[$n].timeO2Start ${DATA})
		endofRun=$(jq .data.runs[$n].timeO2End ${DATA})
		startofTrigger=$(jq .data.runs[$n].timeTrgStart ${DATA})
		endofTrigger=$(jq .data.runs[$n].timeTrgEnd ${DATA})
		runDuration=$(jq .data.runs[$n].runDuration ${DATA})
		runDurationSec=$((runDuration/1000))
		(( $startofTrigger == null )) && startofTrigger=$startofRun
		(( $endofTrigger == null )) && endofTrigger=$endofRun	
					
		first_physics_run=$(jq .data.runs[$n].runNumber ${DATA})
		first_physics_start=$startofRun
		frist_physics_quality=$(jq .data.runs[$n].runQuality ${DATA})
		first_physics_eor=$(jq .data.runs[$n].eorReasons[0].reasonTypeId ${DATA})
		first_physics_id=$(jq .data.runs[$n].eorReasons[0].environmentId ${DATA})
		hist=$(jq ".data[$e].historyItems[].status" ${DATA2})
		histlist_short=
		time_standby=0
		time_deployed=0
		time_configured=0
		time_running=0
		time_stopped=0
		time_destroyed=0
		error_found=0
		h=-1
		if [ x"$runQuality" == "xgood" ]; then
				nGood=$((nGood+1))
			   (( goodStart == 0 )) && goodStart=$(jq .data.runs[$n].timeTrgStart ${DATA}) && first_physics_env_run=$first_physics_run
			   goodDuration=$((goodDuration+runDuration))
			   good_env=$(( good_env+1))
			   
		fi
		goodEnd=$(jq .data.runs[$n].timeTrgEnd ${DATA})
		
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
			if [[ $histlist_short == "" ]];
			then	
				histlist_short=${histlocal:1:1}
			else
				histlist_short=$histlist_short-${histlocal:1:1}
			fi
		done
		
		(( time_stopped == 0 )) && time_stopped=$endofRun
		time_to_deploy_loc=$(( (time_deployed-time_standby)/1000 ))
		time_to_configured_local=$(( (time_configured-time_deployed)/1000))
		time_to_running_local=$(( (time_running-time_configured)/1000))
		time_to_stopping_local=$(( (time_stopped-endofTrigger)/1000))
		time_to_shutdown_local=$(( (time_destroyed-time_stopped)/1000))
		nEPN=$(jq ".data.runs[$n].nEpns" ${DATA})
		nFLP=$(jq ".data.runs[$n].nFlps" ${DATA})
		startClickTime=$(jq ".data.runs[$n].timeO2Start" ${DATA}) 
		(( dbg )) && echo time_standby:$(timeToDate $time_standby)
		(( dbg )) && echo time_deployed:$(timeToDate $time_deployed)
		(( dbg )) && echo time_configured:$(timeToDate $time_configured)
		(( dbg )) && echo time_StartofRun:$(timeToDate $startofRun)
		(( dbg )) && echo time_StartofTrigger:$(timeToDate $startofTrigger)
		(( dbg )) && echo time_running:$(timeToDate $time_running)
		(( dbg )) && echo time_endofRun:$(timeToDate $endofRun)
		(( dbg )) && echo time_endofTrigger:$(timeToDate $endofTrigger)
		(( dbg )) && echo time_stopped:$(timeToDate $time_stopped)
		(( dbg )) && echo time_destroyed:$(timeToDate $time_destroyed)
		(( dbg )) && echo "Tags($goodtag):" $tags
		(( dbg )) && echo $(timeToDate  $goodStart) -  $(timeToDate  $goodEnd) - $(( (goodEnd - goodStart)/1000 ))
		if [[ $firstrun=1 == 1 ]]; then	
			time_to_configured_local=0
			firstrun=0
		fi
		(( $calibandenv == 1 )) && echo $id,$fillNo,$(timeToDate $env),$runNumber,$nEPN,$nFLP,${runDefinition},$(timeToDate $startClickTime),$(timeToDate $startofTrigger),$(timeToDate $endofRun),$time_to_deploy_loc,$time_to_configured_local,$time_to_running_local,$time_to_stopping_local,$time_to_shutdown_local,$error_found
		if [[ $calibfound == 0 ]];
		then		
			first_physics_env_status="SUCCESS"
		fi
		sbEndloc=$startofRun
	elif  [[ "$runDefinition" == *"CALIBRATION"* ]];then
		calibfound=1 
		(( $startofCalib < 1 )) && startofCalib=$env
		endofCalib=$endofRun
		startofRun=$(jq .data.runs[$n].timeTrgStart ${DATA})
		endofRun=$(jq .data.runs[$n].timeTrgEnd ${DATA})
		detectors=$(jq .data.runs[$n].detectors ${DATA})
		quality=$(jq .data.runs[$n].calibrationStatus ${DATA})

		
		if [[ "$detectors" != *"ZDC"* ]];
		then
			if [[ "$quality" == *"SUCCESS"* ]];
			then
				good_calibrations=$((good_calibrations + 1 ))
				good_env=$(( good_env+1))
			fi
			calib_detectors="$calib_detectors`echo $detectors | xargs` "
		fi
		(( dbg )) && echo $id - $(timeToDate $sbStartlocshift) - $(timeToDate $env)  - $runN - ${runDefinition} - $(timeToDate $startofRun) - $(timeToDate $endofRun) $detectors $quality $good_calibrations
	else	
		startofRun=$(jq .data.runs[$n].timeTrgStart ${DATA})
		endofRun=$(jq .data.runs[$n].timeTrgEnd ${DATA})
		(( dbg )) && echo $id - $(timeToDate $sbStartlocshift) - $(timeToDate $env)  - $runN - ${runDefinition} - ignored - $(timeToDate $startofRun) - $(timeToDate $endofRun)
	fi
done
(( dbg )) && echo " ---------------------- Finished Run loop -----------------------------"
total_env=0;
if [[ $calibandenv2 == 1 ]]; 
then  
	for env in ${ENVS}; do
	(( $env < $first_env )) && break;
	(( $env > $last_env )) && continue;
	(( dbg )) && echo "ok" $env $first_env - $last_env
	total_env=$((total_env+1))
	done
	failed_env=$((total_env-good_env))
fi

calib_duration=$(( endofCalib/1000 - startofCalib/1000))
(( $calib_duration > 1500 )) && calib_duration=1500
sbDuration=$(jq ".data.stableBeamsDuration" ${DATA})

(( dbg )) && echo ""
(( dbg )) && echo "Start of Stable Beams: $LINE"
(( dbg )) && printf 'Stable Beam Duration: %02d:%02d:%02d\n' $((sbDuration/3600)) $((sbDuration%3600/60)) $((sbDuration%60))
(( dbg )) && echo "Start of Calib:" $(timeToDate $startofCalib)
(( dbg )) && echo "End if Calib:" $(timeToDate $endofCalib)
(( dbg )) &&  echo " First - Last env:" $first_env - $last_env
(( dbg )) && echo Environments: Good: $good_env Failed:$failed_env 
(( dbg )) && echo Duraction Calibration: $calib_duration
(( dbg )) && echo First Physics Env: $first_physics_env - $(timeToDate $first_physics_env_time) - Status: $first_env_status
(( dbg )) && echo First Good Run: $first_physics_run - $(timeToDate $first_physics_start) - $frist_physics_quality - $frist_physics_id- $first_physics_eor
(( dbg )) && echo ""




if [[ $dbg -gt 0 ]];then printf '%02d:%02d:%02d\n' $((sbDuration/3600)) $((sbDuration%3600/60)) $((sbDuration%60));fi


if (( goodEnd > sbEnd )); then
   goodDuration=$((goodDuration+sbEnd-goodEnd))
else
   lossEnd=$((sbEnd-goodEnd))
fi

effEnd=$(echo "scale=2; $lossEnd/$sbDuration/10" | bc -l)

if [[ nGood -gt 0 ]];then
	meanDuration=$((goodDuration/nGood))
else
	meanDuration=0
fi
meanDurationSec=$((meanDuration/1000))
(( dbg )) && echo $meanDuration
meanDurationPerc=$(echo "scale=2; $meanDuration/$sbDuration/10" | bc -l)

goodDurationSec=$((goodDuration/1000))
(( dbg )) && echo $goodDurationSec
(( dbg )) && printf '%02d:%02d:%02d\n' $((goodDurationSec/3600)) $((goodDurationSec%3600/60)) $((goodDurationSec%60))


beforeFirst=$((goodStart-sbStart))
# If not run was taken in the fill the beforeFirst is 100% and last is 0%
if [[ $beforeFirst -lt 0 ]]; then
	beforeFirst=$(echo "scale=2; $sbDuration * 1000" | bc -l)
	effEnd=0;
fi
beforeFirstSec=$((beforeFirst/1000))
(( dbg )) && printf '%02d:%02d:%02d\n' $((beforeFirstSec/3600)) $((beforeFirstSec%3600/60)) $((beforeFirstSec%60))
beforeFirstPerc=$(echo "scale=2; $beforeFirst/$sbDuration/10" | bc -l)
(( dbg )) && echo Eff Lost before first run: "$beforeFirstPerc%"

eff=$(echo "scale=2; $goodDuration/$sbDuration/10" | bc -l)
(( dbg )) && echo Data Taking Efficiency: "$eff%"

ShortFill=""
if [[ $sbDuration -lt 1800 ]];
then
	ShortFill="S"
fi

(( dbg )) && echo Efficiency loss at End of Fill: "$effEnd%"


filling_schema=$(jq ".data.fillingSchemeName" ${DATA} | tr -d "\"")
coll_bunches=`echo $filling_schema | cut -f 4 -d_`
if [[ $calibandenv == 0 ]];
then
	echo -n "$fillNo,$eff%"
	printf ',%02d:%02d:%02d' $((meanDurationSec/3600)) $((meanDurationSec%3600/60)) $((meanDurationSec%60));
	echo -n ",${meanDurationPerc}%,${beforeFirstPerc}%"
	printf ',%02d:%02d:%02d' $((beforeFirstSec/3600)) $((beforeFirstSec%3600/60)) $((beforeFirstSec%60))
	echo -n ",${effEnd}%,$coll_bunches,$(timeToDate $sbStart)"
	printf ',%02d:%02d:%02d' $((sbDuration/3600)) $((sbDuration%3600/60)) $((sbDuration%60))
	printf ',%02d:%02d:%02d' $((goodDurationSec/3600)) $((goodDurationSec%3600/60)) $((goodDurationSec%60))
	if [[ $calibandenv2 == 1 ]];
	then
		echo -n ",,${CalibFill}${ShortFill},$(jq ".data.fillingSchemeName" ${DATA} | tr -d "\"")"
		echo -n ",$(timeToDate $startofCalib),$(timeToDate $endofCalib)"
		printf ',%02d:%02d:%02d' $((calib_duration/3600)) $((calib_duration%3600/60)) $((calib_duration%60))
		echo ",$calib_detectors,$good_env,$failed_env",$first_physics_env,$(timeToDate $first_physics_env_time),$first_physics_env_run,$first_physics_env_status,,$first_physics_run,$frist_physics_quality,$(timeToDate $first_physics_start), $frist_physics_id,$first_physics_eor
	else
		echo ",${delivered_lumi},${CalibFill}${ShortFill},$(jq ".data.fillingSchemeName" ${DATA} | tr -d "\"")",${peak_lumi}
		#echo ",${delivered_lumi}"
	fi
fi

#rm -f ${DATA}
