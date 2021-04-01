#!/bin/bash
nproc=16

#remove the default version
echo y | sudo apt remove --purge --auto-remove cmake

version=3.19
build=1
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