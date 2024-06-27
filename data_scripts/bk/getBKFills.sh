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
}

dbg=0
fillNo=0
selection=""
CalibFill=""
calibandenv=0
while getopts F:s:dhce? flag; do
   case "${flag}" in
      F) fillNo="${OPTARG}";;
      d) dbg=1;;
      c) CalibFill="C";;
      s) selection="${OPTARG}";;
      e) calibandenv=1;;
      h|*) usage; exit 1;;
   esac
done

if (( dbg )); then
   printf "`basename $0` starting\t"
   printf "\tfrom:'%s' to:'%s' fillNo:'%d'\n" "${from}" "${to}" "${fillNo}"
fi >&2
# Get delivery from masi file:
mass_summary=`ssh lhcif "cat massiFiles/$fillNo/${fillNo}_summary_ALICE.txt"`
delivered_lumi=`echo $mass_summary | cut -f 4 -d" "`
delivered_lumi=`echo "scale=1; $delivered_lumi /1000" | bc`

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
	wget -q "${URL}" --no-check-certificate -O ${DATA}
	wget -q "${URL2}" --no-check-certificate -O ${DATA2}
	declare -x http_proxy=""
	declare -x https_proxy=""
else
	(( dbg )) && echo "Run externally"
	wget -q "${URL}"  -O ${DATA}
	wget -q "${URL2}" -O ${DATA2}
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
 if [[ $dbg -gt 0 ]];then    echo $LINE | tr "$SEP" "${SEP_CSV}";fi
else
 if [[ $dbg -gt 0 ]];then    echo $LINE | cut -d"$SEP" -f $selection | tr "$SEP" "${SEP_CSV}";fi
fi

LINE=""

RUNS="`jq .data.runs[].runNumber ${DATA}`"
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

LINE+=$(printNum $(jq ".data.fillNumber" ${DATA}))

