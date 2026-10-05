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

abstract class Source
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Source._({
    this.id,
    required this.userId,
    required this.type,
    this.url,
    required this.rawText,
    required this.title,
    required this.targetLanguage,
    required this.cefrLevel,
    required this.createdAt,
  });

  factory Source({
    int? id,
    required String userId,
    required String type,
    String? url,
    required String rawText,
    required String title,
    required String targetLanguage,
    required String cefrLevel,
    required DateTime createdAt,
  }) = _SourceImpl;

  factory Source.fromJson(Map<String, dynamic> jsonSerialization) {
    return Source(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      type: jsonSerialization['type'] as String,
      url: jsonSerialization['url'] as String?,
      rawText: jsonSerialization['rawText'] as String,
      title: jsonSerialization['title'] as String,
      targetLanguage: jsonSerialization['targetLanguage'] as String,
      cefrLevel: jsonSerialization['cefrLevel'] as String,
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

  String type;

  String? url;

  String rawText;

  String title;

  String targetLanguage;

  String cefrLevel;

  DateTime createdAt;

  /// Returns a shallow copy of this [Source]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Source copyWith({
    int? id,
    String? userId,
    String? type,
    String? url,
    String? rawText,
    String? title,
    String? targetLanguage,
    String? cefrLevel,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Source',
      if (id != null) 'id': id,
      'userId': userId,
      'type': type,
      if (url != null) 'url': url,
      'rawText': rawText,
      'title': title,
      'targetLanguage': targetLanguage,
      'cefrLevel': cefrLevel,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Source',
      if (id != null) 'id': id,
      'userId': userId,
      'type': type,
      if (url != null) 'url': url,
      'rawText': rawText,
      'title': title,
      'targetLanguage': targetLanguage,
      'cefrLevel': cefrLevel,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SourceImpl extends Source {
  _SourceImpl({
    int? id,
    required String userId,
    required String type,
    String? url,
    required String rawText,
    required String title,
    required String targetLanguage,
    required String cefrLevel,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         type: type,
         url: url,
         rawText: rawText,
         title: title,
         targetLanguage: targetLanguage,
         cefrLevel: cefrLevel,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Source]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Source copyWith({
    Object? id = _Undefined,
    String? userId,
    String? type,
    Object? url = _Undefined,
    String? rawText,
    String? title,
    String? targetLanguage,
    String? cefrLevel,
    DateTime? createdAt,
  }) {
    return Source(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      url: url is String? ? url : this.url,
      rawText: rawText ?? this.rawText,
      title: title ?? this.title,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
