#!/bin/bash

# Mount the disk /dev/sdb to /mnt/sdb for more disk spaces
echo y | sudo mkfs.ext4 /dev/sdb
sudo mkdir /mnt/sdb
sudo mount /dev/sdb /mnt/sdb

# Then run everything under /mnt/sdb

# Install rocksdb
echo y | sudo apt install default-jdk
echo y | sudo apt install default-jre
cd /mnt/sdb
sudo git clone https://github.com/facebook/rocksdb.git
cd /mnt/sdb/rocksdb
sudo git checkout -b 97bf78721b7d9c1fa25e6a9b38b693d45e85196d
sed -i '24iJAVA_HOME = "/usr/lib/jvm/default-java"' Makefile
sudo make -j32 rocksdbjava

# Install YCSB and run the test
sudo apt install maven
mv root/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb.ini /mnt/sdb/
cd /mnt/sdb
git clone https://github.com/brianfrankcooper/YCSB/
cd YCSB/

# Load the database
./bin/ycsb load rocksdb -s -P ./workloads/workloada -p rocksdb.dir=/mnt/sdb/rocksdb/ -p rocksdb.optionsfile=/mnt/sdb/rocksdb.ini -threads 4

# Run the experiment
./bin/ycsb run rocksdb -s -P ./workloads/workloada -p rocksdb.dir=/mnt/sdb/rocksdb/ -p rocksdb.optionsfile=/mnt/sdb/rocksdb.ini -threads 16 -p \
hdrhistogram.percentiles=50,90,95,99,99.9
