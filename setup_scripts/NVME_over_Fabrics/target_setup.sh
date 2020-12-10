#!/usr/bin/env bash

# target server setup to enable NVMe over RoCE

#echo y | sudo mkfs.ext4 /dev/nvme0n1p4 # This is the part name for m510
#sudo mkdir /mnt/nvme0n1p4
#sudo mount /dev/nvme0n1p4 /mnt/nvme0n1p4


#set this to the ip addr of the target machine
IP_ADDR=10.10.1.2

modprobe nvmet
modprobe nvmet-rdma

# create a nvme subsystem called "nvme-target1"
mkdir /sys/kernel/config/nvmet/subsystems/nvme-target1
cd /sys/kernel/config/nvmet/subsystems/nvme-target1

#allow any host to connect to the target
echo 1 > attr_allow_any_host

mkdir namespaces/10
cd namespaces/10

echo -n /dev/nvme0n1 > device_path
echo 1 > enable

#setting nvme port
mkdir /sys/kernel/config/nvmet/ports/1
cd  /sys/kernel/config/nvmet/ports/1

echo ${IP_ADDR} > addr_traddr
echo rdma > addr_trtype
echo 4420 > addr_trsvcid
echo ipv4 > addr_adrfam


ln -s /sys/kernel/config/nvmet/subsystems/nvme-target1 /sys/kernel/config/nvmet/ports/1/subsystems/nvme-target1
