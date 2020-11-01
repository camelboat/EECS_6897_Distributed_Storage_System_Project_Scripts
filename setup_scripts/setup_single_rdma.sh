#!/bin/bash


#wget http://content.mellanox.com/ofed/MLNX_OFED-3.4-1.0.0.0/MLNX_OFED_LINUX-3.4-1.0.0.0-ubuntu14.04-x86_64.tgz
# wget http://content.mellanox.com/ofed/MLNX_OFED-3.4-1.0.0.0/MLNX_OFED_LINUX-3.4-1.0.0.0-ubuntu16.04-x86_64.tgz
wget http://content.mellanox.com/ofed/MLNX_OFED-4.4-1.0.0.0/MLNX_OFED_LINUX-4.4-1.0.0.0-ubuntu16.04-x86_64.tgz
tar -xvf MLNX_OFED_LINUX-3.4-1.0.0.0-ubuntu14.04-x86_64.tgz
cd MLNX_OFED_LINUX-3.4-1.0.0.0-ubuntu14.04-x86_64/
echo y | sudo ./mlnxofedinstall
sudo /etc/init.d/openibd restart
sudo /etc/init.d/opensmd restart
sudo mst start

sudo ./mlnxofedinstall --without-dkms --add-kernel-support --kernel 4.4.0-193-generic --without-fw-update --force

sudo ./mlnxofedinstall --add-kernel-support --force --skip-distro-check

# Check Mellanox network controller
lspci | grep Mellanox
