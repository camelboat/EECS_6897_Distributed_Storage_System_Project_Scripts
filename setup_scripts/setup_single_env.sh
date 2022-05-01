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

BLOCK_DEVICE="/dev/nvme0n1p4"
RUBBLE_PATH="/mnt/sdb"
TMP_SCRIPT_PATH='/tmp/rubble_scripts'
OPERATOR="NO"

for i in "$@"
do
case $i in
    -b=*|--block-device=*)
    BLOCK_DEVICE="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--rubble-path=*)
    RUBBLE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    --operator)
    OPERATOR="YES"
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done


# Properly partition the /dev/nvme0n1p4 device into three partitions, mount
# and format them into ext4 FS.
sudo bash "${TMP_SCRIPT_PATH}/disk_partition.sh"

# Then run everything under /mnt/code

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
cd /mnt/sdb/scripts/setup_scripts/gRPC
sudo bash grpc_setup.sh

# Install gflags
echo y | sudo apt install libgflags-dev

# Install htop to monitor cpu and memory usage
echo y | sudo apt install htop

if [ ${OPERATOR} == "YES" ]; then
    pushd ./
    cd /tmp && python3 -m venv rubble_venv;
    source /tmp/rubble_venv/bin/activate
    pip install --upgrade pip
    popd
    echo $(pwd)
    pip install -r ../test_scripts/requirements.txt
fi

