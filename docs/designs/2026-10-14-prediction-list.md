# 预测市场列表页（真实 API）与四交易模式导航设计

日期：2026-10-14
范围：Flutter 手机端。预测市场列表（真实 v1 API，分页 + 分类筛选 + 三态）；交易页顶部 tab 四模式切换。
导航决策：用户批准**方案 B**——底部导航不动（首页/探索/交易/星球/资产），交易页顶部 tab 改为 现货/合约/CFD/预测；合约/CFD 为占位主体。方案 A（底部导航加预测独立入口、移除星球）不执行。
参考：dex-v2_fe `catalog.ts`（itemToCard 字段映射、概率推导）与 `index.ts`（catalog.cards 请求、pmMenu 分类）。
状态：已按批准范围实现；详情页/下单/搜索/WebSocket 不在本期。

## 导航结构（方案 B）

架构门禁禁止 modules 互相 import，tab 容器上升到 shell：
- `shell/trade/trade_home_screen.dart`：/spot 路由的新宿主——SpotTopBar + InstrumentTabs（受控）+ 按 `tradeTabProvider` 切换主体（0 现货 → modules/spot 交易主体；1/2 合约/CFD → PageStatus“即将上线”；3 预测 → modules/prediction 列表）。shell → modules 方向允许（router.dart 先例）。
- `shell/trade/instrument_tabs.dart`：受控组件（selected + onChanged），自 modules/spot/widgets 迁入；闪兑、策略与跟单两项移除。
- `modules/spot/spot_screen.dart`：不再含顶部栏与 tab，仅保留目录三态 + 交易主体。

## 契约与 wire 映射

`PlatformApi.prediction`（PredictionApi）：
- `events(CardQuery{domain?, sort='soon', page, pageSize=20})` → `GET /swap/pm/home`（信封 data.markets.{items,pagination}）。
- `categories()` → `GET /uc/member/application_config`（data 为 JSON 字符串，取 pmMenu 三级 {name,children}）；401/403 降级为空列表（UI 只显示“全部”），不让列表页失败。

解码规则（与 Web itemToCard 对齐）：
- 概率 = yesAsk×100；ask+bid 价差 ≥0.9（退化占位盘口）→ 未定价 null；无 ask 退 bid → mid → lastTraded（yesPrice）。未定价显示 `—`，不显示 0%。
- SINGLE_BINARY → Yes/No 行（label 缺省用 Yes/No 规范名）；MATCH/MULTI_ROW 等版式一律按通用 outcome 行渲染（label 空白 → `—`）。
- 状态映射（大小写不敏感）：open/active→open，suspended，closed，resolved，settled，cancelled/voided→voided，market_adj_pending/adjudication_pending→adjudicating；未知值抛 responseMalformed（单行失败跳过，整页全失败才报错）。
- volume24h = totalVolumeUsd ?? totalVolume（Decimal，>0，缺失为 null 不补 0）；numMarkets = marketCount ?? totalOutcomeCount ?? outcomes 数。
- 时间：tradingCloseTime/tradingStartTime（毫秒）→ DateTime；LIVE/UPCOMING 由窗口判定（open 且当前 < tradingStartTime → UPCOMING；> tradingCloseTime → Closed；窗口内 → LIVE）。
- 分类 id 为本地 slug（仅作 key）；domain 过滤参数发送节点 label（后端大小写不敏感前缀匹配）。

## 页面

PredictionScreen：CategoryChips（全部 + pmMenu 一级/二级扁平，横向滚动）+ 事件卡片列表。三态：loading / error（eventsError，backendNotConfigured→“未连接”，其余可重试）/ empty（eventsEmpty）。分页：滚动到底部 120px 内自动加载下一页，按 pagination.total 截止；加载更多失败保留已加载内容并在底部给重试入口。卡片点击 → toast“即将上线”（详情页下一阶段）。

EventCardTile：图标（iconUrl，失败/空回退首字母占位圆）、标题（≤2 行）、状态 pill、≤3 个 OutcomeRow（名称 + 概率条 + 百分比/`—`）+ “+N”、底部截止时间与 24h 成交量（K/M 紧凑格式）。

## 测试

- `test/prediction_decode_test.dart`：wire 解码 6 组（ask 定价、退化价差未定价、ask→bid→mid→last 回退链、状态映射与 pricingPending、volume 缺失为 null、MULTI_ROW 通用行、pmMenu 树与 slug）。
- `test/prediction_list_test.dart`：卡片渲染（标题/64%/LIVE/成交量）、空态、错误重试、分类筛选触发 domain 重请求、滚动分页加载、卡片点击占位、tab 切回现货。
- 现有测试适配：instrumentTab.futures/cfd 改断言占位主体；各 FixtureApi 补 prediction getter。

## 卡片版式（2026-10-14 用户反馈后改版；同日按 Polymarket 风参考图二次改版）

EventCard 增加 `archetype`（wire `cardLayout`：MATCH→match、SINGLE_BINARY→binary、其余/缺省→leaderboard）、`isParticipant`、`startsAt`（eventStartTime）与 `domain`。列表卡片按用户提供的 Polymarket 移动风参考图：
- 共同结构：图标（Monogram）+ 标题 + 状态 pill 头；选项行 = Monogram + 名称 + 右侧大号百分比（`24%`，未定价 `—`）；底部 = 交易量紧凑格式（`$52M 交易量`，`formatCompactVolume`，K/M/B 三语一致，null 省略该段）· 分类（domain 末段）· 截止时间（MM-dd HH:mm 本地）+ 书签图标（点击 toast“即将上线”）。
- match：主/客两行 + 三个大胶囊按钮（主队浅蓝 / Draw 居中灰底 / 客队浅蓝，未定价灰显）。
- binary：Yes/No 两行 + 两个大胶囊（按选项着色：是=浅绿、否=浅红，不按领先）。
- leaderboard：概率降序前 4 行，行尾小号 是/否 胶囊（未定价灰显）+ “+N”。
胶囊按钮非独立手势（无快捷下单），点击随整卡进详情。美分格式（12¢）已废弃，`event_price.dart` 删除（详情页未使用，grep 确认后移除）。

## 明确不做

预测详情页与下单、搜索、WebSocket 实时概率、世界杯等特殊版式、合约/CFD 真实页、新依赖、Git 操作。

<!-- 2026-10-14 | 预测列表+四模式导航设计 | 用户批准方案 B；全部真实 API 无 demo 数据。 -->
