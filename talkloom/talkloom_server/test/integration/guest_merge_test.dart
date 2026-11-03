import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/anonymous.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:talkloom_server/src/auth/merge_learning_data.dart';
import 'package:talkloom_server/src/auth/anonymous_idp_endpoint.dart';
import 'package:talkloom_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Guest conversion', (builder, endpoints) {
    test(
      'verified email account receives guest data through native auth merge',
      () async {
        final session = builder.build();
        try {
          session.serverpod.initializeAuthServices(
            tokenManagerBuilders: [JwtConfigFromPasswords()],
            identityProviderBuilders: [
              AnonymousIdpConfig(),
              ServerpodCloudEmailIdpConfig(appDisplayName: 'test'),
            ],
            accountMergeConfig: AccountMergeConfig(
              applicationMergeHandler: mergeLearningData,
            ),
          );
          final services = AuthServices.instance;
          final guest = await services.anonymousIdp.login(session);
          final user = await services.authUsers.create(session);
          await services.userProfiles.createUserProfile(
            session,
            user.id,
            UserProfileData(),
          );
          await services.emailIdp.admin.createEmailAuthentication(
            session,
            authUserId: user.id,
            email: 'conversion-test@example.com',
            password: 'StrongGuestPassword123!',
          );
          final account = await services.emailIdp.login(
            session,
            email: 'conversion-test@example.com',
            password: 'StrongGuestPassword123!',
          );
          final source = await Source.db.insertRow(
            session,
            Source(
              userId: guest.authUserId.toString(),
              type: 'text',
              rawText: 'Hallo',
              title: 'Private guest source',
              targetLanguage: 'de',
              cefrLevel: 'A1',
              createdAt: DateTime.utc(2026),
            ),
          );
          final guestSession = builder
              .copyWith(
                authentication: AuthenticationOverride.authenticationInfo(
                  guest.authUserId.toString(),
                  const {},
                ),
              )
              .build();
          try {
            await expectLater(
              AnonymousIdpEndpoint().upgrade(guestSession, 'forged'),
              throwsStateError,
            );
            await AnonymousIdpEndpoint().upgrade(guestSession, account.token);
            expect(
              (await Source.db.findById(session, source.id!))!.userId,
              account.authUserId.toString(),
            );
            expect(
              await AuthUser.db.findById(session, guest.authUserId),
              isNull,
            );
          } finally {
            await guestSession.close();
          }
        } finally {
          await session.close();
        }
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
  withServerpod('Guest data ownership', (builder, endpoints) {
    test(
      'anonymous visitors cannot claim a guest or request a merge',
      () async {
        final session = builder.build();
        try {
          await expectLater(
            AnonymousIdpEndpoint().isGuest(session),
            throwsStateError,
          );
          await expectLater(
            AnonymousIdpEndpoint().upgrade(session, 'forged'),
            throwsStateError,
          );
        } finally {
          await session.close();
        }
      },
    );
    test(
      'conversion moves sources, lessons, evidence and combines progress',
      () async {
        final session = builder.build();
        final guest = UuidValue.fromString(
          '00000000-0000-4000-8000-000000000011',
        );
        final account = UuidValue.fromString(
          '00000000-0000-4000-8000-000000000012',
        );
        try {
          final source = await Source.db.insertRow(
            session,
            Source(
              userId: guest.toString(),
              type: 'text',
              rawText: 'Hallo Welt',
              title: 'Guest import',
              targetLanguage: 'de',
              cefrLevel: 'A1',
              createdAt: DateTime.utc(2026),
            ),
          );
          final lesson = await Lesson.db.insertRow(
            session,
            Lesson(
              userId: guest.toString(),
              sourceId: source.id!,
              targetLanguage: 'de',
              supportLanguage: 'en',
              objectives: [],
              vocabulary: '[]',
              grammar: '[]',
              activities: '[]',
              conversationPlan: '{}',
              createdAt: DateTime.utc(2026),
            ),
          );
          final evidence = await EvidenceEvent.db.insertRow(
            session,
            EvidenceEvent(
              userId: guest.toString(),
              targetLanguage: 'de',
              itemId: 'hallo',
              activityType: 'speaking',
              supportLevel: 'none',
              spontaneous: true,
              correct: true,
              timestamp: DateTime.utc(2026),
            ),
          );
          for (final id in [guest, account]) {
            await LearnerState.db.insertRow(
              session,
              LearnerState(
                userId: id.toString(),
                targetLanguage: 'de',
                recognizedWords: [id == guest ? 'hallo' : 'welt'],
                activeWords: ['hallo'],
                grammarMastery: '{}',
                updatedAt: DateTime.utc(2026),
              ),
            );
          }
          await session.db.transaction(
            (tx) => mergeLearningData(
              session,
              userToKeepId: account,
              userToRemoveId: guest,
              transaction: tx,
            ),
          );
          expect(
            (await Source.db.findById(session, source.id!))!.userId,
            account.toString(),
          );
          expect(
            (await Lesson.db.findById(session, lesson.id!))!.userId,
            account.toString(),
          );
          expect(
            (await EvidenceEvent.db.findById(session, evidence.id!))!.userId,
            account.toString(),
          );
          final states = await LearnerState.db.find(session);
          expect(states, hasLength(1));
          expect(
            states.single.recognizedWords,
            unorderedEquals(['hallo', 'welt']),
          );
          expect(states.single.activeWords, ['hallo']);
        } finally {
          await session.close();
        }
      },
    );
  });
}
