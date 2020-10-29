#!/bin/bash

cd /mnt/sdb/
git clone https://github.com/camelboat/my_rocksdb
git checkout -b my_test_branch
cd /mnt/sdb/my_rocksdb
sed -i '24iJAVA_HOME = "/usr/lib/jvm/default-java"' Makefile
sudo make -j32 rocksdbjava
