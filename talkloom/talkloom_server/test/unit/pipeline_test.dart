import 'package:test/test.dart';
import 'package:talkloom_server/src/services/tavily_service.dart';
import 'package:talkloom_server/src/services/lesson_compiler_service.dart';
import 'package:talkloom_server/src/services/pedagogical_agent_service.dart';

void main() {
  group('Tavily Context Grounding Engine Tests', () {
    test('grounds German apartment rental topic with statutory and cultural facts', () async {
      final tavily = TavilyService(apiKey: ''); // Tests fallback/mock grounding logic
      final result = await tavily.groundTopic(
        topic: 'Mietvertrag Berlin',
        targetLanguage: 'de',
        contextSnippet: 'Apartment contract in Berlin with Kaution and Nebenkosten.',
      );

      expect(result.culturalFacts.isNotEmpty, isTrue);
      expect(result.statutoryRules.isNotEmpty, isTrue);
      expect(result.culturalFacts.any((f) => f.contains('Nebenkosten') || f.contains('kitchen') || f.contains('Ruhezeit')), isTrue);
      expect(result.statutoryRules.any((r) => r.contains('Kaution') || r.contains('Mietpreisbremse')), isTrue);
    });
  });

  group('Pedagogical Lesson Compiler Tests', () {
    test('compiles structured Lesson DSL with objectives, vocabulary, grammar, and activities', () async {
      final compiler = LessonCompilerService(nebiusApiKey: '');
      final tavily = TavilyService(apiKey: '');
      final grounding = await tavily.groundTopic(
        topic: 'Apartment Hunting',
        targetLanguage: 'de',
        contextSnippet: 'Mietvertrag details',
      );

      final dsl = await compiler.compileLesson(
        sourceTitle: 'German Apartment Contract',
        rawText: 'Die Kaution beträgt drei Monatskaltmieten. Nebenkosten sind extra.',
        targetLanguage: 'de',
        supportLanguage: 'en',
        estimatedLevel: 'B1',
        grounding: grounding,
      );

      expect(dsl['objectives'], isA<List>());
      expect((dsl['objectives'] as List).isNotEmpty, isTrue);
      expect(dsl['vocabulary'], isA<List>());
      expect((dsl['vocabulary'] as List).length, greaterThanOrEqualTo(2));
      expect(dsl['grammar'], isA<List>());
      expect(dsl['activities'], isA<List>());
      expect(dsl['conversation'], isA<Map>());
      expect(dsl['conversation']['role'], equals('landlord'));
      expect((dsl['conversation']['hiddenTargets'] as List).contains('de:kaution'), isTrue);
    });
  });

  group('Pedagogical Agent State Machine & Telemetry Tests', () {
    test('detects spontaneous production of target vocabulary and modulates cognitive load', () async {
      final agent = PedagogicalAgentService(nebiusApiKey: '');
      final telemetry = await agent.stepConversation(
        targetLanguage: 'de',
        role: 'landlord',
        situation: 'apartment viewing in Berlin',
        hiddenTargets: ['de:kaution', 'de:nebenkosten', 'de:einziehen'],
        previousTurns: [],
        learnerUtterance: 'Wie hoch ist die Kaution für die Wohnung?',
        responseLatencySec: 1.2,
      );

      expect(telemetry.targetProducedSpontaneously, isTrue);
      expect(telemetry.detectedTarget, equals('kaution'));
      expect(telemetry.cognitiveLoad, contains('Normal'));
      expect(telemetry.activeMission.toLowerCase(), contains('kaution'));
      expect(telemetry.reply.isNotEmpty, isTrue);
    });

    test('adapts tactic when hesitation/latency is elevated', () async {
      final agent = PedagogicalAgentService(nebiusApiKey: '');
      final telemetry = await agent.stepConversation(
        targetLanguage: 'de',
        role: 'landlord',
        situation: 'apartment viewing in Berlin',
        hiddenTargets: ['de:kaution', 'de:nebenkosten'],
        previousTurns: [],
        learnerUtterance: 'Ich... äh... weiß nicht genau.',
        responseLatencySec: 4.5,
      );

      expect(telemetry.targetProducedSpontaneously, isFalse);
      expect(telemetry.cognitiveLoad, contains('Hesitation'));
      expect(telemetry.activeTactic, contains('Simplify'));
    });
  });
}