#jq ".data.stableBeamsStart" ${DATA}
sbStart=$(jq ".data.stableBeamsStart" ${DATA})
sbEnd=$(jq ".data.stableBeamsEnd" ${DATA})
LINE+=$(timeToDate $sbStart)
endofCalib=0
startofCalib=$sbEndloc
if [[ $calibandenv == 1 ]];
then
e=-1
good_env=0;
failed_env=0;
sbStartloc=$sbStart
sbStartlocshift=$(( sbStart - 3600000 ))
sbEndloc=$sbEnd
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
	if [[ $envRuns == "" ]];
	then
		hist=$(jq ".data[$e].historyItems[].status" ${DATA2})
		histlist_short=
		h=-1
		for hi in ${hist}; do
			h=$((h+1))
			histlocal=$(jq ".data[$e].historyItems[$h].status" ${DATA2})
			if [[ $histlist_short == "" ]];
			then	
				histlist_short=${histlocal:1:1}
			else
				histlist_short=$histlist_short-${histlocal:1:1}
			fi
		done
		(( dbg )) && echo $id - $(timeToDate $sbStartlocshift) - $(timeToDate $env) - No Runs -  $histlist_short
		failed_env=$(( failed_env+1))
		if [[ $calibfound == 0 ]];
		then
			first_physics_env_run=""
			first_physics_env_status=$histlist_short
			first_physics_env=$id
			first_physics_env_time=$envStartloc
		fi
	else
		runN=$(jq ".data[$e].runs[].runNumber" ${DATA2})
		n=-1
		for runNumber in ${RUNS}; do
			n=$((n+1))
			if [[ $runNumber -eq $runN ]];
			then
				curRun=$(jq .data.runs[$n].runNumber ${DATA})
				runDefinition=$(jq .data.runs[$n].definition ${DATA})
				if  [[ "$runDefinition" == *"PHYSICS"* ]];then
					startofRun=$(jq .data.runs[$n].timeTrgStart ${DATA})
					endofRun=$(jq .data.runs[$n].timeTrgEnd ${DATA})
					
					
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
					h=-1
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
						if [[ "$hi" == *"DESTROYED"* ]];
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
					time_to_stopping_local=$(( (time_stopped-endofRun)/1000))
					time_to_shutdown_local=$(( (time_destroyed-time_stopped)/1000))
					nEPN=$(jq ".data.runs[$n].nEpns" ${DATA})
					nFLP=$(jq ".data.runs[$n].nFlps" ${DATA})
					(( dbgt )) && echo $id,$fillNo,$(timeToDate $env),$runN,$nEPN,$nFLP,${runDefinition},$(timeToDate $startofRun),$(timeToDate $endofRun),$time_to_deploy_loc,$time_to_configured_local,$time_to_running_local,$time_to_stopping_local,$time_to_shutdown_local
					if [[ $calibfound == 0 ]];
					then
						first_physics_env_run=$first_physics_run
						first_physics_env_status="SUCCESS"
						first_physics_env=$id
						first_physics_env_time=$envStartloc
					fi
					sbEndloc=$startofRun
				elif  [[ "$runDefinition" == *"CALIBRATION"* ]];then
					(( $env < $sbStartloc )) && calibfound=1 
					startofRun=$(jq .data.runs[$n].timeTrgStart ${DATA})
					endofRun=$(jq .data.runs[$n].timeTrgEnd ${DATA})
					detectors=$(jq .data.runs[$n].detectors ${DATA})
					quality=$(jq .data.runs[$n].calibrationStatus ${DATA})

					
					if [[ "$detectors" != *"ZDC"* ]];
					then
						if [[ "$quality" == *"SUCCESS"* ]];
						then
							good_calibrations=$((good_calibrations + 1 ))
						fi
						calib_detectors=$detectors" "$calib_detectors
						(( $env < $startofCalib )) &&  startofCalib=$env
						(( $endofRun > $endofCalib )) &&  endofCalib=$endofRun
					fi
					(( dbg )) && echo $id - $(timeToDate $sbStartlocshift) - $(timeToDate $env)  - $runN - ${runDefinition} - $(timeToDate $startofRun) - $(timeToDate $endofRun) $detectors $quality $good_calibrations
				else	
					startofRun=$(jq .data.runs[$n].timeTrgStart ${DATA})
					endofRun=$(jq .data.runs[$n].timeTrgEnd ${DATA})
					(( dbg )) && echo $id - $(timeToDate $sbStartlocshift) - $(timeToDate $env)  - $runN - ${runDefinition} - ignored - $(timeToDate $startofRun) - $(timeToDate $endofRun)
				fi
			fi
		done
		#echo  `date -d @$sbStartloc` - `date -d @$envStartloc` - `date -d @$sbEndloc` - $runN- $curRun
		good_env=$(( good_env+1))
		(( good_calibrations > 5 )) && break
	fi


done
calib_duration=$(( endofCalib/1000 - startofCalib/1000))
if [[ $calib_duration > 1500 ]]; 
then
	calib_duration=1500
fi
(( dbg )) && echo ""
(( dbg )) && echo Environments: Good: $good_env Failed:$failed_env 
(( dbg )) && echo Duraction Calibration: $calib_duration
(( dbg )) && echo First Physics Env: $first_physics_env - $(timeToDate $first_physics_env_time) - Status: $first_env_status
(( dbg )) && echo First Good Run: $first_physics_run - $(timeToDate $first_physics_start) - $frist_physics_quality - $frist_physics_id- $first_physics_eor
(( dbg )) && echo ""
fi

sbDuration=$(jq ".data.stableBeamsDuration" ${DATA})

if [[ $dbg -gt 0 ]];then echo $LINE;fi
if [[ $dbg -gt 0 ]];then echo $sbDuration;fi
if [[ $dbg -gt 0 ]];then printf '%02d:%02d:%02d\n' $((sbDuration/3600)) $((sbDuration%3600/60)) $((sbDuration%60));fi

nGood=0
goodDuration=0
goodStart=0
goodEnd=0

#echo ${NRUNS}

