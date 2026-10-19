# 网络/会话与 Forui 阶段验证

日期：2026-10-13。最终正常入口 lib/main.dart。

## 最终检查

- 用户确认四项安装命令，pub add 退出码 0：Dio 5.11.1、flutter_secure_storage 11.2.0、shared_preferences 2.5.6、Forui 0.27.5。
- flutter analyze：No issues found，退出码 0。
- flutter test：39 项通过，退出码 0，日志 build/final-tests.log。
- dart run tool/check_architecture.dart：Architecture boundaries passed，退出码 0。
- check-android-requirements.ps1：当前 SDK/锁文件通过；注入不具备 SDK 目录的临时路径时正确拒绝。
- 独立只读审查无 Important/Critical 问题；捕获登录输入的非阻塞建议已修正，根层资源注册另经复核。
- 最终 flutter run -d emulator-5554 --no-resident：退出码 0，日志 build/final-fixed-run.log。
- apksigner verify 最终 APK 退出码 0。
- APK：build/app/outputs/flutter-apk/app-debug.apk，150535450 字节，2026-10-13 15:49:02。
- SHA256：979BC05DEE2389BC55BEA36480D0EA2FED55A7D266274ADE9ADE2E35F527FE04。
- x86_64 模拟器 debug 构建，非商店或实体手机通用交付包。探针 APK 已被正常 main.dart 构建覆盖。

## 实际数据与设备

开发 GET /market/symbol HTTP 200，原始 18 条；tool/live_catalog_check.dart 独立从原始 symbol/enable 计算基准，与 adapter Page.total 和全部 symbol 比对：LIVE_CATALOG_PASS raw=18 mapped=18。
实际页面已检查 CP4/USD、BTC/USDT、ETH/USDT 等服务器列表，不插入模拟行情或金融数值。
记录：build/live-catalog-final.log、build/network-spot.png、build/network-final.png。

tool/storage_probe.dart 以隔离非账号测试键验证原生安全存储和普通偏好：
WRITE_PASS 后全新进程 READ_PASS，随后同一 AVD 冷启动再 READ_PASS。测试值未用于业务账号或提交到后端；探针数据保留，未执行清理。
真实设置控件保存简体中文/深色后重启正常应用，设置实际恢复；截图 build/settings-before-restart.png、build/settings-restored.png。后续用户可自行改变偏好，不将测试选择当作产品默认值。

访客账户入口实际重定向到登录页。登录 multipart、身份确认、过期、旧401隔离由受控本地 HTTP/会话测试验证；没有自动使用真实账号或搬运 Web 凭证。

## 用户报错修复

长按 Forui 输入框出现 No MaterialLocalizations found。输入框使用新 material_ui，根旧 MaterialApp 原本只注册 FLocalizations.delegate，输入框局部资源不能覆盖 Navigator overlay。
改为根层展开 FLocalizations.localizationsDelegates，并保留旧 Flutter 委托。
test/selection_toolbar_test.dart 先复现六个失败，修复后 Android/iOS 模式 × 三语言均通过；实际 Android 长按截图 build/selection-fixed.png 显示剪切/复制/粘贴/全选菜单，无红屏。没有额外安装 UI 包。

## 构建与运行提示

插件 Gradle 自动补装 Android API 35 / CMake 3.22.1 到 D:\Android\Sdk。事前清单遗漏这两项；jni_flutter 的 compileSdk=35 已核实，CMake 版本来自构建日志。增加锁文件关联的脚本门禁，今后依赖变化先审查原生需求，缺组件不让包装脚本继续构建。IDE 直接 Run 不经过此脚本。
一次存储探针运行出现 DDS 连接失败；当时后续检查模拟器已关闭。实际 READ_PASS 已记录，重启模拟器后再次 READ_PASS，正常入口最终启动退出码 0。
冷启动有 System UI 无响应提示，选择等待后恢复；未改应用业务代码掩盖该系统提示。调试启动有 skipped frames/x86/SELinux 等日志，不宣称性能或环境无警告。
iOS 平台变体测试不是 iOS 原生构建/键盘/Keychain 验收。实体手机、真实账号与交易、图表/实时链路均未验收。

