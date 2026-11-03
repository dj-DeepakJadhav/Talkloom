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

/// One progress update for an [ImportJob], pushed to its owner's stream.
abstract class ImportJobProgress
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ImportJobProgress._({
    required this.jobId,
    required this.stage,
    this.sourceId,
    this.lessonId,
    this.errorCode,
    this.errorMessage,
  });

  factory ImportJobProgress({
    required int jobId,
    required String stage,
    int? sourceId,
    int? lessonId,
    String? errorCode,
    String? errorMessage,
  }) = _ImportJobProgressImpl;

  factory ImportJobProgress.fromJson(Map<String, dynamic> jsonSerialization) {
    return ImportJobProgress(
      jobId: jsonSerialization['jobId'] as int,
      stage: jsonSerialization['stage'] as String,
      sourceId: jsonSerialization['sourceId'] as int?,
      lessonId: jsonSerialization['lessonId'] as int?,
      errorCode: jsonSerialization['errorCode'] as String?,
      errorMessage: jsonSerialization['errorMessage'] as String?,
    );
  }

  int jobId;

  /// queued, fetching, transcript, compiling, validating, saved or failed.
  String stage;

  int? sourceId;

  int? lessonId;

  /// Safe ImportException-style code when [stage] is failed.
  String? errorCode;

  /// Learner-facing explanation when [stage] is failed.
  String? errorMessage;

  /// Returns a shallow copy of this [ImportJobProgress]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ImportJobProgress copyWith({
    int? jobId,
    String? stage,
    int? sourceId,
    int? lessonId,
    String? errorCode,
    String? errorMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ImportJobProgress',
      'jobId': jobId,
      'stage': stage,
      if (sourceId != null) 'sourceId': sourceId,
      if (lessonId != null) 'lessonId': lessonId,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ImportJobProgress',
      'jobId': jobId,
      'stage': stage,
      if (sourceId != null) 'sourceId': sourceId,
      if (lessonId != null) 'lessonId': lessonId,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ImportJobProgressImpl extends ImportJobProgress {
  _ImportJobProgressImpl({
    required int jobId,
    required String stage,
    int? sourceId,
    int? lessonId,
    String? errorCode,
    String? errorMessage,
  }) : super._(
         jobId: jobId,
         stage: stage,
         sourceId: sourceId,
         lessonId: lessonId,
         errorCode: errorCode,
         errorMessage: errorMessage,
       );

  /// Returns a shallow copy of this [ImportJobProgress]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ImportJobProgress copyWith({
    int? jobId,
    String? stage,
    Object? sourceId = _Undefined,
    Object? lessonId = _Undefined,
    Object? errorCode = _Undefined,
    Object? errorMessage = _Undefined,
  }) {
    return ImportJobProgress(
      jobId: jobId ?? this.jobId,
      stage: stage ?? this.stage,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
      lessonId: lessonId is int? ? lessonId : this.lessonId,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
    );
  }
}
