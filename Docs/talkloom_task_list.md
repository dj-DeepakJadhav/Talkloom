# Talkloom engineering status

Updated 6 October 2026. This file tracks verified product status; the active
owner/acceptance loop is [`fix_tickets_2026-10-06.md`](fix_tickets_2026-10-06.md).
Old checkboxes and submission claims were removed because they described
planned or mocked features as delivered.

## Product scope

Talkloom starts with German. Learners bring links, text, images or documents,
review the source-linked vocabulary and grammar, and use the material in
speaking practice. Additional languages, social-platform share targets, and
self-hosted Qwen3-TTS are future work until tested end to end.

## Verified locally

- Flutter analysis and 11 widget tests passed on 6 October.
- Server analysis and 31 tests passed, including authenticated ownership,
  security boundary, and lesson-compiler integration coverage.
- URL cache reuse still works after the original source is archived, while a
  returning learner receives an owner-scoped copy.
- Flutter Web release, Android debug APK, and Docker image builds passed.
- The generated Serverpod client now exposes the pedagogical endpoint; codegen
  ran after its endpoint changes.
- The YouTube transcript script returned a transcript for the shared German
  video when run with the server virtual environment.
- The default My German filter defect was fixed and is now covered by the
  source-linked collection test.
- Imported content failures are explicit, and lesson coverage is validated
  against source sentences before persistence.
- No positive mastery is awarded: the backend currently marks all speaking
  evidence ineligible until an independent semantic evaluator exists.

These checks do not establish physical-device permissions, iOS compilation,
authenticated production behavior, live provider responses, or successful
deployment.

## Not to present as shipped

- Production deployment or a public demo URL.
- Cross-user isolation has passing automated tests; production behavior still
  needs a fresh-account deployment test.
- Independent speaking mastery is not shipped until a semantic evaluator can
  verify correctness.
- Qwen3-TTS service/native audio playback or Agent Reach integration.
- A dedicated shared-content schema, provider/creator metadata, and concurrent
  URL-import deduplication; current cache reuse is URL/language/level based.
- Story/audio synchronization, creator links, ads/reward unlocks, verified CEFR
  grades, or speech/cognitive telemetry.
- Camera/microphone permission behavior on Android and iOS.

## Release gates

1. Run the root CI workflow on GitHub, including its macOS iOS compile job.
2. Configure a real deployment with secrets outside source control and apply
  migrations without losing existing user content.
3. From fresh accounts, test import → complete takeaways → speaking → saved
  history; confirm account isolation and failure/retry behavior.
4. Test camera, file selection, microphone denial/recovery, and voice playback
  on physical Android and iOS devices.
5. Add provider/model/status provenance to lesson persistence and design a
   semantic answer evaluation before re-enabling mastery scoring.
6. Only then record and submit a demo using measured, reproducible claims.
