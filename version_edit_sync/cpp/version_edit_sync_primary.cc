#include <iostream>
#include <string>
#include <memory>

#include <grpcpp/grpcpp.h>
#include "version_edit_sync.grpc.pb.h"

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
  std::string target_str = "10.10.1.2:50051";
  VersionEditSyncClient client(grpc::CreateChannel(
    target_str, grpc::InsecureChannelCredentials()
  ));
  std::string record = "A Test Record";
  std::string reply = client.VersionEditSync(record);
  std::cout << "Primary received: " << reply << std::endl;
  return 0;
}
