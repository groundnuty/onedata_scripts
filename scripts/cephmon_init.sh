#!/bin/bash -x

#Update software 
apt-get update

#Install software
echo y | sudo apt-get install python2.7
echo y | sudo apt-get install python3.5
echo y | sudo apt-get install python-setuptools
sudo apt-get install ntp
sudo apt-get install openssh-server
echo y | sudo apt-get install expect

#Close FireWall
echo y | sudo apt-get remove iptables

#Install ceph-deploy
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
echo deb https://download.ceph.com/debian-hammer/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
echo y | sudo apt-get install ceph-deploy

#Create Ceph User
useradd -d /home/ceph-demo -m ceph-demo
echo "ceph-demo ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-demo
sudo chmod 0440 /etc/sudoers.d/ceph-demo

#Set Ceph User Password
var_username="ceph-demo"
var_password="Admin@123"

expect -c"
set timeout 30
spawn sudo passwd ceph-demo
expect \"*password:\"
send \"$var_password\n\"
expect \"*password:\"
send \"$var_password\n\"
expect eof;"

#Configure host and network
usr_data_file=/tmp/user-inject.data
CephMds1Host=`sed -n -e '/^CEPH_MDS1_HOST/p' $usr_data_file | awk -F"=" '{print $2}'`
CephMds1Ipaddr=`sed -n -e '/^CEPH_MDS1_IPADDR/p' $usr_data_file | awk -F"=" '{print $2}'`
CephOsd1Host=`sed -n -e '/^CEPH_OSD1_HOST/p' $usr_data_file | awk -F"=" '{print $2}'`
CephOsd1Ipaddr=`sed -n -e '/^CEPH_OSD1_IPADDR/p' $usr_data_file | awk -F"=" '{print $2}'`

CephMon1Host=`hostname | awk -F"." '{print $1}'`
CephMon1Ipaddr=`ifconfig ens5 | grep "inet addr" | awk '{ print $2}' | awk -F":" '{print $2}'`

#Configue /etc/hosts file
echo $CephMon1Ipaddr " " $CephMon1Host >> /etc/hosts
echo $CephMds1Ipaddr " " $CephMds1Host >> /etc/hosts
echo $CephOsd1Ipaddr " " $CephOsd1Host >> /etc/hosts

#Enable login with password
sudo sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo service ssh restart

#Copy ssh id to Other CEPH Nodes
su - ceph-demo<<EOF
cd ~

#Create KeyPair
expect -c"
set timeout 30
spawn ssh-keygen
expect \"*save the key*\"
send \"\n\"
expect \"*Enter passphrase*\"
send \"\n\"
expect \"*Enter same passphrase*\"
send \"\n\"
expect eof;"

echo "Host " $CephMon1Host >> /home/ceph-demo/.ssh/config
echo "    Hostname " $CephMon1Host >> /home/ceph-demo/.ssh/config
echo "    User ceph-demo" >> /home/ceph-demo/.ssh/config
echo "Host " $CephMds1Host >> /home/ceph-demo/.ssh/config
echo "    Hostname " $CephMds1Host >> /home/ceph-demo/.ssh/config
echo "    User ceph-demo" >> /home/ceph-demo/.ssh/config
echo "Host " $CephOsd1Host >> /home/ceph-demo/.ssh/config
echo "    Hostname " $CephOsd1Host >> /home/ceph-demo/.ssh/config
echo "    User ceph-demo" >> /home/ceph-demo/.ssh/config
sudo chmod 600 /home/ceph-demo/.ssh/config

sleep 5

#Upload KeyPair to other Hosts
expect -c"
set timeout 30
spawn ssh-copy-id ceph-demo@$CephMds1Host
expect \"*continue connecting*\"
send \"yes\n\"
expect \"*password*\"
send \"$var_password\n\"
expect eof;"

expect -c"
set timeout 30
spawn ssh-copy-id ceph-demo@$CephOsd1Host
expect \"*continue connecting*\"
send \"yes\n\"
expect \"*password*\"
send \"$var_password\n\"
expect eof;"

#Create CEPH Cluster
mkdir ceph-cluster
cd ceph-cluster

#Create Monitor Nodes
ceph-deploy new $CephMon1Host

echo "osd pool default size = 1" >> /home/ceph-demo/ceph-cluster/ceph.conf
echo "osd pool default min size = 1" >> /home/ceph-demo/ceph-cluster/ceph.conf
echo "osd pool default pg num = 512" >> /home/ceph-demo/ceph-cluster/ceph.conf
echo "osd pool default pgp num = 512" >> /home/ceph-demo/ceph-cluster/ceph.conf

#Install CEPH software to all nodes
ceph-deploy install $CephMon1Host $CephMds1Host $CephOsd1Host

#Install CEPH Monitor Nodes
ceph-deploy mon create-initial

#Install CEPH OSD Nodes
ceph-deploy osd create $CephMds1Host:/dev/xvdb $CephOsd1Host:/dev/xvdb

#Copy configuration and KEY file to all nodes
ceph-deploy admin $CephMon1Host $CephMds1Host $CephOsd1Host
sudo chmod +r /etc/ceph/ceph.client.admin.keyring

#Create CEPH pool
ceph osd pool create cephfs 128

exit;
EOF
