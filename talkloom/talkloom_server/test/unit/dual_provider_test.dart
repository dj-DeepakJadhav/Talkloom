import 'dart:convert';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/tavily_service.dart';
import 'package:talkloom_server/src/services/dual_ai_compiler_service.dart';
import 'package:talkloom_server/src/services/dual_pedagogical_agent_service.dart';
import 'package:talkloom_server/src/services/ingestion_service.dart';

void main() {
  group('Dual AI Compiler Tests (Gemini & Nebius modes)', () {
    test('compiles structured Lesson DSL via fallback/mock when keys absent', () async {
      final compilerGemini = DualLessonCompilerService(
        provider: AiProvider.gemini,
        geminiApiKey: '',
      );
      final tavily = TavilyService(apiKey: '');
      final grounding = await tavily.groundTopic(
        topic: 'Apartment Hunting',
        targetLanguage: 'de',
        contextSnippet: 'Mietvertrag details',
      );

      final dsl = await compilerGemini.compileLesson(
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
      expect(dsl['conversation']['role'], isA<String>());
      expect((dsl['conversation']['role'] as String).isNotEmpty, isTrue);
      expect((dsl['conversation']['hiddenTargets'] as List).isNotEmpty, isTrue);

      final compilerNebius = DualLessonCompilerService(
        provider: AiProvider.nebius,
        nebiusApiKey: '',
      );
      final dslNebius = await compilerNebius.compileLesson(
        sourceTitle: 'German Apartment Contract',
        rawText: 'Die Kaution beträgt drei Monatskaltmieten. Nebenkosten sind extra.',
        targetLanguage: 'de',
        supportLanguage: 'en',
        estimatedLevel: 'B1',
        grounding: grounding,
      );
      expect(dslNebius['objectives'], isA<List>());

      final compilerNvidia = DualLessonCompilerService(
        provider: AiProvider.nvidia,
        nvidiaApiKey: '',
      );
      final dslNvidia = await compilerNvidia.compileLesson(
        sourceTitle: 'German Apartment Contract',
        rawText: 'Die Kaution beträgt drei Monatskaltmieten. Nebenkosten sind extra.',
        targetLanguage: 'de',
        supportLanguage: 'en',
        estimatedLevel: 'B1',
        grounding: grounding,
      );
      expect(dslNvidia['objectives'], isA<List>());
    });
  });

  group('Dual Pedagogical Agent State Machine & Telemetry Tests', () {
    test('detects spontaneous production of target vocabulary with Gemini provider mode', () async {
      final agent = DualPedagogicalAgentService(
        provider: AiProvider.gemini,
        geminiApiKey: '',
      );
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
      expect(telemetry.cognitiveLoad, contains('Low'));
      expect(telemetry.activeMission.toLowerCase(), contains('kaution'));
      expect(telemetry.reply.isNotEmpty, isTrue);
    });

    test('adapts tactic when hesitation/latency is elevated with Nebius provider mode', () async {
      final agent = DualPedagogicalAgentService(
        provider: AiProvider.nebius,
        nebiusApiKey: '',
      );
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
      expect(telemetry.cognitiveLoad, contains('High'));
      expect(telemetry.activeTactic, contains('Simplify'));
    });

    test('steers conversation accurately with direct NVIDIA NIM provider mode', () async {
      final agent = DualPedagogicalAgentService(
        provider: AiProvider.nvidia,
        nvidiaApiKey: '',
      );
      final telemetry = await agent.stepConversation(
        targetLanguage: 'de',
        role: 'landlord',
        situation: 'apartment viewing in Berlin',
        hiddenTargets: ['de:kaution'],
        previousTurns: [],
        learnerUtterance: 'Die Kaution ist bezahlt.',
        responseLatencySec: 1.0,
      );

      expect(telemetry.targetProducedSpontaneously, isTrue);
      expect(telemetry.detectedTarget, equals('kaution'));
      expect(telemetry.reply.isNotEmpty, isTrue);
    });
  });

  group('Universal Ingestion Pipeline Tests (YouTube & Multimodal OCR)', () {
    test('extracts textual content from document and image media via fallback and Base64', () async {
      final ingestion = IngestionService();
      final base64Doc = 'Mietvertrag für Wohnräume. Kaution: 3 Monatskaltmieten.';
      final encoded = base64Encode(utf8.encode(base64Doc));

      final extracted = await ingestion.extractTextFromMedia(
        base64Data: encoded,
        mimeType: 'text/plain',
        provider: AiProvider.gemini,
      );

      expect(extracted.isNotEmpty, isTrue);
      expect(extracted.contains('Mietvertrag') || extracted.contains('Kaution'), isTrue);
    });

    test('extracts YouTube transcript structure from video link', () async {
      final ingestion = IngestionService();
      final transcript = await ingestion.ingestUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ');

      expect(transcript.isNotEmpty, isTrue);
      expect(transcript.contains('YouTube') || transcript.contains('Video') || transcript.contains('Transcript'), isTrue);
    });
  });
}
