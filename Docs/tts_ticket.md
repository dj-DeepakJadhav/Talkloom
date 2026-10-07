# TTS-01 — Implement Qwen3-TTS speech output

Status: in progress. Owner: Codex. Complexity: high (GPU runtime, Serverpod,
cross-platform audio, failure handling).

Replace browser synthesis with self-hosted Qwen3-TTS for German learning.
Keep browser speech recognition independent. Do not silently fall back to OS or
browser voices. Optional accounts and private guest sessions remain supported.

Acceptance:
- [ ] Isolated local GPU runtime generates real German WAV audio.
- [ ] Serverpod authenticates speech requests and validates input limits.
- [ ] Model/voice/language/text cache avoids repeated inference.
- [ ] Concurrent identical requests generate audio once.
- [ ] Flutter plays returned audio on Web, Android and iOS using one service.
- [ ] Loading and synthesis/playback failures are visible.
- [ ] Browser speech synthesis is removed from the active playback path.
- [ ] Backend/cache regressions, Flutter analysis and Web build pass.
- [ ] A real German sample is generated and playable for review.

Reference: https://github.com/QwenLM/Qwen3-TTS (official Python inference API).
Native device playback requires a device test before claiming Android/iOS QA.
