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

#Enable login with password
sudo sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo service ssh restart

