#!/usr/bin/env bash

set -ex

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
