# Test Scripts

## Environment Setup(three-m510, 2-replica 2-shard setup example)

- Instantiate Cloudlab Experiment using [profile](https://www.cloudlab.us/manage_profile.php?action=edit&uuid=4bfc3b7b-b3f4-11eb-b1eb-e4434b2381fc). This experiment has three m510 nodes named node-0, node-1, and node-2. By default, we will use node-0 as the operator machine(running YCSB and Replicator), and RocksDBs are running on node-1 and node-2.
- When the experiment is ready, login to node-0, and run the following commands(all run under `sudo`) to create file system on NVMe device, mount it, install necessary packages, create Python virtual environment for running the testing framework, and install Python packages needed.
```bash
#!/bin/bash
# assumes sudo priviledge
wget https://raw.githubusercontent.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts/chen_test/test_scripts/startup_script.sh
bash startup_script.sh
```
- Check your `test_config.yml` file and make sure everything is correct, e.g., the IP map. See section [Test Configuration](#test-configuration) for details. The default configuration file in this repo is ready to use for the three-m510 setup.
- Now the virtual environment is in `/tmp/rubble_venv`, enter it via
`source /tmp/rubble_venv`, and test if you have the required libs installed by issueing a dryrun:
```bash
python rubble_init.py --dryrun
```
- If you have all the libs needed, you will see "Hello!" messages from the other two machines.
- To setup the environment
```bash
python rubble_init.py
```
- Now we can start the distributed system setup by:
```bash
python rubble_init.py
```
- This process may take about half hour.

## Test Configuration
