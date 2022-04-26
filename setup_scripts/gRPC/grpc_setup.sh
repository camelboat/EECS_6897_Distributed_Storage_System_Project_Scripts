#!/bin/bash

set -x

RUBBLE_PATH='/mnt/code'

for i in "$@"
do
case $i in
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

GPRC_VERSION=1.34.0
NUM_JOBS=32

export MY_INSTALL_DIR=/root
mkdir -p $MY_INSTALL_DIR

export PATH="$PATH:$MY_INSTALL_DIR/bin"

sudo bash cmake_install.sh
apt-get install -y build-essential autoconf libtool pkg-config && \

cd ${RUBBLE_PATH}

if [ ! -d './grpc' ]; then
    git clone --recurse-submodules -b v${GPRC_VERSION} https://github.com/grpc/grpc
fi
cd grpc
mkdir -p cmake/build
pushd cmake/build
cmake -DgRPC_INSTALL=ON \
    -DgRPC_BUILD_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX=$MY_INSTALL_DIR \
    ../..
make -j${NUM_JOBS}
make install
popd

echo "grpc build success, building hellp world example "

cd ${RUBBLE_PATH}/grpc/examples/cpp/helloworld
mkdir -p cmake/build
pushd cmake/build
cmake -DCMAKE_PREFIX_PATH=$MY_INSTALL_DIR ../..
make -j

echo "export PATH=/root/bin:$PATH" >> /root/.bashrc

echo "hello world example build success"