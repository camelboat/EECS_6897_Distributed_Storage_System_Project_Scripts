#!bin/bash

set -ex

RUBBLE_PATH='/mnt/code/my_rocksdb/rubble'
DB_PATH='/mnt/db'
RUBBLE_MODE='vanilla' #vanilla, primary, secondary, tail
NEXT_PORT=''
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
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done

mkdir -p "${DB_PATH}/${RUBBLE_MODE}/db"
cd "$RUBBLE_PATH"

# set cgroup config
cgset -r memory.limit_in_bytes=${MEMORY_LIMIT} rubble-mem
cgset -r cpuset.cpus=${CPUSET_CPUS} rubble-cpu
cgset -r cpuset.mems=${CPUSET_MEMS} rubble-cpu


# bring up rocksdb server
if [ ${RUBBLE_MODE} == 'vanilla' ]; then
    (nohup cgexec -g cpuset:rubble-cpu -g memory:rubble-mem ./rocksdb_server ${NEXT_PORT}) &
fi

if [ ${RUBBLE_MODE} == 'primary' ]; then
    (nohup cgexec -g cpuset:rubble-cpu -g memory:rubble-mem ./primary_node ${NEXT_PORT} > log/primary_log.txt 2>&1) &
fi

if [ ${RUBBLE_MODE} == 'secondary' ]; then
    (nohup cgexec -g cpuset:rubble-cpu -g memory:rubble-mem ./secondary_node ${NEXT_PORT} > log/secondary_log.txt 2>&1 ) &
fi

if [ ${RUBBLE_MODE} == 'tail' ]; then
    (nohup cgexec -g cpuset:rubble-cpu -g memory:rubble-mem ./tail_node ${NEXT_PORT} > log/tail_log.txt 2>&1) &
fi

RUBBLE_PID=$!
echo ${RUBBLE_PID}

mkdir -p /tmp/rubble_proc/
echo "RUBBLE ${RUBBLE_PID}" >> /tmp/rubble_proc/proc_table
