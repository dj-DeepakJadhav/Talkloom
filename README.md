# Talkloom: Learn Your Language From Anything. Then Speak About It.
> **Don't save it. Learn it. Speak it.**

**Target Hackathon:** Nebius x NVIDIA Global AI Hackathon  
**Track:** Best Apps & Agents Track  
**Special Prize Target:** Best Use of Tavily ($3,000)  
**Tech Stack:** Serverpod 4 (Dart backend & ORM), Flutter (Mobile & Web), Nebius Token Factory & Serverless Jobs, NVIDIA Nemotron, Tavily Context Grounding.

---

## 🚀 Architecture Overview

```
                      ┌────────────────────────────────────────┐
                      │        Talkloom Flutter Client         │
                      │  (Astryx Tokens + Lucide + Agent HUD)  │
                      └──────────────────┬─────────────────────┘
                                         │ WebSocket / HTTP
                                         ▼
                      ┌────────────────────────────────────────┐
                      │           Serverpod 4 Backend          │
                      │       PostgreSQL Relational ORM        │
                      └────┬───────────────┬────────────────┬──┘
                           │               │                │
                           ▼               ▼                ▼
     ┌────────────────────────┐  ┌──────────────────┐  ┌─────────────────┐
     │ Nebius Token Factory   │  │ Tavily Grounding │  │ Nebius          │
     │ (NVIDIA Nemotron LLM)  │  │ Search API       │  │ Serverless Jobs │
     │ • Pedagogical Compiler │  │ • Culture & Law  │  │ • Batch Parsing │
     │ • Adaptive Voice Agent │  │ • Local Context  │  │ • Transcription │
     └────────────────────────┘  └──────────────────┘  └─────────────────┘
```

---

## 🌟 Key Features Delivered

1. **Universal Ingestion & Content-to-Lesson Pipeline:**
   - Ingest YouTube video transcripts, rental contracts, PDFs, or pasted text.
   - Ground truth extraction powered by **Tavily Search API** (e.g. German rental laws like Section 551 BGB, Kaution deposit limits, and Nebenkosten indices).

2. **Pedagogical Lesson Compiler (Tri-Provider: Google Gemini, Nebius Token Factory & NVIDIA NIM):**
   - **Google Gemini** (`gemini-1.5-flash` / `gemini-2.5-flash`): Free tier via Google AI Studio (15 RPM / 1,500 daily requests) with structured JSON generation.
   - **NVIDIA NIM direct API** (`nvidia/nemotron-3.5-lightning-30b-a3b`): Free developer tier via [build.nvidia.com](https://build.nvidia.com) (1,000 free inference credits on sign-up) using `https://integrate.api.nvidia.com/v1`.
   - **Nebius Token Factory & NVIDIA Nemotron** (`nvidia/nemotron-3-8b-instruct`): Sovereign open-weights inference tailored for hackathon evaluation.
   - Configurable in `talkloom_server/config/passwords.yaml` (`aiProvider: 'gemini'`, `'nvidia'`, or `'nebius'`).
   - Compiles content into strict **Lesson DSL** JSON format with targeted objectives, vocabulary lemmas, grammar concepts, and speaking missions.

3. **Live Pedagogical Agent HUD (Judge Showcase):**
   - Real-time telemetry displaying the agent's hidden teaching mission, active teaching tactic, cognitive load / speech latency detection, and instant recognition of spontaneously produced language targets.

4. **Active Mastery Graph:**
   - Visualizes the learner's vocabulary state transitioning from *Recognized* to *Spontaneously Produced* (isolated per target language following the Mural architectural design).

5. **Sentence Builder Mini-Game:**
   - Verifies passive syntax recognition before learners transition into live conversation.

6. **Sustainable Unit Economics & Creator Smart Lesson Links:**
   - Built-in community sponsor card layout and one-click shareable deep links for creators.

---

## 🛠️ Setup & Running

### Serverpod Backend
```bash
cd talkloom_server
# Generate protocols and migrations
serverpod generate
serverpod create-migration
# Run server
dart bin/main.dart
```

### Running Unit & Pipeline Tests
```bash
cd talkloom_server
dart test test/unit/pipeline_test.dart
```

### Flutter Frontend
```bash
cd talkloom_flutter
flutter run
# Or Flutter Web
flutter run -d chrome
```

---

## 📜 License
MIT License. Open source for the Nebius x NVIDIA Hackathon 2026.
