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
import 'dart:typed_data' as _idt;
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// One house-style illustration per vocabulary lemma, shared across all
/// learners and languages. The style is locked server-side, so the same
/// word always renders the same picture everywhere. Server-side only:
/// clients receive bytes, never rows.
abstract class VocabArtwork
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  VocabArtwork._({
    this.id,
    required this.lemmaKey,
    required this.language,
    int? styleVersion,
    required this.mimeType,
    required this.artwork,
    int? hitCount,
    required this.createdAt,
    required this.lastUsedAt,
  }) : styleVersion = styleVersion ?? 1,
       hitCount = hitCount ?? 0;

  factory VocabArtwork({
    int? id,
    required String lemmaKey,
    required String language,
    int? styleVersion,
    required String mimeType,
    required _idt.ByteData artwork,
    int? hitCount,
    required DateTime createdAt,
    required DateTime lastUsedAt,
  }) = _VocabArtworkImpl;

  factory VocabArtwork.fromJson(Map<String, dynamic> jsonSerialization) {
    return VocabArtwork(
      id: jsonSerialization['id'] as int?,
      lemmaKey: jsonSerialization['lemmaKey'] as String,
      language: jsonSerialization['language'] as String,
      styleVersion: jsonSerialization['styleVersion'] as int?,
      mimeType: jsonSerialization['mimeType'] as String,
      artwork: _isc.ByteDataJsonExtension.fromJson(
        jsonSerialization['artwork'],
      ),
      hitCount: jsonSerialization['hitCount'] as int?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastUsedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastUsedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Lower-cased lemma; the cross-language dedupe key.
  String lemmaKey;

  /// Language the word was requested in (informational; art is shared).
  String language;

  /// Bumps when the house style changes; old rows are ignored, never migrated.
  int styleVersion;

  String mimeType;

  _idt.ByteData artwork;

  int hitCount;

  DateTime createdAt;

  DateTime lastUsedAt;

  /// Returns a shallow copy of this [VocabArtwork]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  VocabArtwork copyWith({
    int? id,
    String? lemmaKey,
    String? language,
    int? styleVersion,
    String? mimeType,
    _idt.ByteData? artwork,
    int? hitCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VocabArtwork',
      if (id != null) 'id': id,
      'lemmaKey': lemmaKey,
      'language': language,
      'styleVersion': styleVersion,
      'mimeType': mimeType,
      'artwork': artwork.toJson(),
      'hitCount': hitCount,
      'createdAt': createdAt.toJson(),
      'lastUsedAt': lastUsedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VocabArtwork',
      if (id != null) 'id': id,
      'lemmaKey': lemmaKey,
      'language': language,
      'styleVersion': styleVersion,
      'mimeType': mimeType,
      'artwork': artwork.toJson(),
      'hitCount': hitCount,
      'createdAt': createdAt.toJson(),
      'lastUsedAt': lastUsedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VocabArtworkImpl extends VocabArtwork {
  _VocabArtworkImpl({
    int? id,
    required String lemmaKey,
    required String language,
    int? styleVersion,
    required String mimeType,
    required _idt.ByteData artwork,
    int? hitCount,
    required DateTime createdAt,
    required DateTime lastUsedAt,
  }) : super._(
         id: id,
         lemmaKey: lemmaKey,
         language: language,
         styleVersion: styleVersion,
         mimeType: mimeType,
         artwork: artwork,
         hitCount: hitCount,
         createdAt: createdAt,
         lastUsedAt: lastUsedAt,
       );

  /// Returns a shallow copy of this [VocabArtwork]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  VocabArtwork copyWith({
    Object? id = _Undefined,
    String? lemmaKey,
    String? language,
    int? styleVersion,
    String? mimeType,
    _idt.ByteData? artwork,
    int? hitCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return VocabArtwork(
      id: id is int? ? id : this.id,
      lemmaKey: lemmaKey ?? this.lemmaKey,
      language: language ?? this.language,
      styleVersion: styleVersion ?? this.styleVersion,
      mimeType: mimeType ?? this.mimeType,
      artwork: artwork ?? this.artwork.clone(),
      hitCount: hitCount ?? this.hitCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
