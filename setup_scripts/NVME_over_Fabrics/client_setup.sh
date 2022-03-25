#!/usr/bin/env bash

# Client should be the one who visits nvme device on other nodes(targets)

if [$# != 1]; then
  echo "Usage: ./client_setup.sh target_ip_addr"
  exit
fi

ADDR=$1

#NVMe over RoCE setup for client side
modprobe nvme-rdma

sudo apt install uuid-dev

# git clone https://github.com/linux-nvme/nvme-cli.git

# cd nvme-cli
# make
# make install

sudo apt install nvme-cli

nvme gen-hostnqn > /etc/nvme/hostnqn

nvme connect -t rdma -n nvme-target1 -a $ADDR -s 4420
