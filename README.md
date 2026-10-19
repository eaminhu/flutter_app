# Flutter NexusFT

**English** | [简体中文](README.zh-CN.md)

Android/iOS Spot-first client. UI direction: Forui with custom trading components.

The network/session foundation is implemented: GoRouter, Riverpod, Dio, strict v1 decoding, scoped secure credentials, login guards, persistent language/theme settings and Forui controls.
The default dev build reads the real public catalog (18 entries verified). Quotes, charts, order books, order placement and full assets are not implemented. Real-account login, iOS and physical devices remain unverified.

```powershell
cd D:\project\flutter_nexusft
.\scripts\android-studio.ps1
.\scripts\check-android-requirements.ps1
.\scripts\flutter.ps1 analyze
.\scripts\flutter.ps1 test
D:\development\flutter\bin\dart.bat run tool/check_architecture.dart
.\scripts\flutter.ps1 run -d emulator-5554
```

SDKs/caches/AVD use D drive. Run/build wrappers preflight the current dependency lock and Android components; direct IDE Run does not invoke this preflight.
Default APP_ENV is dev. Other environments need an explicit HTTPS API_BASE_URL; credentials are scoped by environment and server.
The debug app uses a development com.example identifier.

Start with [handoff](docs/handoff.md), [documentation](docs/manifest.md), [architecture](docs/architecture.md) and [current verification](docs/references/2026-10-13-network-session-verification.md).

