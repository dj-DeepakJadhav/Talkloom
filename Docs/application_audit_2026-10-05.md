# Talkloom application and hackathon audit

Reviewed 5 October 2026 (Europe/Berlin). Source baseline: `d40470d`.

## Assessment

Talkloom has a real Flutter/Serverpod foundation, generated client, relational
models, and substantial UI work. It is not yet submission-ready. The largest
risks are the disconnected import-to-lesson flow, shared anonymous identity,
silent invented content, and progress indicators that overstate learning.
Finish one trustworthy experience before adding more features.

## Scope and initialization

Three parallel reviews covered backend/services/models/tests, Flutter
navigation/state/voice/UX, and all six existing Docs files plus root/package
READMEs, CLAUDE.md, manifests, deployment configuration and submission materials.
The primary review covered repository infrastructure, CI, packaging, memory,
source verification and the event rubric. This is a source/configuration audit
and bounded verification, not an exhaustive runtime or penetration test.

Codebase-memory-mcp was already connected and persistently configured locally,
but this repository had no index. Initialized a full persistent index:
`C-DJ-Hackathon-Talkloom-Talkloom`, 2,074 nodes, 5,641 edges. The artifact is
`.codebase-memory/graph.db.zst`. Added root AGENTS.md and memory architecture notes.
Graph discovery preceded source reads; filesystem fallbacks handled configs,
documents, literals and insufficient graph results. Source verification matters:
some Dart graph positions/complexity values do not capture whole implementations.

Serverpod and Dart runtime MCP tools are not exposed in this session. No
application server was started, following `talkloom/AGENTS.md`. The local
passwords.yaml is absent; secret environment values were not inspected. No live
provider call, public deployment, migration application or authenticated browser
flow was verified. No functional application source was changed by this audit.

## Event criteria

