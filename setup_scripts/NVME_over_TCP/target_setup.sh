#!/bin/bash

set -ex

modprobe nvme_tcp
modprobe nvmet
modprobe nvmet-tcp

NVME_SUBSYS=nvme_tcp_test
NAMESPACE=11
TARGET_DEV=nvme0n1p4
TARGET_ADDR=10.10.1.2
TARGET_PORT=4421

mkdir -p /sys/kernel/config/nvmet/subsystems/${NVME_SUBSYS}
cd /sys/kernel/config/nvmet/subsystems/${NVME_SUBSYS}

## Allow any host to connect to the target
echo 1 | tee -a attr_allow_any_host > /dev/null

## Make namespace
mkdir namespaces/${NAMESPACE}
cd namespaces/${NAMESPACE}

## Set target device
echo -n /dev/${TARGET_DEV} | tee -a device_path > /dev/null
echo 1 | tee -a enable > /dev/null

## Set nvme port
mkdir /sys/kernel/config/nvmet/ports/1
cd  /sys/kernel/config/nvmet/ports/1
echo ${TARGET_ADDR} > addr_traddr
echo tcp | tee -a addr_trtype > /dev/null
echo ${TARGET_PORT} | tee -a addr_trsvcid > /dev/null
echo ipv4 | tee -a addr_adrfam > /dev/null
ln -s /sys/kernel/config/nvmet/subsystems/${NVME_SUBSYS} /sys/kernel/config/nvmet/ports/1/subsystems/${NVME_SUBSYS}

echo "NVMe-over-TCP Target setup finished."
