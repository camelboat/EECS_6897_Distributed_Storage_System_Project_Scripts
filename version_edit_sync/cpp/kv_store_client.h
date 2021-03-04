#pragma once

#include <vector>
#include <iostream>
#include <string>

#include <grpcpp/grpcpp.h>
#include <grpcpp/health_check_service_interface.h>
#include <grpcpp/ext/proto_server_reflection_plugin.h>
#include "rubble_kv_store.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;

using rubble::RubbleKvStoreService;
using rubble::GetReply;
using rubble::GetRequest;
using rubble::PutReply;
using rubble::PutRequest;

// Client used by user to make Put/Get requests to the db server
class KvStoreClient{

  public:
    KvStoreClient(std::shared_ptr<Channel> channel)
        : stub_(RubbleKvStoreService::NewStub(channel)),
        to_primary_(false){};

    KvStoreClient(std::shared_ptr<Channel> channel, bool to_primary)
        : stub_(RubbleKvStoreService::NewStub(channel)),
        to_primary_(to_primary){};
    
  // Requests each key in the vector and displays the key and its corresponding
  // value as a pair
  Status Get(const std::vector<std::string>& keys, std::vector<std::string>& vals) {
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
    Status status = stream->Finish();
    if (!status.ok()) {
      std::cout << status.error_code() << ": " << status.error_message()
                << std::endl;
      std::cout << "RPC failed";
    }
    return status;
  }

  Status Put(const std::pair<std::string, std::string>& kv){
    ClientContext context;
    auto stream = stub_->Put(&context);
    // for(const auto& kv: kvs){
        
        put_count_++;
        PutRequest request;
        request.set_key(kv.first);
        request.set_value(kv.second);

        stream->Write(request);

        PutReply reply;
        stream->Read(&reply);

        // if(put_count_ % 1000 == 0 ){
          std::cout << " Put ----> " ;
          if(to_primary_){
            std::cout << "Primary   ";
          }else{
            std::cout << "Secondary ";
          }
          std::cout <<" ( " << kv.first << " ," << kv.second << " ) , status : " ;
          if(reply.ok()){
            std::cout << "Succeeds";
          } else{
            
            std::cout << "Failed ( " << reply.status() << " )";
          }
          std::cout << "\n";  
        // }
    // }

    stream->WritesDone();

    Status s = stream->Finish();
    if(!s.ok()){
        std::cout << s.error_code() << ": " << s.error_message()
                << std::endl;
        std::cout << "RPC failed";
    }
    return s;
  }

  private:
    std::unique_ptr<RubbleKvStoreService::Stub> stub_ = nullptr;
      // Is this client sending kv to the primary? If not, it's sending kv to the secondary
    bool to_primary_ = false;
    std::atomic<uint64_t> put_count_{0};
};

