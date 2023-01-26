#!/bin/bash

skip=0
addrs=$(lspci | grep -i 'cern' | awk '{print $1}')
num_rescanned=0

for i in $addrs
do
    if [ $skip = 0 ]; then
	skip=1
	sn=`roc-reg-read --i=$i --ch=2 --add=0x00030818`
	sn0=`echo $sn | cut -c10-10`
	sn1=`echo $sn | cut -c8-8`
	sn2=`echo $sn | cut -c6-6`
	sn3=`echo $sn | cut -c4-4`
	sn=`echo $sn0$sn1$sn2$sn3`
	echo $sn
	host=`hostname -s`

	for j in 0 1
	do
	    roc-config --id=$sn:$j --byp --force --config-uri consul-json://alio2-cr1-hv-aliecs:8500/o2/components/readoutcard/${host}/cru/${sn}/$j  
	done
    else
	skip=0
    fi
done
