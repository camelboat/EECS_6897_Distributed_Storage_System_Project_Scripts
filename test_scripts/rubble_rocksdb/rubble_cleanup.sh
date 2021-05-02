#!/bin/bash
primary='./primary_node'
replica='./tail_node'
# kill process
kill $(ps aux | grep $replica | awk '{print $2}')
kill $(ps aux | grep $primary | awk '{print $2}')
# cleanup db files
rm -rf /tmp/rubble_*
rm -rf /mnt/sdb/archive_dbs/*/sst_dir/*
# cleanup nohup.out log
echo "--------rubble fresh start-------------" > /mnt/sdb/my_rocksdb/rubble/nohup.out

