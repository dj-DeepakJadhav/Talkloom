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
import 'package:serverpod/serverpod.dart' as _is;

/// Raised when a source cannot be imported for a reason the learner can act
/// on. Serverpod delivers serializable exceptions to the client intact, unlike
/// ordinary errors, which are masked as an internal server error.
abstract class ImportException
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  ImportException._({
    required this.code,
    required this.message,
  });

  factory ImportException({
    required String code,
    required String message,
  }) = _ImportExceptionImpl;

  factory ImportException.fromJson(Map<String, dynamic> jsonSerialization) {
    return ImportException(
      code: jsonSerialization['code'] as String,
      message: jsonSerialization['message'] as String,
    );
  }

  /// Machine-readable reason: blocked, not_found, unavailable, no_text,
  /// timeout, unreachable, unsupported_link or unreadable.
  String code;

  /// Plain-language explanation that is safe to show a learner.
  String message;

  /// Returns a shallow copy of this [ImportException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ImportException copyWith({
    String? code,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ImportException',
      'code': code,
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ImportException',
      'code': code,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'ImportException(code: $code, message: $message)';
  }
}

class _ImportExceptionImpl extends ImportException {
  _ImportExceptionImpl({
    required String code,
    required String message,
  }) : super._(
         code: code,
         message: message,
       );

  /// Returns a shallow copy of this [ImportException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ImportException copyWith({
    String? code,
    String? message,
  }) {
    return ImportException(
      code: code ?? this.code,
      message: message ?? this.message,
    );
  }
}
