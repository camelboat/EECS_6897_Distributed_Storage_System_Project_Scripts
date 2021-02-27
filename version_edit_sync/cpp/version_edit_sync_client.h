#pragma once

#include <vector>
#include <iostream>
#include <string>

#include <grpcpp/grpcpp.h>
#include <grpcpp/health_check_service_interface.h>
#include <grpcpp/ext/proto_server_reflection_plugin.h>
#include "version_edit_sync.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
// using grpc::Status;
using version_edit_sync::VersionEditSyncService;
using version_edit_sync::VersionEditSyncRequest;
using version_edit_sync::VersionEditSyncReply;

using version_edit_sync::GetReply;
using version_edit_sync::GetRequest;
using version_edit_sync::PutReply;
using version_edit_sync::PutRequest;

class VersionEditSyncClient {
  public:
    VersionEditSyncClient(std::shared_ptr<Channel> channel)
        : stub_(VersionEditSyncService::NewStub(channel)) {}

    std::string VersionEditSync(const std::string& record) {
      VersionEditSyncRequest request;
      request.set_record(record);

      VersionEditSyncReply reply;
      ClientContext context;
      grpc::Status status = stub_->VersionEditSync(&context, request, &reply);

      if (status.ok()) {
        return reply.message();
      } else {
        std::cout << status.error_code() << ": " << status.error_message()
                    << std::endl;
          return "RPC failed";
      }
    }

  // Requests each key in the vector and displays the key and its corresponding
  // value as a pair
  grpc::Status Get(const std::vector<std::string>& keys, std::vector<std::string>& vals) {
    // Context for the client. It could be used to convey extra information to
    // the server and/or tweak certain RPC behaviors.
    ClientContext context;
    auto stream = stub_->Get(&context);
    for (const auto& key : keys) {
      // Key we are sending to the server.
      GetRequest request;
      request.set_key(key);
      stream->Write(request);

      // Get the value for the sent key
      GetReply response;
      stream->Read(&response);

      vals.emplace_back(response.value());
      std::cout << key << " : " << response.value() << "\n";
    }

    stream->WritesDone();
    grpc::Status status = stream->Finish();
    if (!status.ok()) {
      std::cout << status.error_code() << ": " << status.error_message()
                << std::endl;
      std::cout << "RPC failed";
    }
    return status;
  }

  grpc::Status Put(const std::pair<std::string, std::string>& kv){
    ClientContext context;
    auto stream = stub_->Put(&context);
    // for(const auto& kv: kvs){
        
        PutRequest request;
        request.set_key(kv.first);
        request.set_value(kv.second);

        stream->Write(request);

        PutReply reply;
        stream->Read(&reply);
        std::cout << "Put : ( " << kv.first << " ," << kv.second << " ) , status : " << reply.ok() << "\n";  
    // }

    stream->WritesDone();

    grpc::Status s = stream->Finish();
    if(!s.ok()){
        std::cout << s.error_code() << ": " << s.error_message()
                << std::endl;
        std::cout << "RPC failed";
    }
    return s;
  }

  private:
    std::unique_ptr<VersionEditSyncService::Stub> stub_;
};