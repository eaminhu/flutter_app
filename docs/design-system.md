# 移动端设计规范

更新：2026-10-15。记录用户已确认方向与当前实现，不作为完整交易页设计验收。

## 已确认方向

- 首期 Android/iOS 手机端，现货优先。
- Forui + 自定义交易组件。
- 参考 OKX、Binance、Polymarket 移动端的专业交易体验；信息紧凑、交互流畅，两平台保持统一视觉。
- **2026-10-15 UI 重构：浅色优先（Polymarket 级精致度），深色同步适配；token 先行 + 逐页重构已完成八个阶段。**
- 无需沿用旧 Web UI；参考产品不代表复制其品牌色、布局或业务能力。
- 基础 K 线与成交量采用 Lightweight Charts / WebView；概率曲线留到后续 Event。

## 当前实现

通用主题是 Forui neutral 的 light.touch / dark.touch，支持跟随系统、浅色和深色。2026-10-15 起项目有自有 App token 层（字号/间距/圆角/投影 + AppCard/AppIconButton/AppListRow/PageStatus 四个 primitives），页面字号、间距、圆角全部 token 化，Material IconButton/ListTile/Card/CircleAvatar 直接用法已清零；详见 [design-tokens.md](design-tokens.md)「应用 token 层」。AppShell 统一 SafeArea 处理。

已使用 FScaffold、FHeader、FBottomNavigationBar、FButton、FTextField、FSelect、FCheckbox、FToaster，并有自定义 PageStatus。MaterialApp.router 是宿主；仍有 Flutter Text、Divider、Icon 和加载指示器，尚未完成全量视觉统一。

现货首页（/spot）已实现交易页布局 demo：顶部栏、交易类型 tab（现货/合约/CFD/预测，合约/CFD 占位）、交易对选择 + 价格区、买入/卖出下单表单、盘口面板与买卖比条、图表入口条、订单/仓位区；底部导航为首页/交易/资产/我的四项，shell 无 FHeader，设置入口在交易页顶栏齿轮，未上线入口走 /placeholder 占位页。价格、涨跌幅、盘口、余额一律 `--` 占位，不接行情与交易写入。交易色板（涨绿 #2EBD85、跌红 #F6465D、面板底深色 #0B0E11 系）与等宽数字已落地为 trading token，见 [design-tokens.md](design-tokens.md)「交易专用 token」。预测卡片按 match/leaderboard/binary 三版式渲染，价格为大号百分比（未定价 `—`），卡片底部为交易量紧凑格式（K/M/B）· 分类 · 截止时间与书签占位。

本阶段页面仅包含现货目录、登录、账户身份和设置。当前目录没有价格、涨跌幅、成交量，不用假数据填补设计。

根层保留 Forui 与 Flutter 两套本地化委托，覆盖根 Navigator overlay 的选择菜单；不能只在输入框子树补委托。三语言 en-US / zh-CN / zh-TW。当前六种平台/语言文字选择菜单测试已通过，Android 实际菜单已验证；iOS 原生表现未验证。

## 尚待设计确认与实现

- 行情/盘口真实数据接入后的密度与精度复核；资产与委托导航。
- 金额精度与截断显示由行情阶段的市场元数据决定。
- 品牌色、图表网格与蜡烛色、动效时长。
- 大字体、屏幕阅读器、对比度和小屏验证；两平台视觉统一是目标，当前没有完整对比验收。

交易页布局、盘口行密度、订单表单与买卖/涨跌颜色已于 2026-10-13 确认并实现（见上文当前实现与 design-tokens.md）。

<!-- 2026-10-13 | 汇总设计规范 | 汇集已确认移动端方向，区分当前组件与待设计交易体验。 -->

