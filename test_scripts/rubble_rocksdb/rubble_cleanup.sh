#!/bin/bash
# TODO: don't set ex here or use the proc table for process termination

primary="./primary_node"
replica="./tail_node"
COPY="False"
# parse input
for i in "$@"
do
case $i in
    -c=*|--copy=*)
    COPY="${i#*=}"
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
# kill process
kill $(ps aux | grep $replica | awk '{print $2}')
kill $(ps aux | grep $primary | awk '{print $2}')
# cleanup db files
rm -rf /tmp/rubble_primary
rm -rf /tmp/rubble_tail
rm -rf /tmp/rubble_secondary
rm -rf /tmp/rubble_vanilla
rm -rf /mnt/sdb/archive_dbs/*/sst_dir/*.sst
# copy over new files
if [[ "$COPY" == "True" ]]; then
    echo "COPY FILES OVER"
    cp -r /tmp/backup_primary /tmp/rubble_primary
    cp -r /tmp/backup_tail /tmp/rubble_tail
    cp /mnt/sdb/archive_dbs/backup_primary/*.sst /mnt/sdb/archive_dbs/primary/sst_dir/
    cp /mnt/sdb/archive_dbs/backup_tail/*.sst /mnt/sdb/archive_dbs/tail/sst_dir/
fi
# cleanup nohup.out log
echo "--------rubble fresh start-------------" > /mnt/sdb/my_rocksdb/rubble/nohup.out

