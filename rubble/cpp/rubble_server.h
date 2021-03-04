#pragma once

#include <iostream>
#include <string>
#include <sstream>   
#include <memory>
#include <typeinfo> 
#include <nlohmann/json.hpp>

#include <grpcpp/grpcpp.h>
#include <grpcpp/health_check_service_interface.h>
#include <grpcpp/ext/proto_server_reflection_plugin.h>
#include "rubble_kv_store.grpc.pb.h"

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

using rubble::RubbleKvStoreService;
using rubble::SyncRequest;
using rubble::SyncReply;

using rubble::GetReply;
using rubble::GetRequest;
using rubble::PutReply;
using rubble::PutRequest;

using json = nlohmann::json;

class RubbleKvServiceImpl final : public RubbleKvStoreService::Service {
  public:
    explicit RubbleKvServiceImpl(rocksdb::DB* db)
      :db_(db),put_count_(0),log_apply_counter_(0){};

      RubbleKvServiceImpl(rocksdb::DB* db, bool is_primary)
      :db_(db),put_count_(0),log_apply_counter_(0), is_primary_(is_primary){};
    
    ~RubbleKvServiceImpl(){
      delete db_;
    }

  void ParseJsonStringToVersionEdit(const json& j /* json version edit */, rocksdb::VersionEdit* edit, bool& is_flush, 
                                  int& num_of_added_files, int& added_file_num, int& batch_count, int& next_file_num){

      std::cout << "Dumped VersionEdit : " << j.dump(4) << std::endl;

      assert(j.contains("AddedFiles"));
      if(j.contains("IsFlush")){ // means edit corresponds to a flush job
        is_flush = true;
        num_of_added_files = j["AddedFiles"].get<std::vector<json>>().size();
        auto added_file = j["AddedFiles"].get<std::vector<json>>().front();
        added_file_num = added_file["FileNumber"].get<uint64_t>();
        batch_count = j["BatchCount"].get<int>();
      }

      if(j.contains("LogNumber")){
        edit->SetLogNumber(j["LogNumber"].get<uint64_t>());
      }

      if(j.contains("PrevLogNumber")){
        edit->SetPrevLogNumber(j["PrevLogNumber"].get<uint64_t>());
      }
      assert(!j["ColumnFamily"].is_null());
      edit->SetColumnFamily(j["ColumnFamily"].get<uint32_t>());

      int max_file_num = 0;
     
      for(auto& j_added_file : j["AddedFiles"].get<std::vector<json>>()){
          
          assert(!j_added_file["SmallestUserKey"].is_null());
          assert(!j_added_file["SmallestSeqno"].is_null());
          rocksdb::InternalKey smallest(rocksdb::Slice(j_added_file["SmallestUserKey"].get<std::string>()), 
                                          j_added_file["SmallestSeqno"].get<uint64_t>(),rocksdb::ValueType::kTypeValue);

          assert(smallest.Valid());
          std::string* rep = smallest.rep();

          uint64_t smallest_seqno = j_added_file["SmallestSeqno"].get<uint64_t>();
         
          assert(!j_added_file["LargestUserKey"].is_null());
          assert(!j_added_file["LargestSeqno"].is_null());
          rocksdb::InternalKey largest(rocksdb::Slice(j_added_file["LargestUserKey"].get<std::string>()), 
                                          j_added_file["LargestSeqno"].get<uint64_t>(),rocksdb::ValueType::kTypeValue);

          assert(largest.Valid());
          rep = largest.rep();

          uint64_t largest_seqno = j_added_file["LargestSeqno"].get<uint64_t>();


          int level = j_added_file["Level"].get<int>();

          uint64_t file_num = j_added_file["FileNumber"].get<uint64_t>();
          max_file_num = std::max(max_file_num, (int)file_num);

          uint64_t file_size = j_added_file["FileSize"].get<uint64_t>();

          edit->AddFile(level, file_num, 0 /* path_id shoule be 0*/,
                      file_size, 
                      smallest, largest, 
                      smallest_seqno, largest_seqno,
                      false, 
                      rocksdb::kInvalidBlobFileNumber,
                      rocksdb::kUnknownOldestAncesterTime,
                      rocksdb::kUnknownFileCreationTime,
                      rocksdb::kUnknownFileChecksum, 
                      rocksdb::kUnknownFileChecksumFuncName
                      );
      }
      next_file_num = max_file_num + 1;

      if(j.contains("DeletedFiles")){
        for(auto j_delete_file : j["DeletedFiles"].get<std::vector<json>>()){
          edit->DeleteFile(j_delete_file["Level"].get<int>(), j_delete_file["FileNumber"].get<uint64_t>());
        }
      }
  }


