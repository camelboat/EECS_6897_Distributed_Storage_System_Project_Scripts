#include <iostream>
#include <string>
#include <memory>

#include <grpcpp/grpcpp.h>
#include <grpcpp/health_check_service_interface.h>
#include <grpcpp/ext/proto_server_reflection_plugin.h>
#include "version_edit_sync.grpc.pb.h"

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
  Status VersionEditSync(ServerContext* context, const VersionEditSyncRequest* request, 
                          VersionEditSyncReply* reply) override {
    std::string prefix("Received record ");
    reply->set_message(prefix+request->record());
    return Status::OK;
  }
};

void RunServer() {
  std::string server_address("10.10.1.2:50051");
  VersionEditSyncServiceImpl service;

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
  RunServer();
  return 0;
}
