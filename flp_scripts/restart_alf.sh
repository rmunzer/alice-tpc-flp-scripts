#!/bin/bash

good_port=`sudo netstat -tulpen | grep o2-alf | grep -c ":5100"`

Host=`hostname`
if [ $good_port -eq 0 ]
then
    echo Restart o2-alf on £HOST
    sudo systemctl restart o2-alf
fi
