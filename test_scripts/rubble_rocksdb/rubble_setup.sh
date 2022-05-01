#!/bin/bash
# script used to create sst directories and pre-allocate slots
# mkdir
for ROLE in "primary" "tail"
do
    mkdir -p /mnt/sdb/archive_dbs/${ROLE}/sst_dir
done
mkdir -p /mnt/remote/archive_dbs/sst_dir
# run only to pre-allocate slots
bash rubble_client_run.sh -m=tail
# bash rubble_cleanup.sh


