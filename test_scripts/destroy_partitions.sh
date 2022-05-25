# !/bin/bash
set -x

SUBSYSTEM_NAME='nvme-target1'
WORK_PATH='/mnt/code'
DB_PATH='/mnt/db'
LOCAL_SST_PATH='/mnt/sst'
REMOTE_DEVICE_PATH='/mnt/remote-sst'


# set some constants
ip_address=$(hostname -I | awk '{print $2}')
node_number="${ip_address: -1}"
VG_NAME="node-${ip_address: -1}-vg"
ORIGINAL_PARTITION='/dev/nvme0n1p4'


# kill all db server processes
kill $(ps aux | grep shard | awk '{print $2}')

# umount all the directories
umount ${WORK_PATH}
umount ${DB_PATH}
umount ${LOCAL_SST_PATH}
umount ${REMOTE_DEVICE_PATH}

# disconnect the remote nvme devices
nvme disconnect -n ${SUBSYSTEM_NAME}

# remove all the logical volumes
echo y | lvremove /dev/${VG_NAME}/code
echo y | lvremove /dev/${VG_NAME}/db
echo y | lvremove /dev/${VG_NAME}/sst

# remove all the volume groups
vgremove ${VG_NAME}

# remove all the lvm physical volumes
pvremove ${ORIGINAL_PARTITION}

# delete all folders
rm -rf ${WORK_PATH}
rm -rf ${DB_PATH}
rm -rf ${LOCAL_SST_PATH}
rm -rf ${REMOTE_DEVICE_PATH}

# send reboot signal

