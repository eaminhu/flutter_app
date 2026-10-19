# 开发环境与项目初始化计划

日期：2026-10-12
状态：D 盘环境与 APK 初始化里程碑完成；用户明确推迟真机验收，框架依赖安装进入下一步确认。
负责人：当前 Codex 会话
目标：用官方 Flutter 工具在 D:\project\flutter_nexusft 生成 Android/iOS 项目并验证 Android 初始构建。
范围：环境安装与官方项目初始化；现货功能实现进入下一里程碑，不在本计划内直接写交易逻辑。
架构：保留已确认的 app/core/design_system/shell/modules 分层，首个业务模块为 Spot。当前阶段不创建无实现的业务模块或假接口。
技术栈：Flutter stable（安装时记录准确版本）、其捆绑 Dart、Android Studio stable 与 Android SDK。
执行方式：当前会话逐任务执行。用户明确要求前不运行任何 Git 命令，不创建 worktree，不提交或推送。
退出条件（按用户后续选择调整）：所需 Android 工具链可编译、分析/模板测试/Android 构建通过、产物检查通过；真机验证稍后做，iOS 保留为明确未验证项。doctor 的未使用 SDK 许可/Windows 桌面工具提示单独记录。

## 文件与产物

- docs/designs/2026-10-12-flutter-foundation.md：已确认的总体设计。
- docs/references/windows-install-checklist.md：安装范围、位置、命令和来源。
- docs/status.md：当前完成项与待处理条件。
- pubspec.yaml、lib/main.dart、test/widget_test.dart、android/、ios/：由官方 flutter create 生成。
- README.md、README.zh-CN.md：初始化后写入等价的中英文运行说明。
- docs/manifest.md、docs/manifest.zh-CN.md：初始化后写入等价的文档导航。

## 任务 1：预检与安装授权

- [x] 确认目标目录和现货优先设计。
- [x] 确认 Windows x64、Git 与 winget 可用。
- [x] 检查 PATH、SDK 环境变量及常见目录；用户确认尚未安装开发环境。
- [x] 保存具体安装清单和命令。
- [x] 用户确认安装到 D 盘；开始下载 SDK，不改全局 PATH。

## 任务 2：Flutter SDK

- [x] 官方元数据选定 3.47.7；同版本 CFUG 镜像下载完成，官方 SHA256 核验通过并解压到 D 盘。
- [x] 已记录 Flutter 3.47.7、Dart 3.13.5、archive 地址和 SHA256。
- [x] Flutter --version 已验证，退出码 0；通过项目启动脚本调用，不改全局 PATH：

```powershell
& 'D:\development\flutter\bin\flutter.bat' --version
& 'D:\development\flutter\bin\dart.bat' --version
```

预期：两条命令成功并显示版本。下载、解压或工具初始化失败时保留错误输出，不换成手写的近似项目模板。

## 任务 3：Android 工具链

- [x] 发现 D:\Program Files\Android\Android Studio 已有可用安装，自带 Java 21.0.5 已验证；先复用。
- [x] SDK 已安装到 D:\Android\Sdk；未安装模拟器，预设模拟器数据路径 D:\Android\avd。
- [x] 已安装 API 36 r2、Build-Tools 36.0.0、Command-line Tools 22.0、Platform-Tools 37.0.1 和 NDK 28.2.13676358。模拟器与 CMake 按实际需要安装。
- [x] 使用现有 Android Studio 自带 Java 21；Flutter 已配置 D 盘 SDK 和 JBR 路径：

```powershell
& 'D:\development\flutter\bin\flutter.bat' config --android-sdk 'D:\Android\Sdk'
& 'D:\development\flutter\bin\flutter.bat' doctor -v
```

- [x] 用户已明确确认 Google SDK 许可；所需 android-sdk-license 已接受，未自动接受未使用组件的其它许可：

```powershell
& 'D:\development\flutter\bin\flutter.bat' doctor --android-licenses
```

- [ ] 连接开启 USB 调试的 Android 真机，或创建 API 36 x86_64 模拟器并启动。虚拟化/Windows 功能变更如确有需要，列出具体变更后单独确认。
- [ ] 验证设备发现：

```powershell
& 'D:\development\flutter\bin\flutter.bat' devices
```

预期：doctor 的 Flutter 与 Android toolchain 通过；devices 至少发现一个 Android 设备。Windows 桌面工具缺失不属于本计划失败。

## 任务 4：官方项目初始化

- [x] 检查无既有代码；官方 Android/iOS 项目生成成功，默认依赖已解析到 D 盘：

```powershell
Set-Location -LiteralPath 'D:\project\flutter_nexusft'
& 'D:\development\flutter\bin\flutter.bat' create --platforms=android,ios --project-name flutter_nexusft --no-pub .
& 'D:\development\flutter\bin\flutter.bat' pub get
```

`--no-pub` 将生成项目与下载依赖分开。正式发布 applicationId / bundle identifier 未确定前，生成的默认标识仅用于开发，不发布商店。

- [x] flutter analyze：No issues found；flutter test：1/1 通过。
- [x] Android build apk：退出码 0，236.2 秒生成 debug APK：

```powershell
& 'D:\development\flutter\bin\flutter.bat' analyze
& 'D:\development\flutter\bin\flutter.bat' test
& 'D:\development\flutter\bin\flutter.bat' build apk --debug
```

预期：完整输出和退出码均成功，生成 debug APK。构建会获取模板所需 Gradle/Android 构建依赖，属于须确认的初始化范围。

- [ ] 仅连接一个 Android 设备时运行：

```powershell
& 'D:\development\flutter\bin\flutter.bat' run
```

如发现多个设备，先选定已发现的设备 ID，再指定 `-d`；记录设备、实际运行结果和截图。

## 任务 5：关闭环境里程碑

- [x] SDK 版本、分析/测试命令和退出码已记录，status 已更新。
- [x] APK 构建、元数据与签名检查完成，详见 ../references/2026-10-12-bootstrap-verification.md。
- [ ] Android 设备与截图证据：用户明确推迟，不属于本轮 APK 构建验收。
- [x] 已生成中英文 README 和文档导航，说明运行方式与 iOS 构建条件。
- [ ] 下一里程碑按已确认设计制定基础框架计划，列出 Riverpod、go_router、webview_flutter、Decimal 和本地化依赖的准确版本及安装命令供确认。
- [ ] macOS/Xcode 不可用时明确标记 iOS 构建和真机验证未完成，不能以 Android 成功代替。



