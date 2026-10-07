# Talkloom

Talkloom helps German learners turn their own videos, links, text and documents
into material they can speak about. It is a mobile-first Flutter app with a
Serverpod 4 backend and a Web companion. It is designed around a simple path:
bring something you want to understand, review its words and grammar, then use
the material in a conversation.

## Current status

The current repository includes the Flutter shell, source-linked vocabulary and
grammar views, Serverpod endpoints and models, URL/text/media ingestion paths,
and a generated Serverpod client. On 6 October 2026, the local checks passed:
31 backend tests, 11 Flutter tests, both analyzers, Web and Android builds, and a
Docker image build. These checks do not yet prove a deployed, authenticated
import-to-speaking experience on a physical device. See
[`Docs/fix_tickets_2026-10-06.md`](Docs/fix_tickets_2026-10-06.md) and
[`Docs/application_audit_2026-10-05.md`](Docs/application_audit_2026-10-05.md)
for open acceptance gates.

Qwen3-TTS self-hosting, Agent Reach, creator sharing, verified mastery, and
production deployment are not represented as shipped functionality. Do not
describe them as available until their tickets and verification gates close.
Browser speech can use an installed browser voice where supported; native
Android/iOS speech output remains a no-op implementation today.

## Project layout

- `talkloom/talkloom_flutter` — Flutter app for Android, iOS and Web.
- `talkloom/talkloom_server` — Serverpod API, persistence, ingestion and AI
  orchestration.
- `talkloom/talkloom_client` — generated protocol client; do not edit directly.
- `.github/workflows/ci.yml` — repository-root CI for analysis, tests and builds.
- `Docs/` — product design, audit, ticket loop and demo/submission materials.

## Run locally

Install Flutter 3.44.4 or later, Dart, and the Serverpod 4.0.3 CLI. From the
workspace root:

```powershell
cd talkloom
flutter pub get
dart pub global activate serverpod_cli 4.0.3
serverpod start
```

The backend expects its local database password in the untracked
`talkloom_server/config/passwords.yaml`. Never commit that file or paste its
contents into tickets or logs. To extract YouTube captions, install the Python
dependency once from `talkloom/talkloom_server`:

```powershell
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r scripts/requirements.txt
```

Set `TALKLOOM_PYTHON_EXECUTABLE` to the Python interpreter containing that
dependency when running the server outside the development virtual environment.
On a physical Android device, pass the reachable API host with
`--dart-define=SERVER_URL=http://<computer-lan-ip>:8080/`.

## Verify locally

Run each command from the indicated package directory:

```powershell
# talkloom/talkloom_flutter
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug

# talkloom/talkloom_server
dart analyze
dart test
```

The server tests use Serverpod's local embedded test database. iOS compilation
requires macOS and Xcode:

```sh
cd talkloom/talkloom_flutter
flutter build ios --debug --no-codesign
```

CI runs on pushes and pull requests to `main`. It runs the Flutter and Serverpod
checks, Web and Android builds, an unsigned iOS compile, and a backend container
build. The container can be built manually from the repository root:

```sh
docker build -f talkloom/talkloom_server/Dockerfile -t talkloom-server .
```

## Production configuration

Production is not deployed from this repository yet. Serverpod configuration
values can be overridden with environment variables; configure the public API,
Insights and Web hosts, database connection, secrets, allowed browser origins,
and the Flutter `SERVER_URL` for the actual environment before deployment. The
`examplepod.com` values in the sample production YAML are placeholders, not live
hosts. See the [Serverpod configuration reference](https://docs.serverpod.dev/concepts/lookups/configuration-reference).

## License

No license has been selected or added to the repository yet.
