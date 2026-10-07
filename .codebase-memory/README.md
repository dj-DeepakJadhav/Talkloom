# Talkloom codebase memory

The codebase-memory-mcp connection is configured in the local Codex configuration.
This repository was first indexed on 2026-10-05 with full extraction and
persistence enabled. The MCP project identifier is
`C-DJ-Hackathon-Talkloom-Talkloom`.

`graph.db.zst` is the compressed graph; `artifact.json` records its source commit,
index time, and node/edge counts. The initial source index contains 2,074 nodes
and 5,641 edges. Regenerate after substantive changes using `index_repository`
with the repository root, `name: "Talkloom"`, `mode: "full"`, and
`persistence: true`. The artifact is a snapshot, not a live correctness check.

## Architecture notes

- `talkloom/pubspec.yaml` defines a Dart workspace with a Flutter UI, Serverpod
  backend, and generated client. All Serverpod dependencies are pinned to 4.0.0.
- Backend ingestion produces Source rows; compilation produces Lesson rows;
  conversation and activities produce EvidenceEvent and LearnerState rows.
- Authentication services are configured in `talkloom_server/lib/server.dart`,
  but application endpoints currently permit anonymous calls and share the
  `guest_learner` identity. This is an unresolved security defect.
- The initial route now renders Today / My content / My German. Source detail
  opens speaking or source-derived practice. Legacy prototype screens remain
  outside this navigation. German is the initial target language.
- AI/compiler/search/import fallbacks can return sample content without explicit
  provenance. Existing documents overstate several live integrations.
- Browser speech APIs now use conditional platform exports. Native voice input
  reports unavailable; the conversation offers typed replies.

See `Docs/application_audit_2026-10-05.md` for evidence, verification outcomes,
and prioritized work. These observations describe the reviewed implementation;
they are not architectural decisions endorsing its defects.


## Redesign index refresh

The full index was refreshed after the editorial redesign. The tool returned
2,085 nodes and 5,651 edges with persistence enabled. A follow-up search did not
find the new, untracked SourceDetailScreen file. Treat this graph as incomplete
for newly added files until indexing confirms them; use the source files and
current design specification as the authoritative reference for those screens.
