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
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'package:talkloom_server/src/generated/evidence/evidence_event.dart'
    as _irgkj883;
import 'package:talkloom_server/src/generated/evidence/word_evidence_summary.dart'
    as _itcuoxhy;
import 'package:talkloom_server/src/generated/lessons/lesson.dart' as _i671tbp8;
import 'package:talkloom_server/src/generated/sources/source.dart' as _ijkl03oo;
import 'evidence/evidence_event.dart' as _idx9o88s;
import 'evidence/turn_evaluation.dart' as _i0m0m0et;
import 'evidence/word_evidence_summary.dart' as _iuhv7p0x;
import 'future_calls_generated_models/import_job_future_call_compile_model.dart'
    as _i0leerse;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'learner/learner_state.dart' as _ihnw2h1r;
import 'lessons/lesson.dart' as _idiive9r;
import 'lessons/vocab_artwork.dart' as _i80t56xh;
import 'sources/import_exception.dart' as _ivq8tzld;
import 'sources/import_job.dart' as _i5fsgrng;
import 'sources/import_job_progress.dart' as _ibcc22em;
import 'sources/link_analysis.dart' as _i9zsyima;
import 'sources/source.dart' as _i78k1pe6;
import 'usage/ai_usage.dart' as _iaxrn8hs;
export 'evidence/evidence_event.dart';
export 'evidence/turn_evaluation.dart';
export 'evidence/word_evidence_summary.dart';
export 'greetings/greeting.dart';
export 'learner/learner_state.dart';
export 'lessons/lesson.dart';
export 'lessons/vocab_artwork.dart';
export 'sources/import_exception.dart';
export 'sources/import_job.dart';
export 'sources/import_job_progress.dart';
export 'sources/link_analysis.dart';
export 'sources/source.dart';
export 'usage/ai_usage.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'ai_usage',
      dartName: 'AiUsage',
      schema: 'public',
      module: 'talkloom',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'day',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'imports',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'conversationTurns',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'transcriptions',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'illustrations',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'ai_usage_user_day_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'day',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'evidence_events',
      dartName: 'EvidenceEvent',
      schema: 'public',
      module: 'talkloom',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'targetLanguage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'activityType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'supportLevel',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'spontaneous',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'correct',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'timestamp',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'import_jobs',
      dartName: 'ImportJob',
      schema: 'public',
      module: 'talkloom',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'type',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'targetLanguage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'supportLanguage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'cefrLevel',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'url',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'rawContent',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'stage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'queued\'',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'lessonId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'errorCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'errorMessage',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'import_job_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'learner_state',
      dartName: 'LearnerState',
      schema: 'public',
      module: 'talkloom',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'targetLanguage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'recognizedWords',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'activeWords',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'grammarMastery',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'lessons',
      dartName: 'Lesson',
      schema: 'public',
      module: 'talkloom',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'targetLanguage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'supportLanguage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'objectives',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'vocabulary',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'grammar',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'activities',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'conversationPlan',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'lesson_user_lang_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'targetLanguage',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'link_analyses',
      dartName: 'LinkAnalysis',
      schema: 'public',
      module: 'talkloom',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'normalizedUrl',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'platform',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'creator',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'creatorKey',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'targetLanguage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'supportLanguage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'cefrLevel',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'transcript',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'contentHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'objectives',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'vocabulary',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'grammar',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'activities',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'conversationPlan',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'hitCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'lastUsedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'link_analysis_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'normalizedUrl',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'targetLanguage',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'supportLanguage',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'cefrLevel',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'link_analysis_url_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'normalizedUrl',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'targetLanguage',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'link_analysis_category_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'platform',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'creatorKey',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'sources',
      dartName: 'Source',
      schema: 'public',
      module: 'talkloom',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'type',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'url',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'rawText',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'targetLanguage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'cefrLevel',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'isArchived',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'platform',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'creator',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'source_user_lang_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'targetLanguage',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'isArchived',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'source_url_lang_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'url',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'targetLanguage',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'turn_evaluations',
      dartName: 'TurnEvaluation',
      schema: 'public',
      module: 'talkloom',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'targetLanguage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'lessonId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'learnerUtterance',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'provider',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'model',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'reason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'results',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'turn_evaluation_user_lang_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'targetLanguage',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'vocab_artworks',
      dartName: 'VocabArtwork',
      schema: 'public',
      module: 'talkloom',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'lemmaKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'language',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'styleVersion',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _isp.ColumnDefinition(
          name: 'mimeType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'artwork',
          columnType: _isp.ColumnType.bytea,
          isNullable: false,
          dartType: 'dart:typed_data:ByteData',
        ),
        _isp.ColumnDefinition(
          name: 'hitCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'lastUsedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'artwork_lemma_style_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'lemmaKey',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'styleVersion',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iais.Protocol.targetTableDefinitions,
    ..._iacs.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

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
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _idx9o88s.EvidenceEvent) {
      return _idx9o88s.EvidenceEvent.fromJson(data) as T;
    }
    if (t == _i0m0m0et.TurnEvaluation) {
      return _i0m0m0et.TurnEvaluation.fromJson(data) as T;
    }
    if (t == _iuhv7p0x.WordEvidenceSummary) {
      return _iuhv7p0x.WordEvidenceSummary.fromJson(data) as T;
    }
    if (t == _i0leerse.ImportJobFutureCallCompileModel) {
      return _i0leerse.ImportJobFutureCallCompileModel.fromJson(data) as T;
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
    if (t == _i80t56xh.VocabArtwork) {
      return _i80t56xh.VocabArtwork.fromJson(data) as T;
    }
    if (t == _ivq8tzld.ImportException) {
      return _ivq8tzld.ImportException.fromJson(data) as T;
    }
    if (t == _i5fsgrng.ImportJob) {
      return _i5fsgrng.ImportJob.fromJson(data) as T;
    }
    if (t == _ibcc22em.ImportJobProgress) {
      return _ibcc22em.ImportJobProgress.fromJson(data) as T;
    }
    if (t == _i9zsyima.LinkAnalysis) {
      return _i9zsyima.LinkAnalysis.fromJson(data) as T;
    }
    if (t == _i78k1pe6.Source) {
      return _i78k1pe6.Source.fromJson(data) as T;
    }
    if (t == _iaxrn8hs.AiUsage) {
      return _iaxrn8hs.AiUsage.fromJson(data) as T;
    }
    if (t == _is.getType<_idx9o88s.EvidenceEvent?>()) {
      return (data != null ? _idx9o88s.EvidenceEvent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i0m0m0et.TurnEvaluation?>()) {
      return (data != null ? _i0m0m0et.TurnEvaluation.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iuhv7p0x.WordEvidenceSummary?>()) {
      return (data != null
              ? _iuhv7p0x.WordEvidenceSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i0leerse.ImportJobFutureCallCompileModel?>()) {
      return (data != null
              ? _i0leerse.ImportJobFutureCallCompileModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihnw2h1r.LearnerState?>()) {
      return (data != null ? _ihnw2h1r.LearnerState.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_idiive9r.Lesson?>()) {
      return (data != null ? _idiive9r.Lesson.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i80t56xh.VocabArtwork?>()) {
      return (data != null ? _i80t56xh.VocabArtwork.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ivq8tzld.ImportException?>()) {
      return (data != null ? _ivq8tzld.ImportException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5fsgrng.ImportJob?>()) {
      return (data != null ? _i5fsgrng.ImportJob.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ibcc22em.ImportJobProgress?>()) {
      return (data != null ? _ibcc22em.ImportJobProgress.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i9zsyima.LinkAnalysis?>()) {
      return (data != null ? _i9zsyima.LinkAnalysis.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i78k1pe6.Source?>()) {
      return (data != null ? _i78k1pe6.Source.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iaxrn8hs.AiUsage?>()) {
      return (data != null ? _iaxrn8hs.AiUsage.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_irgkj883.EvidenceEvent>) {
      return (data as List)
              .map((e) => deserialize<_irgkj883.EvidenceEvent>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_itcuoxhy.WordEvidenceSummary>) {
      return (data as List)
              .map((e) => deserialize<_itcuoxhy.WordEvidenceSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_ijkl03oo.Source>) {
      return (data as List)
              .map((e) => deserialize<_ijkl03oo.Source>(e))
              .toList()
          as T;
    }
    if (t == List<_i671tbp8.Lesson>) {
      return (data as List)
              .map((e) => deserialize<_i671tbp8.Lesson>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    try {
      return _iais.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacs.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _idx9o88s.EvidenceEvent => 'EvidenceEvent',
      _i0m0m0et.TurnEvaluation => 'TurnEvaluation',
      _iuhv7p0x.WordEvidenceSummary => 'WordEvidenceSummary',
      _i0leerse.ImportJobFutureCallCompileModel =>
        'ImportJobFutureCallCompileModel',
      _izw8z7ou.Greeting => 'Greeting',
      _ihnw2h1r.LearnerState => 'LearnerState',
      _idiive9r.Lesson => 'Lesson',
      _i80t56xh.VocabArtwork => 'VocabArtwork',
      _ivq8tzld.ImportException => 'ImportException',
      _i5fsgrng.ImportJob => 'ImportJob',
      _ibcc22em.ImportJobProgress => 'ImportJobProgress',
      _i9zsyima.LinkAnalysis => 'LinkAnalysis',
      _i78k1pe6.Source => 'Source',
      _iaxrn8hs.AiUsage => 'AiUsage',
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
      case _i0m0m0et.TurnEvaluation():
        return 'TurnEvaluation';
      case _iuhv7p0x.WordEvidenceSummary():
        return 'WordEvidenceSummary';
      case _i0leerse.ImportJobFutureCallCompileModel():
        return 'ImportJobFutureCallCompileModel';
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _ihnw2h1r.LearnerState():
        return 'LearnerState';
      case _idiive9r.Lesson():
        return 'Lesson';
      case _i80t56xh.VocabArtwork():
        return 'VocabArtwork';
      case _ivq8tzld.ImportException():
        return 'ImportException';
      case _i5fsgrng.ImportJob():
        return 'ImportJob';
      case _ibcc22em.ImportJobProgress():
        return 'ImportJobProgress';
      case _i9zsyima.LinkAnalysis():
        return 'LinkAnalysis';
      case _i78k1pe6.Source():
        return 'Source';
      case _iaxrn8hs.AiUsage():
        return 'AiUsage';
    }
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
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
    if (dataClassName == 'TurnEvaluation') {
      return deserialize<_i0m0m0et.TurnEvaluation>(data['data']);
    }
    if (dataClassName == 'WordEvidenceSummary') {
      return deserialize<_iuhv7p0x.WordEvidenceSummary>(data['data']);
    }
    if (dataClassName == 'ImportJobFutureCallCompileModel') {
      return deserialize<_i0leerse.ImportJobFutureCallCompileModel>(
        data['data'],
      );
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
    if (dataClassName == 'VocabArtwork') {
      return deserialize<_i80t56xh.VocabArtwork>(data['data']);
    }
    if (dataClassName == 'ImportException') {
      return deserialize<_ivq8tzld.ImportException>(data['data']);
    }
    if (dataClassName == 'ImportJob') {
      return deserialize<_i5fsgrng.ImportJob>(data['data']);
    }
    if (dataClassName == 'ImportJobProgress') {
      return deserialize<_ibcc22em.ImportJobProgress>(data['data']);
    }
    if (dataClassName == 'LinkAnalysis') {
      return deserialize<_i9zsyima.LinkAnalysis>(data['data']);
    }
    if (dataClassName == 'Source') {
      return deserialize<_i78k1pe6.Source>(data['data']);
    }
    if (dataClassName == 'AiUsage') {
      return deserialize<_iaxrn8hs.AiUsage>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iais.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacs.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol('talkloom', this);
    _iacs.Protocol().registerHostProtocol('talkloom', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _idx9o88s.EvidenceEvent:
        return _idx9o88s.EvidenceEvent.t;
      case _i0m0m0et.TurnEvaluation:
        return _i0m0m0et.TurnEvaluation.t;
      case _ihnw2h1r.LearnerState:
        return _ihnw2h1r.LearnerState.t;
      case _idiive9r.Lesson:
        return _idiive9r.Lesson.t;
      case _i80t56xh.VocabArtwork:
        return _i80t56xh.VocabArtwork.t;
      case _i5fsgrng.ImportJob:
        return _i5fsgrng.ImportJob.t;
      case _i9zsyima.LinkAnalysis:
        return _i9zsyima.LinkAnalysis.t;
      case _i78k1pe6.Source:
        return _i78k1pe6.Source.t;
      case _iaxrn8hs.AiUsage:
        return _iaxrn8hs.AiUsage.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

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
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
