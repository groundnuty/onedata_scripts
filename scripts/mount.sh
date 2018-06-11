#! /bin/bash -x

SFS_SPACE_NAME="SPACE_NAME_1,SPACE_NAME_2"
SHARE_PATH="SHARE_PATH_1,SHARE_PATH_2"

apt-get -y install nfs-common
apt-get install -y jq

ids=`curl -k -u admin:password https://localhost:9443/api/v3/onepanel/provider/spaces | awk -F '\"' '{for (i = 4; i < NF; i+=2) print $i}'`

SPACE_NAME_ARR=(${SFS_SPACE_NAME//,/ })
SHARE_PATH_ARR=(${SHARE_PATH//,/ })

for ((i=0;i<${#SPACE_NAME_ARR[@]};i++));do
    space=${SPACE_NAME_ARR[$i]}
    share_path=${SHARE_PATH_ARR[$i]}

    for line in $ids
    do
        if [ $line != "," ]; then
            space_name=`curl -u admin:password -k  "https://localhost:9443/api/v3/onepanel/provider/spaces/$line" | jq '.name' | awk -F '\"' '{print$2}'`

            if [ "$space_name" == "$space" ]; then
                echo "Space name is "$space
                mkdir /mnt/oneprovider_data/$line
                mount -t nfs $share_path /mnt/oneprovider_data/$line
                sleep 2
                break
            fi
        fi
    done
done

id=`docker ps -a | grep oneprovider | awk '{print $1}'`
docker restart $id
