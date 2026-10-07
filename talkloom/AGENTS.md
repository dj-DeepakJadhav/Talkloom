# Flutter & Serverpod project

This project is a Flutter app (frontend) backed by a Serverpod server (backend). Always build the app's backend with Serverpod.
Build for multiple users, use Serverpod's built-in authentication, which is already set up in `lib/server.dart`.

The user starts the server and Flutter app with `serverpod start`. There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then STOP and ask the user to start it. NEVER start the server yourself. The Flutter app is started along with it, or can be launched from the MCP tool `spawn_flutter_app`.

While running, `serverpod start` watches for file changes to run incremental code generation and hot reload both the server and the Flutter app.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

ALWAYS use the MCP server instead of the command line. Use the MCP server to:

- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `tail_flutter_logs` to read the raw stdout/stderr of the Flutter app.
- `hot_reload` / `hot_restart` to reload or restart the server and the Flutter app. ALWAYS call `hot_restart` after doing changes in the Flutter app that may not work with normal hot reload (which is automatically applied).
- `spawn_flutter_app` to start a Flutter app declared under `serverpod: flutter_apps:` in the server `pubspec.yaml`.
- `get_flutter_app_dtd` (Dart tooling daemon) for connecting to the app through the `dart` MCP.

NEVER edit generated code. The server's `lib/src/generated/` directory and the whole `talkloom_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the server cannot be started at all, fall back to the CLI in the server package:

- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; `serverpod start` applies pending migrations when it boots the server.

Tests need no Docker. `config/test.yaml` sets `database.dataPath`, so Serverpod starts and manages the test database (an embedded PostgreSQL) itself, and the project's `docker-compose.yaml` is not used for it. Just run `dart test` in the server package.

Checklist after doing changes, in this order:

- `dart analyze` (CLI)
- `dart format` (CLI)
- `create_migration` and `apply_migrations` (MCP - only if necessary)
- Do `serverpod` MCP `hot_restart` if required (hot reload is done automatically). Will also hot restart Flutter app
- Run tests, if applicable (`dart test` in the server package)
- Check `serverpod` MCP `tail_server_logs` and `tail_flutter_logs` for any issues.

If the user asks you to test the app:

1. Use `get_flutter_app_dtd` (`serverpod` MCP) to get the Flutter app's DTD
2. Pass the DTD to `connect_dart_tooling_daemon` (`dart` MCP) to connect to the app
3. Use `flutter_driver` (`dart` MCP) to navigate through the app

The app is launched from `talkloom_flutter/lib/driver.dart`, which starts the Flutter driver extension with text entry emulation turned off so the app stays usable by hand. To let the driver type, set `enableTextEntryEmulation: true` there and `hot_restart` the app.

## Talkloom application

Guest-first access is required. Create a unique persisted Serverpod anonymous
session automatically; keep registration optional. Never restore the former
mandatory-sign-in product flow or a shared guest identity. Account conversion
must verify both identities and transfer learning data transactionally. See
`../Docs/guest_access.md` for the implementation and recovery contract.

German-first, user-content-driven language learning. The current shell exposes
Today, My content and My German. Source detail opens speaking first, with optional
practice; collection entries preserve original context. Follow
`../Docs/talkloom_design_specification.md`, not historical Mural screenshot
matching. Do not introduce sample lessons or simulated mastery into default flows.

Client providers use selectedSourceProvider and activeLessonProvider to carry
context. Runtime speech imports are conditional: Web speech uses the browser's
installed voice; the current Android/iOS TTS stub is a no-op. The selected
direction is self-hosted open-weight Qwen3-TTS behind Serverpod; this is a plan,
not an implemented or verified integration. No new server models or migration
were introduced by the editorial redesign. A separate Serverpod 4.0.3 auth-core
schema-sync migration was added on 6 October 2026 after startup exposed drift in
`serverpod_auth_core_profile_fk_1`; the generated migration is
`talkloom/talkloom_server/migrations/20261006192906960-sync-auth-core-schema`.
After Serverpod dependency upgrades, run `serverpod create-migration`, inspect
the generated SQL, and apply it through the normal server startup before testing.

Known backend audit findings (shared anonymous identity, fabricated import
fallbacks and unvalidated evidence) remain separate work. Never claim the UI
redesign resolves those defects.

The release contract is mobile-first Android and iOS, with Web as a supported
companion build. Check 360 px phone layouts, safe-area insets, keyboard scrolling,
camera/file permissions, and native speech fallbacks before tuning wide layouts.

## Serverpod 4 agent workflow (Windows)

The repository is opened at its root, while the Dart workspace is `talkloom/`.
Official Serverpod skills live in `talkloom/.agents/skills/`; refresh them from
the Dart workspace root after changing Serverpod dependencies with
`skills get --all --agent codex`. On machines where the `skills` executable is
not on `PATH`, install it with `dart install skills` and add Dart's install bin
directory to the user's `PATH`.

The repository-root `.codex/config.toml` registers the Serverpod MCP server and
Dart MCP server. Serverpod MCP operations depend on the dev environment started
by the user; do not launch, stop, or restart it unless explicitly asked. After
changing the MCP configuration, reload/reopen the Codex project so it discovers
the servers. Agent skills provide domain guidance; MCP provides access to the
live app's logs and development controls.

`serverpod start` is the normal full-stack development command from
`talkloom/`. It orchestrates the backend, local development database, configured
Flutter app, code generation, and hot reload. In the Serverpod 4 terminal UI,
`M` creates and applies a migration, `P` creates/applies a repair migration,
and `R` hot-restarts. Use the CLI only for documented fallbacks or diagnostics;
do not run `serverpod create .` on this existing application because that can
overwrite server/config/authentication files and secrets. Model sources stay
editable; generated client/server files are not. Inspect migration SQL and
preserve data before applying schema changes. Run server tests with `dart test`
from `talkloom/talkloom_server/` (the project test config uses embedded
PostgreSQL).

Serverpod does not document a notebook runtime or Jupyter notebook workflow, and
this repository has no `.ipynb` notebooks. Use Dart tests and small, reviewable
scripts for executable examples/evaluations; add notebooks only for a concrete
analysis need, with sensitive user/media data excluded.

App Studio and Serverpod Insights are separate tools. Serverpod's release post
describes App Studio as a macOS beta with Windows coming soon. The current page
shows “Windows Download” as plain text without an actual download link, so treat
Windows App Studio as unavailable until a verifiable installer is published.
The Serverpod CLI and regular Dart/Flutter workflow are the supported path for
this Windows project. Do not add experimental offline sync to Talkloom without
a product requirement and a fresh compatibility review.

For link ingestion, Agent Reach is the preferred external capability layer:
https://github.com/Panniantong/agent-reach. Use its health-checked upstream
selection first in a worker adapter, then fall back to the normal platform
resolver and AI path. Do not add Agent Reach as generated Serverpod code or
claim the current Dart resolver has completed that integration.
