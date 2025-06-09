declare -x http_proxy=10.161.69.44:8080
declare -x https_proxy=10.161.69.44:8080
start=10670
stop=10678
if [ ! -z ${1} ];then
	start=${1}
fi
if [ ! -z ${2} ];then
	stop=${2}
fi
python /home/rc/alice-tpc-flp-scripts/data_scripts/bk/draw_lhc_fill_data.py -f $start -t $stop -c pp -e 13.8
