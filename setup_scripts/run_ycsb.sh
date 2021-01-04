WORKLOAD_NUM='16-50_95-5'
#RUN_OUT_SUFFIX='ori_mlsm_2g'
#RUN_OUT_SUFFIX='mod_mlsm'
RUN_OUT_SUFFIX='primary'
#---------------------------------------------------------------------------------------
WORKLOAD_FILE="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/workload_${WORKLOAD_NUM}"
ROCKSDB_DIR="/mnt/sdb/archive_dbs/${WORKLOAD_NUM}"
ROCKSDB_CONFIG_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_auto_compaction_16.ini'
#---------------------------------------------------------------------------------------
#ROCKSDB_CONFIG_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_no_auto_compaction.ini'
RUN_OUT_FILE="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report/run_${WORKLOAD_NUM}_${RUN_OUT_SUFFIX}_16.csv"
#---------------------------------------------------------------------------------------
SST_WORK_DIR="/mnt/sdb/archive_dbs/sst_dir/sst_last_run"
SST_WORK_DIR_CPY="/mnt/sdb/archive_dbs/sst_dir/sst_${WORKLOAD_NUM}_cpy"
#---------------------------------------------------------------------------------------
IOSTAT_FILE_NAME="iostat-17"
PS_FILE_NAME="ps-18"
TOP_FILE_NAME="top-25"
STATS_OUTPUT_DIR="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report"
#---------------------------------------------------------------------------------------

# COMPACTION_META_PATH="/mnt/sdb/archive_dbs/compaction_meta"
# rm ${COMPACTION_META_PATH}/*

# REMOTE_SST_WORK_DIR="/mnt/nvme0n1p4/archive_dbs/sst_dir/sst_last_run"
# rm ${REMOTE_SST_WORK_DIR}/*
# nvme flush /dev/nvme0n1p4 -n 10

# Make sure you copy both ROCKSDB_DIR and SST files dir before you run this script

function create_or_move {
    if [ -d $1 ]; then
        rm -rf $1
    fi
    mkdir -p $1
}

function remove_if_exist {
    if [ -d $1 ]; then
        rm -rf $1
    fi
}

function remove_or_touch {
    if [ -f $1 ]; then
        rm $1
    fi
    touch $1
}


echo "remove sst work dir and copy sst work dir copy to sst work dir"
remove_if_exist $SST_WORK_DIR

cp -rf $SST_WORK_DIR_CPY $SST_WORK_DIR
echo "Copy sst_dir finished";

echo "remove rocksdb working dir and copy rocksdb workding dir copy to rocksdb working dir"
remove_if_exist $ROCKSDB_DIR

cp -rf "${ROCKSDB_DIR}_cpy" $ROCKSDB_DIR
echo "Copy rocksdb_dir finished";

TOP_FILE_PATH=${STATS_OUTPUT_DIR}/${TOP_FILE_NAME}.csv
echo "remove or touch top output file"
remove_or_touch $TOP_FILE_PATH


# echo "create or remove compaction meta folder"
# create_or_remove $COMPACTION_META_PATH

# echo "create or remove manifest meta folder"
# create_or_remove $MANIFEST_META_PATH

# TRIM SSD to recover SSD performance
fstrim -v /

# Writes data buffered in memory out to disk, then clear memory cache(page cache).
sudo -S sync; echo 1 | sudo tee /proc/sys/vm/drop_caches

cd /mnt/sdb/YCSB/
#---------------------------------------------------------------------------------------
# cgexec -g memory:mlsm cpu:clsm \
{ cgexec -g memory:mlsm \
./bin/ycsb run rocksdb -s \
-P $WORKLOAD_FILE \
-p rocksdb.dir=$ROCKSDB_DIR \
-p rocksdb.optionsfile=$ROCKSDB_CONFIG_FILE \
-threads 16 \
-p hdrhistogram.percentiles=5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,99,99.9 \
| tee $RUN_OUT_FILE; } &
{ cd /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/setup_scripts/ && \
./collect_stats.sh --ps-file-name=$PS_FILE_NAME --iostat-file-name=$IOSTAT_FILE_NAME --output-path=$STATS_OUTPUT_DIR; } &
{ cd /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/setup_scripts/NVME_over_Fabrics && ./sync_ssts.sh; } &
{ top -b -d 0.2 | grep "Cpu(s)" --line-buffered >> $TOP_FILE_PATH; } &
wait -n
#---------------------------------------------------------------------------------------

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

# Kill collect_stats and sync_ssts
kill 0