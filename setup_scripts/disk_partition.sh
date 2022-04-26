# !/bin/bash
set -ex

# change /dev/nvme0n1p4 to type Linux LVM before partitioning
BLOCK_DEVICE='/dev/nvme0n1'
ORIGINAL_PARTITION='nvme0n1p4'
FILENAME="nvme0n1.sfdisk"
sfdisk -d ${BLOCK_DEVICE} > ${FILENAME}
sed -i "/${ORIGINAL_PARTITION}/s/type=0/type=8e/" ${FILENAME}
sfdisk ${BLOCK_DEVICE} --no-reread < ${FILENAME}
partprobe

# create physical volume for nvme0n1p4
pvcreate /dev/nvme0n1p4
echo "Physical volume /dev/nvme0n1p4 successfully created."

# create volume group
ip_address=$(hostname -I | awk '{print $2}')
node_number="${ip_address: -1}"
VG_NAME="node-${ip_address: -1}-vg"
vgcreate ${VG_NAME} /dev/nvme0n1p4
echo  "Volume group ${VG_NAME} successfully created."

# create logical volumes inside the vg
lvcreate -n code -L 20g ${VG_NAME}
lvcreate -n db -L 50g ${VG_NAME}
lvcreate -n sst -L 140g ${VG_NAME}

# make ext4 fs on the lv just created
sudo mkfs.ext4 /dev/mapper/node--${node_number}--vg-code; sudo mkdir /mnt/code; sudo mount /dev/mapper/node--${node_number}--vg-code /mnt/code
sudo mkfs.ext4 /dev/mapper/node--${node_number}--vg-db; sudo mkdir /mnt/db; sudo mount /dev/mapper/node--${node_number}--vg-db /mnt/db
sudo mkfs.ext4 /dev/mapper/node--${node_number}--vg-sst; sudo mkdir /mnt/sst; sudo mount /dev/mapper/node--${node_number}--vg-sst /mnt/sst