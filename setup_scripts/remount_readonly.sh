#!bin/bash

set -x

LOCAL_SSTDIR="/mnt/sst"

# infer the node_number and the partition name
ip_address=$(hostname -I | awk '{print $2}')
node_number="${ip_address: -1}"
partition="/dev/mapper/node--${node_number}--vg-sst"

# kill all db server processes
kill $(ps aux | grep shard | awk '{print $2}')

# remount as read-only
sleep 2
umount ${LOCAL_SSTDIR}
mount -oro,noload ${partition} ${LOCAL_SSTDIR}


