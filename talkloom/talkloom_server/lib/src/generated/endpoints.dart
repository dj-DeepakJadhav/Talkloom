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
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../greetings/greeting_endpoint.dart' as _il624ik7;
import '../learner/learner_state_endpoint.dart' as _i9uu499j;
import '../lessons/lesson_compiler_endpoint.dart' as _iszs4rjo;
import '../lessons/pedagogical_endpoint.dart' as _ikctb4li;
import '../sources/ingestion_endpoint.dart' as _i18xt97h;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'emailIdp': _iuc1hd5t.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _inwq3ztq.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'greeting': _il624ik7.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
      'learnerState': _i9uu499j.LearnerStateEndpoint()
        ..initialize(
          server,
          'learnerState',
          null,
        ),
      'lessonCompiler': _iszs4rjo.LessonCompilerEndpoint()
        ..initialize(
          server,
          'lessonCompiler',
          null,
        ),
      'pedagogical': _ikctb4li.PedagogicalEndpoint()
        ..initialize(
          server,
          'pedagogical',
          null,
        ),
      'ingestion': _i18xt97h.IngestionEndpoint()
        ..initialize(
          server,
          'ingestion',
          null,
        ),
    };
    connectors['emailIdp'] = _is.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint).login(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
        'startRegistration': _is.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _is.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _is.ParameterDescription(
              name: 'accountRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _is.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _is.ParameterDescription(
              name: 'registrationToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _is.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _is.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _is.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _is.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _is.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'newPassword': _is.ParameterDescription(
              name: 'newPassword',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _is.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _is.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _is.ParameterDescription(
              name: 'refreshToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['jwtRefresh'] as _inwq3ztq.JwtRefreshEndpoint)
                      .refreshAccessToken(
                        session,
                        refreshToken: params['refreshToken'],
                      ),
        ),
      },
    );
    connectors['greeting'] = _is.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _is.MethodConnector(
          name: 'hello',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['greeting'] as _il624ik7.GreetingEndpoint).hello(
                    session,
                    params['name'],
                  ),
        ),
      },
    );
    connectors['learnerState'] = _is.EndpointConnector(
      name: 'learnerState',
      endpoint: endpoints['learnerState']!,
      methodConnectors: {
        'getLearnerState': _is.MethodConnector(
          name: 'getLearnerState',
          params: {
            'targetLanguage': _is.ParameterDescription(
              name: 'targetLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['learnerState'] as _i9uu499j.LearnerStateEndpoint)
                      .getLearnerState(
                        session,
                        params['targetLanguage'],
                      ),
        ),
        'recordEvidenceEvent': _is.MethodConnector(
          name: 'recordEvidenceEvent',
          params: {
            'targetLanguage': _is.ParameterDescription(
              name: 'targetLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'itemId': _is.ParameterDescription(
              name: 'itemId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'activityType': _is.ParameterDescription(
              name: 'activityType',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'supportLevel': _is.ParameterDescription(
              name: 'supportLevel',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'spontaneous': _is.ParameterDescription(
              name: 'spontaneous',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'correct': _is.ParameterDescription(
              name: 'correct',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['learnerState'] as _i9uu499j.LearnerStateEndpoint)
                      .recordEvidenceEvent(
                        session,
                        targetLanguage: params['targetLanguage'],
                        itemId: params['itemId'],
                        activityType: params['activityType'],
                        supportLevel: params['supportLevel'],
                        spontaneous: params['spontaneous'],
                        correct: params['correct'],
                      ),
        ),
        'getEvidenceHistory': _is.MethodConnector(
          name: 'getEvidenceHistory',
          params: {
            'targetLanguage': _is.ParameterDescription(
              name: 'targetLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['learnerState'] as _i9uu499j.LearnerStateEndpoint)
                      .getEvidenceHistory(
                        session,
                        params['targetLanguage'],
                        limit: params['limit'],
                      ),
        ),
      },
    );
    connectors['lessonCompiler'] = _is.EndpointConnector(
      name: 'lessonCompiler',
      endpoint: endpoints['lessonCompiler']!,
      methodConnectors: {
        'compileLesson': _is.MethodConnector(
          name: 'compileLesson',
          params: {
            'sourceTitle': _is.ParameterDescription(
              name: 'sourceTitle',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'rawText': _is.ParameterDescription(
              name: 'rawText',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'targetLanguage': _is.ParameterDescription(
              name: 'targetLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'supportLanguage': _is.ParameterDescription(
              name: 'supportLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'estimatedLevel': _is.ParameterDescription(
              name: 'estimatedLevel',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'sourceId': _is.ParameterDescription(
              name: 'sourceId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lessonCompiler']
                          as _iszs4rjo.LessonCompilerEndpoint)
                      .compileLesson(
                        session,
                        sourceTitle: params['sourceTitle'],
                        rawText: params['rawText'],
                        targetLanguage: params['targetLanguage'],
                        supportLanguage: params['supportLanguage'],
                        estimatedLevel: params['estimatedLevel'],
                        sourceId: params['sourceId'],
                      ),
        ),
      },
    );
    connectors['pedagogical'] = _is.EndpointConnector(
      name: 'pedagogical',
      endpoint: endpoints['pedagogical']!,
      methodConnectors: {
        'stepConversationTurn': _is.MethodConnector(
          name: 'stepConversationTurn',
          params: {
            'targetLanguage': _is.ParameterDescription(
              name: 'targetLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'role': _is.ParameterDescription(
              name: 'role',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'situation': _is.ParameterDescription(
              name: 'situation',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'hiddenTargets': _is.ParameterDescription(
              name: 'hiddenTargets',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
            'previousTurns': _is.ParameterDescription(
              name: 'previousTurns',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
            'learnerUtterance': _is.ParameterDescription(
              name: 'learnerUtterance',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'responseLatencySec': _is.ParameterDescription(
              name: 'responseLatencySec',
              type: _is.getType<double>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['pedagogical'] as _ikctb4li.PedagogicalEndpoint)
                      .stepConversationTurn(
                        session,
                        params['targetLanguage'],
                        params['role'],
                        params['situation'],
                        params['hiddenTargets'],
                        params['previousTurns'],
                        params['learnerUtterance'],
                        params['responseLatencySec'],
                      ),
        ),
        'getLearnerState': _is.MethodConnector(
          name: 'getLearnerState',
          params: {
            'targetLanguage': _is.ParameterDescription(
              name: 'targetLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['pedagogical'] as _ikctb4li.PedagogicalEndpoint)
                      .getLearnerState(
                        session,
                        params['targetLanguage'],
                      ),
        ),
        'getEvidenceHistory': _is.MethodConnector(
          name: 'getEvidenceHistory',
          params: {
            'targetLanguage': _is.ParameterDescription(
              name: 'targetLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['pedagogical'] as _ikctb4li.PedagogicalEndpoint)
                      .getEvidenceHistory(
                        session,
                        params['targetLanguage'],
                        limit: params['limit'],
                      ),
        ),
      },
    );
    connectors['ingestion'] = _is.EndpointConnector(
      name: 'ingestion',
      endpoint: endpoints['ingestion']!,
      methodConnectors: {
        'processSourceAndCompile': _is.MethodConnector(
          name: 'processSourceAndCompile',
          params: {
            'type': _is.ParameterDescription(
              name: 'type',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'targetLanguage': _is.ParameterDescription(
              name: 'targetLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'supportLanguage': _is.ParameterDescription(
              name: 'supportLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'cefrLevel': _is.ParameterDescription(
              name: 'cefrLevel',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'url': _is.ParameterDescription(
              name: 'url',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'rawContent': _is.ParameterDescription(
              name: 'rawContent',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingestion'] as _i18xt97h.IngestionEndpoint)
                  .processSourceAndCompile(
                    session,
                    params['type'],
                    params['title'],
                    params['targetLanguage'],
                    params['supportLanguage'],
                    params['cefrLevel'],
                    params['url'],
                    params['rawContent'],
                  ),
        ),
        'listSources': _is.MethodConnector(
          name: 'listSources',
          params: {
            'targetLanguage': _is.ParameterDescription(
              name: 'targetLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'offset': _is.ParameterDescription(
              name: 'offset',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingestion'] as _i18xt97h.IngestionEndpoint)
                  .listSources(
                    session,
                    params['targetLanguage'],
                    limit: params['limit'],
                    offset: params['offset'],
                  ),
        ),
        'getLessonBySourceId': _is.MethodConnector(
          name: 'getLessonBySourceId',
          params: {
            'sourceId': _is.ParameterDescription(
              name: 'sourceId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingestion'] as _i18xt97h.IngestionEndpoint)
                  .getLessonBySourceId(
                    session,
                    params['sourceId'],
                  ),
        ),
        'listLessons': _is.MethodConnector(
          name: 'listLessons',
          params: {
            'targetLanguage': _is.ParameterDescription(
              name: 'targetLanguage',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'offset': _is.ParameterDescription(
              name: 'offset',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingestion'] as _i18xt97h.IngestionEndpoint)
                  .listLessons(
                    session,
                    params['targetLanguage'],
                    limit: params['limit'],
                    offset: params['offset'],
                  ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeEndpoints(server);
  }
}
