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

# Vimrc
cd /root/
wget https://gist.githubusercontent.com/simonista/8703722/raw/d08f2b4dc10452b97d3ca15386e9eed457a53c61/.vimrc

sudo apt update

# Install Java
echo y | sudo apt install default-jdk
echo y | sudo apt install default-jre

# Install Maven
echo y | sudo apt install maven

# Install cgroup tools
echo y | sudo apt install cgroup-tools

# Install inotify-tools
echo y | sudo apt install inotify-tools

# Install sysstat for iostat
echo y | sudo apt install sysstat

# Install python3 virtualenv
echo y | sudo apt install python3-venv python-dev

# Install gflags
echo y | sudo apt install libgflags-dev

# Clone scripts and data
cd /mnt/sdb
git clone https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts.git
git clone https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Data.git

sudo mkdir -p /mnt/sdb/archive_dbs/sst_dir/sst_last_run
sudo mkdir -p /mnt/sdb/archive_dbs/compaction_meta
sudo mkdir -p /mnt/sdb/archive_dbs/manifest_meta

cd /mnt/sdb
git clone https://github.com/brianfrankcooper/YCSB
cd /mnt/sdb/YCSB
mvn -pl com.yahoo.ycsb:rocksdb-binding -am clean package

# For remote editor client.
chown -R cl3875 /mnt

# Check space of the disk where current path is
df -Ph . | tail -1 | awk '{print $4}'
