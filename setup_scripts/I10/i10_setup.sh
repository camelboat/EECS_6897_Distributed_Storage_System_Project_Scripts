#!/bin/bash

# Install the ncursees library.
echo y | sudo apt-get install libncurses5-dev libncursesw5-dev

cd /mnt/sdb
# Get linux kernel 4.20.0
wget http://www.cs.cornell.edu/~jaehyun/eb00c1a1852eb91e1b303aad0cb331318b7b9a0c.tar.gz
tar -xvf eb00c1a1852eb91e1b303aad0cb331318b7b9a0c.tar.gz
mv nvme-eb00c1a/ linux-4.20.0/
rm eb00c1a1852eb91e1b303aad0cb331318b7b9a0c.tar.gz

# Get i10 implementation
git clone https://github.com/i10-kernel/i10-implementation.git
cd i10-implementation
cp -rf drivers include /mnt/sdb/linux-4.20.0/
cd /mnt/sdb/linux-4.20.0/

# Update kernel configuration
cp /boot/config-* .config
# make oldconfig
yes "" | make oldconfig

# Make sure i10 modules are included in the kernel configuration.
# - To include i10 host: Device Drivers ---> NVME Support ---> <M> i10: A New Remote Storage I/O Stack (host)
# - To include i10 target: Device Drivers ---> NVME Support ---> <M> i10: A New Remote Storage I/O Stack (target)
# - To use the high resolution timer: General setup ---> Timers subsystem ---> [*] High Resolution Timer Support
make menuconfig

make -j32 bindeb-pkg LOCALVERSION=-my-k;
sudo dpkg -i 

# Compile and Install
#make -j32 bzImage;
#make -j32 modules;
#make modules_install;
#make install;

# Then reboot
