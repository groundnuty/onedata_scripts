#!/bin/bash -x

apt-get update
apt-get -y install unzip
apt-get -y install python

onezone_version=`sed -n -e '/^ONEZONE_VERSION/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
onezone_domain=`sed -n -e '/^ONEZONE_DOMAIN/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
email=`sed -n -e '/^EMAIL/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`

if [[ $onezone_version =~ ^18.02.0- ]];then
    rm -rf /home/ubuntu/onedata
    mkdir -p /home/ubuntu/onedata
    git clone https://github.com/onedata/getting-started /home/ubuntu/onedata

    cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
    sed -i "s/18.02.0.*/$onezone_version/" docker-compose-onezone.yml
    sed -i 's/ONEPANEL_GENERATE_TEST_WEB_CERT: "true"/ONEPANEL_GENERATE_TEST_WEB_CERT: "false"/' docker-compose-onezone.yml
    sed -i 's/ONEPANEL_GENERATED_CERT_DOMAIN: "node1.onezone"/ONEPANEL_GENERATED_CERT_DOMAIN: ""/' docker-compose-onezone.yml
    sed -i 's/ONEPANEL_TRUST_TEST_CA: "true"/ONEPANEL_TRUST_TEST_CA: "false"/' docker-compose-onezone.yml

    if [ "$onezone_domain" != "NO_DOMAIN" ]
    then
        ping -c 1 -q $onezone_domain
        if [ $? -eq 0 ]
        then
            if [ -e /root/obs/aksk.txt ]
            then
                python /root/obs/config.py
                cd /root/
                unzip onedata_cert.zip

                mkdir -p /opt/onezone/certs
                cd /opt/onezone/certs
                ln -s /root/onedata_cert/onezone/chain.pem chain.pem
                ln -s /root/onedata_cert/onezone/cert.pem cert.pem
                ln -s /root/onedata_cert/onezone/privkey.pem key.pem

                cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
                sed -i 's/#- "${OZ_PRIV_KEY_PATH}/- "\/opt\/onezone\/certs\/key.pem/' docker-compose-onezone.yml
                sed -i 's/#- "${OZ_CERT_PATH}/- "\/opt\/onezone\/certs\/cert.pem/' docker-compose-onezone.yml
                sed -i 's/#- "${OZ_CHAIN_PATH}/- "\/opt\/onezone\/certs\/chain.pem/g' docker-compose-onezone.yml
            else
                #install certbot & create certs
                apt-get -y install software-properties-common

                echo "\n" | add-apt-repository ppa:certbot/certbot
                apt-get update
                apt-get -y install certbot

                certbot certonly --standalone --agree-tos --test-cert -m $email -d $onezone_domain
                echo '2' | certbot certonly --standalone --agree-tos -m $email -d $onezone_domain --eff-email

                mkdir -p /opt/onezone/certs
                cd /opt/onezone/certs
                ln -s /etc/letsencrypt/live/$onezone_domain/chain.pem chain.pem
                ln -s /etc/letsencrypt/live/$onezone_domain/cert.pem cert.pem
                ln -s /etc/letsencrypt/live/$onezone_domain/privkey.pem key.pem

                cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
                sed -i 's/#- "${OZ_PRIV_KEY_PATH}/- "\/opt\/onezone\/certs\/key.pem/' docker-compose-onezone.yml
                sed -i 's/#- "${OZ_CERT_PATH}/- "\/opt\/onezone\/certs\/cert.pem/' docker-compose-onezone.yml
                sed -i 's/#- "${OZ_CHAIN_PATH}/- "\/opt\/onezone\/certs\/chain.pem/g' docker-compose-onezone.yml
            fi
        fi
    fi

else
    if [ "$onezone_version"x != "17.06.0-rc8"x ]
    then
        cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
        sed -i "s/image: onedata\/onezone:17.06.0-rc8/image: onedata\/onezone:$onezone_version/" docker-compose-onezone.yml
    fi

    if [ "$onezone_domain" != "NO_DOMAIN" ]
    then
        ping -c 1 -q $onezone_domain
        if [ $? -eq 0 ]
        then
            if [ -e /root/obs/aksk.txt ]
            then
                python /root/obs/config.py
                cd /root/
                unzip onedata_cert.zip

                mkdir -p /opt/onezone/certs
                cd /opt/onezone/certs
                ln -s /root/onedata_cert/onezone/chain.pem cacert.pem
                ln -s /root/onedata_cert/onezone/cert.pem cert.pem
                ln -s /root/onedata_cert/onezone/privkey.pem key.pem

                cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
                sed -i 's/#- "${OZ_PRIV_KEY_PATH}/- "\/opt\/onezone\/certs\/key.pem/' docker-compose-onezone.yml
                sed -i 's/#- "${OZ_CERT_PATH}/- "\/opt\/onezone\/certs\/cert.pem/' docker-compose-onezone.yml
                sed -i 's/#- "${OZ_CACERT_PATH}/- "\/opt\/onezone\/certs\/cacert.pem/g' docker-compose-onezone.yml
            else
                #install certbot & create certs
                apt-get -y install software-properties-common

                echo "\n" | add-apt-repository ppa:certbot/certbot
                apt-get update
                apt-get -y install certbot

                certbot certonly --standalone --agree-tos --test-cert -m $email -d $onezone_domain
                echo '2' | certbot certonly --standalone --agree-tos -m -d $onezone_domain --eff-email

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
    fi
fi
#Update and Install docker
apt-get -y install docker.io

#Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


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
