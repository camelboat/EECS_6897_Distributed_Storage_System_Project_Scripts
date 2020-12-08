#!/bin/bash

OUTPUT_PATH="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report"
EXPERIMENT_NAME="load_base"

while true; do
  top -b -n 1 | grep java | tee -a ${OUTPUT_PATH}/${EXPERIMENT_NAME}_top.csv;
  iostat | tee -a ${OUTPUT_PATH}/${EXPERIMENT_NAME}_iostat.csv;
  sleep 5;
done
