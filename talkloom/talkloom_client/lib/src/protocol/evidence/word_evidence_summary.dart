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

/// Owner-scoped, server-verified evidence summary for one lesson target.
abstract class WordEvidenceSummary
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WordEvidenceSummary._({
    required this.itemId,
    required this.kind,
    required this.eligibleCorrectTurns,
    required this.incorrectTurns,
    required this.ineligibleTurns,
    required this.threshold,
    required this.mastered,
    this.lastEvidenceAt,
  });

  factory WordEvidenceSummary({
    required String itemId,
    required String kind,
    required int eligibleCorrectTurns,
    required int incorrectTurns,
    required int ineligibleTurns,
    required int threshold,
    required bool mastered,
    DateTime? lastEvidenceAt,
  }) = _WordEvidenceSummaryImpl;

  factory WordEvidenceSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return WordEvidenceSummary(
      itemId: jsonSerialization['itemId'] as String,
      kind: jsonSerialization['kind'] as String,
      eligibleCorrectTurns: jsonSerialization['eligibleCorrectTurns'] as int,
      incorrectTurns: jsonSerialization['incorrectTurns'] as int,
      ineligibleTurns: jsonSerialization['ineligibleTurns'] as int,
      threshold: jsonSerialization['threshold'] as int,
      mastered: _isc.BoolJsonExtension.fromJson(jsonSerialization['mastered']),
      lastEvidenceAt: jsonSerialization['lastEvidenceAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastEvidenceAt'],
            ),
    );
  }

  String itemId;

  /// vocabulary or grammar.
  String kind;

  /// Number of separate evaluated turns with eligible correct, in-context,
  /// spontaneous use.
  int eligibleCorrectTurns;

  /// Number of evaluated turns where the target was used incorrectly.
  int incorrectTurns;

  /// Evaluated turns with correct use that was prompted or tutor-modelled,
  /// so it does not count toward mastery.
  int ineligibleTurns;

  /// Turns required for active mastery (see masteryTurnThreshold).
  int threshold;

  bool mastered;

  DateTime? lastEvidenceAt;

  /// Returns a shallow copy of this [WordEvidenceSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WordEvidenceSummary copyWith({
    String? itemId,
    String? kind,
    int? eligibleCorrectTurns,
    int? incorrectTurns,
    int? ineligibleTurns,
    int? threshold,
    bool? mastered,
    DateTime? lastEvidenceAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WordEvidenceSummary',
      'itemId': itemId,
      'kind': kind,
      'eligibleCorrectTurns': eligibleCorrectTurns,
      'incorrectTurns': incorrectTurns,
      'ineligibleTurns': ineligibleTurns,
      'threshold': threshold,
      'mastered': mastered,
      if (lastEvidenceAt != null) 'lastEvidenceAt': lastEvidenceAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WordEvidenceSummary',
      'itemId': itemId,
      'kind': kind,
      'eligibleCorrectTurns': eligibleCorrectTurns,
      'incorrectTurns': incorrectTurns,
      'ineligibleTurns': ineligibleTurns,
      'threshold': threshold,
      'mastered': mastered,
      if (lastEvidenceAt != null) 'lastEvidenceAt': lastEvidenceAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WordEvidenceSummaryImpl extends WordEvidenceSummary {
  _WordEvidenceSummaryImpl({
    required String itemId,
    required String kind,
    required int eligibleCorrectTurns,
    required int incorrectTurns,
    required int ineligibleTurns,
    required int threshold,
    required bool mastered,
    DateTime? lastEvidenceAt,
  }) : super._(
         itemId: itemId,
         kind: kind,
         eligibleCorrectTurns: eligibleCorrectTurns,
         incorrectTurns: incorrectTurns,
         ineligibleTurns: ineligibleTurns,
         threshold: threshold,
         mastered: mastered,
         lastEvidenceAt: lastEvidenceAt,
       );

  /// Returns a shallow copy of this [WordEvidenceSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WordEvidenceSummary copyWith({
    String? itemId,
    String? kind,
    int? eligibleCorrectTurns,
    int? incorrectTurns,
    int? ineligibleTurns,
    int? threshold,
    bool? mastered,
    Object? lastEvidenceAt = _Undefined,
  }) {
    return WordEvidenceSummary(
      itemId: itemId ?? this.itemId,
      kind: kind ?? this.kind,
      eligibleCorrectTurns: eligibleCorrectTurns ?? this.eligibleCorrectTurns,
      incorrectTurns: incorrectTurns ?? this.incorrectTurns,
      ineligibleTurns: ineligibleTurns ?? this.ineligibleTurns,
      threshold: threshold ?? this.threshold,
      mastered: mastered ?? this.mastered,
      lastEvidenceAt: lastEvidenceAt is DateTime?
          ? lastEvidenceAt
          : this.lastEvidenceAt,
    );
  }
}
