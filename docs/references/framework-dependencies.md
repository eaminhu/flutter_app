# 基础框架依赖安装清单

日期：2026-10-12
状态：2026-10-13 用户明确确认后安装成功；pubspec.yaml / pubspec.lock 已记录五项直接依赖。
运行环境：Flutter 3.47.7 / Dart 3.13.5。

## 直接依赖

- flutter_riverpod 3.4.3：统一页面状态、依赖组装和生命周期管理。
- go_router 18.0.2：统一导航和会话路由守卫。
- webview_flutter 4.14.1：承载本地 Lightweight Charts 图表页面。
- decimal 3.2.6：金额、价格和数量的精确十进制计算。
- flutter_localizations：随已安装 Flutter SDK 提供，支持框架控件本地化。

不额外引入代码生成、HTTP 客户端或多套状态管理框架；这些不属于本次基础依赖清单。Lightweight Charts 的 JS 资源与署名作为图表实现任务单独记录，不在本命令内获取。

## 预检证据

通过 pub.dev 官方包元数据核实版本和 SDK 要求：

- flutter_riverpod：Dart ^3.12.0，Flutter >=3.0.0。
- go_router：Dart ^3.12.0，Flutter >=3.44.0。
- webview_flutter：Dart ^3.10.0，Flutter >=3.38.0。
- decimal：Dart >=3.3.0 <4.0.0。

执行以下 dry-run，退出码 0，解析出 22 项依赖变更，包括传递依赖。前后 SHA256 核对 pubspec.yaml 与 pubspec.lock 不变；Pub 缓存可能已下载依赖包，不代表项目已声明或采用它们。

```powershell
.\scripts\flutter.ps1 pub add --dry-run 'flutter_riverpod@3.4.3' 'go_router@18.0.2' 'webview_flutter@4.14.1' 'decimal@3.2.6' 'flutter_localizations@{sdk: flutter}'
```

## 实际安装命令（已批准并执行成功）

工作目录：D:\project\flutter_nexusft。

```powershell
.\scripts\flutter.ps1 pub add 'flutter_riverpod@3.4.3' 'go_router@18.0.2' 'webview_flutter@4.14.1' 'decimal@3.2.6' 'flutter_localizations@{sdk: flutter}'
```

此命令退出码 0，修改 pubspec.yaml、pubspec.lock，并解析直接与传递依赖。直接依赖版本固定，缓存使用 D:\development\cache\pub。后续新增或修改包仍遵循用户确认规则。

## 官方来源

- https://pub.dev/packages/flutter_riverpod
- https://pub.dev/packages/go_router
- https://pub.dev/packages/webview_flutter
- https://pub.dev/packages/decimal
- 官方元数据接口：https://pub.dev/api/packages/<package-name>

