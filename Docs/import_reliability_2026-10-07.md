# Import reliability investigation — 7 October 2026

Three independent defects were found in the live import flow:

- Successful preparation inserts a new source and refreshes the source collection.
  That refresh can dispose the incomplete source card before its awaited callback
  runs. The callback previously abandoned navigation, leaving the learner on the
  old source. It now captures the router before the await and opens the returned
  source if the learner is still on the original route. The returned lesson's
  provider is invalidated before refreshing the collection.
- Provider output can contain malformed vocabulary IDs. IDs are now normalized
  from language and lemma before schema validation, with conversation and choice
  targets remapped. Ambiguous duplicate references are rejected rather than
  guessed. Meanings, examples and source-evidence checks are unchanged.
- Serverpod Client's default `connectionTimeout` covers the entire HTTP response
  and defaults to 20 seconds. It wraps expiry in a network exception, bypassing
  the repository's timeout recovery. The application client now allows eight
  minutes, while repository operations retain their own shorter deadlines.
  URL import recovery polls for six additional minutes after its 90-second wait,
  covering the provider repair/failover times observed in the live logs.

Each provider generation attempt now has a 120-second deadline; a stalled
provider can fail over rather than hold the import indefinitely. Timeout failures
have the safe diagnostic code `provider_timeout`.
Repair requests now include the rejected JSON and its specific validation code,
so the model can correct the actual response rather than regenerate blindly.
The application shell also synchronizes tab state when a source-detail bottom
navigation action updates the route query.

Regression coverage: `source_preparation_handoff_test.dart` forces disposal during
completion; `ai_integrity_test.dart` checks local ID repair without another AI
request and rejection of ambiguous references. Provider completeness tests still
reject sparse lessons. Flutter analysis and release web build passed; server
analysis reported two existing logging-style informational findings.

Live browser verification confirmed that imports remain active past both the
20-second transport default and the 90-second repository wait, and a failed
compilation shows a terminal failure message with the saved-transcript status.
The supplied A1 video exposes only generated English captions, which corrupt
spoken German words. A subsequent prompt correction requires quoting the
original English teaching narration for evidence rather than back-translating
German source sentences. This retains the source-evidence validation.

Passing regressions does not establish complete extraction from video audio.
Mixed-language caption accuracy and an audio transcription fallback remain
separate reliability concerns; a saved transcript is not a completed lesson.

Final live check: the supplied A1 video compiled successfully in 131,171 ms and
the completion sheet displayed 15 words and 3 grammar patterns. Both tabs and
the saved source view showed the actual data. A repeat import completed in 72 ms
through cache reuse. These counts are verified, but exhaustive video coverage
has not been established. The proof image is
`assets/import-success-2026-10-07.jpg`.
