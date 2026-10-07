# Talkloom Flutter app

Mobile-first Talkloom client for Android and iOS, with a Web companion. The
app's product contract is in [`../../Docs/talkloom_design_specification.md`](../../Docs/talkloom_design_specification.md).

## Run

From this package directory, resolve workspace packages and launch through the
Serverpod workspace:

```sh
flutter pub get
cd ..
serverpod start
```

For a physical Android device, pass a reachable backend address with
`--dart-define=SERVER_URL=http://<computer-lan-ip>:8080/`. Production Web builds
must be compiled with their deployed API URL; do not ship the localhost default.

## Verify

```sh
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
```

Build iOS on macOS with Xcode using `flutter build ios --debug --no-codesign`.
Camera and microphone behavior still requires permission testing on physical
devices. See the active acceptance gates in
[`../../Docs/fix_tickets_2026-10-06.md`](../../Docs/fix_tickets_2026-10-06.md).
