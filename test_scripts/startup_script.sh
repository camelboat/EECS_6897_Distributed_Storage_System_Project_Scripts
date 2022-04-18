#!/bin/bash
set -ex
cd /mnt
git clone https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts scripts
cd /mnt/scripts
git checkout chen_test
cd setup_scripts
bash setup_single_env.sh -b=/dev/nvme0n1p4 -p=/mnt/sdb --operator
source /tmp/rubble_venv/bin/activate
cd ../test_scripts

