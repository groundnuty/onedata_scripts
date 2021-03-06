#!/bin/bash -x

apt-get update
apt-get -y install unzip
apt-get -y install python
apt-get install -y jq

oneprovider_version=`sed -n -e '/^ONEPROVIDER_VERSION/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
onezone_domain=`sed -n -e '/^ONEZONE_DOMAIN/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
oneprovider_domain=`sed -n -e '/^ONEPROVIDER_DOMAIN/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`
email=`sed -n -e '/^EMAIL/p' /tmp/user-inject.data | awk -F"=" '{print $2}'`

if [[ $oneprovider_version =~ ^18.02.0- ]];then

    rm -rf /home/ubuntu/onedata
    mkdir -p /home/ubuntu/onedata
    git clone https://github.com/onedata/getting-started /home/ubuntu/onedata

    cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
    sed -i "s/18.02.0.*/$oneprovider_version/" docker-compose-oneprovider.yml
    sed -i 's/ONEPANEL_GENERATE_TEST_WEB_CERT: "true"/ONEPANEL_GENERATE_TEST_WEB_CERT: "false"/' docker-compose-oneprovider.yml
    sed -i 's/ONEPANEL_GENERATED_CERT_DOMAIN: "node1.oneprovider"/ONEPANEL_GENERATED_CERT_DOMAIN: ""/' docker-compose-oneprovider.yml
    sed -i 's/ONEPANEL_TRUST_TEST_CA: "true"/ONEPANEL_TRUST_TEST_CA: "false"/' docker-compose-oneprovider.yml

    if [ "$oneprovider_domain" != "NO_DOMAIN" ]
    then
        ping -c 1 -q $oneprovider_domain
        if [ $? -eq 0 ]
        then
            if [ -e /root/obs/aksk.txt ]
            then
                python /root/obs/config.py
                cd /root/
                unzip onedata_cert.zip

                mkdir -p /opt/oneprovider/certs
                cd /opt/oneprovider/certs
                ln -s /root/onedata_cert/oneprovider/chain.pem chain.pem
                ln -s /root/onedata_cert/oneprovider/cert.pem cert.pem
                ln -s /root/onedata_cert/oneprovider/privkey.pem key.pem

                cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
                sed -i 's/#- "${OP_PRIV_KEY_PATH}/- "\/opt\/oneprovider\/certs\/key.pem/' docker-compose-oneprovider.yml
                sed -i 's/#- "${OP_CERT_PATH}/- "\/opt\/oneprovider\/certs\/cert.pem/' docker-compose-oneprovider.yml
                sed -i 's/#- "${OP_CHAIN_PATH}/- "\/opt\/oneprovider\/certs\/chain.pem/g' docker-compose-oneprovider.yml
            else
                #install certbot & create certs
                apt-get -y install software-properties-common

                echo "\n" | add-apt-repository ppa:certbot/certbot
                apt-get update
                apt-get -y install certbot

                certbot certonly --standalone --agree-tos --test-cert -m $email -d $oneprovider_domain --eff-email
                echo '2' | certbot certonly --standalone --agree-tos -m $email -d $oneprovider_domain --eff-email

                mkdir -p /opt/oneprovider/certs
                cd /opt/oneprovider/certs
                ln -s /etc/letsencrypt/live/$oneprovider_domain/chain.pem chain.pem
                ln -s /etc/letsencrypt/live/$oneprovider_domain/cert.pem cert.pem
                ln -s /etc/letsencrypt/live/$oneprovider_domain/privkey.pem key.pem

                cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
                sed -i 's/#- "${OP_PRIV_KEY_PATH}/- "\/opt\/oneprovider\/certs\/key.pem/' docker-compose-oneprovider.yml
                sed -i 's/#- "${OP_CERT_PATH}/- "\/opt\/oneprovider\/certs\/cert.pem/' docker-compose-oneprovider.yml
                sed -i 's/#- "${OP_CHAIN_PATH}/- "\/opt\/oneprovider\/certs\/chain.pem/g' docker-compose-oneprovider.yml
            fi
        fi
    fi

else
    if [ "$oneprovider_version"x != "17.06.0-rc8"x ]
    then
        cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
        sed -i "s/image: onedata\/oneprovider:17.06.0-rc8/image: onedata\/oneprovider:$oneprovider_version/" docker-compose-oneprovider.yml
    fi


    if [ "$oneprovider_domain" != "NO_DOMAIN" ]
    then
        ping -c 1 -q $oneprovider_domain
        if [ $? -eq 0 ]
        then
            if [ -e /root/obs/aksk.txt ]
            then
                python /root/obs/config.py
                cd /root/
                unzip onedata_cert.zip

                mkdir -p /opt/oneprovider/certs
                cd /opt/oneprovider/certs
                ln -s /root/onedata_cert/oneprovider/chain.pem cacert.pem
                ln -s /root/onedata_cert/oneprovider/cert.pem cert.pem
                ln -s /root/onedata_cert/oneprovider/privkey.pem key.pem

                cd /home/ubuntu/onedata/scenarios/3_0_oneprovider_onezone_multihost
                sed -i 's/#- "${OP_PRIV_KEY_PATH}/- "\/opt\/oneprovider\/certs\/key.pem/' docker-compose-oneprovider.yml
                sed -i 's/#- "${OP_CERT_PATH}/- "\/opt\/oneprovider\/certs\/cert.pem/' docker-compose-oneprovider.yml
                sed -i 's/#- "${OP_CACERT_PATH}/- "\/opt\/oneprovider\/certs\/cacert.pem/g' docker-compose-oneprovider.yml
            else
                #install certbot & create certs
                apt-get -y install software-properties-common

                echo "\n" | add-apt-repository ppa:certbot/certbot
                apt-get update
                apt-get -y install certbot

                certbot certonly --standalone --agree-tos --test-cert -m $email -d $oneprovider_domain --eff-email
                echo '2' | certbot certonly --standalone --agree-tos -m $email -d $oneprovider_domain --eff-email

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
    fi
fi

#Install docker
apt-get -y install docker.io

#Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


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
sleep 30
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
