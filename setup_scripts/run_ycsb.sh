#!/bin/bash

# Example usage:

# ./run_ycsb.sh \
# -w workload_1-10_95-5 \
# -c rocksdb_auto_compaction.ini \
# -v 0 \
# -l 1-10_95-5/load_data_1-10_95-5_auto_compaction.csv \
# -r 1-10_95-5/run_data_1-10_95-5_auto_compaction.csv

# ./run_ycsb.sh \
# -w workload_1-10_95-5 \
# -c rocksdb_no_auto_compaction.ini \
# -v 1 \
# -l 1-10_95-5/load_data_1-10_95-5_no_auto_compaction.csv \
# -r 1-10_95-5/run_data_1-10_95-5_no_auto_compaction.csv

VERSION=0
ROCKSDB_REPO="https://github.com/facebook/rocksdb.git"
BRANCH="my_test_branch_2"
ROCKSDB_DIR="rocksdb"

while getopts w:c:v:l:r: flag
do
  case "${flag}" in
    w) WORKLOAD_FILE=${OPTARG};;
    c) CONFIGURATION_FILE=${OPTARG};;
    v) VERSION=${OPTARG};; # 0 for unmodified version, 1 for modified version
    l) LOAD_OUT_FILE=${ORTARG};;
    r) RUN_OUT_FILE=${OPTARG};;
  esac
done

# Without absolute path, all paths are concatenated after /mnt/sdb
echo "workload file path: $WORKLOAD_FILE";
echo "configuration file path: $CONFIGURATION_FILE";
echo "load output file path: $LOAD_OUT_FILE";
echo "run output file path: $RUN_OUT_FILE";
if [ $VERSION = 0 ];
then
  echo "use unmodified rocksdb";
else
  echo "use modified rocksdb";
  ROCKSDB_DIR="my_rocksdb"
  ROCKSDB_REPO="https://github.com/camelboat/my_rocksdb"
fi
echo "rocksdb working dir: $ROCKSDB_DIR";
echo "rocksdb repo: $ROCKSDB_REPO";

# Go to /mnt/sdb
cd /mnt/sdb

# Remove the last rocksdb instance
echo "Start removing $ROCKSDB_DIR";
rm -rf /mnt/sdb/$ROCKSDB_DIR;
echo "Finish removing";

# Download rocksdb and compile it
git clone $ROCKSDB_REPO;
cd $ROCKSDB_DIR
if [ $VERSION = 0 ];
then
  git checkout -b 97bf78721b7d9c1fa25e6a9b38b693d45e85196d;
else
  git checkout $BRANCH
fi
sed -i '24iJAVA_HOME = "/usr/lib/jvm/default-java"' Makefile
make -j32 rocksdbjava

# Go to the directory of YCSB and run benchmarks
cd /mnt/sdb/YCSB

# Load the database
./bin/ycsb load rocksdb -s \
-P /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/$WORKLOAD_FILE \
-p rocksdb.dir=/mnt/sdb/$ROCKSDB_DIR \
-p rocksdb.optionsfile=/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_auto_compaction.ini \
-threads 12 \
| tee /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/$LOAD_OUT_FILE;

# Run the experiment
./bin/ycsb run rocksdb -s \
-P /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/$WORKLOAD_FILE \
-p rocksdb.dir=/mnt/sdb/$ROCKSDB_DIR \
-p rocksdb.optionsfile=/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/$CONFIGURATION_FILE \
-threads 16 \
-p hdrhistogram.percentiles=50,90,95,99,99.9 \
| tee /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/$RUN_OUT_FILE;

cd /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/
git add *;
git commit -m "update data for $WORKLOAD_FILE, $CONFIGURATION_FILE, version=$VERSION, $LOAD_OUT_FILE, $RUN_OUT_FILE";
git push origin master;
