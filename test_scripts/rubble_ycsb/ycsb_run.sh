#!bin/bash

set -ex

YCSB_BRANCH='singleOp'
RUBBLE_PATH='/mnt/sdb'
YCSB_MODE='load' #load, run
THREAD_NUM=16
REPLICATOR_ADDR="128.110.153.185:50050"
REPLICATOR_BATCH_SIZE=10
WORKLOAD=1

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

cd ${RUBBLE_PATH}/YCSB;
git checkout $YCSB_BRANCH

if [ ${YCSB_MODE} == 'load' ]; then
    ./load.sh \
    --threads=${THREAD_NUM} \
    --replicator_addr=${REPLICATOR_ADDR} \
    --replicator_batch_size=${REPLICATOR_BATCH_SIZE} \
    --workload=${WORKLOAD} \
    > load_${WORKLOAD}.txt 2>&1 
    
fi

if [ ${YCSB_MODE} == 'run' ]; then
    ./run.sh \
    --threads=${THREAD_NUM} \
    --replicator_addr=${REPLICATOR_ADDR} \
    --replicator_batch_size=${REPLICATOR_BATCH_SIZE} \
    --workload=${WORKLOAD} \
    > run_${WORKLOAD}.txt 2>&1
fi
