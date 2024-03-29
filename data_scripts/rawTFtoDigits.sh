ARGS_ALL="--session default --shm-segment-size $((20<<30))"

NCPU=2

o2-raw-tf-reader-workflow $ARGS_ALL \
  --input-data $1 \
  --onlyDet TPC \
  --max-cached-files 2 \
  --max-cached-tf 1 \
  | o2-tpc-raw-to-digits-workflow $ARGS_ALL \
  --input-spec "A:TPC/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0" \
  --configKeyValues "TPCDigitDump.LastTimeBin=57024;TPCDigitDump.ADCMin=0;keyval.output_dir=/dev/null" \
  --remove-duplicates \
  --severity info \
  --ignore-grp \
  | o2-tpc-reco-workflow $ARGS_ALL \
  --input-type digitizer \
  --output-type digits \
  --disable-mc \
  --configKeyValues "keyval.output_dir=/dev/null" \
  | o2-dpl-run $ARGS_ALL -b --run


#  --ignore-trigger \
