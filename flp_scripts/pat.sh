#!/bin/bash


for i in $(roc-list-cards | grep CRU | awk '{print $1}')
do
    o2-roc-reg-write --id=#$i --ch=2 --address=0026003c --val=$1
    o2-roc-reg-write --id=#$i --ch=2 --address=00260040 --val=$2
done

exit 0
