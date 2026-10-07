# Talkloom design specification

Updated 5 October 2026. This is the current design contract, superseding the
previous five-tab luxury/HUD specification and the Mural visual reference.

## Product

German first. Users provide the material. Talkloom turns their imported content
into conversation and optional vocabulary/grammar practice. Speaking is the
primary learning action; the collection is built from their imports, not from a
preloaded curriculum. Additional languages remain future work.

## Identity

Warm editorial paper and ink with coral speaking actions. The source, rather than
an animated orb, is the defining visual object. Cream light mode is the default;
dark mode is available through the appearance button. Heading typography is
editorial serif, with clear sans-serif body copy. Solid cards, restrained borders,
generous spacing, and accessible Material controls replace floating glass tabs.

Semantic tokens live in `lib/design/colors.dart` and `tokens.dart`; type styles
live in `typography.dart`. Coral action color: #B94732; paper canvas: #FAF6EF.
Dark mode uses a readable lighter coral accent. Do not encode success through
color alone or invent mastery bars.

## Navigation and hierarchy

- **Today:** latest imported source with a prominent Speak about this action;
  earlier sources let the user pick up another conversation. No fake due dates,
  streaks, or starter lessons.
- **My content:** recent imports, source artwork where obtainable, platform,
  German, source difficulty estimate, title, and a speaking entry point.
  Source options let a learner remove an item from their feed; this archives
  their personal entry and preserves successful URL analysis for reuse.
- **My German:** every word/phrase and grammar pattern extracted from saved
  lessons, grouped in count-bearing Words and Grammar tabs. Search, source
  context, and a link back to each originating source. Repeated terms remain
  visible when they come from separate sources; no sample vocabulary fallback.
- **Add content:** link or pasted German text, optional title, validation,
  preparation state and errors. It routes to the imported source detail.

## Source detail

After import, open the source detail directly to a complete, count-bearing
Words/Grammar tab view. Show every extracted item with a plain explanation and
its source sentence/context; do not truncate the lesson to a preview count.
Synthesis must request full source coverage with no fixed vocabulary cap and
validate unique, source-supported words and grammar before saving. A short or
unsupported result is an import failure, not a finished lesson.
Speaking is the primary action beneath the takeaways; generated mini-games stay
optional. The original source text remains available on demand. Missing lessons
show an honest not-ready state rather than fabricated content. Source ID routes
can reopen content from the current backend collection.

## Speaking

Carry source title and text into the conversation screen. Show the goal and
conversation partner; keep learner/tutor turns readable. Use an accessible mic,
editable typed response, explicit send and available playback. Speech errors
stop the listening state and offer typing. Observations say Expression detected,
not mastered or independent use, because the backend does not yet establish that.
No decorative orb, exam scorecard, or cognitive-load telemetry in this flow.

## Practice

Existing source-specific activities remain available as optional preparation.
Deep-linking without a selected lesson shows an empty state, never a sample
German tenancy lesson. Source identity remains visible above the activity.

## Truthfulness and scope

- Link and pasted text are visible inputs alongside image, document, and camera
  capture. Image/document bytes are sent through the existing media compilation
  path; camera capture uses the same image path. Native OS share targets and
  reliable Instagram retrieval remain future work.
- Creator metadata and transcript timestamps are not in the current protocol;
  do not fabricate them. YouTube thumbnails are derived only from a valid ID and
  have an accessible neutral fallback.
- Collection reads currently show up to 100 recent sources/lessons. Full paging,
  review scheduling, and verified speaking evidence remain separate backend
  work. URL lesson reuse matches normalized URL, target/support language, and
  CEFR level against retained source/lesson rows and copies complete results
  without re-running extraction or lesson compilation. Incomplete legacy lessons
  are skipped; a weak current entry is archived only after a complete replacement
  is saved. This is a pragmatic shared cache over existing tables, not yet a
  dedicated canonical-source table.
- Existing backend shared-guest identity and invented extraction fallbacks are
  unresolved audit findings; this UI redesign does not claim to fix them.
- The current Web build uses the browser's installed `de-DE` speech voice;
  Android/iOS currently have a no-op TTS stub. This is not a selected speech
  model and voice quality varies by device.
