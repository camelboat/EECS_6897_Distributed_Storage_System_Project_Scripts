#!bin/bash

set -x

RUBBLE_PATH='/mnt/code'
ARGS=''

for i in "$@"
do
case $i in
    -a=*|--arguments=*)
    ARGS="${i#*=}"
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

# bring up a new replicator
cd ${RUBBLE_PATH}/YCSB
echo ${ARGS}
(nohup ./bin/ycsb.sh ${ARGS} > replicator_log.txt 2>&1) &
