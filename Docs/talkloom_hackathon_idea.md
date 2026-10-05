# Talkloom

## Learn Your Language From Anything

> **Learn your language from anything. Then speak about it.**

> **Don't save it. Learn it. Speak it.**

**Product:** Talkloom  
**Hackathon:** Nebius Global AI Hackathon  
**Primary Track:** Best Apps & Agents  
**Product Form:** Mobile-first language learning app  
**Recommended Stack:** Flutter + Serverpod + Nebius + NVIDIA open models  
**Document status:** Revised after competitive analysis of Lanma and Mural  
**Competitive review date:** September 16, 2026

---

# Brand

## Name

**Talkloom**

The name reflects the product idea: weaving the content already present in a learner's life into language they can actively use.

## Primary Line

> **Learn your language from anything. Then speak about it.**

## Behavioral Tagline

> **Don't save it. Learn it. Speak it.**

The UI should stay natural rather than overusing invented terminology. The product should feel like a consumer learning brand first, not an AI utility.

---

# 1. Executive Summary

People already encounter more language-learning material every day than any textbook could provide:

- YouTube videos
- Instagram Reels
- TikTok videos
- articles
- websites
- screenshots
- PDFs
- rental contracts
- government letters
- menus
- workplace documents
- photos
- podcasts
- uploaded audio and video

The problem is not access to content.

The problem is converting that content into **actual language ability**.

Most content gets:

**watched → saved → forgotten**

Our product changes that loop to:

**share → understand → learn → practice → speak → remember**

The user shares something they genuinely care about or genuinely need to understand. The app analyzes both the source and the learner, selects the few language elements that matter most, generates a short interactive lesson, and ends with a real-time conversation designed to make the learner actively use what they just learned.

The core product promise is:

> **Anything can become your next language lesson.**

The signature behavior is:

> **Every lesson should move toward speaking.**

The deeper technical thesis is:

> **AI should not merely extract words. It should continuously find the boundary between what a learner can understand and what they can actually produce, then generate the next activity that moves that boundary forward.**

---

# 2. What We Learned From Competitors

Two products are particularly important to understand because they validate major pieces of this concept.

## 2.1 Lanma

Lanma currently offers a surprisingly similar content-to-language workflow.

Its public product describes a four-stage loop:

1. **Capture** — share a YouTube video, article, song, or other source
2. **Keep** — identify words the learner does not already know
3. **Remember** — review them through spaced repetition
4. **Speak** — use saved words in a live AI voice conversation

Lanma also:

- supports 20 study languages
- remembers known vocabulary
- hides already-known words in later imports
- preserves source context
- uses spaced repetition
- offers flashcards, multiple-choice and typing quizzes
- creates AI review drills
- provides pronunciation audio
- supports live voice conversations
- shows a real-time transcript
- steers conversation toward saved words
- gives grammar corrections
- produces a session report
- feeds mistakes back into future review

This is important because it means we **cannot claim** the following as novel:

- "learn from YouTube"
- "share a video into a language app"
- "extract unknown vocabulary"
- "remember known words"
- "spaced repetition from imported content"
- "practice saved vocabulary with an AI voice tutor"
- "support many languages"

Lanma proves these are now baseline category features.

### What Lanma is fundamentally optimized around

Lanma's center of gravity is still the **word set**.

The source becomes vocabulary, and vocabulary becomes the persistent learning object.

That is a strong product, but it gives us an important strategic direction:

> **Talkloom's primary object should be the lesson and the learner's ability, not the vocabulary list.**

We should go beyond:

**source → word set → review → speak**

toward:

**source + learner state → personalized learning objective → multimodal lesson → speaking mission → evidence → updated learner state**

That is a deeper loop.

---

## 2.2 Mural

Mural approaches the problem from the opposite direction.

It is a conversation-first language learning app.

Its current open-source implementation includes:

- live voice conversation
- gentle corrections
- optional meaning subtitles
- word lookup
- typed replies
- 24 conversation settings
- current-topic conversation with web search
- adaptive vocabulary observations
- provisional ability observations
- evidence-based recall indicators
- separate learner progress for each target language
- local storage of conversations, vocabulary, and preferences
- JSON learning backup/import
- eight language modules
- per-language pronunciation, grammar, and teaching guidance

Mural is particularly valuable because of **how it models learning**.

Its language architecture isolates progress by target language. A user's German evidence does not leak into Spanish. Identical surface words can have different language-specific identities. The app also avoids treating one exposure as mastery: recall is based on repeated evidence across time and contexts.

That gives us several architectural lessons worth adopting.

### Lesson 1 — Progress must be isolated by language

A learner can be:

- B2 German
- A1 Spanish
- complete beginner in Japanese

These should be separate learning worlds.

### Lesson 2 — Learning claims should be evidence-based

Do not say:

> "You know this word"

because the user saw it once.

Instead collect evidence:

- recognized correctly
- recalled without help
- used in typing
- used in speech
- used spontaneously
- reused in a later context
- retrieved after time has passed

### Lesson 3 — Speaking quality itself is not differentiation

Mural makes high-quality AI conversation a category baseline.

Talkloom's novelty cannot be:

> "You can talk to AI in German."

Speaking remains essential, but it must be connected to something deeper:

> **the AI knows exactly what the learner encountered, what they understood, what they still cannot produce, and what this conversation should make them practice next.**

### Lesson 4 — Privacy and local learner state can be a product feature

Mural keeps learner records locally on the device.

We do not have to copy that architecture completely, because our product needs cloud processing, but we should preserve the principle:

> **A learner's long-term language model is sensitive personal data and should be understandable, exportable, and under user control.**

---

# 3. Competitive Conclusion

Lanma and Mural do **not** invalidate this project.

