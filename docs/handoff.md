# NexusFT Flutter 交接

更新：2026-10-14。阶段：交易首页 demo、认证（登录/注册）、预测市场（列表/详情/实时概率）、导航精简。
本文件记录会话状态与授权，不替代工程规则；工程规则以 AGENTS.md → CLAUDE.md 与 docs/project-rules.md 为准。

## 项目与已确认方向

- Flutter 项目：D:\project\flutter_nexusft。Web 参考：D:\project\dex-v2_fe（只读）。
- 首期 Android/iOS 手机端；UI 为 Forui + 自定义交易组件，专业紧凑方向。
- 四种交易模式的导航已定（方案 B）：交易页顶部 tab = 现货/合约/CFD/预测；底部导航四项 = 首页/交易/资产/我的（探索/星球已移除）。现货/合约/CFD 同范式共用交易屏，预测为卡片列表→详情范式。
- 数据纪律：真实目录/预测列表用真实 API；盘口、订单、仓位、资产为本地确定性 demo 数据且 UI 明确标注“演示数据”；表单/报价/余额为 `--` 占位；未定价显示 `—`，不显示 0，不用 0 填充。

## 已交付（按阶段）

1. 网络/会话/Forui 基础（2026-10-13）：Dio、v1 目录与登录 adapter、SessionManager（代次隔离）、原生凭证/偏好、三语言、路由守卫。详见 references/2026-10-13-network-session-verification.md。
2. 现货交易首页 demo：OKX 布局 + Binance 深色 token（trading_tokens.dart）；design_system/trading 六个通用组件；顶部栏、下单表单、盘口（demo 标注）、图表入口条、订单/仓位区（demo 标注）。
3. 认证：登录页完善（密码可见性、忘记密码占位、Google 占位）；注册页 /register 真实 v1 链路（国家列表、邮箱验证码 60s 倒计时、密码强度 checklist、双协议、成功自动登录），失败展示后端 message。
4. 资产页 /assets（总资产卡、快捷操作占位、币种列表、账户区，demo 标注）。
5. 预测市场：列表（真实 GET /swap/pm/home + pmMenu 分类、滚动分页、搜索：非 CJK 服务端 / CJK 本地过滤、三态）；详情页 /prediction/:eventId（ShellRoute 外全屏，结算规则展示）；实时概率（core/realtime/stomp_client.dart 自实现 SockJS+STOMP 最小子集，无新依赖；协议经 tool/ws_probe.dart 实测 dev 握手通过）。
6. 预测卡片版式：按用户提供的 Polymarket 风参考图——大号百分比价格（未定价 `—`）、match 主/DRAW/客三胶囊、binary 是/否大胶囊（按选项着色）、leaderboard 行尾是/否小胶囊、底部交易量紧凑格式（formatCompactVolume，K/M/B）·分类·时间+书签占位。
7. “我的”页：/account 改造（无守卫，访客登录/注册 CTA；已登录显示账户 ID、设置/语言主题入口、退出）。AppShell 已移除 FHeader，SpotTopBar 为交易页唯一顶栏（含设置齿轮）。
8. UI 全面重构（2026-10-15，浅色优先，币安/欧易/Polymarket 基准）：App token 层（app_spacing/app_typography/app_radius/app_shadows + TradingColors 新增 border）与 primitives（AppCard/AppIconButton/AppListRow/PageStatus 升级）；现货交易页（盘口深度条、24h 统计行、订单区 Expanded、tab 指示条动画）、预测列表/卡片/详情（骨架屏、AppCard、outcome 概率条卡片化、结算规则卡）、资产页（三等分快捷操作、_AssetRow）、登录/注册（token 化、checklist 两列）、我的/设置（AppListRow 单选列表）、底部导航（caption 标签 + 选中 w600）。Material IconButton/ListTile/Card/CircleAvatar 直接用法清零；AppShell 统一 SafeArea(bottom:false)；OrderTicket 区域可滚动（修 SafeArea 后高度收窄的裁切）。

## 关键文件

| 入口 | 责任 |
|---|---|
| lib/main.dart | 原生存储、配置、ProviderContainer 组装与恢复 |
| lib/shell/trade/trade_home_screen.dart | 交易页宿主：SpotTopBar + 四 tab（现货/合约/CFD/预测）切换主体；tab 状态 tradeTabProvider |
| lib/modules/spot/ | 现货交易主体（盘口/订单 demo 数据 demo_order_book.dart、demo_orders.dart） |
| lib/modules/prediction/ | 预测列表 + detail/ 详情页 + 实时概率订阅合并 |
| lib/modules/assets/ | 资产页（demo_assets.dart） |
| lib/core/realtime/stomp_client.dart | SockJS+STOMP 客户端（懒连接、15s 心跳、5s 重连×6 封顶、revalidate） |
| lib/core/api/stream.dart | RealtimeApi/AuctionTick 契约；UI 只经 platformApiProvider.realtime 访问 |
| lib/core/adapters/v1/v1_adapter.dart | 目录/认证/注册/预测列表与详情/实时解码 |
| lib/design_system/tokens/trading_tokens.dart | 交易 token（涨买绿 #2EBD85、跌卖红 #F6465D、面板底 #0B0E11 系，明/暗两套） |
| lib/design_system/trading/ | 可复用交易组件（含 compact_volume.dart；event_price.dart 美分格式已废弃删除） |
| tool/ws_probe.dart | WS 协议探针（dart run tool/ws_probe.dart） |
| tool/check_architecture.dart | 依赖边界门禁 |

