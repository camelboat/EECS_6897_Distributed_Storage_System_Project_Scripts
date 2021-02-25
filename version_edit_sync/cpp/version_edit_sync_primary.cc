#include <iostream>
#include <string>
#include <memory>

#include <grpcpp/grpcpp.h>
#include "version_edit_sync.grpc.pb.h"

#include "rocksdb/db.h"
#include "rocksdb/slice.h"
#include "rocksdb/options.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;
using version_edit_sync::VersionEditSyncService;
using version_edit_sync::VersionEditSyncRequest;
using version_edit_sync::VersionEditSyncReply;

class VersionEditSyncClient {
  public:
    VersionEditSyncClient(std::shared_ptr<Channel> channel)
        : stub_(VersionEditSyncService::NewStub(channel)) {}

    std::string VersionEditSync(const std::string& record) {
      VersionEditSyncRequest request;
      request.set_record(record);

      VersionEditSyncReply reply;
      ClientContext context;
      Status status = stub_->VersionEditSync(&context, request, &reply);

      if (status.ok()) {
        return reply.message();
      } else {
        std::cout << status.error_code() << ": " << status.error_message()
                    << std::endl;
          return "RPC failed";
      }
    }
  private:
    std::unique_ptr<VersionEditSyncService::Stub> stub_;
};

int main(int argc, char** argv) {
  // std::string target_str = "10.10.1.2:50051";
  // VersionEditSyncClient client(grpc::CreateChannel(
  //   target_str, grpc::InsecureChannelCredentials()
  // ));
  // std::string record = "A Test Record";
  // std::string reply = client.VersionEditSync(record);
  // std::cout << "Primary received: " << reply << std::endl;
  
  std::string kDBPath = "/tmp/rocksdb_primary_test";
  rocksdb::DB* db;
  rocksdb::Options options;
  // Optimize RocksDB. This is the easiest way to get RocksDB to perform well
  options.IncreaseParallelism();
  options.OptimizeLevelStyleCompaction();
  // create the DB if it's not already present
  options.create_if_missing = true;

  // open DB
  rocksdb::Status s = rocksdb::DB::Open(options, kDBPath, &db);
  assert(s.ok());

  // Put key-value
  for(int i = 0; i < 100000; ++i) {
    std::string key_str = std::to_string(i);
    std::string value = std::to_string(i);
    s = db->Put(rocksdb::WriteOptions(), key_str, value);
    //std::cout << "Put " << key_str << "-" << value << '\n';
  }
  assert(s.ok());
  return 0;
}
