#!/bin/bash

#https://community.mellanox.com/s/article/howto-configure-nfs-over-rdma--roce-x

TARGET_IP=10.1.1.2
TARGET_DIR=/mnt/nvme0n1p4
LOCAL_DIR=/mnt/nvme1n1p4

modprobe xprtrdma

mount -o rdma,port=20049 $TARGET_IP:$TARGET_DIR $LOCAL_DIR