They clarify the bar.

## Lanma proves

> People want to learn from content they already consume.

## Mural proves

> People want low-friction, adaptive AI conversation with persistent learner memory.

## Talkloom must combine and extend those ideas

Talkloom's strongest version is:

> **Bring in anything from your real life. AI decides what is worth learning for you, turns it into a compact interactive lesson, and then creates a speaking situation that makes you actively use it.**

The core differentiation is therefore **not one individual feature**.

It is the intelligence of the entire loop:

```text
REAL-WORLD SOURCE
      +
LEARNER MODEL
      ↓
WHAT IS WORTH LEARNING NOW?
      ↓
PERSONALIZED LESSON
      ↓
GENERATED MINI-GAMES
      ↓
SPEAKING MISSION
      ↓
LEARNING EVIDENCE
      ↓
UPDATED LEARNER MODEL
```

---

# 4. Product Positioning

The product should not be positioned as:

> an AI flashcard app

or:

> a YouTube vocabulary extractor

or:

> another AI speaking tutor

or:

> a generic AI study app

The positioning should be:

# **Learn your language from anything. Then speak about it.**

Supporting behavioral tagline:

# **Don't save it. Learn it. Speak it.**

The first line describes the product.

The second describes the behavior change.

---

# 5. The Real User Problem

Language learners already have abundant input.

They watch:

- videos
- shows
- news
- tutorials
- interviews
- social media
- lectures

They also encounter real-world content:

- contracts
- notices
- menus
- emails
- letters
- work documents
- signs
- forms

But there is a gap between:

> "I encountered this"

and:

> "I can now use the language from this."

There is also a deeper gap between:

> **recognition**

and:

> **production**

A learner may understand `Kündigungsfrist` immediately when reading it, yet fail to spontaneously ask:

> *Wie lang ist die Kündigungsfrist?*

during a conversation.

That gap is where the product should focus.

---

# 6. Core Learning Model: Passive → Active

Instead of a binary known/unknown state, every language item should move through an evidence-based progression.

For vocabulary:

```text
UNSEEN
  ↓
SEEN
  ↓
RECOGNIZED
  ↓
UNDERSTOOD IN CONTEXT
  ↓
RECALLED WITH SUPPORT
  ↓
RECALLED WITHOUT SUPPORT
  ↓
USED IN WRITING
  ↓
USED WITH HELP IN SPEECH
  ↓
USED SPONTANEOUSLY IN SPEECH
  ↓
RETRIEVED AGAIN LATER
  ↓
STABLE / MASTERED
```

The same idea can apply to:

- grammatical structures
- sentence patterns
- pronunciation targets
- conversational functions
- listening comprehension
- topic vocabulary

Important:

These are **product heuristics**, not official language-certification claims.

We should avoid pretending that an internal score equals a CEFR certificate.

---

# 7. The Product's Most Important Intelligence

The app should not ask:

> "What vocabulary exists in this video?"

It should ask:

> **"What should this particular learner learn from this particular source right now?"**

Example:

A 12-minute German video contains:

- 1,700 total spoken words
- 1,530 already familiar to the learner
- 70 domain-specific terms that are not useful now
- 60 unknown but low-value words
- 25 useful expressions
- 8 that are exactly appropriate for the learner's current level
- 3 that connect directly to current speaking weaknesses

The best lesson may contain only:

- 5 vocabulary items
- 1 sentence pattern
- 1 grammar target
- 1 pronunciation target
- 3 short games
- 1 speaking mission

This restraint should feel intelligent.

The product's job is not extraction.

It is **selection**.

---

# 8. Core User Behavior: Share Instead of Save

The strongest entry point is outside the app.

The user sees something interesting.

Instead of:

**Share → Save to Notes**

they choose:

**Share → Our App**

The source immediately enters their Learning Inbox.

Example notification:

> **Your German lesson is ready**  
> 5 useful expressions · 1 grammar pattern · 3 mini-games · 4-minute speaking session

The habit we want to create:

> **I found something interesting. I should send it to my language app.**

---

# 9. Universal Input, Language-Focused Output

We should remain focused on **language learning**, while accepting extremely broad source material.

Supported or planned source types:

- YouTube or other permitted URLs
- websites
- articles
- uploaded video
- uploaded audio
- PDF
- screenshot
- camera photo
- pasted text
- document
- podcast content where access permits
- supported social-platform integrations

The product should not depend on scraping every public platform.

Use an adapter architecture:

```text
INPUT ADAPTERS

├── Camera / Photo
├── Screenshot
├── PDF
├── Uploaded Audio
├── Uploaded Video
├── Pasted Text
├── Web Page
├── Permitted URL Integration
└── Future Platform-Specific Integrations
```

This keeps the core product stable when a platform changes API rules.

---

# 10. The Core Learning Loop

## Step 1 — Capture

The learner imports something they care about.

## Step 2 — Understand

AI determines:

- source language
- topic
- context
- difficulty
- communicative intent
- important ideas
- useful vocabulary
- grammar structures
- idioms
- sentence patterns
- domain terminology
- likely real-world conversation connected to the source

## Step 3 — Compare Against Learner State

The system asks:

- What is already mastered?
- What is recognized but not produced?
- What is repeatedly weak?
- What is useful for the learner's stated goals?
- What is appropriate difficulty?
- What should be postponed?
- Which source elements create good speaking opportunities?

## Step 4 — Generate Learning Objective

The lesson receives a compact learning objective.

Example:

```text
SOURCE:
German video about apartment hunting

OBJECTIVE:
By the end of this lesson, learner should be able to:
- ask about Nebenkosten
- use einziehen naturally
- ask a polite question about Kaution
- understand one common rental-contract phrase
```

