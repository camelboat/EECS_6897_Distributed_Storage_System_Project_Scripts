#!bin/bash

set -ex

YCSB_BRANCH='singleOp'
WORK_PATH='/mnt/sdb'

for i in "$@"
do
case $i in
    -b=*|--ycsb_branch=*)
    YCSB_BRANCH="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--RUBBLE_PATH=*)
    RUBBLE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done

# Install java and maven
sudo apt install default-jdk maven -y
cd $WORK_PATH
git clone https://github.com/cc4351/YCSB.git
cd YCSB
git checkout $YCSB_BRANCH

# Modify configuration files
./build.sh
