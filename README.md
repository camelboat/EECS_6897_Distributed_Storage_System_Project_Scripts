# Test Scripts

## Environment Setup(three-m510, 2-replica n-shard setup example)

- Instantiate Cloudlab Experiment using [profile](https://www.cloudlab.us/manage_profile.php?action=edit&uuid=4bfc3b7b-b3f4-11eb-b1eb-e4434b2381fc). This experiment has three m510 nodes named node-0, node-1, and node-2. By default, we will use node-0 as the operator machine(running YCSB and Replicator), and RocksDBs are running on node-1 and node-2.
  - Alternatively, you can use [this profile](https://www.cloudlab.us/show-profile.php?uuid=ccd6c2b3-dace-11eb-8fd9-e4434b2381fc) for 4-m510 experiment setup
  - There's no profile with c6526-100g at the time of writing, and requesting c6526-100g ([hardware specs](https://docs.cloudlab.us/hardware.html)) usually requires a reservation ahead of time ([link](https://www.cloudlab.us/resgroup.php))
- When the experiment is ready, login to node-0, and run the following commands(all run under `sudo`) to properly set up the environment on the operator node (node-0 / 10.10.1.1)
	```bash
	#!/bin/bash
	wget https://raw.githubusercontent.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts/rubble/test_scripts/startup_script.sh
	sudo bash startup_script.sh
	```
- Check your `/mnt/scripts/test_scripts/test_config.yml` file and make sure everything is correct, e.g., the IP map. See section [Test Configuration](#test-configuration) for some caveats and a list of parameters to pay attention to.
  - The default configuration file in this repo is ready to use for the three-m510 setup that supports up to 8 shards.
- Run
`source /tmp/rubble_venv/bin/activate`, and test if you have the required libs installed by issueing a dryrun:
	```bash
	python rubble_init.py --dryrun
	```
  - If you have all the libs needed, you will see "Hello!" messages from the other two machines.
- To setup the environment on all worker nodes and install YCSB on the operator node:
	```bash
	python rubble_init.py --setup
	```
- This process may take about half hour.

## Define Your Evaluation and Execute It
- Once you have all the setup work done, please check
  - `test_config.yml` again, specifically the `rubble_params` for the experiment setup, modify it as needed. Similarly, please check section [Test Configuration](#test-configuration) for more info on how to interpret and modify the config file.
  - the `rubble_eval` function in `utils/rubble_eval.py`, the default code represents one
		round of end-to-end evaluation for using workload a with 2-shard, 2-replica. For test config, modify the `test_config.yml` file, note that you need to check the `is_rubble`
		flag in the `run_rocksdb_servers` function call within `rubble_eval` function.
- Once the check is done, make sure that you are in the rubble_venv virtualenv, and run
  ```
	python rubble_init.py --eval
	```
- Logs:
  - rocksdb:
    - `/mnt/code/my_rocksdb/rubble/log/shard-<shard-id>-<role>_cout.txt` for the db server stdout
    - `/mnt/code/my_rocksdb/rubble/log/shard-<shard-id>-<role>_log` for all the logs from RUBBLE_INFO_LOG calls
    - `/tmp/rubble_data/dstat_<num-of-shard>_<is_rubble>_<kv_per_shard>-<cpu/disk>.txt` dstat output
  - replicator: `/mnt/code/YCSB/replicator_log.txt`
  - YCSB:
    - load: /mnt/code/YCSB/load_\<name_of_workload\>.txt (e.g. load_shard4_workloada_vanilla_10k.txt)
    - run: /mnt/code/YCSB/run_\<name_of_workload\>.txt (e.g. load_shard4_workloada_vanilla_10k.txt)

## Test Configuration

## Limitations of This Framework

## Operator Node and Worker Node File Structures

## FAQs and Common Debugging Scenarios
