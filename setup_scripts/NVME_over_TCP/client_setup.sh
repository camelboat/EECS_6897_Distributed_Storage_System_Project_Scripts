#!/bin/bash

set -ex

NVME_SUBSYS=nvme_tcp_test
TARGET_ADDR=10.10.1.2
TARGET_PORT=4421

apt install nvme-cli
modprobe nvme
modprobe nvme-tcp

nvme discover -t tcp -a ${TARGET_ADDR} -s ${TARGET_PORT}

nvme connect -t tcp -n ${NVME_SUBSYS} -a ${TARGET_ADDR} -s ${TARGET_PORT}

echo "NVME-over-TCP client setup finished."
