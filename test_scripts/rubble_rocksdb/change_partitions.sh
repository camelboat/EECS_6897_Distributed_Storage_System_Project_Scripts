# !/bin/bash
set -x

RUBBLE_PARTITION=false

for i in "$@"
do
case $i in
    --rubble-partition)
    RUBBLE_PARTITION=true
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done

# set some constants
ip_address=$(hostname -I | awk '{print $2}')
node_number="${ip_address: -1}"
VG_NAME="node-${ip_address: -1}-vg" # TODO: change this to /dev/mapper

# kill all db server processes
kill $(ps aux | grep shard | awk '{print $2}')

# umount remote-sst if applicable
umount /mnt/remote-sst

# remount /mnt/sst to rw partition
umount /mnt/sst
mount /dev/mapper/node--${node_number}--vg-sst /mnt/sst

# remove all files from /mnt/db
for d in /mnt/db/*
do
	if [ "$d" != /mnt/db/lost+found ]; then
		rm -rf "$d"
	fi
done


# remove all files from /mnt/sst
for d in /mnt/sst/*
do
	if [ "$d" != /mnt/sst/lost+found ]; then
		rm -rf "$d"
	fi
done


# umount /mnt/db and /mnt/sst
umount /mnt/db
umount /mnt/sst

# shrink the partition
# if baseline -> rubble: shrinks db 180g -> 50g
# else (rubble->baseline): shrinks sst 140g -> 10g
if ${RUBBLE_PARTITION}; then
	PART_TO_SHRINK="/dev/mapper/node--${node_number}--vg-db"
	e2fsck -f ${PART_TO_SHRINK}
	echo y | resize2fs ${PART_TO_SHRINK} 45G
	echo y | lvreduce -L 50g ${PART_TO_SHRINK}
	resize2fs ${PART_TO_SHRINK}
	e2fsck -f ${PART_TO_SHRINK}
else
	PART_TO_SHRINK="/dev/mapper/node--${node_number}--vg-sst"
	e2fsck -f ${PART_TO_SHRINK}
	echo y | resize2fs ${PART_TO_SHRINK} 8G
	echo y | lvreduce -L 10g ${PART_TO_SHRINK}
	resize2fs ${PART_TO_SHRINK}
	e2fsck -f ${PART_TO_SHRINK}
fi


# extend the partition
# if baseline -> rubble: extends sst 10g -> 140g
# else (rubble->baseline): extends db 50g -> 180g
if ${RUBBLE_PARTITION}; then
	PART_TO_EXTEND="/dev/mapper/node--${node_number}--vg-sst"
	e2fsck -f ${PART_TO_EXTEND}
	echo y | lvextend -L 140g ${PART_TO_EXTEND}
	resize2fs ${PART_TO_EXTEND}
	e2fsck -f ${PART_TO_EXTEND}
else
	PART_TO_EXTEND="/dev/mapper/node--${node_number}--vg-db"
	e2fsck -f ${PART_TO_EXTEND}
	echo y | lvextend -L 180g ${PART_TO_EXTEND}
	resize2fs ${PART_TO_EXTEND}
	e2fsck -f ${PART_TO_EXTEND}
fi


# mount the partitions to folders
sudo mount /dev/mapper/node--${node_number}--vg-db /mnt/db
sudo mount /dev/mapper/node--${node_number}--vg-sst /mnt/sst
