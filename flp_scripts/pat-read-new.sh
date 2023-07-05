#!/bin/bash


for i in $(roc-list-cards | grep CRU | awk '{print $1}')
do
    o2-roc-reg-read --id=#$i --ch=2 --address=00260004 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260008 
    o2-roc-reg-read --id=#$i --ch=2 --address=0026000C 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260010 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260014 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260018 
    o2-roc-reg-read --id=#$i --ch=2 --address=0026001C 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260020 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260024 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260028 
    o2-roc-reg-read --id=#$i --ch=2 --address=0026002C 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260030 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260034 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260038 
    o2-roc-reg-read --id=#$i --ch=2 --address=0026003C 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260040 
    echo ---------
done

exit 0