## 环境和运行

Flutter 3.47.7 / Dart 3.13.5：D:\development\flutter。Android SDK：D:\Android\Sdk；JBR：D:\Program Files\Android\Android Studio\jbr。AVD：Medium_Phone_API_36（API 36 / x86_64，2026-10-15 起；config.ini 已改指 google_apis 镜像，备份 config.ini.bak，详见 references/2026-10-15-p3-emulator-verification.md）。

```powershell
cd D:\project\flutter_nexusft
pwsh -NoProfile -File .\scripts\check-android-requirements.ps1
pwsh -NoProfile -File .\scripts\flutter.ps1 run -d emulator-5554
```

**注意：必须用 pwsh（PowerShell 7）跑脚本**。系统自带 Windows PowerShell 5.1 缺 Microsoft.PowerShell.Utility（无 Get-FileHash），预检脚本在 5.1 下必失败；这是本机环境缺陷，不是脚本问题。IDE 直接 Run 不经包装脚本，改依赖后须先手动预检。

默认 dev API：https://dev-nexusft-trade-api.nexuspb.com。APP_ENV 只支持 dev/uat/prod。

## 验证证据（2026-10-15 现状）

- `dart run tool/check_architecture.dart` → 通过；`flutter.ps1 analyze` → 无问题；`flutter.ps1 test` → **112 项全部通过**；`check-android-requirements.ps1` → 通过。
- UI 重构双主题截图矩阵（2026-10-15，build/p8-*.png）：浅色=现货/预测列表/详情/资产/我的（已登录态）/设置/Home 占位；深色=现货/预测列表/详情/资产/我的。安全区与下单表单滚动回归已修复并复拍。
- 模拟器实测已过：现货首页（双栏/盘口 demo/订单区）、登录、注册、资产页、预测列表。2026-10-14 重新构建并覆盖安装 APK 后，截图确认底部四项导航、交易页“预测”tab 与预测列表的 match 卡片已显示（build/nexusft-after-update.png）；旧版截图在 build/ 目录（v2-*.png、v3-*.png）。
- **模拟器核对已补齐（2026-10-15）**：四项底部导航逐项跳转、合并顶栏、我的页访客态、预测 match/leaderboard/binary 三种卡片版式、详情页全部截图通过（build/p3-*.png，记录见 references/2026-10-15-p3-emulator-verification.md）。**我的页已登录态**：模拟器留存的会话（账户 763291068673425408）在 p8-L6/D5 截图中确认了身份卡/菜单/退出渲染；真实账号主动登录验收仍待用户。**实时概率真机更新**仍待有行情的事件（dev 数据静默）。
- WS 协议探针实测：SockJS websocket 直连成功无需 Origin 头；服务端心跳为 `a["\n"]`（非 `h` 帧）；观测窗口内 dev 无 auction 推送（数据静默非协议问题）。实时概率的真机更新表现未验证。

## 未完成和下一步

总体任务计划见 plans/2026-10-15-master-roadmap.md（P0–P9 阶段划分与完成标准），当前处于 P3 收尾验证。

1. ~~补模拟器截图核对~~ 已完成（2026-10-15）：四项导航逐项跳转、合并顶栏、我的页访客态、预测三种卡片版式、详情页均通过，证据 references/2026-10-15-p3-emulator-verification.md；实时概率在 LIVE 详情页停留 2 分钟无推送（dev 数据静默），仍待有行情的事件核对。
2. 真实账号验收：登录/注册/恢复/失效/退出需用户在 App 输入测试账号；注册真实链路未走通验证。不从 Web Cookie 或本机文件找凭证。我的页已登录态随此项核对。
3. match 卡片 1X2 的主/客顺序依赖 venue previewItems 排列，dev 有真实对阵数据时需校准。
4. 预测：下单（Yes/No 交易票）、概率历史曲线、liveScore、/topic/pm/vob 订单簿未接。
5. 现货/合约：真实行情 REST/WS、K 线（Lightweight Charts/WebView）、下单/撤单、真实订单/仓位/资产 API 未接；合约/CFD 为占位。
6. MFA 二段、Google 真实登录、忘记密码/重置密码未实现。
7. iOS Keychain 已配置未验证；实体手机与性能基准未做。

## 会话约束（持续有效）

- SDK/缓存留 D 盘；新增或修改包需先明确确认；删除需双重确认，移动/重命名需确认。
- 禁止自主 Git 命令、分支、提交或推送。
- 沿用 PlatformApi/adapter 边界与 Decimal；错误不替换为合法业务默认值；demo 数据必须明确标注且不进 API。
- 本阶段结束后不要自动进入下单或生产操作。

原生存储探针使用隔离测试键，仍留在模拟器中，不是业务会话；未清理用户数据或测试键。
