#!bin/bash

set -ex

YCSB_BRANCH='singleOp'
WORK_PATH='/mnt/sdb'
YCSB_MODE='load' #load, run

for i in "$@"
do
case $i in
    -b=*|--ycsb-branch=*)
    YCSB_BRANCH="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--rubble-path=*)
    RUBBLE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -y=*|--ycsb-mode=*)
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
bash build-rpc.sh rubble_vn_store.proto
(nohup ./compile.sh rubblejava/Replicator) &
