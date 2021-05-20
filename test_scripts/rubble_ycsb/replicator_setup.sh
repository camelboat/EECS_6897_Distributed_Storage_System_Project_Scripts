#!bin/bash

set -ex

YCSB_BRANCH='singleOp'
RUBBLE_PATH='/mnt/sdb'

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
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done

cd ${RUBBLE_PATH}/YCSB
git checkout $YCSB_BRANCH
cd ./replicator
(nohup ./compile.sh) &
