#include "version_edit_sync_server.h"

rocksdb::DB* GetPrimaryDBInstance(const std::string& db_path){
  // std::string kDBPath = "/tmp/rocksdb_primary_test";
  rocksdb::DB* db;
  rocksdb::Options options;
  // Optimize RocksDB. This is the easiest way to get RocksDB to perform well
  options.IncreaseParallelism();
  options.OptimizeLevelStyleCompaction();
  // create the DB if it's not already present
  options.create_if_missing = true;
  options.is_primary = true;

  options.db_paths.emplace_back(rocksdb::DbPath("/mnt/sdb/archive_dbs/primary/sst_dir", 10000000000));
  
  // open DB
  rocksdb::Status s = rocksdb::DB::Open(options, db_path, &db);
  assert(s.ok());

  return db;
}

int main(int argc, char** argv) {
  
  rocksdb::DB* primary_db = GetPrimaryDBInstance("/tmp/rocksdb_primary_test");

  RunServer(primary_db, "localhost:50000");
  
  return 0;
}
