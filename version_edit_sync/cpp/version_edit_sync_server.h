#pragma once

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
using grpc::ServerReaderWriter;
using grpc::Status;
using version_edit_sync::VersionEditSyncService;
using version_edit_sync::VersionEditSyncRequest;
using version_edit_sync::VersionEditSyncReply;

using version_edit_sync::GetReply;
using version_edit_sync::GetRequest;
using version_edit_sync::PutReply;
using version_edit_sync::PutRequest;

class VersionEditSyncServiceImpl final : public VersionEditSyncService::Service {
  public:
    explicit VersionEditSyncServiceImpl(rocksdb::DB* db)
      :db_(db),put_count_(0){};
    
    ~VersionEditSyncServiceImpl(){
      delete db_;
    }

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

  Status Get(ServerContext* context,
                   ServerReaderWriter<GetReply, GetRequest>* stream) override { 

    GetRequest request;
    while (stream->Read(&request)) {
      GetReply response;
      std::string value;

      std::cout << "calling Get on key : " << request.key();
      rocksdb::Status s = db_->Get(rocksdb::ReadOptions(), request.key(), &value);
      std::cout << " return value : " << value << "\n";

      if(s.ok()){
          // find the value for the key
        response.set_value(value);
        response.set_ok(true);
      }else {
          response.set_ok(false);
      }

      stream->Write(response);
    }
    return Status::OK;
  }

   Status Put(ServerContext* context,
             ServerReaderWriter<PutReply, PutRequest> *stream) override {

    PutRequest request;
    while(stream->Read(&request)){
        PutReply reply;

        std::string key = request.key();
        std::string value = request.value();

        put_count_++;
        if(put_count_%100000 == 0){
          std::cout << "caliing put : (" << key << "," << value <<")\n";  
        }
        rocksdb::Status s = db_->Put(rocksdb::WriteOptions(), key, value);
        if (s.ok()){
            reply.set_ok(true);
        }else{
            reply.set_ok(false);
        }

        stream->Write(reply);
     }
     return Status::OK;
    }

  private:
    rocksdb::DB* db_;
    std::atomic<uint64_t> put_count_;

};

void RunServer(rocksdb::DB* db, const std::string server_addr) {
  
  std::string server_address(server_addr);
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