#!/bin/bash

# sudo apt install inotify-tools

META_PATH=/mnt/sdb/archive_dbs/compaction_meta

inotifywait -m $META_PATH -e create -e moved_to |
  while read path action file; do
    echo "${path} ${action} ${file}"
  done
