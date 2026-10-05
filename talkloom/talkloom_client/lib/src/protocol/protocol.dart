/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:talkloom_client/src/protocol/evidence/evidence_event.dart'
    as _i4nm32oi;
import 'package:talkloom_client/src/protocol/lessons/lesson.dart' as _irv3hfbd;
import 'package:talkloom_client/src/protocol/sources/source.dart' as _ikpsvynv;
import 'evidence/evidence_event.dart' as _idx9o88s;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'learner/learner_state.dart' as _ihnw2h1r;
import 'lessons/lesson.dart' as _idiive9r;
import 'sources/source.dart' as _i78k1pe6;
export 'evidence/evidence_event.dart';
export 'greetings/greeting.dart';
export 'learner/learner_state.dart';
export 'lessons/lesson.dart';
export 'sources/source.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _idx9o88s.EvidenceEvent) {
      return _idx9o88s.EvidenceEvent.fromJson(data) as T;
    }
    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
    }
    if (t == _ihnw2h1r.LearnerState) {
      return _ihnw2h1r.LearnerState.fromJson(data) as T;
    }
    if (t == _idiive9r.Lesson) {
      return _idiive9r.Lesson.fromJson(data) as T;
    }
    if (t == _i78k1pe6.Source) {
      return _i78k1pe6.Source.fromJson(data) as T;
    }
    if (t == _isc.getType<_idx9o88s.EvidenceEvent?>()) {
      return (data != null ? _idx9o88s.EvidenceEvent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ihnw2h1r.LearnerState?>()) {
      return (data != null ? _ihnw2h1r.LearnerState.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_idiive9r.Lesson?>()) {
      return (data != null ? _idiive9r.Lesson.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i78k1pe6.Source?>()) {
      return (data != null ? _i78k1pe6.Source.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i4nm32oi.EvidenceEvent>) {
      return (data as List)
              .map((e) => deserialize<_i4nm32oi.EvidenceEvent>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_ikpsvynv.Source>) {
      return (data as List)
              .map((e) => deserialize<_ikpsvynv.Source>(e))
              .toList()
          as T;
    }
    if (t == List<_irv3hfbd.Lesson>) {
      return (data as List)
              .map((e) => deserialize<_irv3hfbd.Lesson>(e))
              .toList()
          as T;
    }
    try {
      return _iaic.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacc.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _idx9o88s.EvidenceEvent => 'EvidenceEvent',
      _izw8z7ou.Greeting => 'Greeting',
      _ihnw2h1r.LearnerState => 'LearnerState',
      _idiive9r.Lesson => 'Lesson',
      _i78k1pe6.Source => 'Source',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('talkloom.', '');
    }

    switch (data) {
      case _idx9o88s.EvidenceEvent():
        return 'EvidenceEvent';
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _ihnw2h1r.LearnerState():
        return 'LearnerState';
      case _idiive9r.Lesson():
        return 'Lesson';
      case _i78k1pe6.Source():
        return 'Source';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'EvidenceEvent') {
      return deserialize<_idx9o88s.EvidenceEvent>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
    }
    if (dataClassName == 'LearnerState') {
      return deserialize<_ihnw2h1r.LearnerState>(data['data']);
    }
    if (dataClassName == 'Lesson') {
      return deserialize<_idiive9r.Lesson>(data['data']);
    }
    if (dataClassName == 'Source') {
      return deserialize<_i78k1pe6.Source>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('talkloom', this);
    _iacc.Protocol().registerHostProtocol('talkloom', this);
  }

  @override
  String getModuleName() => 'talkloom';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
