#!bin/bash

set -x

LOCAL_SSTDIR="/mnt/sst"

# infer the node_number and the partition name
ip_address=$(hostname -I | awk '{print $2}')
node_number="${ip_address: -1}"
partition="/dev/mapper/node--${node_number}--vg-sst"

# remount as read-only
sudo umount ${LOCAL_SSTDIR}
sudo mount -oro,noload ${partition} ${LOCAL_SSTDIR}


