#include "rubble_server.h"

rocksdb::DB* GetPrimaryDBInstance(const std::string& db_path, const std::string& secondary_server_address){

  rocksdb::DB* db;
  rocksdb::DBOptions db_options;
  // Optimize RocksDB. This is the easiest way to get RocksDB to perform well
  db_options.IncreaseParallelism();
  // create the DB if it's not already present
  db_options.create_if_missing = true;

  db_options.is_rubble = true;
  db_options.is_primary = true;
  db_options.target_address = secondary_server_address;
  db_options.remote_sst_dir = "/mnt/sdb/archive_dbs/secondary/sst_dir";

  db_options.db_paths.emplace_back(rocksdb::DbPath("/mnt/sdb/archive_dbs/primary/sst_dir", 10000000000));
  
  rocksdb::ColumnFamilyOptions cf_options;
  cf_options.OptimizeLevelStyleCompaction();
  cf_options.num_levels=5;

  // L0 size 16MB
  cf_options.max_bytes_for_level_base=16777216;
  cf_options.compression=rocksdb::kNoCompression;
  // cf_options.compression_per_level=rocksdb::kNoCompression:kNoCompression:kNoCompression:kNoCompression:kNoCompression;

  const int kWriteBufferSize = 64*1024;
  // memtable size set to 4MB
  cf_options.write_buffer_size=kWriteBufferSize;
  // sst file size 4MB
  cf_options.target_file_size_base=4194304;
 
  rocksdb::Options options(db_options, cf_options);

  // open DB
  rocksdb::Status s = rocksdb::DB::Open(options, db_path, &db);
  assert(s.ok());

  return db;
}

int main(int argc, char** argv) {
  
  const std::string primary_server_address = "localhost:50051";
  const std::string secondary_server_address = "localhost:50050";
  // secondary server is running on localhost:50050
  rocksdb::DB* primary_db = GetPrimaryDBInstance("/tmp/rocksdb_primary_test", secondary_server_address);

  // primary server is running on localhost:50051
  RunServer(primary_db, primary_server_address, true);
  return 0;
}