  Status Sync(ServerContext* context, const SyncRequest* request, 
                          SyncReply* reply) override {
    log_apply_counter_++;
    std::cout << " --------[Secondary] Accepting Sync PRC " << log_apply_counter_.load() << " th times --------- \n";
    rocksdb::VersionEdit edit;
    /**
     * example args json: 
     * 
     *  {
     *     "AddedFiles": [
     *          {
     *             "FileNumber": 12,
     *             "FileSize": 71819,
     *             "LargestSeqno": 7173,
     *             "LargestUserKey": "key7172",
     *             "Level": 0,
     *             "SmallestSeqno": 3607,
     *             "SmallestUserKey": "key3606"
     *          }
     *      ],
     *      "ColumnFamily": 0,
     *      "DeletedFiles": [
     *          {
     *              "FileNumber": 8,
     *              "Level": 0
     *          },
     *          {
     *              "FileNumber": 12,
     *              "Level": 0
     *          }
     *       ],
     *      "EditNumber": 2,
     *      "LogNumber": 11,
     *      "PrevLogNumber": 0,
     * 
     *       // fields exist only when it's triggered by a flush
     *      "IsFlush" : 1,
     *      "BatchCount" : 2
     *  }
     *  
     */ 
    
    // if true, means this version edit indicates a flush job
    bool is_flush = false; 
    // number of added sst files
    int num_of_added_files = 0;
    int added_file_num = 0;
    // number of memtables get flushed in a flush job, looks like is always 2
    int batch_count = 0;
    // get the next file num of secondary, which is the maximum file number of the AddedFiles in the shipped vesion edit plus 1
    int next_file_num = 0;
    // number of immutable memtable in the list to drop
    int num_of_imm_to_delete = 0;

    std::string args = request->args();
    const json j_args = json::parse(args);
     
    ParseJsonStringToVersionEdit(j_args, &edit, is_flush, num_of_added_files, added_file_num, batch_count, next_file_num);

    rocksdb::Status s;
    rocksdb::DBImpl* impl_ = (rocksdb::DBImpl*)db_;
    
    rocksdb::InstrumentedMutex* mu = impl_->mutex();
    rocksdb::InstrumentedMutexLock l(mu);

    rocksdb::VersionSet* version_set = impl_->TEST_GetVersionSet();
    uint64_t current_next_file_num = version_set->current_next_file_number();
    
    rocksdb::ColumnFamilyData* default_cf = version_set->GetColumnFamilySet()->GetDefault();
    const rocksdb::MutableCFOptions* cf_options = default_cf->GetCurrentMutableCFOptions();

    rocksdb::autovector<rocksdb::ColumnFamilyData*> cfds;
    cfds.emplace_back(default_cf);

    rocksdb::autovector<const rocksdb::MutableCFOptions*> mutable_cf_options_list;
    mutable_cf_options_list.emplace_back(cf_options);

    rocksdb::autovector<rocksdb::VersionEdit*> edit_list;
    edit_list.emplace_back(&edit);

    rocksdb::autovector<rocksdb::autovector<rocksdb::VersionEdit*>> edit_lists;
    edit_lists.emplace_back(edit_list);

    rocksdb::FSDirectory* db_directory = impl_->directories_.GetDbDir();
    
    rocksdb::MemTableList* imm = default_cf->imm();
    
    // std::cout << "MemTable : " <<  json::parse(default_cf->mem()->DebugJson()).dump(4) << std::endl;
    std::cout  << "Immutable MemTable list : " << json::parse(imm->DebugJson()).dump(4) << std::endl;
    std::cout << " Current Version :\n " << default_cf->current()->DebugString(false) <<std::endl;

    // set secondary version set's next file num according to the primary's next_file_num_
    version_set->FetchAddFileNumber(next_file_num - current_next_file_num);
    assert(version_set->current_next_file_number() == next_file_num);

    // Calling LogAndApply on the secondary
    s = version_set->LogAndApply(cfds, mutable_cf_options_list, edit_lists, mu,
                      db_directory);


    //Drop The corresponding MemTables in the Immutable MemTable List
    //If this version edit corresponds to a flush job
    if(is_flush){
      //flush always output one file?
      assert(num_of_added_files == 1);
      // batch count is always 2 ?
      assert(batch_count == 2);
      // creating a new verion after we applied the edit
      imm->InstallNewVersion();

      // All the later memtables that have the same filenum
      // are part of the same batch. They can be committed now.
      uint64_t mem_id = 1;  // how many memtables have been flushed.
      
      rocksdb::autovector<rocksdb::MemTable*> to_delete;
      if(s.ok() &&!default_cf->IsDropped()){

        while(num_of_added_files-- > 0){
            rocksdb::SuperVersion* sv = default_cf->GetSuperVersion();
          
            rocksdb::MemTableListVersion*  current = imm->current();
            rocksdb::MemTable* m = current->GetMemlist().back();

            m->SetFlushCompleted(true);
            m->SetFileNumber(added_file_num); 

            // if (m->GetEdits().GetBlobFileAdditions().empty()) {
            //   ROCKS_LOG_BUFFER(log_buffer,
            //                   "[%s] Level-0 commit table #%" PRIu64
            //                   ": memtable #%" PRIu64 " done",
            //                   cfd->GetName().c_str(), m->file_number_, mem_id);
            // } else {
            //   ROCKS_LOG_BUFFER(log_buffer,
            //                   "[%s] Level-0 commit table #%" PRIu64
            //                   " (+%zu blob files)"
            //                   ": memtable #%" PRIu64 " done",
            //                   cfd->GetName().c_str(), m->file_number_,
            //                   m->edit_.GetBlobFileAdditions().size(), mem_id);
            // }

            // assert(imm->current()->GetMemlist().size() >= batch_count) ? 
            // This is not always the case, sometimes secondary has only one immutable memtable in the list, say ID 89,
            // while the primary has 2 immutable memtables, say 89 and 90, with a more latest one,
            // so should set the number_of_immutable_memtable_to_delete to be the minimum of batch count and immutable memlist size
            num_of_imm_to_delete = std::min(batch_count, (int)imm->current()->GetMemlist().size());

            assert(m->GetFileNumber() > 0);
            while(num_of_imm_to_delete-- > 0){
              /* drop the corresponding immutable memtable in the list if version edit corresponds to a flush */
              // according the code comment in the MemTableList class : "The memtables are flushed to L0 as soon as possible and in any order." 
              // as far as I observe, it's always the back of the imm memlist gets flushed first, which is the earliest memtable
              // so here we always drop the memtable in the back of the list
              current->RemoveLast(sv->GetToDelete());
            }

            imm->SetNumFlushNotStarted(current->GetMemlist().size());
            imm->UpdateCachedValuesFromMemTableListVersion();
            imm->ResetTrimHistoryNeeded();
            ++mem_id;
        }
      }else {
        //TODO : Commit Failed For Some reason, need to reset state
        std::cout << s.ToString() << std::endl;
      }

      imm->SetCommitInProgress(false);
      std::cout << " ----------- After RemoveLast : ( ImmutableList : " << json::parse(imm->DebugJson()).dump(4) << " ) ----------------\n";
      int size = static_cast<int> (imm->current()->GetMemlist().size());
      // std::cout << " memlist size : " << size << " , num_flush_not_started : " << imm->GetNumFlushNotStarted() << std::endl;
    }else { // It is either a trivial move compaction or a full compaction

    }

    if(s.ok()){
      reply->set_message("Succeeds");
    }else{
      std::string failed = "Failed : " + s.ToString();
      reply->set_message(failed);
    }

    rocksdb::VersionStorageInfo::LevelSummaryStorage tmp;

    auto vstorage = default_cf->current()->storage_info();
    const char* c = vstorage->LevelSummary(&tmp);

    std::cout << " VersionStorageInfo->LevelSummary : " << std::string(c) << std::endl;

    return Status::OK;
  }

