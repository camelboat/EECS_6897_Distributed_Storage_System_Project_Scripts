#!bin/bash

set -ex

RUBBLE_BRANCH='chain'
RUBBLE_PATH='/mnt/sdb'

for i in "$@"
do
case $i in
    -b=*|--rubble_branch=*)
    RUBBLE_BRANCH="${i#*=}"
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

cd ${RUBBLE_PATH}/my_rocksdb/rubble
cmake .
make -j16
