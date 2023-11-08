  ARGS_ALL+=" --severity info  --shm-segment-size 5000000000"
  
  PROXY_INSPEC="A:TPC/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0"
  CALIB_INSPEC="A:TPC/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0"
  
  CALIB_CONFIG="TPCCalibPulser.FirstTimeBin=80;TPCCalibPulser.LastTimeBin=260;TPCCalibPulser.NbinsQtot=250;TPCCalibPulser.XminQtot=10;TPCCalibPulser.XmaxQtot=510;TPCCalibPulser.NbinsWidth=100;TPCCalibPulser.XminWidth=0.3;TPCCalibPulser.XmaxWidth=0.7;TPCCalibPulser.MinimumQtot=30;TPCCalibPulser.MinimumQmax=25;TPCCalibPulser.XminT0=125;TPCCalibPulser.XmaxT0=145;TPCCalibPulser.NbinsT0=800"
  
  EXTRA_CONFIG=" "
  EXTRA_CONFIG="--calib-type pulser --publish-after-tfs 30 --max-events 120 --lanes 36"
  
  CCDB_PATH="--ccdb-path http://o2-ccdb.internal"
  HOST=localhost
  
  o2-raw-tf-reader-workflow --onlyDet TPC --input-data tfs.txt $ARGS_ALL \
#    | o2-tpc-calib-pad-raw $ARGS_ALL \
 #    --input-spec "$CALIB_INSPEC" \
 #    --configKeyValues "$CALIB_CONFIG;keyval.output_dir=/dev/null" \
 #    $EXTRA_CONFIG \
 #    | o2-calibration-ccdb-populator-workflow $ARGS_ALL \
 #    $CCDB_PATH \
 #    | o2-dpl-run $ARGS_ALL
