# 现货交易首页 Demo 设计（/spot 改造）

日期：2026-10-13
范围：Flutter 手机端现货首页布局 demo；不接真实行情、盘口与交易写入。
参考：用户提供 OKX 现货页截图（布局）与 Binance 深色截图（配色），取色来源已在 design-tokens.md 标注。
状态：用户已确认数据策略、页面范围与路由方案后实施。

## 目标与非目标

目标：按 OKX 截图结构实现现货首页——顶部栏、交易类型 tab、交易对选择 + 价格区、买入/卖出下单表单、盘口区（含买卖比条）、底部图表入口条；底部导航改为首页/探索/交易/星球/资产五项。

非目标：不接真实行情/盘口/价格接口；不实现下单（登录后点击仅提示“交易写入未接入”）；不接 Lightweight Charts（图表入口仅占位）；闪兑/合约/策略与跟单、首页/探索/星球为禁用态或占位路由。

## 数据策略（已确认）

- 交易对列表使用真实 `/market/symbol` 目录（经既有 `spotMarketsProvider`，开发环境 18 条）。
- 价格、涨跌幅、余额一律显示 `--` 占位；不编造数值、不用 0 填充、不给 Market 增加假字段。
- 盘口与买卖比条：用户要求加入模拟数据（2026-10-13）。由 `modules/spot/demo_order_book.dart` 按 symbol 确定性本地生成（同一交易对数值稳定），UI 明确标注“演示数据”；仅用于界面开发，不进入任何 API 请求，真实行情接入后移除。其余表单/账户数值仍为 `--` 占位。

## 页面结构

自上而下：SpotTopBar（logo/搜索/注册或账户/菜单）→ InstrumentTabs（闪兑/现货/合约/策略与跟单，仅现货可用）→ PairHeader（选中交易对 + 最新价/涨跌幅占位，点击弹出真实目录选择）→ 双栏区（左 OrderTicket 下单表单 : 右 OrderBookPanel 盘口，窄屏 flex 约 5:4）→ ChartEntryBar（“BTC/USDT 图表”入口占位）。

三态保留：loading（目录读取中）、error（`marketError` key，沿用 PageStatus + retryable）、empty（`marketEmpty` key）。错误/空态下顶部栏与 tab 仍可见。

## 组件划分

- `design_system/tokens/trading_tokens.dart`：交易色板（明/暗）、字号档位、盘口行高 token。涨/买绿、跌/卖红参考 Binance 截图（#2EBD85 / #F6465D 系）；面板底参考 #0B0E11 / #161A1E 系；不把 Forui destructive 当跌色。
- `design_system/trading/`：跨模块可复用纯 UI——price_text / change_text / trade_side_switch / percent_selector / order_book_entry（纯 Dart 值类型）/ order_book_list / buy_sell_ratio_bar。数字统一 `FontFeature.tabularFigures()` 等宽，null → `--`。
- `modules/spot/widgets/`：spot 页面级组合——spot_top_bar / instrument_tabs / pair_header / order_ticket / order_book_panel / chart_entry_bar。

## 交互与状态

- PairHeader 点击弹出真实目录列表，选择更新 `spotSelectedMarketIdProvider`（默认目录第一条）。
- OrderTicket：限价委托下拉（市价委托禁用占位）、价格输入（“最优价”按钮提示行情未接入）、数量/金额输入、0/25/50/75/100% 百分比（纯 UI 状态）、可用/可买 `--`、止盈/止损勾选（纯 UI 状态）。
- OrderBookPanel：演示数据标注 + 本地确定性生成的 7 档卖盘/7 档买盘/中间价/买卖比（`demoOrderBook(symbol)`，Decimal 值类型，同 symbol 结果稳定）。
- CTA：未登录显示“登录/注册”并 `context.go('/login')`；已登录显示“买入/卖出”，点击仅 SnackBar 提示“交易写入未接入”，不发请求。
- 搜索/菜单/图表入口/未上线 tab：SnackBar 提示“即将上线”或禁用灰显。

## 路由与导航

- `/spot` 路由名与 initialLocation 不变。
- 底部导航五项：首页/探索/交易(/spot)/星球/资产(/account，未登录守卫跳 /login)；首页/探索/星球 → `/placeholder`（PageStatus“即将上线”）。
- 选中项按 location 白名单计算，`/placeholder` 等未匹配路径不高亮；`/settings` 移至 AppShell header 右侧设置图标。

## 验收标准

- 架构门禁、`flutter analyze`、全部测试、`check-android-requirements.ps1` 通过。
- 测试覆盖：目录加载后 PairHeader 显示真实 symbol；表单/报价为 `--` 占位；盘口演示数据渲染且标注“演示数据”；demoOrderBook 同 symbol 确定性；买入/卖出切换；未上线 tab 禁用；未登录 CTA 为“登录/注册”；底部导航五项且交易选中；`/placeholder` 可达；新输入框 Android/iOS × 三语言长按选择菜单不红屏。
- 模拟器截图核对：深色底、双栏布局、盘口演示数据与买卖比、底部导航选中态（build/spot-demo1.png）。

<!-- 2026-10-13 | 现货首页 demo 设计 | 用户确认 OKX 布局 + Binance 深色配色；盘口模拟数据按用户要求加入并明确标注。 -->
