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

abstract class SourceTranslationChunk
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  SourceTranslationChunk._({
    this.id,
    required this.userId,
    required this.sourceId,
    required this.cacheKey,
    required this.supportLanguage,
    required this.mode,
    required this.segments,
    required this.createdAt,
  });

  factory SourceTranslationChunk({
    int? id,
    required String userId,
    required int sourceId,
    required String cacheKey,
    required String supportLanguage,
    required String mode,
    required String segments,
    required DateTime createdAt,
  }) = _SourceTranslationChunkImpl;

  factory SourceTranslationChunk.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SourceTranslationChunk(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      sourceId: jsonSerialization['sourceId'] as int,
      cacheKey: jsonSerialization['cacheKey'] as String,
      supportLanguage: jsonSerialization['supportLanguage'] as String,
      mode: jsonSerialization['mode'] as String,
      segments: jsonSerialization['segments'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = SourceTranslationChunkTable();

  static const db = SourceTranslationChunkRepository._();

  @override
  int? id;

  String userId;

  int sourceId;

  String cacheKey;

  String supportLanguage;

  String mode;

  String segments;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [SourceTranslationChunk]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SourceTranslationChunk copyWith({
    int? id,
    String? userId,
    int? sourceId,
    String? cacheKey,
    String? supportLanguage,
    String? mode,
    String? segments,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SourceTranslationChunk',
      if (id != null) 'id': id,
      'userId': userId,
      'sourceId': sourceId,
      'cacheKey': cacheKey,
      'supportLanguage': supportLanguage,
      'mode': mode,
      'segments': segments,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SourceTranslationChunk',
      if (id != null) 'id': id,
      'userId': userId,
      'sourceId': sourceId,
      'cacheKey': cacheKey,
      'supportLanguage': supportLanguage,
      'mode': mode,
      'segments': segments,
      'createdAt': createdAt.toJson(),
    };
  }

  static SourceTranslationChunkInclude include() {
    return SourceTranslationChunkInclude._();
  }

  static SourceTranslationChunkIncludeList includeList({
    _is.WhereExpressionBuilder<SourceTranslationChunkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SourceTranslationChunkTable>? orderBy,
    _is.OrderByListBuilder<SourceTranslationChunkTable>? orderByList,
    SourceTranslationChunkInclude? include,
  }) {
    return SourceTranslationChunkIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SourceTranslationChunk.t),
      orderByList: orderByList?.call(SourceTranslationChunk.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SourceTranslationChunkImpl extends SourceTranslationChunk {
  _SourceTranslationChunkImpl({
    int? id,
    required String userId,
    required int sourceId,
    required String cacheKey,
    required String supportLanguage,
    required String mode,
    required String segments,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         sourceId: sourceId,
         cacheKey: cacheKey,
         supportLanguage: supportLanguage,
         mode: mode,
         segments: segments,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SourceTranslationChunk]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SourceTranslationChunk copyWith({
    Object? id = _Undefined,
    String? userId,
    int? sourceId,
    String? cacheKey,
    String? supportLanguage,
    String? mode,
    String? segments,
    DateTime? createdAt,
  }) {
    return SourceTranslationChunk(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      sourceId: sourceId ?? this.sourceId,
      cacheKey: cacheKey ?? this.cacheKey,
      supportLanguage: supportLanguage ?? this.supportLanguage,
      mode: mode ?? this.mode,
      segments: segments ?? this.segments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SourceTranslationChunkUpdateTable
    extends _is.UpdateTable<SourceTranslationChunkTable> {
  SourceTranslationChunkUpdateTable(super.table);

  _is.ColumnValue<String, String> userId(String value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int value) => _is.ColumnValue(
    table.sourceId,
    value,
  );

  _is.ColumnValue<String, String> cacheKey(String value) => _is.ColumnValue(
    table.cacheKey,
    value,
  );

  _is.ColumnValue<String, String> supportLanguage(String value) =>
      _is.ColumnValue(
        table.supportLanguage,
        value,
      );

  _is.ColumnValue<String, String> mode(String value) => _is.ColumnValue(
    table.mode,
    value,
  );

  _is.ColumnValue<String, String> segments(String value) => _is.ColumnValue(
    table.segments,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class SourceTranslationChunkTable extends _is.Table<int?> {
  SourceTranslationChunkTable({super.tableRelation})
    : super(tableName: 'source_translation_chunk') {
    updateTable = SourceTranslationChunkUpdateTable(this);
    userId = _is.ColumnString(
      'userId',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
    cacheKey = _is.ColumnString(
      'cacheKey',
      this,
    );
    supportLanguage = _is.ColumnString(
      'supportLanguage',
      this,
    );
    mode = _is.ColumnString(
      'mode',
      this,
    );
    segments = _is.ColumnString(
      'segments',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final SourceTranslationChunkUpdateTable updateTable;

  late final _is.ColumnString userId;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnString cacheKey;

  late final _is.ColumnString supportLanguage;

  late final _is.ColumnString mode;

  late final _is.ColumnString segments;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    sourceId,
    cacheKey,
    supportLanguage,
    mode,
    segments,
    createdAt,
  ];
}

class SourceTranslationChunkInclude extends _is.IncludeObject {
  SourceTranslationChunkInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => SourceTranslationChunk.t;
}

class SourceTranslationChunkIncludeList extends _is.IncludeList {
  SourceTranslationChunkIncludeList._({
    _is.WhereExpressionBuilder<SourceTranslationChunkTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SourceTranslationChunk.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => SourceTranslationChunk.t;
}

class SourceTranslationChunkRepository {
  const SourceTranslationChunkRepository._();

  /// Returns a list of [SourceTranslationChunk]s matching the given query parameters.
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
  Future<List<SourceTranslationChunk>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SourceTranslationChunkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SourceTranslationChunkTable>? orderBy,
    _is.OrderByListBuilder<SourceTranslationChunkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SourceTranslationChunk>(
      where: where?.call(SourceTranslationChunk.t),
      orderBy: orderBy?.call(SourceTranslationChunk.t),
      orderByList: orderByList?.call(SourceTranslationChunk.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SourceTranslationChunk] matching the given query parameters.
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
  Future<SourceTranslationChunk?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SourceTranslationChunkTable>? where,
    int? offset,
    _is.OrderByBuilder<SourceTranslationChunkTable>? orderBy,
    _is.OrderByListBuilder<SourceTranslationChunkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SourceTranslationChunk>(
      where: where?.call(SourceTranslationChunk.t),
      orderBy: orderBy?.call(SourceTranslationChunk.t),
      orderByList: orderByList?.call(SourceTranslationChunk.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SourceTranslationChunk] by its [id] or null if no such row exists.
  Future<SourceTranslationChunk?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SourceTranslationChunk>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SourceTranslationChunk]s in the list and returns the inserted rows.
  ///
  /// The returned [SourceTranslationChunk]s will have their `id` fields set.
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
  Future<List<SourceTranslationChunk>> insert(
    _is.DatabaseSession session,
    List<SourceTranslationChunk> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SourceTranslationChunk>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SourceTranslationChunk] and returns the inserted row.
  ///
  /// The returned [SourceTranslationChunk] will have its `id` field set.
  Future<SourceTranslationChunk> insertRow(
    _is.DatabaseSession session,
    SourceTranslationChunk row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SourceTranslationChunk>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SourceTranslationChunk]s in the list and returns the resulting rows.
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
  /// The returned [SourceTranslationChunk]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SourceTranslationChunk>> upsert(
    _is.DatabaseSession session,
    List<SourceTranslationChunk> rows, {
    required _is.ColumnSelections<SourceTranslationChunkTable> conflictColumns,
    _is.ColumnSelections<SourceTranslationChunkTable>? updateColumns,
    _is.WhereExpressionBuilder<SourceTranslationChunkTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SourceTranslationChunk>(
      rows,
      conflictColumns: conflictColumns(SourceTranslationChunk.t),
      updateColumns: updateColumns?.call(SourceTranslationChunk.t),
      updateWhere: updateWhere?.call(SourceTranslationChunk.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SourceTranslationChunk] and returns the resulting row.
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
  /// The returned [SourceTranslationChunk] will have its `id` field set.
  Future<SourceTranslationChunk?> upsertRow(
    _is.DatabaseSession session,
    SourceTranslationChunk row, {
    required _is.ColumnSelections<SourceTranslationChunkTable> conflictColumns,
    _is.ColumnSelections<SourceTranslationChunkTable>? updateColumns,
    _is.WhereExpressionBuilder<SourceTranslationChunkTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SourceTranslationChunk>(
      row,
      conflictColumns: conflictColumns(SourceTranslationChunk.t),
      updateColumns: updateColumns?.call(SourceTranslationChunk.t),
      updateWhere: updateWhere?.call(SourceTranslationChunk.t),
      transaction: transaction,
    );
  }

  /// Updates all [SourceTranslationChunk]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SourceTranslationChunk>> update(
    _is.DatabaseSession session,
    List<SourceTranslationChunk> rows, {
    _is.ColumnSelections<SourceTranslationChunkTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SourceTranslationChunk>(
      rows,
      columns: columns?.call(SourceTranslationChunk.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SourceTranslationChunk]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SourceTranslationChunk> updateRow(
    _is.DatabaseSession session,
    SourceTranslationChunk row, {
    _is.ColumnSelections<SourceTranslationChunkTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SourceTranslationChunk>(
      row,
      columns: columns?.call(SourceTranslationChunk.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SourceTranslationChunk] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SourceTranslationChunk?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SourceTranslationChunkUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SourceTranslationChunk>(
      id,
      columnValues: columnValues(SourceTranslationChunk.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SourceTranslationChunk]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SourceTranslationChunk>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SourceTranslationChunkUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<SourceTranslationChunkTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SourceTranslationChunkTable>? orderBy,
    _is.OrderByListBuilder<SourceTranslationChunkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SourceTranslationChunk>(
      columnValues: columnValues(SourceTranslationChunk.t.updateTable),
      where: where(SourceTranslationChunk.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SourceTranslationChunk.t),
      orderByList: orderByList?.call(SourceTranslationChunk.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SourceTranslationChunk]s in the list and returns the deleted rows.
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
  Future<List<SourceTranslationChunk>> delete(
    _is.DatabaseSession session,
    List<SourceTranslationChunk> rows, {
    _is.OrderByBuilder<SourceTranslationChunkTable>? orderBy,
    _is.OrderByListBuilder<SourceTranslationChunkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SourceTranslationChunk>(
      rows,
      orderBy: orderBy?.call(SourceTranslationChunk.t),
      orderByList: orderByList?.call(SourceTranslationChunk.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SourceTranslationChunk].
  Future<SourceTranslationChunk> deleteRow(
    _is.DatabaseSession session,
    SourceTranslationChunk row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SourceTranslationChunk>(
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
  Future<List<SourceTranslationChunk>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SourceTranslationChunkTable> where,
    _is.OrderByBuilder<SourceTranslationChunkTable>? orderBy,
    _is.OrderByListBuilder<SourceTranslationChunkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SourceTranslationChunk>(
      where: where(SourceTranslationChunk.t),
      orderBy: orderBy?.call(SourceTranslationChunk.t),
      orderByList: orderByList?.call(SourceTranslationChunk.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SourceTranslationChunkTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SourceTranslationChunk>(
      where: where?.call(SourceTranslationChunk.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SourceTranslationChunk] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SourceTranslationChunkTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SourceTranslationChunk>(
      where: where(SourceTranslationChunk.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
