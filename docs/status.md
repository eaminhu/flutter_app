# 当前状态

更新：2026-10-15

- 项目 D:\project\flutter_nexusft；Android/iOS 手机端、现货优先。
- **2026-10-15 UI 全面重构完成（浅色优先，币安/欧易/Polymarket 基准）**：新增 App token 层（app_spacing/app_typography/app_radius/app_shadows + trading_tokens 扩展 border）与 primitives（AppCard/AppIconButton/AppListRow/PageStatus）；逐页重构现货交易页（盘口深度条、24h 统计行、订单区 Expanded 布局、tab 动画）、预测列表/卡片/详情（骨架屏、AppCard、概率条卡片化）、资产页、登录/注册、我的/设置/占位页/底部导航；Material 直接用法清零；AppShell 统一 SafeArea。112 测试全过，analyze 无问题，架构门禁通过；浅/深双主题截图矩阵验收（build/p8-*.png）。已登录态我的页/资产页随模拟器留存的会话一并截图确认。
- UI 已确认 Forui + 自定义交易组件。现货首页 demo（OKX 布局 + Binance 深色配色）：顶部栏、交易 tab、交易对选择、下单表单、盘口、图表入口条，以及底部订单/仓位区（当前委托/历史委托/仓位三 tab）。盘口、订单、仓位、资产均为本地确定性 demo 数据并明确标注“演示数据”（demo_order_book.dart / demo_orders.dart / demo_assets.dart），不进 API；表单/报价/余额仍为 `--` 占位，行情与交易写入未接入。
- 登录页完善：密码可见性、忘记密码占位、注册入口、Google 占位（toast）。注册页 /register 已实现真实 v1 链路（国家列表、邮箱验证码 60s 倒计时、校验 checklist、双协议、注册成功自动登录），失败展示后端 message。
- 资产页 /assets 已实现（总资产卡、快捷操作占位、币种列表、账户区），demo 数据标注；无守卫。底部导航资产项指向 /assets；/account 与守卫保留。
- 底部导航四项（首页/交易/资产/我的，探索/星球已移除）；shell 不再含 FHeader，SpotTopBar 为交易页唯一顶栏（含设置齿轮）；/account 为“我的”页（无守卫，访客 CTA）；首页走 /placeholder 占位页。
- 已实现 Dio HTTP、v1 目录/认证/注册 adapter、会话恢复/身份确认/失效/退出、登录路由守卫、原生凭证和偏好存储。
- 默认 dev 已连接真实开发公开目录，18 条响应映射为 18 个交易对；不展示未接入的价格。
- 预测市场列表已实现（真实 /swap/pm/home + pmMenu 分类，分页、三态、LIVE/UPCOMING 判定；无 demo 数据）；详情页（/prediction/:eventId 全屏、auction 实时概率订阅、结算规则展示）与列表搜索（非 CJK 服务端、CJK 本地、300ms 防抖）已实现；SockJS+STOMP 客户端为 dart:io 自实现（无新依赖），协议经 tool/ws_probe.dart 实测 dev 握手通过。交易页顶部 tab 为现货/合约/CFD/预测四模式（方案 B），合约/CFD 占位；底部导航四项（首页/交易/资产/我的）。预测卡片按 Polymarket 风参考图版式（match 1X2 胶囊 / leaderboard 前 4 行 + 是否小胶囊 / binary 是否大胶囊，大号百分比价格，未定价 `—`，底部交易量紧凑格式·分类·时间+书签占位）。
- 112 项测试通过，静态分析无问题，架构与原生依赖预检通过；独立审查和本地化修复复核通过。
- 2026-10-15 模拟器核对已补齐：四项导航逐项跳转、合并顶栏、我的页访客态、预测 match/leaderboard/binary 三种卡片版式、详情页全部通过（build/p3-*.png，见 references/2026-10-15-p3-emulator-verification.md）。仍待核对：我的页已登录态（随真实账号验收）、实时概率真机更新（LIVE 详情页停留 2 分钟无 auction 推送，dev 数据静默）。总体任务计划见 plans/2026-10-15-master-roadmap.md。
- Android 模拟器真实目录、访客登录入口、文字长按选择菜单、偏好重启恢复均已检查；原生存储隔离测试通过 App/AVD 重启。
- 用户报告的 No MaterialLocalizations found 已修复；三语言 × Android/iOS 模式回归覆盖菜单交互。
- 最终正常 main.dart debug APK 已构建、签名核验通过；150535450 字节。当前产物为 x86_64 模拟器构建，实体手机需按目标架构重新构建。
- v1 无 refresh；MFA/Google 真实登录尚未实现（Google 按钮为占位）。真实账号鉴权闭环未验收，需用户在 App 输入测试账号；注册真实链路未用测试账号验证。
- 价格/行情 REST 快照、K 线、下单/撤单、真实订单/仓位/资产 API、充提划转、忘记密码未实现；实时仅预测 auction 概率通道（详情页），其余行情订阅未接。
- Flutter/SDK/缓存位于 D 盘；AVD 已换为 C:\Users\86186\.android\avd\Medium_Phone_API_36（config.ini 改指 google_apis 镜像，备份 .bak）。本轮插件构建自动补装 API 35 与 CMake 3.22.1，已记录并增加后续脚本预检。
- iOS Keychain 配置已准备，iOS 和实体手机未验证；环境诊断未宣称全绿。
- 本轮未执行 Git 操作，未访问生产或执行交易写入。

交接：[handoff.md](handoff.md)。验证：[网络/会话阶段](references/2026-10-13-network-session-verification.md)。

