#!/bin/bash
set -x

RUBBLE_PATH='/mnt/code'
SHARD='2'
MODE='rubble'
NUM_CPU='4'
BASE_RECORD_COUNT='1000000'

# parse input
for i in "$@"
do
case $i in
    -p=*|--rubble-path=*)
    RUBBLE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -s=*|--shard-number=*)
    SHARD="${i#*=}"
    shift # past argument=value
    ;;
    -m=*|--rubble-mode=*)
    MODE="${i#*=}"
    shift # past argument=value
    ;;
    -ct=*|--base-record-count=*)
    BASE_RECORD_COUNT="${i#*=}"
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

# kill existing dstat program
kill $(ps aux | grep /usr/bin/dstat | awk '{print $2}')

# generate the plots immediately after
PLOT_SCRIPT_PATH="${RUBBLE_PATH}/my_rocksdb/rubble/plot-dstat.py"
sed -ire "s/cpu_num = [[:digit:]]\+/cpu_num = ${NUM_CPU}/" ${PLOT_SCRIPT_PATH}
source /tmp/rubble_venv/bin/activate
python ${PLOT_SCRIPT_PATH} /tmp/rubble_data/dstat_${SHARD}_${MODE}_${BASE_RECORD_COUNT}.csv 10


