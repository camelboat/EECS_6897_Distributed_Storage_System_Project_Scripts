#!/bin/bash

OUTPUT_PATH="/mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Data/report"
EXPERIMENT_NAME="load_base"

while true; do
  iostat | tee -a ${OUTPUT_PATH}/${EXPERIMENT_NAME}_iostat.csv;
  tmp=$(top -b -n -1 | grep java)
  if [ -z "$tmp" ]; then
    break
  else
    tmp >> ${OUTPUT_PATH}/${EXPERIMENT_NAME}_top.csv
  fi
  # top -b -n 1 | grep java | tee -a ${OUTPUT_PATH}/${EXPERIMENT_NAME}_top.csv;
  sleep 5;
done
