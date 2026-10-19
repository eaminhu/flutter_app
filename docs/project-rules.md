# Flutter 项目工程约束说明

更新：2026-10-13。本文件集中说明已确认的约束及其 Flutter 对应关系，不另立一套 Agent 指令。工程指令入口仍为 [AGENTS.md](../AGENTS.md) → [CLAUDE.md](../CLAUDE.md)；产品决策见 [decisions.md](decisions.md)，实现边界见 [architecture.md](architecture.md)。

## 适用范围与来源

首期 Android/iOS 手机端，现货（Spot）优先；Forui + 自定义交易组件。采用已确认的 [基础设计](designs/2026-10-12-flutter-foundation.md) 和 [网络/会话设计](designs/2026-10-13-network-session-foundation.md)。

当前 CLAUDE.md 仍保留 Web 项目的名称、路径和工具规则。以下是已确认 Flutter 设计的对应关系；不得把 Web 特有实现直接当作 Flutter 实现要求。其余通用工程、数据、文档和验证纪律继续适用。

| Web 特有表述 | Flutter 已确认对应 |
| --- | --- |
| src/core、@core、@ds | lib/core、lib/design_system |
| JavaScript BigNumber、禁用金融浮点计算 | Dart Decimal；金额、价格、数量禁止用 double 计算 |
| v1 JS-readable Cookie | 原生 flutter_secure_storage；按环境与服务器隔离，HTTP 注入 x-auth-token |
| CSS 断点、anchoredPopover 等 Web 组件 | 未迁移为 Flutter 公共规范，不直接照搬 |
| npm 脚本、Playwright Web 验证 | Flutter analyze/test、Dart 架构门禁、Android/iOS 运行验证 |
| Web adapter aliases | 当前 Flutter 仅 dev/uat/prod；不要假设支持完整 Web alias |

这些对应不是新增后端能力。v1 不支持 refresh；MFA、Google 登录、图表、实时和交易写入当前未完成。

## 当前开发边界

- 页面通过 ViewModel / repository / PlatformApi 获取数据；不直接访问 Dio、adapter 或存储插件。
- 后端路径、字段与枚举映射只在 adapter；modules 不互相导入。
- core/domain 与 core/api 保持纯 Dart；通用 UI 放 design_system，跨模块能力放 shell/core。
- 不编造价格、余额、状态或过期时间；失败不能变成空列表或默认成功。
- 退出、令牌失效及旧请求隔离由会话代次管理；旧请求不能覆盖新会话。
- 三语言 en-US / zh-CN / zh-TW；HTTP 与 UI 使用同一语言判定。后台市场 symbol 保留原始内容。
- 通用视觉使用 Forui 语义 token，具体入口见 [设计 token](design-tokens.md)。交易专用样式尚未定稿。
- 图表目标是 WebView 仅渲染，Dart 管理数据和交易；图表不得持有凭证或发起交易。

## 操作与验证

按用户当前授权约束：在当前分支工作，不自行执行 Git 命令；依赖/环境安装先明确确认；删除需双重确认，移动/重命名需确认。批准计划后执行完整范围，不反复询问是否继续。

修改前读相关实现与文档，修复限定到必要路径，同次更新受影响文档。新增业务流程遵循已确认设计；未实现内容不得写成已生效能力。

当前检查入口：

```powershell
.\scripts\check-android-requirements.ps1
.\scripts\flutter.ps1 analyze
.\scripts\flutter.ps1 test
D:\development\flutter\bin\dart.bat run tool/check_architecture.dart
```

架构门禁是词法检查，不能替代代码审查。改依赖后须重新评估原生组件；IDE Run 不自动执行安装预检。测试通过不能代表真实账号、真实交易或 iOS 已验证；交易写入需要明确授权的环境与账户。

## 文档职责

manifest 为入口；architecture 记录当前实现；decisions 记录已确认决策；status 记录当前范围；design-system / design-tokens 记录已确认视觉方向及实际 token；handoff 记录交接上下文；plans/references 保留执行与证据。不要把状态写入 AGENTS.md。

<!-- 2026-10-13 | 集中工程约束说明 | 用户要求在 docs 保存规则，明确 Web 与 Flutter 对应关系。 -->

