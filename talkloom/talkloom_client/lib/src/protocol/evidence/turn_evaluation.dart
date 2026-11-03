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

/// Independent semantic evaluation of one learner speaking turn against the
/// source-linked targets of a lesson the learner owns. Written only by the
/// server; the tutor reply is never used as evidence.
abstract class TurnEvaluation
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  TurnEvaluation._({
    this.id,
    required this.targetLanguage,
    required this.lessonId,
    required this.status,
    this.provider,
    this.model,
    this.reason,
    required this.results,
    required this.createdAt,
  });

  factory TurnEvaluation({
    int? id,
    required String targetLanguage,
    required int lessonId,
    required String status,
    String? provider,
    String? model,
    String? reason,
    required String results,
    required DateTime createdAt,
  }) = _TurnEvaluationImpl;

  factory TurnEvaluation.fromJson(Map<String, dynamic> jsonSerialization) {
    return TurnEvaluation(
      id: jsonSerialization['id'] as int?,
      targetLanguage: jsonSerialization['targetLanguage'] as String,
      lessonId: jsonSerialization['lessonId'] as int,
      status: jsonSerialization['status'] as String,
      provider: jsonSerialization['provider'] as String?,
      model: jsonSerialization['model'] as String?,
      reason: jsonSerialization['reason'] as String?,
      results: jsonSerialization['results'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String targetLanguage;

  int lessonId;

  /// evaluated, evaluator_unavailable or assisted.
  String status;

  /// Evaluator provider and model, null when no evaluator call was made.
  String? provider;

  String? model;

  /// Safe reason when status is not evaluated (no_provider_key,
  /// provider_error, malformed_output, tutor_assisted).
  String? reason;

  /// JSON list of per-target judgements:
  /// {itemId, kind, used, correct, inContext, spontaneous, eligible}.
  String results;

  DateTime createdAt;

  /// Returns a shallow copy of this [TurnEvaluation]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  TurnEvaluation copyWith({
    int? id,
    String? targetLanguage,
    int? lessonId,
    String? status,
    String? provider,
    String? model,
    String? reason,
    String? results,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TurnEvaluation',
      if (id != null) 'id': id,
      'targetLanguage': targetLanguage,
      'lessonId': lessonId,
      'status': status,
      if (provider != null) 'provider': provider,
      if (model != null) 'model': model,
      if (reason != null) 'reason': reason,
      'results': results,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TurnEvaluation',
      if (id != null) 'id': id,
      'targetLanguage': targetLanguage,
      'lessonId': lessonId,
      'status': status,
      if (provider != null) 'provider': provider,
      if (model != null) 'model': model,
      if (reason != null) 'reason': reason,
      'results': results,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TurnEvaluationImpl extends TurnEvaluation {
  _TurnEvaluationImpl({
    int? id,
    required String targetLanguage,
    required int lessonId,
    required String status,
    String? provider,
    String? model,
    String? reason,
    required String results,
    required DateTime createdAt,
  }) : super._(
         id: id,
         targetLanguage: targetLanguage,
         lessonId: lessonId,
         status: status,
         provider: provider,
         model: model,
         reason: reason,
         results: results,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TurnEvaluation]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  TurnEvaluation copyWith({
    Object? id = _Undefined,
    String? targetLanguage,
    int? lessonId,
    String? status,
    Object? provider = _Undefined,
    Object? model = _Undefined,
    Object? reason = _Undefined,
    String? results,
    DateTime? createdAt,
  }) {
    return TurnEvaluation(
      id: id is int? ? id : this.id,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      lessonId: lessonId ?? this.lessonId,
      status: status ?? this.status,
      provider: provider is String? ? provider : this.provider,
      model: model is String? ? model : this.model,
      reason: reason is String? ? reason : this.reason,
      results: results ?? this.results,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
