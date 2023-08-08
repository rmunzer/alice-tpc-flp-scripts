#!/bin/bash
prefix="/opt/o2/bin/"

if [[ -z $1 ]]; then
#     pat_tf=12C
     pat_tf=A
else
     pat_tf=$1
fi
if [[ -z $2 ]]; then
     pat_bc=1f
else
     pat_bc=$2
fi
pat_tf=`echo ${pat_tf#0x}`
pat_bc=`echo ${pat_bc#0x}`
resync=0x${pat_tf}${pat_bc}C04
echo $resync


for i in $(${prefix}roc-list-cards | grep CRU | awk '{print $1}')
do
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260004 --val=0xffffffff
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260008 --val=0xffff
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=0026000C --val=0x0
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260010 --val=0xfffff
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260014 --val=0xff00
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260018 --val=0x0
#    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=0026001C --val=0xfff00000
#    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260020 --val=0xffff
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=0026001C --val=0x0
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260020 --val=0xff00
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260024 --val=0x0
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260028 --val=0x20
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=0026002C --val=0x0
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260030 --val=0x20

#### RESET PATTERN
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260034 --val=0x0
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260038 --val=0x280
#### TIME_STAMP
    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260040 --val=${resync}
#    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260040 --val=0x12C1fC04
#    ${prefix}o2-roc-reg-write --id=#$i --ch=2 --address=00260040 --val=0x11fC04



done

