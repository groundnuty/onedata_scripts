#!/bin/bash
# Setup environment variables
space_cofnig_file="/tmp/sfs.config"

# Get Configuration from file
ONEZONE_IP=`sed -n -e '/^ONEZONE_IP/p' $space_cofnig_file | awk -F"=" '{print $2}'`
ONEPROVIDER_IP="localhost"
ONEDATA_CREDS=`sed -n -e '/^ONEDATA_CREDS/p' $space_cofnig_file | awk -F"=" '{print $2}'`
SFS_SPACE_NAMES=`sed -n -e '/^SFS_SPACE_NAME/p' $space_cofnig_file | awk -F"=" '{print $2}'`
SFS_STORAGE_NAMES=`sed -n -e '/^SFS_STORAGE_NAME/p' $space_cofnig_file | awk -F"=" '{print $2}'`
STORAGE_SIZE=`sed -n -e '/^STORAGE_SIZE/p' $space_cofnig_file | awk -F"=" '{print $2}'`
SHARE_PATHS=`sed -n -e '/^SHARE_PATH/p' $space_cofnig_file | awk -F"=" '{print $2}'`


# Set URL address
ONEZONE_URL="https://"$ONEZONE_IP"/api/v3/onezone"
ONEPANEL_URL="https://"$ONEPROVIDER_IP":9443/api/v3/onepanel"

SPACE_NAME_ARR=(${SFS_SPACE_NAMES//,/ })
STORAGE_NAME_ARR=(${SFS_STORAGE_NAMES//,/ })
SHARE_PATH_ARR=(${SHARE_PATHS//,/ })

mount_point="mount_point"

echo ${#SPACE_NAME_ARR[@]}
for ((i=0;i<${#SPACE_NAME_ARR[@]};i++));do
    SFS_SPACE_NAME=${SPACE_NAME_ARR[$i]}
    SFS_STORAGE_NAME=${STORAGE_NAME_ARR[$i]}
    SHARE_PATH=${SHARE_PATH_ARR[$i]}
    echo $SFS_SPACE_NAME
    echo $SFS_STORAGE_NAME
    echo $SHARE_PATH
    # Create space on OneZone
    space_id=`curl -i -u $ONEDATA_CREDS -sS --tlsv1.2 -k -H 'Content-type: application/json' -d '
    {
      "name": "'$SFS_SPACE_NAME'"
    }'  -X POST "$ONEZONE_URL/user/spaces" | grep Location | awk -F '/' '{print$NF}' | awk '{sub(/([^0-9a-zA-Z])+$/,"",$NF);print}'`
    
    mkdir -p /mnt/oneprovider_data/$space_id
    mount_point="$mount_point,/mnt/oneprovider_data/$space_id"


    # Create SFS Storage on OnePanel
    curl -u $ONEDATA_CREDS -sS --tlsv1.2 -k -H 'Content-type: application/json' -d '
    {
      "'$SFS_STORAGE_NAME'" : {
           "type" : "posix",
           "mountPoint" : "/volumes/storage"
      }    
    }'  -X POST "$ONEPANEL_URL/provider/storages"

    sleep 2
    # Get Storage ID on OneZone
    storage_info=`curl -u $ONEDATA_CREDS -sS --tlsv1.2 -k -H 'Content-type: application/json' -X GET "$ONEPANEL_URL/provider/storages" | awk -F '\"' '{for (i = 4; i < NF; i+=2) print $i}'`
    echo $storage_info
    for line in $storage_info
    do 
        if [ $line != "," ]; then
            storage_name=`curl -u $ONEDATA_CREDS -sS --tlsv1.2 -k -H 'Content-type: application/json' -X GET "$ONEPANEL_URL/provider/storages/$line" | jq '.name' | awk -F '\"' '{print$2}'`
            echo $storage_name
            if [ "${storage_name}" == "${SFS_STORAGE_NAME}" ]; then 
                storage_id=$line
                echo "Storage name is "$storage_name
                break
            fi 
        else 
            break
        fi 
    done

    # Get Space Token
    space_token=`curl -u $ONEDATA_CREDS -sS --tlsv1.2 -k -H 'Content-type: application/json' -X POST "$ONEZONE_URL/spaces/$space_id/providers/token" | jq '.token' | awk -F '\"' '{print$2}'`

    # Create space on OneProvider
    curl -u $ONEDATA_CREDS -sS --tlsv1.2 -k -H 'Content-type: application/json' -d '
    {
      "size": "'$STORAGE_SIZE'", 
      "storageName": "'$storage_name'", 
      "storageId": "'$storage_id'",
      "token": "'$space_token'"
    }'   -X POST "$ONEPANEL_URL/provider/spaces"

    mount -t nfs $SHARE_PATH /mnt/oneprovider_data/$space_id
    sleep 2

done

mount_point=`echo $mount_point | awk -F "mount_point," '{print $2}'`
echo "MOUNT_POINT=$mount_point" >> /root/scripts/sfs.config
echo "ONEDATA_CREDS=$ONEDATA_CREDS" >> /root/scripts/sfs.config
grep 'SHARE_PATH' /tmp/sfs.config >> /root/scripts/sfs.config
