# Windows 开发环境安装清单

日期：2026-10-12
状态：所需 Android SDK 已安装，debug APK 构建与签名检查通过；真机验证按用户要求推迟。详细证据见 2026-10-12-bootstrap-verification.md。
目标：Android/iOS Flutter 项目，现阶段先在 Windows 验证 Android。

## 本机预检

- Windows AMD64；Git 命令存在：d:\Program Files\Git\cmd\git.exe。
- winget 命令存在；D 盘约 414.2 GB 可用。
- 当前 PATH 未发现 Flutter、Dart、Java、adb；用户确认尚未安装环境。
- 项目目录 D:\project\flutter_nexusft，目前仅有设计和本次新增文档。

## 安装范围与位置

1. Flutter 官方 stable x64 SDK：D:\development\flutter。SDK 内含 Dart，无需单独安装 Dart。
2. Android Studio：已发现 D:\Program Files\Android\Android Studio 现有安装，先复用；自带 JBR Java 21.0.5 已验证可运行。winget 新装请求因旧安装记录拒绝；未升级或卸载。若其版本造成实际兼容性问题，再处理升级。
3. Android SDK：D:\Android\Sdk。包括 API 36、Build-Tools、Command-line Tools、Platform-Tools、Emulator、CMake、匹配 Flutter 模板的 NDK。
4. Android 设备：真机或 API 36 x86_64 模拟器。模拟器系统镜像通过 Device Manager 下载。
5. 后续项目初始化：Flutter 默认依赖、Gradle 与模板需要的构建依赖。业务依赖另行列出版本和命令。

不重复安装已有 Git。当前不修改全局 PATH，命令使用 SDK 绝对路径。若安装器自身要求系统权限，应由用户确认系统提示。

## Flutter 下载与解压命令（已授权）

在目录已存在且非空时停止，避免覆盖已有 SDK。下载文件使用唯一临时名称；下载后核对官方 SHA256。

```powershell
$flutterInstallParent = 'D:\development'
$flutterInstallPath = Join-Path $flutterInstallParent 'flutter'
if (Test-Path -LiteralPath $flutterInstallPath) {
    throw 'Flutter target already exists; inspect before installation.'
}
$flutterReleaseMetadata = Invoke-RestMethod -Uri 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
$flutterSelectedRelease = @($flutterReleaseMetadata.releases | Where-Object {
    $_.hash -eq $flutterReleaseMetadata.current_release.stable -and
    ($null -eq $_.dart_sdk_arch -or $_.dart_sdk_arch -eq 'x64')
})
if ($flutterSelectedRelease.Count -ne 1) { throw 'Expected one stable x64 release.' }
$flutterStableRelease = $flutterSelectedRelease[0]
$flutterArchiveUri = $flutterReleaseMetadata.base_url + '/' + $flutterStableRelease.archive
$flutterDownloadDirectory = 'D:\development\downloads'
New-Item -ItemType Directory -Path $flutterDownloadDirectory -Force | Out-Null
$flutterDownloadPath = Join-Path $flutterDownloadDirectory ('flutter-sdk-' + [Guid]::NewGuid().ToString('N') + '.zip')
Write-Output ('Selected Flutter stable: ' + $flutterStableRelease.version)
Write-Output $flutterArchiveUri
Invoke-WebRequest -Uri $flutterArchiveUri -OutFile $flutterDownloadPath
$flutterDownloadedHash = (Get-FileHash -LiteralPath $flutterDownloadPath -Algorithm SHA256).Hash
if ($flutterDownloadedHash -ne $flutterStableRelease.sha256) { throw 'SDK SHA256 mismatch.' }
New-Item -ItemType Directory -Path $flutterInstallParent -Force | Out-Null
Expand-Archive -LiteralPath $flutterDownloadPath -DestinationPath $flutterInstallParent
& 'D:\development\flutter\bin\flutter.bat' --version
```

下载后的临时压缩包不自动删除；删除按用户规则另行确认。SDK 首次执行可能获取其初始化工具和缓存，包含在 Flutter 安装范围内。

## Android Studio 命令（已尝试，现复用 D 盘已有安装）

先查看当前 winget 来源提供的版本和官方安装器信息，再安装：

