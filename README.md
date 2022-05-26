# Test Scripts

## Environment Setup(three-m510, 2-replica n-shard setup example)

- Instantiate Cloudlab Experiment using [profile](https://www.cloudlab.us/manage_profile.php?action=edit&uuid=4bfc3b7b-b3f4-11eb-b1eb-e4434b2381fc). This experiment has three m510 nodes named node-0, node-1, and node-2. By default, we will use node-0 as the operator machine(running YCSB and Replicator), and RocksDBs are running on node-1 and node-2.
  - Alternatively, you can use [this profile](https://www.cloudlab.us/show-profile.php?uuid=ccd6c2b3-dace-11eb-8fd9-e4434b2381fc) for 4-m510 experiment setup
  - There's no profile with c6526-100g at the time of writing, and requesting c6526-100g ([hardware specs](https://docs.cloudlab.us/hardware.html)) usually requires a [reservation](https://www.cloudlab.us/resgroup.php) ahead of time.
- When the experiment is ready, login to node-0, and run the following commands(all run under `sudo`) to properly set up the environment on the operator node (node-0 / 10.10.1.1)
	```bash
	#!/bin/bash
	wget https://raw.githubusercontent.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts/rubble/test_scripts/startup_script.sh
	sudo bash startup_script.sh
	```
- Check your `/mnt/scripts/test_scripts/test_config.yml` file and make sure everything is correct, e.g. the max number of shards you would allocate. See section [Test Configuration](#test-configuration) for some caveats and a list of parameters to pay attention to.
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
### Collecting Results
- metrics
	- dstat on worker nodes: `/tmp/rubble_data/dstat_<num-of-shard>_<is_rubble>_<kv_per_shard>-<cpu/disk>.txt` 
	- throughput results on operator node:
		- load: /mnt/code/YCSB/load_\<name_of_workload\>.txt (e.g. load_shard4_workloada_vanilla_10k.txt)
		- run: /mnt/code/YCSB/run_\<name_of_workload\>.txt (e.g. load_shard4_workloada_vanilla_10k.txt)
		- plotting script: `/mnt/code/YCSB/plot-thru.py`, make sure that you're in the virtualenv (run `source /tmp/rubble_venv/bin/activate`) and sample command would be `python plot-thru.py <name_of_throughput_txt> <agg_count, typically 10 or 20>`

- logs
	- rocksdb:
		- `/mnt/code/my_rocksdb/rubble/log/shard-<shard-id>-<role>_cout.txt` for the db server stdout
		- `/mnt/code/my_rocksdb/rubble/log/shard-<shard-id>-<role>_log` for all the logs from RUBBLE_INFO_LOG calls
		- `/mnt/db/<shard-id>/<role>/db/LOG` for rocksdb-generated logs
  - replicator: `/mnt/code/YCSB/replicator_log.txt`


## Test Configuration
- The configuration file is divided into two sections: `physical_env_params` and `rubble_params`.
	- `physical_env_params` controls per-server specs and each server listed under `server_info` corresponds to a physical server. It is predominantly used by the framework during [environment setup](#environment-setupthree-m510-2-replica-n-shard-setup-example).
	- `rubble_params` controls per-shard specs and each node listed under `shard-info` represents a db server process running on a specific physical server and communicates through the designated port. Mainly referenced during evaluation but is used during setup to pre-allocate slots as well.
		- One caveat: note that `len(rubble_params['shard_info])` <= `rubble_params['shard_num']`, the former represents the max number of shard you would like to support and and is used to allocate the corresponding number of slots during setup, while the latter is what would be used during evaluation to determine how many shards would be run at that specific round of evaluation.
- Type Checks: there is a `test_config_schema.yml` associated with the `test_config.yml`. When you run `python rubble_init.py --dryrun`, a type check is automatically performed using this `test_config_schema.yml` against your `test_config.yml`. Therefore, every time you add or remove a field in `test_config.yml` please make sure to also update it in the schema file.

## Limitations & Future Work
- Note: this is just a list of things that could be done without any regard to their priorities.
- Removal of un-used parameters in `test_config.yml`
- TODO

## Operator Node and Worker Node File Structures
### Worker Node
- `/tmp/rubble_scripts` stores all the scripts shipped from operator node
- `/tmp/rubble_data` stores all the dstat csv files and the plots generated
- `/mnt/code` is where rocksdb code + the logs generated live
### Operator Node
- `/mnt/scripts` hosts the [script repo](https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts/tree/rubble)
- `/mnt/code/YCSB` hosts the [YCSB + replicator repo](https://github.com/cc4351/YCSB/tree/single-thread)

## FAQs and Common Debugging Scenarios
- A list of resources for debugging
	- `ps aux | grep <name of node>` to check if specific processes are still running, e.g. `ps aux | grep shard` to look for all db servers
	- check the logs for error messages (most likely in the *_cout.txt file, sometimes in *_log, see [Collecting Results](#collecting-results) section for their paths)
	- Hopefully you have run `ps aux | grep shard` while all nodes are up and running and persisted their PIDs somewhere. Check `/mnt/code/my_rocksdb/rubble/core.*.<PID>` for the generated core dump files. You will see them if the db server processes terminated with errors. You can run `gdb <name of executable> <name of core dump file>` to get a trace for the error.
- Where to Find All the Code
	- rubble: [link](https://github.com/camelboat/my_rocksdb/tree/lhy_dev), `lhy_dev` branch
	- YCSB: [link](https://github.com/cc4351/YCSB/tree/single-thread), `single-thread` branch
	- script/framework: [link](https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts/tree/rubble), `rubble` branch
- What exactly happens when I run `python rubble_init.py --setup`?
	- good starting point for reading the code: [`setup_rubble_env` function](https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts/blob/5f8ea676b2bafdceb88bef4f99f080f9382062e2/test_scripts/utils/rubble_setup.py#L242) and there are documentations in every substaintial functions included in the `rubble_setup.py` file.
- What exactly happens when I run `python rubble_init.py --eval`?
	- good starting point for reading the code [`rubble_eval` function](https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts/blob/5f8ea676b2bafdceb88bef4f99f080f9382062e2/test_scripts/utils/rubble_eval.py#L270), and again documentations are included in each substaintial functions in the `rubble_eval.py` file.
- How does the framework fit together?
	- The framework is written in Python and Bash. Generally, the Python part is run on the operator node and contains all the logic (or the smarter part of the framework, e.g. what arguments to pass to specific programs), and the bash scripts are the ones actually executed on the remote worker node (or sometimes the operator node itself when running YCSB + replicator).
	- General flow: a Python script on operator node is brought up -> a specific function is evoked -> within the function all the arguments to a specific bash script is composed -> the said bash script (with any additional helper scripts it would need) would be shipped to remote machine into `/tmp/rubble_scripts` path first -> the bash script is executed on the remote by the root user -> results and logs would be mirrored back to the operator node.

