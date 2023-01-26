#!/bin/bash

addrs_ep0="
0x422040
0x442040
0x424040
0x444040
0x426040
0x446040
0x428040
0x448040
0x42a040
0x44a040
0x42c040
0x44c040
"
addrs_ep1="
0x462040
0x482040
0x464040
0x484040
0x466040
0x486040
0x468040
0x488040
0x46a040
0x48a040
0x46c040
0x48c040
"


# GET serial number
sn=()
for i in $(roc-list-cards | grep CRU | awk '{print $4}');
do
    sn+=( $i );
done

# GET end point
ep=()
for i in $(roc-list-cards | grep CRU | awk '{print $5}');
do
    ep+=( $i );
done

skip=0
idx=0
for i in ${sn[@]}
do
    link_num=0

    # get opticl power
    link_op=()
    for op in $(roc-status --i=$i:${ep[$idx]} | grep Stre | awk '{print $10}')
    do
	link_op+=( $op )
    done

    # EP 0
    if [[ "${ep[$idx]}" == "0" ]]
    then	
	for addr in $addrs_ep0
	do
	    # If there is OP in the link I check
	    if [[ "${link_op[$link_num]}" != "0.0" ]] 
	    then		  
	    	addr_hex=`printf "0x%X" $(( $addr+4 ))`
		res=`o2-roc-reg-read --i=$i --ch=2 --add=$addr_hex`
		if [[ "$res" != "0x0" ]]
		then
		    echo "CRU $i EP ${ep[$idx]} link $link_num error detected [$res] ... reset counter"
		    # reset counter
		    o2-roc-reg-write --i=$i --ch=2 --add=$addr --value=0x0 > /dev/null
		fi
	    fi
	    (( link_num=$link_num+1 ))
	done
    else
	# EP 1
	for addr in $addrs_ep1
	do
	    # If there is OP in the link I check
	    if [[ "${link_op[$link_num]}" != "0.0" ]] 
	    then		  
	    	addr_hex=`printf "0x%X" $(( $addr+4 ))`
		res=`o2-roc-reg-read --i=$i --ch=2 --add=$addr_hex`
		
		if [[ "$res" != "0x0" ]]
		then
		    echo "CRU $i EP ${ep[$idx]} link $link_num error detected [$res] ... reset counter"
		    # reset counter
		    o2-roc-reg-write --i=$i --ch=2 --add=$addr --value=0x0 > /dev/null
		fi
	    fi
	    (( link_num=$link_num+1 ))
	done
    fi
    (( idx=$idx+1 ))
done
