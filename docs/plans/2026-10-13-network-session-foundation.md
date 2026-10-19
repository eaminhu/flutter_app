# 网络与会话基础设施实现计划

目标：真实开发市场目录、HTTP、凭证/偏好存储和基础登录路由可运行。
架构：保留 PlatformApi 边界，Dio 只在 core；会话统一拥有凭证和请求代次，Forui 负责通用控件。
技术栈：已批准并安装 Dio 5.11.1、secure_storage 11.2.0、shared_preferences 2.5.6、Forui 0.27.5。
按 executing-plans 顺序执行；用户禁止自主 Git 操作，不创建 worktree，不提交。

- [x] 安装四项依赖并检查退出码。
- [x] test/core/network_session_test.dart：配置安全、严格市场映射、真实 HTTP 状态/取消、凭据与并发反例；先确认失败。
- [x] core/config/app_config.dart、core/http/dio_http.dart、core/adapters/v1/v1_adapter.dart：配置、超时、取消、语言、x-auth-token、JSON/envelope 解码、市场 ID。
- [x] core/domain/session.dart、core/session/session_manager.dart：恢复、身份确认、代次隔离、串行凭证写入；过期不自动刷新。
- [x] core/storage/session_store.dart、preferences_store.dart 与平台实现：安全凭证和非敏感偏好分开；失败显式呈现。
- [x] core/providers 与 main.dart：原生启动组装、恢复监听、偏好持久化。
- [x] app/router.dart、shell/auth/login_screen.dart、account_screen.dart：登录入口、身份页守卫、退出与恢复错误。
- [x] app/nexus_app.dart、design_system、settings/spot：Forui 主题、按钮和通用输入；不展示虚构行情。
- [x] 验证架构、analyze、全部 tests，独立只读审查并修正范围内问题。
- [x] 模拟器实际目录与 18 条公开响应比对；重启偏好/原生安全存储验证；不使用真实账户凭证自动登录。
- [x] 更新架构、决策、状态、双语导航及验证记录。

真实账号登录需要用户在 App 中输入测试账号；fixture 登录测试仅验证客户端协议，不能声称真实账号登录已联调。


阶段完成。真实账号登录未验收；证据见 ../references/2026-10-13-network-session-verification.md。另完成六种文字选择菜单回归、实际修复与 handoff.md。
