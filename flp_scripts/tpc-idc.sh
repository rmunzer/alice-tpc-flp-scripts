#!/usr/bin/env bash

# set -x;
set -e;
set -u;

WF_NAME=tpc-idc

cd ..

# DPL command to generate the AliECS dump
#o2-dpl-raw-proxy -b --session default --dataspec 'x:ZYX/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' \
#| o2-dpl-output-proxy -b --session default --dataspec 'x:ZYX/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' --o2-control $WF_NAME

export GLOBAL_SHMSIZE=$(( 16 << 30 )) #  GB for the global SHMEM
#PROXY_INSPEC="A:TPC/RAWDATA"
PROXY_INSPEC="x:TPC/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0"

OUTSPEC_IDC="x:TPC/1DIDC;x:TPC/IDCGROUP"
OUTSPEC=${PROXY_INSPEC}
# TODO: Adjust path to pedestal file
pedestalFile="/home/tpc/IDCs/FLP/Pedestals.root"


# TODO: Adjust path and check this ends up properly in the script
CRU_GEN_CONFIG_PATH='//'`pwd`'/etc/getCRUs.sh'
CRU_FINAL_CONFIG_PATH='$(/home/tpc/IDCs/FLP/getCRUs.sh)'
CRU_CONFIG_PARAM='cru_config_uri'

QC_GEN_CONFIG_PATH='json://'`pwd`'/scripts/etc/tpc-full-idc.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/tpc-full-idc'
QC_CONFIG_PARAM='qc_config_uri'


CRUS='\"$(/home/tpc/IDCs/FLP/getCRUs.sh)\"'
CRUS_LOCAL='$('`pwd`"/etc/getCRU.sh"
#CRUS='$(/tmp/getCRUs.sh)'
CRUIDS="11,13"
# TODO: Adjust merger and port, if the port is change this also must be done
#       in the merger script
MERGER=alio2-cr1-qts01
#MERGER=alio2-cr1-flp145
PORT=30453

ARGS_ALL="-b --session default "
#--shm-segment-size $GLOBAL_SHMSIZE"

o2-dpl-raw-proxy $ARGS_ALL \
  --dataspec "$PROXY_INSPEC" \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc://tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-tpc-idc-to-vector $ARGS_ALL \
  --crus ${CRUIDS} \
  --pedestal-file $pedestalFile \
  --severity info \
  --configKeyValues "keyval.output_dir=/dev/null" \
  | o2-tpc-idc-flp $ARGS_ALL \
  --propagateIDCs true \
  --crus ${CRUIDS} \
  --severity info \
  --configKeyValues "keyval.output_dir=/dev/null" \
  --lanes 1 \
  | o2-dpl-output-proxy $ARGS_ALL \
   --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
   --dataspec "${OUTSPEC}" \
  | o2-dpl-output-proxy $ARGS_ALL \
   --proxy-name tpc-idc-flp-merger-proxy \
   --proxy-channel-name tpc-idc-flp-merger-channel \
   --tpc-idc-flp-merger-proxy '--channel-config "name=tpc-idc-flp-merger-channel,method=connect,address=tcp://alio2-cr1-qts01:47734,type=push,transport=zeromq" ' \
   --dataspec "${OUTSPEC_IDC}" \
#   --o2-control $WF_NAME


# add the templated CRU config file path
ESCAPED_CRU_FINAL_CONFIG_PATH=$(printf '%s\n' "$CRU_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
sed -i /defaults:/\ a\\\ \\\ "${CRU_CONFIG_PARAM}":\ \""${ESCAPED_CRU_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml

# find and replace all usages of the CRU config path which was used to generate the workflow
ESCAPED_CRU_GEN_CONFIG_PATH=$(printf '%s\n' "$CRU_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/""${ESCAPED_CRU_GEN_CONFIG_PATH}""/{{ ""${CRU_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*



# add the templated QC config file path
ESCAPED_QC_FINAL_CONFIG_PATH=$(printf '%s\n' "$QC_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
sed -i /defaults:/\ a\\\ \\\ "${QC_CONFIG_PARAM}":\ \""${ESCAPED_QC_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml

# find and replace all usages of the QC config path which was used to generate the workflow
ESCAPED_QC_GEN_CONFIG_PATH=$(printf '%s\n' "$QC_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/""${ESCAPED_QC_GEN_CONFIG_PATH}""/{{ ""${QC_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*

sed -i "s/ZYX/{{ detector }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*



