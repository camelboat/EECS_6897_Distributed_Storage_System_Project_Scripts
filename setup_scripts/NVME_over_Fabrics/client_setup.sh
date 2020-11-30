#!/usr/bin/env bash

#NVMe over RoCE setup for client side
modprobe nvme-rdma

apt-get install uuid-dev

git clone https://github.com/linux-nvme/nvme-cli.git

cd nvme-cli
make
make install

nvme gen-hostnqn > /etc/nvme/hostnqn
