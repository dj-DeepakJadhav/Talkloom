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
import 'dart:async' as _ida;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:talkloom_client/src/protocol/evidence/evidence_event.dart'
    as _i4nm32oi;
import 'package:talkloom_client/src/protocol/evidence/word_evidence_summary.dart'
    as _icmj5pil;
import 'package:talkloom_client/src/protocol/greetings/greeting.dart'
    as _i0sfqx47;
import 'package:talkloom_client/src/protocol/learner/learner_state.dart'
    as _ij90w53a;
import 'package:talkloom_client/src/protocol/lessons/lesson.dart' as _irv3hfbd;
import 'package:talkloom_client/src/protocol/sources/import_job.dart'
    as _ikhpiv0x;
import 'package:talkloom_client/src/protocol/sources/import_job_progress.dart'
    as _inw88992;
import 'package:talkloom_client/src/protocol/sources/source.dart' as _ikpsvynv;
import 'protocol.dart' as _il2as5qe;

/// Exposes Agent Reach's read-only channel actions to a learner identity.
/// The CLI runs under a HOME isolated to that learner's Serverpod identity.
/// {@category Endpoint}
class EndpointAgentReach extends _isc.EndpointRef {
  EndpointAgentReach(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'agentReach';

  /// Lists Agent Reach channels, actions, parameters and available backends.
  _ida.Future<String> channels() => caller.callServerEndpoint<String>(
    'agentReach',
    'channels',
    {},
  );

  /// Returns channel setup/health information scoped to this learner.
  _ida.Future<String> doctor() => caller.callServerEndpoint<String>(
    'agentReach',
    'doctor',
    {},
  );

  /// Runs one read-only channel action, for example `youtube subtitle` or
  /// `reddit read`. Parameters are JSON so newly added Agent Reach actions are
  /// available without another Serverpod schema change.
  _ida.Future<String> runAction(
    String channel,
    String action,
    String parametersJson, {
    String? backend,
    required int timeoutSeconds,
  }) => caller.callServerEndpoint<String>(
    'agentReach',
    'runAction',
    {
      'channel': channel,
      'action': action,
      'parametersJson': parametersJson,
      'backend': backend,
      'timeoutSeconds': timeoutSeconds,
    },
  );
}

/// Each guest receives a distinct, persisted Serverpod identity.
/// {@category Endpoint}
class EndpointAnonymousIdp extends _iaic.EndpointAnonymousIdpBase {
  EndpointAnonymousIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'anonymousIdp';

  _ida.Future<bool> isGuest() => caller.callServerEndpoint<bool>(
    'anonymousIdp',
    'isGuest',
    {},
  );

  /// Both identities must be proved: the request authenticates the guest and
  /// the fresh email access token proves ownership of the destination account.
  _ida.Future<void> upgrade(String accountToken) =>
      caller.callServerEndpoint<void>(
        'anonymousIdp',
        'upgrade',
        {'accountToken': accountToken},
      );

