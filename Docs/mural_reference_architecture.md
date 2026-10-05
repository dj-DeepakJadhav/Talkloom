# Talkloom & Mural Reference Architecture

This document formalizes the architectural reference, design patterns, and feature adaptations derived from [Chuloo/mural](https://github.com/Chuloo/mural) into the Talkloom language learning platform.

---

## 1. Vision & Core Philosophy

Talkloom is a spoken-first, multi-modal immersion language learning platform. Drawing inspiration from **Mural**'s minimal, intuitive aesthetic and client-empowered design, Talkloom marries:
1. **Talkloom's Visual Identity**: Dark obsidian canvas (`#0D0F12`), rich warm brass-gold accents (`#D4AF37`), frosted glass surfaces, and tactile typography.
2. **Mural's Minimal Glanceability**: Elimination of cognitive clutter, replacement of cumbersome scoreboards with intuitive visual progression, and frictionless multi-provider AI flexibility.

---

## 2. Multi-Provider BYOK (Bring Your Own Key) Architecture

Like Mural's localized key management (`apps/ios/App/LibraryViews.swift: SettingsView`), Talkloom provides full client-side provider selection and BYOK flexibility without locking users into any single cloud model.

### Supported AI Providers
- **Google Gemini**:
  - Compiler: `gemini-2.5-flash` for high-throughput pedagogical breakdown and JSON grammar extraction.
  - Conversational Agent: Sub-second conversational responses.
- **NVIDIA NIM**:
  - Compiler & Agent: Hosted open-weights models (`meta/llama-3.1-70b-instruct`) with high inference speed.
- **Groq LPU**:
  - Compiler & Agent: Ultra-low latency LPU execution (`llama-3.3-70b-versatile`) via OpenAI-compatible endpoints (`https://api.groq.com/openai/v1/chat/completions`).

### Storage & Persistence Flow
```
[ User in ApiKeysSheet ]
        │
        ▼
[ SharedPreferences (tl_active_provider, tl_key_<provider>) ]
        │
        ▼
[ ByokSettingsController (Riverpod) ]
        │
        ├── Client-side direct or custom header injection
        ▼
[ Serverpod DualAiCompilerService / DualPedagogicalAgentService ]
        │
        ▼
[ Realtime Stream / Lesson Synthesis ]
```

---

## 3. Mural-Inspired Feature Adaptations

### A. Spoken Recall Strength (3-Bar Gauge)
Instead of arbitrary numerical percentages or cluttered SRS interval counters, Talkloom adopts Mural's glanceable 3-bar gauge:
- **Level 1 (`1 · Fragile`)**: 1 warm brass-gold bar active. Newly acquired or missed vocabulary.
- **Level 2 (`2 · Growing`)**: 2 warm brass-gold bars active. Words successfully recognized in context.
- **Level 3 (`3 · Steady`)**: 3 warm brass-gold bars active. Fully retained phrases ready for unprompted conversation.

Implemented across:
- `LexiconVaultScreen`: Filterable vocabulary dictionary.
- `SanctuaryScreen`: Quick-review lesson vocabulary tab.

### B. Conversation Themes ("What's On Your Mind?")
Adopted from Mural's `Themes.swift` and `ThemesView`:
- **Categorized Starter Decks**: Everyday, Connection, Local Life, Interests, and Professional.
- **Dynamic Roleplay Configuration**: Tapping a theme (e.g., "A coffee?", "At the market", "Monday morning") immediately configures the conversational agent's persona (`role`), situational constraints (`situation`), and covert lexical goals (`hiddenTargets`).
- Accessible via the **Themes** button in the minimal top bar of `VoiceArenaScreen`.

### C. Fluid Bottom-Center Voice Control
- Replaced oversized interactive modals with a small, 44px pulsating Siri/Apple-inspired `FluidVoiceOrb` anchored at the bottom-center of `VoiceArenaScreen`.
- State transitions:
  - `idle`: Gentle amber pulse.
  - `listening`: Expanded aura reacting to microphone input.
  - `thinking`: Rotating dual-ring indicator while compiler/tutor infers.
  - `speaking`: Rhythmic audio-wave pulse during native TTS speech playback.

---

## 4. Repository Structure & Alignment

| Component | Mural Reference (`Chuloo/mural`) | Talkloom Implementation |
| :--- | :--- | :--- |
| **BYOK Settings** | `apps/ios/App/LibraryViews.swift: SettingsView` | `talkloom_flutter/lib/features/settings/api_keys_screen.dart` |
| **Themes Engine** | `apps/ios/Core/Themes.swift` | `talkloom_flutter/lib/features/arena/conversation_themes.dart` |
| **Recall Gauge** | `apps/ios/App/Design.swift: RecallBars` | `talkloom_flutter/lib/features/vault/lexicon_vault_screen.dart` |
| **Voice Interaction**| `apps/ios/App/ConversationCoordinator.swift` | `talkloom_flutter/lib/features/arena/voice_arena_screen.dart` |
| **Backend Providers**| Direct client endpoints | Serverpod `DualAiCompilerService` + `DualPedagogicalAgentService` |

---

## 5. References
- Reference Repository: [https://github.com/Chuloo/mural](https://github.com/Chuloo/mural)
- Talkloom Design Specification: `Docs/talkloom_design_specification.md`
