sudo apt install default-jre

./bin/ycsb load rocksdb -s -P workloads/workloada -p rocksdb.dir=~/rocksdb/ -p rocksdb.optionsfile=~/rocksdb_config/rocksdb.ini -threads 4
