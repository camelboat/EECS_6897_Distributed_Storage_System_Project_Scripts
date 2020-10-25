#!/bin/bash

# Mount the disk /dev/sdb to /mnt/sdb for more disk spaces
sudo mkfs.ext4 /dev/sdb
sudo mkdir /mnt/sdb
sudo mount /dev/sdb /mnt/sdb

# Then run everything under /mnt/sdb
cd /mnt/sdb

echo y | sudo apt install default-jdk
echo y | sudo apt install default-jre
cd /mnt/sdb
git clone https://github.com/facebook/rocksdb.git
cd rocksdb
git checkout -b 97bf78721b7d9c1fa25e6a9b38b693d45e85196d
make -j32 rocksdbjava


./bin/ycsb load rocksdb -s -P workloads/workloada -p rocksdb.dir=~/rocksdb/ -p rocksdb.optionsfile=~/rocksdb_config/rocksdb.ini -threads 4
