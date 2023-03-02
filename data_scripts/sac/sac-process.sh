nTFs=1000
ARGS_ALL=" --shm-segment-size 50000000000"

o2-raw-tf-reader-workflow --severity warning --onlyDet TPC --input-data run_531627.txt $ARGS_ALL \
| o2-tpc-sac-processing --severity info --condition-tf-per-query -1 $ARGS_ALL \
| o2-tpc-sac-distribute --timeframes ${nTFs} --output-lanes 1 $ARGS_ALL \
| o2-tpc-sac-factorize --timeframes ${nTFs} --nthreads-SAC-factorization 4 --input-lanes 1 $ARGS_ALL --debug true 
