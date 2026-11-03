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

abstract class LearnerState
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LearnerState._({
    this.id,
    required this.userId,
    required this.targetLanguage,
    required this.recognizedWords,
    required this.activeWords,
    required this.grammarMastery,
    required this.updatedAt,
  });

  factory LearnerState({
    int? id,
    required String userId,
    required String targetLanguage,
    required List<String> recognizedWords,
    required List<String> activeWords,
    required String grammarMastery,
    required DateTime updatedAt,
  }) = _LearnerStateImpl;

  factory LearnerState.fromJson(Map<String, dynamic> jsonSerialization) {
    return LearnerState(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      targetLanguage: jsonSerialization['targetLanguage'] as String,
      recognizedWords: _irivagvh.Protocol().deserialize<List<String>>(
        jsonSerialization['recognizedWords'],
      ),
      activeWords: _irivagvh.Protocol().deserialize<List<String>>(
        jsonSerialization['activeWords'],
      ),
      grammarMastery: jsonSerialization['grammarMastery'] as String,
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String userId;

  String targetLanguage;

  List<String> recognizedWords;

  List<String> activeWords;

  String grammarMastery;

  DateTime updatedAt;

  /// Returns a shallow copy of this [LearnerState]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LearnerState copyWith({
    int? id,
    String? userId,
    String? targetLanguage,
    List<String>? recognizedWords,
    List<String>? activeWords,
    String? grammarMastery,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LearnerState',
      if (id != null) 'id': id,
      'userId': userId,
      'targetLanguage': targetLanguage,
      'recognizedWords': recognizedWords.toJson(),
      'activeWords': activeWords.toJson(),
      'grammarMastery': grammarMastery,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LearnerState',
      if (id != null) 'id': id,
      'userId': userId,
      'targetLanguage': targetLanguage,
      'recognizedWords': recognizedWords.toJson(),
      'activeWords': activeWords.toJson(),
      'grammarMastery': grammarMastery,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LearnerStateImpl extends LearnerState {
  _LearnerStateImpl({
    int? id,
    required String userId,
    required String targetLanguage,
    required List<String> recognizedWords,
    required List<String> activeWords,
    required String grammarMastery,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         targetLanguage: targetLanguage,
         recognizedWords: recognizedWords,
         activeWords: activeWords,
         grammarMastery: grammarMastery,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [LearnerState]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LearnerState copyWith({
    Object? id = _Undefined,
    String? userId,
    String? targetLanguage,
    List<String>? recognizedWords,
    List<String>? activeWords,
    String? grammarMastery,
    DateTime? updatedAt,
  }) {
    return LearnerState(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      recognizedWords:
          recognizedWords ?? this.recognizedWords.map((e0) => e0).toList(),
      activeWords: activeWords ?? this.activeWords.map((e0) => e0).toList(),
      grammarMastery: grammarMastery ?? this.grammarMastery,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
