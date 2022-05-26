#!bin/bash

set -x

DB_PATH='/mnt/db'
SST_PATH='/mnt/sst'
REMOTE_SST_PATH='/mnt/remote-sst'

# kill all processes using /mnt/sst before umounting
while [ $(lsof | grep "${SST_PATH}" | wc -l) -gt 0 ]
do
	kill -9 $(lsof | grep "${SST_PATH}" | awk '{print $2}')
done

# get node number
ip_address=$(hostname -I | awk '{print $2}')
node_number="${ip_address: -1}"

# umount and remount directories
sleep 2
umount ${REMOTE_SST_PATH}
umount ${SST_PATH}
mount /dev/mapper/node--${node_number}--vg-sst /mnt/sst
rm -rf ${SST_PATH}/shard-*/
rm -rf ${DB_PATH}/shard-*/




