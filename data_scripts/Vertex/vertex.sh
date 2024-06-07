#!/bin/bash

usage() {
  usage="Usage:
vertex.sh <required arguments> [optional arguments]

required arguments
-f, --fill=        :  Fillnumber (9618), Weeknumber (e.g 19) , Timestamp (e.g. 1713484800-1715786054, ppprod-now , md1,vdmstart,vdmend,md2,ts1)
-m,--massicopy=    :  Copy files to Massifolder (default=0)

optional arguments:
-o, --outputDir=          : set output directory for (default: ~/vertex/)"
  echo "$usage"
}

usageAndExit() {
  usage
  if [[ "$0" =~ vertex.sh ]]; then
    exit 0
  else
    return 0
  fi
}

# ===| default variable values |================================================
fillN=9570
outfolder="/home/rc/vertex/"
massicopy=0;

# ===| parse command line options |=============================================
OPTIONS=$(getopt -l "fill:,outputDir:massicopy:,help" -o "f:o:m:h" -n "vdrift.sh" -- "$@")

if [ $? != 0 ] ; then
  usageAndExit
fi

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    --) shift; break;;
    -f|--fill) fillN=$2; shift 2;;
    -o|--outputDir) outfolder=$2; shift 2;;
    -m|--massicopy) massicopy=$2; shift 2;;
    -h|--help) usageAndExit;;
     *) echo "Internal error!" ; exit 1 ;;
   esac
done

# ===| check for required arguments |===========================================
if [[ -z "$fillN" ]]; then
  usageAndExit
fi

# ===| command building and execution |=========================================
# # . ~/.bashrc
firsttime=$fillN
lasttime=0;
if [[ $fillN == *"-"* ]]; then
  IFS='-'
  read -ra newarr <<< "$fillN"
  i=0;
  for val in "${newarr[@]}";
  do
	echo $i - "$val"
	if [[ $val == "now" ]];
		then
			val=`date +"%s"`
	fi
	if [[ $val == "ppprod" ]];
		then
			val=1713484800
	fi
	if [[ $val == "md1" ]];
		then
			val=1715611601
	fi
	if [[ $val == "vdmstart" ]];
		then
			val=1715849201
	fi
	if [[ $val == "vdmend" ]];
		then
			val=1716108401
	fi
	if [[ $val == "md2" ]];
		then
			val=1718376401
	fi
	if [[ $val == "ts1" ]];
		then
			val=1718376401
	fi
	if [[ $i == 0 ]];
	then
		firsttime=$val
	fi
	if [[ $i == 1 ]];
	then
		lasttime=$val
	fi
	let i=i+1;
  done
  IFS=""
  outfolder_txt="/home/rc/vertex/"
else
	if [[ $lasttime > 0 ]];then
		outfolder_txt="/home/rc/vertex/"$fillN
	else
		if [[ $fillN < 100 ]]; then
			outfolder_txt="/home/rc/vertex/"
		else
			outfolder_txt="/home/rc/vertex/massi/"$firsttime
		fi
	fi
fi

mkdir $outfolder_txt
echo $outfolder
. ~/.bashrc
cmd="root.exe -l -n -q -x ~/alice-tpc-flp-scripts/data_scripts/Vertex/PlotVertex.C+g'($firsttime,$lasttime,\"$outfolder\",\"$outfolder_txt\",\"true\")'"
echo "running: $cmd"
eval $cmd
if [[ $massicopy == 1 ]];then
	echo scp -r $outfolder_txt lhcif:massiFiles		
	scp -r $outfolder_txt lhcif:massiFiles						
fi