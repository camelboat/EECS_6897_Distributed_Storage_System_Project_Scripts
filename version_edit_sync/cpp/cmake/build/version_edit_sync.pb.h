// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: version_edit_sync.proto

#ifndef GOOGLE_PROTOBUF_INCLUDED_version_5fedit_5fsync_2eproto
#define GOOGLE_PROTOBUF_INCLUDED_version_5fedit_5fsync_2eproto

#include <limits>
#include <string>

#include <google/protobuf/port_def.inc>
#if PROTOBUF_VERSION < 3013000
#error This file was generated by a newer version of protoc which is
#error incompatible with your Protocol Buffer headers. Please update
#error your headers.
#endif
#if 3013000 < PROTOBUF_MIN_PROTOC_VERSION
#error This file was generated by an older version of protoc which is
#error incompatible with your Protocol Buffer headers. Please
#error regenerate this file with a newer version of protoc.
#endif

#include <google/protobuf/port_undef.inc>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/arena.h>
#include <google/protobuf/arenastring.h>
#include <google/protobuf/generated_message_table_driven.h>
#include <google/protobuf/generated_message_util.h>
#include <google/protobuf/inlined_string_field.h>
#include <google/protobuf/metadata_lite.h>
#include <google/protobuf/generated_message_reflection.h>
#include <google/protobuf/message.h>
#include <google/protobuf/repeated_field.h>  // IWYU pragma: export
#include <google/protobuf/extension_set.h>  // IWYU pragma: export
#include <google/protobuf/unknown_field_set.h>
// @@protoc_insertion_point(includes)
#include <google/protobuf/port_def.inc>
#define PROTOBUF_INTERNAL_EXPORT_version_5fedit_5fsync_2eproto
PROTOBUF_NAMESPACE_OPEN
namespace internal {
class AnyMetadata;
}  // namespace internal
PROTOBUF_NAMESPACE_CLOSE

