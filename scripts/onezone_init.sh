#!/bin/bash -x

apt-get update

onezone_version=`sed -n -e '/^ONEZONE_VERSION/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
if [ "$onezone_version"x != "17.06.0-rc8"x ]
then
    cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
    sed -i "s/image: onedata\/onezone:17.06.0-rc8/image: onedata\/onezone:$onezone_version/" docker-compose-onezone.yml
fi

onezone_domain=`sed -n -e '/^ONEZONE_DOMAIN/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
if [ "$onezone_domain" != "NO_DOMAIN" ]
then
    ping -c 1 -q $onezone_domain
    if [ $? -eq 0 ]
    then
        #install certbot & create certs
        apt-get -y install software-properties-common

        echo "\n" | add-apt-repository ppa:certbot/certbot
        apt-get update
        apt-get -y install certbot

        echo 'A' | certbot certonly --standalone -d $onezone_domain --register-unsafely-without-email

        mkdir -p /opt/onezone/certs
        cd /opt/onezone/certs
        ln -s /etc/letsencrypt/live/$onezone_domain/chain.pem cacert.pem
        ln -s /etc/letsencrypt/live/$onezone_domain/fullchain.pem cert.pem
        ln -s /etc/letsencrypt/live/$onezone_domain/privkey.pem key.pem

        cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
        sed -i 's/#- "${OZ_PRIV_KEY_PATH}/- "\/opt\/onezone\/certs\/key.pem/' docker-compose-onezone.yml
        sed -i 's/#- "${OZ_CERT_PATH}/- "\/opt\/onezone\/certs\/cert.pem/' docker-compose-onezone.yml
        sed -i 's/#- "${OZ_CACERT_PATH}/- "\/opt\/onezone\/certs\/cacert.pem/g' docker-compose-onezone.yml
    fi
fi

#Update and Install docker
apt-get -y install docker.io

#Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


#Download onezone software
#mkdir -p /home/ubuntu/onezone
#git clone https://github.com/onedata/getting-started /home/ubuntu/onedata

#Get Host Name
host_name=`hostname | awk -F"." '{print $1}'`

cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost

#Start onezone
if [ "$onezone_domain" != "NO_DOMAIN" ]
then
    echo n | ./run_onedata.sh --zone --name $host_name --zone-fqdn $onezone_domain --detach
else
    echo n | ./run_onedata.sh --zone --name $host_name --detach
fi

echo '*  *    * * *   root    sleep 10; /bin/bash /root/scripts/onezone_auto_start.sh 1' >> /etc/crontab
echo '*  *    * * *   root    sleep 40; /bin/bash /root/scripts/onezone_auto_start.sh 1' >> /etc/crontab
