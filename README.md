# EECS 6897 Distributed Storage Project Scripts
This is the experiment setup/testing scripts and database configuration files repo for Columbia University EECS 6897 Distributed Storage course project. The scripts are tested on [CloudLab](https://www.cloudlab.us/) single-node experiment, with hardware type r320, and default disk image(Ubuntu 18.04).

## Related Docs
- [Project Proposal](https://docs.google.com/document/d/10Lm-jubDBOmU9yy7izu_UKHuwxQAzoYct9zt2_DgtAY/edit?usp=sharing)
- [LSM optimizations in replicated settintgs](https://docs.google.com/document/d/17Gpa3x4bHyFTy2qgquJNm5kQGSuB3quuTmNIL1x4Qeg/edit?usp=sharing)

## Related Repos
- [EECS_6897_Distributed_Storage_System_Project_Data](https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Data)
- [my_rocksdb](https://github.com/camelboat/my_rocksdb)

## Usage for compiling RocksDB
- After the node starts, switch to administrator via `sudo -i`, the following procedure will assume that you have root access.

- Run the folllowing command to start the environment setup
``` bash
$ cd /
$ wget https://github.com/camelboat/EECS_6897_Distributed_Storage_System_Project_Scripts/blob/master/setup_scripts/setup_single_env.sh
$ ./setup_single_env.sh
```
This will format the empty disk and mount it to `/mnt/sdb`(CloudLab only provides about 16GB for default home directory, so we need to mount a larger disk as our working directory), install jdk, maven, and clone this scripts and data repos to our working directory `/root/mnt/sdb`. From now on, we will assume that all work happens under this directory.

- To clone and compile the modified version of RocksDB, run `compile_and_move.sh` by:
``` bash
$ cd /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/setup_scripts/
$ ./compile_and_move.sh
```
This script will clone the modified rocksdb, pull and checkout to a test branch(you need to uncomment the corresponding line to select the branch), add the `JAVA_HOME` variable path to the MakeFile, and compile it as a java ARchive file. The resulted `rocksdbjni-x.x.x.jar` file will be copy to `~/.m2/repository/org/rocksdb/rocksdbjni/x.x.x/rocksdbjni-x.x.x.jar` so that YCSB can know where the latest compiled rocksdb is.

- Install YCSB by
``` bash
$ cd /
$ git clone https://github.com/brianfrankcooper/YCSB
```

- To run the YCSB benchmark, modify the `WORKLOAD_NUM` variable in both `load_ycsb.sh` and `run_ycsb.sh`. The naming convention for `WORKLOAD_NUM` is `Key-size(M)`-`Operations Num(M)`-`Read Percentage(%)`-`Update Percentage(%)`. For example, naming `WORKLOAD_NUM` as `16-50_95-5` means workload of 16M keys, 50M operations, and in 50M operations there are 95% of reading operations and 5% of updating operations. After the modification, first perform YCSB load benchmark by
``` bash
$ cd /mnt/sdb/EECS_6897_Distributed_Storage_System_Project_Scripts/setup_scripts/
$ ./load_ycsb.sh
```
Then perform YCSB run benchmark by
``` bash
$ ./run_ycsb.sh
```
By default, the working directory for rocksdb is `/mnt/sdb/archive_dbs/${WORKLOAD_NUM}`, and the directory for SST files is `/mnt/sdb/archive_dbs/sst_dir/sst_last_run`(this path is hardcoded in rocksdb source code by us). `load_ycsb.sh` will remove the SST files in `sst_last_run`, and copy it to `sst_${WORKLOAD_NUM}_cpy` when load is finished. `run_ycsb.sh` will also remove the SST files in `sst_last_run`, and copy the corresponding `sst_${WORKLOAD_NUM}_cpy` back to `sst_last_run` before running the benchmark. All the benchmark results will be output to `/mnt/sdb/EECS_6987_Distributed_Storage_System_Project_data/${WORKLOAD_NUM}`.

For usage of NVME over Fabrics scripts, see README in /setup_scripts/NVME_over_Fabrics.

## Project Structure

```
/root/mnt/sdb
           |
           |---EECS_6987_Distributed_Storage_System_Project_data/
           |---EECS_6897_Distributed_Storage_System_Project_Scripts/
           |     |
           |     |---README.md
           |     |---rocksdb_config
           |     |     |
           |     |     |---rocksdb_auto_compaction_100.ini
           |     |     |---rocksdb_auto_compaction_16.ini
           |     |     |---rocksdb_no_auto_compaction.ini
           |     |
           |     |---setup_scripts
           |     |     |
           |     |     |---compile_and_move.sh
           |     |     |---load_ycsb.sh
           |     |     |---run_ycsb.sh
           |     |     |---setup_single_env.sh
           |     |     |---setup_single_rocksdb.sh
           |     |     |---setup_single_rdma.sh
           |     |     |---NVME_over_Fabrics
           |     |           |
           |     |           |---client_setup.sh
           |     |           |---client_util.sh
           |     |           |---target_setup.sh
           |     |
           |     |---ycsb_workloads
           |           |
           |           |---workload_1-10_50-50
           |           |---workload_16-50-95-5
           |           |---workload_100-200_50-50
           |            
           |---my_rocksdb
           |---archive_dbs
           |     |
           |     |---1-10_95-5_cpy
           |     |---16-50_95-5_cpy
           |     |---sst_dir
           |           |
           |           |---sst_1-10_95-5_cpy
           |           |---sst_16-50_95-5_cpy
           |
           |---YCSB

```
