#!bin/bash

# set -ex
RUBBLE_PATH='/mnt/code'
WORKLOAD='a'
RECORD_COUNT=1000000
OPERATION_COUNT=1000000

for i in "$@"
do
case $i in
    -p=*|--rubble-path=*)
    RUBBLE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -w=*|--workload=*)
    WORKLOAD="${i#*=}"
    shift # past argument=value            
    ;;
    -rc=*|--record-count=*)
    RECORD_COUNT="${i#*=}"
    shift # past argument=value            
    ;;
    -oc=*|--operation-count=*)
    OPERATION_COUNT="${i#*=}"
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

# go the workload folder and find the matching workload file
cd ${RUBBLE_PATH}/YCSB/workloads

# overwrite the opcounts
sed -ire "s/recordcount=\w*/recordcount=${RECORD_COUNT}/" workload${WORKLOAD}
sed -ire "s/operationcount=\w*/operationcount=${OPERATION_COUNT}/" workload${WORKLOAD}

