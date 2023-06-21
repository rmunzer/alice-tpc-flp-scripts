#!/bin/bash


for i in $(roc-list-cards | grep CRU | awk '{print $1}')
do
    o2-roc-reg-read --id=#$i --ch=2 --address=0026003c 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260040 
done

exit 0
