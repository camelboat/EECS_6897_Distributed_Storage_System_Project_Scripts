#Discover available subsystesm on NVMF target.
# nvme discover -t rdma -a 10.10.1.2 -s 4420

#Connect to the discovered subsystem. (REPLACE the nvme-subsystem-name with the one probed)
# nvme connect -t rdma -n nvme-subsystem-name -a 10.10.1.2 -s 4420

#Disconnect from the target.
# nvme disconnect -d /dev/nvme0n1
# nvme disconnect -n nvme-subsystem-name

#Run from the client to see the list of the NVMe devices currently connected
# nvme list

#After establishing a connection between NVMF host and NVMF target, find a
#new NVMe block device under /dev/dir in the initiator side. Then perform a simple
# traffic test on the block device.
fio --bs=64k --numjobs=16 --iodepth=4 --loops=1 --ioengine=libaio --direct=1 \
--fsync_on_close=1 --randrepeat=1 --norandommap --time_based --runtime=60 \
--filename=/dev/nvme1n1 --name=read-phase --rw=randread

#Write to a block device
nvme write /dev/nvme1n1p4 -d file --data-size=520

#Read from a block device
nvme read /dev/nvme0n1p4 --data-size=520
