#!bin/bash

set -ex

YCSB_BRANCH='singleOp'
WORK_PATH='/mnt/sdb'
YCSB_MODE='load' #load, run

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
    -p=*|--YCSB_MODE=*)
    YCSB_MODE="${i#*=}"
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

cd ${WORK_PATH}/YCSB
git checkout $YCSB_BRANCH

cd ./replicator
(nohup ./compile.sh rubblejava/Replicator) &