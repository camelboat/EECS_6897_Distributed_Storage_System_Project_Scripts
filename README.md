# Project Structure

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
           |     |
           |     |---ycsb_workloads
           |     |     |
           |     |     |---workload_1-10_50-50
           |     |     |---workload_16-50-95-5
           |     |     |---workload_100-200_50-50
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
