#! /bin/bash
space_cofnig_file="/root/scripts/sfs.config"
id=`docker ps -a | grep oneprovider | awk '{print $1}'`

if [ "$1" == "1" ];then
    stats=`docker ps -a | grep oneprovider | awk '{print $7}'`
    if [ "$stats" != "Up" ];then
        start_time=`date`
        echo -n $start_time > /root/scripts/start.log
        docker start $id >> /root/scripts/start.log
    fi

    num=`df -h | grep 'sfs-nas1' | awk '{print $6}' | awk -F '/' '{print $4}' | wc -l`
    space_str=`df -h | grep 'sfs-nas1' | awk '{print $6}' | awk -F '/' '{print $4}'`
    share_path_str=`df -h | grep 'sfs-nas1' | awk '{print $1}'`

    if [ "$num" == "0" ];then
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
                    mkdir -p ${mount_arr[$i]}
                    chmod 777 ${mount_arr[$i]}
                    mount -t  nfs ${share_arr[$i]} ${mount_arr[$i]}
                else
                    rm -rf ${mount_arr[$i]}
                fi
            done

            if [ -z "$share_path" ];then
                exit
            fi
            docker restart $id
        fi
        exit
    else
        mount="mount"
        share="share"
        space_arr=(${space_str//,/ })
        share_path_arr=(${share_path_str//,/ })
        
        for ((i=1;i<=$num;i++));do
            space=${space_arr[$i]}
            share_path=${share_path_arr[$i]}

            resp=`curl -i -k -u admin:password https://localhost:9443/api/v3/onepanel/provider/spaces/$space | grep HTTP | awk '{print $2}'`
            if [ "$resp" != "200" ]
            then
                umount "/mnt/oneprovider_data/$space"
                rm -rf "/mnt/oneprovider_data/$space"
                sed -i "s/,\/mnt\/oneprovider_data\/$space//g" $space_cofnig_file
                sed -i "s/\/mnt\/oneprovider_data\/$space,//g" $space_cofnig_file
                sed -i "s/\/mnt\/oneprovider_data\/$space//g" $space_cofnig_file

                share_path=`echo $share_path | awk -F '/' '{print $2}'`
                sed -i "s/,sfs-nas1.eu-de.otc.t-systems.com:\/$share_path//g" $space_cofnig_file
                sed -i "s/sfs-nas1.eu-de.otc.t-systems.com:\/$share_path,//g" $space_cofnig_file
                sed -i "s/sfs-nas1.eu-de.otc.t-systems.com:\/$share_path//g" $space_cofnig_file
            else

                if [ -e "$space_cofnig_file" ];then
                    grep "$space" $space_cofnig_file > /dev/null
                    if [ "$?" == "1" ];then
                        
                        mount_point=`sed -n -e '/^MOUNT_POINT/p' $space_cofnig_file | awk -F "=" '{print $2}'`
                        share_path=`sed -n -e '/^SHARE_PATH/p' $space_cofnig_file | awk -F "=" '{print $2}'`

                        new_mount_point="/mnt/oneprovider_data/$space"
                        new_share_path=${share_path_arr[$i]}
                        mount_point="$mount_point,$new_mount_point"
                        share_path="$share_path,$new_share_path"

                        echo "MOUNT_POINT=$mount_point" > $space_cofnig_file
                        echo "ONEDATA_CREDS=admin:password" >> $space_cofnig_file
                        echo "SHARE_PATH=$share_path" >> $space_cofnig_file
                    fi
                else
                    new_mount_point="/mnt/oneprovider_data/$space"
                    new_share_path=${share_path_arr[$i]}
                    mount="$mount,$new_mount_point"
                    share="$share,$new_share_path"
                fi
            fi
        done
        if [ "$mount" != "mount" ];then
            mount=`echo $mount | awk -F "mount," '{print $2}'`
            share=`echo $share | awk -F "share," '{print $2}'`
            echo "MOUNT_POINT=$mount" > $space_cofnig_file
            echo "ONEDATA_CREDS=admin:password" >> $space_cofnig_file
            echo "SHARE_PATH=$share" >> $space_cofnig_file
        fi
    fi
fi
