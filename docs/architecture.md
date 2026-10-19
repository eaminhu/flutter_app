# Flutter 客户端架构

更新：2026-10-14。网络/会话基础设施、现货首页 demo、注册、订单/仓位与资产 demo、预测市场列表（真实 API）已交付；真实行情与交易写入尚未实现。

## 依赖与运行

View → ViewModel → repository → PlatformApi → V1Adapter → DioHttp → HTTPS。
页面不得直接导入 adapter、HTTP 或存储插件；app 负责启动组装，shell 负责导航、认证和设置。
main.dart 使用原生存储并注入真实配置；直接构造 NexusApp 的隔离 widget 测试默认使用未配置 API / 内存存储，不代表真实启动入口。

- app：GoRouter、本地化、Forui 主题启动，根层含 FToaster（页面提示统一用 showFToast；FScaffold 下没有 Material Scaffold，不能用 SnackBar）；WidgetsBindingObserver 在 App 回前台时 realtime.revalidate() 并使打开的详情页 REST 重拉对齐。
- core/realtime：最小 SockJS（仅 websocket transport）+ STOMP 1.2 客户端（dart:io），/swap_market/ws；帧编解码纯函数；15s 心跳、5s 重连、连续失败 6 次封顶、revalidate；探针 tool/ws_probe.dart 实测 dev 通过。
- core/api / domain：目录/认证/注册/预测契约、统一错误、不可变 Page、Decimal；Country/RegisterInput、注册校验纯函数（register_rules.dart）、EventCard/CardQuery/TradeStatus（event_card.dart）。
- core/adapters/v1：所有 wire 路径、code/data/message 与字段映射；非 0 code 抛 serverError 并保留后端 message；发码/注册的空 data 视为成功；/swap/pm/home 单行解码失败跳过（整页全失败才报错）；application_config 401/403 时分类降级为空。
- core/http：Dio 超时、取消、语言和 x-auth-token；禁止跨 origin 请求与跟随重定向；不默认重试或记录正文/凭证。
- core/session：恢复、身份确认、退出、401 失效；generation 和顺序写队列隔离旧请求/旧登录。
- core/storage：凭证用 flutter_secure_storage；普通偏好用 SharedPreferencesAsync，JSON 严格解码。
- modules/spot：真实目录读取 + 现货交易主体（widgets/ 下顶部栏、交易对 header、下单表单、盘口面板、图表入口条、订单/仓位区）；demo_order_book/demo_orders 为确定性本地生成并标注“演示数据”，不进 API；selectedMarketId 选择状态默认目录第一条；账号/会话变化作废旧读取。
- modules/prediction：预测市场列表（真实 /swap/pm/home + application_config pmMenu 分类，无 demo 数据）与详情页（/swap/pm/detail/{id}，全屏路由 /prediction/:eventId，前 12 个领先 outcome 订阅 /topic/pm/auction 实时概率，ask 优先退化价差跳过）；搜索非 CJK 走服务端 search、CJK 本地过滤；分类 chips、滚动分页、三态；状态 pill 由 TradeStatus + 交易窗口判定 LIVE/UPCOMING。
- modules/assets：资产页 demo（总资产卡、快捷操作占位、币种列表、账户区），demo_assets 固定确定性数值并标注“演示数据”。
- shell：/spot、/settings、/login、/register、/account、/assets、/placeholder + shell 外全屏 /prediction/:eventId；shell/trade 的 TradeHomeScreen 是 /spot 宿主：SpotTopBar（唯一顶栏，含设置齿轮）+ 受控 InstrumentTabs（现货/合约/CFD/预测，合约/CFD 为占位主体）+ 按 tradeTabProvider 切换主体；AppShell 无 FHeader；底部导航首页/交易/资产/我的(/account)四项；未上线首页走 /placeholder；/account 无守卫（访客 CTA），/login、/register 已登录守卫跳 /account；资产/我的/设置页各自带简洁页头。
- design_system：Forui 通用主题/控件、PageStatus，以及 trading/ 交易通用组件（price_text、change_text、trade_side_switch、percent_selector、order_book_entry/list、buy_sell_ratio_bar）与 tokens/trading_tokens.dart 交易色板。

默认 main.dart 的 APP_ENV=dev，指向 https://dev-nexusft-trade-api.nexuspb.com。
其他环境不静默复用 dev；API_BASE_URL 需显式传入。Flutter 当前只支持 dev/uat/prod，未完整迁移 Web 的开放 alias 机制。
开发目录 GET /market/symbol 原始数组 → Market，symbol 保留原值；ID 沿用 Web 的下划线后缀移除及斜杠变连字符。enable=0 排除，enable=2 仍列表展示。
Market 当前只有 marketId/symbol/instrumentType；不提供未接入的价格、余额和交易状态。

## 会话

v1 登录为 multipart/form-data POST /uc/login_auth_data；身份为 POST /uc/member/my-info。
注册链路：国家 POST /uc/support/country?isReg=1；发码 GET /uc/verify/email/register；注册 POST /uc/register/email（form-urlencoded，空 data 即成功），成功后沿用 login+me 自动登录。
先确认身份再持久化会话；没有 expiresAt 就保留 null。
v1 不支持 refresh，HTTP/业务 code=401 作废会话，要求重新登录；MFA 挑战未迁移时明确拒绝。
旧请求的 401 不能清除新会话；恢复失败会退休暂存凭证的请求代次。退出清除当前环境/服务器凭证和身份，目录读取随会话代次重新计算。
真实账号登录/恢复/登出仍需测试账号验收；当前协议与并发验证来自受控 HTTP 测试，不能冒充真实账号闭环。

## UI 与存储

Forui + 自定义交易组件是已确认方向，风格专业、紧凑、两平台统一。
当前已接入 Forui header/navigation/buttons/inputs；MaterialApp 仅保留路由与原有基础框架宿主。两套 Material 类型不能直接混用 ThemeData，主题分别组装。
根层必须注册 AppLocalizations、FLocalizations.localizationsDelegates 和现有 Flutter 的委托；Forui 的新 material_ui / cupertino_ui 本地化类型与 Flutter 旧类型不同。输入框子树补资源不能覆盖根 Navigator overlay 的文字选择菜单。
三语言为 en-US/zh-CN/zh-TW；系统 Hans/Hant 判定由纯 Dart languageForTags 共享，HTTP 和 UI 一致。
偏好初始化完成后显示应用，写入成功后更新状态；失败明确显示，不静默回退为成功。Android 原生凭证和偏好均完成跨进程验证。
Android 主 manifest 开启 Internet 并关闭备份；iOS Keychain entitlements 已配置，但 iOS 未构建验证。

## 门禁与边界

tool/check_architecture.dart 覆盖 package/相对路径/条件 import-export、模块隔离、纯 core 与 UI 直接访问 HTTP/存储。它是词法门禁，不是完整 Dart AST 分析器。
scripts/check-android-requirements.ps1 在 run/build apk 前检查当前锁文件与 SDK 清单；缺组件或依赖变化提前失败，不安装。IDE 直接 Run 不执行该脚本，改依赖后仍须先手动检查原生要求。
最终 111 项测试、analyze、架构检查和 Android 模拟器运行通过；真实目录 18 条与响应比对通过。
原生存储探针用独立非账号测试键；不作为真实登录成功证据。图表、实时 STOMP/SockJS、交易写入、MFA/Google 真实登录、忘记密码、真实订单/仓位/资产 API 未实现（订单/仓位/资产为标注的本地 demo 数据）；实体手机和 iOS 未验收。

