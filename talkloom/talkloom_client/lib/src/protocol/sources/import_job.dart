/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// A background lesson import owned by one learner. The import endpoint
/// creates the row and schedules a Future Call that does the slow work, so the
/// request returns immediately and progress is pushed over a stream.
abstract class ImportJob
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ImportJob._({
    this.id,
    required this.type,
    required this.title,
    required this.targetLanguage,
    required this.supportLanguage,
    required this.cefrLevel,
    this.url,
    String? stage,
    this.sourceId,
    this.lessonId,
    this.errorCode,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  }) : stage = stage ?? 'queued';

  factory ImportJob({
    int? id,
    required String type,
    required String title,
    required String targetLanguage,
    required String supportLanguage,
    required String cefrLevel,
    String? url,
    String? stage,
    int? sourceId,
    int? lessonId,
    String? errorCode,
    String? errorMessage,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ImportJobImpl;

  factory ImportJob.fromJson(Map<String, dynamic> jsonSerialization) {
    return ImportJob(
      id: jsonSerialization['id'] as int?,
      type: jsonSerialization['type'] as String,
      title: jsonSerialization['title'] as String,
      targetLanguage: jsonSerialization['targetLanguage'] as String,
      supportLanguage: jsonSerialization['supportLanguage'] as String,
      cefrLevel: jsonSerialization['cefrLevel'] as String,
      url: jsonSerialization['url'] as String?,
      stage: jsonSerialization['stage'] as String?,
      sourceId: jsonSerialization['sourceId'] as int?,
      lessonId: jsonSerialization['lessonId'] as int?,
      errorCode: jsonSerialization['errorCode'] as String?,
      errorMessage: jsonSerialization['errorMessage'] as String?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// url, text, document, image or ocr.
  String type;

  String title;

  String targetLanguage;

  String supportLanguage;

  String cefrLevel;

  String? url;

  /// queued, fetching, transcript, compiling, validating, saved or failed.
  String stage;

  int? sourceId;

  int? lessonId;

  String? errorCode;

  String? errorMessage;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ImportJob]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ImportJob copyWith({
    int? id,
    String? type,
    String? title,
    String? targetLanguage,
    String? supportLanguage,
    String? cefrLevel,
    String? url,
    String? stage,
    int? sourceId,
    int? lessonId,
    String? errorCode,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ImportJob',
      if (id != null) 'id': id,
      'type': type,
      'title': title,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'cefrLevel': cefrLevel,
      if (url != null) 'url': url,
      'stage': stage,
      if (sourceId != null) 'sourceId': sourceId,
      if (lessonId != null) 'lessonId': lessonId,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ImportJob',
      if (id != null) 'id': id,
      'type': type,
      'title': title,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'cefrLevel': cefrLevel,
      if (url != null) 'url': url,
      'stage': stage,
      if (sourceId != null) 'sourceId': sourceId,
      if (lessonId != null) 'lessonId': lessonId,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ImportJobImpl extends ImportJob {
  _ImportJobImpl({
    int? id,
    required String type,
    required String title,
    required String targetLanguage,
    required String supportLanguage,
    required String cefrLevel,
    String? url,
    String? stage,
    int? sourceId,
    int? lessonId,
    String? errorCode,
    String? errorMessage,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         type: type,
         title: title,
         targetLanguage: targetLanguage,
         supportLanguage: supportLanguage,
         cefrLevel: cefrLevel,
         url: url,
         stage: stage,
         sourceId: sourceId,
         lessonId: lessonId,
         errorCode: errorCode,
         errorMessage: errorMessage,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ImportJob]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ImportJob copyWith({
    Object? id = _Undefined,
    String? type,
    String? title,
    String? targetLanguage,
    String? supportLanguage,
    String? cefrLevel,
    Object? url = _Undefined,
    String? stage,
    Object? sourceId = _Undefined,
    Object? lessonId = _Undefined,
    Object? errorCode = _Undefined,
    Object? errorMessage = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ImportJob(
      id: id is int? ? id : this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      supportLanguage: supportLanguage ?? this.supportLanguage,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      url: url is String? ? url : this.url,
      stage: stage ?? this.stage,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
      lessonId: lessonId is int? ? lessonId : this.lessonId,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
