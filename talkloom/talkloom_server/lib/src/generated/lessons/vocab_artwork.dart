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
import 'dart:typed_data' as _idt;
import 'package:serverpod/serverpod.dart' as _is;

/// One house-style illustration per vocabulary lemma, shared across all
/// learners and languages. The style is locked server-side, so the same
/// word always renders the same picture everywhere. Server-side only:
/// clients receive bytes, never rows.
abstract class VocabArtwork
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  VocabArtwork._({
    this.id,
    required this.lemmaKey,
    required this.language,
    int? styleVersion,
    required this.mimeType,
    required this.artwork,
    int? hitCount,
    required this.createdAt,
    required this.lastUsedAt,
  }) : styleVersion = styleVersion ?? 1,
       hitCount = hitCount ?? 0;

  factory VocabArtwork({
    int? id,
    required String lemmaKey,
    required String language,
    int? styleVersion,
    required String mimeType,
    required _idt.ByteData artwork,
    int? hitCount,
    required DateTime createdAt,
    required DateTime lastUsedAt,
  }) = _VocabArtworkImpl;

  factory VocabArtwork.fromJson(Map<String, dynamic> jsonSerialization) {
    return VocabArtwork(
      id: jsonSerialization['id'] as int?,
      lemmaKey: jsonSerialization['lemmaKey'] as String,
      language: jsonSerialization['language'] as String,
      styleVersion: jsonSerialization['styleVersion'] as int?,
      mimeType: jsonSerialization['mimeType'] as String,
      artwork: _is.ByteDataJsonExtension.fromJson(jsonSerialization['artwork']),
      hitCount: jsonSerialization['hitCount'] as int?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastUsedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastUsedAt'],
      ),
    );
  }

  static final t = VocabArtworkTable();

  static const db = VocabArtworkRepository._();

  @override
  int? id;

  /// Lower-cased lemma; the cross-language dedupe key.
  String lemmaKey;

  /// Language the word was requested in (informational; art is shared).
  String language;

  /// Bumps when the house style changes; old rows are ignored, never migrated.
  int styleVersion;

  String mimeType;

  _idt.ByteData artwork;

  int hitCount;

  DateTime createdAt;

  DateTime lastUsedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [VocabArtwork]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VocabArtwork copyWith({
    int? id,
    String? lemmaKey,
    String? language,
    int? styleVersion,
    String? mimeType,
    _idt.ByteData? artwork,
    int? hitCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VocabArtwork',
      if (id != null) 'id': id,
      'lemmaKey': lemmaKey,
      'language': language,
      'styleVersion': styleVersion,
      'mimeType': mimeType,
      'artwork': artwork.toJson(),
      'hitCount': hitCount,
      'createdAt': createdAt.toJson(),
      'lastUsedAt': lastUsedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VocabArtwork',
      if (id != null) 'id': id,
      'lemmaKey': lemmaKey,
      'language': language,
      'styleVersion': styleVersion,
      'mimeType': mimeType,
      'artwork': artwork.toJson(),
      'hitCount': hitCount,
      'createdAt': createdAt.toJson(),
      'lastUsedAt': lastUsedAt.toJson(),
    };
  }

  static VocabArtworkInclude include() {
    return VocabArtworkInclude._();
  }

  static VocabArtworkIncludeList includeList({
    _is.WhereExpressionBuilder<VocabArtworkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VocabArtworkTable>? orderBy,
    _is.OrderByListBuilder<VocabArtworkTable>? orderByList,
    VocabArtworkInclude? include,
  }) {
    return VocabArtworkIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VocabArtwork.t),
      orderByList: orderByList?.call(VocabArtwork.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VocabArtworkImpl extends VocabArtwork {
  _VocabArtworkImpl({
    int? id,
    required String lemmaKey,
    required String language,
    int? styleVersion,
    required String mimeType,
    required _idt.ByteData artwork,
    int? hitCount,
    required DateTime createdAt,
    required DateTime lastUsedAt,
  }) : super._(
         id: id,
         lemmaKey: lemmaKey,
         language: language,
         styleVersion: styleVersion,
         mimeType: mimeType,
         artwork: artwork,
         hitCount: hitCount,
         createdAt: createdAt,
         lastUsedAt: lastUsedAt,
       );

  /// Returns a shallow copy of this [VocabArtwork]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VocabArtwork copyWith({
    Object? id = _Undefined,
    String? lemmaKey,
    String? language,
    int? styleVersion,
    String? mimeType,
    _idt.ByteData? artwork,
    int? hitCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return VocabArtwork(
      id: id is int? ? id : this.id,
      lemmaKey: lemmaKey ?? this.lemmaKey,
      language: language ?? this.language,
      styleVersion: styleVersion ?? this.styleVersion,
      mimeType: mimeType ?? this.mimeType,
      artwork: artwork ?? this.artwork.clone(),
      hitCount: hitCount ?? this.hitCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

class VocabArtworkUpdateTable extends _is.UpdateTable<VocabArtworkTable> {
  VocabArtworkUpdateTable(super.table);

  _is.ColumnValue<String, String> lemmaKey(String value) => _is.ColumnValue(
    table.lemmaKey,
    value,
  );

  _is.ColumnValue<String, String> language(String value) => _is.ColumnValue(
    table.language,
    value,
  );

  _is.ColumnValue<int, int> styleVersion(int value) => _is.ColumnValue(
    table.styleVersion,
    value,
  );

  _is.ColumnValue<String, String> mimeType(String value) => _is.ColumnValue(
    table.mimeType,
    value,
  );

  _is.ColumnValue<_idt.ByteData, _idt.ByteData> artwork(_idt.ByteData value) =>
      _is.ColumnValue(
        table.artwork,
        value,
      );

  _is.ColumnValue<int, int> hitCount(int value) => _is.ColumnValue(
    table.hitCount,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> lastUsedAt(DateTime value) =>
      _is.ColumnValue(
        table.lastUsedAt,
        value,
      );
}

class VocabArtworkTable extends _is.Table<int?> {
  VocabArtworkTable({super.tableRelation})
    : super(tableName: 'vocab_artworks') {
    updateTable = VocabArtworkUpdateTable(this);
    lemmaKey = _is.ColumnString(
      'lemmaKey',
      this,
    );
    language = _is.ColumnString(
      'language',
      this,
    );
    styleVersion = _is.ColumnInt(
      'styleVersion',
      this,
      hasDefault: true,
    );
    mimeType = _is.ColumnString(
      'mimeType',
      this,
    );
    artwork = _is.ColumnByteData(
      'artwork',
      this,
    );
    hitCount = _is.ColumnInt(
      'hitCount',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    lastUsedAt = _is.ColumnDateTime(
      'lastUsedAt',
      this,
    );
  }

  late final VocabArtworkUpdateTable updateTable;

  /// Lower-cased lemma; the cross-language dedupe key.
  late final _is.ColumnString lemmaKey;

  /// Language the word was requested in (informational; art is shared).
  late final _is.ColumnString language;

  /// Bumps when the house style changes; old rows are ignored, never migrated.
  late final _is.ColumnInt styleVersion;

  late final _is.ColumnString mimeType;

  late final _is.ColumnByteData artwork;

  late final _is.ColumnInt hitCount;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime lastUsedAt;

  @override
  List<_is.Column> get columns => [
    id,
    lemmaKey,
    language,
    styleVersion,
    mimeType,
    artwork,
    hitCount,
    createdAt,
    lastUsedAt,
  ];
}

class VocabArtworkInclude extends _is.IncludeObject {
  VocabArtworkInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => VocabArtwork.t;
}

class VocabArtworkIncludeList extends _is.IncludeList {
  VocabArtworkIncludeList._({
    _is.WhereExpressionBuilder<VocabArtworkTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(VocabArtwork.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => VocabArtwork.t;
}

class VocabArtworkRepository {
  const VocabArtworkRepository._();

  /// Returns a list of [VocabArtwork]s matching the given query parameters.
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
  Future<List<VocabArtwork>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VocabArtworkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VocabArtworkTable>? orderBy,
    _is.OrderByListBuilder<VocabArtworkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<VocabArtwork>(
      where: where?.call(VocabArtwork.t),
      orderBy: orderBy?.call(VocabArtwork.t),
      orderByList: orderByList?.call(VocabArtwork.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [VocabArtwork] matching the given query parameters.
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
  Future<VocabArtwork?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VocabArtworkTable>? where,
    int? offset,
    _is.OrderByBuilder<VocabArtworkTable>? orderBy,
    _is.OrderByListBuilder<VocabArtworkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<VocabArtwork>(
      where: where?.call(VocabArtwork.t),
      orderBy: orderBy?.call(VocabArtwork.t),
      orderByList: orderByList?.call(VocabArtwork.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [VocabArtwork] by its [id] or null if no such row exists.
  Future<VocabArtwork?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<VocabArtwork>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [VocabArtwork]s in the list and returns the inserted rows.
  ///
  /// The returned [VocabArtwork]s will have their `id` fields set.
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
  Future<List<VocabArtwork>> insert(
    _is.DatabaseSession session,
    List<VocabArtwork> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<VocabArtwork>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [VocabArtwork] and returns the inserted row.
  ///
  /// The returned [VocabArtwork] will have its `id` field set.
  Future<VocabArtwork> insertRow(
    _is.DatabaseSession session,
    VocabArtwork row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<VocabArtwork>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [VocabArtwork]s in the list and returns the resulting rows.
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
  /// The returned [VocabArtwork]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VocabArtwork>> upsert(
    _is.DatabaseSession session,
    List<VocabArtwork> rows, {
    required _is.ColumnSelections<VocabArtworkTable> conflictColumns,
    _is.ColumnSelections<VocabArtworkTable>? updateColumns,
    _is.WhereExpressionBuilder<VocabArtworkTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<VocabArtwork>(
      rows,
      conflictColumns: conflictColumns(VocabArtwork.t),
      updateColumns: updateColumns?.call(VocabArtwork.t),
      updateWhere: updateWhere?.call(VocabArtwork.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [VocabArtwork] and returns the resulting row.
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
  /// The returned [VocabArtwork] will have its `id` field set.
  Future<VocabArtwork?> upsertRow(
    _is.DatabaseSession session,
    VocabArtwork row, {
    required _is.ColumnSelections<VocabArtworkTable> conflictColumns,
    _is.ColumnSelections<VocabArtworkTable>? updateColumns,
    _is.WhereExpressionBuilder<VocabArtworkTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<VocabArtwork>(
      row,
      conflictColumns: conflictColumns(VocabArtwork.t),
      updateColumns: updateColumns?.call(VocabArtwork.t),
      updateWhere: updateWhere?.call(VocabArtwork.t),
      transaction: transaction,
    );
  }

  /// Updates all [VocabArtwork]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VocabArtwork>> update(
    _is.DatabaseSession session,
    List<VocabArtwork> rows, {
    _is.ColumnSelections<VocabArtworkTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<VocabArtwork>(
      rows,
      columns: columns?.call(VocabArtwork.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [VocabArtwork]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<VocabArtwork> updateRow(
    _is.DatabaseSession session,
    VocabArtwork row, {
    _is.ColumnSelections<VocabArtworkTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<VocabArtwork>(
      row,
      columns: columns?.call(VocabArtwork.t),
      transaction: transaction,
    );
  }

  /// Updates a single [VocabArtwork] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<VocabArtwork?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<VocabArtworkUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<VocabArtwork>(
      id,
      columnValues: columnValues(VocabArtwork.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [VocabArtwork]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VocabArtwork>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<VocabArtworkUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<VocabArtworkTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VocabArtworkTable>? orderBy,
    _is.OrderByListBuilder<VocabArtworkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<VocabArtwork>(
      columnValues: columnValues(VocabArtwork.t.updateTable),
      where: where(VocabArtwork.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VocabArtwork.t),
      orderByList: orderByList?.call(VocabArtwork.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [VocabArtwork]s in the list and returns the deleted rows.
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
  Future<List<VocabArtwork>> delete(
    _is.DatabaseSession session,
    List<VocabArtwork> rows, {
    _is.OrderByBuilder<VocabArtworkTable>? orderBy,
    _is.OrderByListBuilder<VocabArtworkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<VocabArtwork>(
      rows,
      orderBy: orderBy?.call(VocabArtwork.t),
      orderByList: orderByList?.call(VocabArtwork.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [VocabArtwork].
  Future<VocabArtwork> deleteRow(
    _is.DatabaseSession session,
    VocabArtwork row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<VocabArtwork>(
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
  Future<List<VocabArtwork>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VocabArtworkTable> where,
    _is.OrderByBuilder<VocabArtworkTable>? orderBy,
    _is.OrderByListBuilder<VocabArtworkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<VocabArtwork>(
      where: where(VocabArtwork.t),
      orderBy: orderBy?.call(VocabArtwork.t),
      orderByList: orderByList?.call(VocabArtwork.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VocabArtworkTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<VocabArtwork>(
      where: where?.call(VocabArtwork.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [VocabArtwork] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VocabArtworkTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<VocabArtwork>(
      where: where(VocabArtwork.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
