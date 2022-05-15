#!/bin/bash
set -x


CPUSTR='0,1,2,3'
SHARD='4'
MODE='rubble'
BASE_RECORD_COUNT='1000000'

# parse input
for i in "$@"
do
case $i in
    -c=*|--cpuset=*)
    CPUSTR="${i#*=}"
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

# mkdir to put data in
mkdir -p /tmp/rubble_data

# kill existing dstat program
kill $(ps aux | grep /usr/bin/dstat | awk '{print $2}')

# run dstat
(nohup dstat -cdt -C ${CPUSTR} --output /tmp/rubble_data/dstat_${SHARD}_${MODE}_${BASE_RECORD_COUNT}.csv) & 
sleep 2
echo "PID: ${!} | dstat running > /tmp/rubble_data/dstat_${SHARD}_${MODE}_${BASE_RECORD_COUNT}.csv"