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

/// Daily AI spend ledger, one row per learner per UTC day.
/// The quota gate reads and bumps these counters before any Meta call.
abstract class AiUsage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AiUsage._({
    this.id,
    required this.userId,
    required this.day,
    int? imports,
    int? conversationTurns,
    int? transcriptions,
    int? illustrations,
  }) : imports = imports ?? 0,
       conversationTurns = conversationTurns ?? 0,
       transcriptions = transcriptions ?? 0,
       illustrations = illustrations ?? 0;

  factory AiUsage({
    int? id,
    required String userId,
    required DateTime day,
    int? imports,
    int? conversationTurns,
    int? transcriptions,
    int? illustrations,
  }) = _AiUsageImpl;

  factory AiUsage.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiUsage(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      day: _isc.DateTimeJsonExtension.fromJson(jsonSerialization['day']),
      imports: jsonSerialization['imports'] as int?,
      conversationTurns: jsonSerialization['conversationTurns'] as int?,
      transcriptions: jsonSerialization['transcriptions'] as int?,
      illustrations: jsonSerialization['illustrations'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String userId;

  /// UTC midnight of the counted day.
  DateTime day;

  int imports;

  int conversationTurns;

  int transcriptions;

  int illustrations;

  /// Returns a shallow copy of this [AiUsage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AiUsage copyWith({
    int? id,
    String? userId,
    DateTime? day,
    int? imports,
    int? conversationTurns,
    int? transcriptions,
    int? illustrations,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiUsage',
      if (id != null) 'id': id,
      'userId': userId,
      'day': day.toJson(),
      'imports': imports,
      'conversationTurns': conversationTurns,
      'transcriptions': transcriptions,
      'illustrations': illustrations,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AiUsage',
      if (id != null) 'id': id,
      'userId': userId,
      'day': day.toJson(),
      'imports': imports,
      'conversationTurns': conversationTurns,
      'transcriptions': transcriptions,
      'illustrations': illustrations,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AiUsageImpl extends AiUsage {
  _AiUsageImpl({
    int? id,
    required String userId,
    required DateTime day,
    int? imports,
    int? conversationTurns,
    int? transcriptions,
    int? illustrations,
  }) : super._(
         id: id,
         userId: userId,
         day: day,
         imports: imports,
         conversationTurns: conversationTurns,
         transcriptions: transcriptions,
         illustrations: illustrations,
       );

  /// Returns a shallow copy of this [AiUsage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AiUsage copyWith({
    Object? id = _Undefined,
    String? userId,
    DateTime? day,
    int? imports,
    int? conversationTurns,
    int? transcriptions,
    int? illustrations,
  }) {
    return AiUsage(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      day: day ?? this.day,
      imports: imports ?? this.imports,
      conversationTurns: conversationTurns ?? this.conversationTurns,
      transcriptions: transcriptions ?? this.transcriptions,
      illustrations: illustrations ?? this.illustrations,
    );
  }
}