## Step 5 — Generate Lesson

Create:

- contextual explanation
- selected vocabulary
- grammar insight
- listening task
- mini-games
- speaking preparation

## Step 6 — Speak

Generate a conversation mission grounded in the source and learner weaknesses.

## Step 7 — Collect Evidence

During all activities record evidence.

## Step 8 — Update Learner Model

Determine what should:

- be reviewed soon
- return in another context
- move toward active mastery
- disappear from routine review

---

# 11. Lesson, Not Word Set

The most important product-design decision after studying Lanma is:

> **The persistent object should be a Lesson, not merely a Word Set.**

A lesson contains:

```text
SOURCE
+
SOURCE UNDERSTANDING
+
LEARNER SNAPSHOT
+
LEARNING OBJECTIVES
+
TARGET LANGUAGE ITEMS
+
GRAMMAR / PATTERNS
+
ACTIVITIES
+
SPEAKING MISSION
+
LEARNING EVIDENCE
+
FOLLOW-UP PLAN
```

Vocabulary belongs inside the lesson.

It does not define the entire lesson.

---

# 12. Speaking Is the Hero — But Not the Novelty Claim

Real-time speaking should be the most memorable part of the product.

But the innovation claim should not be:

> "Our app lets you speak to AI."

That category already exists.

The stronger claim is:

> **The AI conversation is automatically designed from the exact content you just encountered and the exact language abilities you still need to develop.**

This transforms voice from a generic chatbot feature into the final stage of the learning compiler.

---

# 13. Pedagogical Conversation Agent

The speaking agent should receive a hidden mission.

Example:

```text
SOURCE:
German apartment-hunting video

TARGET EXPRESSIONS:
Kaution
Nebenkosten
einziehen

KNOWN WEAKNESS:
polite questions

CONVERSATION ROLE:
landlord

SUCCESS:
learner spontaneously uses at least 2 target expressions

RULES:
- never explicitly tell the learner which target word to say
- create natural opportunities for target vocabulary
- simplify if learner repeatedly struggles
- increase difficulty if learner performs easily
- correct only when correction is useful
- do not interrupt fluency for every small error
```

Example:

**AI**

> Wann möchten Sie denn einziehen?

Learner answers.

Later:

**AI**

> Haben Sie noch Fragen zu den Kosten?

This naturally creates an opportunity for:

> Wie hoch sind die Nebenkosten?

If the learner avoids the target concept, the AI can create another context.

That is a genuine adaptive teaching loop.

---

# 14. Conversation Should Adapt in Real Time

The pedagogical agent should observe:

- response latency
- sentence complexity
- repeated errors
- avoidance of target structures
- vocabulary retrieval
- pronunciation uncertainty
- whether the learner switches languages
- whether the learner needs clarification

Then adjust.

### If the learner struggles

- slow down
- shorten sentence
- paraphrase
- provide contextual clue
- reduce target count
- temporarily allow support language
- return to the target later

### If the learner succeeds

- increase speaking speed
- ask an unexpected follow-up
- introduce ambiguity
- remove visual support
- require longer response
- bring back a previously weak structure

The agent should optimize for **productive struggle**, not maximum difficulty.

### 14.1 The Pedagogical Agent HUD (Live Telemetry Visualization)

To prove to judges and advanced users that Talkloom is an active agent—not a generic chat prompt—the client provides an optional **Live Pedagogical HUD (Heads-Up Display)**:

```text
┌─────────────────────────────────────────────────────────────┐
│ 🧠 TALKLOOM AGENT TELEMETRY (LIVE)                          │
├─────────────────────────────────────────────────────────────┤
│ Mission: Elicit [Kaution] | Grammar Target: [Konjunktiv II] │
│ Current Strategy: Landlord discussing deposit regulations   │
│ Cognitive Load: Normal (Speech Latency: 1.1s)               │
│ Dynamic Policy: User hesitated on clause ➔ simplifying turn │
│ Target Detection: 'Kaution' PRODUCED SPONTANEOUSLY! ✨      │
│ State Transition: [Kaution] Recognized ➔ Active Spoken (+1) │
└─────────────────────────────────────────────────────────────┘
```

This live transparency turns invisible LLM behavior into tangible, demonstrable technological sophistication.


---

# 15. Real-Time Voice Architecture

The experience should be streaming from end to end.

```text
Phone Microphone
      ↓
Streaming Audio
      ↓
Voice Activity Detection
      ↓
NVIDIA ASR
      ↓
Partial Transcript
      ↓
Nemotron
      ↓
Streaming Response
      ↓
NVIDIA TTS
      ↓
Streaming Audio
      ↓
Phone Speaker
```

Avoid:

```text
record whole sentence
→ upload
→ wait for transcript
→ wait for entire LLM answer
→ synthesize entire answer
→ play
```

Target experience:

- partial transcript while learner is speaking
- fast end-of-turn detection
- immediate model generation
- TTS starts before the complete answer exists
- interruption stops playback naturally

---

# 16. Barge-In Is Important

Natural conversation requires interruption.

Example:

**AI**

> Wenn Sie den Vertrag kündigen möchten, müssen Sie zunächst—

**Learner**

> Was bedeutet *zunächst*?

The AI should:

1. immediately stop speaking
2. preserve conversation state
3. understand the interruption
4. answer the clarification
5. return to the lesson naturally

This is a small feature with disproportionate perceived quality.

---

# 17. Evidence-Based Learner Model

We should adopt Mural's principle of evidence rather than naive counters, then extend it.

Each evidence event should include fields such as:

```text
timestamp
target_language
item_id
skill_type
source_id
lesson_id
activity_type
context_id
support_level
response
correctness
latency
pronunciation_result
spontaneous_or_prompted
confidence
```

