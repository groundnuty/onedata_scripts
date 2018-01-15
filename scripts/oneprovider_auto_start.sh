#! /bin/bash

space_cofnig_file="/root/scripts/sfs.config"

if [ -e "$space_cofnig_file" ];then
    share_path=`sed -n -e '/^SHARE_PATH/p' $space_cofnig_file | awk -F"=" '{print $2}'`
    mount_point=`sed -n -e '/^MOUNT_POINT/p' $space_cofnig_file | awk -F"=" '{print $2}'`
    share_arr=(${share_path//,/ })
    mount_arr=(${mount_point//,/ })

    for ((i=0;i<${#share_arr[@]};i++));do
        if [ -d ${mount_arr[$i]} ]
        then
            echo ${share_arr[$i]} ${mount_arr[$i]}
            mount -t  nfs ${share_arr[$i]} ${mount_arr[$i]}
        fi
    done
fi

id=`docker ps -a | grep oneprovider | awk '{print $1}'`
docker start $id
