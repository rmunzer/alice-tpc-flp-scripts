#!/bin/bash

usage() {
  usage="Usage:
  create_calib_files.sh <required arguments> [optional arguments]
  
  Calib selection
  -c, --cmc    :  CMC parameters
  -p, --pedestal : Pedestal/Nosie parameters
  -i, --itf : ITF Parameters
  
  optional arguments:
  -o, --outputDir=          : set output directory for (default: ./)
  -m, --minADC=             : minimal ADC value accepted for threshold (default: $minADC)
  -s, --sigmaNoise=         : number of sigmas for the threshold (default: $sigmaNoise)
  -p, --pedestalOffset=     : pedestal offset value
  -f, --onlyFilled          : only write links which have data
  -k, --noMaskZero          : don't set pedetal value of missing pads to 1023
  -h, --help                : show this help message
  -n, --noisyThreshold	  : threshold for noisy channel treatment (default: $noisyThreshold)
  -y, --sigmaNoiseNoisy     : sigmaNoise for noisy channels (default: $sigmaNoiseNoisy)
  -b, --badChannelThreshold : noise threshold to mask channels (default: $badChannelThreshold)"
  
  echo "$usage"
}
    
usageAndExit() {
  usage
  if [[ "$0" =~ create_calib_files.sh ]]; then
     exit 0
  else
     return 0
  fi
 }
                    
# ===| default variable values |================================================
  fileInfo=
  cmc=0
  itf=0
  pad=0
  inputDir=cdb-prod
  outputDir=./calib_files
  minADC=2
  sigmaNoise=3
  pedestalOffset=0
  onlyFilled=0
  maskZero=1
  noisyThreshold=1.5
  sigmaNoiseNoisy=4
  badChannelThreshold=6
                   
# ===| parse command line options |=============================================
OPTIONS=$(getopt -l "cmc,itf,pedestal,minADC:,sigmaNoise:,pedestalOffset:,noisyThreshold:,sigmaNoiseNoisy:,badChannelThreshold:,onlyFilled,noMaskZero,help" -o "o:t:m:s:n:y:b:fkhcip" -n "create_calib_files.sh" -- "$@")
                    
if [ $? != 0 ] ; then
  usageAndExit
fi
eval set -- "$OPTIONS"

while true; do
  case "$1" in
      --) shift; break;;
      -i|--itf) itf=1; shift;;
      -c|--cmc) cmc=1; shift;;
      -p|--pedestal) pad=1; shift;;
      -o|--outputDir) outputDir=$2; shift 2;;
      -m|--minADC) minADC=$2; shift 2;;
      -s|--sigmaNoise) sigmaNoise=$2; shift 2;;
      -f|--onlyFilled) onlyFilled=1; shift;;
      -k|--noMaskZero) maskZero=0; shift;;
      -n|--noisyThreshold) noisyThreshold=$2; shift 2;;
      -y|--sigmaNoiseNoisy) sigmaNoiseNoisy=$2; shift 2;;
      -b|--badChannelThreshold) badChannelThreshold=$2; shift 2;;
      -h|--help) usageAndExit;;
      *) echo "Internal error!" ; exit 1 ;;
   esac
done
                                                          
# ===| check for required arguments |===========================================

echo $cmc $itf $pad

if [[ $pad == 1 ]];
then 
	echo "Create Pedestal/Noise calib File(s)"
	options="-i $inputDir -o $outputDir -s $sigmaNoise -y $sigmaNoiseNoisy -b $badChannelThreshold -m $minADC -y $sigmaNoiseNoisy -n $noisyThreshold"
	if [[ $maskZero -eq 0 ]]; then options="$options -k"; fi
	if [[ $onlyFilled -eq 1 ]]; then options="$options -f"; fi

	echo ./data_scripts/pedestal/preparePedestalFiles.sh $options
	./data_scripts/pedestal/preparePedestalFiles.sh $options
fi
if [[ $cmc == 1 ]];
then 
	echo "Create CMC calib File(s)"
	echo ./data_scripts/pulser/prepareCMFiles.sh -i $inputDir -o $outputDir
	./data_scripts/pulser/prepareCMFiles.sh -i $inputDir -o $outputDir
fi
if [[ $itf == 1 ]];
then 
	echo "Create ITF calib File(s)"
	./data_scripts/puslser/prepareITFFiles.sh -i $inputDir -o $outputDir
fi