Example evidence:

```text
item: "Kaution"
language: de
activity: live_speech
support: none
spontaneous: true
correct_context: true
timestamp: ...
```

That evidence is more valuable than:

```text
Kaution = mastered
```

because mastery can be recomputed as models improve.

---

# 18. Separate Progress Per Language

Borrow this directly from Mural's architecture.

Every target language should have its own isolated state.

```text
USER

German / de
├── vocabulary evidence
├── grammar evidence
├── listening evidence
├── pronunciation evidence
├── conversation history
├── learner interests
└── lesson history

Spanish / es
├── vocabulary evidence
├── grammar evidence
├── listening evidence
├── pronunciation evidence
├── conversation history
├── learner interests
└── lesson history
```

A German cognate should not accidentally affect Spanish progress.

Switching language should change:

- learner model
- language targets
- speech settings
- TTS voice
- pronunciation evaluation
- teaching policy
- active lesson history

---

# 19. Separate Three Different Languages

The architecture should explicitly distinguish:

### Target Language

The language being learned.

Example:

> German

### Support Language

The language used for explanations.

Example:

> English

### Interface Language

The UI language.

Example:

> Polish

These may all be different.

Example user:

```text
UI: Polish
Explanations: English
Learning: German
```

This becomes important if we want genuinely global multilingual support.

---

# 20. Learner State Should Be User-Controlled

Inspired by Mural's local-first approach, our product should provide:

- clear progress data
- export
- deletion
- per-language reset
- ability to correct AI assumptions
- "I already know this"
- "I don't know this"
- "stop reviewing this"
- "teach this more"
- transparent privacy explanation

We may still use cloud processing because of Nebius/NVIDIA inference.

The principle should be:

> **The user's learner model belongs to the user.**

---

# 21. AI Learning Compiler

Treat the AI subsystem as a compiler.

```text
SOURCE
+
LEARNER MODEL
      ↓
CONTENT ANALYSIS
      ↓
PEDAGOGICAL PLANNING
      ↓
LESSON DSL
      ↓
CLIENT RENDERER
```

Do not ask the model to generate arbitrary front-end code.

The model generates structured content.

The application owns the interaction system.

---

# 22. Lesson DSL

Example:

```json
{
  "source": {
    "id": "source_123",
    "type": "video",
    "topic": "renting an apartment",
    "language": "de"
  },
  "learner": {
    "targetLanguage": "de",
    "supportLanguage": "en",
    "estimatedLevel": "B1"
  },
  "objectives": [
    "Ask about additional costs",
    "Use einziehen in spontaneous speech",
    "Form one polite rental-related question"
  ],
  "vocabulary": [
    {
      "id": "de:kaution",
      "lemma": "Kaution",
      "article": "die",
      "meaning": "security deposit",
      "sourceContext": "Die Kaution beträgt zwei Monatsmieten.",
      "learnerState": "recognized_not_active"
    }
  ],
  "grammar": [
    {
      "concept": "polite_indirect_question",
      "sourceSentence": "Können Sie mir sagen, wie hoch die Kaution ist?"
    }
  ],
  "activities": [
    {
      "type": "context_choice",
      "targets": ["de:kaution"]
    },
    {
      "type": "sentence_builder",
      "target": "Wie hoch sind die Nebenkosten?"
    },
    {
      "type": "speak_response",
      "objective": "Ask about extra costs"
    }
  ],
  "conversation": {
    "role": "landlord",
    "situation": "apartment viewing",
    "hiddenTargets": [
      "de:kaution",
      "de:nebenkosten",
      "de:einziehen"
    ],
    "successCriteria": {
      "spontaneousTargetCount": 2
    }
  }
}
```

---

# 23. Mini-Games

Do not build twenty games.

Build a small number of reusable, polished activity engines.

## 1. Context Choice

Choose a meaning that matches the source context.

## 2. Fill the Gap

Vocabulary or grammar.

## 3. Sentence Builder

Reconstruct a sentence or question.

## 4. Listen & Pick

Listen and identify meaning.

## 5. Shadow

Hear a phrase and reproduce it.

## 6. Say It Yourself

Produce the phrase with minimal support.

## 7. Timed Speaking Challenge

Speak for 20–30 seconds about the source.

## 8. Micro-Retell

Explain one part of the original content in the target language.

Each game emits learning evidence into the same learner model.

---

# 24. Source Understanding Should Create Conversation, Not Just Vocabulary

This is one of the most important strategic differences from a word-centric product.

For every source ask:

> **What real conversation naturally follows from this?**

Examples:

### Rental contract

→ talk to landlord

### Restaurant menu

→ order food

### Train cancellation notice

→ ask railway staff for options

### German filmmaking tutorial

→ explain why the cinematographer made a choice

### Football interview

→ discuss the match

### News article

→ explain or debate the story

### Workplace PDF

→ discuss the topic with a colleague

This is where arbitrary source material becomes meaningful speaking practice.

---

# 25. Example: YouTube Game Development Video

Learner shares a German Unreal Engine video.

The learner already knows:

- Licht
- Szene
- Kamera

They recognize but rarely use:

- Beleuchtung
- Auswirkung

They do not know:

- widerspiegeln

Their grammar weakness:

- Konjunktiv II

The generated lesson may choose:

### Vocabulary

- Beleuchtung
- Auswirkung
- widerspiegeln

### Pattern

> Das hat eine Auswirkung auf ...

### Mini-games

- context choice
- sentence builder
- audio recognition

### Speaking mission

AI asks:

> Warum hat der Entwickler die Beleuchtung geändert?

Then later:

> Was würdest du anders machen, wenn du die Szene entwickeln würdest?

