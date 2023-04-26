#!/bin/bash

usage() {
  usage="Usage:
  create_calib_files.sh <required arguments> [optional arguments]
  
  Action selection
  -i, --init          		:  Initial Script
  -l, --links         		:  Link Status
  -a, --alf           		:  Restart ALF
      --alf_force     		:  Restart ALF (force resart)

  -s, --start_flp=    		:  Start FLP
  -f, --stop_flp=     		:  Stop FLP
  -p, --pp 	      		:  COnfig pattern player
      --pp_tf=        		:  Skipped TF in pp for re-sync (=0x1)
      --pp_bc=        		:  BC for re-sync (=0x8)
  -c, --cru_config    		:  Config CRU
      --cru_config_force    	:  Config CRU force
  -r, --rescan        		:  Rescan (Reload Firmware)
  -h, --help          		:  Show Help
  "  
  echo "$usage"
}
    
usageAndExit() {
  usage
  if [[ "$0" =~ flp_execute.sh ]]; then
     exit 0
  else
     return 0
  fi
 }
                    
# ===| default variable values |================================================
  fileInfo=
  init=0
  links=0
  alf=0
  alf_force=0
  pat=0
  pat_tf=0x190
  pat_bc=0x8
  cru_config=0
  cru_config_force=0
  rescan=0
  start_flp=0
  stop_flp=0   
                   
# ===| parse command line options |=============================================
OPTIONS=$(getopt -l "init,links,alf,alf_force,start_flp:,stop_flp:,pp,pp_tf:,pp_bc:,cru_config,cru_config_force,rescan,help" -o "s:f:ilapcrh" -n "flp_execute.sh" -- "$@")
                    
if [ $? != 0 ] ; then
  usageAndExit
fi
eval set -- "$OPTIONS"

while true; do
  case "$1" in
      --) shift; break;;
      -i|--init) init=1; shift;;
      -l|--links) links=1; shift;;
      -a|--alf)   alf=1; shift;;
      --alf_force) alf_force=1; shift;;
      -p|--pp) pat=1; shift;;
      --pp_tf) pat_tf=$2; shift 2;;
      --pp_bc) pat_bc=$2; shift 2;;
      -c|--cru_config) cru_config=1; shift;;
      --cru_config_force) cru_config_force=1; shift;;
      -r|--rescan) rescan=1; shift;;
      -s|--start_flp) start_flp=$2; shift 2;;
      -f|--stop_flp) stop_flp=$2; shift 2;;
      -h|--help) usageAndExit; shift;;
      *) echo "Internal error!" ; exit 1 ;;
   esac
done
                                                          
# ===| check for required arguments |===========================================

echo $cmc $itf $pad
command=""
if [[ $start_flp -gt $stop_flp ]];
then
    usageAndExit;
fi

BASEDIR=$(dirname "$0")
echo "$BASEDIR"

echo "Execute $command on FLPS ($start_flp..$stop_flp)"

for (( j=$start_flp; j<=$stop_flp; j++ ))
do 
	i=$(printf "%03d" $j)
	echo FLP: alio2-cr1-flp$i
	if [[ $init == 1 ]];
	then 
		echo ssh tpc@alio2-cr1-flp$i "mkdir -p /home/tpc/scripts/" &
		echo scp ./flp_scripts/* tpc@alio2-cr1-flp$i:scripts/. &
	fi
	if [[ $links == 1 ]]; 
	then 
	   echo ssh tpc@alio2-cr1-flp$i "source ./scripts/check_links_status_filter.sh"; 
	fi
	if [[ $cru_config == 1 ]]; then
		if [[ $j -eq 145 ]]; then
			echo Send config to $i
			echo ssh tpc@alio2-cr1-flp$i "/home/tpc/build/bin/tpc_initialize.sh --id 3b:00.0 -m 0xc3 --syncbox -d" 
		else
			 echo ssh tpc@alio2-cr1-flp$i "source ./scripts/cru_config.sh" &
		 fi
	fi
	if [[ $cru_config_force == 1 ]]; then 
		echo ssh tpc@alio2-cr1-flp$i "source ./scripts/cru_config_force.sh" & 
	fi
	if [[ $alf == 1 ]]; 
	then 
		echo ssh tpc@alio2-cr1-flp$i "source ./scripts/restart_alf.sh"; 
	fi
	if [[ $rescan == 1  ]]; 
	then 
		echo ssh tpc@alio2-cr1-flp$i "sudo ./scripts/rescan.sh 1"; 
	fi
	if [[ $alf_force == 1 ]]; 
	then 
		echo ssh tpc@alio2-cr1-flp$i "source ./scripts/restart_alf.sh 1"; 
	fi
	if [[ $pat == 1  ]]; then 
		echo ssh tpc@alio2-cr1-flp$i "source ./scripts/pat.sh $pat_tf $pat_bc" & 
	fi


done
