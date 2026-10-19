# 基础框架验证

日期：2026-10-13
项目：D:\project\flutter_nexusft

## 证据

- 五项直接依赖的批准命令执行退出码 0，版本见 framework-dependencies.md / pubspec.lock。
- dart format lib test tool 已执行。
- dart run tool/check_architecture.dart：Architecture boundaries passed，退出码 0。
- scripts/flutter.ps1 analyze：No issues found，退出码 0。
- scripts/flutter.ps1 test：16 项通过，退出码 0。
- scripts/flutter.ps1 build apk --debug --verbose：BUILD SUCCESSFUL，80 个任务，最终重建退出码 0；完整诊断位于 build/foundation-apk-build.log（构建产物，不作为仓库文档来源）。
- apksigner verify --verbose：Verifies，v2 签名通过，1 个 signer，退出码 0。
- aapt 元数据：com.example.flutter_nexusft，版本 1.0.0+1，minSdk 24，target/compileSdk 36。
- APK：build/app/outputs/flutter-apk/app-debug.apk，177616619 字节；最后构建 2026-10-13 11:29:32。
- SHA256：79446E8D1B6D2878B43796D18F9B92DA601C51362B2A1BBE467F3243A2B75675。

首次构建耗时约 980 秒，长时间没有终端输出；最终返回构建成功。两项审查修复之后按最终源码重新构建，约 14 秒成功。不以先前模板 APK 或第一次构建代替最终产物证据。

## 行为与反例

自动化覆盖现货入口、导航、语言/主题跨导航保留、系统 zh-Hant-HK 使用繁体、加载到成功空结果、错误到手动重试、失败不自动重试、Page 不可变、非法环境拒绝、三语言 key 完整性、缺失金额与零区分、必填金额错误、0.1+0.2=0.3 和长小数精度。

架构反例覆盖相对 adapter 导入、跨模块导入、纯 core 使用 Flutter、页面使用 IO，以及条件 import/export 分支。两项审查问题均先通过失败回归测试复现，再修复并通过。独立只读审查及复核未发现本阶段范围内 Critical / Important 问题。

## 边界

上述 API 读取测试使用受控测试 fixture；没有访问真实后端，也不声称真实交易端到端验证通过。当前正常展示后端未连接。图表依赖已安装，图表本身尚未实现。

widget 测试不等同于手机视觉/手势验证。用户明确推迟真机验证；未安装模拟器，iOS 未构建。偏好没有持久化。debug APK 不是商店发布产物。

环境仍有未使用 SDK 许可/Windows 桌面工具诊断；构建存在 SDK XML 版本与 Gradle 弃用提示。此次 Android 构建已验证，不宣称环境无任何提示。

未执行 Git 操作、手机安装、生产交易或发布。


后续模拟器运行重新构建了同路径 APK；本文件保留基础阶段历史证据，当前产物见 2026-10-13-android-emulator-verification.md。
