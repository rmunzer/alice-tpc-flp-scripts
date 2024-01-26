#!/bin/bash


for i in $(roc-list-cards | grep CRU | awk '{print $1}')
do
    echo "---- Pat 0 ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=00260004 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260008 
    o2-roc-reg-read --id=#$i --ch=2 --address=0026000C 
    echo "---- Pat 1 ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=00260010 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260014 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260018 
    echo "---- Pat 2 ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=0026001C 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260020 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260024 
    echo "----- Pat 1 length ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=00260028 
    echo "----- Pat 1 delay ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=0026002C 
    echo "----- Pat 2 length ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=00260030 
    echo "----- Pat 1 trigger_select ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=00260034 
    echo "----- Pat 2 trigger_select ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=00260038 
    echo "----- Pat 3 trigger_select ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=0026003C 
    echo "----- Pat 3 repeat ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=00260040 
    echo "----- Pat 3 length ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=00260044 
    echo "---- Pat 3 ----"
    o2-roc-reg-read --id=#$i --ch=2 --address=00260048 
    o2-roc-reg-read --id=#$i --ch=2 --address=0026004C 
    o2-roc-reg-read --id=#$i --ch=2 --address=00260050
    echo "----------------------------------------------------"
done

exit 0
