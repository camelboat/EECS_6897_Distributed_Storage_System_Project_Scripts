#!bin/bash

# set -ex
SHARD_NUM=1
RUBBLE_PATH='/mnt/code'
YCSB_MODE='load' #load, run
THREAD_NUM=16
REPLICATOR_ADDR="localhost:50050"
REPLICATOR_BATCH_SIZE=10
WORKLOAD='a'
STATUS_INTERVAL=1000

for i in "$@"
do
case $i in
    -s=*|--shard-number=*)
    SHARD_NUM="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--rubble-path=*)
    RUBBLE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -m=*|--ycsb-mode=*)
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
    -tr=*|--target-rate=*)
    TARGET_RATE="${i#*=}"
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
kill $(ps aux | grep site.ycsb.Client | awk '{print $2}')

# start a new YCSB client
cd ${RUBBLE_PATH}/YCSB;

if [ ${YCSB_MODE} == 'load' ]; then
    bash load.sh ${WORKLOAD} ${REPLICATOR_ADDR} ${SHARD_NUM} ${STATUS_INTERVAL} \
    ${TARGET_RATE} ${THREAD_NUM} > load_${WORKLOAD}.txt 2>&1 
    
fi

if [ ${YCSB_MODE} == 'run' ]; then
    bash run.sh ${WORKLOAD} ${REPLICATOR_ADDR} ${SHARD_NUM} ${STATUS_INTERVAL} \
    ${TARGET_RATE} ${THREAD_NUM} > run_${WORKLOAD}.txt 2>&1
fi

YCSB_PID=$!
echo ${YCSB_PID}