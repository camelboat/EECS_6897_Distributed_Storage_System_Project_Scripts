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

sudo apt update
sudo apt install mstflint

# Check Mellanox network controller
lspci | grep Mellanox

DEVICE_PCI_ADDR=$(lspci | grep Mellanox | awk '{print $1}')
DEVICE_PSID=$(mstflint -d $DEVICE_PCI_DIR q | grep PSID | awk '{print $2}')
# Find out that it is Dell's network adapter
# With PSID DEL0A30000019
# Download firmware from https://www.mellanox.com/support/firmware/dell
wget http://www.mellanox.com/downloads/firmware/fw-ConnectX3-rel-2_42_5000-0T483W-FlexBoot-3.4.752.bin.zip


sudo apt-get install libmlx4-1 infiniband-diags ibutils ibverbs-utils rdmacm-utils perftest
