#!/bin/bash

# Run this script under /root/

# On secondary node, we currently create two partitions on the NVMe by fdisk.
# By default, we first delete /dev/nvme0n1p3 and /dev/nvme0n1p4, and then create two new partitions
# with size 100GB and size of the rest space of storage.

# Example setup(view by 'p' in fdisk)
# Device         Boot     Start       End   Sectors   Size Id Type
# /dev/nvme0n1p1 *         2048  33556479  33554432    16G 83 Linux
# /dev/nvme0n1p2       33556480  39847935   6291456     3G  0 Empty
# /dev/nvme0n1p3       39847936 249563135 209715200   100G 83 Linux
# /dev/nvme0n1p4      249563136 500118191 250555056 119.5G 83 Linux

# The system by default would set /dev/nvme0n1p3 as the swap space, and we need to turn it off by:
# swapoff /dev/nvme0n1p3

BLOCK_DEVICE="nvme0n1p4"

# Mount the disk /dev/sdb to /mnt/sdb for more disk spaces
echo y | sudo mkfs.ext4 /dev/$BLOCK_DEVICE
sudo mkdir /mnt/sdb
sudo mount /dev/$BLOCK_DEVICE /mnt/sdb
# Then run everything under /mnt/sdb

sudo apt update

# Install Java
echo y | sudo apt install default-jdk
echo y | sudo apt install default-jre

# Install Maven
echo y | sudo apt install maven

# Install cgroup tools
echo y | sudo apt install cgroup-tools

sudo apt-get install libgflags-dev

mv ./EECS_6897_Distributed_Storage_System_Project_Scripts /mnt/sdb/scripts

# build grpc
cd /mnt/sdb/script/setup_scripts/gRPC
sudo bash grpc_setup.sh

# build rocksdb
cd /mnt/sdb
git clone -b rubble https://github.com/camelboat/my_rocksdb
cd my_rocksdb
cmake .
make -j32

# build rubble 
cd rubble
make rocksdb_server





