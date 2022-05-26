#!/bin/bash
# TODO: don't set ex here or use the proc table for process termination

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
# if [[ "$BACKUP" == "True" ]]; then
#     sleep 60
#     for role in "primary" "tail"
#     do
#         if [ -f "${prefix}"/"${role}"/backup_db ]; then
#             echo "backup db exists"
#             rm -rf "${prefix}"/"${role}"/backup_db
#         fi
#         if [ -f "${prefix}"/"${role}"/backup_sst ]; then
#             echo "backup sst exists"
#             rm -rf "${prefix}"/"${role}"/backup_sst
#         fi
#         rsync -az "${prefix}"/"${role}"/db "${prefix}"/"${role}"/backup_db
#         rsync -az "${prefix}"/"${role}"/sst_dir/*.sst "${prefix}"/"${role}"/backup_sst
#     done
# fi

# kill process
while [ $(ps aux | grep shard | wc -l) -gt 1 ]
do
	kill -9 $(ps aux | grep shard | awk '{print $2}')
done

# cleanup db files
for d in ${SSTDIR}/*
do
  if [ "$d" != "${SSTDIR}/lost+found" ]; then
    rm -rf "$d"/*
  fi
done

# delete all log files
rm "${logDir}"/*


# # copy over new files TO BE TESTED
# if [[ "$COPY" == "True" ]]; then
#   echo "COPY FILES OVER"
#   for role in "primary" "tail"
#   do
#     rsync -az "${prefix}"/"${role}"/backup_db/ "${prefix}"/"${role}"/db/ 
#     rsync -az "${prefix}"/"${role}"/backup_sst/*.sst "${prefix}"/"${role}"/sst_dir/
#   done
# fi


# cleanup nohup.out log
echo "--------rubble fresh start-------------" > "${CODEDIR}/my_rocksdb/rubble/nohup.out"

