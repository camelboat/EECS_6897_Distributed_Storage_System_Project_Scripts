#!bin/bash

# set -ex

YCSB_BRANCH='recovery'
RUBBLE_PATH='/mnt/sdb'
YCSB_MODE='load' #load, run
THREAD_NUM=16
REPLICATOR_ADDR="localhost:50050"
REPLICATOR_BATCH_SIZE=10
WORKLOAD=a

for i in "$@"
do
case $i in
    -b=*|--ycsb-branch=*)
    YCSB_BRANCH="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--rubble-path=*)
    RUBBLE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--ycsb-mode=*)
    YCSB_MODE="${i#*=}"
    shift # past argument=value
    ;;
    -t=*|--thread-num=*)
    THREAD_NUM="${i#*=}"
    shift # past argument=value
    ;;
    -r=*|--replicator-addr=*)
    REPLICATOR_ADDR="${i#*=}"
    shift # past argument=value
    ;;
    -s=*|--replicator-batch-size=*)
    REPLICATOR_BATCH_SIZE="${i#*=}"
    shift # past argument=value            
    ;;
    -w=*|--workload=*)
    WORKLOAD="${i#*=}"
    shift # past argument=value            
    ;;    
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done

# kill the old process
kill $(ps aux | grep site.ycsb.db.rocksdb.RocksDBClient | awk '{print $2}')

# start a new YCSB client
cd ${RUBBLE_PATH}/YCSB;
# git checkout $YCSB_BRANCH

if [ ${YCSB_MODE} == 'load' ]; then
    (nohup \
    bash load.sh ${WORKLOAD} ${REPLICATOR_ADDR} 1 1000 20000 2 \
    > load_${WORKLOAD}.txt 2>&1 ) &
    
fi

if [ ${YCSB_MODE} == 'run' ]; then
    ./run.sh \
    --threads=${THREAD_NUM} \
    --replicator_addr=${REPLICATOR_ADDR} \
    --replicator_batch_size=${REPLICATOR_BATCH_SIZE} \
    --workload=${WORKLOAD} \
    > run_${WORKLOAD}.txt 2>&1
fi

YCSB_PID=$!
echo ${YCSB_PID}