  /// Creates a new anonymous account and returns its session.
  ///
  /// Invokes the [AnonymousIdp.beforeAnonymousAccount] callback if configured,
  /// which may prevent account creation if the endpoint is protected.
  @override
  _ida.Future<_iacc.AuthSuccess> login({String? token}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'anonymousIdp',
        'login',
        {'token': token},
      );
}

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _iacc.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'jwtRefresh',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _isc.EndpointRef {
  EndpointGreeting(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _ida.Future<_i0sfqx47.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i0sfqx47.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// {@category Endpoint}
class EndpointLearnerState extends _isc.EndpointRef {
  EndpointLearnerState(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'learnerState';

  /// Retrieves the current vocabulary mastery state (recognized vs active/spoken words)
  /// for the authenticated user and target language.
  _ida.Future<_ij90w53a.LearnerState?> getLearnerState(String targetLanguage) =>
      caller.callServerEndpoint<_ij90w53a.LearnerState?>(
        'learnerState',
        'getLearnerState',
        {'targetLanguage': targetLanguage},
      );

  /// Records an EvidenceEvent (e.g. mini-game completion or spoken target word)
  /// and updates the user's LearnerState (recognized vs active words).
  _ida.Future<_i4nm32oi.EvidenceEvent> recordEvidenceEvent({
    required String targetLanguage,
    required String itemId,
    required String activityType,
    required String supportLevel,
    required bool spontaneous,
    required bool correct,
  }) => caller.callServerEndpoint<_i4nm32oi.EvidenceEvent>(
    'learnerState',
    'recordEvidenceEvent',
    {
      'targetLanguage': targetLanguage,
      'itemId': itemId,
      'activityType': activityType,
      'supportLevel': supportLevel,
      'spontaneous': spontaneous,
      'correct': correct,
    },
  );

  /// Fetches historical evidence events for tracking learner progress over time.
  _ida.Future<List<_i4nm32oi.EvidenceEvent>> getEvidenceHistory(
    String targetLanguage, {
    required int limit,
  }) => caller.callServerEndpoint<List<_i4nm32oi.EvidenceEvent>>(
    'learnerState',
    'getEvidenceHistory',
    {
      'targetLanguage': targetLanguage,
      'limit': limit,
    },
  );
}

/// House-style illustration via Muse Image (Meta Model API).
/// The style is locked server-side; callers pass only the subject.
/// {@category Endpoint}
class EndpointIllustration extends _isc.EndpointRef {
  EndpointIllustration(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'illustration';

  /// Illustrates [subject] (a scene or one-off picture) in the Talkloom
  /// house style. Returns base64 PNG/JPEG bytes for the client to cache.
  _ida.Future<String> illustrate(String subject) =>
      caller.callServerEndpoint<String>(
        'illustration',
        'illustrate',
        {'subject': subject},
      );

  /// Vocabulary art shared across all learners and languages, keyed by
  /// lower-cased lemma. First request generates and stores it; every later
  /// request (any learner, any language) reuses the stored bytes.
  _ida.Future<String> wordArt(
    String lemma,
    String language, {
    String? meaning,
  }) => caller.callServerEndpoint<String>(
    'illustration',
    'wordArt',
    {
      'lemma': lemma,
      'language': language,
      'meaning': meaning,
    },
  );
}

/// Combined vocabulary + grammar across all of one learner's lessons.
///
/// Per-video rows stay the source of truth (each lesson keeps its own
/// vocabulary/grammar JSON). This endpoint aggregates them on read using
/// canonical keys, so a short video and a long video teaching the same
/// grammar merge into one entry with references to every lesson it came
/// from. Filtering and sorting happen over the merged groups, not over
/// one-to-one lesson rows.
/// {@category Endpoint}
class EndpointKnowledge extends _isc.EndpointRef {
  EndpointKnowledge(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'knowledge';

  /// Merged vocabulary and grammar for [targetLanguage].
  ///
  /// Each entry carries `sources` (lessonId/sourceId/title per occurrence)
  /// so the learner can jump back to the video it came from. [query]
  /// filters by lemma/concept substring; [sort] is `recent` (default),
  /// `alpha`, or `coverage` (most sources first).
  _ida.Future<String> getCombinedKnowledge(
    String targetLanguage, {
    required String query,
    required String sort,
    required int limit,
  }) => caller.callServerEndpoint<String>(
    'knowledge',
    'getCombinedKnowledge',
    {
      'targetLanguage': targetLanguage,
      'query': query,
      'sort': sort,
      'limit': limit,
    },
  );

  /// Repairs the learner's own saved lessons against the current compiler
  /// gates: audits every lesson, recompiles the defective ones from source
  /// (refetching live content for links), and reports per-lesson results.
  /// Capped per call; each repair consumes daily AI quota like an import.
  _ida.Future<String> repairMyLessons(
    String targetLanguage, {
    required int maxRepairs,
  }) => caller.callServerEndpoint<String>(
    'knowledge',
    'repairMyLessons',
    {
      'targetLanguage': targetLanguage,
      'maxRepairs': maxRepairs,
    },
  );
}

/// {@category Endpoint}
class EndpointLessonCompiler extends _isc.EndpointRef {
  EndpointLessonCompiler(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'lessonCompiler';

  /// Compiles raw source text or structured input into a Lesson DSL object
  /// and saves it as a Serverpod Lesson entity.
  _ida.Future<_irv3hfbd.Lesson> compileLesson({
    required String sourceTitle,
    required String rawText,
    required String targetLanguage,
    required String supportLanguage,
    required String estimatedLevel,
    int? sourceId,
  }) => caller.callServerEndpoint<_irv3hfbd.Lesson>(
    'lessonCompiler',
    'compileLesson',
    {
      'sourceTitle': sourceTitle,
      'rawText': rawText,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'estimatedLevel': estimatedLevel,
      'sourceId': sourceId,
    },
  );
}

/// {@category Endpoint}
class EndpointPedagogical extends _isc.EndpointRef {
  EndpointPedagogical(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'pedagogical';

  /// Runs one tutor turn. When [lessonId] names a lesson the learner owns, an
  /// independent evaluator judges the learner utterance against that lesson's
  /// targets and the result is persisted; client flags are never trusted.
  _ida.Future<String> stepConversationTurn(
    String targetLanguage,
    String role,
    String situation,
    List<String> hiddenTargets,
    List<String> previousTurns,
    String learnerUtterance,
    double responseLatencySec, {
    int? lessonId,
  }) => caller.callServerEndpoint<String>(
    'pedagogical',
    'stepConversationTurn',
    {
      'targetLanguage': targetLanguage,
      'role': role,
      'situation': situation,
      'hiddenTargets': hiddenTargets,
      'previousTurns': previousTurns,
      'learnerUtterance': learnerUtterance,
      'responseLatencySec': responseLatencySec,
      'lessonId': lessonId,
    },
  );

  _ida.Future<_ij90w53a.LearnerState?> getLearnerState(String targetLanguage) =>
      caller.callServerEndpoint<_ij90w53a.LearnerState?>(
        'pedagogical',
        'getLearnerState',
        {'targetLanguage': targetLanguage},
      );

  _ida.Future<List<_i4nm32oi.EvidenceEvent>> getEvidenceHistory(
    String targetLanguage, {
    required int limit,
  }) => caller.callServerEndpoint<List<_i4nm32oi.EvidenceEvent>>(
    'pedagogical',
    'getEvidenceHistory',
    {
      'targetLanguage': targetLanguage,
      'limit': limit,
    },
  );

  /// The learner's server-verified per-target evidence. Owner-scoped.
  _ida.Future<List<_icmj5pil.WordEvidenceSummary>> getWordEvidenceSummary(
    String targetLanguage,
  ) => caller.callServerEndpoint<List<_icmj5pil.WordEvidenceSummary>>(
    'pedagogical',
    'getWordEvidenceSummary',
    {'targetLanguage': targetLanguage},
  );

  /// Recall bars per target (New/Fragile/Growing/Steady), computed on read
  /// from evaluated turns. No stored state, no migration.
  _ida.Future<String> getWordRecall(String targetLanguage) =>
      caller.callServerEndpoint<String>(
        'pedagogical',
        'getWordRecall',
        {'targetLanguage': targetLanguage},
      );
}

/// Video understanding via Muse Spark (Meta Model API, Responses API).
/// Accepts direct public mp4 URLs; YouTube watch pages are resolved to
/// playable media separately.
/// {@category Endpoint}
class EndpointVideo extends _isc.EndpointRef {
  EndpointVideo(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'video';

  /// Summarizes the footage and its embedded speech, with timestamped
  /// chapters for jumping back into the parts worth practicing.
  _ida.Future<String> describeVideo(
    String videoUrl,
    String language,
  ) => caller.callServerEndpoint<String>(
    'video',
    'describeVideo',
    {
      'videoUrl': videoUrl,
      'language': language,
    },
  );
}

/// {@category Endpoint}
class EndpointIngestion extends _isc.EndpointRef {
  EndpointIngestion(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'ingestion';

  /// Synchronous import kept for older clients. New clients use
  /// [startImport] and [watchImportJob].
  _ida.Future<_irv3hfbd.Lesson> processSourceAndCompile(
    String type,
    String title,
    String targetLanguage,
    String supportLanguage,
    String cefrLevel,
    String? url,
    String? rawContent,
  ) => caller.callServerEndpoint<_irv3hfbd.Lesson>(
    'ingestion',
    'processSourceAndCompile',
    {
      'type': type,
      'title': title,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'cefrLevel': cefrLevel,
      'url': url,
      'rawContent': rawContent,
    },
  );

  /// Validates the request, records an [ImportJob] and hands compilation to
  /// a Future Call. Returns at once; follow it with [watchImportJob].
  _ida.Future<_ikhpiv0x.ImportJob> startImport(
    String type,
    String title,
    String targetLanguage,
    String supportLanguage,
    String cefrLevel,
    String? url,
    String? rawContent,
  ) => caller.callServerEndpoint<_ikhpiv0x.ImportJob>(
    'ingestion',
    'startImport',
    {
      'type': type,
      'title': title,
      'targetLanguage': targetLanguage,
      'supportLanguage': supportLanguage,
      'cefrLevel': cefrLevel,
      'url': url,
      'rawContent': rawContent,
    },
  );

  /// The caller's own job, or null for a missing or foreign id.
  _ida.Future<_ikhpiv0x.ImportJob?> getImportJob(int jobId) =>
      caller.callServerEndpoint<_ikhpiv0x.ImportJob?>(
        'ingestion',
        'getImportJob',
        {'jobId': jobId},
      );

  /// Pushes progress for one of the caller's import jobs: the current state
  /// first, then each stage until saved or failed. Another learner's job id
  /// fails exactly like a missing one.
  _ida.Stream<_inw88992.ImportJobProgress> watchImportJob(int jobId) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_inw88992.ImportJobProgress>,
        _inw88992.ImportJobProgress
      >(
        'ingestion',
        'watchImportJob',
        {'jobId': jobId},
        {},
      );

  _ida.Future<List<_ikpsvynv.Source>> listSources(
    String targetLanguage, {
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_ikpsvynv.Source>>(
    'ingestion',
    'listSources',
    {
      'targetLanguage': targetLanguage,
      'limit': limit,
      'offset': offset,
    },
  );

  _ida.Future<_irv3hfbd.Lesson?> getLessonBySourceId(int sourceId) =>
      caller.callServerEndpoint<_irv3hfbd.Lesson?>(
        'ingestion',
        'getLessonBySourceId',
        {'sourceId': sourceId},
      );

  /// Recompiles one owned source with the current lesson compiler and
  /// writes the improved lesson back to the shared analysis, so future
  /// importers of the same material benefit too.
  _ida.Future<_irv3hfbd.Lesson> refreshLesson(int sourceId) =>
      caller.callServerEndpoint<_irv3hfbd.Lesson>(
        'ingestion',
        'refreshLesson',
        {'sourceId': sourceId},
      );

  _ida.Future<List<_irv3hfbd.Lesson>> listLessons(
    String targetLanguage, {
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_irv3hfbd.Lesson>>(
    'ingestion',
    'listLessons',
    {
      'targetLanguage': targetLanguage,
      'limit': limit,
      'offset': offset,
    },
  );

  _ida.Future<bool> removeSource(int sourceId) =>
      caller.callServerEndpoint<bool>(
        'ingestion',
        'removeSource',
        {'sourceId': sourceId},
      );

  _ida.Future<bool> restoreSource(int sourceId) =>
      caller.callServerEndpoint<bool>(
        'ingestion',
        'restoreSource',
        {'sourceId': sourceId},
      );
}

/// {@category Endpoint}
class EndpointSpeech extends _isc.EndpointRef {
  EndpointSpeech(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'speech';

  /// Transcribes learner audio with Muse Voice Transcribe via the Meta
  /// Model API — the only cloud speech provider in this project.
  /// [base64Audio] must be mono 16-bit PCM WAV (16 or 24 kHz).
  _ida.Future<String> transcribe(
    String base64Audio,
    String language, {
    List<String>? vocabulary,
  }) => caller.callServerEndpoint<String>(
    'speech',
    'transcribe',
    {
      'base64Audio': base64Audio,
      'language': language,
      'vocabulary': vocabulary,
    },
  );

  /// Spoken output via the self-hosted open-source voice worker (Piper).
  /// Meta offers no TTS, so an open model fills the gap; all language
  /// understanding stays Meta-only. The client falls back to on-device
  /// speech when the worker is unreachable.
  _ida.Future<String> synthesize(
    String text,
    String language, {
    String? voice,
  }) => caller.callServerEndpoint<String>(
    'speech',
    'synthesize',
    {
      'text': text,
      'language': language,
      'voice': voice,
    },
  );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _iacc.Caller serverpod_auth_core;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    agentReach = EndpointAgentReach(this);
    anonymousIdp = EndpointAnonymousIdp(this);
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    greeting = EndpointGreeting(this);
    learnerState = EndpointLearnerState(this);
    illustration = EndpointIllustration(this);
    knowledge = EndpointKnowledge(this);
    lessonCompiler = EndpointLessonCompiler(this);
    pedagogical = EndpointPedagogical(this);
    video = EndpointVideo(this);
    ingestion = EndpointIngestion(this);
    speech = EndpointSpeech(this);
    modules = Modules(this);
  }

  late final EndpointAgentReach agentReach;

  late final EndpointAnonymousIdp anonymousIdp;

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointGreeting greeting;

  late final EndpointLearnerState learnerState;

  late final EndpointIllustration illustration;

  late final EndpointKnowledge knowledge;

  late final EndpointLessonCompiler lessonCompiler;

  late final EndpointPedagogical pedagogical;

  late final EndpointVideo video;

  late final EndpointIngestion ingestion;

  late final EndpointSpeech speech;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'agentReach': agentReach,
    'anonymousIdp': anonymousIdp,
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'greeting': greeting,
    'learnerState': learnerState,
    'illustration': illustration,
    'knowledge': knowledge,
    'lessonCompiler': lessonCompiler,
    'pedagogical': pedagogical,
    'video': video,
    'ingestion': ingestion,
    'speech': speech,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
