#!/bin/bash

# Mount the disk /dev/sdb to /mnt/sdb for more disk spaces
echo y | sudo mkfs.ext4 /dev/sdb
sudo mkdir /mnt/sdb
sudo mount /dev/sdb /mnt/sdb
# Then run everything under /mnt/sdb

sudo apt update

# Install Java
echo y | sudo apt install default-jdk
echo y | sudo apt install default-jre

# Install Maven
sudo apt install maven

# Clone scripts and data
cd /mnt/sdb
git clone https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts.git
git clone https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Data.git

# Check space of the disk where current path is
df -Ph . | tail -1 | awk '{print $4}'
