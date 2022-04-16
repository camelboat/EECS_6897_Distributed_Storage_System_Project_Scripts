#!bin/bash

set -ex

RUBBLE_BRANCH='chain'

# Clone my_rocksdb
cd /mnt/sdb
if [ ! -d './my_rocksdb' ]; then
  git clone https://github.com/camelboat/my_rocksdb -b ${RUBBLE_BRANCH}
fi
cd my_rocksdb

# Install gflags
echo y | sudo apt install libgflags-dev

# Install gRPC and protobuf
cd /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/setup_scripts/gRPC
./grpc_setup.sh
export PATH=/root/bin:$PATH

# Build rocksdb
cd /mnt/sdb/my_rocksdb
cmake .
make -j32

