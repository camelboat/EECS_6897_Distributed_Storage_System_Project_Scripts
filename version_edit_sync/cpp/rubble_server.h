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
                                  int& num_of_added_files, int& added_file_num, int& batch_count){
      // std::cout << " ---------- calling ParseJsonStringToVersionEdit ----------- \n";

      std::cout << "Dumped Json VersionEdit : " << j.dump(4) << std::endl;

      if(!j["IsFlush"].is_null()){ // means edit corresponds to a flush job
        is_flush = true;
        // number of flushed memtable, needs to discard the corresponding ones in secondary
        num_of_added_files = j["AddedFiles"].get<std::vector<json>>().size();
        std::cout << " ----------- NumOutputFile : " << num_of_added_files << "--------------\n";
        auto added_file = j["AddedFiles"].get<std::vector<json>>().front();
        added_file_num = added_file["FileNumber"].get<uint64_t>();
        batch_count = j["BatchCount"].get<int>();
      }

      if(!j["LogNumber"].is_null()){
        edit->SetLogNumber(j["LogNumber"].get<uint64_t>());
        // std::cout << " LogNumber : " << j["LogNumber"].get<uint64_t>() << std::endl;
      }

      if(!j["PrevLogNumber"].is_null()){
        edit->SetPrevLogNumber(j["PrevLogNumber"].get<uint64_t>());
        // std::cout << " PrevLogNumver " << j["PrevLogNumber"].get<uint64_t>() << std::endl;
      }
      assert(!j["ColumnFamily"].is_null());
      edit->SetColumnFamily(j["ColumnFamily"].get<uint32_t>());

      for(auto j_added_file : j["AddedFiles"].get<std::vector<json>>()){
          // std::cout << " Added File : " << j_added_file << std::endl;
          assert(!j_added_file["SmallestUserKey"].is_null());
          assert(!j_added_file["SmallestSeqno"].is_null());
          rocksdb::InternalKey smallest(rocksdb::Slice(j_added_file["SmallestUserKey"].get<std::string>()), 
                                          j_added_file["SmallestSeqno"].get<uint64_t>(),rocksdb::ValueType::kTypeValue);

          assert(smallest.Valid());
          std::string* rep = smallest.rep();
          // std::cout << "Smallest InternalKey rep : " << rep << std::endl;

          uint64_t smallest_seqno = j_added_file["SmallestSeqno"].get<uint64_t>();
         
          // std::cout <<"Smallest IKey : " <<  smallest.DebugString(false) << std::endl;
          // std::cout << "Smallest Seqno : " << smallest_seqno << std::endl;

          assert(!j_added_file["LargestUserKey"].is_null());
          assert(!j_added_file["LargestSeqno"].is_null());
          rocksdb::InternalKey largest(rocksdb::Slice(j_added_file["LargestUserKey"].get<std::string>()), 
                                          j_added_file["LargestSeqno"].get<uint64_t>(),rocksdb::ValueType::kTypeValue);

          assert(largest.Valid());
          rep = largest.rep();
          // std::cout << "Largest InternalKey rep : " << rep << std::endl;

          uint64_t largest_seqno = j_added_file["LargestSeqno"].get<uint64_t>();

          // std::cout <<"Largest IKey : " <<  largest.DebugString(false) << std::endl;
          // std::cout << "Largest Seqno : " << largest_seqno << std::endl;

          edit->AddFile(j_added_file["Level"].get<int>(), j_added_file["FileNumber"].get<uint64_t>(), 0 /* path_id shoule be 0*/,
                      j_added_file["FileSize"].get<uint64_t>(), 
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

      if(!j["DeletedFiles"].is_null()){
        // std::cout << " DeletedFiles : " << j["DeletedFiles"].get<std::vector<json>>() << std::endl;
        for(auto j_delete_file : j["DeletedFiles"].get<std::vector<json>>()){
          edit->DeleteFile(j_delete_file["Level"].get<int>(), j_delete_file["FileNumber"].get<uint64_t>());
        }
      }

  }


  Status Sync(ServerContext* context, const SyncRequest* request, 
                          SyncReply* reply) override {
    log_apply_counter_++;
    std::cout << " --------[Secondary] Accepting VersionEditSync PRC " << log_apply_counter_.load() << " th times --------- \n";
    rocksdb::VersionEdit edit;
    /**
     * example args json: 
     * {
     *  "VersionEdit" : {
     *        "AddedFiles": [
     *             {
     *                "FileNumber": 12,
     *                "FileSize": 71819,
     *                "LargestIKey": "'key7172' seq:7173, type:1",
     *                "LargestSeqno": 7173,
     *                "LargestUserKey": "key7172",
     *                "Level": 0,
     *                "SmallestIKey": "'key3606' seq:3607, type:1",
     *                "SmallestSeqno": 3607,
     *                "SmallestUserKey": "key3606"
     *             }
     *         ],
     *         "ColumnFamily": 0,
     *         "DeletedFiles": [
     *             {
     *                 "FileNumber": 8,
     *                 "Level": 0
     *             },
     *             {
     *                 "FileNumber": 12,
     *                 "Level": 0
     *             }
     *          ],
     *         "EditNumber": 2,
     *         "LogNumber": 11,
     *         "PrevLogNumber": 0,
     *    
     *          // fields exist only when it's triggered by a flush
     *         "IsFlush" : 1,
     *         "BatchCount" : 2
     *      },
     *    "ImmutableMemlistSize" : 2
     *  }
     */ 
    
    bool is_flush = false; 
    // number of added sst file
    int num_of_added_files = 0;
    int added_file_num = 0;
    // number of memtables get flushed in a flush job
    int batch_count = 0;

    std::string args = request->args();

    json j_args = json::parse(args);
    ParseJsonStringToVersionEdit(j_args["VersionEdit"].get<json>(), &edit, is_flush, num_of_added_files, added_file_num, batch_count);
    // size of Immutable memtable list of the priamry
    assert(!j_args["ImmutableMemlistSize"].is_null());
    int immutable_memlist_size = j_args["ImmutablMemlistSize"].get<int>();
    rocksdb::Status s;
    rocksdb::DBImpl* impl_ = (rocksdb::DBImpl*)db_;
    
    rocksdb::InstrumentedMutex* mu = impl_->mutex();
    rocksdb::InstrumentedMutexLock l(mu);

    rocksdb::VersionSet* version_set = impl_->TEST_GetVersionSet();
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
    // assert the size of immutable memtable list of the priamry and secondary is equal
    assert(imm->current()->GetMemlist().size() == immutable_memlist_size);
    // std::cout << "MemTable : " <<  json::parse(default_cf->mem()->DebugJson()).dump(4) << std::endl;
    std::cout  << json::parse(imm->DebugJson()).dump(4) << std::endl;
    std::cout << " Current Version :\n " << default_cf->current()->DebugString(false) <<std::endl;

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

            assert(m->GetFileNumber() > 0);
            while(batch_count-- > 0){
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
      std::cout << " memlist size : " << size << " , num_flush_not_started : " << imm->GetNumFlushNotStarted() << std::endl;
    }else { // It is either a trivial move compaction or a full compaction

    }

    if(s.ok()){
      reply->set_message(" Succeeds");
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