sudo apt install nvme-cli

TARGET_IP=10.10.1.2

modprobe i10-host
nvme connect -t i10 \
-n nvme_i10 \
-a $TARGET_IP \
-s 4420 \
-q nvme_i10_host

nvme list