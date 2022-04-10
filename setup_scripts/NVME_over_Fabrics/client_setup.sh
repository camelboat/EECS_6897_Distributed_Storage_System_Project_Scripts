#!/usr/bin/env bash

set -x

TARGET_IP_ADDR='10.10.1.3'
SUBSYSTEM_NAME='nvme-target1'
RDMA_PORT='4420'
REMOTE_DEV='nvme1n1p4'
LOCAL_MT_DIR='remote'

for i in "$@"
do
case $i in
    -a=*|--target-ip-address=*)
    TARGET_IP_ADDR="${i#*=}"
    shift # past argument=value
    ;;
    -n=*|--subsystem-name=*)
    SUBSYSTEM_NAME="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--rdma-port=*)
    RDMA_PORT="${i#*=}"
    shift # past argument=value
    ;;
    -c=*|--is-connect=*) # ture/false, after client setup, connect to target device or not
    CONNECT="${i#*=}"
    shift # past argument=value
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

# NVMe over RoCE setup for client side
# Client should be the one who visits nvme device on other nodes(targets) 

modprobe nvme-rdma

echo 'y' | sudo apt install uuid-dev

# git clone https://github.com/linux-nvme/nvme-cli.git
# cd nvme-cli
# make
# make install

echo 'y' | sudo apt install nvme-cli

nvme gen-hostnqn > /etc/nvme/hostnqn

if [ ${CONNECT} == 'true' ]; then
    nvme connect -t rdma -n ${SUBSYSTEM_NAME} -a ${TARGET_IP_ADDR} -s ${RDMA_PORT}
    mkdir -p /mnt/${LOCAL_MT_DIR}
    mount /dev/${REMOTE_DEV} /mnt/${LOCAL_MT_DIR}
fi
