# 基础框架实现计划

日期：2026-10-13
负责人：当前 Codex 会话
状态：本阶段已完成；证据见 ../references/2026-10-13-foundation-verification.md
范围：已确认设计的“基础框架”阶段。真实后端、登录、交易写入、完整 mock 交易、图表渲染与真机验收不属于本阶段完成声明。

用户已明确确认五项依赖安装；不执行 Git 操作，不删除或移动文件。

## 交付结构

- lib/app：NexusApp、启动组装、GoRouter、本地化 delegate。
- lib/core/config：严格解析 APP_ENV=dev/uat/prod，非法值显式失败。
- lib/core/api：PlatformApi.catalog.markets、统一 PlatformError。
- lib/core/domain：只迁移列表所需 Market / MarketQuery / Page 字段；金额使用 Decimal，必填值缺失或不合法显式失败。
- lib/core/adapters/unconfigured：未接入后端时显式抛出 BACKEND_NOT_CONFIGURED，不提供默认市场、价格或余额。
- lib/core/providers：平台接口依赖组装、全局偏好、失败日志。
- lib/design_system：公共主题和加载/空/失败状态组件。
- lib/shell：导航框架和设置页面。
- lib/modules/spot：现货市场列表的 View + ViewModel；真实数据入口尚未配置。
- tool/check_architecture.dart：机械检查领域纯 Dart、模块隔离与后端访问边界。
- test：导航、语言/主题、数据读取失败与空结果区别、金额精度、配置和边界规则。

## 执行与验收

- [x] 安装已批准依赖：flutter_riverpod 3.4.3、go_router 18.0.2、webview_flutter 4.14.1、decimal 3.2.6、flutter_localizations。
- [x] 先运行期望导航/现货入口的测试，确认官方计数器模板不满足行为。
- [x] 实现应用启动、导航、三语言与主题设置；偏好只保存于当前 App 会话，不声称持久化。
- [x] 实现最小目录接口、未配置 adapter、列表 ViewModel 与显式状态；失败日志仅记录 provider / error code，不记录凭证或后端原始响应。
- [x] 验证空结果只在成功响应时呈现；请求失败不能返回空列表；精确追踪 0.1 + 0.2 = 0.3，以及长小数不丢位。
- [x] 落实架构文档与机械检查，覆盖相对路径绕过边界的反例。
- [x] 运行架构检查、flutter analyze、flutter test、Android debug APK 构建和签名检查。
- [x] 更新双语 README、文档导航和 status；明确图表依赖已安装但图表未实现、真实数据与手机/iOS 未验证。

环境命令继续使用 scripts/flutter.ps1；项目仍使用默认开发 applicationId，不发布商店。

本阶段完成条件：上述框架行为和自动化验收通过；Android APK 能构建。用户已明确推迟真机验证，不将 widget 测试冒充手机端视觉/手势验证。


