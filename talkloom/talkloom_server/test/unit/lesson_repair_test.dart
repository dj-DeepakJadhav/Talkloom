import 'package:test/test.dart';
import 'package:talkloom_server/src/generated/protocol.dart';
import 'package:talkloom_server/src/lessons/lesson_repair_service.dart';

Lesson lessonWith({
  required String vocabulary,
  required String grammar,
  required String activities,
}) => Lesson(
  userId: 'u',
  sourceId: 1,
  targetLanguage: 'de',
  supportLanguage: 'en',
  objectives: ['Greet people'],
  vocabulary: vocabulary,
  grammar: grammar,
  activities: activities,
  conversationPlan:
      '{"role":"driver","situation":"taxi","hiddenTargets":["de:zentrum"],"culturalNotes":[],"successCriteria":{"spontaneousTargetCount":1}}',
  createdAt: DateTime.now(),
);

const cleanVocab =
    '[{"id":"de:zentrum","lemma":"Zentrum","article":"das","meaning":"city center","sourceContext":"Ins Zentrum bitte.","learnerState":"recognized_not_active"}]';
const cleanGrammar =
    '[{"concept":"Wechselpräpositionen mit Akkusativ","sourceSentence":"Fahren Sie bitte ins Zentrum der Stadt.","explanation":"Nach Wechselpraepositionen wie in steht der Akkusativ, sobald eine Richtung oder ein Ziel beschrieben wird."}]';
const cleanBuilder =
    '[{"type":"sentence_builder","target":"Fahren Sie bitte ins Zentrum","scrambledTokens":["Zentrum","Fahren","ins","bitte","Sie"]}]';

void main() {
  group('LessonRepairService.audit', () {
    test('clean lesson passes', () {
      expect(
        LessonRepairService.audit(
          null,
          lessonWith(
            vocabulary: cleanVocab,
            grammar: cleanGrammar,
            activities: cleanBuilder,
          ),
        ),
        isNull,
      );
    });

    test('screenshot builder is defective', () {
      expect(
        LessonRepairService.audit(
          null,
          lessonWith(
            vocabulary: cleanVocab,
            grammar: cleanGrammar,
            activities:
                '[{"type":"sentence_builder","target":"- die Spaghetti (Plural): spaghetti","scrambledTokens":["-","Spaghetti","die","spaghetti","(Plural):"]}]',
          ),
        ),
        anyOf('dirty_builder_target', 'junk_builder_token'),
      );
    });

    test('tautological grammar is defective', () {
      expect(
        LessonRepairService.audit(
          null,
          lessonWith(
            vocabulary: cleanVocab,
            grammar:
                '[{"concept":"Ins for destination","sourceSentence":"Ins Zentrum bitte","explanation":"Ins names the destination."}]',
            activities: cleanBuilder,
          ),
        ),
        isNotNull,
      );
    });
  });
}
