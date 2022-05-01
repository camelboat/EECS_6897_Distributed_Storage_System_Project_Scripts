#!/bin/bash
# bash rubble_cleanup.sh
bash rubble_client_run.sh -m=tail -n=128.110.153.185:50050
sleep 1
bash rubble_client_run.sh -m=primary -n=128.110.153.157:50052
df -h
ps aux | grep _node
