pid=`ps -x | grep python | grep pgen | awk '{print $1}'`
echo $pid
if [[ -z $pid ]]; then
        echo No process found 
else
        kill $pid
fi





