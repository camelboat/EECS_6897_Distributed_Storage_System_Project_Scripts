#!/bin/bash

top -b -n 1 | grep java | tee data2

# Display  six  reports  at  two second intervals for device sda and all its partitions
# (sda1, etc.)
iostat -p sda 2 6


OUTPUT_PATH="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report"
EXPERIMENT_NAME="load_base"

JAVA_PID=$(top -b -n 1 | grep top | sed '3!d' | awk '{print $1}')
echo "RocksDB PID: ${JAVA_PID}"

while true; do
  # top -b -n 1 | grep java | tee -a ${OUPUT_PATH}/${EXPERIMENT_NAME}_top.csv;
  ps -p $JAVA_PID -o %cpu,%mem,cmd | tee -a {OUPUT_PATH}/${EXPERIMENT_NAME}_top.csv
  iostat | sed '7!d' | tee -a ${OUTPUT_PATH}/${EXPERIMENT_NAME}_iostat.csv;
  sleep 5;
done
