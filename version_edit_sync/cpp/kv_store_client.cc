#include "version_edit_sync_client.h"

int main(){

// I'm actually acting as a kv_store client
  VersionEditSyncClient client1(grpc::CreateChannel(
    "localhost:50051", grpc::InsecureChannelCredentials()));

  VersionEditSyncClient client2(grpc::CreateChannel(
    "localhost:50050", grpc::InsecureChannelCredentials()));

  grpc::Status s;
  std::vector<std::pair<std::string, std::string>> kvs;

  for (int i = 0; i < 1000000; i++){
      //sending the kv pairs to both primary and secondary server
      s = client1.Put(std::pair<std::string, std::string>("key" + std::to_string(i), "val" + std::to_string(i)));
      assert(s.ok());
      s = client2.Put(std::pair<std::string, std::string>("key" + std::to_string(i), "val" + std::to_string(i)));
      assert(s.ok());
  }
  
  std::vector<std::string> keys;
  for (int i =0; i < 10; i++){
    keys.emplace_back("key" + std::to_string(i));
  }

  std::vector<std::string> vals;
  s = client1.Get(keys, vals);

  return 0;
}