n=-1
for runNumber in ${RUNS}; do
   n=$((n+1))
   

   
   curRun=$(jq .data.runs[$n].runNumber ${DATA})


   
   if (( curRun != runNumber )); then
     printf "Run number mismatch, fatal error\n" >&2
     exit 1
   fi

   runDefinition=$(jq .data.runs[$n].definition ${DATA} | tr -d "\"")

   
    if [ x"$runDefinition" == "xCALIBRATION" ]; then
      continue;
   fi 
   if [ x"$runDefinition" == "xSYNTHETIC" ]; then
      continue;
   fi   
   nDecRun=$(jq .data.runs[$n].nDetectors ${DATA})
   (( dbg )) && echo "-----------"
      (( dbg )) && echo "$n  $curRun  $runNumber" NDEc="$nDecRun"
	goodtag=0
   tags=`jq .data.runs[$n].tags[].text ${DATA} | tac` 
   if  [[ "$tags" == *"System Test 2024"* ]]; then goodtag=1; fi
   if  [[ "$tags" == *"Special Run 2024"* ]] && [[ $nDecRUn -gt 2 ]]; then goodtag=1; fi
   (( dbg )) && echo "$runDefinition,$tags,$goodtag"  >&2

   if [ x"$runDefinition" != "xPHYSICS" ]; then
      (( !goodtag )) && continue;
   fi

   runQuality=$(jq .data.runs[$n].runQuality ${DATA} | tr -d "\"")
   (( dbg )) && echo "$runQuality" >&2
   if [ x"$runQuality" != "xgood" ]; then
      (( !goodtag )) && continue;
   fi
   if [ x"$runQuality" == "xbad" ]; then
      continue;
   fi
   (( dbg )) && echo "Used"

   nGood=$((nGood+1))

   runDuration=$(jq .data.runs[$n].runDuration ${DATA})
   runDurationSec=$((runDuration/1000))
   goodDuration=$((goodDuration+runDuration))

 (( dbg )) && printf '%02d  %06d  %08d  %02d:%02d:%02d\n' $n $runNumber $runDurationSec $((runDurationSec/3600)) $((runDurationSec%3600/60)) $((runDurationSec%60))

   if (( goodStart == 0 )); then
      goodStart=$(jq .data.runs[$n].timeTrgStart ${DATA})
   fi

   goodEnd=$(jq .data.runs[$n].timeTrgEnd ${DATA})
   
	(( dbg )) && echo -n $(timeToDate  $goodStart) -  $(timeToDate  $goodEnd) - $(( (goodEnd - goodStart)/1000 ))

done

lossEnd=0
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



echo -n "$fillNo,$eff%"
printf ',%02d:%02d:%02d' $((meanDurationSec/3600)) $((meanDurationSec%3600/60)) $((meanDurationSec%60));
echo -n ",${meanDurationPerc}%,${beforeFirstPerc}%"
printf ',%02d:%02d:%02d' $((beforeFirstSec/3600)) $((beforeFirstSec%3600/60)) $((beforeFirstSec%60))
echo -n ",${effEnd}%,,$(timeToDate $sbStart)"
printf ',%02d:%02d:%02d' $((sbDuration/3600)) $((sbDuration%3600/60)) $((sbDuration%60))
printf ',%02d:%02d:%02d' $((goodDurationSec/3600)) $((goodDurationSec%3600/60)) $((goodDurationSec%60))
if [[ $calibandenv == 1 ]];
then
echo -n ",,${CalibFill}${ShortFill},$(jq ".data.fillingSchemeName" ${DATA} | tr -d "\"")"
echo -n ",$(timeToDate $startofCalib),$(timeToDate $endofCalib)"
printf ',%02d:%02d:%02d' $((calib_duration/3600)) $((calib_duration%3600/60)) $((calib_duration%60))
echo ",$calib_detectors,$good_env,$failed_env",$first_physics_env,$(timeToDate $first_physics_env_time),$first_physics_env_run,$first_physics_env_status,,$first_physics_run,$frist_physics_quality,$(timeToDate $first_physics_start), $frist_physics_id,$first_physics_eor
else
echo ",${delivered_lumi},${CalibFill}${ShortFill},$(jq ".data.fillingSchemeName" ${DATA} | tr -d "\"")"
fi


#rm -f ${DATA}
