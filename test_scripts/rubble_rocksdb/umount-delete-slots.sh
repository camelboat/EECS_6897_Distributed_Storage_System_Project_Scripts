#!bin/bash

set -x

DB_PATH='/mnt/db'
SST_PATH='/mnt/sst'
REMOTE_SST_PATH='/mnt/remote-sst'

# kill all the db servers running before umounting /mnt/sst
kill $(ps aux | grep _node | awk '{print $2}')

# get node number
ip_address=$(hostname -I | awk '{print $2}')
node_number="${ip_address: -1}"

# umount and remount directories
umount ${REMOTE_SST_PATH}
umount ${SST_PATH}
mount /dev/mapper/node--${node_number}--vg-sst /mnt/sst
rm -rf ${SST_PATH}/shard-*/
rm -rf ${DB_PATH}/shard-*/



