#!/bin/bash

prefix="/opt/o2/bin/"

${prefix}o2-roc-list-cards > /root/serial_update/workspace/logs/before_last_rescan

skip=0
addrs=$(lspci | grep -i 'cern' | awk '{print $1}')
num_rescanned=0
jtag_cable=1
config_addrs=()

for i in $addrs
do
  if [ $skip = 0 ]; then
    skip=1
    firmware=$(${prefix}o2-roc-reg-read --id=$i --ch=2 --addr=0x4)
    if [ $firmware != "0xe4a5a46e" ] && [ $# == 0 ]; then
      continue
    fi
    # check if you need to load sof or rpd file
    if [ -f "/root/serial_update/cru-fw/cru.sof" ]; then
      /root/intelFPGA_pro/17.1/qprogrammer/bin/quartus_pgm --cable=$jtag_cable --mode=JTAG --operation="p;/root/serial_update/cru-fw/cru.sof"
      # increase jtag cable number
      let jtag_cable+=1
    else
      ${prefix}o2-roc-reg-write --id=$i --ch=2 --addr=0x20000 --val=0x0 > /dev/null
      ${prefix}o2-roc-reg-write --id=$i --ch=2 --addr=0x20004 --val=0x1 > /dev/null
    fi
    #add first endpoint for config
    config_addrs+=$i
    #care for second endpoint
    config_addrs+=" "
  else
    # if odd, not both endpoints added, add the second one
    # the following monstrosity allows us to have '{ #' (no space)
    # for the bash array length without jinja templating to a comment
    if [ $(( ${#config_addrs[@]} % 2 )) = 1 ]; then
      config_addrs+=$i
      config_addrs+=" "
    fi
    skip=0
  fi
done

modprobe -r uio_pci_dma

for i in $addrs
do
  num_rescanned=$((num_rescanned+1))
  echo 1 > /sys/bus/pci/devices/0000\:$i/remove
  sleep 1
done

sleep 3
echo 1 > /sys/bus/pci/rescan
sleep 1

modprobe uio_pci_dma

${prefix}o2-roc-list-cards > /root/serial_update/workspace/logs/after_last_rescan

# Configure the CARD using the configuration stored in CONSUL
skip=0
num_rescanned=0

for i in $config_addrs
do
  # configure the clock if fw reloaded
  ${prefix}o2-roc-config --id=$i --clock=ttc --links=0-11 --gbtmode=WB --downstreamdata=PATTERN --datapathmode=streaming --force --bypass
done


for i in $config_addrs
do
    if [ $skip = 0 ]; then
        skip=1
        sn=`${prefix}o2-roc-reg-read --i=$i --ch=2 --add=0x00030818`
        sn0=`echo $sn | cut -c10-10`
        sn1=`echo $sn | cut -c8-8`
        sn2=`echo $sn | cut -c6-6`
        sn3=`echo $sn | cut -c4-4`
        sn=`echo $sn0$sn1$sn2$sn3`
        #echo $sn
        host=`hostname -s`

        for j in 0 1
        do
            ${prefix}o2-roc-config --id=$sn:$j --byp --config-uri consul-json://localhost:8500/o2/components/readoutcard/${host}/cru/${sn}/$j
        done
    else
        skip=0
    fi
done

/home/tpc/scripts/pat-new.sh

exit 0
