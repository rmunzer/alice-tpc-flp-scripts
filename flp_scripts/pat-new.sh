#!/bin/bash


for i in $(roc-list-cards | grep CRU | awk '{print $1}')
do
    o2-roc-reg-write --id=#$i --ch=2 --address=00260004 --val=0xffffffff
    o2-roc-reg-write --id=#$i --ch=2 --address=00260008 --val=0xffff
    o2-roc-reg-write --id=#$i --ch=2 --address=0026000C --val=0x0
    o2-roc-reg-write --id=#$i --ch=2 --address=00260010 --val=0xfffff
    o2-roc-reg-write --id=#$i --ch=2 --address=00260014 --val=0xff00
    o2-roc-reg-write --id=#$i --ch=2 --address=00260018 --val=0x0
#    o2-roc-reg-write --id=#$i --ch=2 --address=0026001C --val=0xfff00000
#    o2-roc-reg-write --id=#$i --ch=2 --address=00260020 --val=0xffff
    o2-roc-reg-write --id=#$i --ch=2 --address=0026001C --val=0x0
    o2-roc-reg-write --id=#$i --ch=2 --address=00260020 --val=0xff00
    o2-roc-reg-write --id=#$i --ch=2 --address=00260024 --val=0x0
    o2-roc-reg-write --id=#$i --ch=2 --address=00260028 --val=0x20
    o2-roc-reg-write --id=#$i --ch=2 --address=0026002C --val=0x0
    o2-roc-reg-write --id=#$i --ch=2 --address=00260030 --val=0x20

#### RESET PATTERN
    o2-roc-reg-write --id=#$i --ch=2 --address=00260034 --val=0x0
    o2-roc-reg-write --id=#$i --ch=2 --address=00260038 --val=0x200
#### TIME_STAMP
    o2-roc-reg-write --id=#$i --ch=2 --address=00260040 --val=0x12C1fC04



done

exit 0
