#!/bin/bash

# Usage: ./collect_stats --ps-file-name=ps_2 --iostat-file-name=iostat-3 --output-path=/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report

for i in "$@"
do
case $i in
    -p=*|--ps-file-name=*)
    PS_FILE_NAME="${i#*=}"
    shift # past argument=value
    ;;
    -i=*|--iostat-file-name=*)
    IOSTAT_FILE_NAME="${i#*=}"
    shift # past argument=value
    ;;
    -o=*|--output-path=*)
    OUTPUT_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -m=*|--mpstat-file-name=*)
    MPSTAT_FILE_NAME="${i#*=}"
    shift
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

# OUTPUT_PATH="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report"
EXPERIMENT_NAME="load_base"

JAVA_PID=$(top -b -n 1 | grep java | awk '{print $1}')
echo "RocksDB PID: ${JAVA_PID}"

function remove_or_create_file {
  if [ -f $1 ]; then
    echo "remove ${1}"
    rm $1
  fi
  echo "touch ${1}"
  touch $1
}

IOSTAT_FILE_PATH=${OUTPUT_PATH}/${IOSTAT_FILE_NAME}.csv
PS_FILE_PATH=${OUTPUT_PATH}/${PS_FILE_NAME}.csv
# SYNC_FILE_PATH=${OUTPUT_PATH}/${SYNC_FILE_NAME}.csv
MPSTAT_FILE_PATH=${OUTPUT_PATH}/${MPSTAT_FILE_NAME}.csv

remove_or_create_file $IOSTAT_FILE_PATH
remove_or_create_file $PS_FILE_PATH
remove_or_create_file $MPSTAT_FILE_PATH

while true; do
  iostat -p /dev/nvme0n1 | sed '7!d' | tee -a $IOSTAT_FILE_PATH;
  JAVA_PID=$(top -b -n 1 | grep java | awk '{print $1}')
  # tmp=$(ps -p $JAVA_PID | sed '2!d')
  # JAVA_PID=$(top -b -n 1 | grep java | awk '{print $1}')
  # if [ -z "$tmp" ]; then
  #   break
  # else
  #   # echo $tmp >> ${OUTPUT_PATH}/${EXPERIMENT_NAME}_top.csv
  #   ps -p $JAVA_PID -o %cpu,%mem | sed '2!d' | tee -a $PS_FILE_PATH
  # fi
  ps -p $JAVA_PID -o %cpu,%mem | sed '2!d' | tee -a $PS_FILE_PATH
  mpstat 3 1 | sed '4!d' | tee -a $MPSTAT_FILE_PATH
  # mpstat -P ALL 1 1 | tee -a $MPSTAT_FILE_PATH
  # ps -p $SYNC_PID -o %cpu,%mem | sed '2!d' | tee -a $SYNC_FILE_PATH
  # top -b -n 1 | grep java | tee -a ${OUTPUT_PATH}/${EXPERIMENT_NAME}_top.csv;
  sleep 2;
done
