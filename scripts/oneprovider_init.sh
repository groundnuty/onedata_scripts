#!/bin/bash -x

apt-get update

oneprovider_version=`sed -n -e '/^ONEPROVIDER_VERSION/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
if [ "$oneprovider_version"x != "17.06.0-rc8"x ]
then
    cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
    sed -i "s/image: onedata\/oneprovider:17.06.0-rc8/image: onedata\/oneprovider:$oneprovider_version/" docker-compose-oneprovider.yml
fi

onezone_domain=`sed -n -e '/^ONEZONE_DOMAIN/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
oneprovider_domain=`sed -n -e '/^ONEPROVIDER_DOMAIN/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
if [ "$oneprovider_domain" != "NO_DOMAIN" ]
then
    ping -c 1 -q $oneprovider_domain
    if [ $? -eq 0 ]
    then
        #install certbot & create certs
        apt-get -y install software-properties-common

        echo "\n" | add-apt-repository ppa:certbot/certbot
        apt-get update
        apt-get -y install certbot

        echo 'A' | certbot certonly --standalone -d $oneprovider_domain --register-unsafely-without-email

        mkdir -p /opt/oneprovider/certs
        cd /opt/oneprovider/certs
        ln -s /etc/letsencrypt/live/$oneprovider_domain/chain.pem cacert.pem
        ln -s /etc/letsencrypt/live/$oneprovider_domain/fullchain.pem cert.pem
        ln -s /etc/letsencrypt/live/$oneprovider_domain/privkey.pem key.pem

        cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
        sed -i 's/#- "${OP_PRIV_KEY_PATH}/- "\/opt\/oneprovider\/certs\/key.pem/' docker-compose-oneprovider.yml
        sed -i 's/#- "${OP_CERT_PATH}/- "\/opt\/oneprovider\/certs\/cert.pem/' docker-compose-oneprovider.yml
        sed -i 's/#- "${OP_CACERT_PATH}/- "\/opt\/oneprovider\/certs\/cacert.pem/g' docker-compose-oneprovider.yml
    fi
fi

#Install docker
apt-get -y install docker.io

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

#Start oneprovider
if [ "$oneprovider_domain" != "NO_DOMAIN" ]
then
    echo n | ./run_onedata.sh --provider --name $host_name --zone-fqdn $onezone_domain --provider-fqdn $oneprovider_domain --set-lat-long --provider-data-dir /mnt/oneprovider_data --detach

else
    echo n | ./run_onedata.sh --provider --name $host_name --zone-fqdn $onezone_ip --set-lat-long --provider-data-dir /mnt/oneprovider_data --detach
fi

if [ -e /tmp/sfs.config ]
then
    while true
    do
        ret=`curl -k -i https://localhost:9443 | grep 'HTTP' | awk -F ' ' '{print $2}'`
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

    apt-get -y install nfs-common

    cd  /root/scripts
    sleep 30
    /bin/bash sfs_storage_setup.sh

    id=`docker ps -a | grep oneprovider.sh | awk '{print $1}'`
    docker restart $id

fi

echo '*  *    * * *   root    sleep 10; /bin/bash /root/scripts/oneprovider_auto_start.sh 1' >> /etc/crontab
echo '*  *    * * *   root    sleep 40; /bin/bash /root/scripts/oneprovider_auto_start.sh 1' >> /etc/crontab