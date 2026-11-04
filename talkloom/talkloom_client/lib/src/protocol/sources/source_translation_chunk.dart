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

abstract class SourceTranslationChunk
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SourceTranslationChunk._({
    this.id,
    required this.userId,
    required this.sourceId,
    required this.cacheKey,
    required this.supportLanguage,
    required this.mode,
    required this.segments,
    required this.createdAt,
  });

  factory SourceTranslationChunk({
    int? id,
    required String userId,
    required int sourceId,
    required String cacheKey,
    required String supportLanguage,
    required String mode,
    required String segments,
    required DateTime createdAt,
  }) = _SourceTranslationChunkImpl;

  factory SourceTranslationChunk.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SourceTranslationChunk(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      sourceId: jsonSerialization['sourceId'] as int,
      cacheKey: jsonSerialization['cacheKey'] as String,
      supportLanguage: jsonSerialization['supportLanguage'] as String,
      mode: jsonSerialization['mode'] as String,
      segments: jsonSerialization['segments'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String userId;

  int sourceId;

  String cacheKey;

  String supportLanguage;

  String mode;

  String segments;

  DateTime createdAt;

  /// Returns a shallow copy of this [SourceTranslationChunk]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SourceTranslationChunk copyWith({
    int? id,
    String? userId,
    int? sourceId,
    String? cacheKey,
    String? supportLanguage,
    String? mode,
    String? segments,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SourceTranslationChunk',
      if (id != null) 'id': id,
      'userId': userId,
      'sourceId': sourceId,
      'cacheKey': cacheKey,
      'supportLanguage': supportLanguage,
      'mode': mode,
      'segments': segments,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SourceTranslationChunk',
      if (id != null) 'id': id,
      'userId': userId,
      'sourceId': sourceId,
      'cacheKey': cacheKey,
      'supportLanguage': supportLanguage,
      'mode': mode,
      'segments': segments,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SourceTranslationChunkImpl extends SourceTranslationChunk {
  _SourceTranslationChunkImpl({
    int? id,
    required String userId,
    required int sourceId,
    required String cacheKey,
    required String supportLanguage,
    required String mode,
    required String segments,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         sourceId: sourceId,
         cacheKey: cacheKey,
         supportLanguage: supportLanguage,
         mode: mode,
         segments: segments,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SourceTranslationChunk]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SourceTranslationChunk copyWith({
    Object? id = _Undefined,
    String? userId,
    int? sourceId,
    String? cacheKey,
    String? supportLanguage,
    String? mode,
    String? segments,
    DateTime? createdAt,
  }) {
    return SourceTranslationChunk(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      sourceId: sourceId ?? this.sourceId,
      cacheKey: cacheKey ?? this.cacheKey,
      supportLanguage: supportLanguage ?? this.supportLanguage,
      mode: mode ?? this.mode,
      segments: segments ?? this.segments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