// Internal implementation detail -- do not use these members.
struct TableStruct_version_5fedit_5fsync_2eproto {
  static const ::PROTOBUF_NAMESPACE_ID::internal::ParseTableField entries[]
    PROTOBUF_SECTION_VARIABLE(protodesc_cold);
  static const ::PROTOBUF_NAMESPACE_ID::internal::AuxiliaryParseTableField aux[]
    PROTOBUF_SECTION_VARIABLE(protodesc_cold);
  static const ::PROTOBUF_NAMESPACE_ID::internal::ParseTable schema[2]
    PROTOBUF_SECTION_VARIABLE(protodesc_cold);
  static const ::PROTOBUF_NAMESPACE_ID::internal::FieldMetadata field_metadata[];
  static const ::PROTOBUF_NAMESPACE_ID::internal::SerializationTable serialization_table[];
  static const ::PROTOBUF_NAMESPACE_ID::uint32 offsets[];
};
extern const ::PROTOBUF_NAMESPACE_ID::internal::DescriptorTable descriptor_table_version_5fedit_5fsync_2eproto;
namespace version_edit_sync {
class VersionEditSyncReply;
class VersionEditSyncReplyDefaultTypeInternal;
extern VersionEditSyncReplyDefaultTypeInternal _VersionEditSyncReply_default_instance_;
class VersionEditSyncRequest;
class VersionEditSyncRequestDefaultTypeInternal;
extern VersionEditSyncRequestDefaultTypeInternal _VersionEditSyncRequest_default_instance_;
}  // namespace version_edit_sync
PROTOBUF_NAMESPACE_OPEN
template<> ::version_edit_sync::VersionEditSyncReply* Arena::CreateMaybeMessage<::version_edit_sync::VersionEditSyncReply>(Arena*);
template<> ::version_edit_sync::VersionEditSyncRequest* Arena::CreateMaybeMessage<::version_edit_sync::VersionEditSyncRequest>(Arena*);
PROTOBUF_NAMESPACE_CLOSE
namespace version_edit_sync {

// ===================================================================

class VersionEditSyncRequest PROTOBUF_FINAL :
    public ::PROTOBUF_NAMESPACE_ID::Message /* @@protoc_insertion_point(class_definition:version_edit_sync.VersionEditSyncRequest) */ {
 public:
  inline VersionEditSyncRequest() : VersionEditSyncRequest(nullptr) {}
  virtual ~VersionEditSyncRequest();

  VersionEditSyncRequest(const VersionEditSyncRequest& from);
  VersionEditSyncRequest(VersionEditSyncRequest&& from) noexcept
    : VersionEditSyncRequest() {
    *this = ::std::move(from);
  }

  inline VersionEditSyncRequest& operator=(const VersionEditSyncRequest& from) {
    CopyFrom(from);
    return *this;
  }
  inline VersionEditSyncRequest& operator=(VersionEditSyncRequest&& from) noexcept {
    if (GetArena() == from.GetArena()) {
      if (this != &from) InternalSwap(&from);
    } else {
      CopyFrom(from);
    }
    return *this;
  }

  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* descriptor() {
    return GetDescriptor();
  }
  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* GetDescriptor() {
    return GetMetadataStatic().descriptor;
  }
  static const ::PROTOBUF_NAMESPACE_ID::Reflection* GetReflection() {
    return GetMetadataStatic().reflection;
  }
  static const VersionEditSyncRequest& default_instance();

  static void InitAsDefaultInstance();  // FOR INTERNAL USE ONLY
  static inline const VersionEditSyncRequest* internal_default_instance() {
    return reinterpret_cast<const VersionEditSyncRequest*>(
               &_VersionEditSyncRequest_default_instance_);
  }
  static constexpr int kIndexInFileMessages =
    0;

  friend void swap(VersionEditSyncRequest& a, VersionEditSyncRequest& b) {
    a.Swap(&b);
  }
  inline void Swap(VersionEditSyncRequest* other) {
    if (other == this) return;
    if (GetArena() == other->GetArena()) {
      InternalSwap(other);
    } else {
      ::PROTOBUF_NAMESPACE_ID::internal::GenericSwap(this, other);
    }
  }
  void UnsafeArenaSwap(VersionEditSyncRequest* other) {
    if (other == this) return;
    GOOGLE_DCHECK(GetArena() == other->GetArena());
    InternalSwap(other);
  }

  // implements Message ----------------------------------------------

  inline VersionEditSyncRequest* New() const final {
    return CreateMaybeMessage<VersionEditSyncRequest>(nullptr);
  }

  VersionEditSyncRequest* New(::PROTOBUF_NAMESPACE_ID::Arena* arena) const final {
    return CreateMaybeMessage<VersionEditSyncRequest>(arena);
  }
  void CopyFrom(const ::PROTOBUF_NAMESPACE_ID::Message& from) final;
  void MergeFrom(const ::PROTOBUF_NAMESPACE_ID::Message& from) final;
  void CopyFrom(const VersionEditSyncRequest& from);
  void MergeFrom(const VersionEditSyncRequest& from);
  PROTOBUF_ATTRIBUTE_REINITIALIZES void Clear() final;
  bool IsInitialized() const final;

  size_t ByteSizeLong() const final;
  const char* _InternalParse(const char* ptr, ::PROTOBUF_NAMESPACE_ID::internal::ParseContext* ctx) final;
  ::PROTOBUF_NAMESPACE_ID::uint8* _InternalSerialize(
      ::PROTOBUF_NAMESPACE_ID::uint8* target, ::PROTOBUF_NAMESPACE_ID::io::EpsCopyOutputStream* stream) const final;
  int GetCachedSize() const final { return _cached_size_.Get(); }

  private:
  inline void SharedCtor();
  inline void SharedDtor();
  void SetCachedSize(int size) const final;
  void InternalSwap(VersionEditSyncRequest* other);
  friend class ::PROTOBUF_NAMESPACE_ID::internal::AnyMetadata;
  static ::PROTOBUF_NAMESPACE_ID::StringPiece FullMessageName() {
    return "version_edit_sync.VersionEditSyncRequest";
  }
  protected:
  explicit VersionEditSyncRequest(::PROTOBUF_NAMESPACE_ID::Arena* arena);
  private:
  static void ArenaDtor(void* object);
  inline void RegisterArenaDtor(::PROTOBUF_NAMESPACE_ID::Arena* arena);
  public:

  ::PROTOBUF_NAMESPACE_ID::Metadata GetMetadata() const final;
  private:
  static ::PROTOBUF_NAMESPACE_ID::Metadata GetMetadataStatic() {
    ::PROTOBUF_NAMESPACE_ID::internal::AssignDescriptors(&::descriptor_table_version_5fedit_5fsync_2eproto);
    return ::descriptor_table_version_5fedit_5fsync_2eproto.file_level_metadata[kIndexInFileMessages];
  }

  public:

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  enum : int {
    kRecordFieldNumber = 1,
  };
  // string record = 1;
  void clear_record();
  const std::string& record() const;
  void set_record(const std::string& value);
  void set_record(std::string&& value);
  void set_record(const char* value);
  void set_record(const char* value, size_t size);
  std::string* mutable_record();
  std::string* release_record();
  void set_allocated_record(std::string* record);
  private:
  const std::string& _internal_record() const;
  void _internal_set_record(const std::string& value);
  std::string* _internal_mutable_record();
  public:

  // @@protoc_insertion_point(class_scope:version_edit_sync.VersionEditSyncRequest)
 private:
  class _Internal;

  template <typename T> friend class ::PROTOBUF_NAMESPACE_ID::Arena::InternalHelper;
  typedef void InternalArenaConstructable_;
  typedef void DestructorSkippable_;
  ::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr record_;
  mutable ::PROTOBUF_NAMESPACE_ID::internal::CachedSize _cached_size_;
  friend struct ::TableStruct_version_5fedit_5fsync_2eproto;
};
// -------------------------------------------------------------------

class VersionEditSyncReply PROTOBUF_FINAL :
    public ::PROTOBUF_NAMESPACE_ID::Message /* @@protoc_insertion_point(class_definition:version_edit_sync.VersionEditSyncReply) */ {
 public:
  inline VersionEditSyncReply() : VersionEditSyncReply(nullptr) {}
  virtual ~VersionEditSyncReply();

  VersionEditSyncReply(const VersionEditSyncReply& from);
  VersionEditSyncReply(VersionEditSyncReply&& from) noexcept
    : VersionEditSyncReply() {
    *this = ::std::move(from);
  }

  inline VersionEditSyncReply& operator=(const VersionEditSyncReply& from) {
    CopyFrom(from);
    return *this;
  }
  inline VersionEditSyncReply& operator=(VersionEditSyncReply&& from) noexcept {
    if (GetArena() == from.GetArena()) {
      if (this != &from) InternalSwap(&from);
    } else {
      CopyFrom(from);
    }
    return *this;
  }

  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* descriptor() {
    return GetDescriptor();
  }
  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* GetDescriptor() {
    return GetMetadataStatic().descriptor;
  }
  static const ::PROTOBUF_NAMESPACE_ID::Reflection* GetReflection() {
    return GetMetadataStatic().reflection;
  }
  static const VersionEditSyncReply& default_instance();

  static void InitAsDefaultInstance();  // FOR INTERNAL USE ONLY
  static inline const VersionEditSyncReply* internal_default_instance() {
    return reinterpret_cast<const VersionEditSyncReply*>(
               &_VersionEditSyncReply_default_instance_);
  }
  static constexpr int kIndexInFileMessages =
    1;

  friend void swap(VersionEditSyncReply& a, VersionEditSyncReply& b) {
    a.Swap(&b);
  }
  inline void Swap(VersionEditSyncReply* other) {
    if (other == this) return;
    if (GetArena() == other->GetArena()) {
      InternalSwap(other);
    } else {
      ::PROTOBUF_NAMESPACE_ID::internal::GenericSwap(this, other);
    }
  }
  void UnsafeArenaSwap(VersionEditSyncReply* other) {
    if (other == this) return;
    GOOGLE_DCHECK(GetArena() == other->GetArena());
    InternalSwap(other);
  }

  // implements Message ----------------------------------------------

  inline VersionEditSyncReply* New() const final {
    return CreateMaybeMessage<VersionEditSyncReply>(nullptr);
  }

  VersionEditSyncReply* New(::PROTOBUF_NAMESPACE_ID::Arena* arena) const final {
    return CreateMaybeMessage<VersionEditSyncReply>(arena);
  }
  void CopyFrom(const ::PROTOBUF_NAMESPACE_ID::Message& from) final;
  void MergeFrom(const ::PROTOBUF_NAMESPACE_ID::Message& from) final;
  void CopyFrom(const VersionEditSyncReply& from);
  void MergeFrom(const VersionEditSyncReply& from);
  PROTOBUF_ATTRIBUTE_REINITIALIZES void Clear() final;
  bool IsInitialized() const final;

  size_t ByteSizeLong() const final;
  const char* _InternalParse(const char* ptr, ::PROTOBUF_NAMESPACE_ID::internal::ParseContext* ctx) final;
  ::PROTOBUF_NAMESPACE_ID::uint8* _InternalSerialize(
      ::PROTOBUF_NAMESPACE_ID::uint8* target, ::PROTOBUF_NAMESPACE_ID::io::EpsCopyOutputStream* stream) const final;
  int GetCachedSize() const final { return _cached_size_.Get(); }

  private:
  inline void SharedCtor();
  inline void SharedDtor();
  void SetCachedSize(int size) const final;
  void InternalSwap(VersionEditSyncReply* other);
  friend class ::PROTOBUF_NAMESPACE_ID::internal::AnyMetadata;
  static ::PROTOBUF_NAMESPACE_ID::StringPiece FullMessageName() {
    return "version_edit_sync.VersionEditSyncReply";
  }
  protected:
  explicit VersionEditSyncReply(::PROTOBUF_NAMESPACE_ID::Arena* arena);
  private:
  static void ArenaDtor(void* object);
  inline void RegisterArenaDtor(::PROTOBUF_NAMESPACE_ID::Arena* arena);
  public:

  ::PROTOBUF_NAMESPACE_ID::Metadata GetMetadata() const final;
  private:
  static ::PROTOBUF_NAMESPACE_ID::Metadata GetMetadataStatic() {
    ::PROTOBUF_NAMESPACE_ID::internal::AssignDescriptors(&::descriptor_table_version_5fedit_5fsync_2eproto);
    return ::descriptor_table_version_5fedit_5fsync_2eproto.file_level_metadata[kIndexInFileMessages];
  }

  public:

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  enum : int {
    kMessageFieldNumber = 1,
  };
  // string message = 1;
  void clear_message();
  const std::string& message() const;
  void set_message(const std::string& value);
  void set_message(std::string&& value);
  void set_message(const char* value);
  void set_message(const char* value, size_t size);
  std::string* mutable_message();
  std::string* release_message();
  void set_allocated_message(std::string* message);
  private:
  const std::string& _internal_message() const;
  void _internal_set_message(const std::string& value);
  std::string* _internal_mutable_message();
  public:

  // @@protoc_insertion_point(class_scope:version_edit_sync.VersionEditSyncReply)
 private:
  class _Internal;

  template <typename T> friend class ::PROTOBUF_NAMESPACE_ID::Arena::InternalHelper;
  typedef void InternalArenaConstructable_;
  typedef void DestructorSkippable_;
  ::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr message_;
  mutable ::PROTOBUF_NAMESPACE_ID::internal::CachedSize _cached_size_;
  friend struct ::TableStruct_version_5fedit_5fsync_2eproto;
};
// ===================================================================


// ===================================================================

#ifdef __GNUC__
  #pragma GCC diagnostic push
  #pragma GCC diagnostic ignored "-Wstrict-aliasing"
#endif  // __GNUC__
// VersionEditSyncRequest

// string record = 1;
inline void VersionEditSyncRequest::clear_record() {
  record_.ClearToEmpty(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), GetArena());
}
inline const std::string& VersionEditSyncRequest::record() const {
  // @@protoc_insertion_point(field_get:version_edit_sync.VersionEditSyncRequest.record)
  return _internal_record();
}
inline void VersionEditSyncRequest::set_record(const std::string& value) {
  _internal_set_record(value);
  // @@protoc_insertion_point(field_set:version_edit_sync.VersionEditSyncRequest.record)
}
inline std::string* VersionEditSyncRequest::mutable_record() {
  // @@protoc_insertion_point(field_mutable:version_edit_sync.VersionEditSyncRequest.record)
  return _internal_mutable_record();
}
inline const std::string& VersionEditSyncRequest::_internal_record() const {
  return record_.Get();
}
inline void VersionEditSyncRequest::_internal_set_record(const std::string& value) {
  
  record_.Set(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), value, GetArena());
}
inline void VersionEditSyncRequest::set_record(std::string&& value) {
  
  record_.Set(
    &::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), ::std::move(value), GetArena());
  // @@protoc_insertion_point(field_set_rvalue:version_edit_sync.VersionEditSyncRequest.record)
}
inline void VersionEditSyncRequest::set_record(const char* value) {
  GOOGLE_DCHECK(value != nullptr);
  
  record_.Set(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), ::std::string(value),
              GetArena());
  // @@protoc_insertion_point(field_set_char:version_edit_sync.VersionEditSyncRequest.record)
}
inline void VersionEditSyncRequest::set_record(const char* value,
    size_t size) {
  
  record_.Set(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), ::std::string(
      reinterpret_cast<const char*>(value), size), GetArena());
  // @@protoc_insertion_point(field_set_pointer:version_edit_sync.VersionEditSyncRequest.record)
}
inline std::string* VersionEditSyncRequest::_internal_mutable_record() {
  
  return record_.Mutable(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), GetArena());
}
inline std::string* VersionEditSyncRequest::release_record() {
  // @@protoc_insertion_point(field_release:version_edit_sync.VersionEditSyncRequest.record)
  return record_.Release(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), GetArena());
}
inline void VersionEditSyncRequest::set_allocated_record(std::string* record) {
  if (record != nullptr) {
    
  } else {
    
  }
  record_.SetAllocated(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), record,
      GetArena());
  // @@protoc_insertion_point(field_set_allocated:version_edit_sync.VersionEditSyncRequest.record)
}

