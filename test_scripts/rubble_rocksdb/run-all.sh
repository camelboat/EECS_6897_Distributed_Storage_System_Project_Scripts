#!/bin/bash
# bash rubble_cleanup.sh
bash run-tail.sh
bash run-primary.sh
df -h
ps aux | grep _node
