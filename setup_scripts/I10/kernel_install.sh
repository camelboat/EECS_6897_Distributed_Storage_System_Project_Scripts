#!/bin/bash

set -e

cd /mnt/sdb
curl -OL https://mirrors.edge.kernel.org/pub/linux/kernel/v4.x/linux-4.20.tar.gz

# curl -OL https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-5.0-rc3.tar.gz
tar -xvf linux-4.20.tar.gz
cd linux-4.20

cp /boot/config-4.15.0-137-generic .config
yes "" | make oldconfig

sudo apt-get install build-essential libssl-dev

rm vmlinux-gdb.py
rm -rf debian/
make -j32 deb-pkg
cd /mnt/sdb
dpkg -i *.deb
