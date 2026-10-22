# 文档总览

[English](manifest.md) | **简体中文**

优先阅读当前文档；带日期的计划和验证保留阶段证据。

- [项目约束](project-rules.md)：既有工程约束与 Web↔Flutter 对应关系；Agent 指令仍在 AGENTS.md / CLAUDE.md。
- [Invariants](invariants.md)：必须始终成立的规则，逐条标注来源。
- [术语表](glossary.md)：领域术语与面向用户词汇。
- [移动端设计](design-system.md)：已确认视觉方向、当前组件与待设计范围。
- [设计 token](design-tokens.md)：实际 Forui 0.27.5 颜色、字体、圆角与局部间距；交易 token 尚未定义。
- [架构](architecture.md)：当前依赖与实现边界。
- [决策](decisions.md)：已确认范围与授权，注明历史阶段。
- [当前状态](status.md)：已实现行为和剩余范围。
- [交接文档](handoff.md)：环境、验证证据与下一阶段上下文。

## 设计与执行证据

- [已确认基础设计](designs/2026-10-12-flutter-foundation.md)：整体移动端现货目标。
- [网络/会话设计](designs/2026-10-13-network-session-foundation.md)、[计划](plans/2026-10-13-network-session-foundation.md)与[验证](references/2026-10-13-network-session-verification.md)：本阶段实现和 Android 证据；真实账号登录仍未验收。
- [基础框架计划](plans/2026-10-13-foundation-framework.md)与[验证](references/2026-10-13-foundation-verification.md)：早期框架阶段记录。
- [框架依赖](references/framework-dependencies.md)：初始已批准依赖；后续版本见交接与网络/会话验证。
- [环境计划](plans/2026-10-12-environment-and-bootstrap.md)、[安装证据](references/windows-install-checklist.md)、[初始化验证](references/2026-10-12-bootstrap-verification.md)和[Android Studio/模拟器验证](references/2026-10-13-android-emulator-verification.md)。

当前文档区分已确认方向、已实现行为和已验证证据。规划能力不作为生效约束。修改代码时同步受影响文档，一个概念保持一个维护来源。文档检查和自动化测试不能证明真实账号交易或 iOS 已验收。

<!-- 2026-10-13 | 文档盘点 | 补齐约束、设计/token 快照，修复交接导航。 -->
<!-- 2026-10-20 | 规则集对齐 | CLAUDE.md 重写为 Flutter 原生；新增 invariants.md 与 glossary.md 权威文档。 -->