- TTS decision (2026-10-06): use open-weight Qwen3-TTS, self-hosted behind a
  private inference worker called by Serverpod. Start with the 0.6B
  CustomVoice model for German; evaluate 1.7B VoiceDesign if the smaller model
  does not meet naturalness targets. The [official Qwen3-TTS project](https://github.com/QwenLM/Qwen3-TTS)
  lists German and streaming support.
  Do not bundle model weights in Flutter or call a paid speech API from the
  client.
- Self-hosting removes per-request vendor TTS charges, but still requires
  inference compute and operations. Reuse cached audio for repeated vocabulary
  and phrases. Serverpod remains the authenticated app boundary; keep the
  worker internal and return playable audio to Android, iOS, and Web clients.
- Treat streaming synthesis, native playback, retries, cache behavior, and
  browser/device fallback as unimplemented until verified end to end.

## Acceptance checks

1. Today -> source -> speaking preserves the user's imported context.
2. Empty collections invite the first import and contain no fake examples.
3. Source detail shows all saved vocabulary and grammar with accurate counts,
   simple explanations, and context. My German includes source-specific repeats
   and links every item back to its source.
4. Failure states offer retry and do not pretend the collection is empty.
5. Mobile layouts keep primary actions usable with scrolling and a keyboard.
6. Without the logo, source context and editorial hierarchy still communicate
   Talkloom's content-to-speaking product.
7. Android, iOS, and Web preserve the same source-to-speaking flow; platform
   controls adapt to native permissions and safe areas.

Implementation: `features/content`, `features/shell`, `features/speak`, and
`features/ingest`. Widget tests in `test/content_flow_test.dart` cover navigation,
empty state, and source-linked collection. Screenshot capture uses fixture data
in tests only; it is never supplied to the application as starter content.

## Source takeaways — 2026-10-06

- The import success route goes to source detail, where Words and Grammar tabs
  show the full lesson output and exact item counts. Items retain their meaning,
  explanation, and source sentence/context when available.
- My German uses the same two-category model across saved lessons. It keeps
  occurrences from different sources, so each entry can return to its origin.
- “Speak about it” remains the prominent next action. A source-specific quick
  practice is available as a secondary action when the lesson includes activities.
- This is an overview, not a generated-content guarantee: empty categories state
  that nothing was extracted, and current backend extraction integrity limits
  remain as documented in the application audit.
- Removing a feed item archives only that learner's source entry; its analysis
  remains available for a later matching URL import. The learner can undo from
  the confirmation snackbar. URL extraction failures now return a retry/paste
  message instead of fabricated source text that could poison future reuse.


## Verification — 2026-10-06

- Flutter static analysis: no issues.
- Eight tests pass, including content → detail → speaking, source-linked
  vocabulary/grammar, truthful empty states, invalid-link validation, and
  a 360 × 640 phone viewport.
- Release web build passes. Fonts are bundled with their OFL licenses.
- Android and iOS remain the primary release targets; Web is the judge/demo
  companion build.
- Widget screenshots use test fixtures, not live backend data.
- Live source extraction, AI conversation, microphone permissions, and native
  voice capture were not verified in this pass. The server was not started.

## Action-first visual direction — 2026-10-06

The shell should feel like a tool the learner can use immediately, not an AI
landing page. Primary surfaces lead with one action, one source, and one clear
next step. Explanatory copy is secondary and should normally fit on one line.

- Use Lucide's consistent outline icons for navigation, source type, speaking,
  add, theme, and feedback controls. Keep icon size and stroke weight stable;
  do not mix decorative emoji or unrelated Material glyphs into the primary
  flow. Reference: https://lucide.dev/
- Use Astryx as a component-system reference: composable primitives, explicit
  states, accessible controls, and tokens that can be themed without changing
  product meaning. Reference: https://github.com/facebook/astryx
- Prefer motion that explains state: cards fade and lift into a collection,
  tab content cross-fades, and a press changes the control before navigation.
  Avoid ambient loops, ornamental particles, and motion that delays speaking.
- The home screen hierarchy is `Today` / `My content`, a short prompt, the
  latest source, and a `Speak` action. Empty states show one sentence and one
  `Add something` action.
- Keep the warm paper, ink, and coral palette. The reference image's large
  color fields are useful as a restraint: broad surfaces establish mood while
  the coral accent marks the next action.
- The supplied reference swatches are named in the token layer: Deep Walnut
  (`#46351D`), Dusty Olive (`#646F4B`), Cool Steel (`#839D9A`), Sky Reflection
  (`#7BB2D9`), and Ash Grey (`#BFD2BF`). They support text, state, information,
  and borders without turning the product into a multicolor dashboard.

## Source intake

The Add action exposes five modes: Link, Text, Image, File, and Camera. A file
or camera selection must show its name or capture state before the learner sends
it for analysis. The learner can optionally name it. Empty selections are
validated locally and never trigger a backend request. The backend remains the
source of truth for OCR, transcription, and lesson generation; the client does
not invent extracted content.
## Link resolution reference

Talkloom should use [Agent Reach](https://github.com/Panniantong/agent-reach) as
the first link-resolution capability in the ingestion worker. Agent Reach is a
capability and routing layer that health-checks upstreams for YouTube,
Instagram, web pages, GitHub, RSS, and other platforms. It is not a Dart
package and must not be presented as a direct Serverpod endpoint.

The intended order is: normalize and validate the URL; ask an Agent Reach worker
adapter to resolve it using its healthy channel (`agent-reach doctor --json` is
the health signal); fall back to Talkloom's normal resolver and AI transcription
path; then cache the normalized URL and source text before compiling German.

For the current Flutter/Serverpod slice this is a documented boundary. The
checked-in Dart service still uses its existing resolver; a deployable Agent
Reach worker adapter is the next backend task.
## Platform contract — 2026-10-06

Talkloom is mobile-first. Android and iOS are the primary product surfaces;
Flutter Web is a supported companion build for demos, review, and desktop use.
Every core flow must work at a 360 px-wide phone viewport before it is tuned for
wide screens.

- Primary navigation stays reachable with one thumb and uses a bottom bar on
  phones. Wide layouts may center the same content column but keep the same
  information architecture.
- Add, camera, image, document, link, text, and speaking actions remain
  reachable without hover. Keyboard-safe scrolling is required on phones.
- Android and iOS use native picker/camera permissions and native fallbacks
  where browser APIs do not exist. Web uses browser permissions and speech where
  supported.
- Web release builds help judges evaluate the product but do not replace
  Android/iOS device checks for camera, microphone, file selection, and safe
  areas.
# Guest-first access

Registration is optional. Open the app with a private persisted guest session;
allow imports, vocabulary, grammar, speaking and practice without a sign-up gate.
Keep the account/sign-in entry available for converting guest learning into a
registered account, preserving saved content and progress. See `guest_access.md`.
