#!/bin/bash

# sudo apt install inotify-tools

COMPACTION_META_PATH=/mnt/sdb/archive_dbs/compaction_meta/
SST_PATH=/mnt/sdb/archive_dbs/sst_dir/sst_last_run/
NVME_COMPACTION_META_PATH=/mnt/nvme0n1p4/

function nvme_flush {
  nvme flush /dev/nvme0n1p4 -n 10
}

# Arg1: File Path
# Arg2: File Size
function nvme_write {
  # nvme write /dev/nvme0n1p4 -d $1 --data-size=$2
  cp $1 "/mnt/nvme0n1p4/archive_dbs/sst_dir/sst_last_run/${1}"
}

# Arg1: File Path
function nvme_delete {
  rm "/mnt/nvme0n1p4/archive_dbs/sst_dir/sst_last_run/${1}"
}

inotifywait -m $COMPACTION_META_PATH -e create -e moved_to |
  while read path action file; do
    echo "${path} ${action} ${file}"
    file_path="${path}${file}"
    line_num=0
    while IFS= read -r line; do
      # echo "$line"
      if [ $line_num == 0 ]; then
        for word in $line; do
          if [ $word_num -ne 0 ]; then
            echo "delete $word";
            nvme_delete $file_path;
          fi
          word_num=$(($word_num+1))
        done
      elif [ $line_num == 1 ]; then
        echo "Second line, need to delete";
        for word in $line; do
          if [ $word_num -ne 0 ]; then
            echo "delete $word";
            nvme_delete $file_path
          fi
          word_num=$(($word_num+1))
        done
      elif [ $line_num == 2 ]; then
        echo "Third line, need to write and flush";
        for word in $line; do
          if [ $word_num -ne 0 ]; then
            echo "write $word";
            data_size=$(wc -c < $file_path)
            nvme_write $file_path $data_size
          fi
          word_num=$(($word_num+1))
        done
      fi
      word_num=0

      line_num=$(($line_num+1))
    done < "$file_path"
    nvme_flush
  done
