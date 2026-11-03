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

/// Independent semantic evaluation of one learner speaking turn against the
/// source-linked targets of a lesson the learner owns. Written only by the
/// server; the tutor reply is never used as evidence.
abstract class TurnEvaluation
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TurnEvaluation._({
    this.id,
    this.userId,
    required this.targetLanguage,
    required this.lessonId,
    this.learnerUtterance,
    required this.status,
    this.provider,
    this.model,
    this.reason,
    required this.results,
    required this.createdAt,
  });

  factory TurnEvaluation({
    int? id,
    String? userId,
    required String targetLanguage,
    required int lessonId,
    String? learnerUtterance,
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
      userId: jsonSerialization['userId'] as String?,
      targetLanguage: jsonSerialization['targetLanguage'] as String,
      lessonId: jsonSerialization['lessonId'] as int,
      learnerUtterance: jsonSerialization['learnerUtterance'] as String?,
      status: jsonSerialization['status'] as String,
      provider: jsonSerialization['provider'] as String?,
      model: jsonSerialization['model'] as String?,
      reason: jsonSerialization['reason'] as String?,
      results: jsonSerialization['results'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = TurnEvaluationTable();

  static const db = TurnEvaluationRepository._();

  @override
  int? id;

  String? userId;

  String targetLanguage;

  int lessonId;

  /// The learner utterance that was judged.
  String? learnerUtterance;

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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TurnEvaluation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TurnEvaluation copyWith({
    int? id,
    String? userId,
    String? targetLanguage,
    int? lessonId,
    String? learnerUtterance,
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
      if (userId != null) 'userId': userId,
      'targetLanguage': targetLanguage,
      'lessonId': lessonId,
      if (learnerUtterance != null) 'learnerUtterance': learnerUtterance,
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

  static TurnEvaluationInclude include() {
    return TurnEvaluationInclude._();
  }

  static TurnEvaluationIncludeList includeList({
    _is.WhereExpressionBuilder<TurnEvaluationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TurnEvaluationTable>? orderBy,
    _is.OrderByListBuilder<TurnEvaluationTable>? orderByList,
    TurnEvaluationInclude? include,
  }) {
    return TurnEvaluationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TurnEvaluation.t),
      orderByList: orderByList?.call(TurnEvaluation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TurnEvaluationImpl extends TurnEvaluation {
  _TurnEvaluationImpl({
    int? id,
    String? userId,
    required String targetLanguage,
    required int lessonId,
    String? learnerUtterance,
    required String status,
    String? provider,
    String? model,
    String? reason,
    required String results,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         targetLanguage: targetLanguage,
         lessonId: lessonId,
         learnerUtterance: learnerUtterance,
         status: status,
         provider: provider,
         model: model,
         reason: reason,
         results: results,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TurnEvaluation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TurnEvaluation copyWith({
    Object? id = _Undefined,
    Object? userId = _Undefined,
    String? targetLanguage,
    int? lessonId,
    Object? learnerUtterance = _Undefined,
    String? status,
    Object? provider = _Undefined,
    Object? model = _Undefined,
    Object? reason = _Undefined,
    String? results,
    DateTime? createdAt,
  }) {
    return TurnEvaluation(
      id: id is int? ? id : this.id,
      userId: userId is String? ? userId : this.userId,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      lessonId: lessonId ?? this.lessonId,
      learnerUtterance: learnerUtterance is String?
          ? learnerUtterance
          : this.learnerUtterance,
      status: status ?? this.status,
      provider: provider is String? ? provider : this.provider,
      model: model is String? ? model : this.model,
      reason: reason is String? ? reason : this.reason,
      results: results ?? this.results,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TurnEvaluationUpdateTable extends _is.UpdateTable<TurnEvaluationTable> {
  TurnEvaluationUpdateTable(super.table);

  _is.ColumnValue<String, String> userId(String? value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<String, String> targetLanguage(String value) =>
      _is.ColumnValue(
        table.targetLanguage,
        value,
      );

  _is.ColumnValue<int, int> lessonId(int value) => _is.ColumnValue(
    table.lessonId,
    value,
  );

  _is.ColumnValue<String, String> learnerUtterance(String? value) =>
      _is.ColumnValue(
        table.learnerUtterance,
        value,
      );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> provider(String? value) => _is.ColumnValue(
    table.provider,
    value,
  );

  _is.ColumnValue<String, String> model(String? value) => _is.ColumnValue(
    table.model,
    value,
  );

  _is.ColumnValue<String, String> reason(String? value) => _is.ColumnValue(
    table.reason,
    value,
  );

  _is.ColumnValue<String, String> results(String value) => _is.ColumnValue(
    table.results,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class TurnEvaluationTable extends _is.Table<int?> {
  TurnEvaluationTable({super.tableRelation})
    : super(tableName: 'turn_evaluations') {
    updateTable = TurnEvaluationUpdateTable(this);
    userId = _is.ColumnString(
      'userId',
      this,
    );
    targetLanguage = _is.ColumnString(
      'targetLanguage',
      this,
    );
    lessonId = _is.ColumnInt(
      'lessonId',
      this,
    );
    learnerUtterance = _is.ColumnString(
      'learnerUtterance',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    provider = _is.ColumnString(
      'provider',
      this,
    );
    model = _is.ColumnString(
      'model',
      this,
    );
    reason = _is.ColumnString(
      'reason',
      this,
    );
    results = _is.ColumnString(
      'results',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final TurnEvaluationUpdateTable updateTable;

  late final _is.ColumnString userId;

  late final _is.ColumnString targetLanguage;

  late final _is.ColumnInt lessonId;

  /// The learner utterance that was judged.
  late final _is.ColumnString learnerUtterance;

  /// evaluated, evaluator_unavailable or assisted.
  late final _is.ColumnString status;

  /// Evaluator provider and model, null when no evaluator call was made.
  late final _is.ColumnString provider;

  late final _is.ColumnString model;

  /// Safe reason when status is not evaluated (no_provider_key,
  /// provider_error, malformed_output, tutor_assisted).
  late final _is.ColumnString reason;

  /// JSON list of per-target judgements:
  /// {itemId, kind, used, correct, inContext, spontaneous, eligible}.
  late final _is.ColumnString results;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    targetLanguage,
    lessonId,
    learnerUtterance,
    status,
    provider,
    model,
    reason,
    results,
    createdAt,
  ];
}

class TurnEvaluationInclude extends _is.IncludeObject {
  TurnEvaluationInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TurnEvaluation.t;
}

class TurnEvaluationIncludeList extends _is.IncludeList {
  TurnEvaluationIncludeList._({
    _is.WhereExpressionBuilder<TurnEvaluationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TurnEvaluation.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TurnEvaluation.t;
}

class TurnEvaluationRepository {
  const TurnEvaluationRepository._();

  /// Returns a list of [TurnEvaluation]s matching the given query parameters.
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
  Future<List<TurnEvaluation>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TurnEvaluationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TurnEvaluationTable>? orderBy,
    _is.OrderByListBuilder<TurnEvaluationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TurnEvaluation>(
      where: where?.call(TurnEvaluation.t),
      orderBy: orderBy?.call(TurnEvaluation.t),
      orderByList: orderByList?.call(TurnEvaluation.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TurnEvaluation] matching the given query parameters.
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
  Future<TurnEvaluation?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TurnEvaluationTable>? where,
    int? offset,
    _is.OrderByBuilder<TurnEvaluationTable>? orderBy,
    _is.OrderByListBuilder<TurnEvaluationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TurnEvaluation>(
      where: where?.call(TurnEvaluation.t),
      orderBy: orderBy?.call(TurnEvaluation.t),
      orderByList: orderByList?.call(TurnEvaluation.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TurnEvaluation] by its [id] or null if no such row exists.
  Future<TurnEvaluation?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TurnEvaluation>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TurnEvaluation]s in the list and returns the inserted rows.
  ///
  /// The returned [TurnEvaluation]s will have their `id` fields set.
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
  Future<List<TurnEvaluation>> insert(
    _is.DatabaseSession session,
    List<TurnEvaluation> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TurnEvaluation>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TurnEvaluation] and returns the inserted row.
  ///
  /// The returned [TurnEvaluation] will have its `id` field set.
  Future<TurnEvaluation> insertRow(
    _is.DatabaseSession session,
    TurnEvaluation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TurnEvaluation>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TurnEvaluation]s in the list and returns the resulting rows.
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
  /// The returned [TurnEvaluation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TurnEvaluation>> upsert(
    _is.DatabaseSession session,
    List<TurnEvaluation> rows, {
    required _is.ColumnSelections<TurnEvaluationTable> conflictColumns,
    _is.ColumnSelections<TurnEvaluationTable>? updateColumns,
    _is.WhereExpressionBuilder<TurnEvaluationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TurnEvaluation>(
      rows,
      conflictColumns: conflictColumns(TurnEvaluation.t),
      updateColumns: updateColumns?.call(TurnEvaluation.t),
      updateWhere: updateWhere?.call(TurnEvaluation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TurnEvaluation] and returns the resulting row.
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
  /// The returned [TurnEvaluation] will have its `id` field set.
  Future<TurnEvaluation?> upsertRow(
    _is.DatabaseSession session,
    TurnEvaluation row, {
    required _is.ColumnSelections<TurnEvaluationTable> conflictColumns,
    _is.ColumnSelections<TurnEvaluationTable>? updateColumns,
    _is.WhereExpressionBuilder<TurnEvaluationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TurnEvaluation>(
      row,
      conflictColumns: conflictColumns(TurnEvaluation.t),
      updateColumns: updateColumns?.call(TurnEvaluation.t),
      updateWhere: updateWhere?.call(TurnEvaluation.t),
      transaction: transaction,
    );
  }

  /// Updates all [TurnEvaluation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TurnEvaluation>> update(
    _is.DatabaseSession session,
    List<TurnEvaluation> rows, {
    _is.ColumnSelections<TurnEvaluationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TurnEvaluation>(
      rows,
      columns: columns?.call(TurnEvaluation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TurnEvaluation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TurnEvaluation> updateRow(
    _is.DatabaseSession session,
    TurnEvaluation row, {
    _is.ColumnSelections<TurnEvaluationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TurnEvaluation>(
      row,
      columns: columns?.call(TurnEvaluation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TurnEvaluation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TurnEvaluation?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TurnEvaluationUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TurnEvaluation>(
      id,
      columnValues: columnValues(TurnEvaluation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TurnEvaluation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TurnEvaluation>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TurnEvaluationUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TurnEvaluationTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TurnEvaluationTable>? orderBy,
    _is.OrderByListBuilder<TurnEvaluationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TurnEvaluation>(
      columnValues: columnValues(TurnEvaluation.t.updateTable),
      where: where(TurnEvaluation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TurnEvaluation.t),
      orderByList: orderByList?.call(TurnEvaluation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TurnEvaluation]s in the list and returns the deleted rows.
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
  Future<List<TurnEvaluation>> delete(
    _is.DatabaseSession session,
    List<TurnEvaluation> rows, {
    _is.OrderByBuilder<TurnEvaluationTable>? orderBy,
    _is.OrderByListBuilder<TurnEvaluationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TurnEvaluation>(
      rows,
      orderBy: orderBy?.call(TurnEvaluation.t),
      orderByList: orderByList?.call(TurnEvaluation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TurnEvaluation].
  Future<TurnEvaluation> deleteRow(
    _is.DatabaseSession session,
    TurnEvaluation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TurnEvaluation>(
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
  Future<List<TurnEvaluation>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TurnEvaluationTable> where,
    _is.OrderByBuilder<TurnEvaluationTable>? orderBy,
    _is.OrderByListBuilder<TurnEvaluationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TurnEvaluation>(
      where: where(TurnEvaluation.t),
      orderBy: orderBy?.call(TurnEvaluation.t),
      orderByList: orderByList?.call(TurnEvaluation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TurnEvaluationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TurnEvaluation>(
      where: where?.call(TurnEvaluation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TurnEvaluation] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TurnEvaluationTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TurnEvaluation>(
      where: where(TurnEvaluation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
