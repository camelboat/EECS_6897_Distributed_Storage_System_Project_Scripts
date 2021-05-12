#!bin/bash

set -ex

RUBBLE_BRANCH='rubble'
RUBBLE_PATH='/mnt/sdb'
RUBBLE_MODE='vanilla' #vanilla, primary, secondary, tail
NEXT_PORT=''

for i in "$@"
do
case $i in
    -b=*|--rubble-branch=*)
    RUBBLE_BRANCH="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--rubble-path=*)
    RUBBLE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -m=*|--rubble-mode=*)
    RUBBLE_MODE="${i#*=}"
    shift # past argument=value
    ;;
    -n=*|--NEXT_PORT=*)
    NEXT_PORT="${i#*=}"
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

cd ${RUBBLE_PATH}/my_rocksdb/rubble

if [ ${RUBBLE_MODE} == 'vanilla' ]; then
    (nohup ./rocksdb_server ${NEXT_PORT}) &
fi

if [ ${RUBBLE_MODE} == 'primary' ]; then
    (nohup ./primary_node ${NEXT_PORT}) &
fi

if [ ${RUBBLE_MODE} == 'secondary' ]; then
    (nohup ./secondary_node ${NEXT_PORT}) &
fi

if [ ${RUBBLE_MODE} == 'tail' ]; then
    (nohup ./tail_node ${NEXT_PORT}) &
fi

RUBBLE_PID=$!
echo ${RUBBLE_PID}

mkdir -p /tmp/rubble_proc/
echo "RUBBLE ${RUBBLE_PID}" >> /tmp/rubble_proc/proc_table
