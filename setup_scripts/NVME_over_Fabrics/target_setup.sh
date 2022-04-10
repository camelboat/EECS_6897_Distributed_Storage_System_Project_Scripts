#!/usr/bin/env bash

set -x

# target server setup to enable NVMe over RoCE

#echo y | sudo mkfs.ext4 /dev/nvme0n1p4 # This is the part name for m510
#sudo mkdir /mnt/nvme0n1p4
#sudo mount /dev/nvme0n1p4 /mnt/nvme0n1p4

TARGET_IP_ADDR='10.10.1.2'
DEVICE_PATH='/dev/nvme0n1'
SUBSYSTEM_NAME='nvme-target1'
RDMA_PORT='4420'

for i in "$@"
do
case $i in
    -a=*|--target-ip-address=*)
    TARGET_IP_ADDR="${i#*=}"
    shift # past argument=value
    ;;
    -d=*|--device_path=*)
    DEVICE_PATH="${i#*=}"
    shift
    ;;
    -n=*|--subsystem-name=*)
    SUBSYSTEM_NAME="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--rdma-port=*)
    RDMA_PORT="${i#*=}"
    shift
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done

modprobe nvmet

modprobe nvmet-rdma

# create a nvme subsystem called "nvme-target1"
mkdir -p /sys/kernel/config/nvmet/subsystems/${SUBSYSTEM_NAME}
cd /sys/kernel/config/nvmet/subsystems/${SUBSYSTEM_NAME}

#allow any host to connect to the target
echo "1" > attr_allow_any_host

mkdir -p namespaces/10
cd namespaces/10

echo -n ${DEVICE_PATH} > device_path
echo 1 > enable

#setting nvme port
mkdir -p /sys/kernel/config/nvmet/ports/1
cd  /sys/kernel/config/nvmet/ports/1

echo ${TARGET_IP_ADDR} > addr_traddr
echo rdma > addr_trtype
echo ${RDMA_PORT} > addr_trsvcid
echo ipv4 > addr_adrfam

ln -s /sys/kernel/config/nvmet/subsystems/${SUBSYSTEM_NAME} /sys/kernel/config/nvmet/ports/1/subsystems/${SUBSYSTEM_NAME}
echo "NVMe-oF over RDMA target setup done on ${TARGET_IP_ADDR}"
