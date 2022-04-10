#/bin/bash
set -e

# git clone the script repo
git clone https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts.git /mnt/scripts/
cd /mnt/scripts/setup_scripts && git checkout chen_test
bash /mnt/scripts/setup_scripts/setup_single_env.sh
bash /mnt/scripts/setup_scripts/gRPC/cmake_install.sh
bash /mnt/scripts/setup_scripts/gRPC/grpc_setup.sh

# build my_rocksdb
git clone https://github.com/camelboat/my_rocksdb.git /mnt/sdb/my_rocksdb/
cd /mnt/sdb/my_rocksdb && git checkout recovery && cmake . && make -j16


