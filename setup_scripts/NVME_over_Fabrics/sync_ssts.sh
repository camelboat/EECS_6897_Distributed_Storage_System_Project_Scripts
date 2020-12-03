#!/bin/bash

# sudo apt install inotify-tools

COMPACTION_META_PATH=/mnt/sdb/archive_dbs/compaction_meta/
SST_PATH=/mnt/sdb/archive_dbs/sst_dir/sst_last_run/

inotifywait -m $COMPACTION_META_PATH -e create -e moved_to |
  while read path action file; do
    echo "${path} ${action} ${file}"
    file_path="${path}${file}"
    line_num=0
    while IFS= read -r line; do
      # echo "$line"
      if [ $line_num == 0 ]; then echo "First line, need to delete"; fi
      if [ $line_num == 1 ]; then echo "Second line, need to delete"; fi
      if [ $line_num == 2 ]; then echo "Third line, need to write and flush"; fi
      word_num=0
      for word in $line; do
        if [ $word_num -ne 0 ]; then echo $word; fi
        word_num=$(($word_num+1))
      done
      line_num=$(($line_num+1))
    done < "$file_path"
  done
