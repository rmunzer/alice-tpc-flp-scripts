#!/bin/bash

usage() {
  usage="Usage:
  create_calib_files.sh <required arguments> [optional arguments]
  
  Action selection
  -i, --init          		:  Initial Script
  -l, --links         		:  Link Status
  -a, --alf           		:  Restart ALF
      --alf_force     		:  Restart ALF (force resart)
  -o, --oos_dump    		:  Dump performance of IDC output proxy
  -s, --start_flp=    		:  Start FLP
  -f, --stop_flp=     		:  Stop FLP
    , --all	                :  Use all FLPs
  -p, --pp 	      		:  COnfig pattern player
      --pp_read 	      	:  COnfig pattern player
      --pp_old	 	      	:  COnfig pattern player (old Pattern Player)
      --pp_tf=        		:  Skipped TF in pp for re-sync (=0x1)
      --pp_bc=        		:  BC for re-sync (=0x8)      
  -c, --cru_config    		:  Config CRU
      --cru_config_force    	:  Config CRU force
      --fw_copy=<file>          :  Copy firmware in to rescanning folder
      --fw_revert               :  Revert firmw in rescanning folder to golden version
      --fw_check                :  Execute roc-list-cards
  -r, --rescan        		:  Rescan (Reload Firmware)
      --pgen_start		:  Start random pattern generator
      --pgen_stop		:  Start random pattern generator
      --pgen_occ_min <value>    :  Set minimum occupancy for random pattern generator
      --pgen_occ_max <value>    :  Set maxmimum occupancy for random pattern generator 
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
  pat_new=0
#  pat_tf=12C
  pat_tf=A
#  pat_tf=ffff
  pat_bc=0x1f
  cru_config=0
  pp_read=0
  cru_config_force=0
  rescan=0
  rescan_full=0
  start_flp=0
  stop_flp=0
  all=0
  oos_dump=0
  firmware_copy=""
  firmware_revert=0
  firmware_check=0
  pgen_start=0
  pgen_stop=0
  pgen_min=0
  pgen_max=10

                   
# ===| parse command line options |=============================================
OPTIONS=$(getopt -l "pgen_start,pgen_stop,pgen_occ_min:,pgen_occ_max:,init,links,alf,alf_force,all,start_flp:,oos_dump,stop_flp:,fw_copy:,fw_revert,fw_check,pp,pp_new,pp_tf:,pp_bc:,pp_read,cru_config,cru_config_force,rescan,rescan_full,help" -o "s:f:ilapcrho" -n "flp_execute.sh" -- "$@")
                    
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
      -o|--oos_dump)   oos_dump=1; shift;;
      --alf_force) alf_force=1; shift;;
      -p|--pp) pat_new=1; shift;;
      --pp_read) shift 1;;
      --pp_tf) pat_tf=$2; shift 2;;
      --pp_bc) pat_bc=$2; shift 2;;
      --pp_old) pat=1; shift 1;;
      -c|--cru_config) cru_config=1; shift;;
      --cru_config_force) cru_config_force=1; shift;;
      -r|--rescan) rescan=1; shift;;
      --rescan_full) rescan_full=1; shift;;
      -s|--start_flp) start_flp=$2; shift 2;;
      -f|--stop_flp) stop_flp=$2; shift 2;;
      --all) start_flp=1; stop_flp=145; shift;;
      --fw_copy) firmware_copy=$2; shift 2;;
      --fw_revert) firmware_revert=1; shift;;
      --fw_check) firmware_check=1; shift;;
      --pgen_start) pgen_start=1; shift;;
      --pgen_stop) pgen_stop=1; shift;;
      --pgen_occ_min) pgen_min=$2; shift 2;;
      --pgen_occ_max) pgen_max=$2; shift 2;;
      -h|--help) usageAndExit; shift;;
      *) echo "Internal error!" ; exit 1 ;;
   esac
done
                                                          
# ===| check for required arguments |===========================================

echo $cmc $itf $pad
command=""
if [[ $start_flp -eq 0 ]];
then
    usageAndExit;
fi
if [[ $stop_flp -eq 0 ]];
then 
    stop_flp=$start_flp
fi
if [[ $start_flp -gt $stop_flp ]];
then
    usageAndExit;
fi


