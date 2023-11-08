CONSUL=http://alio2-cr1-hv-aliecs:8500
consul kv get -recurse -keys -http-addr=$CONSUL o2/components/qc/ANY/any/tpc/tpc-full-qcmn > /tmp/key
consul kv get -recurse -keys -http-addr=$CONSUL o2/components/qc/ANY/any/tpc/tpc-full-synthetic-qcmn > /tmp/key
consul kv get -recurse -keys -http-addr=$CONSUL o2/components/qc/ANY/any/tpc/tpc-full-cosmics-qcmn > /tmp/key

for i in $(cat /tmp/key)
    do
        echo $i
	file=`echo $i | cut -f 6 -d '/'` 
	echo $file
        consul kv get -http-addr=$CONSUL $i > $file
done