  // return the key range of entire db(memtables and ssts)
  void GetDbKeyRange(){

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

        rocksdb::Status s = db_->Put(rocksdb::WriteOptions(), key, value);

        if(put_count_%10000 == 0){
          // std::cout << "caliing put : (" << key << "," << value <<")\n";  
          if(is_primary_){
            std::cout << "Primary -> Put ( " << key << ", " << value << " ), Status : "; 
          }else{
            std::cout << "Secondary -> Put ( " << key << ", " << value << " ), Status : "; 
          }
          std::cout <<  s.ToString() << std::endl;
        }

        // std::cout << "Put " << put_count_ << " status: " << s.ToString() << std::endl;
        if (s.ok()){
            reply.set_ok(true);
        }else{
            reply.set_ok(false);
            reply.set_status(s.ToString());
        }

        stream->Write(reply);
     }
     return Status::OK;
    }

  private:
    rocksdb::DB* db_ = nullptr;
    std::atomic<uint64_t> put_count_;
    std::atomic<uint64_t> log_apply_counter_;
    bool is_primary_ = false;
};

void RunServer(rocksdb::DB* db, const std::string server_addr, bool is_primary = false) {
  
  std::string server_address(server_addr);
  RubbleKvServiceImpl service(db, is_primary);

  grpc::EnableDefaultHealthCheckService(true);
  grpc::reflection::InitProtoReflectionServerBuilderPlugin();
  ServerBuilder builder;

  builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
  builder.RegisterService(&service);
  std::unique_ptr<Server> server(builder.BuildAndStart());
  std::cout << "Server listening on " << server_address << std::endl;
  server->Wait();
}