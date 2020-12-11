#!/bin/bash

# sudo apt install inotify-tools

COMPACTION_META_PATH=/mnt/sdb/archive_dbs/compaction_meta
SST_PATH=/mnt/sdb/archive_dbs/sst_dir/sst_last_run
NVME_SST_PATH=/mnt/nvme0n1p4/archive_dbs/sst_dir/sst_last_run

function create_or_remove {
    if [ -d $1 ]; then
        rm -rf $1
    fi
    mkdir -p $1
}

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
  rm "${NVME_SST_PATH}/${1}.sst"
}

level0_delete=0
level1_delete=0
level2_delete=0
level3_delete=0
level4_delete=0

level0_write=0
level1_write=0
level2_write=0
level3_write=0
level4_write=0

cur_first=""
cur_level=""

create_or_remove $NVME_SST_PATH

inotifywait -m $COMPACTION_META_PATH -e create -e moved_to |
  while read path action file; do
    echo "${path} ${action} ${file}"
    file_path="${path}${file}"
    line_num=0
    while IFS= read -r line; do
      # echo "$line"
        word_num=0
        for word in $line; do
          if [ $word_num == 0 ]; then
            cur_first=$word
          elif [ $word_num == 1 ]; then
            cur_level=$word
          else
            if [  $cur_first == 'd' ]; then
              printf -v file_name "%06d" $word
              echo "delete $file_name";
              nvme_delete $file_name
            else
              printf -v file_name "%06d" $word
              echo "write $file_name";
              nvme_write $file_name
            fi
          fi
          word_num=$(($word_num+1))
        done
        echo "cur_first: ${cur_first}, cur_level: ${cur_level}"
        if [ $cur_first == 'd' ]; then
          case $cur_level in
            "0") level0_delete=$(($level0_delete+$word_num-1));;
            "1") level1_delete=$(($level1_delete+$word_num-1));;
            "2") level2_delete=$(($level2_delete+$word_num-1));;
            "3") level3_delete=$(($level3_delete+$word_num-1));;
            "4") level4_delete=$(($level4_delete+$word_num-1));;
          esac
        elif [ $cur_first == 'w' ]; then
          case $cur_level in
            "0") level0_write=$(($level0_write+$word_num-1));;
            "1") level1_write=$(($level1_write+$word_num-1));;
            "2") level2_write=$(($level2_write+$word_num-1));;
            "3") level3_write=$(($level3_write+$word_num-1));;
            "4") level4_write=$(($level4_write+$word_num-1));;
          esac
        fi
      line_num=$(($line_num+1))
    done < "$file_path"
    rm $file_path
    echo "level0_write: ${level0_write}"
    echo "level1_write: ${level1_write}"
    echo "level2_write: ${level2_write}"
    echo "level3_write: ${level3_write}"
    echo "level4_write: ${level4_write}"
    echo "level0_delete: ${level0_delete}"
    echo "level1_delete: ${level1_delete}"
    echo "level2_delete: ${level2_delete}"
    echo "level3_delete: ${level3_delete}"
    echo "level4_delete: ${level4_delete}"
    # nvme_flush
  done