// -------------------------------------------------------------------

// VersionEditSyncReply

// string message = 1;
inline void VersionEditSyncReply::clear_message() {
  message_.ClearToEmpty(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), GetArena());
}
inline const std::string& VersionEditSyncReply::message() const {
  // @@protoc_insertion_point(field_get:version_edit_sync.VersionEditSyncReply.message)
  return _internal_message();
}
inline void VersionEditSyncReply::set_message(const std::string& value) {
  _internal_set_message(value);
  // @@protoc_insertion_point(field_set:version_edit_sync.VersionEditSyncReply.message)
}
inline std::string* VersionEditSyncReply::mutable_message() {
  // @@protoc_insertion_point(field_mutable:version_edit_sync.VersionEditSyncReply.message)
  return _internal_mutable_message();
}
inline const std::string& VersionEditSyncReply::_internal_message() const {
  return message_.Get();
}
inline void VersionEditSyncReply::_internal_set_message(const std::string& value) {
  
  message_.Set(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), value, GetArena());
}
inline void VersionEditSyncReply::set_message(std::string&& value) {
  
  message_.Set(
    &::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), ::std::move(value), GetArena());
  // @@protoc_insertion_point(field_set_rvalue:version_edit_sync.VersionEditSyncReply.message)
}
inline void VersionEditSyncReply::set_message(const char* value) {
  GOOGLE_DCHECK(value != nullptr);
  
  message_.Set(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), ::std::string(value),
              GetArena());
  // @@protoc_insertion_point(field_set_char:version_edit_sync.VersionEditSyncReply.message)
}
inline void VersionEditSyncReply::set_message(const char* value,
    size_t size) {
  
  message_.Set(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), ::std::string(
      reinterpret_cast<const char*>(value), size), GetArena());
  // @@protoc_insertion_point(field_set_pointer:version_edit_sync.VersionEditSyncReply.message)
}
inline std::string* VersionEditSyncReply::_internal_mutable_message() {
  
  return message_.Mutable(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), GetArena());
}
inline std::string* VersionEditSyncReply::release_message() {
  // @@protoc_insertion_point(field_release:version_edit_sync.VersionEditSyncReply.message)
  return message_.Release(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), GetArena());
}
inline void VersionEditSyncReply::set_allocated_message(std::string* message) {
  if (message != nullptr) {
    
  } else {
    
  }
  message_.SetAllocated(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), message,
      GetArena());
  // @@protoc_insertion_point(field_set_allocated:version_edit_sync.VersionEditSyncReply.message)
}

#ifdef __GNUC__
  #pragma GCC diagnostic pop
#endif  // __GNUC__
// -------------------------------------------------------------------


// @@protoc_insertion_point(namespace_scope)

}  // namespace version_edit_sync

// @@protoc_insertion_point(global_scope)

#include <google/protobuf/port_undef.inc>
#endif  // GOOGLE_PROTOBUF_INCLUDED_GOOGLE_PROTOBUF_INCLUDED_version_5fedit_5fsync_2eproto