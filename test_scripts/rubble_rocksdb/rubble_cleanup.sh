#!/bin/bash
# TODO: don't set ex here or use the proc table for process termination

primary="./primary_node"
replica="./tail_node"
COPY="False"
BACKUP="False"
# parse input
for i in "$@"
do
case $i in
    -c=*|--copy=*)
    COPY="${i#*=}"
    shift # past argument=value
    ;;
    -b=*|--backup=*)
    BACKUP="${i#*=}"
    shift # past argument=value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
        # unknown option
    ;;
esac
done

prefix='/mnt/sdb/archive_dbs'
# sleep for 60 seconds to let compaction finish
# before saving a backup
if [[ "$BACKUP" == "True" ]]; then
    sleep 60
    for role in "primary" "tail"
    do
        rsync -az "${prefix}"/"${role}"/db/ "${prefix}"/"${role}"/backup_db/
        rsync -az "${prefix}"/"${role}"/sst_dir/*.sst "${prefix}"/"${role}"/backup_sst/
    done
fi

# kill process
kill $(ps aux | grep $replica | awk '{print $2}')
kill $(ps aux | grep $primary | awk '{print $2}')
# cleanup db files
for role in "primary" "tail"
do
    rm -rf "${prefix}"/"${role}"/db
    rm "${prefix}"/"${role}"/sst_dir/*.sst
done

# copy over new files
if [[ "$COPY" == "True" ]]; then
    echo "COPY FILES OVER"
    for role in "primary" "tail"
    do
        rsync -az "${prefix}"/"${role}"/backup_db/ "${prefix}"/"${role}"/db/ 
        rsync -az "${prefix}"/"${role}"/backup_sst/*.sst "${prefix}"/"${role}"/sst_dir/
    done
fi
# cleanup nohup.out log
echo "--------rubble fresh start-------------" > /mnt/sdb/my_rocksdb/rubble/nohup.out

