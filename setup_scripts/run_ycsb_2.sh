WORKLOAD_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/workload_1-10_95-5'
ROCKSDB_DIR='/mnt/sdb/archive_dbs/1-10_95-5/'
LOAD_OUT_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/load_1-10_95-5.csv'
ROCKSDB_CONFIG_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_auto_compaction.ini'
RUN_OUT_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/1-10_95-5/run_1-10_95-5_auto.csv'

cd /mnt/sdb/ycsb/

./bin/ycsb load rocksdb -s \
-P $WORKLOAD_FILE \
-p rocksdb.dir=$ROCKSDB_DIR \
-p rocksdb.optionsfile=$ROCKSDB_CONFIG_FILE \
-threads 12 \
| tee $LOAD_OUT_FILE;

# ./bin/ycsb run rocksdb -s \
# -P $WORKLOAD_FILE \
# -p rocksdb.dir=$ROCKSDB_DIR \
# -p rocksdb.optionsfile=$CONFIGURATION_FILE \
# -threads 16 \
# -p hdrhistogram.percentiles=50,90,95,99,99.9 \
# | tee $RUN_OUT_FILE;
