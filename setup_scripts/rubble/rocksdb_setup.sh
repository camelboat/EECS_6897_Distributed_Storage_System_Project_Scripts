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

# Install and modify nlohmann_json
cd /mnt/sdb/my_rocksdb/nlohmann_json
rm -rf json
git clone https://github.com/nlohmann/json.git
mkdir -p /tmp/rubble_gists
cd /tmp/rubble_gists

if [ -d './nlohmann_json' ]; then
  rm -rf ./nlohmann_json
fi
git clone https://gist.github.com/6e30397180d68b7e93969d63578fcc4c.git nlohmann_json  
mv nlohmann_json/CMakeLists.txt /mnt/sdb/my_rocksdb/nlohmann_json/json/

if [ -d './nlohmann_json_single_include' ]; then
  rm -rf ./nlohmann_json_single_include
fi
git clone https://gist.github.com/6fbdf9cca0ab96072f9959e5013b7aa5.git nlohmann_json_single_include
mv nlohmann_json_single_include/json.hpp /mnt/sdb/my_rocksdb/nlohmann_json/json/single_include/nlohmann/

# Install gRPC and protobuf
cd /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/setup_scripts/gRPC
./grpc_setup.sh
export PATH=/root/bin:$PATH

# Build rocksdb
cd /mnt/sdb/my_rocksdb
cmake .
make -j32

