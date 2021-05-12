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
    -p=*|--ycsb-mode=*)
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

cd ${WORK_PATH}/YCSB;
git checkout $YCSB_BRANCH

if [ ${YCSB_MODE} == 'load' ]; then
    ./load.sh
fi

if [ ${YCSB_MODE} == 'run' ]; then
    ./run.sh
fi
