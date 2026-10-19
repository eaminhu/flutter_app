# 环境与官方项目初始化验证

日期：2026-10-12
范围：D 盘开发环境、官方 Flutter 项目、Android debug APK；用户明确选择只构建 APK，真机验证稍后做。
结论：Android debug APK 构建、元数据检查和签名验证通过。当前应用仍为官方初始模板，现货业务与应用分层尚未实现；未验证手机运行或 iOS。

## 已安装组件

- Flutter 3.47.7 / Dart 3.13.5：D:\development\flutter。
- Android command-line tools 22.0：D:\Android\Sdk\cmdline-tools\latest。
- Android Platform API 36 revision 2：D:\Android\Sdk\platforms\android-36。
- Android Platform-Tools 37.0.1：D:\Android\Sdk\platform-tools。
- Android Build-Tools 36.0.0：D:\Android\Sdk\build-tools\36.0.0。
- NDK 28.2.13676358（r28c）：D:\Android\Sdk\ndk\28.2.13676358。
- 复用 D:\Program Files\Android\Android Studio 和 Java 21.0.5，未升级或卸载。
- Pub 缓存 D:\development\cache\pub；Gradle 缓存 D:\development\cache\gradle。未安装模拟器。

## 命令与实际结果

- 官方 Flutter Android/iOS 项目生成与默认依赖解析：退出码 0。
- flutter analyze：No issues found，退出码 0。
- flutter test：官方计数器 smoke test 1/1 通过，退出码 0。此为前一初始化步骤证据，业务代码未变更。
- scripts/flutter.ps1 --version：Flutter 3.47.7 / Dart 3.13.5，退出码 0。
- sdkmanager：所需四项 SDK 包均显示 complete / finished，退出码 0；关键文件及 source.properties 已核对。
- scripts/flutter.ps1 doctor -v：识别 D 盘 Flutter、Android API 36 / Build-Tools 36、Java 21。仍提示部分 SDK 许可及 Windows Visual Studio 缺失；未宣称整体 doctor 全绿。
- scripts/flutter.ps1 build apk --debug：assembleDebug 236.2 秒，退出码 0，生成下方 APK。
- aapt dump badging：包名 com.example.flutter_nexusft，versionCode 1，versionName 1.0.0，minSdk 24，targetSdk / compileSdk 36，退出码 0。
- apksigner verify：退出码 0。

## 产物

路径：D:\project\flutter_nexusft\build\app\outputs\flutter-apk\app-debug.apk
大小：143.52 MiB（debug 构建）。
SHA256：04B5CFE97EBD3D0F6C2EEFDAD77880D6E891CD198404EB16AC6D16D645FECD24

默认 com.example 标识与 debug 签名仅用于开发，未发布或安装到手机。

## 安装恢复与局限

用户已明确确认 Google SDK 许可；仅接受所需 android-sdk-license，不自动接受未使用组件的全部许可。
NDK 下载遇到慢速和超时，保留下载进度并补齐同一官方包，完整文件匹配 Google 仓库 SHA1 后由标准 SDK 安装器安装。
Build-Tools 首次准备遇到损坏 ZIP；从同一官方 URL 重新下载并通过仓库校验后安装，未更换版本。
API 36 与 Platform-Tools 下载文件也核对了官方仓库校验值。
构建日志提示 SDK XML 版本差异（读取器支持到 3、遇到 4）；构建成功。保留提示，不通过无关升级或修改业务代码消除日志。
真机运行、视觉/手势、图表、真实后端以及 iOS 验证均不在本次已完成证据内。
基础框架依赖 dry-run 已通过，但 pubspec.yaml 与 pubspec.lock 未添加这些新依赖；实际增加需要用户确认。
