#!/bin/bash -x

#Update and Install docker 
apt-get update
echo y | apt-get install docker.io

#Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


#Download oneprovider software
#mkdir -p /home/ubuntu/oneprovider
#git clone https://github.com/onedata/getting-started /home/ubuntu/onedata

#Get Host Name and OneZone IP address
host_name=`hostname | awk -F"." '{print $1}'`
onezone_ip=`sed -n -e '/^ONEZONE_EIP_ADDR/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`

# mk provider data dir
mkdir -p /mnt/oneprovider_data

while true
do
    ret=`curl -k -i https://$onezone_ip | grep 'HTTP' | awk -F ' ' '{print $2}'`
    echo $ret
    if [ "$ret"x == "200"x ]
    then
        echo "onezone started"
        break
    else
        echo "waiting onezone start"
        sleep 5
    fi
done

cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
echo n | ./run_onedata.sh --provider --name $host_name --zone-fqdn $onezone_ip --set-lat-long --provider-data-dir '/mnt/oneprovider_data' --detach
