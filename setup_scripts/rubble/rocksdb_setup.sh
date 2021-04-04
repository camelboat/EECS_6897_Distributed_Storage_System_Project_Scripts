#!bin/bash

set -ex

RUBBLE_BRANCH='chain'

# Clone my_rocksdb
git clone https://github.com/camelboat/my_rocksdb -b ${RUBBLE_BRANCH}
cd my_rocksdb

# Install gflags
echo y | sudo apt install libgflags-dev

# Install and modify nlohmann_json
cd /mnt/sdb/my_rocksdb/nlohmann_json
git clone https://github.com/nlohmann/json.git
mkdir -p /tmp/rubble_gists
cd /tmp/rubble_gists
git clone https://gist.github.com/6e30397180d68b7e93969d63578fcc4c.git nlohmann_json
mv nlohmann_json/CMakeLists.txt /mnt/sdb/my_rocksdb/nlohmann_json/

git clone https://gist.github.com/6fbdf9cca0ab96072f9959e5013b7aa5.git nlohmann_json_single_include
mv nlohmann_json_single_include/json.hpp /mnt/sdb/my_rocksdb/single_include/

# Install gRPC and protobuf
cd /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/setup_scripts/gRPC
./grpc_setup.sh
export PATH=/root/bin:$PATH

# Build rocksdb
cd /mnt/sdb/my_rocksdb
cmake .
make -j32

