#!/bin/bash

#https://community.mellanox.com/s/article/howto-configure-nfs-over-rdma--roce-x

echo "/mnt/nvme0n1p4 *(rw,async,insecure,no_root_squash)" >> /etc/exports

modprobe svcrdma

service nfs-server start
#system ctl status nfs-server

echo rdma 20049 > /proc/fs/nfsd/portlist
