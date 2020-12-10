#!/bin/bash

OUTPUT_PATH="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report"
EXPERIMENT_NAME="load_base"

JAVA_PID=$(top -b -n 1 | grep java | awk '{print $1}')
echo "RocksDB PID: ${JAVA_PID}"

function remove_or_create_file {
  if [ -d $1 ]; then
    rm $1
  fi
  touch $1
}

IOSTAT_FILE_PATH=${OUTPUT_PATH}/${EXPERIMENT_NAME}_iostat_2.csv
PS_FILE_PATH=${OUTPUT_PATH}/${EXPERIMENT_NAME}_ps_3.csv
remove_or_create_file $IOSTAT_FILE_PATH
remove_or_create_file $PS_FILE_PATH

while true; do
  iostat -p /dev/nvme0n1 | sed '7!d' | tee -a $IOSTAT_FILE_PATH;
  # tmp=$(top -b -n 1 | grep java)
  # tmp=$(ps -p $JAVA_PID | sed '2!d')
  # JAVA_PID=$(top -b -n 1 | grep java | awk '{print $1}')
  # if [ -z "$tmp" ]; then
  #   break
  # else
  #   # echo $tmp >> ${OUTPUT_PATH}/${EXPERIMENT_NAME}_top.csv
  #   ps -p $JAVA_PID -o %cpu,%mem | sed '2!d' | tee -a $PS_FILE_PATH
  # fi
  ps -p $JAVA_PID -o %cpu,%mem | sed '2!d' | tee -a $PS_FILE_PATH
  # top -b -n 1 | grep java | tee -a ${OUTPUT_PATH}/${EXPERIMENT_NAME}_top.csv;
  sleep 5;
done
