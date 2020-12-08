#!/bin/bash

top -b -n 1 | grep java | tee data2

# Display  six  reports  at  two second intervals for device sda and all its partitions
# (sda1, etc.)
iostat -p sda 2 6


OUTPUT_PATH="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report"
EXPERIMENT_NAME="load_base"

while true; do
  top -b -n 1 | grep java | tee -a ${OUPUT_PATH}/${EXPERIMENT_NAME}_top.csv;
  iostat | tee -a ${OUTPUT_PATH}/${EXPERIMENT_NAME}_iostat.csv;
  sleep 5;
done
