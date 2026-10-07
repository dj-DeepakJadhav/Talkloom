# Serverpod 4 and agent workflow

This repository is a Serverpod 4.0.3 / Dart 3.13.3 workspace. The Git
repository root is `C:\DJ\Hackathon\Talkloom`; the Dart workspace root is
`C:\DJ\Hackathon\Talkloom\talkloom`, which contains the Flutter, server, and
generated client packages.

## What is configured

- Official Serverpod agent skills are installed in `talkloom/.agents/skills/`
  for the three-package Dart workspace (21 skill areas).
- `.codex/config.toml` registers the Serverpod MCP server and the Dart MCP
  server for this repository.
- `talkloom/AGENTS.md` contains project-specific workflow constraints and
  product context. Read it before changing code in the Dart workspace.
- The repository-level codebase-memory MCP graph is a separate code-navigation
  index. Use it for code discovery first; refresh it after substantive code
  changes. The Serverpod skills/MCP complement that graph rather than replace
  it.

MCP tools that inspect or control the running development environment are
available only when the corresponding process is running. The project owner
starts and manages the app. After changing `.codex/config.toml`, reload/reopen
the Codex project before expecting MCP servers to appear.

## Windows CLI loop

From PowerShell:

```powershell
Set-Location C:\DJ\Hackathon\Talkloom\talkloom
serverpod version
serverpod start
```

`serverpod start` is the Serverpod 4 development orchestrator: it runs the
backend and local database, launches configured Flutter apps, watches code,
regenerates generated protocol code, and coordinates hot reload. In its
interactive terminal, `M` creates and applies a migration, `P` creates/applies a
repair migration, and `R` hot-restarts. For the project test suite:

```powershell
Set-Location C:\DJ\Hackathon\Talkloom\talkloom\talkloom_server
dart test
```

Use Serverpod MCP tools for live logs, hot reload/restart, Flutter app controls,
and migration operations when the user-started environment is connected. Use
the CLI for version checks, code generation troubleshooting, and command-line
fallbacks documented in `talkloom/AGENTS.md`. Never run `serverpod create .` on
this existing application: Serverpod warns it can overwrite server
configuration, auth, workflows, Flutter files, and ignored passwords/secrets.

Define/edit model sources and endpoint code; never edit generated protocol code
directly. Review every generated migration and protect existing data before
applying it. `talkloom/talkloom_server/config/test.yaml` uses embedded PostgreSQL,
so tests do not require the development Docker database.

## Skills command and workspace placement

The current installed Dart `skills` CLI is version 1.0.3. Its command syntax
differs from the older Serverpod docs: from the Dart workspace root, use:

```powershell
Set-Location C:\DJ\Hackathon\Talkloom\talkloom
skills get --all --agent codex
```

This scans the three Dart workspace packages and updates the generic `.agents`
skills directory. If the CLI is missing, run `dart install skills`; on this
machine the executable was installed under
`%LOCALAPPDATA%\Dart\install\bin`, which may need to be added to the user's
`PATH`. Do not run `serverpod create .` as a shortcut for enabling agent tools.

## Notebooks

Serverpod's current product/docs pages describe Dart tools, agent skills, MCP,
and the development CLI; they do not describe Jupyter or notebook support. No
`.ipynb` notebooks are present in this repository. For this app, keep testable
examples and evaluations in Dart tests/scripts unless a specific data-analysis
task justifies a notebook. Never place credentials, private learner data, or
unlicensed media/transcripts in notebooks.

## App Studio and related tools

Serverpod App Studio is an optional packaged Flutter/Serverpod development
environment, not a different project format. The Serverpod 4 announcement says
its beta launched on macOS and Windows was “coming soon.” The current App Studio
page shows “Windows Download” text but exposes no Windows download link. Until
an installer is actually published, this Windows machine should use the normal
Serverpod CLI workflow configured here.

Serverpod Insights is a separate tool for inspecting requests, exceptions, and
slow queries; its documentation describes it as a desktop companion. Do not
conflate Insights availability with App Studio availability. Serverpod's
open-source page also lists related Dart/Flutter packages (including Relic,
`cli_tools`, `config`, and experimental Labs projects); none is required to
enable this app's agent workflow. Serverpod 4.0 offline sync is experimental;
Talkloom does not currently depend on it.

## References

- [Serverpod 4 release](https://serverpod.dev/blog/serverpod-4)
- [Serverpod documentation](https://docs.serverpod.dev/)
- [Upgrade guide and agent workflow](https://docs.serverpod.dev/upgrading/upgrade-to-four)
- [App Studio](https://serverpod.dev/appstudio)
- [Serverpod open source](https://serverpod.dev/open-source)
