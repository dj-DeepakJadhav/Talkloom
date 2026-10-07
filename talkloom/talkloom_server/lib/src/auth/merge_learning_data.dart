import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// All ownership changes participate in the auth module's merge transaction.
Future<void> mergeLearningData(
  Session session, {
  required UuidValue userToKeepId,
  required UuidValue userToRemoveId,
  required Transaction transaction,
}) async {
  final keep = userToKeepId.toString();
  final remove = userToRemoveId.toString();
  await Source.db.updateWhere(
    session,
    where: (t) => t.userId.equals(remove),
    columnValues: (t) => [t.userId(keep)],
    transaction: transaction,
  );
  await Lesson.db.updateWhere(
    session,
    where: (t) => t.userId.equals(remove),
    columnValues: (t) => [t.userId(keep)],
    transaction: transaction,
  );
  await EvidenceEvent.db.updateWhere(
    session,
    where: (t) => t.userId.equals(remove),
    columnValues: (t) => [t.userId(keep)],
    transaction: transaction,
  );
  final states = await LearnerState.db.find(
    session,
    where: (t) => t.userId.equals(remove),
    transaction: transaction,
  );
  for (final guest in states) {
    final existing = await LearnerState.db.findFirstRow(
      session,
      where: (t) =>
          t.userId.equals(keep) & t.targetLanguage.equals(guest.targetLanguage),
      transaction: transaction,
    );
    if (existing == null) {
      await LearnerState.db.updateRow(
        session,
        guest.copyWith(userId: keep),
        transaction: transaction,
      );
    } else {
      final grammar = <String, dynamic>{
        ...jsonDecode(guest.grammarMastery) as Map<String, dynamic>,
        ...jsonDecode(existing.grammarMastery) as Map<String, dynamic>,
      };
      await LearnerState.db.updateRow(
        session,
        existing.copyWith(
          recognizedWords: {
            ...existing.recognizedWords,
            ...guest.recognizedWords,
          }.toList(),
          activeWords: {...existing.activeWords, ...guest.activeWords}.toList(),
          grammarMastery: jsonEncode(grammar),
          updatedAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
      await LearnerState.db.deleteRow(session, guest, transaction: transaction);
    }
  }
}
