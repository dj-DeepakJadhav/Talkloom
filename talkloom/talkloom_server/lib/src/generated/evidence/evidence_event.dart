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

abstract class EvidenceEvent
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
      spontaneous: _is.BoolJsonExtension.fromJson(
        jsonSerialization['spontaneous'],
      ),
      correct: _is.BoolJsonExtension.fromJson(jsonSerialization['correct']),
      timestamp: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['timestamp'],
      ),
    );
  }

  static final t = EvidenceEventTable();

  static const db = EvidenceEventRepository._();

  @override
  int? id;

  String userId;

  String targetLanguage;

  String itemId;

  String activityType;

  String supportLevel;

  bool spontaneous;

  bool correct;

  DateTime timestamp;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [EvidenceEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static EvidenceEventInclude include() {
    return EvidenceEventInclude._();
  }

  static EvidenceEventIncludeList includeList({
    _is.WhereExpressionBuilder<EvidenceEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceEventTable>? orderBy,
    _is.OrderByListBuilder<EvidenceEventTable>? orderByList,
    EvidenceEventInclude? include,
  }) {
    return EvidenceEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceEvent.t),
      orderByList: orderByList?.call(EvidenceEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class EvidenceEventUpdateTable extends _is.UpdateTable<EvidenceEventTable> {
  EvidenceEventUpdateTable(super.table);

  _is.ColumnValue<String, String> userId(String value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<String, String> targetLanguage(String value) =>
      _is.ColumnValue(
        table.targetLanguage,
        value,
      );

  _is.ColumnValue<String, String> itemId(String value) => _is.ColumnValue(
    table.itemId,
    value,
  );

  _is.ColumnValue<String, String> activityType(String value) => _is.ColumnValue(
    table.activityType,
    value,
  );

  _is.ColumnValue<String, String> supportLevel(String value) => _is.ColumnValue(
    table.supportLevel,
    value,
  );

  _is.ColumnValue<bool, bool> spontaneous(bool value) => _is.ColumnValue(
    table.spontaneous,
    value,
  );

  _is.ColumnValue<bool, bool> correct(bool value) => _is.ColumnValue(
    table.correct,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> timestamp(DateTime value) =>
      _is.ColumnValue(
        table.timestamp,
        value,
      );
}

class EvidenceEventTable extends _is.Table<int?> {
  EvidenceEventTable({super.tableRelation})
    : super(tableName: 'evidence_events') {
    updateTable = EvidenceEventUpdateTable(this);
    userId = _is.ColumnString(
      'userId',
      this,
    );
    targetLanguage = _is.ColumnString(
      'targetLanguage',
      this,
    );
    itemId = _is.ColumnString(
      'itemId',
      this,
    );
    activityType = _is.ColumnString(
      'activityType',
      this,
    );
    supportLevel = _is.ColumnString(
      'supportLevel',
      this,
    );
    spontaneous = _is.ColumnBool(
      'spontaneous',
      this,
    );
    correct = _is.ColumnBool(
      'correct',
      this,
    );
    timestamp = _is.ColumnDateTime(
      'timestamp',
      this,
    );
  }

  late final EvidenceEventUpdateTable updateTable;

  late final _is.ColumnString userId;

  late final _is.ColumnString targetLanguage;

  late final _is.ColumnString itemId;

  late final _is.ColumnString activityType;

  late final _is.ColumnString supportLevel;

  late final _is.ColumnBool spontaneous;

  late final _is.ColumnBool correct;

  late final _is.ColumnDateTime timestamp;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    targetLanguage,
    itemId,
    activityType,
    supportLevel,
    spontaneous,
    correct,
    timestamp,
  ];
}

class EvidenceEventInclude extends _is.IncludeObject {
  EvidenceEventInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => EvidenceEvent.t;
}

class EvidenceEventIncludeList extends _is.IncludeList {
  EvidenceEventIncludeList._({
    _is.WhereExpressionBuilder<EvidenceEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EvidenceEvent.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => EvidenceEvent.t;
}

class EvidenceEventRepository {
  const EvidenceEventRepository._();

  /// Returns a list of [EvidenceEvent]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<EvidenceEvent>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceEventTable>? orderBy,
    _is.OrderByListBuilder<EvidenceEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EvidenceEvent>(
      where: where?.call(EvidenceEvent.t),
      orderBy: orderBy?.call(EvidenceEvent.t),
      orderByList: orderByList?.call(EvidenceEvent.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [EvidenceEvent] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<EvidenceEvent?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceEventTable>? where,
    int? offset,
    _is.OrderByBuilder<EvidenceEventTable>? orderBy,
    _is.OrderByListBuilder<EvidenceEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EvidenceEvent>(
      where: where?.call(EvidenceEvent.t),
      orderBy: orderBy?.call(EvidenceEvent.t),
      orderByList: orderByList?.call(EvidenceEvent.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EvidenceEvent] by its [id] or null if no such row exists.
  Future<EvidenceEvent?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EvidenceEvent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EvidenceEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [EvidenceEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceEvent>> insert(
    _is.DatabaseSession session,
    List<EvidenceEvent> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<EvidenceEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [EvidenceEvent] and returns the inserted row.
  ///
  /// The returned [EvidenceEvent] will have its `id` field set.
  Future<EvidenceEvent> insertRow(
    _is.DatabaseSession session,
    EvidenceEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<EvidenceEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [EvidenceEvent]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [EvidenceEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceEvent>> upsert(
    _is.DatabaseSession session,
    List<EvidenceEvent> rows, {
    required _is.ColumnSelections<EvidenceEventTable> conflictColumns,
    _is.ColumnSelections<EvidenceEventTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceEventTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<EvidenceEvent>(
      rows,
      conflictColumns: conflictColumns(EvidenceEvent.t),
      updateColumns: updateColumns?.call(EvidenceEvent.t),
      updateWhere: updateWhere?.call(EvidenceEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [EvidenceEvent] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [EvidenceEvent] will have its `id` field set.
  Future<EvidenceEvent?> upsertRow(
    _is.DatabaseSession session,
    EvidenceEvent row, {
    required _is.ColumnSelections<EvidenceEventTable> conflictColumns,
    _is.ColumnSelections<EvidenceEventTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceEventTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<EvidenceEvent>(
      row,
      conflictColumns: conflictColumns(EvidenceEvent.t),
      updateColumns: updateColumns?.call(EvidenceEvent.t),
      updateWhere: updateWhere?.call(EvidenceEvent.t),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceEvent>> update(
    _is.DatabaseSession session,
    List<EvidenceEvent> rows, {
    _is.ColumnSelections<EvidenceEventTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<EvidenceEvent>(
      rows,
      columns: columns?.call(EvidenceEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [EvidenceEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EvidenceEvent> updateRow(
    _is.DatabaseSession session,
    EvidenceEvent row, {
    _is.ColumnSelections<EvidenceEventTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<EvidenceEvent>(
      row,
      columns: columns?.call(EvidenceEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EvidenceEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EvidenceEvent?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<EvidenceEventUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<EvidenceEvent>(
      id,
      columnValues: columnValues(EvidenceEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceEvent>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<EvidenceEventUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<EvidenceEventTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceEventTable>? orderBy,
    _is.OrderByListBuilder<EvidenceEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<EvidenceEvent>(
      columnValues: columnValues(EvidenceEvent.t.updateTable),
      where: where(EvidenceEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceEvent.t),
      orderByList: orderByList?.call(EvidenceEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [EvidenceEvent]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceEvent>> delete(
    _is.DatabaseSession session,
    List<EvidenceEvent> rows, {
    _is.OrderByBuilder<EvidenceEventTable>? orderBy,
    _is.OrderByListBuilder<EvidenceEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<EvidenceEvent>(
      rows,
      orderBy: orderBy?.call(EvidenceEvent.t),
      orderByList: orderByList?.call(EvidenceEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [EvidenceEvent].
  Future<EvidenceEvent> deleteRow(
    _is.DatabaseSession session,
    EvidenceEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EvidenceEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceEvent>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceEventTable> where,
    _is.OrderByBuilder<EvidenceEventTable>? orderBy,
    _is.OrderByListBuilder<EvidenceEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<EvidenceEvent>(
      where: where(EvidenceEvent.t),
      orderBy: orderBy?.call(EvidenceEvent.t),
      orderByList: orderByList?.call(EvidenceEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceEventTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<EvidenceEvent>(
      where: where?.call(EvidenceEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EvidenceEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceEventTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EvidenceEvent>(
      where: where(EvidenceEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
