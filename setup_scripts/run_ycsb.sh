WORKLOAD_NUM='16-50_95-5'
#RUN_OUT_SUFFIX='ori_mlsm_2g'
#RUN_OUT_SUFFIX='mod_mlsm'
RUN_OUT_SUFFIX='mod_print_statistics'
WORKLOAD_FILE="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/workload_${WORKLOAD_NUM}"
ROCKSDB_DIR="/mnt/sdb/archive_dbs/${WORKLOAD_NUM}"
ROCKSDB_CONFIG_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_auto_compaction_16.ini'
#ROCKSDB_CONFIG_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_no_auto_compaction.ini'
RUN_OUT_FILE="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/${WORKLOAD_NUM}/run_${WORKLOAD_NUM}_${RUN_OUT_SUFFIX}.csv"
SST_WORK_DIR="/mnt/sdb/archive_dbs/sst_dir/sst_last_run"
SST_WORK_DIR_CPY="/mnt/sdb/archive_dbs/sst_dir/sst_${WORKLOAD_NUM}_cpy"

# Make sure you copy both ROCKSDB_DIR and SST files dir before you run this script

if [ -d $ROCKSDB_DIR ]
then
    echo "Remove rocksdb_dir";
    rm -rf $ROCKSDB_DIR
fi
cp -rf "${ROCKSDB_DIR}_cpy" $ROCKSDB_DIR
echo "Copy rocksdb_dir";

if [ -d $SST_WORK_DIR ]
then
    echo "Remove sst_dir";
    rm -rf $SST_WORK_DIR
fi
cp -rf $SST_WORK_DIR_CPY $SST_WORK_DIR
echo "Copy sst_dir";

cd /mnt/sdb/YCSB/

sudo -S sync; echo 1 | sudo tee /proc/sys/vm/drop_caches

cgexec -g memory:mlsm \
./bin/ycsb run rocksdb -s \
-P $WORKLOAD_FILE \
-p rocksdb.dir=$ROCKSDB_DIR \
-p rocksdb.optionsfile=$ROCKSDB_CONFIG_FILE \
-threads 16 \
-p hdrhistogram.percentiles=50,90,95,99,99.9 \
| tee $RUN_OUT_FILE;

echo "copy rocksdb working dir"
SST_WORK_DIR_RES_CPY="/mnt/sdb/archive_dbs/sst_dir/sst_${WORKLOAD_NUM}_${RUN_OUT_SUFFIX}"
if [ -d $SST_WORK_DIR_RES_CPY ]
then
    rm -rf $SST_WORK_DIR_RES_CPY
fi
cp -rf $SST_WORK_DIR $SST_WORK_DIR_RES_CPY
echo "finished copy to ${SST_WORK_DIR_RES_CPY}"

echo "copy rocksdb working dir"
if [ -d "${ROCKSDB_DIR}_${RUN_OUT_SUFFIX}" ]
then
    rm -rf "${ROCKSDB_DIR}_${RUN_OUT_SUFFIX}"
fi
cp -rf $ROCKSDB_DIR "${ROCKSDB_DIR}_${RUN_OUT_SUFFIX}"
echo "finished copy to ${ROCKSDB_DIR}_${RUN_OUT_SUFFIX}"

