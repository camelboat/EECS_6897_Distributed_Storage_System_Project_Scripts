#include "kv_store_client.h"

int main(){

// sending kv to ptimary
  RubbleClient client1(grpc::CreateChannel(
    "localhost:50051", grpc::InsecureChannelCredentials()), true);
// sending kv to the secondary
  RubbleClient client2(grpc::CreateChannel(
    "localhost:50050", grpc::InsecureChannelCredentials()), false);

  grpc::Status s;
  std::vector<std::pair<std::string, std::string>> kvs;

  for (int i = 0; i < 50000; i++){
      //sending the kv pairs to both primary and secondary server
      s = client1.Put(std::pair<std::string, std::string>("key" + std::to_string(i), "val" + std::to_string(i)));
      assert(s.ok());
      s = client2.Put(std::pair<std::string, std::string>("key" + std::to_string(i), "val" + std::to_string(i)));
      assert(s.ok());
  }
  
  std::vector<std::string> keys;
  for(int i = 0; i <50000; i++){
    keys.emplace_back("key" + std::to_string(i));
  }

  std::vector<std::string> vals;
  client1.Get(keys, vals);
  for(int i = 0 ; i < vals.size(); i++){
    assert(vals[i] == ("val" + std::to_string(i)));
  }
  vals.erase(vals.begin(), vals.end());
  client2.Get(keys, vals);
  for(int i = 0 ; i < vals.size(); i++){
    assert(vals[i] == ("val" + std::to_string(i)));
  }


  return 0;
}