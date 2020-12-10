WORKLOAD_NUM='16-50_95-5'
#RUN_OUT_SUFFIX='ori_mlsm_2g'
#RUN_OUT_SUFFIX='mod_mlsm'
RUN_OUT_SUFFIX=''
WORKLOAD_FILE="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/workload_${WORKLOAD_NUM}"
ROCKSDB_DIR="/mnt/sdb/archive_dbs/${WORKLOAD_NUM}"
ROCKSDB_CONFIG_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_auto_compaction_16.ini'
#ROCKSDB_CONFIG_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_no_auto_compaction.ini'
RUN_OUT_FILE="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report/run_base_${WORKLOAD_NUM}_${RUN_OUT_SUFFIX}_7.csv"
SST_WORK_DIR="/mnt/sdb/archive_dbs/sst_dir/sst_last_run"
SST_WORK_DIR_CPY="/mnt/sdb/archive_dbs/sst_dir/sst_${WORKLOAD_NUM}_cpy"

# COMPACTION_META_PATH="/mnt/sdb/archive_dbs/compaction_meta"
# rm ${COMPACTION_META_PATH}/*

# REMOTE_SST_WORK_DIR="/mnt/nvme0n1p4/archive_dbs/sst_dir/sst_last_run"
# rm ${REMOTE_SST_WORK_DIR}/*
# nvme flush /dev/nvme0n1p4 -n 10

# Make sure you copy both ROCKSDB_DIR and SST files dir before you run this script

function create_or_remove {
    if [ -d $1 ]; then
        rm -rf $1
    fi
    mkdir -p $1
}

echo "remove sst work dir and copy sst work dir copy to sst work dir"
create_or_remove $SST_WORK_DIR

cp -rf $SST_WORK_DIR_CPY $SST_WORK_DIR
echo "Copy sst_dir finished";

echo "remove rocksdb working dir and copy rocksdb workding dir copy to rocksdb working dir"
create_or_remove $ROCKSDB_DIR

cp -rf "${ROCKSDB_DIR}_cpy" $ROCKSDB_DIR
echo "Copy rocksdb_dir finished";


# echo "create or remove compaction meta folder"
# create_or_remove $COMPACTION_META_PATH

# echo "create or remove manifest meta folder"
# create_or_remove $MANIFEST_META_PATH

cd /mnt/sdb/YCSB/

sudo -S sync; echo 1 | sudo tee /proc/sys/vm/drop_caches

# cgexec -g memory:mlsm cpu:clsm \
cgexec -g memory:mlsm \
./bin/ycsb run rocksdb -s \
-P $WORKLOAD_FILE \
-p rocksdb.dir=$ROCKSDB_DIR \
-p rocksdb.optionsfile=$ROCKSDB_CONFIG_FILE \
-threads 16 \
-p hdrhistogram.percentiles=5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,99,99.9 \
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

