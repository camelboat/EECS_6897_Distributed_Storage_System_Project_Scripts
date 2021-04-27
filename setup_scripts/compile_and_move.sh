#!/bin/bash

cd /mnt/sdb
git clone https://github.com/camelboat/my_rocksdb
cd my_rocksdb/
# git pull origin my_test_branch_origin
# git pull origin my_test_branch_2
sed -i '24iJAVA_HOME = "/usr/lib/jvm/default-java"' Makefile
make -j32 rocksdbjava

# Change pom.xml in YCSB for rocksdb version to 6.13.3
mkdir -p /root/.m2/repository/org/rocksdb/rocksdbjni/6.14.0 && cp /mnt/sdb/my_rocksdb/java/target/rocksdbjni-6.14.0-linux64.jar /root/.m2/repository/org/rocksdb/rocksdbjni/6.14.0/rocksdbjni-6.14.0.jar;
