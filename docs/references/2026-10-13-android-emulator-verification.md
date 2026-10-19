# Android Studio 与模拟器运行验证

日期：2026-10-13
状态：Studio 项目已打开；插件、模拟器与系统镜像配置完成，应用在模拟器中运行验证通过。

用户已明确批准 Android Emulator、API 36 Google APIs x86_64 镜像、D 盘 AVD 和 Flutter/Dart 插件安装。

## 环境与证据

- Studio 窗口：flutter_nexusft – main.dart；日志确认 Flutter device daemon 和 Dart SDK 3.13.5。
- Flutter 插件 88.1.0 / Dart 插件 243.27824.5，依据 Marketplace 兼容范围选择，安装在 D:\development\android-studio\plugins。
- Android Emulator 37.2.12.0，D:\Android\Sdk\emulator；官方 SHA1 488ed747e82de7e9bb5247becd1ac043c7e5e85d 核验通过。
- Google APIs x86_64 API 36 revision 7，D:\Android\Sdk\system-images\android-36\google_apis\x86_64；官方 SHA1 c6bf44bdcd885bb902b4ba752d111a073ad7a817 核验通过。
- SDK Manager 识别上述安装。安装登记依据同一官方元数据生成，没有替换包内容。
- WHPX(10.0.26200) is installed and usable，退出码 0；实际启动日志确认加速器运行。
- AVD NexusFT_API_36，路径 D:\Android\avd\NexusFT_API_36.avd；内置 Pixel 7 配置，x86_64、1080x2400、2G RAM。
- sys.boot_completed=1，ADB emulator-5554 为 device 状态，API 36。
- scripts/flutter.ps1 run -d emulator-5554 --no-resident：退出码 0，构建、安装、启动成功。
- topResumedActivity 为 com.example.flutter_nexusft/.MainActivity。
- 实际截图检查现货页和设置页，已返回现货页；显示“交易服务尚未连接”，与未配置 adapter 一致。
- 截图：build/emulator-spot.png、build/emulator-settings.png、build/emulator-spot-final.png。
- APK：build/app/outputs/flutter-apk/app-debug.apk，150493369 字节，2026-10-13 12:09:07。
- APK SHA256：5805224CC41BEDD0BE699E01F7522CFF0F94AE6314D125C23D93E2A950FCCC45；apksigner verify 退出码 0。

本轮模拟器构建覆盖同路径 APK；基础框架验证文档保留此前构建的历史哈希。运行日志位于 build/emulator-flutter-run.log。

## 恢复与提示

原设置向导运行期间重复启动，第二实例出现 DirectoryLock bind 错误。结束失败实例、由用户退出旧向导后，单实例重新打开成功；未重置设置或插件。

SDK Manager 卡在 SSL 数据读取。改用 Google 官方分发节点分段续传，合并后核验官方 SHA1；未通过校验不安装。安装包与分段保留在 D:\development\downloads\android-emulator-cdn，未执行删除。

avdmanager 提示镜像缺少 devices.xml；官方镜像哈希有效，内置 pixel_7 配置生成成功，实际开机和应用启动验证通过。未制造该文件或静默修改镜像。启动还有 x86 CPU variant、SELinux/hidden API 提示，不将提示等同于应用崩溃。

## 下次运行与边界

从项目目录执行 scripts/android-studio.ps1。Studio 顶部选择运行中的 NexusFT_API_36 / sdk gphone64 x86 64 和 main.dart，点击 Run；Device Manager 也可启动该 AVD。
启动脚本设置 D 盘 SDK、缓存、AVD，不修改全局 PATH；已有 Studio 实例时显式拒绝重复启动。脚本语法检查与实际启动均通过。

本次仅验证安装、启动、现货/设置页面导航，不声称全部语言/主题、图表或真实后端交易链路验收通过。实体手机和 iOS 未验证。未执行 Git 操作。

## 来源

- [Flutter 插件](https://plugins.jetbrains.com/plugin/9212-flutter/versions/stable/892899)
- [Dart 插件](https://plugins.jetbrains.com/plugin/6351-dart)
- [插件目录配置](https://www.jetbrains.com/help/idea/directories-used-by-the-ide-to-store-settings-caches-plugins-and-logs.html)
- [Google SDK 元数据](https://dl.google.com/android/repository/repository2-3.xml)
- [Google 系统镜像元数据](https://dl.google.com/android/repository/sys-img/google_apis/sys-img2-4.xml)

