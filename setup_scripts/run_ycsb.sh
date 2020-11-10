WORKLOAD_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/workload_16-50_95-5'
ROCKSDB_DIR='/mnt/sdb/archive_dbs/16-50_95-5/'
#ROCKSDB_CONFIG_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_auto_compaction.ini'
ROCKSDB_CONFIG_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_no_auto_compaction.ini'
RUN_OUT_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/16-50_95-5/run_16-50_95-5_no.csv'

# Make sure you copy both ROCKSDB_DIR and SST files dir before you run this script

cd /mnt/sdb/YCSB/

./bin/ycsb run rocksdb -s \
-P $WORKLOAD_FILE \
-p rocksdb.dir=$ROCKSDB_DIR \
-p rocksdb.optionsfile=$ROCKSDB_CONFIG_FILE \
-threads 16 \
-p hdrhistogram.percentiles=50,90,95,99,99.9 \
| tee $RUN_OUT_FILE;
