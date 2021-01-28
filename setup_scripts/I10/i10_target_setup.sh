#!/bin/bash

TARGET_IP=10.10.1.2

modprobe nvmet
modprobe i10-target

mkdir /sys/kernel/config/nvmet/subsystems/nvme_i10
cd /sys/kernel/config/nvmet/subsystems/nvme_i10

echo 1 > attr_allow_any_host
mkdir namespaces/10
cd namespaces/10
echo -n /dev/nvme0n1 > device_path
echo 1 > enable

mkdir /sys/kernel/config/nvmet/ports/1
cd /sys/kernel/config/nvmet/ports/1
echo $TARGET_IP > addr_traddr
echo i10 > addr_trtype
echo 4420 > addr_trsvcid
echo ipv4 > addr_adrfam

ln -s /sys/kernel/config/nvmet/subsystems/nvme_i10 /sys/kernel/config/nvmet/ports/1/subsystems/nvme_i10
