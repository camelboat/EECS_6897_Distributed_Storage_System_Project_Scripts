#include "version_edit_sync_server.h"

int main(int argc, char** argv) {

  //secondary db path
  std::string kDBPath = "/tmp/rocksdb_secondary_test";
  std::string secondary_server_address = "localhost:50050";

  rocksdb::DB* db;
  rocksdb::DBOptions db_options;
  // Optimize RocksDB. This is the easiest way to get RocksDB to perform well
  db_options.IncreaseParallelism();
  // create the DB if it's not already present
  db_options.create_if_missing = true;

  db_options.is_rubble = true;
  db_options.is_secondary = true;

  db_options.db_paths.emplace_back(rocksdb::DbPath("/mnt/sdb/archive_dbs/primary/sst_dir", 10000000000));
  
  rocksdb::ColumnFamilyOptions cf_options;
  cf_options.OptimizeLevelStyleCompaction();
  // Number of Level 5
  cf_options.num_levels=5;
  // L0 size 16MB
  cf_options.max_bytes_for_level_base=16777216;
  cf_options.compression=rocksdb::kNoCompression;
  // cf_options.compression_per_level=rocksdb::kNoCompression:kNoCompression:kNoCompression:kNoCompression:kNoCompression;

  const int kWriteBufferSize = 10000;
  // memtable size set to 10000 Bytes, to trigger compaction more easily
  cf_options.write_buffer_size=kWriteBufferSize;

  // sst file size 4MB
  cf_options.target_file_size_base=4194304;
  cf_options.disable_auto_compactions=true;

  rocksdb::Options options(db_options, cf_options);
  options.db_paths.emplace_back(rocksdb::DbPath("/mnt/sdb/archive_dbs/secondary/sst_dir", 10000000000));

  rocksdb::Status s = rocksdb::DB::Open(options, kDBPath, &db);
  
  //secondary server running on port 50050
  RunServer(db, secondary_server_address);
  return 0;
}
