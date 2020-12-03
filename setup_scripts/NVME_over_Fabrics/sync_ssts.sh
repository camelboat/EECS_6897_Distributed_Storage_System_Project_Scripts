#!/bin/bash

# sudo apt install inotify-tools

COMPACTION_META_PATH=/mnt/sdb/archive_dbs/compaction_meta
SST_PATH=/mnt/sdb/archive_dbs/sst_dir/sst_last_run
NVME_SST_PATH=/mnt/nvme0n1p4/archive_dbs/sst_dir_sst_last_run


function nvme_flush {
  nvme flush /dev/nvme0n1p4 -n 10
}

# Arg1: File Name
function nvme_write {
  # data_size=$(wc -c < "${SST_PATH}${1}")
  # nvme write /dev/nvme0n1p4 -d $1 --data-size=$data_size
  cp "${SST_PATH}/${1}.sst" "${NVME_SST_PATH}/${1}.sst"
}

# Arg1: File Name
function nvme_delete {
  rm "${NVME_SST_PATH}${1}.sst"
}

inotifywait -m $COMPACTION_META_PATH -e create -e moved_to |
  while read path action file; do
    echo "${path} ${action} ${file}"
    file_path="${path}${file}"
    line_num=0
    while IFS= read -r line; do
      # echo "$line"
      if [ $line_num == 0 ]; then
        word_num=0
        for word in $line; do
          if [ $word_num -ne 0 ]; then
            # echo "delete $word";
            nvme_delete $word
          fi
          word_num=$(($word_num+1))
        done
      elif [ $line_num == 1 ]; then
        # echo "Second line, need to delete";
        word_num=0
        for word in $line; do
          if [ $word_num -ne 0 ]; then
            # echo "delete $word";
            nvme_delete $word
          fi
          word_num=$(($word_num+1))
        done
      elif [ $line_num == 2 ]; then
        word_num=0
        # echo "Third line, need to write and flush";
        for word in $line; do
          if [ $word_num -ne 0 ]; then
            # echo "write $word";
            nvme_write $word
          fi
          word_num=$(($word_num+1))
        done
      fi
      line_num=$(($line_num+1))
    done < "$file_path"
    nvme_flush
  done
