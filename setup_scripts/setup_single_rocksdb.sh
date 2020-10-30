#!/bin/bash

cd /mnt/sdb
sudo git clone https://github.com/facebook/rocksdb.git
cd /mnt/sdb/rocksdb
sudo git checkout -b 97bf78721b7d9c1fa25e6a9b38b693d45e85196d
sed -i '24iJAVA_HOME = "/usr/lib/jvm/default-java"' Makefile
sudo make -j32 rocksdbjava

# Install YCSB and run the test
cd /mnt/sdb
git clone https://github.com/brianfrankcooper/YCSB/
cd YCSB/

# Load the database
./bin/ycsb load rocksdb -s \
-P /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/workload_16_50 \
-p rocksdb.dir=/mnt/sdb/rocksdb/ \
-p rocksdb.optionsfile=/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_1.ini \
-threads 4 \
| tee /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/load_data_1.csv

# Run the experiment
./bin/ycsb run rocksdb -s \
-P /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/workload_16_50 \
-p rocksdb.dir=/mnt/sdb/rocksdb/ \
-p rocksdb.optionsfile=/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_1.ini \
-threads 16 \
-p hdrhistogram.percentiles=50,90,95,99,99.9 \
| tee /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/run_data_1.csv

# Load the database
./bin/ycsb load rocksdb -s \
-P /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/workload_16_50 \
-p rocksdb.dir=/mnt/sdb/rocksdb/ \
-p rocksdb.optionsfile=/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_2.ini \
-threads 4 \
| tee /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/load_data_2_true.csv

# Run the experiment
./bin/ycsb run rocksdb -s \
-P /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/workload_16_50 \
-p rocksdb.dir=/mnt/sdb/rocksdb/ \
-p rocksdb.optionsfile=/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_2.ini \
-threads 16 \
-p hdrhistogram.percentiles=50,90,95,99,99.9 \
| tee /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/run_data_2_true.csv
