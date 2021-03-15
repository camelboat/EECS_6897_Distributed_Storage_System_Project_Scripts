#!/bin/bash

echo "y" | apt install libibverbs-dev

cd /mnt/sdb
git clone https://github.com/erpc-io/eRPC
cd eRPC/

./scripts/packages/ubuntu18/required.sh
./scripts/packages/ubuntu18/optional.sh
# cmake . -DPERF=OFF -DTRANSPORT=infiniband -DROCE=on -DAZURE=off
cmake . -DPERF=OFF -DTRANSPORT=raw -DAZURE=off

# Need to edit /src/config.h
make -j

# Set the HugePages value.
sysctl -w vm.nr_hugepages=4096
# You can check the previous setting result by
grep Huge /proc/meminfo
