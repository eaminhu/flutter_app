# NexusFT Flutter 总路线图（Web 功能全量对齐版）

更新：2026-10-15。目标：**Web 版（D:\project\dex-v2_fe）现有功能在 Flutter 手机端全部落地**（明确排除项见 §3）。
本文件是唯一的总体计划；各阶段开工时另写带 checkbox 的执行计划（`docs/plans/<日期>-<阶段名>.md`），完成后在 `docs/references/` 留验证记录。
功能盘点来源：Web 版源码全面调查（路由表 `src/app/router/index.ts`、PlatformApi 契约、v1/dex-v2 双适配器）。项目当前状态见 [../status.md](../status.md)、[../handoff.md](../handoff.md)。

## 1. 全局约束（每阶段适用）

- 沿用 PlatformApi/adapter 边界与 Decimal；Dio 只在 core；UI 只经 `platformApiProvider` 访问数据。
- demo 数据必须明确标注且不进 API；未定价显示 `—`，不用 0 填充；错误不替换为合法业务默认值。
- 新增或修改包需先明确确认；禁止自主 Git 操作；不访问生产；真实交易写入（下单/提现/划转）每个阶段开工前单独确认。
- 每阶段完成标准：`check_architecture` 通过、`analyze` 无问题、全部测试通过、模拟器实测截图、文档同步（status/handoff/本文件勾选）。
- 后端：当前对接 v1（x-auth-token，无 refresh）。Web 已确认 dex-v2 是 go-live 目标后端（Bearer + httpOnly refresh cookie）；Flutter 的适配器边界必须保证将来可平移，不为 v1 怪癖泄漏到契约层。

## 2. Web 功能全量盘点 → Flutter 状态矩阵

图例：✅ 已实现并验证 · 🔶 部分实现 · ⬜ 未实现 · ❌ 不做（见 §3）

### 2.1 预测市场（modules/event，Web 唯一完整业务模块）

| 功能 | Web 位置 | Flutter 状态 |
|---|---|---|
| 列表：真实目录 + pmMenu 分类 + 分页 | MarketsHome | ✅ |
| 搜索（非 CJK 服务端 / CJK 本地） | MarketsHome | ✅ |
| 卡片版式 match/binary/leaderboard | MarketCardItem | ✅（7 种 archetype 中已覆盖 3 种版式；winner/qualifiers/ladder/h2h/comparison 均按 leaderboard 泛化渲染，待真实数据校准） |
| 详情页（全屏、状态 pill、Closes） | EventDetail | ✅ |
| 结算规则展示 | EventDetail | ✅（条件渲染） |
| 实时概率（SockJS+STOMP auction） | useEventLiveProb | 🔶 已实现，真机更新未验证（dev 无推送） |
| 排序（临近截止/市场数）、Live/Upcoming/Trending 横切 | MarketsHome | ⬜ |
| 三级发现树（sector→L2→L3）+ tag 过滤 + URL 状态分享 | MarketsHome | ⬜（当前只有一级分类 chips） |
| Hero 横幅、新手引导 PredictionIntro | MarketsHome | ⬜ |
| Prices⇄Odds 赔率透镜切换 | core/lens | ⬜ |
| 队徽 OutcomeCrest、世界杯分组瓷砖视图 | cards | ⬜ |
| 详情：多子市场索引 MarketIndex（分组/搜索/Active 折叠） | detail/MarketIndex | ⬜（当前只渲染首个市场） |
| 详情：概率历史曲线 EventProbabilityHistory | detail/ | ⬜ |
| 详情：liveScore 实时比分（/topic/pm/livescore） | useEventLiveScore | ⬜ |
| 详情：标的价格面板 AssetPricePanel（资产类预测挂现货 K 线） | detail/ | ⬜ |
| 详情：子市场行展开内联订单簿（/topic/pm/vob） | detail/MarketBookPanel | ⬜ |
| 详情：下单票据（Yes/No、amount→payout、previewOrder 预估） | OrderTicket 复用 | ⬜（Yes/No 按钮现为 toast 占位） |
| 详情：当前持仓行（YES+NO 双书） | useEventPosition | ⬜ |
| 事件生命周期锁 CTA（suspended/closed/resolved…） | EventDetail | 🔶（状态 pill 已显示，锁定逻辑待核） |

