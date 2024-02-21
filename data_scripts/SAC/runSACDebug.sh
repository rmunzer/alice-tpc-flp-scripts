#!/bin/bash


inputFile=$1

alien-token-init

cp /data/wiechula/tmp/SAC_test/input.cfg ./
sed -i "s|filePath=.*|filePath=${inputFile}|" input.cfg

ARGS_ALL="-b --shm-segment-size $((12<<30))"

o2-raw-file-reader-workflow $ARGS_ALL \
 --input-conf input.cfg \
 --onlyDet TPC \
 --nocheck-tf-start-mismatch --nocheck-starts-with-tf --nocheck-hbf-per-tf --nocheck-tf-per-link --nocheck-hbf-jump --nocheck-packet-increment \
| o2-tpc-sac-processing $ARGS_ALL \
 --debug-level $((0x203)) \
 --try-re-align 2 \
 --nthreads-decoding 1 \
 --aggregate-tfs 1 
| o2-run $ARGS_ALL
