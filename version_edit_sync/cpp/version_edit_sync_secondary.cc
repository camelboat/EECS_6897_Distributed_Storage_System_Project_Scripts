#include <iostream>
#include <string>
#include <memory>

#include <grpcpp/grpcpp.h>
#include <grpcpp/health_check_service_interface.h>
#include <grpcpp/ext/proto_server_reflection_plugin.h>
#include "version_edit_sync.grpc.pb.h"

#include "rocksdb/db.h"
#include "port/port_posix.h"
#include "port/port.h"
#include "db/version_edit.h"
#include "db/db_impl/db_impl.h"
#include "rocksdb/slice.h"
#include "rocksdb/options.h"


using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;
using version_edit_sync::VersionEditSyncService;
using version_edit_sync::VersionEditSyncRequest;
using version_edit_sync::VersionEditSyncReply;

class VersionEditSyncServiceImpl final : public VersionEditSyncService::Service {
  public:
    explicit VersionEditSyncServiceImpl(rocksdb::DB* db)
      :db_(db){};

  Status VersionEditSync(ServerContext* context, const VersionEditSyncRequest* request, 
                          VersionEditSyncReply* reply) override {
    std::string prefix("Received record ");
    reply->set_message(prefix+request->record());
    std::cout << "Received from Rocksdb primary instance: " << request->record() << "\n";

    rocksdb::VersionEdit v_edit;
    v_edit.DecodeFrom(request->record());

    rocksdb::DBImpl* impl_ = (rocksdb::DBImpl*)db_;
    rocksdb::VersionSet* version_set = impl_->TEST_GetVersionSet();
    // rocksdb::VersionSet* version_set = impl_->versions_.get();
    rocksdb::ColumnFamilyData* default_cf = version_set->GetColumnFamilySet()->GetDefault();
    const rocksdb::MutableCFOptions* cf_options = default_cf->GetLatestMutableCFOptions();

    rocksdb::autovector<rocksdb::ColumnFamilyData*> cfds;
    cfds.emplace_back(default_cf);

    rocksdb::autovector<const rocksdb::MutableCFOptions*> mutable_cf_options_list;
    mutable_cf_options_list.emplace_back(cf_options);

    rocksdb::autovector<rocksdb::VersionEdit*> edit_list;
    edit_list.emplace_back(&v_edit);

    rocksdb::autovector<rocksdb::autovector<rocksdb::VersionEdit*>> edit_lists;
    edit_lists.emplace_back(edit_list);

    std::cout << "locking mutex\n";
    rocksdb::InstrumentedMutex* mu = impl_->mutex();
    rocksdb::InstrumentedMutexLock l(mu);

    rocksdb::FSDirectory* db_directory = impl_->directories_.GetDbDir();
    
    std::cout << "calling logAndApply \n";

    rocksdb::Status s = version_set->LogAndApply(cfds, mutable_cf_options_list, edit_lists, mu,
                      db_directory);

    rocksdb::VersionStorageInfo::LevelSummaryStorage tmp;

    auto vstorage = default_cf->current()->storage_info();
    const char* c = vstorage->LevelSummary(&tmp);

    std::cout << std::string(c) << std::endl;
    return Status::OK;

  }

  private:
    rocksdb::DB* db_;

};

void RunServer(rocksdb::DB* db) {
  //std::string server_address("10.10.1.2:50051");
  std::string server_address("localhost:50051");
  VersionEditSyncServiceImpl service(db);

  grpc::EnableDefaultHealthCheckService(true);
  grpc::reflection::InitProtoReflectionServerBuilderPlugin();
  ServerBuilder builder;

  builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
  builder.RegisterService(&service);
  std::unique_ptr<Server> server(builder.BuildAndStart());
  std::cout << "Server listening on " << server_address << std::endl;
  server->Wait();
}

int main(int argc, char** argv) {
  std::string kDBPath = "/tmp/rocksdb_secondary_test";
  rocksdb::DB* db;
  rocksdb::Options options;
  
  options.IncreaseParallelism();
  options.OptimizeLevelStyleCompaction();
  options.create_if_missing = true;

  rocksdb::Status s = rocksdb::DB::Open(options, kDBPath, &db);

  RunServer(db);
  return 0;
}