### 2.2 现货/合约/CFD 交易屏（shell/trade，三模式共用）

| 功能 | Web 位置 | Flutter 状态 |
|---|---|---|
| 交易页四 tab 导航 | —（Web 是路由区分） | ✅ |
| 下单表单骨架（限价、Buy/Sell、%、`--` 占位） | OrderTicket | 🔶（静态骨架，无真实数据） |
| 盘口 UI | SpotVobOrderBook | 🔶（demo 数据，已标注） |
| 订单/仓位区 UI | OrdersTable/PositionsView | 🔶（demo 数据，已标注） |
| 市场选择器 MarketPopup（三模块搜索/分组/自选/实时报价） | MarketPopup | ⬜（当前只有交易对下拉占位） |
| 真实行情：REST 快照 + WS 报价（quote/trade-plate/trade/kline/vob） | realtime.ts 5 个 SockJS 端点 | ⬜ |
| K 线图（蜡烛/线图、周期切换、左滑加载历史、持仓/挂单参考线） | PriceChart（Lightweight Charts） | ⬜ |
| 最新成交流 | market.trades | ⬜ |
| 交易条件弹层 MarketConditions（参数/费率/保证金三 tab） | MarketConditions | ⬜ |
| 风险指标 RiskMetrics（权益/保证金率五值 + 分解弹层） | RiskMetrics | ⬜ |
| 下单全功能：6 种订单类型、TIF 六选、post-only、单位切换、钱包选择、previewOrder 预估、确认弹窗 | OrderTicket（2133 行） | ⬜ |
| 改单 ModifyOrderModal、订单详情 OrderDetailModal（fills+生命周期时间线） | account/components | ⬜ |
| 持仓操作：ManagePositionModal（调杠杆/全逐仓/加减仓/TP/SL）、ClosePositionModal、PositionDetailModal | account/components | ⬜ |
| 交易时段提示（休市/假日文案，只提示不阻断）、不可交易锁 CTA | TradeScreen | ⬜ |
| 合约专属：资金费率历史、杠杆档位表、强平价显示 | position_tiers 等 | ⬜ |

### 2.3 资产 / 资金（shell/wallet + shell/account）

| 功能 | Web 位置 | Flutter 状态 |
|---|---|---|
| 资产页骨架（总资产卡/快捷操作/币种列表/账户区） | WalletAssets | 🔶（demo 数据，已标注） |
| 真实余额：全钱包余额（WS allWalletBalance + REST 调和） | useAccountBalances | ⬜ |
| 资金/交易 silos 分组钱包表（Credit/Liabilities/Equity 分解、隐藏小额、估值币种换算） | WalletAssets | ⬜ |
| Portfolio 页：Positions/Orders/Assets/Ledger/Statement 五 tab | Portfolio | ⬜ |
| Ledger 流水（16 种 TransactionType、服务端过滤分页、Before→After 弹层） | LedgerView | ⬜ |
| Statement 对账单（日/月、预签名 URL 下载） | Portfolio | ⬜ |
| 充值：币种+网络选择、申报式充值、内联二维码、充值记录 | Funds deposit | ⬜ |
| 提现：白名单地址簿增删、校验、二次确认、提现记录、撤销 | Funds withdraw | ⬜ |
| 划转：钱包间划转 + 记录 | Funds transfer | ⬜ |

### 2.4 认证与账户设置（shell/auth + shell/account）

