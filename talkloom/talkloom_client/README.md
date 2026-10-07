# Talkloom Serverpod client

This package contains the generated Dart client for Talkloom's Serverpod API.
It is consumed by `talkloom_flutter` and regenerated from the server endpoints
and protocol models.

Do not edit files under `lib/src/protocol` directly. Change the server endpoint
or `.spy.yaml` model, then use the Serverpod generation workflow described in
[`../AGENTS.md`](../AGENTS.md). Commit generated client changes with the
endpoint/model change that requires them.

The current client provides authenticated account, ingestion, lesson, learner
state, evidence history and pedagogical conversation endpoints. Server APIs
require an authenticated session for private content and learning progress.

For setup and test commands, see the [workspace README](../../README.md) and
the [engineering status](../../Docs/talkloom_task_list.md).
