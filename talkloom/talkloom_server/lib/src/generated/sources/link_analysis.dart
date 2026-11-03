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

/// The shared, learner-independent result of analysing one public link for one
/// language pair and level. Any learner who imports the same link reuses this
/// row instead of fetching and compiling again. Server-side only: never
/// returned to clients.
abstract class LinkAnalysis
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  LinkAnalysis._({
    this.id,
    required this.normalizedUrl,
    required this.platform,
    this.creator,
    this.creatorKey,
    required this.title,
    required this.targetLanguage,
    required this.supportLanguage,
    required this.cefrLevel,
    required this.transcript,
    required this.contentHash,
    required this.objectives,
    required this.vocabulary,
    required this.grammar,
    required this.activities,
    required this.conversationPlan,
    int? hitCount,
    required this.createdAt,
    required this.lastUsedAt,
    this.expiresAt,
  }) : hitCount = hitCount ?? 0;

  factory LinkAnalysis({
    int? id,
    required String normalizedUrl,
    required String platform,
    String? creator,
    String? creatorKey,
    required String title,
    required String targetLanguage,
    required String supportLanguage,
    required String cefrLevel,
    required String transcript,
    required String contentHash,
    required List<String> objectives,
    required String vocabulary,
    required String grammar,
    required String activities,
    required String conversationPlan,
    int? hitCount,
    required DateTime createdAt,
    required DateTime lastUsedAt,
    DateTime? expiresAt,
  }) = _LinkAnalysisImpl;

  factory LinkAnalysis.fromJson(Map<String, dynamic> jsonSerialization) {
    return LinkAnalysis(
      id: jsonSerialization['id'] as int?,
      normalizedUrl: jsonSerialization['normalizedUrl'] as String,
      platform: jsonSerialization['platform'] as String,
      creator: jsonSerialization['creator'] as String?,
      creatorKey: jsonSerialization['creatorKey'] as String?,
      title: jsonSerialization['title'] as String,
      targetLanguage: jsonSerialization['targetLanguage'] as String,
      supportLanguage: jsonSerialization['supportLanguage'] as String,
      cefrLevel: jsonSerialization['cefrLevel'] as String,
      transcript: jsonSerialization['transcript'] as String,
      contentHash: jsonSerialization['contentHash'] as String,
      objectives: _itiajcaj.Protocol().deserialize<List<String>>(
        jsonSerialization['objectives'],
      ),
      vocabulary: jsonSerialization['vocabulary'] as String,
      grammar: jsonSerialization['grammar'] as String,
      activities: jsonSerialization['activities'] as String,
      conversationPlan: jsonSerialization['conversationPlan'] as String,
      hitCount: jsonSerialization['hitCount'] as int?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastUsedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastUsedAt'],
      ),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
    );
  }

  static final t = LinkAnalysisTable();

  static const db = LinkAnalysisRepository._();

  @override
  int? id;

  /// Output of the URL normaliser; the cache key together with the languages.
  String normalizedUrl;

  /// youtube, instagram, tiktok, reddit, x, facebook or web.
  String platform;

  /// Channel, account, subreddit or site host, as displayed.
  String? creator;

  /// Lower-cased creator for grouping and lookups.
  String? creatorKey;

  String title;

  String targetLanguage;

  String supportLanguage;

  String cefrLevel;

  String transcript;

  /// SHA-256 of the whitespace-normalised transcript.
  String contentHash;

  List<String> objectives;

  String vocabulary;

  String grammar;

  String activities;

  String conversationPlan;

  int hitCount;

  DateTime createdAt;

  DateTime lastUsedAt;

  /// Null means the analysis does not expire.
  DateTime? expiresAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [LinkAnalysis]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LinkAnalysis copyWith({
    int? id,
    String? normalizedUrl,
    String? platform,
    String? creator,
    String? creatorKey,
    String? title,
    String? targetLanguage,
    String? supportLanguage,
    String? cefrLevel,
    String? transcript,
    String? contentHash,
    List<String>? objectives,
    String? vocabulary,
    String? grammar,
    String? activities,
    String? conversationPlan,
    int? hitCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LinkAnalysis',
      if (id != null) 'id': id,
      'normalizedUrl': normalizedUrl,
      'platform': platform,
      if (creator != null) 'creator': creator,
      if (creatorKey != null) 'creatorKey': creatorKey,
      'title': title,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'cefrLevel': cefrLevel,
      'transcript': transcript,
      'contentHash': contentHash,
      'objectives': objectives.toJson(),
      'vocabulary': vocabulary,
      'grammar': grammar,
      'activities': activities,
      'conversationPlan': conversationPlan,
      'hitCount': hitCount,
      'createdAt': createdAt.toJson(),
      'lastUsedAt': lastUsedAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LinkAnalysis',
      if (id != null) 'id': id,
      'normalizedUrl': normalizedUrl,
      'platform': platform,
      if (creator != null) 'creator': creator,
      if (creatorKey != null) 'creatorKey': creatorKey,
      'title': title,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'cefrLevel': cefrLevel,
      'transcript': transcript,
      'contentHash': contentHash,
      'objectives': objectives.toJson(),
      'vocabulary': vocabulary,
      'grammar': grammar,
      'activities': activities,
      'conversationPlan': conversationPlan,
      'hitCount': hitCount,
      'createdAt': createdAt.toJson(),
      'lastUsedAt': lastUsedAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
    };
  }

  static LinkAnalysisInclude include() {
    return LinkAnalysisInclude._();
  }

  static LinkAnalysisIncludeList includeList({
    _is.WhereExpressionBuilder<LinkAnalysisTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LinkAnalysisTable>? orderBy,
    _is.OrderByListBuilder<LinkAnalysisTable>? orderByList,
    LinkAnalysisInclude? include,
  }) {
    return LinkAnalysisIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LinkAnalysis.t),
      orderByList: orderByList?.call(LinkAnalysis.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LinkAnalysisImpl extends LinkAnalysis {
  _LinkAnalysisImpl({
    int? id,
    required String normalizedUrl,
    required String platform,
    String? creator,
    String? creatorKey,
    required String title,
    required String targetLanguage,
    required String supportLanguage,
    required String cefrLevel,
    required String transcript,
    required String contentHash,
    required List<String> objectives,
    required String vocabulary,
    required String grammar,
    required String activities,
    required String conversationPlan,
    int? hitCount,
    required DateTime createdAt,
    required DateTime lastUsedAt,
    DateTime? expiresAt,
  }) : super._(
         id: id,
         normalizedUrl: normalizedUrl,
         platform: platform,
         creator: creator,
         creatorKey: creatorKey,
         title: title,
         targetLanguage: targetLanguage,
         supportLanguage: supportLanguage,
         cefrLevel: cefrLevel,
         transcript: transcript,
         contentHash: contentHash,
         objectives: objectives,
         vocabulary: vocabulary,
         grammar: grammar,
         activities: activities,
         conversationPlan: conversationPlan,
         hitCount: hitCount,
         createdAt: createdAt,
         lastUsedAt: lastUsedAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [LinkAnalysis]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LinkAnalysis copyWith({
    Object? id = _Undefined,
    String? normalizedUrl,
    String? platform,
    Object? creator = _Undefined,
    Object? creatorKey = _Undefined,
    String? title,
    String? targetLanguage,
    String? supportLanguage,
    String? cefrLevel,
    String? transcript,
    String? contentHash,
    List<String>? objectives,
    String? vocabulary,
    String? grammar,
    String? activities,
    String? conversationPlan,
    int? hitCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    Object? expiresAt = _Undefined,
  }) {
    return LinkAnalysis(
      id: id is int? ? id : this.id,
      normalizedUrl: normalizedUrl ?? this.normalizedUrl,
      platform: platform ?? this.platform,
      creator: creator is String? ? creator : this.creator,
      creatorKey: creatorKey is String? ? creatorKey : this.creatorKey,
      title: title ?? this.title,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      supportLanguage: supportLanguage ?? this.supportLanguage,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      transcript: transcript ?? this.transcript,
      contentHash: contentHash ?? this.contentHash,
      objectives: objectives ?? this.objectives.map((e0) => e0).toList(),
      vocabulary: vocabulary ?? this.vocabulary,
      grammar: grammar ?? this.grammar,
      activities: activities ?? this.activities,
      conversationPlan: conversationPlan ?? this.conversationPlan,
      hitCount: hitCount ?? this.hitCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
    );
  }
}

class LinkAnalysisUpdateTable extends _is.UpdateTable<LinkAnalysisTable> {
  LinkAnalysisUpdateTable(super.table);

  _is.ColumnValue<String, String> normalizedUrl(String value) =>
      _is.ColumnValue(
        table.normalizedUrl,
        value,
      );

  _is.ColumnValue<String, String> platform(String value) => _is.ColumnValue(
    table.platform,
    value,
  );

  _is.ColumnValue<String, String> creator(String? value) => _is.ColumnValue(
    table.creator,
    value,
  );

  _is.ColumnValue<String, String> creatorKey(String? value) => _is.ColumnValue(
    table.creatorKey,
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

  _is.ColumnValue<String, String> transcript(String value) => _is.ColumnValue(
    table.transcript,
    value,
  );

  _is.ColumnValue<String, String> contentHash(String value) => _is.ColumnValue(
    table.contentHash,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> objectives(List<String> value) =>
      _is.ColumnValue(
        table.objectives,
        value,
      );

  _is.ColumnValue<String, String> vocabulary(String value) => _is.ColumnValue(
    table.vocabulary,
    value,
  );

  _is.ColumnValue<String, String> grammar(String value) => _is.ColumnValue(
    table.grammar,
    value,
  );

  _is.ColumnValue<String, String> activities(String value) => _is.ColumnValue(
    table.activities,
    value,
  );

  _is.ColumnValue<String, String> conversationPlan(String value) =>
      _is.ColumnValue(
        table.conversationPlan,
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

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime? value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );
}

class LinkAnalysisTable extends _is.Table<int?> {
  LinkAnalysisTable({super.tableRelation}) : super(tableName: 'link_analyses') {
    updateTable = LinkAnalysisUpdateTable(this);
    normalizedUrl = _is.ColumnString(
      'normalizedUrl',
      this,
    );
    platform = _is.ColumnString(
      'platform',
      this,
    );
    creator = _is.ColumnString(
      'creator',
      this,
    );
    creatorKey = _is.ColumnString(
      'creatorKey',
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
    transcript = _is.ColumnString(
      'transcript',
      this,
    );
    contentHash = _is.ColumnString(
      'contentHash',
      this,
    );
    objectives = _is.ColumnSerializable<List<String>>(
      'objectives',
      this,
    );
    vocabulary = _is.ColumnString(
      'vocabulary',
      this,
    );
    grammar = _is.ColumnString(
      'grammar',
      this,
    );
    activities = _is.ColumnString(
      'activities',
      this,
    );
    conversationPlan = _is.ColumnString(
      'conversationPlan',
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
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
  }

  late final LinkAnalysisUpdateTable updateTable;

  /// Output of the URL normaliser; the cache key together with the languages.
  late final _is.ColumnString normalizedUrl;

  /// youtube, instagram, tiktok, reddit, x, facebook or web.
  late final _is.ColumnString platform;

  /// Channel, account, subreddit or site host, as displayed.
  late final _is.ColumnString creator;

  /// Lower-cased creator for grouping and lookups.
  late final _is.ColumnString creatorKey;

  late final _is.ColumnString title;

  late final _is.ColumnString targetLanguage;

  late final _is.ColumnString supportLanguage;

  late final _is.ColumnString cefrLevel;

  late final _is.ColumnString transcript;

  /// SHA-256 of the whitespace-normalised transcript.
  late final _is.ColumnString contentHash;

  late final _is.ColumnSerializable<List<String>> objectives;

  late final _is.ColumnString vocabulary;

  late final _is.ColumnString grammar;

  late final _is.ColumnString activities;

  late final _is.ColumnString conversationPlan;

  late final _is.ColumnInt hitCount;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime lastUsedAt;

  /// Null means the analysis does not expire.
  late final _is.ColumnDateTime expiresAt;

  @override
  List<_is.Column> get columns => [
    id,
    normalizedUrl,
    platform,
    creator,
    creatorKey,
    title,
    targetLanguage,
    supportLanguage,
    cefrLevel,
    transcript,
    contentHash,
    objectives,
    vocabulary,
    grammar,
    activities,
    conversationPlan,
    hitCount,
    createdAt,
    lastUsedAt,
    expiresAt,
  ];
}

class LinkAnalysisInclude extends _is.IncludeObject {
  LinkAnalysisInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => LinkAnalysis.t;
}

class LinkAnalysisIncludeList extends _is.IncludeList {
  LinkAnalysisIncludeList._({
    _is.WhereExpressionBuilder<LinkAnalysisTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LinkAnalysis.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => LinkAnalysis.t;
}

class LinkAnalysisRepository {
  const LinkAnalysisRepository._();

  /// Returns a list of [LinkAnalysis]s matching the given query parameters.
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
  Future<List<LinkAnalysis>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LinkAnalysisTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LinkAnalysisTable>? orderBy,
    _is.OrderByListBuilder<LinkAnalysisTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LinkAnalysis>(
      where: where?.call(LinkAnalysis.t),
      orderBy: orderBy?.call(LinkAnalysis.t),
      orderByList: orderByList?.call(LinkAnalysis.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LinkAnalysis] matching the given query parameters.
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
  Future<LinkAnalysis?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LinkAnalysisTable>? where,
    int? offset,
    _is.OrderByBuilder<LinkAnalysisTable>? orderBy,
    _is.OrderByListBuilder<LinkAnalysisTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LinkAnalysis>(
      where: where?.call(LinkAnalysis.t),
      orderBy: orderBy?.call(LinkAnalysis.t),
      orderByList: orderByList?.call(LinkAnalysis.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LinkAnalysis] by its [id] or null if no such row exists.
  Future<LinkAnalysis?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LinkAnalysis>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LinkAnalysis]s in the list and returns the inserted rows.
  ///
  /// The returned [LinkAnalysis]s will have their `id` fields set.
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
  Future<List<LinkAnalysis>> insert(
    _is.DatabaseSession session,
    List<LinkAnalysis> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<LinkAnalysis>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [LinkAnalysis] and returns the inserted row.
  ///
  /// The returned [LinkAnalysis] will have its `id` field set.
  Future<LinkAnalysis> insertRow(
    _is.DatabaseSession session,
    LinkAnalysis row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<LinkAnalysis>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [LinkAnalysis]s in the list and returns the resulting rows.
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
  /// The returned [LinkAnalysis]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LinkAnalysis>> upsert(
    _is.DatabaseSession session,
    List<LinkAnalysis> rows, {
    required _is.ColumnSelections<LinkAnalysisTable> conflictColumns,
    _is.ColumnSelections<LinkAnalysisTable>? updateColumns,
    _is.WhereExpressionBuilder<LinkAnalysisTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<LinkAnalysis>(
      rows,
      conflictColumns: conflictColumns(LinkAnalysis.t),
      updateColumns: updateColumns?.call(LinkAnalysis.t),
      updateWhere: updateWhere?.call(LinkAnalysis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [LinkAnalysis] and returns the resulting row.
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
  /// The returned [LinkAnalysis] will have its `id` field set.
  Future<LinkAnalysis?> upsertRow(
    _is.DatabaseSession session,
    LinkAnalysis row, {
    required _is.ColumnSelections<LinkAnalysisTable> conflictColumns,
    _is.ColumnSelections<LinkAnalysisTable>? updateColumns,
    _is.WhereExpressionBuilder<LinkAnalysisTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<LinkAnalysis>(
      row,
      conflictColumns: conflictColumns(LinkAnalysis.t),
      updateColumns: updateColumns?.call(LinkAnalysis.t),
      updateWhere: updateWhere?.call(LinkAnalysis.t),
      transaction: transaction,
    );
  }

  /// Updates all [LinkAnalysis]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LinkAnalysis>> update(
    _is.DatabaseSession session,
    List<LinkAnalysis> rows, {
    _is.ColumnSelections<LinkAnalysisTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<LinkAnalysis>(
      rows,
      columns: columns?.call(LinkAnalysis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [LinkAnalysis]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LinkAnalysis> updateRow(
    _is.DatabaseSession session,
    LinkAnalysis row, {
    _is.ColumnSelections<LinkAnalysisTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<LinkAnalysis>(
      row,
      columns: columns?.call(LinkAnalysis.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LinkAnalysis] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LinkAnalysis?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<LinkAnalysisUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<LinkAnalysis>(
      id,
      columnValues: columnValues(LinkAnalysis.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LinkAnalysis]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LinkAnalysis>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<LinkAnalysisUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<LinkAnalysisTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LinkAnalysisTable>? orderBy,
    _is.OrderByListBuilder<LinkAnalysisTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<LinkAnalysis>(
      columnValues: columnValues(LinkAnalysis.t.updateTable),
      where: where(LinkAnalysis.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LinkAnalysis.t),
      orderByList: orderByList?.call(LinkAnalysis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [LinkAnalysis]s in the list and returns the deleted rows.
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
  Future<List<LinkAnalysis>> delete(
    _is.DatabaseSession session,
    List<LinkAnalysis> rows, {
    _is.OrderByBuilder<LinkAnalysisTable>? orderBy,
    _is.OrderByListBuilder<LinkAnalysisTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<LinkAnalysis>(
      rows,
      orderBy: orderBy?.call(LinkAnalysis.t),
      orderByList: orderByList?.call(LinkAnalysis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [LinkAnalysis].
  Future<LinkAnalysis> deleteRow(
    _is.DatabaseSession session,
    LinkAnalysis row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LinkAnalysis>(
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
  Future<List<LinkAnalysis>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LinkAnalysisTable> where,
    _is.OrderByBuilder<LinkAnalysisTable>? orderBy,
    _is.OrderByListBuilder<LinkAnalysisTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<LinkAnalysis>(
      where: where(LinkAnalysis.t),
      orderBy: orderBy?.call(LinkAnalysis.t),
      orderByList: orderByList?.call(LinkAnalysis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LinkAnalysisTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<LinkAnalysis>(
      where: where?.call(LinkAnalysis.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LinkAnalysis] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LinkAnalysisTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LinkAnalysis>(
      where: where(LinkAnalysis.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