| 功能 | Web 位置 | Flutter 状态 |
|---|---|---|
| 登录（用户名+密码） | Login | ✅ |
| 注册（国家列表/邮箱 OTP/密码 checklist/双协议/自动登录） | Signup | ✅ |
| 会话恢复/失效/退出、路由守卫 | useAuthSession | ✅ |
| MFA 二段（GA/邮箱，登录第二步） | Login | ⬜ |
| 邮箱 OTP 免密登录 | Login | ⬜ |
| Google 登录（GIS → /uc/auth/social/login） | googleSignIn.ts | ⬜（按钮为占位 toast） |
| 忘记密码/重置密码 | ResetPassword | ⬜（入口为占位） |
| 注册开关门控（registerEnable） | Signup | ⬜ |
| 邀请码字段 | Signup | ⬜ |
| 我的页（访客 CTA/已登录账户 ID/设置入口/退出） | 头像菜单 | 🔶（访客态已验证，已登录态待真实账号验收） |
| 安全中心：改密码、2FA 绑定/解绑/启停、资金密码、安全问题、step-up | SecurityCenter | ⬜（Web 侧也 feature-gated） |
| KYC（schema 驱动向导 + 证件上传） | Kyc | ⬜（Web 侧 feature-gated） |
| 偏好：估值币种、下单确认、仓位模式、通知矩阵、每模块默认钱包 | Preferences | ⬜（语言/主题已有） |
| 手续费页（VIP 等级 + maker/taker 费率表） | Fees | ⬜ |
| 自选 Watchlist（跨品类统一收藏） | Watchlist | ⬜（预测卡片书签为占位） |
| 价格提醒 Alerts | Alerts | ❌ Web 已建好但注释隐藏，不跟 |

### 2.5 通知 / 客服 / 其他

| 功能 | Web 位置 | Flutter 状态 |
|---|---|---|
| 收件箱：公告 + 个人消息（已读/删除/未读角标） | Messages | ⬜ |
| 全局公告条（轮播 + 富文本详情） | GlobalAnnouncementBar | ⬜ |
| WS 实时通知 toast（/user/queue/notice：成交/强平/资金事件） | notifications | ⬜ |
| 反馈工单（附件上传 + 我的工单） | Feedback | ⬜ |
| 帮助中心 | Help（CMS + Intercom） | ⬜（做静态内容版，Intercom 换反馈入口） |
| 法律页（条款/风险披露） | Legal | ⬜ |
| 交易条件文档页（冻结快照 + 实时两版） | TradingConditions | ⬜（低优先级，合规内容） |
| 三语言 en/zh-CN/zh-TW | i18n | ✅ |
| 明/暗主题 | data-theme | ✅（token 两套齐备） |
| 客户端机器翻译（后端英文事件标题→本地语言） | core/translate | ⬜（依赖 Edge translator，移动端可行性待评估） |

## 3. 明确不做（与 Web 对齐后的排除项）

- 管理后台一切（AdminApi：上架/裁决/审核/对账）——非 C 端。
- 价格提醒 Alerts——Web 已建好但主动隐藏，不跟。
- 代理下单码 proxyCode、DebugWidget——运营/开发专用。
- 快捷兑换、借贷、法币电汇入金、提现码、质押、子账户、多钱包管理、API Key、个人资料修改——Web 均"契约就绪无 UI"，不做。
- 首页独立内容——Web 首页即预测市场；Flutter 首页维持占位，直到有明确产品定义。
- C2C/跟单/理财/星球/返佣——Web 没有，不做。

## 4. 阶段计划

| 阶段 | 内容 | 状态 |
|---|---|---|
| P0 | 基础：网络/会话/存储/路由/Forui/三语言 | ✅ 2026-10-13 |
| P1 | 现货首页 demo + 登录/注册 + 资产页 demo | ✅ 2026-10-14 |
| P2 | 预测：列表/详情/实时概率/卡片版式/搜索 | ✅ 2026-10-14 |
| P-UI | **UI 全面重构**：token 层 + primitives + 逐页重构（浅色优先，币安/欧易/Polymarket 基准，双主题截图矩阵验收） | ✅ 2026-10-15 |
| P3 | 收尾验证与真实账号验收 | 🔶 进行中 |
| P4 | 现货真实行情 + 市场选择器 | ⬜ |
| P5 | 预测详情增强 + 预测下单 | ⬜ |
| P6 | 现货/合约下单 + 真实订单/仓位 | ⬜ |
| P7 | 真实资产 + Portfolio（五 tab）+ 充提划转 | ⬜ |
| P8 | 认证与账户补全（MFA/OTP 登录/Google/重置密码/偏好/手续费/自选） | ⬜ |
| P9 | 合约/CFD 完整化（风险指标/杠杆/资金费/交易条件） | ⬜ |
| P10 | 通知与客服（收件箱/公告条/WS 通知/反馈/帮助/法律页） | ⬜ |
| P11 | 体验增强（K线全功能/概率曲线/赔率透镜/机翻/新手引导） | ⬜ |
| P12 | 平台与质量（iOS/实体机/性能基准） | ⬜ 持续 |

