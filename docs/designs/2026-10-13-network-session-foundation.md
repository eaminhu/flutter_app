# 网络、会话与偏好基础设施设计

日期：2026-10-13
范围：Flutter 手机端现货第一条真实读取链路；在已批准基础框架设计上继续。
UI 决策：Forui + 自定义交易组件，专业、紧凑、Android/iOS 统一视觉。
状态：用户已确认安装与执行，本阶段实现和 Android 验证完成；真实账号/iOS/完整交易验收除外。未执行 Git 操作。

## 方案

采用 Dio 统一 HTTP、flutter_secure_storage 存储凭证、shared_preferences 存储非敏感偏好，Forui 承载通用控件。
替代方案是 Dart 原生 HttpClient（减少包但需要自行维护请求取消/拦截机制），或 package:http（简单读取方便，但本项目会话和统一传输需要更多组装）。本项目选择 Dio；不增加代码生成或第二套状态管理。

依赖预检版本：dio 5.11.1、flutter_secure_storage 11.2.0、shared_preferences 2.5.6、forui 0.27.5。Flutter 3.47.7/Dart 3.13.5 满足声明 SDK 下限；实际解析仍需安装时核验。

## 边界与配置

保留 View → ViewModel → repository → PlatformApi → v1 adapter → HTTP client。
页面不得直接导入 Dio 或存储插件。wire 路径、字段和 code/data/message 解包只存在于 v1 adapter。
配置明确区分 APP_ENV 和 API_BASE_URL，使用现有 Web 的 HTTPS 开发接口作为首条联调源；不得静默切换到生产服务器。凭证命名空间同时隔离环境和服务器地址。

本轮访问开发环境公开目录，不执行生产请求、下单、资金或账户设置写入。

## HTTP 与 API

统一连接/发送/接收超时、取消、语言 header、明确错误分类；不打印 token、用户名密码、响应正文或 query 原文。
不默认自动重试，尤其不能重复提交写请求。
v1 原始数组和业务 envelope 分开解码；HTTP 状态和业务 code 都要检查。
失败不返回空列表，不合法响应显式 RESPONSE_MALFORMED。保持 Decimal 字符串解析。

现货目录首先接入 GET /market/symbol，只迁移现有 Market 的最小列表投影，不伪造价格。
2026-10-13 开发接口真实预检：HTTP 200，18 条记录，含 symbol/coinSymbol/baseSymbol/enable。
市场 ID 和 enable 可见性沿用 Web 映射规则；成功目录在模拟器页面展示并与原始响应核对。
行情价格、盘口、K 线和实时订阅不属于此轮完成声明。

## 会话

当前 v1 使用 x-auth-token；不存在 refresh token，失效要求重新登录。
凭证通过安全存储接口封装，不能写入 shared_preferences。启动恢复、主动退出和 401/code=401 失效统一经过会话状态。
未恢复完成不当作已登出；持有 token 不等于身份已经验证。
旧请求返回的 401 不能清掉后续新会话；退出和换会话不能让旧请求结果重新写入用户状态。

账号密码登录使用现有 v1 multipart/form-data /uc/login_auth_data；身份确认使用 /uc/member/my-info。
不伪造有效期。MFA 挑战如超出已迁移能力必须明确报告，不能视为普通登录成功；本轮不宣称完整 MFA/Google 登录支持。
基础登录入口和路由守卫按实际接口能力实现；真实账号验证需要用户在 App 中输入自己的测试账号，不查找或搬运 Web 凭证。

## 偏好与 UI

使用 shared_preferences 异步接口持久化语言和主题，初始化完成后展示应用，写入失败明确记录/呈现。
凭证和普通偏好分开；本轮不保存财务数据。
Forui 先接入主题与通用设置/登录控件，业务金额与交易组件仍由 design_system 封装。
专业交易页完整布局另行实现；不使用模拟行情填充页面。

## 验证

针对请求取消/超时/HTTP 错误/envelope 错误、严格映射、凭证环境隔离、失效并发、会话恢复与偏好持久化编写回归测试。
运行架构检查、静态分析、相关测试及 Android 模拟器构建/启动。
用真实开发目录追踪：HTTP 数组 → adapter → Page → provider → 现货页面，核对条数与 symbol。
安全存储和偏好通过模拟器重启应用验证；真实登录成功不以 fixture 测试代替。
iOS、实体手机、完整交易链路和实时协议不宣称已验证。

## 执行顺序

1. 获得新增依赖安装确认并解析。
2. 实现配置、HTTP 与严格 v1 目录映射，首先打通真实只读链路。
3. 实现安全存储、会话生命周期和非敏感偏好持久化。
4. 接入基础路由/登录边界与 Forui 通用组件。
5. 完成检查、模拟器验证与状态文档。


