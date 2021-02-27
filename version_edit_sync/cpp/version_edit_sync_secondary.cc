#include "version_edit_sync_server.h"

int main(int argc, char** argv) {
  std::string kDBPath = "/tmp/rocksdb_secondary_test";
  rocksdb::DB* db;
  rocksdb::Options options;
  
  options.IncreaseParallelism();
  options.OptimizeLevelStyleCompaction();
  options.create_if_missing = true;

  options.db_paths.emplace_back(rocksdb::DbPath("/mnt/sdb/archive_dbs/secondary/sst_dir", 10000000000));

  rocksdb::Status s = rocksdb::DB::Open(options, kDBPath, &db);
  
  //secondary server running on port 50051
  RunServer(db, "localhost:50051");
  return 0;
}
