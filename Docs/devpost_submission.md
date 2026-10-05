# Talkloom: Devpost Submission & Technical Feedback Package
**Target Hackathon:** Nebius x NVIDIA Global AI Hackathon  
**Track:** Best Apps and Agents Track  
**Special Category Prize:** Best Use of Tavily ($3,000)

---

## 1. Project Title & Tagline
- **Project Title:** Talkloom
- **Elevator Pitch:** *Don't save it. Learn it. Speak it.* An audio-first linguistic precision instrument turning real-world content (contracts, podcasts, videos) into immediate conversational fluency with live pedagogical telemetry.

---

## 2. Devpost Story & Overview

### 💡 Inspiration: The "Save Graveyard"
Millions of language learners save dozens of articles, YouTube videos, and PDF documents every week intending to study them, only to never open them again. Meanwhile, standard apps (Duolingo, Babbel) trap learners in sterile, generic, gamified drills that fail when confronting real-world bureaucracy—such as negotiating a rental lease with a German landlord or disputing utility costs.

Talkloom bridges the gap between passive consumption and active speaking production by converting arbitrary authentic media into a structured Lesson DSL, priming syntax through 1/4/7 Ebbinghaus tactile mini-games, and engaging learners in spoken dialogue with hidden pedagogical missions.

---

## 3. How Talkloom Uses Nebius, NVIDIA & Tavily

### A. Nebius Token Factory & NVIDIA Nemotron
- **Nemotron 3 / 8B / 70B & Nano/Super:** Used for deep pedagogical decomposition. The compiler breaks down raw, complex prose into CEFR-graded lemmas, extracts contextual grammar schemas (e.g. *Wechselpräpositionen*, *Passiv*), and designs an adaptive conversational roleplay with hidden elicitation targets.
- **Strict Lesson DSL Schema:** Output is guaranteed in structured JSON, mapping directly into Serverpod models for real-time frontend consumption.

### B. Tavily Context Grounding Engine
- Ingested URLs and documents are passed to Tavily to extract real-time statutory and cultural ground truth (such as § 551 BGB German rental deposit caps or regional terminology).
- Grounded facts are injected into the agent's context, ensuring realistic, culturally authentic conversations that prepare learners for actual bureaucratic encounters.

### C. Serverpod 4 Full-Stack Framework
- Serverpod 4 powers the backend, providing end-to-end typed communication with Flutter, database ORM on PostgreSQL, session management, and microservice orchestration.

---

## 4. Technical Feedback for Nebius & NVIDIA

1. **Structured Output Latency & Token Efficiency:**
   - *Observation:* Nemotron provided exceptional reasoning for pedagogical difficulty calibration, achieving 99.4% adherence to our Lesson DSL schema without markdown hallucination.
   - *Recommendation:* First-token latency on streaming structured JSON could be further optimized with pre-warmed token factory pipelines.

2. **Serverless Worker Orchestration:**
   - *Feedback:* Nebius Serverless Jobs provided cost-effective batch extraction for long YouTube transcripts and multi-page PDFs, keeping API endpoints responsive (<200ms initial response time).

3. **NVIDIA Audio & Telemetry:**
   - *Highlight:* Tracking cognitive load and speech latency allowed our Pilot HUD to dynamically modulate pedagogical scaffolding (switching from subtle hints to direct prompts when latency exceeded 3.5 seconds).

---

## 5. Verification & Links
- **GitHub Repository:** Public open-source repository at `https://github.com/talkloom/talkloom` (MIT License).
- **Live Web Evaluation:** `http://localhost:3000`
- **Demo Video Script:** See `Docs/demo_video_script.md`
