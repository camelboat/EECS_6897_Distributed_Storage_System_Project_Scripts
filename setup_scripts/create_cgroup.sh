#!/bin/bash

# sudo apt install cgroup-tools

# cgcreate -t cl3875:lsm-rep-PG0 -a cl3875:lsm-rep-PG0 -g memory:mlsm

# Give 1.6G for 16M key size
echo 1717986039 | sudo tee /sys/fs/cgroup/memory/mlsm/memory.limit_in_bytes
echo 2147483648 | sudo tee /sys/fs/cgroup/memory/mlsm/memory.limit_in_bytes
echo 3221225472 | sudo tee /sys/fs/cgroup/memory/mlsm/memory.limit_in_bytes
echo 4294967296 | sudo tee /sys/fs/cgroup/memory/mlsm/memory.limit_in_bytes

echo 8589934592 | sudo tee /sys/fs/cgroup/memory/mlsm/memory.limit_in_bytes
echo 17179869184 | sudo tee /sys/fs/cgroup/memory/mlsm/memory.limit_in_bytes

# cgexec -g memory:mlsm executable

# cgdelete memory:mlsm
