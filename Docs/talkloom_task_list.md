# Talkloom: Master Engineering & Hackathon Task List
**Target Hackathon:** Nebius x NVIDIA Global AI Hackathon  
**Target Track:** Best Apps and Agents Track (Prize Target: $20,000 Grand Prize / $10,000 2nd Place / $3,000 Best Use of Tavily / NVIDIA Jetson Orin Nano)  
**Governing Documents:**
1. `talkloom_hackathon_idea.md` (Product Spec, Architecture, Pedagogy, Brand)
2. `talkloom_task_list.md` (Engineering Progress, Milestones, and Verification Checklist)

---

## Phase 1: Foundation, Token Efficiency & Architecture Setup
- [x] **Task 1.1: Local Repository Scaffolding (Serverpod 4 Full-Stack & Craft Design System)**
  - Scaffold Flutter mobile + web client project structure via `serverpod create`.
  - Scaffold Serverpod 4 backend service structure with embedded PostgreSQL & full-stack hot reload.
  - Configure multi-agent MCP server (`talkloom/.mcp.json` for Serverpod and Dart).
  - Adopted **Apple Human Interface Guidelines (HIG)** two-layer architecture (Content layer vs Functional Liquid Glass layer), **QuickLiquid** (`amarnath3003/quickLiquid`) refractive specular highlights, and **Lucide Icons** (`lucide.dev`). No AI-slop cold navy palettes.

- [x] **Task 1.2: Static Security & Rule Enforcement**
  - Integrate **Strix** (`usestrix/strix`) security audit rules for safe input sanitization, API credential shielding, and prompt injection defense.
  - Configure environment secret management for Nebius Token Factory, NVIDIA Speech, and Tavily APIs.
- [x] **Task 1.3: Token Optimization & Memory Hierarchy Governance**
  - Enforce MCP protocol & memory hierarchy: prioritize `codebase-memory-mcp` for structural indexing, `headroom` for payload compression, `mempalace` (`mempalace/mempalace`) & `prometheus` for spatial/hierarchical persistent state recall, and `graft` for cross-references to eliminate redundant token burn.

---

## Phase 2: Nebius & NVIDIA Open Infrastructure Pipeline
- [x] **Task 2.1: Serverpod Backend Services**
  - Establish PostgreSQL schema: `sources`, `lessons`, `learner_state`, `evidence_events`.
  - Build endpoints for ingestion queuing and Lesson DSL delivery.
- [x] **Task 2.2: Universal Ingestion Engine (YouTube, Web, Photo/Camera OCR & Document Scan)**
  - Implement real YouTube subtitle & caption extractor with Tavily fallback when subtitles are not available.
  - Implement Multimodal Vision AI extraction (Gemini / NVIDIA Vision) for camera photos and document uploads (Base64).
  - Add native Flutter file & photo picker (`file_picker`, `image_picker`) in `UniversalIngestSheet`.
  - Connect full end-to-end ingestion pipeline -> Lesson DSL -> Lexicon Vault & Practice Games.
