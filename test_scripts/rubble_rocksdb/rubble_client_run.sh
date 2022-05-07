#!bin/bash

set -x

RUBBLE_PATH='/mnt/code/my_rocksdb/rubble'
DB_PATH='/mnt/db'
SST_PATH='/mnt/sst'
RUBBLE_MODE='vanilla' #vanilla, primary, secondary, tail
THIS_PORT=''
NEXT_PORT=''
SHARD_NUM=''
MEMORY_LIMIT='2G'
CPUSET_CPUS='0-7'
CPUSET_MEMS='0'

for i in "$@"
do
case $i in
    -p=*|--rubble-path=*)
    RUBBLE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -d=*|--db-path=*)
    DB_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -m=*|--rubble-mode=*)
    RUBBLE_MODE="${i#*=}"
    shift # past argument=value
    ;;
    -t=*|--this-port=*)
    THIS_PORT="${i#*=}"
    shift # past argument=value
    ;;
    -n=*|--next-port=*)
    NEXT_PORT="${i#*=}"
    shift # past argument=value
    ;;
    -m=*|--memory-limit=*)
    MEMORY_LIMIT="${i#*=}"
    shift # past argument=value
    ;;
    -c=*|--cpuset-cpus=*)
    CPUSET_CPUS="${i#*=}"
    shift # past argument=value
    ;;
    -s=*|--cpuset-mems=*)
    CPUSET_MEMS="${i#*=}"
    shift # past argument=value
    ;;
    --shard-num=*)
    SHARD_NUM="${i#*=}"
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

mkdir -p "${DB_PATH}/${SHARD_NUM}/${RUBBLE_MODE}/db"
mkdir -p "${SST_PATH}/${SHARD_NUM}"
cd "$RUBBLE_PATH"

# set cgroup config
cgset -r memory.limit_in_bytes=${MEMORY_LIMIT} rubble-mem
cgset -r cpuset.cpus=${CPUSET_CPUS} rubble-cpu
cgset -r cpuset.mems=${CPUSET_MEMS} rubble-cpu

LOG_FILENAME="log/${SHARD_NUM}_${RUBBLE_MODE}_log.txt"

# bring up rocksdb server
if [ ${RUBBLE_MODE} == 'vanilla' ]; then
    (nohup cgexec -g cpuset:rubble-cpu -g memory:rubble-mem \ 
    ./rocksdb_server ${NEXT_PORT} > ${LOG_FILENAME} 2>&1) &
fi

if [ ${RUBBLE_MODE} == 'primary' ]; then
    (nohup cgexec -g cpuset:rubble-cpu -g memory:rubble-mem \
    ./primary_node ${THIS_PORT} ${NEXT_PORT} ${SHARD_NUM} > ${LOG_FILENAME} 2>&1) &
fi

# TODO: fix secondary mode when testing it
if [ ${RUBBLE_MODE} == 'secondary' ]; then
    (nohup cgexec -g cpuset:rubble-cpu -g memory:rubble-mem \
    ./secondary_node ${NEXT_PORT} > ${LOG_FILENAME} 2>&1 ) &
fi

if [ ${RUBBLE_MODE} == 'tail' ]; then
    (nohup cgexec -g cpuset:rubble-cpu -g memory:rubble-mem \
    ./tail_node ${THIS_PORT} ${NEXT_PORT} ${SHARD_NUM}> ${LOG_FILENAME} 2>&1) &
fi

RUBBLE_PID=$!
echo ${RUBBLE_PID}

mkdir -p /tmp/rubble_proc/
echo "RUBBLE ${RUBBLE_PID}" >> /tmp/rubble_proc/proc_table
# sleep here to make sure that the process is properly started before exiting
sleep 1