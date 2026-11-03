import 'package:test/test.dart';
import 'package:talkloom_server/src/evidence/recall_projection.dart';

RecallObservation independent(DateTime at) =>
    RecallObservation(at: at, independent: true, lapse: false);

RecallObservation lapse(DateTime at) =>
    RecallObservation(at: at, independent: false, lapse: true);

void main() {
  group('projectRecall', () {
    test('no independent use is New with no due date', () {
      final state = projectRecall(
        [lapse(DateTime.utc(2026, 10, 1))],
        now: DateTime.utc(2026, 10, 10),
      );

      expect(state.bars, 0);
      expect(state.label, 'New');
      expect(state.dueAt, isNull);
      expect(state.independentUses, 0);
    });

    test('one independent use is Fragile', () {
      final state = projectRecall(
        [independent(DateTime.utc(2026, 10, 1))],
        now: DateTime.utc(2026, 10, 1, 12),
      );

      expect(state.bars, 1);
      expect(state.label, 'Fragile');
      expect(state.dueAt, DateTime.utc(2026, 10, 2));
    });

    test('two distinct days is Growing', () {
      final state = projectRecall(
        [
          independent(DateTime.utc(2026, 10, 1)),
          independent(DateTime.utc(2026, 10, 3)),
        ],
        now: DateTime.utc(2026, 10, 3, 12),
      );

      expect(state.bars, 2);
      expect(state.label, 'Growing');
    });

    test('three days spanning a week is Steady', () {
      final state = projectRecall(
        [
          independent(DateTime.utc(2026, 10, 1)),
          independent(DateTime.utc(2026, 10, 4)),
          independent(DateTime.utc(2026, 10, 9)),
        ],
        now: DateTime.utc(2026, 10, 9, 12),
      );

      expect(state.bars, 3);
      expect(state.label, 'Steady');
    });

    test('three days inside one week stays Growing', () {
      final state = projectRecall(
        [
          independent(DateTime.utc(2026, 10, 1)),
          independent(DateTime.utc(2026, 10, 2)),
          independent(DateTime.utc(2026, 10, 3)),
        ],
        now: DateTime.utc(2026, 10, 3, 12),
      );

      expect(state.bars, 2);
    });

    test('a later lapse weakens the trace to Fragile', () {
      final state = projectRecall(
        [
          independent(DateTime.utc(2026, 10, 1)),
          independent(DateTime.utc(2026, 10, 3)),
          lapse(DateTime.utc(2026, 10, 4)),
        ],
        now: DateTime.utc(2026, 10, 4, 12),
      );

      expect(state.bars, 1);
      expect(state.label, 'Fragile');
    });

    test('overdue words decay one bar', () {
      final state = projectRecall(
        [
          independent(DateTime.utc(2026, 10, 1)),
          independent(DateTime.utc(2026, 10, 3)),
        ],
        now: DateTime.utc(2026, 10, 20),
      );

      // Due 4 days after Oct 3; three weeks later it has faded one bar.
      expect(state.bars, 1);
    });

    test('repetitions on one day do not add bars', () {
      final state = projectRecall(
        [
          independent(DateTime.utc(2026, 10, 1, 9)),
          independent(DateTime.utc(2026, 10, 1, 12)),
          independent(DateTime.utc(2026, 10, 1, 18)),
        ],
        now: DateTime.utc(2026, 10, 1, 20),
      );

      expect(state.bars, 1);
    });
  });
}
