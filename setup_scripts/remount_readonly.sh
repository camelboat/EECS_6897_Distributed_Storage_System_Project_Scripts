#!bin/bash

set -x

LOCAL_SSTDIR="/mnt/sst"

# infer the node_number and the partition name
ip_address=$(hostname -I | awk '{print $2}')
node_number="${ip_address: -1}"
partition="/dev/mapper/node--${node_number}--vg-sst"

# kill all processes using /mnt/sst before umounting
while [ $(lsof | grep "${LOCAL_SSTDIR}" | wc -l) -gt 0 ]
do
	kill -9 $(lsof | grep "${LOCAL_SSTDIR}" | awk '{print $2}')
done

# remount as read-only
sleep 2
umount ${LOCAL_SSTDIR}
mount -oro,noload ${partition} ${LOCAL_SSTDIR}


