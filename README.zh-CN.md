# Flutter NexusFT

[English](README.md) | **简体中文**

Android/iOS 手机端，现货优先。UI 方向：Forui + 自定义交易组件。

网络/会话基础设施已实现：GoRouter、Riverpod、Dio、严格 v1 映射、安全凭证隔离、基础登录守卫、语言/主题持久化与 Forui 控件。
默认 dev 连接真实公开目录，已核对 18 条交易对。价格、图表、盘口、交易写入和完整资产尚未实现；真实账号登录、iOS 与实体手机未验收。

```powershell
cd D:\project\flutter_nexusft
.\scripts\android-studio.ps1
.\scripts\check-android-requirements.ps1
.\scripts\flutter.ps1 analyze
.\scripts\flutter.ps1 test
D:\development\flutter\bin\dart.bat run tool/check_architecture.dart
.\scripts\flutter.ps1 run -d emulator-5554
```

SDK、缓存、AVD 使用 D 盘。run/build 包装脚本预检当前依赖锁和 Android 组件；IDE 直接 Run 不执行此门禁。
默认 APP_ENV=dev；其他环境需显式 HTTPS API_BASE_URL。凭证按环境与服务器隔离，开发 applicationId 为 com.example。

从[交接文档](docs/handoff.md)、[文档总览](docs/manifest.zh-CN.md)、[架构](docs/architecture.md)与[本轮验证](docs/references/2026-10-13-network-session-verification.md)进入。

