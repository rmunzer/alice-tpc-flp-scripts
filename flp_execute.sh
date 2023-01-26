command=$1
start_flp=$2
stop_flp=$3


echo "Execute $command on FLPS ($start_flp..$stop_flp)"

for (( j=$start_flp; j<=$stop_flp; j++ ))
do 
	i=$(printf "%03d" $j)
	echo FLP: alio2-cr1-flp$i
	if [[ $command == "init" ]];
	then 
		ssh tpc@alio2-cr1-flp$i "mkdir -p /home/tpc/scripts/" &
		scp ./flp_scripts/* tpc@alio2-cr1-flp$i:scripts/. &
	fi
	if [[ $command == "links" ]]; then ssh tpc@alio2-cr1-flp$i "source ./scripts/check_links_status_filter.sh"; fi
	if [[ $command == "cru_config" ]]; then
		if [[ $i -eq 145 ]]; then
			ssh tpc@alio2-cr1-flp$i "/home/tpc/build/bin/tpc_initialize.sh --id 3b:00.0 -m 0xc3 --syncbox -d"
		else
			 ssh tpc@alio2-cr1-flp$i "source ./scripts/cru_config.sh"; fi
		fi
	if [[ $command == "cru_config_force" ]]; then ssh tpc@alio2-cr1-flp$i "source ./scripts/cru_config_force.sh"; fi
	if [[ $command == "restart_alf" ]]; then ssh tpc@alio2-cr1-flp$i "source ./scripts/check_links_status_filter.sh"; fi
	if [[ $command == "rescan" ]]; then ssh tpc@alio2-cr1-flp$i "sudo ./scripts/rescan.sh"; fi
	if [[ $command == "pat" ]]; then ssh tpc@alio2-cr1-flp$i "source ./scripts/pat.sh"; fi


done