The second question intentionally elicits the learner's weak grammar.

This is much deeper than extracting a word list.

---

# 26. Example: Rental Contract

The learner uploads a German rental contract.

AI identifies:

- Kündigungsfrist
- Kaution
- Nebenkostenabrechnung
- Mietverhältnis

But it does not simply translate the document.

It creates a lesson around what the learner actually needs.

### Understand

What does this clause mean?

### Learn

Five high-value terms.

### Practice

Two mini-games.

### Speak

> **Call your landlord about ending the contract.**

This is language learning attached directly to the user's life.

---

# 27. Home Screen

Avoid a complicated Duolingo-style map.

Keep the product centered around two behaviors.

```text
┌──────────────────────────────┐
│                              │
│    What are we learning      │
│        from today?           │
│                              │
│       + Learn something      │
│                              │
├──────────────────────────────┤
│                              │
│          🎙 SPEAK             │
│                              │
│   Practice what you've       │
│        been learning         │
│                              │
└──────────────────────────────┘
```

Primary actions:

# Learn Something

and

# Speak

---

# 28. Learning Inbox

Imported sources become a Learning Inbox.

Example:

```text
MY LEARNING INBOX

🎬 Unreal Engine lighting tutorial
German · B1
5 targets · 4 min
[Learn] [Speak]

📄 Rental contract
German · B2
7 targets · 5 min
[Learn] [Speak]

📷 Train cancellation notice
German · A2
4 targets · 3 min
[Learn] [Speak]
```

This directly attacks the "save graveyard."

---

# 29. Daily Learning Feed

Over time the product can generate a compact daily session.

Example:

```text
5 MINUTES FOR YOU

1 min — Recall
2 expressions nearing review

1 min — Listen
Phrase from yesterday's video

1 min — Game
Your recurring Dativ mistake

2 min — Speak
Continue yesterday's apartment topic
```

This session is generated from evidence, not from a fixed curriculum.

---

# 30. Progress Screen

Avoid focusing only on XP.

Show meaningful language ability.

Possible metrics:

- expressions encountered
- expressions recognized
- expressions recalled
- expressions used spontaneously
- speaking minutes
- listening performance
- recurring grammar targets
- pronunciation targets
- topics the learner can discuss
- recent improvements
- items returning for review

Example:

```text
GERMAN

Recognize      2,140 expressions
Can recall     1,610
Used in speech 1,084
Stable         846

Speaking this week
47 min

Current focus
• Dativ after common prepositions
• polite questions
• work vocabulary
```

---

# 31. What We Should Learn From Lanma's Product Discipline

Lanma's biggest strength is not novelty.

It is an understandable loop.

We should preserve that clarity.

Our user should understand the product in seconds:

```text
BRING SOMETHING IN
       ↓
LEARN THE USEFUL PART
       ↓
SPEAK ABOUT IT
```

Avoid hiding the core behind:

- dashboards
- complex AI terminology
- too many modes
- too many content types at onboarding
- excessive game mechanics

---

# 32. What We Should Learn From Mural's Product Discipline

Mural demonstrates several good principles:

### Conversation should feel warm, not evaluative every second

Do not correct every error immediately.

### Learner evidence should survive sessions

The app becomes smarter over time.

### Different target languages need isolated progress

No cross-language contamination.

### Current ability estimates should be provisional

Do not overclaim.

### User data controls matter

Provide export/reset/delete.

### Language quality needs human validation

Model output is not automatically pedagogically correct.

For a serious product, supported languages should eventually receive:

- fluent-speaker review
- pronunciation review
- grammar-policy review
- region/variant policy

---

# 33. Strategic Differentiation

We should not compete on:

- number of languages alone
- "AI chat"
- basic vocabulary extraction
- YouTube ingestion
- spaced repetition
- flashcards

Those are increasingly commodity.

Our defensible direction is the combination of:

## 1. Universal real-world input

Not just videos.

## 2. Learner-specific selection

Not "all unknown words."

## 3. Whole-lesson generation

Not just vocabulary lists.

## 4. Generated mini-games

Activities come directly from the source.

## 5. Passive vs active knowledge model

Recognition and production are different states.

## 6. Source-grounded speaking

Talk about the thing you actually imported.

## 7. Pedagogical conversation planning

The AI has hidden teaching objectives.

## 8. Evidence-driven adaptation

Future lessons change because of demonstrated ability.

## 9. Multilingual architecture

Target, support, and interface languages are separate.

## 10. Real-life relevance

The same engine handles a game-dev tutorial and a rental contract.

---

# 34. The Long-Term Moat: The Active Language Graph

The long-term product moat is not the LLM.

It is the learner's **Active Language Graph**.

The graph records relationships among:

```text
learner
↕
language items
↕
grammar patterns
↕
topics
↕
sources
↕
contexts
↕
learning evidence
↕
spoken production
```

Example:

```text
Kaution

Seen:
Rental Contract #12

Recognized:
2 times

Recalled:
1 time

Spoken:
Apartment Conversation #7

Spontaneous:
Yes

Last successful retrieval:
8 days ago

Related:
Nebenkosten
Mietvertrag
Kündigungsfrist

Context:
housing / Germany
```

As this grows, the system becomes increasingly personal.

The model can answer:

> What should this person learn next?

better than a generic tutor with no history.

---

# 35. Product Architecture

Recommended high-level architecture:

```text
Flutter Mobile App
│
├── Share Extension
├── Camera
├── File / PDF Upload
├── Lesson Renderer
├── Mini-Games
├── Voice Client
├── Local Cache
│
▼
Serverpod
│
├── Auth
├── Sources
├── Lessons
├── Learner Model
├── Evidence Events
├── Review Scheduling
├── Realtime Session Coordination
│
├──────────────► Nebius Serverless Jobs
│                media processing
│                transcription
│                source analysis
│                heavy lesson generation
│
├──────────────► Nebius Token Factory
│                Nemotron
│                pedagogical planning
│                learner-state reasoning
│                lesson compilation
│                conversation control
│
└──────────────► NVIDIA Speech
                 streaming ASR
                 streaming TTS
```

---

# 36. Recommended Technology Stack

## Mobile

**Flutter**

Why:

- iOS and Android from one codebase
- share sheet integration
- camera
- microphone
- file picker
- PDF handling
- custom animation
- offline cache
- notification support
- fast iteration
- Flutter Web can provide a judge-friendly demo

## UI Design System & Component Architecture
- **Astryx** (Design system & styling foundation: https://github.com/facebook/astryx) for clean, unified design tokens, typography, and reactive layout composition.
- **Lucide Icons** (https://lucide.dev/) for crisp, modern, and lightweight iconography across mobile and web interfaces.

## Security & Static Auditing
- **Strix** (Security enforcement: https://github.com/usestrix/strix) for continuous automated security scanning, prompt injection defense, sanitized user inputs, and credential protection.

## Token Optimization & Memory Architecture
- **MemPalace** (https://github.com/mempalace/mempalace) for spatial, hierarchical persistent agent memory without reloading entire conversational contexts.
- **Headroom** for aggressive turn and tool output compression.
- **Codebase Memory MCP & Graft** for graph-based symbol navigation and dependency tracking, eliminating wasteful whole-file context dumps.



## Backend

**Serverpod**

Responsibilities:

- authentication
- relational data
- learner profiles
- lessons
- evidence
- reviews
- streaming coordination
- push/background scheduling

## Database

**PostgreSQL**

## Local Cache

**SQLite**

## Heavy Background Work

**Nebius Serverless Jobs**

## LLM

**Nemotron via Nebius Token Factory**

## Voice

NVIDIA open speech models / services appropriate for:

- ASR
- TTS
- streaming voice

---

# 37. Why Flutter Instead of React / Three.js

This app is fundamentally:

> a mobile application containing interactive exercises

not:

> a browser game containing app functionality

The hard product requirements are:

- native share
- camera
- microphone
- notifications
- documents
- offline data
- streaming audio
- mobile UI
- small interactive games

Flutter is well suited to all of these.

Three.js solves a 3D rendering problem that we currently do not have.

Our mini-games are:

- sentence ordering
- word matching
- timed recall
- listening
- speaking
- dragging
- tapping
- pronunciation
- micro-retelling

2D mobile UI is enough.

---

# 38. How Nemotron Should Be Used

Nemotron should be central, not decorative.

Potential roles:

### Source Analyst

Understand what the content is actually about.

### Pedagogical Planner

Decide what this learner should learn from the source.

### Lesson Compiler

Generate Lesson DSL.

### Exercise Generator

Create controlled content for reusable mini-game engines.

### Conversation Director

Create the hidden speaking mission.

### Adaptive Tutor

Change conversation difficulty during the session.

### Evidence Interpreter

Interpret whether a response demonstrates recognition, recall, or production.

### Review Planner

Recommend what should return later.

Different model sizes can be used for different tasks.

Fast everyday tasks should use smaller models.

Deep source analysis and lesson planning can use stronger reasoning models.

---

# 39. Hackathon Track

## Primary Track: Best Apps & Agents

This remains the strongest fit.

The application is:

- something a real person can use
- powered deeply by Nemotron
- mobile-first
- agentic in lesson planning and conversation
- capable of using Nebius Serverless Jobs
- capable of demonstrating persistent user context
- technically rich while still understandable

Do not force the entry into Personal AI.

Persistent memory alone does not make the product an always-on personal assistant.

The app's primary job is teaching.

---

# 40. Core Tavily Integration ($3,000 Special Prize Target)

Tavily is NOT an optional bonus; it is a core feature targeting the **$3,000 Best Use of Tavily Prize** and enriching pedagogical relevance.

### Contextual Cultural & Factual Web Grounding
When a learner imports an article, video, or document:
1. **Tavily Search Engine** fetches 1–3 live, relevant local cultural facts, news items, or statutory updates connected to the topic.
   - *Example:* If an imported German document discusses apartment rentals (`Mietvertrag`), Tavily queries recent Berlin tenancy statutes, current average `Nebenkosten` indices, or `Mietpreisbremse` guidelines.
2. **Context Injection:** These real-time ground truths are injected into the Pedagogical Conversation Agent.
3. **Hyper-Realistic Practice:** The AI roleplayer incorporates current real-world details, making the conversation shockingly grounded.

### "Continue Learning This Topic" Feed
Tavily searches for complementary authentic target-language sources (articles, podcasts, or videos) that match the learner's exact current CEFR level and vocabulary targets.


---

# 41. Hackathon MVP (The 9.5+ Laser-Focused Delivery)

To maximize demo impact without collapsing under scope bloat, the MVP delivers a complete, bulletproof end-to-end loop:

## Core 9.5+ Must-Haves
- **Frontend Client:** Flutter App with responsive Web build for instant judge evaluation. Clean Astryx layout tokens + Lucide icons.
- **2 Rock-Solid Ingestion Modalities:**
  1. **YouTube URL Pipeline:** Fast transcript extraction + CEFR lexical segmentation.
  2. **Document / Photo Input:** Snap a rental contract or official notice.
- **Nebius Serverless Ingestion Worker:** Demonstrating background token processing and Lesson DSL compilation on Nebius.
- **Pedagogical Lesson Compiler:** Powered by **Nemotron** on Token Factory; outputs structured Lesson DSL with 2 high-impact target phrases and 1 grammar structure.
- **1 Polished Interactive Activity:** Sentence Builder / Context Reconstructor (verifies recognition before production).
- **The Voice Hero:** Real-time conversational tutor with **Live Pedagogical HUD Telemetry** (displays target words, AI tactics, speech latency, and live state transitions).
- **Tavily Context Grounding:** Real-time search injection bringing current cultural/statutory facts into the conversation.
- **Creator Smart Lesson Link:** Generating a shareable deep link from any video URL.
- **Ad & Freemium Monetization Architecture:** Native sponsor cards and rewarded session unlock UI.
- **Active Mastery Graph:** Shows vocabulary transitioning from *Recognized* to *Spontaneously Produced*.

## Stretch / Nice to Have
- Native barge-in voice interruption
- Tavily "Next Topic" recommendation feed
- Offline SQLite sync


---

# 42. What Not to Build

For the hackathon, avoid:

- XR
- Omniverse
- Unity
- 3D environments
- social network
- creator marketplace
- broad "learn anything" mode
- 20 mini-games
- huge fixed curriculum
- elaborate avatars
- complex streak economy
- scraping infrastructure for every platform
- generic AI chatbot mode with no pedagogical target

Every feature should reinforce:

**Learn → Practice → Speak → Remember**

---

# 43. Hackathon Demo

## 0:00–0:20 — The Save Graveyard

Show:

- Watch Later
- saved reels
- bookmarks
- screenshots

Say:

> "We already have more language-learning material than we could ever finish. The problem is that saving isn't learning."

Show:

# **Don't save it. Learn it. Speak it.**

---

## 0:20–0:45 — Share

Share a German video into the app.

Show the source entering the Learning Inbox.

---

## 0:45–1:10 — Intelligence

Show that the app knows the learner already recognizes many words.

Instead of extracting 30 words, it chooses:

- 4 expressions
- 1 grammar pattern
- 1 speaking objective

Explain:

> "The question isn't what vocabulary exists in this video. It's what this learner should learn from it."

---

## 1:10–1:35 — Generated Mini-Game

Play one quick activity generated from the source.

Show that it is source-specific.

---

## 1:35–2:25 — Speak About It (The Hero Moment + Live HUD)

Tap:

# 🎙 Speak About This

Engage in a live voice roleplay directly grounded in the imported source (e.g. landlord discussing rental contract).
Show the **Live Pedagogical HUD** in the demo:
- HUD displays real-time agent intent: `Tactic: Nudging for 'Kaution' using local Berlin rent caps fetched by Tavily`
- Show speech latency and cognitive load tracking.
- Learner speaks the target phrase spontaneously.
- The HUD flashes: **Target detected spontaneously! +1 Spoken Mastery**.
- Interrupt the AI once to demonstrate natural barge-in turn-taking.


---

## 2:25–2:45 — Evidence

Show learner state changing:

```text
BEFORE
Auswirkung
Recognized

AFTER
Auswirkung
Used spontaneously in speech
```

Then show one grammar target marked for future review.

---

## 2:45–3:00 — Close

> **Learn your language from anything. Then speak about it.**

---

# 44. Product Metrics That Actually Matter

Avoid optimizing only for:

- streak days
- time in app
- cards completed

Better metrics:

### Activation

% of users who import first source and complete first lesson.

### Conversion to Speech

% of completed lessons that lead to speaking.

### Active Vocabulary Growth

Number of items moving from recognition to spontaneous production.

### Speaking Minutes

Actual target-language production.

### Retrieval Stability

Can the learner still produce an item later?

### Source Habit

How many users repeatedly use Share → app?

### Lesson Completion

Can a lesson fit naturally into 3–7 minutes?

### Conversation Success

Did the learner naturally use the intended targets?

These align the business with actual learning behavior.

---

# 45. Accessible Consumer Business Model & Viral Unit Economics

To drive mass-market adoption and prevent prohibitive user costs, Talkloom is designed around an **Ad-Supported + Low-Cost Freemium** model with sustainable unit economics on open infrastructure.

## 1. Unit Economics: Keeping Consumer AI Costs Minimal
- **Asymmetric Batch Ingestion:** Long-form video transcripts, OCR, and lexical segmentation are run via **Nebius Serverless Jobs**, costing a fraction of a cent per source compared to synchronous high-concurrency LLMs.
- **Model Cascading on Nebius Token Factory:** Routine lesson generation and fast conversation turns are handled by low-latency, low-cost models (**Nemotron Nano / Super**). Expensive reasoning models (**Nemotron 3 Ultra**) are only invoked during deep pedagogical difficulty synthesis.
- **Capped High-Impact Speaking:** Free tier users get focused, 3–5 minute "speaking missions" per lesson. This keeps token burn well below the advertising revenue earned per active session.

## 2. Monetization Tiers
### Free Tier (Ad-Supported & Fully Accessible)
- Core imports (YouTube, articles, photos, PDFs)
- Full interactive lesson compilation
- 1 speaking mission per lesson (ad banner before session; optional 15s rewarded video ad to unlock extra speaking turns)
- Spaced repetition & learner active vocabulary graph
- Non-intrusive banner / native sponsor cards in the Learning Inbox

### Pro Tier (€4.99–€7.99/month — Budget-friendly)
- Zero ads
- Unlimited speaking minutes & extended conversational roleplay
- Offline lesson pack downloads
- Deep pronunciation wave diagnostics
- Multi-target language support

## 3. The Influencer & Community Viral Growth Engine
- **"Talkloom Smart Lesson Links":** YouTube and Instagram language educators often struggle with audience engagement and course conversion.
- Creators can paste their YouTube/Reel URL into Talkloom to generate a branded **"Practice with this Video"** deep link.
- Influencer includes the link in video descriptions: *"Don't just watch this video—practice the conversation right now on Talkloom for free."*
- **Outcome:** Creators gain interactive engagement tools; learners get free practice; Talkloom acquires users at **near-zero CAC** via community word-of-mouth.


---

# 46. B2B Expansion

Long term:

> **Learn the language from your actual job.**

Examples:

## Hospital

International nurse imports:

- hospital terminology
- internal documents
- patient scenarios

The app generates workplace-specific German lessons and patient conversations.

## Engineering

International employee imports:

- work documents
- technical videos
- meeting vocabulary

The app creates professional-language practice.

## Hospitality

Workers learn from:

- menus
- service scripts
- customer situations

## University

Students learn from:

- lecture slides
- administrative emails
- course material

This moves the product from generic consumer language learning into contextual professional training.

---

# 47. Long-Term Vision

The underlying technology may eventually support other learning domains.

However:

> **Build for language first. Architect for learning more broadly.**

Do not expose generic "learn anything" categories initially.

Language gives us:

- a clear user problem
- consistent interaction model
- measurable speaking output
- recurring usage
- global audience
- natural voice component

The broader company vision can remain:

> **Turn the world's existing content into personalized learning.**

But the first product should remain:

> **Learn any language from anything.**

---

# 48. Competitive Matrix

| Capability | Lanma | Mural | **Talkloom** |
|---|---:|---:|---:|
| Live AI voice conversation | ✅ | ✅ | ✅ |
| Persistent learner memory | ✅ | ✅ | ✅ |
| Multiple study languages | ✅ | ✅ | ✅ |
| Per-language progress isolation | Partial / product-dependent | ✅ | **✅ designed explicitly** |
| Share YouTube/article | ✅ | — | ✅ |
| Photo → learning lesson | Not core | — | **Core** |
| PDF/document → lesson | Not core | — | **Core** |
| Screenshot → lesson | Not core | — | **Core** |
| Learner-known word filtering | ✅ | Evidence-driven vocab | ✅ |
| Spaced repetition | ✅ | Recall heuristics | ✅ |
| Flashcards/quizzes | ✅ | Not central | ✅ |
| Generated mini-games | Limited/basic drills | — | **Core** |
| Source-specific grammar objective | Limited | Conversation policy | **Core** |
| Talk about exact imported source | Vocabulary-driven | General/current themes | **Core** |
| Hidden speaking mission | Steers toward words | Adaptive conversation | **Core** |
| Passive vs active production states | Partial | Evidence/recall | **Core model** |
| Source + learner → full lesson | Word-set centered | Conversation centered | **Core** |
| Real-life camera/documents | Not core | — | **Core** |
| Local/private learner records | Not primary positioning | ✅ | Hybrid/user-controlled |
| Evidence event model | Learning state/SRS | ✅ | **Expanded across modalities** |

The table should be treated as a strategic product comparison based on publicly documented capabilities, not as a claim that competitors cannot add features.

---

# 49. What We Must Be Honest About

This category is competitive.

The concept is **not** novel simply because it uses:

- AI
- voice
- YouTube
- spaced repetition
- multiple languages

That is fine.

Products win by creating the best complete behavior, not by being impossible to copy.

Our bar should be:

> **Can a learner see something interesting anywhere on their phone, send it to us, receive a genuinely useful personalized lesson, and be speaking about that exact thing a few minutes later?**

If that loop feels magical, fast, and repeatable, the product has value.

---

# 50. Final Product Definition

## Company Vision

> **Turn the world's existing content into personalized learning.**

## First Product

> **AI-powered language learning from real-world content.**

## User Promise

> **Learn your language from anything. Then speak about it.**

## Behavior Change

> **Don't save it. Learn it. Speak it.**

## Product Loop

```text
SHARE
  ↓
AI UNDERSTANDS THE SOURCE
  ↓
AI UNDERSTANDS YOU
  ↓
AI SELECTS WHAT MATTERS
  ↓
PERSONALIZED LESSON
  ↓
MINI-GAMES
  ↓
SPEAK ABOUT IT
  ↓
LEARNING EVIDENCE
  ↓
SMARTER NEXT LESSON
```

## Differentiation

> **Not more content. Better conversion of real-world input into active language ability.**

## Signature Experience

> **Every lesson should create a reason for the learner to speak.**

---

# 51. One-Sentence Pitch

> **Talkloom turns anything you watch, read, photograph, or receive into a personalized language lesson, then uses a real-time AI conversation to make you actually speak what you just learned.**

---

# 52. 30-Second Hackathon Pitch

> Language learners already save thousands of videos, articles, screenshots, and documents, but saving content does not turn it into language ability. **Talkloom** lets you share anything you're already interested in. AI compares that source with your personal learner model, selects only what is worth learning right now, generates a few interactive exercises, and then starts a real-time conversation designed to make you actually use it. Instead of giving you another curriculum, your own life becomes the curriculum. **Don't save it. Learn it. Speak it.**

---

# 53. Research Sources

Competitive analysis in this document is based on public product documentation reviewed on September 16, 2026.

### Lanma

- Product overview: https://www.lanma.ai/
- About / feature details: https://www.lanma.ai/about
- YouTube learning workflow: https://www.lanma.ai/youtube-english-learning

### Mural

- GitHub repository: https://github.com/Chuloo/mural
- Language architecture: https://github.com/Chuloo/mural/blob/main/docs/language-architecture.md
- Add-language guide: https://github.com/Chuloo/mural/blob/main/docs/add-language.md

---

# Final Brand

> # **Talkloom**

> ## **Learn your language from anything. Then speak about it.**

> # **Don't save it. Learn it. Speak it.**