```powershell
winget show --id Google.AndroidStudio --exact --source winget
winget install --id Google.AndroidStudio --exact --source winget --location D:\development\android-studio
```

不传自动接受许可参数。安装后，在 SDK Manager 设置 D:\Android\Sdk，选择上述 SDK 组件并审查下载清单；在 Device Manager 配置模拟器，或连接 Android 真机。

## 配置与验收命令

```powershell
& 'D:\development\flutter\bin\flutter.bat' config --android-sdk 'D:\Android\Sdk'
& 'D:\development\flutter\bin\flutter.bat' doctor --android-licenses
& 'D:\development\flutter\bin\flutter.bat' doctor -v
& 'D:\development\flutter\bin\flutter.bat' devices
```

用户阅读并接受许可证。验收要求 Flutter 与 Android toolchain 可用，并发现至少一个 Android 设备。

## iOS 环境

需要 macOS、Flutter、Xcode、iOS SDK/模拟器，以及所选插件使用的原生依赖工具；按官方当前设置指引处理 CocoaPods。App Store 发布需要相应签名与开发者账户。
Windows 上可以开发共享 Dart 代码及生成 iOS 项目文件，但不能完成 iOS 编译和真机验收。目前未配置 Mac，不宣称 iOS 已验证。

## 官方来源

- Flutter 手动安装：https://docs.flutter.dev/install/manual
- Flutter SDK 存档：https://docs.flutter.dev/install/archive
- Android 环境：https://docs.flutter.dev/platform-integration/android/setup
- iOS 环境：https://docs.flutter.dev/platform-integration/ios/setup
- Android Studio：https://developer.android.com/studio

## 用户确认规则

用户要求环境安装双重确认：先说明安装什么及原因，再确认具体命令。用户随后回复“安装到 d盘”，确认在 D 盘执行安装。下载、SDK 与依赖缓存均使用 D 盘；不执行删除、卸载或 Git 操作。

## 本次安装证据

- 官方选择 Flutter 3.47.7 / Dart 3.13.5，SHA256：c2c875da25a1a1448d18ee4e8f398b2f6fce888b4775d8f9130538e16d826cb4。下载完成，SHA256 校验通过。
- Android command-line tools：Google 官方 commandlinetools-win-15859902_latest.zip，SHA256：90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a。下载完成，SHA256 校验通过。
- 第一次 Flutter 元数据请求使用了错误的额外 flutter/ 路径，返回 404；已修正为上述官方地址。


## 当前已验证结果

- Flutter --version：3.47.7 stable，Dart 3.13.5，退出码 0。
- Android command-line tools sdkmanager --version：22.0，退出码 0。
- Android Studio 自带 Java：21.0.5，可运行；原 D 盘安装未升级。
- Flutter 配置已指向 D:\Android\Sdk 和 D:\Program Files\Android\Android Studio\jbr。
- Flutter 官方 Android/iOS 项目已生成；默认依赖已解析至 D:\development\cache\pub。
- flutter analyze：No issues found，退出码 0。
- flutter test：官方计数器 smoke test 1/1 通过，退出码 0；不代表现货交易已实现。
- scripts/flutter.ps1 --version：成功调用 D 盘 Flutter，退出码 0；启动脚本统一 D 盘 SDK 与 Pub/Gradle/模拟器缓存。
- 安装器此前要求接受 android-sdk-license；用户随后明确确认，已接受并完成所需 SDK 安装。未自动接受所有未使用组件的许可。
- Android debug APK 已构建成功，并通过元数据和签名检查；手机运行按用户明确选择推迟。
- iOS 项目文件已生成，但 Windows 上未编译或验证。
- 为简化安装，先准备平台、编译工具和真机；模拟器与系统镜像可以在需要时安装。Flutter 3.47.7 模板的 NDK 值为 28.2.13676358，构建时按实际需要安装。
- 原官方下载速度较慢，最终从 Flutter 官方文档列出的 CFUG 镜像取得同一文件；使用原官方 SHA256 校验成功。

剩余 SDK 可在已有 Android Studio 的 SDK Manager 中安装，路径选择 D:\Android\Sdk。SDK 安装需要阅读并接受 Google Android SDK License Agreement：https://developer.android.com/studio/terms 。

