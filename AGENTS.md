# Talkloom repository guidance

Talkloom is a Flutter application backed by Serverpod 4. The Dart workspace is
`talkloom/`; its packages are `talkloom_flutter`, `talkloom_server`, and the
generated `talkloom_client`. Read `talkloom/AGENTS.md` before work in that tree.

## Codebase knowledge graph

Use codebase-memory-mcp for code discovery before filesystem searches:
`search_graph`, `trace_path`, `get_code_snippet`, `query_graph`, then
`get_architecture`. The initialized project identifier is
`C-DJ-Hackathon-Talkloom-Talkloom`.

The persistent graph artifact is `.codebase-memory/graph.db.zst`, with metadata
in `.codebase-memory/artifact.json`. Refresh the index after substantive code
changes. Use filesystem searches for configuration, documentation, literal
strings, or when the graph returns insufficient results. Verify source before
trusting graph line numbers or complexity estimates.

## Current review context

The user is targeting the Serverpod Build Something Real hackathon:
https://builderbase.com/event/build-something-real-the-serverpod-hackathon

Existing Nebius/NVIDIA-focused documents are historical material and require
reconciliation with this target. Do not treat checked task boxes or submission
claims as proof of working functionality. The October 2026 audit is recorded in
`Docs/application_audit_2026-10-05.md`.

Never edit generated client/server code directly. Do not start the application
server autonomously; follow the nested Serverpod guidance. Unit tests and static
analysis are allowed. Keep credentials out of graph notes and review documents.
