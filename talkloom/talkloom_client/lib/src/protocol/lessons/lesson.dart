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

abstract class Lesson
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Lesson._({
    this.id,
    required this.userId,
    required this.sourceId,
    required this.targetLanguage,
    required this.supportLanguage,
    required this.objectives,
    required this.vocabulary,
    required this.grammar,
    required this.activities,
    required this.conversationPlan,
    required this.createdAt,
  });

  factory Lesson({
    int? id,
    required String userId,
    required int sourceId,
    required String targetLanguage,
    required String supportLanguage,
    required List<String> objectives,
    required String vocabulary,
    required String grammar,
    required String activities,
    required String conversationPlan,
    required DateTime createdAt,
  }) = _LessonImpl;

  factory Lesson.fromJson(Map<String, dynamic> jsonSerialization) {
    return Lesson(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      sourceId: jsonSerialization['sourceId'] as int,
      targetLanguage: jsonSerialization['targetLanguage'] as String,
      supportLanguage: jsonSerialization['supportLanguage'] as String,
      objectives: _irivagvh.Protocol().deserialize<List<String>>(
        jsonSerialization['objectives'],
      ),
      vocabulary: jsonSerialization['vocabulary'] as String,
      grammar: jsonSerialization['grammar'] as String,
      activities: jsonSerialization['activities'] as String,
      conversationPlan: jsonSerialization['conversationPlan'] as String,
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

  String targetLanguage;

  String supportLanguage;

  List<String> objectives;

  String vocabulary;

  String grammar;

  String activities;

  String conversationPlan;

  DateTime createdAt;

  /// Returns a shallow copy of this [Lesson]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Lesson copyWith({
    int? id,
    String? userId,
    int? sourceId,
    String? targetLanguage,
    String? supportLanguage,
    List<String>? objectives,
    String? vocabulary,
    String? grammar,
    String? activities,
    String? conversationPlan,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Lesson',
      if (id != null) 'id': id,
      'userId': userId,
      'sourceId': sourceId,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'objectives': objectives.toJson(),
      'vocabulary': vocabulary,
      'grammar': grammar,
      'activities': activities,
      'conversationPlan': conversationPlan,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Lesson',
      if (id != null) 'id': id,
      'userId': userId,
      'sourceId': sourceId,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'objectives': objectives.toJson(),
      'vocabulary': vocabulary,
      'grammar': grammar,
      'activities': activities,
      'conversationPlan': conversationPlan,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LessonImpl extends Lesson {
  _LessonImpl({
    int? id,
    required String userId,
    required int sourceId,
    required String targetLanguage,
    required String supportLanguage,
    required List<String> objectives,
    required String vocabulary,
    required String grammar,
    required String activities,
    required String conversationPlan,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         sourceId: sourceId,
         targetLanguage: targetLanguage,
         supportLanguage: supportLanguage,
         objectives: objectives,
         vocabulary: vocabulary,
         grammar: grammar,
         activities: activities,
         conversationPlan: conversationPlan,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Lesson]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Lesson copyWith({
    Object? id = _Undefined,
    String? userId,
    int? sourceId,
    String? targetLanguage,
    String? supportLanguage,
    List<String>? objectives,
    String? vocabulary,
    String? grammar,
    String? activities,
    String? conversationPlan,
    DateTime? createdAt,
  }) {
    return Lesson(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      sourceId: sourceId ?? this.sourceId,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      supportLanguage: supportLanguage ?? this.supportLanguage,
      objectives: objectives ?? this.objectives.map((e0) => e0).toList(),
      vocabulary: vocabulary ?? this.vocabulary,
      grammar: grammar ?? this.grammar,
      activities: activities ?? this.activities,
      conversationPlan: conversationPlan ?? this.conversationPlan,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
