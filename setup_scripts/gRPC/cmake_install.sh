#!/bin/bash

set -x

nproc=16

#remove the default version
## --purge would remove ssl-cert, which stops output streaming if executed remotely
# sudo apt remove --purge --auto-remove cmake

sudo apt remove cmake

version=3.19
build=1

CMAKE_VERSION=$(cmake --version | head -1 | awk '{print $3}')
if [ $CMAKE_VERSION == ${version}.${build} ]; then
    echo "Already have cmake ${CMAKE_VERSION} installed".
    exit 0
fi

mkdir ~/temp
cd ~/temp
wget https://cmake.org/files/v$version/cmake-$version.$build.tar.gz
tar -xzvf cmake-$version.$build.tar.gz

cd cmake-$version.$build/
./bootstrap
make -j$(nproc)
sudo make install

cd ~
rm -rf ./temp