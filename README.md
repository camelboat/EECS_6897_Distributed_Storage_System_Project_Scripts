# Test Scripts

## Environment Setup(three-m510, 2-replica 2-shard setup example)

- Instantiate Cloudlab Experiment using [profile](https://www.cloudlab.us/manage_profile.php?action=edit&uuid=4bfc3b7b-b3f4-11eb-b1eb-e4434b2381fc). This experiment has three m510 nodes named node-0, node-1, and node-2. By default, we will use node-0 as the operator machine(running YCSB and Replicator), and RocksDBs are running on node-1 and node-2.
- When the experiment is ready, login to node-0, and run the following commands(all run under `sudo`) to create file system on NVMe device, mount it, install necessary packages, create Python virtual environment for running the testing framework, and install Python packages needed.
	```bash
	#!/bin/bash
	wget https://raw.githubusercontent.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts/rubble/test_scripts/startup_script.sh
	sudo bash startup_script.sh
	```
- Check your `test_config.yml` file and make sure everything is correct, e.g., the IP map. See section [Test Configuration](#test-configuration) for details. The default configuration file in this repo is ready to use for the three-m510 setup.
- Now the virtual environment is in `/tmp/rubble_venv`, enter it via
`source /tmp/rubble_venv/bin/activate`, and test if you have the required libs installed by issueing a dryrun:
	```bash
	python rubble_init.py --dryrun
	```
- If you have all the libs needed, you will see "Hello!" messages from the other two machines.
- To setup the environment
	```bash
	python rubble_init.py --setup
	```
- This process may take about half hour.

## Test Configuration
- Once you have all the setup work done, please check
  - `test_config.yml` again, specifically the `rubble_params` for the experiment setup, modify it as needed.
  - the `rubble_eval` function in `utils/rubble_eval.py`, the default code represents one
		round of end-to-end evaluation for using workload a with 2-shard, 2-replica. For test config, modify the `test_config.yml` file, note that you need to check the `is_rubble`
		flag in the `run_rocksdb_servers` function call within `rubble_eval` function.
- Once the check is done, make sure that you are in the rubble_venv virtualenv, and run
  ```
	python rubble_init.py --eval
	```
- Logs:
  - rocksdb: /mnt/code/my_rocksdb/rubble/log/<role>_log.txt
  - replicator: /mnt/code/YCSB/replicator_log.txt
  - YCSB:
    - load: /mnt/code/YCSB/load_<name_of_workload>.txt (e.g. load_a.txt)
    - run: /mnt/code/YCSB/run_<name_of_workload>.txt (e.g. run_a.txt)