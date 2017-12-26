#!/bin/bash -x

#Update and Install docker 
apt-get update
echo y | apt-get install docker.io

#Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


#Download onezone software
#mkdir -p /home/ubuntu/onezone
#git clone https://github.com/onedata/getting-started /home/ubuntu/onedata

#Get Host Name
host_name=`hostname | awk -F"." '{print $1}'`

cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
./run_onedata.sh --zone --name $host_name --detach
