#!bin/bash

# set -ex

YCSB_BRANCH='recovery'
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

# kill old running Replicator processes
kill $(ps aux | grep Replicator | awk '{print $2}')

# start a new Replicator
cd ${RUBBLE_PATH}/YCSB
(nohup ./bin/ycsb.sh replicator rocksdb -s -P workloads/workloada -p port=50050 -p shard=1 -p tail1=10.10.1.3:50052 -p head1=10.10.1.2:50051 -p replica=2 > replicator.txt) &

REPLICATOR_PID=$!
echo ${REPLICATOR_PID}
