import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/anonymous.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// Each guest receives a distinct, persisted Serverpod identity.
class AnonymousIdpEndpoint extends AnonymousIdpBaseEndpoint {
  Future<bool> isGuest(Session session) async {
    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) {
      throw StateError('A private session is required.');
    }
    final id = UuidValue.withValidation(userIdentifier);
    return await AnonymousAccount.db.findFirstRow(
              session,
              where: (t) => t.authUserId.equals(id),
            ) !=
            null &&
        !await AuthServices.instance.emailIdp.hasAccount(session);
  }

  /// Both identities must be proved: the request authenticates the guest and
  /// the fresh email access token proves ownership of the destination account.
  Future<void> upgrade(Session session, String accountToken) async {
    if (!await isGuest(session)) throw StateError('Only guests can upgrade.');
    final target = await AuthServices.instance.authenticationHandler(
      session,
      accountToken,
    );
    final targetIdentifier = target?.userIdentifier;
    if (targetIdentifier == null) {
      throw StateError('Account authentication expired.');
    }
    final targetId = UuidValue.withValidation(targetIdentifier);
    final email = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(targetId),
    );
    if (email == null) throw StateError('Verify an email account first.');
    await AuthServices.instance.accountMerger.merge(
      session,
      userToKeepId: targetId,
      userToRemoveId: UuidValue.withValidation(
        session.authenticated!.userIdentifier,
      ),
    );
  }
}
