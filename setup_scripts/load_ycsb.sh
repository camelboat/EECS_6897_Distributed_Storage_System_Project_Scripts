WORKLOAD_NUM='16-50_95-5'
#WORKLOAD_NUM='1-10_95-5'
#WORKLOAD_NUM='100-100_95-5'
#WORKLOAD_NUM='16-50_100-0'
LOAD_OUT_SUFFIX='origin'
#---------------------------------------------------------------------------------------
WORKLOAD_FILE="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/ycsb_workloads/workload_${WORKLOAD_NUM}"
ROCKSDB_DIR="/mnt/sdb/archive_dbs/${WORKLOAD_NUM}"
#---------------------------------------------------------------------------------------
COMPACTION_META_PATH="/mnt/sdb/archive_dbs/compaction_meta"
MANIFEST_META_PATH="/mnt/sdb/archive_dbs/manifest_meta"
#---------------------------------------------------------------------------------------
# LOAD_OUT_FILE="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/${WORKLOAD_NUM}/load_${WORKLOAD_NUM}.csv"
LOAD_OUT_FILE="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report/load_${WORKLOAD_NUM}_${LOAD_OUT_SUFFIX}_10.csv"
ROCKSDB_CONFIG_FILE='/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/rocksdb_config/rocksdb_auto_compaction_16.ini'
#---------------------------------------------------------------------------------------
SST_WORK_DIR="/mnt/sdb/archive_dbs/sst_dir/sst_last_run"
SST_WORK_DIR_CPY="/mnt/sdb/archive_dbs/sst_dir/sst_${WORKLOAD_NUM}_cpy"
#---------------------------------------------------------------------------------------
IOSTAT_FILE_NAME="iostat-11"
PS_FILE_NAME="ps-12"
# SYNC_FILE_NAME="sync-22"
# MPSTAT_FILE_NAME="mpstat-22"
TOP_FILE_NAME="top-22"
STATS_OUTPUT_DIR="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report"
#---------------------------------------------------------------------------------------



REMOTE_SST_WORK_DIR="/mnt/sdb/archive_dbs/sst_dir"
rm ${REMOTE_SST_WORK_DIR}/*


# Writes data buffered in memory out to disk, then clear memory cache(page cache).
sudo -S sync; echo 1 | sudo tee /proc/sys/vm/drop_caches

#---------------------------------------------------------------------------------------
cd /mnt/sdb/YCSB/
{ cgexec -g memory:mlsm \
./bin/ycsb load rocksdb -s \
-P $WORKLOAD_FILE \
-p rocksdb.dir=$ROCKSDB_DIR \
-p rocksdb.optionsfile=$ROCKSDB_CONFIG_FILE \
-threads 12 \
-p hdrhistogram.percentiles=5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,99,99.9 \
| tee $LOAD_OUT_FILE; } &
{ cd /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/setup_scripts/ && \
./collect_stats.sh \
--ps-file-name=$PS_FILE_NAME \
--iostat-file-name=$IOSTAT_FILE_NAME \
--output-path=$STATS_OUTPUT_DIR \
--mpstat-file-name=$MPSTAT_FILE_NAME; } &
{ top -b -d 0.2 | grep "Cpu(s)" --line-buffered >> $TOP_FILE_PATH; } &
wait -n
#---------------------------------------------------------------------------------------

echo "copy sst work dir"
if [ -d $SST_WORK_DIR_CPY ]
then
    rm -rf $SST_WORK_DIR_CPY
fi
cp -rf $SST_WORK_DIR $SST_WORK_DIR_CPY
echo "finished copy to ${SST_WORK_DIR_CPY}"

echo "copy rocksdb working dir"
if [ -d "${ROCKSDB_DIR}_cpy" ]
then
    rm -rf "${ROCKSDB_DIR}_cpy"
fi
cp -rf $ROCKSDB_DIR "${ROCKSDB_DIR}_cpy"
echo "finished copy to ${ROCKSDB_DIR}_cpy"

# Kill collect_stats and sync_ssts
kill 0