BASEDIR=$(dirname "$0")
echo Basedir: "$BASEDIR"

echo "Execute $command on FLPS ($start_flp..$stop_flp)"

for (( j=$start_flp; j<=$stop_flp; j++ ))
do 
	i=$(printf "%03d" $j)
	echo FLP: alio2-cr1-flp$i
	if [[ $init == 1 ]];
	then 
		echo copy files from ${BASEDIR}/flp_scripts/*

		ssh tpc@alio2-cr1-flp$i "mkdir -p /home/tpc/scripts/" &
		scp ${BASEDIR}/flp_scripts/* tpc@alio2-cr1-flp$i:scripts/. &
		sleep 0.1
	fi
	if [[ $oos_dump == 1 ]]; 
	then 
	   ssh tpc@alio2-cr1-flp$i "source ./scripts/out-of-sync-dump.sh"; 
	fi
	if [[ $links == 1 ]]; 
	then 
	   ssh tpc@alio2-cr1-flp$i "source ./scripts/check_links_status_filter.sh"; 
	fi
	if [[ $cru_config == 1 ]]; then
		if [[ $j -eq 145 ]]; then
			 Send config to $i
		#	 ssh tpc@alio2-cr1-flp$i "/home/tpc/build/bin/tpc_initialize.sh --id 3b:00.0 -m 0xc3 --syncbox -d" 
			 ssh tpc@alio2-cr1-flp$i "source ./scripts/cru_config_145.sh" &
		else
			 ssh tpc@alio2-cr1-flp$i "source ./scripts/cru_config.sh" &
		 fi
	fi
	if [[ $cru_config_force == 1 ]]; then 
		ssh tpc@alio2-cr1-flp$i "source ./scripts/cru_config_force.sh" & 
	fi
	if [[ $alf == 1 ]]; 
	then 
		ssh tpc@alio2-cr1-flp$i "source ./scripts/restart_alf.sh"; 
	fi
	if [[ $alf_force == 1 ]]; 
	then 
		ssh tpc@alio2-cr1-flp$i "source ./scripts/restart_alf.sh 1" & 
	fi
	if [[ $pat_old == 1  ]]; then 
		ssh tpc@alio2-cr1-flp$i "source ./scripts/pat.sh $pat_tf $pat_bc" &
	fi
	if [[ $pat_new == 1  ]]; then 
		ssh tpc@alio2-cr1-flp$i "source ./scripts/pat-new.sh $pat_tf $pat_bc" &
	fi
	echo $pat_read
	if [[ $pat_read == 1  ]]; then 
		ssh tpc@alio2-cr1-flp$i "source ./scripts/pat_read.sh" &
	fi
	if [[ $firmware_revert == 1  ]]; then 
		ssh tpc@alio2-cr1-flp$i "sudo mv /root/serial_update/cru-fw/cru.sof /root/serial_update/cru-fw/cru.sof.old" &
	fi
	if [[ $firmware_check == 1  ]]; then 
		echo "check FW"
		ssh tpc@alio2-cr1-flp$i "roc-list-cards" &
	fi
	if [[ $firmware_copy != ""  ]]; then 
		echo scp $firmware_copy tpc@alio2-cr1-flp$i:cru.sof
		echo ssh tpc@alio2-cr1-flp$i "sudo mv /home/tpc/cru.sof /root/serial_update/cru-fw/cru.sof" &
		scp $firmware_copy tpc@alio2-cr1-flp$i:cru.sof
		ssh tpc@alio2-cr1-flp$i "sudo mv /home/tpc/cru.sof /root/serial_update/cru-fw/cru.sof" &
		sleep 0.1
	fi
	if [[ $rescan == 1  ]]; 
	then 
		ssh tpc@alio2-cr1-flp$i "sudo /home/tpc/scripts/rescan.sh 1" & 
	fi
	if [[ $pgen_stop == 1  ]]; 
	then 
		ssh tpc@alio2-cr1-flp$i "/home/tpc/scripts/pgen_kill.sh" &
 	fi
	if [[ $pgen_start == 1  ]]; 
	then 
		ssh tpc@alio2-cr1-flp$i "/home/tpc/scripts/pgen-control.py --occupancy-min $pgen_min --occupancy-max $pgen_max" & 
	fi
	sleep 0.01


done
