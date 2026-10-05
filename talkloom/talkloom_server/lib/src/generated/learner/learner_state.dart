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
import 'package:talkloom_server/src/generated/protocol.dart' as _itiajcaj;

abstract class LearnerState
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
      recognizedWords: _itiajcaj.Protocol().deserialize<List<String>>(
        jsonSerialization['recognizedWords'],
      ),
      activeWords: _itiajcaj.Protocol().deserialize<List<String>>(
        jsonSerialization['activeWords'],
      ),
      grammarMastery: jsonSerialization['grammarMastery'] as String,
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = LearnerStateTable();

  static const db = LearnerStateRepository._();

  @override
  int? id;

  String userId;

  String targetLanguage;

  List<String> recognizedWords;

  List<String> activeWords;

  String grammarMastery;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [LearnerState]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static LearnerStateInclude include() {
    return LearnerStateInclude._();
  }

  static LearnerStateIncludeList includeList({
    _is.WhereExpressionBuilder<LearnerStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LearnerStateTable>? orderBy,
    _is.OrderByListBuilder<LearnerStateTable>? orderByList,
    LearnerStateInclude? include,
  }) {
    return LearnerStateIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LearnerState.t),
      orderByList: orderByList?.call(LearnerState.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class LearnerStateUpdateTable extends _is.UpdateTable<LearnerStateTable> {
  LearnerStateUpdateTable(super.table);

  _is.ColumnValue<String, String> userId(String value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<String, String> targetLanguage(String value) =>
      _is.ColumnValue(
        table.targetLanguage,
        value,
      );

  _is.ColumnValue<List<String>, List<String>> recognizedWords(
    List<String> value,
  ) => _is.ColumnValue(
    table.recognizedWords,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> activeWords(List<String> value) =>
      _is.ColumnValue(
        table.activeWords,
        value,
      );

  _is.ColumnValue<String, String> grammarMastery(String value) =>
      _is.ColumnValue(
        table.grammarMastery,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class LearnerStateTable extends _is.Table<int?> {
  LearnerStateTable({super.tableRelation}) : super(tableName: 'learner_state') {
    updateTable = LearnerStateUpdateTable(this);
    userId = _is.ColumnString(
      'userId',
      this,
    );
    targetLanguage = _is.ColumnString(
      'targetLanguage',
      this,
    );
    recognizedWords = _is.ColumnSerializable<List<String>>(
      'recognizedWords',
      this,
    );
    activeWords = _is.ColumnSerializable<List<String>>(
      'activeWords',
      this,
    );
    grammarMastery = _is.ColumnString(
      'grammarMastery',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final LearnerStateUpdateTable updateTable;

  late final _is.ColumnString userId;

  late final _is.ColumnString targetLanguage;

  late final _is.ColumnSerializable<List<String>> recognizedWords;

  late final _is.ColumnSerializable<List<String>> activeWords;

  late final _is.ColumnString grammarMastery;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    targetLanguage,
    recognizedWords,
    activeWords,
    grammarMastery,
    updatedAt,
  ];
}

class LearnerStateInclude extends _is.IncludeObject {
  LearnerStateInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => LearnerState.t;
}

class LearnerStateIncludeList extends _is.IncludeList {
  LearnerStateIncludeList._({
    _is.WhereExpressionBuilder<LearnerStateTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LearnerState.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => LearnerState.t;
}

class LearnerStateRepository {
  const LearnerStateRepository._();

  /// Returns a list of [LearnerState]s matching the given query parameters.
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
  Future<List<LearnerState>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LearnerStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LearnerStateTable>? orderBy,
    _is.OrderByListBuilder<LearnerStateTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LearnerState>(
      where: where?.call(LearnerState.t),
      orderBy: orderBy?.call(LearnerState.t),
      orderByList: orderByList?.call(LearnerState.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LearnerState] matching the given query parameters.
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
  Future<LearnerState?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LearnerStateTable>? where,
    int? offset,
    _is.OrderByBuilder<LearnerStateTable>? orderBy,
    _is.OrderByListBuilder<LearnerStateTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LearnerState>(
      where: where?.call(LearnerState.t),
      orderBy: orderBy?.call(LearnerState.t),
      orderByList: orderByList?.call(LearnerState.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LearnerState] by its [id] or null if no such row exists.
  Future<LearnerState?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LearnerState>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LearnerState]s in the list and returns the inserted rows.
  ///
  /// The returned [LearnerState]s will have their `id` fields set.
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
  Future<List<LearnerState>> insert(
    _is.DatabaseSession session,
    List<LearnerState> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<LearnerState>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [LearnerState] and returns the inserted row.
  ///
  /// The returned [LearnerState] will have its `id` field set.
  Future<LearnerState> insertRow(
    _is.DatabaseSession session,
    LearnerState row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<LearnerState>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [LearnerState]s in the list and returns the resulting rows.
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
  /// The returned [LearnerState]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LearnerState>> upsert(
    _is.DatabaseSession session,
    List<LearnerState> rows, {
    required _is.ColumnSelections<LearnerStateTable> conflictColumns,
    _is.ColumnSelections<LearnerStateTable>? updateColumns,
    _is.WhereExpressionBuilder<LearnerStateTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<LearnerState>(
      rows,
      conflictColumns: conflictColumns(LearnerState.t),
      updateColumns: updateColumns?.call(LearnerState.t),
      updateWhere: updateWhere?.call(LearnerState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [LearnerState] and returns the resulting row.
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
  /// The returned [LearnerState] will have its `id` field set.
  Future<LearnerState?> upsertRow(
    _is.DatabaseSession session,
    LearnerState row, {
    required _is.ColumnSelections<LearnerStateTable> conflictColumns,
    _is.ColumnSelections<LearnerStateTable>? updateColumns,
    _is.WhereExpressionBuilder<LearnerStateTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<LearnerState>(
      row,
      conflictColumns: conflictColumns(LearnerState.t),
      updateColumns: updateColumns?.call(LearnerState.t),
      updateWhere: updateWhere?.call(LearnerState.t),
      transaction: transaction,
    );
  }

  /// Updates all [LearnerState]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LearnerState>> update(
    _is.DatabaseSession session,
    List<LearnerState> rows, {
    _is.ColumnSelections<LearnerStateTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<LearnerState>(
      rows,
      columns: columns?.call(LearnerState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [LearnerState]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LearnerState> updateRow(
    _is.DatabaseSession session,
    LearnerState row, {
    _is.ColumnSelections<LearnerStateTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<LearnerState>(
      row,
      columns: columns?.call(LearnerState.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LearnerState] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LearnerState?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<LearnerStateUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<LearnerState>(
      id,
      columnValues: columnValues(LearnerState.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LearnerState]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LearnerState>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<LearnerStateUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<LearnerStateTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LearnerStateTable>? orderBy,
    _is.OrderByListBuilder<LearnerStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<LearnerState>(
      columnValues: columnValues(LearnerState.t.updateTable),
      where: where(LearnerState.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LearnerState.t),
      orderByList: orderByList?.call(LearnerState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [LearnerState]s in the list and returns the deleted rows.
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
  Future<List<LearnerState>> delete(
    _is.DatabaseSession session,
    List<LearnerState> rows, {
    _is.OrderByBuilder<LearnerStateTable>? orderBy,
    _is.OrderByListBuilder<LearnerStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<LearnerState>(
      rows,
      orderBy: orderBy?.call(LearnerState.t),
      orderByList: orderByList?.call(LearnerState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [LearnerState].
  Future<LearnerState> deleteRow(
    _is.DatabaseSession session,
    LearnerState row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LearnerState>(
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
  Future<List<LearnerState>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LearnerStateTable> where,
    _is.OrderByBuilder<LearnerStateTable>? orderBy,
    _is.OrderByListBuilder<LearnerStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<LearnerState>(
      where: where(LearnerState.t),
      orderBy: orderBy?.call(LearnerState.t),
      orderByList: orderByList?.call(LearnerState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LearnerStateTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<LearnerState>(
      where: where?.call(LearnerState.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LearnerState] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LearnerStateTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LearnerState>(
      where: where(LearnerState.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
