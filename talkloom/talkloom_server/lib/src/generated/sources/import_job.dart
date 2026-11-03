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

/// A background lesson import owned by one learner. The import endpoint
/// creates the row and schedules a Future Call that does the slow work, so the
/// request returns immediately and progress is pushed over a stream.
abstract class ImportJob
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ImportJob._({
    this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.targetLanguage,
    required this.supportLanguage,
    required this.cefrLevel,
    this.url,
    this.rawContent,
    String? stage,
    this.sourceId,
    this.lessonId,
    this.errorCode,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  }) : stage = stage ?? 'queued';

  factory ImportJob({
    int? id,
    String? userId,
    required String type,
    required String title,
    required String targetLanguage,
    required String supportLanguage,
    required String cefrLevel,
    String? url,
    String? rawContent,
    String? stage,
    int? sourceId,
    int? lessonId,
    String? errorCode,
    String? errorMessage,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ImportJobImpl;

  factory ImportJob.fromJson(Map<String, dynamic> jsonSerialization) {
    return ImportJob(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String?,
      type: jsonSerialization['type'] as String,
      title: jsonSerialization['title'] as String,
      targetLanguage: jsonSerialization['targetLanguage'] as String,
      supportLanguage: jsonSerialization['supportLanguage'] as String,
      cefrLevel: jsonSerialization['cefrLevel'] as String,
      url: jsonSerialization['url'] as String?,
      rawContent: jsonSerialization['rawContent'] as String?,
      stage: jsonSerialization['stage'] as String?,
      sourceId: jsonSerialization['sourceId'] as int?,
      lessonId: jsonSerialization['lessonId'] as int?,
      errorCode: jsonSerialization['errorCode'] as String?,
      errorMessage: jsonSerialization['errorMessage'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = ImportJobTable();

  static const db = ImportJobRepository._();

  @override
  int? id;

  String? userId;

  /// url, text, document, image or ocr.
  String type;

  String title;

  String targetLanguage;

  String supportLanguage;

  String cefrLevel;

  String? url;

  /// Pasted text or base64 media. Never sent back to clients.
  String? rawContent;

  /// queued, fetching, transcript, compiling, validating, saved or failed.
  String stage;

  int? sourceId;

  int? lessonId;

  String? errorCode;

  String? errorMessage;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ImportJob]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ImportJob copyWith({
    int? id,
    String? userId,
    String? type,
    String? title,
    String? targetLanguage,
    String? supportLanguage,
    String? cefrLevel,
    String? url,
    String? rawContent,
    String? stage,
    int? sourceId,
    int? lessonId,
    String? errorCode,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ImportJob',
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'type': type,
      'title': title,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'cefrLevel': cefrLevel,
      if (url != null) 'url': url,
      if (rawContent != null) 'rawContent': rawContent,
      'stage': stage,
      if (sourceId != null) 'sourceId': sourceId,
      if (lessonId != null) 'lessonId': lessonId,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ImportJob',
      if (id != null) 'id': id,
      'type': type,
      'title': title,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'cefrLevel': cefrLevel,
      if (url != null) 'url': url,
      'stage': stage,
      if (sourceId != null) 'sourceId': sourceId,
      if (lessonId != null) 'lessonId': lessonId,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ImportJobInclude include() {
    return ImportJobInclude._();
  }

  static ImportJobIncludeList includeList({
    _is.WhereExpressionBuilder<ImportJobTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ImportJobTable>? orderBy,
    _is.OrderByListBuilder<ImportJobTable>? orderByList,
    ImportJobInclude? include,
  }) {
    return ImportJobIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ImportJob.t),
      orderByList: orderByList?.call(ImportJob.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ImportJobImpl extends ImportJob {
  _ImportJobImpl({
    int? id,
    String? userId,
    required String type,
    required String title,
    required String targetLanguage,
    required String supportLanguage,
    required String cefrLevel,
    String? url,
    String? rawContent,
    String? stage,
    int? sourceId,
    int? lessonId,
    String? errorCode,
    String? errorMessage,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         type: type,
         title: title,
         targetLanguage: targetLanguage,
         supportLanguage: supportLanguage,
         cefrLevel: cefrLevel,
         url: url,
         rawContent: rawContent,
         stage: stage,
         sourceId: sourceId,
         lessonId: lessonId,
         errorCode: errorCode,
         errorMessage: errorMessage,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ImportJob]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ImportJob copyWith({
    Object? id = _Undefined,
    Object? userId = _Undefined,
    String? type,
    String? title,
    String? targetLanguage,
    String? supportLanguage,
    String? cefrLevel,
    Object? url = _Undefined,
    Object? rawContent = _Undefined,
    String? stage,
    Object? sourceId = _Undefined,
    Object? lessonId = _Undefined,
    Object? errorCode = _Undefined,
    Object? errorMessage = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ImportJob(
      id: id is int? ? id : this.id,
      userId: userId is String? ? userId : this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      supportLanguage: supportLanguage ?? this.supportLanguage,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      url: url is String? ? url : this.url,
      rawContent: rawContent is String? ? rawContent : this.rawContent,
      stage: stage ?? this.stage,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
      lessonId: lessonId is int? ? lessonId : this.lessonId,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ImportJobUpdateTable extends _is.UpdateTable<ImportJobTable> {
  ImportJobUpdateTable(super.table);

  _is.ColumnValue<String, String> userId(String? value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<String, String> type(String value) => _is.ColumnValue(
    table.type,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> targetLanguage(String value) =>
      _is.ColumnValue(
        table.targetLanguage,
        value,
      );

  _is.ColumnValue<String, String> supportLanguage(String value) =>
      _is.ColumnValue(
        table.supportLanguage,
        value,
      );

  _is.ColumnValue<String, String> cefrLevel(String value) => _is.ColumnValue(
    table.cefrLevel,
    value,
  );

  _is.ColumnValue<String, String> url(String? value) => _is.ColumnValue(
    table.url,
    value,
  );

  _is.ColumnValue<String, String> rawContent(String? value) => _is.ColumnValue(
    table.rawContent,
    value,
  );

  _is.ColumnValue<String, String> stage(String value) => _is.ColumnValue(
    table.stage,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int? value) => _is.ColumnValue(
    table.sourceId,
    value,
  );

  _is.ColumnValue<int, int> lessonId(int? value) => _is.ColumnValue(
    table.lessonId,
    value,
  );

  _is.ColumnValue<String, String> errorCode(String? value) => _is.ColumnValue(
    table.errorCode,
    value,
  );

  _is.ColumnValue<String, String> errorMessage(String? value) =>
      _is.ColumnValue(
        table.errorMessage,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class ImportJobTable extends _is.Table<int?> {
  ImportJobTable({super.tableRelation}) : super(tableName: 'import_jobs') {
    updateTable = ImportJobUpdateTable(this);
    userId = _is.ColumnString(
      'userId',
      this,
    );
    type = _is.ColumnString(
      'type',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    targetLanguage = _is.ColumnString(
      'targetLanguage',
      this,
    );
    supportLanguage = _is.ColumnString(
      'supportLanguage',
      this,
    );
    cefrLevel = _is.ColumnString(
      'cefrLevel',
      this,
    );
    url = _is.ColumnString(
      'url',
      this,
    );
    rawContent = _is.ColumnString(
      'rawContent',
      this,
    );
    stage = _is.ColumnString(
      'stage',
      this,
      hasDefault: true,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
    lessonId = _is.ColumnInt(
      'lessonId',
      this,
    );
    errorCode = _is.ColumnString(
      'errorCode',
      this,
    );
    errorMessage = _is.ColumnString(
      'errorMessage',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final ImportJobUpdateTable updateTable;

  late final _is.ColumnString userId;

  /// url, text, document, image or ocr.
  late final _is.ColumnString type;

  late final _is.ColumnString title;

  late final _is.ColumnString targetLanguage;

  late final _is.ColumnString supportLanguage;

  late final _is.ColumnString cefrLevel;

  late final _is.ColumnString url;

  /// Pasted text or base64 media. Never sent back to clients.
  late final _is.ColumnString rawContent;

  /// queued, fetching, transcript, compiling, validating, saved or failed.
  late final _is.ColumnString stage;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnInt lessonId;

  late final _is.ColumnString errorCode;

  late final _is.ColumnString errorMessage;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    type,
    title,
    targetLanguage,
    supportLanguage,
    cefrLevel,
    url,
    rawContent,
    stage,
    sourceId,
    lessonId,
    errorCode,
    errorMessage,
    createdAt,
    updatedAt,
  ];
}

class ImportJobInclude extends _is.IncludeObject {
  ImportJobInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ImportJob.t;
}

class ImportJobIncludeList extends _is.IncludeList {
  ImportJobIncludeList._({
    _is.WhereExpressionBuilder<ImportJobTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ImportJob.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ImportJob.t;
}

class ImportJobRepository {
  const ImportJobRepository._();

  /// Returns a list of [ImportJob]s matching the given query parameters.
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
  Future<List<ImportJob>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ImportJobTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ImportJobTable>? orderBy,
    _is.OrderByListBuilder<ImportJobTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ImportJob>(
      where: where?.call(ImportJob.t),
      orderBy: orderBy?.call(ImportJob.t),
      orderByList: orderByList?.call(ImportJob.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ImportJob] matching the given query parameters.
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
  Future<ImportJob?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ImportJobTable>? where,
    int? offset,
    _is.OrderByBuilder<ImportJobTable>? orderBy,
    _is.OrderByListBuilder<ImportJobTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ImportJob>(
      where: where?.call(ImportJob.t),
      orderBy: orderBy?.call(ImportJob.t),
      orderByList: orderByList?.call(ImportJob.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ImportJob] by its [id] or null if no such row exists.
  Future<ImportJob?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ImportJob>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ImportJob]s in the list and returns the inserted rows.
  ///
  /// The returned [ImportJob]s will have their `id` fields set.
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
  Future<List<ImportJob>> insert(
    _is.DatabaseSession session,
    List<ImportJob> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ImportJob>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ImportJob] and returns the inserted row.
  ///
  /// The returned [ImportJob] will have its `id` field set.
  Future<ImportJob> insertRow(
    _is.DatabaseSession session,
    ImportJob row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ImportJob>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ImportJob]s in the list and returns the resulting rows.
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
  /// The returned [ImportJob]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ImportJob>> upsert(
    _is.DatabaseSession session,
    List<ImportJob> rows, {
    required _is.ColumnSelections<ImportJobTable> conflictColumns,
    _is.ColumnSelections<ImportJobTable>? updateColumns,
    _is.WhereExpressionBuilder<ImportJobTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ImportJob>(
      rows,
      conflictColumns: conflictColumns(ImportJob.t),
      updateColumns: updateColumns?.call(ImportJob.t),
      updateWhere: updateWhere?.call(ImportJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ImportJob] and returns the resulting row.
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
  /// The returned [ImportJob] will have its `id` field set.
  Future<ImportJob?> upsertRow(
    _is.DatabaseSession session,
    ImportJob row, {
    required _is.ColumnSelections<ImportJobTable> conflictColumns,
    _is.ColumnSelections<ImportJobTable>? updateColumns,
    _is.WhereExpressionBuilder<ImportJobTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ImportJob>(
      row,
      conflictColumns: conflictColumns(ImportJob.t),
      updateColumns: updateColumns?.call(ImportJob.t),
      updateWhere: updateWhere?.call(ImportJob.t),
      transaction: transaction,
    );
  }

  /// Updates all [ImportJob]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ImportJob>> update(
    _is.DatabaseSession session,
    List<ImportJob> rows, {
    _is.ColumnSelections<ImportJobTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ImportJob>(
      rows,
      columns: columns?.call(ImportJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ImportJob]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ImportJob> updateRow(
    _is.DatabaseSession session,
    ImportJob row, {
    _is.ColumnSelections<ImportJobTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ImportJob>(
      row,
      columns: columns?.call(ImportJob.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ImportJob] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ImportJob?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ImportJobUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ImportJob>(
      id,
      columnValues: columnValues(ImportJob.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ImportJob]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ImportJob>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ImportJobUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ImportJobTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ImportJobTable>? orderBy,
    _is.OrderByListBuilder<ImportJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ImportJob>(
      columnValues: columnValues(ImportJob.t.updateTable),
      where: where(ImportJob.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ImportJob.t),
      orderByList: orderByList?.call(ImportJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ImportJob]s in the list and returns the deleted rows.
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
  Future<List<ImportJob>> delete(
    _is.DatabaseSession session,
    List<ImportJob> rows, {
    _is.OrderByBuilder<ImportJobTable>? orderBy,
    _is.OrderByListBuilder<ImportJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ImportJob>(
      rows,
      orderBy: orderBy?.call(ImportJob.t),
      orderByList: orderByList?.call(ImportJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ImportJob].
  Future<ImportJob> deleteRow(
    _is.DatabaseSession session,
    ImportJob row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ImportJob>(
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
  Future<List<ImportJob>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ImportJobTable> where,
    _is.OrderByBuilder<ImportJobTable>? orderBy,
    _is.OrderByListBuilder<ImportJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ImportJob>(
      where: where(ImportJob.t),
      orderBy: orderBy?.call(ImportJob.t),
      orderByList: orderByList?.call(ImportJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ImportJobTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ImportJob>(
      where: where?.call(ImportJob.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ImportJob] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ImportJobTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ImportJob>(
      where: where(ImportJob.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
