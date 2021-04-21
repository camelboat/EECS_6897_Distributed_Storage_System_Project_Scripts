#!/bin/bash

set -x

sudo apt update
sudo apt install build-essential libssl-dev libncurses-dev -y

WORK_DIR='/mnt/sdb'
# SRC_LINK='https://mirrors.edge.kernel.org/pub/linux/kernel/v4.x/linux-4.20.tar.gz'
SRC_LINK='https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-5.0-rc3.tar.gz'
PKG_NAME='linux-5.0-rc3'

cd /mnt/sdb
cd $WORK_DIR
curl -OL $SRC_LINK

tar -xvf ${PKG_NAME}.tar.gz
cd ${PKG_NAME}

cp /boot/config-4.15.0-137-generic .config
yes "" | make oldconfig

make menuconfig

rm vmlinux-gdb.py
rm -rf debian/
make -j32 deb-pkg
cd /mnt/sdb
dpkg -i *.deb