The supplied BuilderBase URL timed out. The organizer's
[Luma listing](https://luma.com/builde-mked) confirms a 14 October submission
deadline and these weights: functioning app 30%, meaningful Serverpod use 25%,
craft/technical creativity 25%, usefulness 20%. Submission happens in BuilderBase.
The exact cutoff hour/timezone and account-specific entry requirements still
need checking in the participant portal. As of 5 October, there are nine calendar
days until the listed deadline. Do not infer an exact midnight cutoff.

## Verification

| Check | Result | What it establishes |
|---|---|---|
| Server `dart analyze` | Exit 0; 21 informational `avoid_print` findings | No reported server analyzer errors after dependency resolution |
| Server `dart test test/unit` | All 10 passed | Mostly no-key/fallback behavior; not live providers or ownership |
| Server greeting integration test | Exit 1 after loading; no useful diagnostic captured | Database integration remains unverified |
| Flutter `flutter analyze` | Exit 0; no issues found | Static analysis succeeds |
| Flutter `flutter test` | Exit 1; one passed, one failed to load | Avatar test passes; main widget test blocked by web imports |
| Flutter `flutter build web --release --no-pub` | Exit 0; release build succeeded in 83.3 seconds | Web compilation succeeds; not public deployment or runtime validation |

Installed tooling was Flutter 3.47.4 / Dart 3.13.3. Project constraints require
Flutter ^3.44.4 / Dart ^3.12.2; CI pins Flutter 3.44.4. Initial unresolved-dependency
analyzer failures disappeared after dependency resolution and are not product
defects. Flutter tools touched generated native registration files; those
incidental changes were restored before concluding the audit.

## Fix before submitting

P1 means a release/demo blocker or serious integrity/security defect; P2 means
important reliability or quality work. Paths below are relative to this repo.

| Priority | Finding and evidence | Required improvement |
|---|---|---|
| P1 | Current route starts at AppShell (`talkloom/talkloom_flutter/lib/app/router.dart:20`), whose visible children are Talk/Themes/Words (`lib/features/shell/app_shell.dart:116`). UniversalIngestSheet, SourceList and SanctuaryScreen have no external instantiation. | Restore visible import → lesson → activity → conversation → progress navigation; expose language selection and identity setup. |
| P1 | Ingestion and learner endpoints permit login-free calls and fall back to one `guest_learner` (`talkloom/talkloom_server/lib/src/sources/ingestion_endpoint.dart:15`, `lib/src/learner/learner_state_endpoint.dart:8`). | Require Serverpod auth or isolated guest accounts; test two users cannot read/write each other's sources, lessons or evidence. |
| P1 | URL ingestion directly fetches caller URIs with no private-network/redirect checks, main-fetch timeout or response size cap (`lib/src/services/ingestion_service.dart:12`). | Restrict schemes, validate hosts/resolved addresses and redirects, block private/loopback/link-local destinations, bound size/time and request concurrency. |
| P1 | Import failures return invented source text; failed OCR returns a fixed German rental contract (`lib/src/services/ingestion_service.dart:61`, `:226`). | Return explicit extraction failures. Offer paste/retry or clearly labeled demo fixtures; never present generated substitutes as extracted originals. |
| P1 | Browser speech imports are unconditional (`talkloom/talkloom_flutter/lib/core/platform/web_voice_service.dart:2`). Main widget test cannot load, and native compilation is affected. | Add conditional web/native platform implementations; unsupported platforms must expose a usable text alternative. |
| P1 | Main mic ignores false from startListening (`lib/features/arena/talk_canvas_screen.dart:127`); browser errors/end are not forwarded (`web/index.html:84`). | Reflect actual speech state, permission denial, unsupported browser and ended recognition in the UI; reset/retry reliably. |
| P1 | BYOK fields are saved as JSON in SharedPreferences, labeled secure, but do not feed the repository/provider requests (`lib/app/providers.dart:214`, `:259`; `lib/features/settings/api_keys_screen.dart:54`). | Either wire supported provider settings end-to-end with suitable credential handling or remove this promise from the demo. |
| P1 | Spontaneous mastery is based on substring matching (`talkloom/talkloom_server/lib/src/services/dual_pedagogical_agent_service.dart:51`) and saved as correct/unsupported (`lib/src/lessons/pedagogical_endpoint.dart:74`). A fallback itself supplies the target word. | Track previous assistance, check contextual correctness and all produced targets, distinguish prompted repetition from spontaneous production. |
| P1 | Caller-supplied correctness/spontaneity directly promotes mastery (`lib/src/learner/learner_state_endpoint.dart:31`). | Validate against owned lesson/activity on the server; client observations must not be authoritative assessments. |
| P1 | CI exists only under `talkloom/.github/workflows`, but Git root is its parent. Even after relocation, pub get and working-directory paths are wrong (`analyze.yml:20`). | Move workflows to root `.github/workflows`, set the workspace/package directories correctly, include Flutter and backend tests. GitHub requires root workflow placement: [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax). |
| P1 | Docker builds with Dart only while server depends on google_fonts, which requires the Flutter SDK (`talkloom/talkloom_server/pubspec.yaml:12`; Dockerfile:5,18). Runtime copies omit Python and scripts used for YouTube extraction. | Remove UI dependency from backend; make ingestion dependencies deployable or use a supported extraction service. These are static packaging defects; container build was not run. |
| P1 | Judge delivery remains unproven: production/staging hosts are examplepod placeholders; client config defaults to localhost; submission links point to the wrong repository/local machine. | Deploy a real public environment, verify API URL/migrations/auth/secrets and complete the flow from a fresh browser. Environment overrides may exist outside the repo; none were verified. |
| P2 | Generated DSL is merely JSON-decoded; required fields and cross-references are not validated (`lib/src/services/dual_ai_compiler_service.dart:259`, `:363`, `:469`, `:573`). | Validate a typed/schema-constrained lesson before persistence, with bounded repair/retry and explicit errors. |
| P2 | Lesson/evidence JSON is stored in string fields; generation and grounding provenance are lost. Silent provider errors produce generic lessons (`dual_ai_compiler_service.dart:147`; tavily_service.dart:34,93). | Persist extraction/generation status, provider/model and citations; make degraded mode visible; use typed protocol objects where practical. |
| P2 | Event insert and learner read/modify/write are separate; learner model lacks a unique user/language constraint (`learner_state_endpoint.dart:53`; learner_state.spy.yaml). | Add unique constraint, transactional updates, concurrency tests and idempotency. Ensure active words remain a subset of recognized words; unify the conversation update path. |
| P2 | Gemini is mapped to NVIDIA in two routes (`lesson_compiler_endpoint.dart:37`; pedagogical_endpoint.dart:41`). Nonzero source ID is not checked for ownership/existence (`lesson_compiler_endpoint.dart:71`). | Centralize provider config and validate the owned source before compilation. |
| P2 | Client sends tutor-only history (`talk_canvas_screen.dart:164`), and backend marks every prior turn assistant (`dual_pedagogical_agent_service.dart:346`, `:406`, `:467`). | Send typed learner/tutor turns with roles; preserve context and assistance history. |
| P2 | Words screen uses sample fallback, index-based mastery bars and fixed Growing detail (`words_screen.dart:183`, `:346`, `:131`). | Read real persisted evidence; empty state should explain how to build a vocabulary collection. Filtering must not change apparent mastery. |
| P2 | Generated replies lack translation; Meaning shows a placeholder (`talk_canvas_screen.dart:174`, `:509`). Story/audio and lesson speaker controls often animate without audio (`story_weaver_screen.dart:30,51`; lesson_screen.dart:415; activity_view.dart:130`). | Implement actual behavior or remove/label unavailable controls; avoid simulated evidence in the submission. |
| P2 | GestureDetector-only controls lack keyboard/focus semantics (`design/components/tl_surface.dart:122`; shell/app_shell.dart:283`); General Talk does not clear selected theme (`shell:44`). | Use accessible interactive widgets and verify focus, keyboard operation, semantics and theme reset. |
| P2 | Production maxRequestSize is 524288 bytes; base64 increases media size by roughly one third. | Set explicit document/image limits, compress when appropriate and display size errors before upload; prefer storage-backed uploads for larger media. |

## Documentation reconciliation

| Document | Change needed |
|---|---|
| README.md | Target Serverpod event rather than Nebius/NVIDIA; correct nested paths, actual runtime commands, tooling and secret setup; replace delivered-feature claims with verified status. MIT is claimed but no LICENSE exists. |
| Docs/talkloom_hackathon_idea.md | Narrow the user/problem/flow; keep its useful distinction between product heuristics and formal assessments; remove event-specific prize strategy. |
| Docs/talkloom_task_list.md | Replace misleading checked completion markers with implemented / verified / mocked / deferred status. Auth marked fixed contradicts shared guest identity; release build is not live deployment; creator links are later described as removed. |
| Docs/talkloom_design_specification.md | Reconcile planned five-tab layout with actual three-tab shell; stop presenting CEFR heuristics as official grading; document current interaction behavior. |
| Docs/mural_reference_architecture.md | Treat as a reference rather than implemented contract. Reconcile tokens and BYOK claims with current code; remove stale duplication. |
| Docs/demo_video_script.md | Record the real current application, genuine audio and persisted evidence; omit static story, fabricated extraction and unsupported Serverless/telemetry claims. |
| Docs/devpost_submission.md | Submit through BuilderBase; correct repository to https://github.com/dj-DeepakJadhav/Talkloom; replace localhost with deployed URL. Remove 99.4% DSL adherence and <200ms claims unless measured evidence supports them. |
| Package READMEs and CLAUDE.md | Replace generic scaffolding and reconcile duplicate guidance. Keep nested AGENTS runtime restrictions; remove stale first-build reminder when updating application guidance. |

No evidence in this review establishes real Nebius Serverless jobs, NVIDIA
streaming ASR/TTS, Agent Reach/opencli integration, creator share links or a
generated/audio-synchronized story experience. Do not advertise them as delivered
without an implementation and reproducible verification.

## Work allocation and acceptance criteria

These are recommended implementation assignments, not work already completed.
The audit itself used three focused agents on the inherited model because each
needed cross-file reasoning. For implementation, use the lightest model that
passes the acceptance criteria; escalate on unresolved failures. This allocation
follows [official OpenAI model-selection guidance](https://developers.openai.com/api/docs/guides/model-selection)
and the models available in this session, rather than changing Talkloom's own AI
provider architecture.

| Workstream | Complexity | Model / effort | Acceptance gate |
|---|---|---|---|
| Identity, ownership, SSRF and evidence integrity | High | gpt-6-astra / high | Cross-user isolation, malicious URL rejection, forged evidence rejection and concurrent updates tested |
| Import-to-lesson UI, typed conversation and speech lifecycle | High | gpt-6.1-sol / high | One visible flow works with authentic content; unsupported/denied mic has recovery; history and progress survive refresh |
| Packaging, CI, provider config and deployment preparation | Medium/high | gpt-6.1-sol / high | Correct root CI runs, backend image builds, web release builds, production configuration and migration checks documented |
| Submission/README/status cleanup | Low/medium | gpt-6-luna / medium | Every delivery claim backed by a test/demo link; public URLs and reproduction steps correct |
| Final integrated demo and adversarial review | High | gpt-6-astra / high | Fresh-browser core flow plus one failure/retry succeeds without invented outputs |

Keep agents' edit ownership separate: security/model migrations in backend,
navigation/voice in frontend, CI/packaging in infrastructure, claims in docs.
Agree on protocol changes before concurrent edits; regenerate generated code
through Serverpod tooling rather than hand-editing it. Integrate and review each
workstream against the same flow.

## Proposed schedule through the deadline

- 5–6 October: freeze scope; fix identity/ownership, extraction truthfulness and
  navigation. Pick one supported import mode and one reliable provider.
- 7–9 October: finish source-specific activities, typed conversation, real speech
  or explicit text fallback, and correct persisted evidence. Add meaningful
  isolation, extraction failure, malformed DSL and end-to-end tests.
- 10–11 October: validate packaging/CI, configure deployment and run the complete
  public flow; test 3–5 target learners and collect concrete usefulness evidence.
- 12–13 October: fix demo failures, record the real demonstration, reconcile docs,
  verify public links and submit with buffer before the portal cutoff.
- 14 October: contingency only; confirm receipt rather than plan major work.

## Recommended winning demo

Choose one user: a German learner preparing for an everyday conversation from
their own document. Import real text, extract three to five relevant phrases,
complete one short source-specific activity, use those phrases in a contextual
conversation, then refresh to show saved evidence and the next practice target.

Make Serverpod's contribution visible: authenticated ownership, relational
sources/lessons/evidence, generated client, backend orchestration and persistent
learning history. A bounded background ingestion job with progress would help
reliability if needed, but unnecessary new infrastructure should not displace
finishing this flow. Defer extra social platforms, monetization, decorative
telemetry and story generation until the core acceptance gates pass.

The useful differentiator is learning from the user's own material and proving
what they can use afterward. Formal CEFR certification, pitch dynamics and
cognitive-load measurements need separate validated assessment methods; label
current heuristics as provisional practice feedback.

## Verification update — 6 October 2026

Follow-up checks were run against the current working tree after the audit above.
They verify a useful slice of the product, but do not resolve the P1 identity,
URL-fetch security, assessment-integrity, deployment, or native speech findings.

| Check | Result | Evidence and limit |
|---|---|---|
| Flutter `flutter analyze` | Pass | No issues found. |
| Flutter `flutter test` | Pass, 8 tests | Includes source-to-speaking navigation, small-phone layout, invalid-link validation, empty collection, and words/grammar from saved sources. The My German default filter was inverted and hid every item; fixed and covered by the collection flow test. |
| Flutter Web release build | Pass | `flutter build web --release` completed. This is compilation, not a fresh-user authenticated end-to-end run. |
| Android debug APK | Pass | `flutter build apk --debug` completed and produced `talkloom/talkloom_flutter/build/app/outputs/flutter-apk/app-debug.apk` in 219.3 seconds. This verifies compilation only, not installation or camera/microphone behavior on a device. |
| Server `dart analyze` | Pass with 21 info notices | Notices are `avoid_print` in AI service code; no analyzer errors or warnings. |
| Server `dart test` | Pass, 13 tests | Includes the greeting integration test using Serverpod's embedded test database, compiler completeness, provider fallback, and ingestion unit tests. Does not verify live paid-provider behavior or user isolation. |
| YouTube extraction | Pass in server `.venv` | Previously shared video `mNX1wpIQ4Uk` returned title, creator and transcript. System Python returned `transcript_dependency_missing`; runtime packaging must install/use `scripts/requirements.txt` consistently. |
| Local HTTP reachability | Pass, HTTP 200 | `localhost:8181/` and `localhost:8082/` responded. This checks availability only, not app behavior or endpoint correctness. |

Manual camera/microphone permissions, physical Android/iOS behavior, iOS build,
live AI provider calls, real import-to-persisted-lesson behavior, cross-user
isolation, hostile URL handling, and deployed production behavior remain
unverified. iOS compilation requires macOS/Xcode and was unavailable on the
Windows test host. The two file-picker call sites were migrated to the current
plugin API after analysis caught the incompatibility.

## Fix-loop verification — 6 October 2026

The findings above describe the 5 October baseline. The code-side fixes were
implemented and rechecked in the active ticket loop recorded in
[`fix_tickets_2026-10-06.md`](fix_tickets_2026-10-06.md). The root CI workflow is
now present, and the local checks below pass; this does not imply deployment or
device validation.

| Check | Result | Scope and remaining limit |
|---|---|---|
| Serverpod `dart test` | Pass, 31/31 | Includes ownership, auth, safe URL, lesson validation, archived URL cache reuse, provider mapping, conversation history and evidence integrity. Paid providers were not called. |
| Server `dart analyze` | Pass; two info notices | No warnings/errors; remaining notices are `avoid_print`. |
| Flutter `flutter analyze` / `flutter test` | Pass; 11 tests | Automated UI/content flow and no-fabricated-progress coverage; not a live signed-in browser test. |
| Flutter Web release / Android debug APK | Pass | Compilation only; Android permissions and all iOS/device speech behavior remain untested. |
| Docker image | Pass | Container includes its extractor dependency and required assets. The application server was not launched from the image. |
| GitHub Actions | Workflow added at repository root | Remote workflow execution and macOS/iOS job remain pending. |

Resolved code findings include authenticated per-user content access, source
ownership checks, SSRF protections and bounded fetches, explicit extraction
failures, strict lesson/evidence validation, correct provider routing, role-aware
conversation history, and removal of fabricated progress/audio controls. Speech
input now has a text path when unsupported, and template tutor replies identify
their degraded mode.

Two deliberate limitations remain: mastery is disabled until semantic answer
evaluation can verify correctness, and lesson provider/model/generation-status
provenance needs an explicit model and migration. Production deployment, target
database migration, hosted CI, live provider behavior, fresh-account end-to-end
flow, and Android/iOS permissions/audio remain release gates.

The existing shared URL reuse path is now covered through an archived original
source: another authenticated learner receives a fresh owner-scoped copy and
does not gain access to the original row. This cache currently derives from
source records and URL/language/level matching; a dedicated curated master
table, creator/provider metadata, and concurrent-import deduplication remain
future database design work.

The app's browser speech path is available only where the browser exposes speech
services. The Android/iOS TTS implementation is still a no-op stub; self-hosted
Qwen3-TTS and Agent Reach integration remain planned, not delivered.

## Runtime follow-up — 6 October 2026

The local development backend was repeatedly exiting because the installed
Serverpod 4.0.3 auth-core module introduced a deferred profile-image foreign
key, while Talkloom's latest checked-in migration still recorded the earlier
schema. Generated and applied
`talkloom/talkloom_server/migrations/20261006192906960-sync-auth-core-schema`;
it updates only that constraint and the Serverpod module migration versions.
After applying it, the backend remained running and HTTP checks returned 200 for
the API (8080), Insights (8081), Serverpod web server (8082), and Flutter web
preview (8181). Future Serverpod upgrades should include a generated, reviewed
migration before restarting the development app.
