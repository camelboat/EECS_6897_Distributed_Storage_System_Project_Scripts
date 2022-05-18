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
OPERATOR="YES"

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

# Vimrc
# cd /root/
# wget https://gist.githubusercontent.com/simonista/8703722/raw/d08f2b4dc10452b97d3ca15386e9eed457a53c61/.vimrc

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

# Install htop to monitor cpu and memory usage
echo y | sudo apt install htop

# Install dstat to monitor per cpu usage
echo y | sudo apt install dstat

# Install python dependencies
if [ ${OPERATOR} == "YES" ]; then
    pushd ./
    cd /tmp && python3 -m venv rubble_venv;
    source /tmp/rubble_venv/bin/activate
    pip install --upgrade pip
    popd
    wget https://raw.githubusercontent.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts/rubble/test_scripts/requirements.txt
    echo $(pwd)
    pip install -r requirements.txt
fi
