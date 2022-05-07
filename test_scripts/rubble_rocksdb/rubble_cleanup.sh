#!/bin/bash
# TODO: don't set ex here or use the proc table for process termination

primary="./primary_node"
replica="./tail_node"
COPY="False"
BACKUP="False"
CODEDIR="/mnt/code"
SSTDIR="/mnt/db"
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
    -d=*|--codedir=*)
    BASEDIR="${i#*=}"
    shift # past argument=value
    ;;
    -s=*|--sstdir=*)
    BASEDIR="${i#*=}"
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

prefix="${SSTDIR}"
logDir="${CODEDIR}/my_rocksdb/rubble/log"
# sleep for 60 seconds to let compaction finish
# before saving a backup
# TODO: need to fix this part of script for the updated filepaths or remove it
if [[ "$BACKUP" == "True" ]]; then
    sleep 60
    for role in "primary" "tail"
    do
        if [ -f "${prefix}"/"${role}"/backup_db ]; then
            echo "backup db exists"
            rm -rf "${prefix}"/"${role}"/backup_db
        fi
        if [ -f "${prefix}"/"${role}"/backup_sst ]; then
            echo "backup sst exists"
            rm -rf "${prefix}"/"${role}"/backup_sst
        fi
        rsync -az "${prefix}"/"${role}"/db "${prefix}"/"${role}"/backup_db
        rsync -az "${prefix}"/"${role}"/sst_dir/*.sst "${prefix}"/"${role}"/backup_sst
    done
fi

# kill process
kill $(ps aux | grep $replica | awk '{print $2}')
kill $(ps aux | grep $primary | awk '{print $2}')
# cleanup db files
for role in "primary" "tail"
do
    for d in ${prefix}/*
    do
        if [ "$d" != /mnt/db/lost+found ]; then
            rm -rf "$d"/"${role}"/db
            rm "$d"/"${role}"/sst_dir/*.sst
            rm "${logDir}/$(basename $d)_${role}_log.txt"
        fi
    done

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
echo "--------rubble fresh start-------------" > "${CODEDIR}/my_rocksdb/rubble/nohup.out"

