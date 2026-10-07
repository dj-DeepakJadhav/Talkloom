# Talkloom — Build Something Real

Updated 6 October 2026 for the Serverpod Build Something Real hackathon.

## The problem

Language learners routinely save a useful video, post, article or document and
never study it again. Generic lessons are easy to abandon because they do not
connect to the content a learner already cares about.

## The product

Talkloom is a German-first, mobile-first app for turning a learner's own content
into a reason to speak. The intended path is:

**share or add a source → see its vocabulary and grammar → speak about it → keep
the source-linked learning record**

The learner supplies the lesson material. Talkloom should not insert invented
transcripts, sample vocabulary or simulated progress. Speaking is the primary
learning action; short source-specific exercises are optional.

## Why Serverpod matters

Serverpod provides the typed Flutter client boundary, authenticated endpoints,
relational source and lesson storage, and persistent learning records. Those
benefits count only when ownership and authorization are enforced and shown in a
working flow. See the audit and ticket tracker for remaining proof gates.

## Scope decisions

- German first; support additional languages after the complete German loop is
  trustworthy.
- Links, text, images, documents and camera capture are input modes, but each
  must return an honest success or actionable failure.
- Reuse analysis for repeated links only when a complete source-grounded lesson
  exists. A shared cache must not expose one learner's private progress to
  another.
- Mini-games are generated from the learner's source, not a generic starter
  curriculum.
- Open-weight Qwen3-TTS behind a private worker is a future direction. Current
  Web/native voices and all platform fallbacks must be described according to
  what is actually tested.
- Agent Reach is a reference for resilient link retrieval, not a delivered
  integration.

## Differentiation to prove

“Learn from your own content” is not enough by itself. The hackathon demo needs
to show a reliable Serverpod-backed loop: an authentic source, complete
source-linked takeaways, a contextual speaking turn, and a persistent record
that belongs only to the learner. Avoid claiming mastery from a single turn or
promising formal CEFR assessment without validated evidence.

## Acceptance and status

The canonical interface and interaction contract is
[`talkloom_design_specification.md`](talkloom_design_specification.md). Current
verification is in [`application_audit_2026-10-05.md`](application_audit_2026-10-05.md);
active fixes are assigned in [`fix_tickets_2026-10-06.md`](fix_tickets_2026-10-06.md).
No real deployment, provider-backed AI session, or physical-device permission
test is claimed by this document.