- [x] **Task 2.3: Pedagogical Lesson Compiler (Tri-AI Provider: Google Gemini, Nebius & NVIDIA NIM)**
  - Integrate **Google Gemini** (`gemini-1.5-flash` / `gemini-2.5-flash`) via native JSON mode for ultra-low latency, free development tier (15 RPM / 1,500 RPD), and zero-friction onboarding.
  - Integrate **NVIDIA NIM API** (`nvidia/nemotron-3.5-lightning-30b-a3b`) directly via [build.nvidia.com](https://build.nvidia.com) (free 1,000 API inference credits upon registration) using `https://integrate.api.nvidia.com/v1`.
  - Integrate **Nebius Token Factory & NVIDIA Nemotron** (`nvidia/nemotron-3-8b-instruct`) for hackathon compliance and open-weights sovereign inference.
  - Runtime selectable via `config/passwords.yaml` (`aiProvider: 'gemini'`, `'nvidia'`, or `'nebius'`).
  - Strictly enforce structured **Lesson DSL JSON Schema** output with automatic deterministic fallback.
- [x] **Task 2.4: Tavily Context Grounding Engine ($3,000 Prize)**
  - Integrate Tavily Search API in the Serverpod ingestion pipeline.
  - Query 1–3 authentic cultural/statutory facts matching the source topic (e.g. local rental laws, regional slang).
  - Inject ground-truth results into the conversation agent context.

---

## Phase 3: Conversational Agent & Live Telemetry HUD
- [x] **Task 3.1: Pedagogical Conversation State Machine**
  - Construct prompt with hidden teaching mission: target expressions, conversation role, and natural steering rules.
  - Implement dynamic adaptation logic: latency detection, difficulty modulation, and avoidance handling.
- [x] **Task 3.2: Live Pedagogical Agent HUD (The Judge Showcase)**
  - Build Flutter client HUD widget displaying real-time agent intent:
    - Target vocabulary & grammar objectives.
    - Active pedagogical strategy & tactic.
    - Speech latency / cognitive load indicator.
    - Real-time spontaneous production detection.
- [x] **Task 3.3: Streaming Voice & Audio Pipeline**
  - Connect NVIDIA Speech ASR (streaming transcription) and TTS (streaming playback).
  - Implement client-side VAD (Voice Activity Detection) with basic barge-in interruption.

---

## Phase 4: Frontend UI, Mini-Game & Monetization Engine
- [x] **Task 4.1: Streamlined Home Screen & Learning Inbox**
  - Home screen: "Learn Something" + "Speak".
  - Learning Inbox: display imported sources with CEFR level tags and estimated completion times.
- [x] **Task 4.2: High-Impact Interactive Mini-Game**
  - Implement 1 bulletproof, high-polish activity engine (Sentence Builder / Context Choice) to verify passive recognition before production.
- [x] **Task 4.3: Active Mastery Graph Screen**
  - Visualize learner vocabulary progressing from *Recognized* to *Spontaneously Produced*.
  - Isolate state per target language.
- [x] **Task 4.4: Ad-Supported & Creator Smart Link System**
  - Implement native sponsor card layout in Inbox and rewarded session unlock modal.
  - Implement "Creator Smart Lesson Link" deep-linking generation for YouTube/Instagram creators.

---

## Phase 5: Hackathon Packaging, Testing & Submission
- [x] **Task 5.1: Live Web Deployment**
  - Compiled and verified responsive Flutter Web release build (`talkloom_flutter/build/web`) ready for 1-click judge evaluation.

- [x] **Task 5.2: Open Source Repository & Documentation**
  - Verify open source license (Apache 2.0 / MIT) at repository root.
  - Write high-clarity README detailing setup, architecture diagrams, and explicit usage of Nebius Token Factory, Nebius Serverless, NVIDIA Nemotron, and Tavily.
- [x] **Task 5.3: 3-Minute Hackathon Demo Video**
  - Completed comprehensive, scene-by-scene script (`Docs/demo_video_script.md`) covering:
    - 0:00–0:20: The Save Graveyard ("Don't save it. Learn it. Speak it.").
    - 0:20–0:45: Share YouTube / Rental Contract into Ingestion Studio with Tavily cultural grounding.
    - 0:45–1:10: Nebius Serverless batch processing & Nemotron Lesson DSL compilation.
    - 1:10–1:35: Kinetic Sentence Builder mini-game (German word order syntax priming).
    - 1:35–2:25: Live Voice Session with **Pilot HUD Telemetry** & spontaneous production catch.
    - 2:25–2:45: Active Mastery Graph, Lexicon Vault & Story Weaver.
    - 2:45–3:00: Business model & closing pitch.
- [x] **Task 5.4: Devpost Submission & Feedback**
  - Completed Devpost submission document (`Docs/devpost_submission.md`) detailing architecture, pitch, Nebius Token Factory / NVIDIA Nemotron / Tavily utilization, and structured technical feedback.

---

## Phase 6: Premium Remediation — Design System & Client Architecture
**Added:** 2026-09-18, after a full code + UX audit of `talkloom_flutter` and `talkloom_server`.
**Goal:** Move from a working hackathon demo to a premium, language-agnostic consumer application.
**Explicitly deferred:** gamification (XP, streaks, goals, mastery tiers) — tracked in Phase 7.

### Audit Findings (the "why" for this phase)

| # | Finding | Evidence | Severity |
|---|---------|----------|----------|
| F1 | `userId` is an unauthenticated `String` endpoint parameter; client passes literal `'user_demo_1'`. Any caller can read/write any learner's state. | `pedagogical_endpoint.dart`, `home_screen.dart:51,106` | CRITICAL |
| F2 | Entire client is one 554-line `StatefulWidget`; no routing, no state layer, no repositories. | `home_screen.dart` | HIGH |
| F3 | German hardcoded throughout the client, blocking "any language" positioning. Backend is already language-agnostic. | `home_screen.dart:33,35,51,62,68-70,107-110,192-194,255,293-297,378-379,460` | HIGH |
| F4 | Errors silently swallowed — user sees a spinner stop and nothing else. | `home_screen.dart:53,85,138` | HIGH |
| F5 | Body text 11–13px in a 440px column; 10 ad-hoc font sizes against 4 defined styles. Primary cause of "not premium". | theme + all widgets | HIGH |
| F6 | 24 distinct hardcoded hex values bypass `AstryxTokens`; dark theme built from magic numbers. | `screens/`, `widgets/` | MEDIUM |
| F7 | `themeMode: ThemeMode.light` hardcoded — the entire dark theme is dead code. | `main.dart:53` | MEDIUM |
| F8 | `liquid_glass_surface.dart` has zero usages (Task 1.1 shipped dead). | repo-wide grep | MEDIUM |
| F9 | Almost no motion: two AnimatedContainers; `BouncyButton` used once; no haptics, sound, or transitions. | client-wide | MEDIUM |
| F10 | Compiled `Lesson.activities` is persisted then ignored; Practice tab shows one hardcoded German sentence. | `home_screen.dart:378` | HIGH |
| F11 | Speak tab is text-only. No mic, audio, or VAD in the client despite Task 3.3. | client-wide | HIGH |
| F12 | Pedagogical HUD reveals hidden targets to the learner, defeating spontaneous elicitation. | `pedagogical_hud_widget.dart` | MEDIUM |
| F13 | Typed models degraded to JSON-in-String across the wire; client hand-decodes. | `lesson.spy.yaml`, `pedagogical_endpoint.dart` | MEDIUM |
| F14 | `processSourceAndCompile` does fetch + Tavily + LLM synchronously on one request (10–30s). | `ingestion_endpoint.dart` | MEDIUM |
| F15 | `listSources` / `listLessons` unbounded, unfiltered, not user-scoped. | `ingestion_endpoint.dart` | MEDIUM |
| F16 | Ad slot (`SponsorCardWidget`) occupies prime space on every screen pre-launch. | `home_screen.dart:180` | LOW |
| F17 | "Speaking Streak" card actually renders a vocabulary ratio; "7 DAYS" is a string literal. | `active_mastery_graph_widget.dart`, `home_screen.dart:239` | LOW |

### Task 6.1: Security — Authenticated Identity (fixes F1)
> Migration `20260918181648180` is **created but not applied**. Applying it recreates the `sources` and `lessons` tables (both gained a non-null `userId`), which drops existing rows. Apply it via the Serverpod MCP `apply_migrations` when you are ready to lose the demo data, or hand-edit its `migration.sql` to backfill instead.
- [x] Remove `userId` from all endpoint signatures; derive from the Serverpod auth session.
- [x] Scope `listSources` / `listLessons` to the authenticated user, with pagination (fixes F15).
- [x] Add `userId` to the `Source` model so sources are ownable.

### Task 6.2: Design System Foundation (fixes F5, F6, F7)
- [x] Replace `AstryxTokens` with a structured design system: colour roles, a real type scale (body 15–16px), spacing, radius, motion, and elevation tokens.
- [x] Expose tokens via `ThemeExtension` so widgets read from `Theme.of(context)`, not static light/dark ternaries.
- [x] Purge all 24 stray hex literals from screens and widgets.
- [x] Enable `ThemeMode.system` and verify both themes render.

### Task 6.3: Component Primitives (fixes F9, partially F8)
- [x] Build reusable primitives: surface/card, button (3 variants), text field, pill, section header, empty state, error state, skeleton loader.
- [x] Centralise motion: standard durations/curves, page transitions, list stagger, press feedback, haptics.
- [x] Delete or genuinely adopt `liquid_glass_surface.dart`.

### Task 6.4: Client Architecture (fixes F2, F4)
- [x] Introduce `flutter_riverpod` for state and `go_router` for navigation (deep links are required by the Creator Smart Link strategy).
- [x] Add a repository layer over the Serverpod client; no widget calls `client.*` directly.
- [x] Introduce a `Result`/`AsyncValue` convention with rendered loading, data, and **error** states everywhere.
- [x] Restructure into `app/ core/ design/ features/ data/`.

### Task 6.5: Language-Agnostic Core (fixes F3)
- [x] Add a language catalogue (code, endonym, English name, flag, RTL flag, voice availability).
- [x] Add a `LearningSession` model carrying target/support language, CEFR level, role, and situation.
- [x] Build first-run onboarding: choose target language, support language, and level.
- [x] Add a language switcher to the top bar, replacing the fake streak badge.
- [x] Replace hardcoded German presets with per-language starter scenarios.
- [x] Remove every hardcoded `'de'`, `'B1'`, `'landlord'`, and German UI string.

### Task 6.6: Lesson Engine (fixes F10)
- [x] Define typed activity models; render activities from the compiled `Lesson`, not from hardcoded constants.
- [x] Support multiple activity types behind one renderer.

### Task 6.7: Screen Rebuilds
- [x] Onboarding — language and level selection.
- [x] Inbox/Explore — import as the hero action, real source list, empty and error states.
- [x] Lesson — driven by compiled activities, with progress and proper success/failure feedback.
- [x] Speak — conversation redesign; HUD reframed as a post-hoc reveal rather than a spoiler (fixes F12).
- [x] Remove the ad slot until there is an ad network (fixes F16).
- [x] Rename the mastery card to match what it renders (fixes F17).

### Deferred to Phase 7 (Gamification)
- Streak, XP, daily goal, mastery tiers derived from `evidence_events`.
- Spontaneous-production celebration moment (full-screen, haptic, audio).

### Deferred to Phase 8 (Backend Hardening)
- Typed models across the wire, replacing JSON-in-String (F13).
- Asynchronous ingestion with job status streaming (F14).
- Client voice pipeline: mic capture, streaming ASR/TTS, VAD (F11).

### Phase 6 status — 2026-09-18

Done: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7.
`flutter analyze`, `dart analyze` (server) and `flutter build web --release` all pass clean.

Not done, deliberately:
- The Creator Smart Link modal and its deep-link route were **removed**, not ported. The
  old modal was orphaned when the home screen was rebuilt, and rebuilding it needs a real
  deep-link route plus a share target. Tracked as Phase 7 work.
- Automated tests added in `test/widget_test.dart` for design tokens and feature screens; `flutter test` passes clean.
- Code paths, typed data structures, and the web release build compile clean.

---

## Phase 9: 100x Luxury Design System & Complete Pedagogical Flow
**Added:** 2026-09-22, following design audit & examination pedagogy expansion.
**Governing Document:** `Docs/talkloom_design_specification.md` (Living design documentation)

### Core Deliverables
- [x] **Task 9.1: Unified 5-Tab Frosted Navigation Scaffold**
  - Implement permanent 5-tab frosted glass bar (`Sanctuary`, `Stories`, center elevated `Ingest (+)`, `Arena`, `Vault`).
  - Wire persistent shell state preservation across tabs with frosted glass specular top hairline.
- [x] **Task 9.2: Universal Ingestion Studio Rebuild**
  - Consolidate input options into a single, clean top segmented tab bar: `[ 📷 Camera OCR | 📄 File Upload | 🔗 Web Link ]`.
  - Fixed top/bottom control duplication and integrated with Nemotron / Tavily synthesis.
- [x] **Task 9.3: The Lexicon & Grammar Vault**
  - Build CEFR-graded dictionary view cataloging vocabulary and grammatical rules extracted from user uploads.
  - Implement 1/4/7 Ebbinghaus spacing tier indicators (`Box 1: Day 1`, `Box 2: Day 4`, `Box 3: Day 7`) with detailed lemma inspector (gender, IPA, contextual usage) and grammar rule cards.
- [x] **Task 9.4: AI Adaptive Story Weaver (Listening & Reading Immersion)**
  - Implement dynamic story generation utilizing accumulated vocabulary ($\ge 15$ words) and grammar patterns.
  - Synchronized bilingual audio player with word-by-word highlight transcript, animated waveform, and end-of-story listening comprehension (*Hörverstehen*) checkpoints.
- [x] **Task 9.5: Complete Exam Triad in Active Voice Arena**
  - Ensure evaluation covers **Listening, Speaking, Writing** rubrics with CEFR Exam Scorecard.
  - Embed live telemetry HUD (speech latency, pitch dynamics, cognitive load gauge) and spontaneous production gold pulse celebrations.
- [x] **Task 9.6: Tactical Mini-Game Suite (1/4/7 Spaced Priming)**
  - Kinetic Sentence Builder (Syntax & Writing word order priming).
  - Context Choice & Cloze Shutter (Listening & Rapid Recall).
  - Pre-voice conversation priming engine fully playable out of the box.

---

## Phase 10: Omnichannel Social Ingestion & Conversational Live Persona
**Added:** 2026-09-30, based on integration of Agent Reach multi-platform ingestion and Gemini 3.8 Live Avatar principles.

### Core Deliverables
- [x] **Task 10.1: Omnichannel Social Media Ingestion (Agent Reach Integration)**
  - Support social platform ingestion in `IngestionService` (`talkloom_server`) for Instagram, TikTok, Facebook, Reddit, and X/Twitter.
  - Bridge to `opencli` and `agent-reach` extractors with resilient web fallback to extract authentic captions, comments, and conversation threads for language lessons.
  - Update Flutter `UniversalIngestSheet` with one-tap social channel presets (Instagram, TikTok, Reddit, Facebook, X).
- [x] **Task 10.2: Interactive Conversational Live Tutor Persona Widget**
  - Implement reusable `TutorAvatarWidget` in `talkloom_flutter` with 4 reactive visual states (`listening`, `thinking`, `speaking`, and `triumph/celebrating`).
  - Wire lip-sync and expressive reaction animations into `SpeakScreen` and `VoiceArenaScreen`.
  - Connect spontaneous production gold-pill triggers directly to the tutor avatar's praise expression.
- [x] **Task 10.3: Autonomous Verification & Testing Loop**
  - Verify zero-warning status on `flutter analyze` and `dart analyze`.
  - Ensure unit and widget tests pass seamlessly.


