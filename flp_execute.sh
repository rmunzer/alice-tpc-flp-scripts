start_flp=$2
stop_flp=$3

command=$1

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
	if [[ link == "links" ]]; then ssh tpc@alio2-cr1-flp$i "source ./scripts/check_links_status_filter.sh"; fi
	if [[ link == "cru_config" ]]; then ssh tpc@alio2-cr1-flp$i "source ./scripts/cru_config.sh"; fi
	if [[ link == "cru_config_force" ]]; then ssh tpc@alio2-cr1-flp$i "source ./scripts/cru_config_force.sh"; fi
	if [[ link == "restart_alf" ]]; then ssh tpc@alio2-cr1-flp$i "source ./scripts/check_links_status_filter.sh"; fi
	if [[ link == "rescan" ]]; then ssh tpc@alio2-cr1-flp$i "source ./scripts/rescan.sh"; fi
	if [[ link == "pat" ]]; then ssh tpc@alio2-cr1-flp$i "source ./scripts/pat.sh"; fi


done
