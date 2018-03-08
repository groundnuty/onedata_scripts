#! /bin/bash

id=`docker ps -a | grep oneclient | awk '{print $1}'`

if [ "$1" == "1" ];then
    stats=`docker ps -a | grep oneclient | awk '{print $7}'`
    if [ "$stats" != "Up" ];then
        start_time=`date`
        echo -n $start_time > /root/scripts/start.log
        docker start $id >> /root/scripts/start.log
    fi
else
    docker start $id
fi
