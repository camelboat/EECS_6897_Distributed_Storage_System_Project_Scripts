#!/bin/bash

wget http://content.mellanox.com/ofed/MLNX_OFED-3.4-1.0.0.0/MLNX_OFED_LINUX-3.4-1.0.0.0-ubuntu14.04-x86_64.tgz
tar -xvf MLNX_OFED_LINUX-3.4-1.0.0.0-ubuntu14.04-x86_64.tgz
cd MLNX_OFED_LINUX-3.4-1.0.0.0-ubuntu14.04-x86_64/
echo y | sudo ./mlnxofedinstall
sudo /etc/init.d/openibd restart
sudo /etc/init.d/opensmd restart
sudo mst start
