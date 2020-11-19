#!/bin/bash

LOCAL_BRANCH='my_test_branch_origin'
REMOTE_ADDR='cl3875@pc10.cloudlab.umass.edu'

cd /Users/camelboat/Desktop/Test/rocksdb
git add *
git commit
git push origin $LOCAL_BRANCH

ssh -p 22 $REMOTE_ADDR << EOF
cd /mnt/sdb/my_rocksdb;
sudo make clean;
sudo git pull origin ${LOCAL_BRANCH};
sudo git checkout ${LOCAL_BRANCH};
sudo make -j32 rocksdbjava;
sudo cp java/target/rocksdbjni-6.14.0-linux64.jar /root/.m2/repository/org/rocksdb/rocksdbjni/6.14.0/rocksdbjni-6.14.0.jar;
/bin/bash -i;
EOF
