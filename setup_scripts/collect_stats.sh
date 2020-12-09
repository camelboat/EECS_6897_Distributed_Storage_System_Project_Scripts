#!/bin/bash

OUTPUT_PATH="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report"
EXPERIMENT_NAME="load_base"

JAVA_PID=$(top -b -n 1 | grep top | sed '3!d' | awk '{print $1}')
echo "RocksDB PID: ${JAVA_PID}"

while true; do
  iostat | tee -a | sed '7!d'  ${OUTPUT_PATH}/${EXPERIMENT_NAME}_iostat.csv;
  tmp=$(top -b -n 1 | grep java)
  if [ -z "$tmp" ]; then
    break
  else
    # echo $tmp >> ${OUTPUT_PATH}/${EXPERIMENT_NAME}_top.csv
    ps -p $JAVA_PID -o %cpu,%mem,cmd | tee -a {OUPUT_PATH}/${EXPERIMENT_NAME}_ps.csv
  fi
  # top -b -n 1 | grep java | tee -a ${OUTPUT_PATH}/${EXPERIMENT_NAME}_top.csv;
  sleep 5;
done
