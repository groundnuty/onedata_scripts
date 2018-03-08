#!/bin/bash -x

apt-get update

oneclient_version=`sed -n -e '/^ONECLIENT_VERSION/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
onezone_ip=`sed -n -e '/^ONEZONE_IP/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
oneprovoder_ip=`sed -n -e '/^ONEPROVIDER_IP/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
creds=`sed -n -e '/^ONEDATA_CREDS/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`

if [ "$oneclient_version"x != "17.06.0-rc8"x ]
then
    cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
    sed -i "s/image: onedata\/oneclient:17.06.0-rc8/image: onedata\/oneclient:$oneclient_version/" docker-compose-onezone.yml
fi

#Update and Install docker
apt-get -y install docker.io

#Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


#Download onezone software
#mkdir -p /home/ubuntu/onezone
#git clone https://github.com/onedata/getting-started /home/ubuntu/onedata

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

while true
do
    ret=`curl -k -i https://$oneprovoder_ip:9443 | grep 'HTTP' | awk -F ' ' '{print $2}'`
    echo $ret
    if [ "$ret"x == "200"x ]
    then
        echo "oneprovider started"
        break
    else
        echo "waiting oneprovider start"
        sleep 5
    fi
done

url="https://$onezone_ip:8443/api/v3/onezone/user/client_tokens"
token_info=`curl -u $creds -sS --tlsv1.2 -k -H 'Content-type: application/json' -X POST $url`

token=`echo $token_info | awk -F '"' '{print $(NF-1)}'`
#Start oneclient
cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
./run_oneclient.sh -d -t $token -p $oneprovoder_ip

echo '*  *    * * *   root    sleep 10; /bin/bash /root/scripts/oneclient_auto_start.sh 1' >> /etc/crontab
echo '*  *    * * *   root    sleep 40; /bin/bash /root/scripts/oneclient_auto_start.sh 1' >> /etc/crontab
