#! /bin/bash

id=`docker ps -a | grep oneprovider | awk '{print $1}'`
if [ "$1" == "1" ];then
    stats=`docker ps -a | grep oneprovider | awk '{print $7}'`
    if [ "$stats" != "Up" ];then
        start_time=`date`
        echo -n $start_time > /root/scripts/start.log
        docker start $id >> /root/scripts/start.log
    fi

else
    space_cofnig_file="/root/scripts/sfs.config"

    if [ -e "$space_cofnig_file" ];then
        share_path=`sed -n -e '/^SHARE_PATH/p' $space_cofnig_file | awk -F "=" '{print $2}'`
        mount_point=`sed -n -e '/^MOUNT_POINT/p' $space_cofnig_file | awk -F "=" '{print $2}'`
        creds=`sed -n -e '/^ONEDATA_CREDS/p' $space_cofnig_file | awk -F "=" '{print $2}'`

        share_arr=(${share_path//,/ })
        mount_arr=(${mount_point//,/ })

        for ((i=0;i<${#share_arr[@]};i++));do
            space=`echo ${mount_arr[$i]} | awk -F '/' '{print $4}'`
            resp=`curl -i -k -u $creds https://localhost:9443/api/v3/onepanel/provider/spaces/$space | grep HTTP | awk '{print $2}'`
            if [ "$resp" == "200" ]
            then
                echo ${share_arr[$i]} ${mount_arr[$i]}
                mount -t  nfs ${share_arr[$i]} ${mount_arr[$i]}
            else
                rm -rf ${mount_arr[$i]}
            fi
        done
    fi

    docker restart $id
fi
