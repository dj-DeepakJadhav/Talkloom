# Talkloom fix loop — 6 October 2026

This is the active implementation tracker for the findings in
[`application_audit_2026-10-05.md`](application_audit_2026-10-05.md). A ticket is
closed only after code review, its acceptance tests pass, and its evidence is
recorded here. Tests and build success do not close device, provider, or deploy
gates that were not actually exercised.

## Assigned tickets

| Ticket | Owner | Scope | Acceptance gate | Status |
|---|---|---|---|---|
| SEC-01 | Backend security agent | Authenticated identity and per-user source/lesson/evidence isolation; SSRF-safe link and redirect handling; request, time and subprocess limits; honest extraction errors. | Two identities cannot observe or mutate one another's data; unauthenticated access is rejected; private/loopback/link-local destinations, unsafe redirects, oversized/slow responses are rejected; tests pass. | **Closed** — boundary tests pass; no positive client mastery flags accepted. |
| AI-02 | Backend lesson agent | Typed lesson validation, provider mapping, role-aware conversation history, evidence integrity, and honest degraded-mode results. | Malformed/sparse/unsupported lesson payloads cannot be persisted; provider selection maps correctly; assisted/fallback turns never become mastery evidence; tests cover regression cases. | **Closed** — full server suite passes; mastery remains intentionally disabled pending semantic evaluation. |
| UI-03 | Frontend agent | Real import-to-detail-to-speaking flow, voice lifecycle/fallback, misleading controls and mastery UI, accessible phone layout and source context. | Widget tests cover primary flow, errors, no fabricated progress, keyboard/safe-area behavior; analyze, test and builds pass. | **Closed** — 11 Flutter tests, Web release and Android debug build pass; iOS/device behavior remains a release gate. |
| REL-04 | Root | Root-level CI, dependency/runtime packaging, Docker image, upload limits, and reproducible setup/deployment instructions. | CI paths match the Git root and runs analysis/tests/builds without checked-in passwords; container builds and starts with its Python extractor; web/API URLs can be configured without rebuilding server code. | **In progress** — Docker image and extractor smoke checks pass; hosted GitHub Actions and production startup remain unverified. |
| DOC-05 | Root | Reconcile README, task list, pitch/demo/submission and reference documents with implemented behavior and this event. | No stale Nebius/NVIDIA claims, fake performance figures, localhost-as-live links, or unsupported delivered-feature claims remain. | **Closed** — drafts and audit reconciled; no public deployment claims. |
| LIVE-06 | Root + project owner | Production environment and real provider/device validation. | Fresh production deployment, migrations, user signup/isolation, real import/speak/persist path, Android/iOS camera/microphone and speech-output tests, and provider-backed checks pass. | Blocked on deployment destination, credentials, physical iOS/device access, and the not-yet-implemented native TTS path; code-side prep continues. |

## Integrated verification — 6 October 2026

| Area | Result | Limit |
|---|---|---|
| Serverpod `dart test` | Pass, 31/31 tests | Includes authenticated ownership boundaries, archived URL cache reuse, unauthorized calls, evidence-flag rejection, URL policy/fetch bounds, provider mapping, schema validation, role-aware history and fallback integrity. No live paid-provider response was tested. |
| Server `dart analyze` | Exit 0; two informational `avoid_print` notices | No warnings or errors. |
| Flutter `flutter analyze` | Pass | No analyzer findings. |
| Flutter `flutter test` | Pass, 11 tests | Covers content flow and false-progress regressions; not a live authenticated browser session. |
| Flutter Web release | Pass | Build only; hosted URL and fresh-account flow remain unverified. |
| Android debug APK | Pass | Build only; no physical device/permission test. |
| Docker build | Pass | Root-context build; image contains server binary, migrations, protocol and Python extractor dependency. Image was inspected without launching the app server. |
| Docker extractor check | Pass | `youtube_transcript_api` imports from the packaged interpreter. |
| GitHub Actions | Workflow added at root | Workflow has not run on GitHub; iOS compile job requires macOS CI. |
| Production/iOS | Open | No production host/provider credentials or Apple device/Xcode validation were provided. |

### Remaining product and release gates

- Mastery scoring is deliberately unavailable: word spotting and model replies do
  not establish semantic correctness. Add an independent evaluation step before
  allowing positive mastery evidence.
- Lesson provider/model and generation-status provenance are not persisted. This
  needs an explicit schema design and migration; current API only returns a
  validated lesson or a safe failure.
- URL cache reuse is verified for completed source-linked lessons, including
  after the original owner's source is archived. The current cache is derived
  from source rows and URL/language/level; there is no dedicated master-content
  table, provider/creator metadata index, or concurrency deduplication yet.
- Native Android/iOS speech output remains a no-op platform stub. Browser speech
  works where supported; self-hosted Qwen3-TTS or another mobile speech path is
  future implementation and must be tested before claiming mobile voice output.
- Agent Reach is still a reference, not the active resolver. Social links use
  the current Jina-based path with a clear failure response.
- Apply the source-archive migration to the target database and verify it during
  the first controlled deployment. Do not claim a production migration ran here.
- Run the root CI workflow on GitHub, deploy to a real host, test signup and
  cross-user isolation against that deployment, then validate Android/iOS camera,
  microphone, and speech behavior on devices.

## Ticket loop

1. Agents implement only their assigned files and add focused regression tests.
2. The root reviews each diff for security, generated-code edits, ticket overlap,
   and whether each acceptance test proves the behavior claimed.
3. The root runs the complete analyzer, backend and Flutter suites, Web and
   Android builds, and the Docker build after integration.
4. The audit, app instructions and submission/demo copy are reconciled with the
   tested result. Any missing external gate stays open with a concrete owner.

No production endpoint or third-party account has been supplied for LIVE-06.
Do not substitute example domains or claim a successful deployment. Serverpod
environment variables can override YAML configuration for public hosts, ports,
origins, request limits and passwords; see the
[Serverpod configuration reference](https://docs.serverpod.dev/concepts/lookups/configuration-reference).
