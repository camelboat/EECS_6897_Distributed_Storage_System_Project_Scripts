#!/bin/bash

BLOCK_DEV = /dev/nvme0n1p3
MOUNT_PT = /mnt/nvme0n1p3

cd /mnt
umount $MOUNT_PT

for i in {1..100}
do
   mount $BLOCK_DEV $MOUNT_PT
   umount $MOUNT_PT 
done
