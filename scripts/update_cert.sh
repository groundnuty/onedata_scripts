#!/bin/bash -x
email=$1
domain=$2

if [ -z $1 ] || [ -z $2 ];then
    echo "Please provider emal and domain name!"
    echo "Command like this: /bin/bash update_cert.sh email domain"
    exit
fi

id=`docker ps -a | awk '{print $1}'`
docker stop $id

echo '2' | certbot certonly --standalone --agree-tos -m $email -d $domain

if [ $? -eq 0 ];then
    id=`docker ps -a | awk '{print $1}'`
    docker restart $id
    echo
    echo "Update cert successed"
else
    echo
    echo "Update cert failed"
fi