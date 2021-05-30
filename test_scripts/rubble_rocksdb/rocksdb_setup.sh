#!bin/bash

set -x

RUBBLE_BRANCH='rubble'
RUBBLE_PATH='/mnt/sdb'
TMP_SCRIPT_PATH='/tmp/rubble_scripts'
MEMORY_LIMIT_MB=$((2*1024)) # in megabytes
CGROUP_CONTROLLERS="memory"
CGROUP_PATH="mlsm"

for i in "$@"
do
case $i in
    -b=*|--rubble-branch=*)
    RUBBLE_BRANCH="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--rubble-path=*)
    RUBBLE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -m=*|--memory-limit-mb=*)
    MEMORY_LIMIT_MB="${i#*=}"
    shift # past argument=value
    ;;
    -c=*|--cgroup-controllers=*)
    CGROUP_CONTROLLERS="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--cgroup-path=*)
    CGROUP_PATH="${i#*=}"
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

# Install gRPC and protobuf
cd ${TMP_SCRIPT_PATH}
bash grpc_setup.sh --rubble-path=${RUBBLE_PATH}
export PATH=/root/bin:$PATH

# Clone my_rocksdb
cd ${RUBBLE_PATH}
if [ ! -d './my_rocksdb' ]; then
  git clone https://github.com/camelboat/my_rocksdb -b ${RUBBLE_BRANCH}
fi
cd my_rocksdb

# Install gflags
echo y | sudo apt install libgflags-dev

# Build rocksdb
cd ${RUBBLE_PATH}/my_rocksdb
cmake .
make -j32

# create cgroup to limit memory usage
# default to a 16GB db
cgcreate -g ${CGROUP_CONTROLLERS}:${CGROUP_PATH}
echo $((${MEMORY_LIMIT_MB}*1024*1024)) | sudo tee /sys/fs/cgroup/${CGROUP_CONTROLLERS}/${CGROUP_PATH}/memory.limit_in_bytes

