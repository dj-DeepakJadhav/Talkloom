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
import 'package:talkloom_client/src/protocol/protocol.dart' as _irivagvh;

/// The shared, learner-independent result of analysing one public link for one
/// language pair and level. Any learner who imports the same link reuses this
/// row instead of fetching and compiling again. Server-side only: never
/// returned to clients.
abstract class LinkAnalysis
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LinkAnalysis._({
    this.id,
    required this.normalizedUrl,
    required this.platform,
    this.creator,
    this.creatorKey,
    required this.title,
    required this.targetLanguage,
    required this.supportLanguage,
    required this.cefrLevel,
    required this.transcript,
    required this.contentHash,
    required this.objectives,
    required this.vocabulary,
    required this.grammar,
    required this.activities,
    required this.conversationPlan,
    int? hitCount,
    required this.createdAt,
    required this.lastUsedAt,
    this.expiresAt,
  }) : hitCount = hitCount ?? 0;

  factory LinkAnalysis({
    int? id,
    required String normalizedUrl,
    required String platform,
    String? creator,
    String? creatorKey,
    required String title,
    required String targetLanguage,
    required String supportLanguage,
    required String cefrLevel,
    required String transcript,
    required String contentHash,
    required List<String> objectives,
    required String vocabulary,
    required String grammar,
    required String activities,
    required String conversationPlan,
    int? hitCount,
    required DateTime createdAt,
    required DateTime lastUsedAt,
    DateTime? expiresAt,
  }) = _LinkAnalysisImpl;

  factory LinkAnalysis.fromJson(Map<String, dynamic> jsonSerialization) {
    return LinkAnalysis(
      id: jsonSerialization['id'] as int?,
      normalizedUrl: jsonSerialization['normalizedUrl'] as String,
      platform: jsonSerialization['platform'] as String,
      creator: jsonSerialization['creator'] as String?,
      creatorKey: jsonSerialization['creatorKey'] as String?,
      title: jsonSerialization['title'] as String,
      targetLanguage: jsonSerialization['targetLanguage'] as String,
      supportLanguage: jsonSerialization['supportLanguage'] as String,
      cefrLevel: jsonSerialization['cefrLevel'] as String,
      transcript: jsonSerialization['transcript'] as String,
      contentHash: jsonSerialization['contentHash'] as String,
      objectives: _irivagvh.Protocol().deserialize<List<String>>(
        jsonSerialization['objectives'],
      ),
      vocabulary: jsonSerialization['vocabulary'] as String,
      grammar: jsonSerialization['grammar'] as String,
      activities: jsonSerialization['activities'] as String,
      conversationPlan: jsonSerialization['conversationPlan'] as String,
      hitCount: jsonSerialization['hitCount'] as int?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastUsedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastUsedAt'],
      ),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Output of the URL normaliser; the cache key together with the languages.
  String normalizedUrl;

  /// youtube, instagram, tiktok, reddit, x, facebook or web.
  String platform;

  /// Channel, account, subreddit or site host, as displayed.
  String? creator;

  /// Lower-cased creator for grouping and lookups.
  String? creatorKey;

  String title;

  String targetLanguage;

  String supportLanguage;

  String cefrLevel;

  String transcript;

  /// SHA-256 of the whitespace-normalised transcript.
  String contentHash;

  List<String> objectives;

  String vocabulary;

  String grammar;

  String activities;

  String conversationPlan;

  int hitCount;

  DateTime createdAt;

  DateTime lastUsedAt;

  /// Null means the analysis does not expire.
  DateTime? expiresAt;

  /// Returns a shallow copy of this [LinkAnalysis]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LinkAnalysis copyWith({
    int? id,
    String? normalizedUrl,
    String? platform,
    String? creator,
    String? creatorKey,
    String? title,
    String? targetLanguage,
    String? supportLanguage,
    String? cefrLevel,
    String? transcript,
    String? contentHash,
    List<String>? objectives,
    String? vocabulary,
    String? grammar,
    String? activities,
    String? conversationPlan,
    int? hitCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LinkAnalysis',
      if (id != null) 'id': id,
      'normalizedUrl': normalizedUrl,
      'platform': platform,
      if (creator != null) 'creator': creator,
      if (creatorKey != null) 'creatorKey': creatorKey,
      'title': title,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'cefrLevel': cefrLevel,
      'transcript': transcript,
      'contentHash': contentHash,
      'objectives': objectives.toJson(),
      'vocabulary': vocabulary,
      'grammar': grammar,
      'activities': activities,
      'conversationPlan': conversationPlan,
      'hitCount': hitCount,
      'createdAt': createdAt.toJson(),
      'lastUsedAt': lastUsedAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LinkAnalysis',
      if (id != null) 'id': id,
      'normalizedUrl': normalizedUrl,
      'platform': platform,
      if (creator != null) 'creator': creator,
      if (creatorKey != null) 'creatorKey': creatorKey,
      'title': title,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'cefrLevel': cefrLevel,
      'transcript': transcript,
      'contentHash': contentHash,
      'objectives': objectives.toJson(),
      'vocabulary': vocabulary,
      'grammar': grammar,
      'activities': activities,
      'conversationPlan': conversationPlan,
      'hitCount': hitCount,
      'createdAt': createdAt.toJson(),
      'lastUsedAt': lastUsedAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LinkAnalysisImpl extends LinkAnalysis {
  _LinkAnalysisImpl({
    int? id,
    required String normalizedUrl,
    required String platform,
    String? creator,
    String? creatorKey,
    required String title,
    required String targetLanguage,
    required String supportLanguage,
    required String cefrLevel,
    required String transcript,
    required String contentHash,
    required List<String> objectives,
    required String vocabulary,
    required String grammar,
    required String activities,
    required String conversationPlan,
    int? hitCount,
    required DateTime createdAt,
    required DateTime lastUsedAt,
    DateTime? expiresAt,
  }) : super._(
         id: id,
         normalizedUrl: normalizedUrl,
         platform: platform,
         creator: creator,
         creatorKey: creatorKey,
         title: title,
         targetLanguage: targetLanguage,
         supportLanguage: supportLanguage,
         cefrLevel: cefrLevel,
         transcript: transcript,
         contentHash: contentHash,
         objectives: objectives,
         vocabulary: vocabulary,
         grammar: grammar,
         activities: activities,
         conversationPlan: conversationPlan,
         hitCount: hitCount,
         createdAt: createdAt,
         lastUsedAt: lastUsedAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [LinkAnalysis]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LinkAnalysis copyWith({
    Object? id = _Undefined,
    String? normalizedUrl,
    String? platform,
    Object? creator = _Undefined,
    Object? creatorKey = _Undefined,
    String? title,
    String? targetLanguage,
    String? supportLanguage,
    String? cefrLevel,
    String? transcript,
    String? contentHash,
    List<String>? objectives,
    String? vocabulary,
    String? grammar,
    String? activities,
    String? conversationPlan,
    int? hitCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    Object? expiresAt = _Undefined,
  }) {
    return LinkAnalysis(
      id: id is int? ? id : this.id,
      normalizedUrl: normalizedUrl ?? this.normalizedUrl,
      platform: platform ?? this.platform,
      creator: creator is String? ? creator : this.creator,
      creatorKey: creatorKey is String? ? creatorKey : this.creatorKey,
      title: title ?? this.title,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      supportLanguage: supportLanguage ?? this.supportLanguage,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      transcript: transcript ?? this.transcript,
      contentHash: contentHash ?? this.contentHash,
      objectives: objectives ?? this.objectives.map((e0) => e0).toList(),
      vocabulary: vocabulary ?? this.vocabulary,
      grammar: grammar ?? this.grammar,
      activities: activities ?? this.activities,
      conversationPlan: conversationPlan ?? this.conversationPlan,
      hitCount: hitCount ?? this.hitCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
    );
  }
}
