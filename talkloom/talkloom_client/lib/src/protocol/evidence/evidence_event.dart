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

abstract class EvidenceEvent
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  EvidenceEvent._({
    this.id,
    required this.userId,
    required this.targetLanguage,
    required this.itemId,
    required this.activityType,
    required this.supportLevel,
    required this.spontaneous,
    required this.correct,
    required this.timestamp,
  });

  factory EvidenceEvent({
    int? id,
    required String userId,
    required String targetLanguage,
    required String itemId,
    required String activityType,
    required String supportLevel,
    required bool spontaneous,
    required bool correct,
    required DateTime timestamp,
  }) = _EvidenceEventImpl;

  factory EvidenceEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return EvidenceEvent(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      targetLanguage: jsonSerialization['targetLanguage'] as String,
      itemId: jsonSerialization['itemId'] as String,
      activityType: jsonSerialization['activityType'] as String,
      supportLevel: jsonSerialization['supportLevel'] as String,
      spontaneous: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['spontaneous'],
      ),
      correct: _isc.BoolJsonExtension.fromJson(jsonSerialization['correct']),
      timestamp: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['timestamp'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String userId;

  String targetLanguage;

  String itemId;

  String activityType;

  String supportLevel;

  bool spontaneous;

  bool correct;

  DateTime timestamp;

  /// Returns a shallow copy of this [EvidenceEvent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  EvidenceEvent copyWith({
    int? id,
    String? userId,
    String? targetLanguage,
    String? itemId,
    String? activityType,
    String? supportLevel,
    bool? spontaneous,
    bool? correct,
    DateTime? timestamp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EvidenceEvent',
      if (id != null) 'id': id,
      'userId': userId,
      'targetLanguage': targetLanguage,
      'itemId': itemId,
      'activityType': activityType,
      'supportLevel': supportLevel,
      'spontaneous': spontaneous,
      'correct': correct,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'EvidenceEvent',
      if (id != null) 'id': id,
      'userId': userId,
      'targetLanguage': targetLanguage,
      'itemId': itemId,
      'activityType': activityType,
      'supportLevel': supportLevel,
      'spontaneous': spontaneous,
      'correct': correct,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EvidenceEventImpl extends EvidenceEvent {
  _EvidenceEventImpl({
    int? id,
    required String userId,
    required String targetLanguage,
    required String itemId,
    required String activityType,
    required String supportLevel,
    required bool spontaneous,
    required bool correct,
    required DateTime timestamp,
  }) : super._(
         id: id,
         userId: userId,
         targetLanguage: targetLanguage,
         itemId: itemId,
         activityType: activityType,
         supportLevel: supportLevel,
         spontaneous: spontaneous,
         correct: correct,
         timestamp: timestamp,
       );

  /// Returns a shallow copy of this [EvidenceEvent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  EvidenceEvent copyWith({
    Object? id = _Undefined,
    String? userId,
    String? targetLanguage,
    String? itemId,
    String? activityType,
    String? supportLevel,
    bool? spontaneous,
    bool? correct,
    DateTime? timestamp,
  }) {
    return EvidenceEvent(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      itemId: itemId ?? this.itemId,
      activityType: activityType ?? this.activityType,
      supportLevel: supportLevel ?? this.supportLevel,
      spontaneous: spontaneous ?? this.spontaneous,
      correct: correct ?? this.correct,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