### P3 收尾验证与真实账号验收（当前）

- [x] 模拟器截图核对：四项导航、合并顶栏、我的页访客态、预测三种卡片版式、详情页。证据：references/2026-10-15-p3-emulator-verification.md。
- [ ] 实时概率真机更新：2026-10-15 在 LIVE 详情页停留 2 分钟无推送（dev 数据静默），待有行情的事件核对。
- [ ] 真实账号验收（需用户输入测试账号）：登录/注册/恢复/失效/退出 + 我的页已登录态。
- [ ] match 1X2 主/客顺序：胶囊顺序与标题一致已确认；venue previewItems 语义待官方依据。

### P4 现货真实行情 + 市场选择器

- v1 行情接入：REST 快照（exchange_plate_full / latest_trade / kline history）+ WS（/market/ws：quote、trade-plate、trade、kline、spot vob）。
- MarketPopup：三模块 tab、搜索、分组、自选（先本地存储，P8 接 API）、实时 bid/ask。
- 盘口/最新成交/价格显示去 demo 化；K 线先接数据 + 基础蜡烛渲染（图表方案决策：自绘 vs WebView+Lightweight Charts，开工时先写 design）。
- 依赖：P3 完成。风险：v1 WS 协议需探针实测（参照 tool/ws_probe.dart）。

### P5 预测详情增强 + 预测下单

- MarketIndex 多子市场索引、子市场行展开内联订单簿（/topic/pm/vob）、liveScore。
- Yes/No 下单票据：amount→payout、previewOrder 试算、确认弹窗、当前持仓行。
- **真实交易写入，开工前需用户确认验收环境。**

### P6 现货/合约下单 + 真实订单/仓位

- OrderTicket 全功能（订单类型/TIF/post-only/单位切换/previewOrder）；下单/撤单/改单。
- 真实当前/历史委托、持仓（REST + /user/queue/refreshOrderList 失效信号重读）、订单/持仓详情弹窗。
- **真实交易写入，开工前需用户确认。**

### P7 真实资产 + Portfolio + 充提划转

- 全钱包余额（WS allWalletBalance + REST）、silos 分组表、Portfolio 五 tab、Ledger、Statement。
- 充值（申报式 + 二维码）、提现（白名单地址簿 + 二次确认）、划转。
- **提现/划转是资金写入，开工前需用户确认。**

### P8 认证与账户补全

- MFA 二段、邮箱 OTP 免密登录、Google 登录、忘记/重置密码、注册开关、邀请码。
- 偏好（估值币种/下单确认/仓位模式/通知矩阵）、手续费页、自选 API 化。

### P9 合约/CFD 完整化

- RiskMetrics、ManagePosition（调杠杆/全逐仓/TP/SL）、资金费率历史、杠杆档位、MarketConditions 三 tab、交易时段提示。
- 依赖 P6（下单链路已通）。

### P10 通知与客服

- 收件箱（公告+个人消息）、全局公告条、/user/queue/notice 实时 toast、反馈工单（含附件上传）、帮助中心静态版、法律页、交易条件文档页。

### P11 体验增强

- K 线全功能（周期切换/左滑历史/持仓挂单参考线）、概率历史曲线、AssetPricePanel、Prices⇄Odds 透镜、机器翻译、新手引导、Hero 横幅、队徽、三级发现树、排序与 Trending 横切。

### P12 平台与质量（持续）

- iOS Keychain 实机验证、实体 Android 机构建验证、性能基准（启动/列表滚动/WS 长连接耗电）。
- P3 之后任何时间点可启动。

## 5. 顺序与调整规则

- 主线：P3 → P4 → P5/P6 → P7 → P8 → P9 → P10 → P11；P12 持续穿插。
- 阶段顺序可调，但调整需更新本表并写明原因；不允许跳过 P3 直接开 P4+。
- 每个新阶段开工前：先写 `docs/designs/<日期>-<主题>.md` 设计文档（含 API 协议确认/探针结论），再写执行计划，按 executing-plans 执行。
