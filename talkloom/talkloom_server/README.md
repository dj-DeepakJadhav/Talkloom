# Talkloom Serverpod server

Serverpod API and persistence layer for Talkloom. The package is part of the
Dart workspace in `../` and uses the generated `../talkloom_client` package.

## Development

From the workspace root, start the backend and configured Flutter app together:

```powershell
cd talkloom
serverpod start
```

Keep `config/passwords.yaml` local and untracked. Serverpod values can be
overridden with `SERVERPOD_*` and `SERVERPOD_PASSWORD_*` environment variables.
Do not put API keys or database passwords in source control.

## YouTube captions

The local extractor uses `youtube-transcript-api`:

```powershell
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r scripts/requirements.txt
```

On macOS or Linux, use `.venv/bin/python`. Set
`TALKLOOM_PYTHON_EXECUTABLE` when the interpreter is elsewhere. Missing or
unavailable captions are reported as an import error; the server must not
invent source text as a substitute. The production image packages the extractor
and its Python dependency.

## Checks

```sh
dart analyze
dart test
```

The tests use Serverpod's local embedded test database; no Docker database is
required. Build the production container from the repository root:

```sh
docker build -f talkloom/talkloom_server/Dockerfile -t talkloom-server .
```

See [`../../Docs/fix_tickets_2026-10-06.md`](../../Docs/fix_tickets_2026-10-06.md)
for current release and verification gates.
