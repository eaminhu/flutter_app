# 已接受决策

## 2026-10-12 — Flutter 手机客户端与业务顺序

用户确认：Android/iOS 首期，项目目录 D:\project\flutter_nexusft；现货交易（Spot）优先。基础 K 线和成交量使用 Lightweight Charts / WebView，概率曲线留到 Event 模块。
沿用现有 Web 的平台契约名称和 adapter 边界；图表只渲染，行情和交易由 Dart 层管理。

## 2026-10-13 — 基础框架执行

用户确认执行已列出的五项依赖安装命令并继续搭框架。
本次落实已接受设计中的基础框架阶段：路由、三语言、主题、目录接口、错误与精确 Decimal。
后端未接入时明确拒绝目录读取；不使用假成功 API 或展示看似真实的市场数值。
偏好目前仅保存在 App 会话内；真实后端、持久化、登录、图表和交易流程进入后续阶段，不作为本次完成声明。
Android 只构建 APK，真机验证按用户明确选择推迟。


2026-10-13：用户确定 UI 使用 Forui + 自定义交易组件，Android/iOS 专业紧凑交易风格；选择已确认，安装与接入尚未完成。

## 2026-10-13 — 网络/会话与 Forui 阶段完成
用户确认四项依赖与方案；真实 dev 目录、HTTP、原生凭证/偏好、基础登录守卫、Forui 通用控件已实现。此前“偏好仅会话内/未接入后端/Forui未安装”描述仅对应最初框架阶段；当前状态以 status.md 和 handoff.md 为准。真实账号、图表、实时与交易写入仍不作为完成声明。

## 2026-10-13 — 现货首页布局与交易 token 确认
用户确认：现货首页按 OKX 截图布局（顶部栏/交易 tab/交易对区/下单表单/盘口/图表入口条），配色参考 Binance 深色截图（涨买绿 #2EBD85、跌卖红 #F6465D、面板底 #0B0E11/#161A1E 系）；交易 token 落地为 design_system/tokens/trading_tokens.dart 并归档 design-tokens.md。数据策略：交易对用真实目录，价格/盘口/余额一律 `--` 占位，不编造数值、不用 0 填充；底部导航五项（首页/探索/交易/星球/资产），未上线入口走 /placeholder；下单与行情接入不在本阶段。未执行 Git 操作。

## 2026-10-13 — 盘口改为模拟数据
用户要求盘口加入模拟数据。实现为 modules/spot/demo_order_book.dart 本地确定性生成（按 symbol 哈希作种子，同交易对数值稳定，Decimal 值），盘口档位、中间价与买卖比均来自该生成器，UI 明确标注“演示数据”；仅用于界面开发，不进入 API 请求，真实行情接入后移除。表单/报价/余额仍保持 `--` 占位。

## 2026-10-14 — 登录注册完善、订单/仓位区与资产页
用户确认本期范围：登录页完善（密码可见性、忘记密码占位、注册入口）、注册页 /register 接真实 v1 邮箱注册链路（国家列表、发码倒计时、校验规则与 Web 一致、成功自动登录）、现货页底部订单/仓位区、资产页 /assets。Google 登录仅占位（不加 google_sign_in 依赖、不接 /uc/auth/social/login）；MFA、忘记密码、真实订单/仓位/资产 API 不做。订单/仓位/资产/盘口使用本地确定性 demo 数据（按 symbol 种子或固定值），UI 标注“演示数据”，不进入任何 API 请求；真实目录继续走 spotMarketsProvider。未执行 Git 操作。

## 2026-10-14 — 预测市场列表与四模式导航（方案 B）
用户确认：预测市场列表页接真实 v1 API（/swap/pm/home + application_config pmMenu 分类，分页、三态，不用 demo 数据）；导航采用方案 B——底部导航不动（首页/探索/交易/星球/资产），交易页顶部 tab 为 现货/合约/CFD/预测，合约/CFD 占位。理由：保持底部五项稳定，四种交易模式集中在交易页切换；方案 A（底部加预测、移除星球）不执行。预测详情/下单、搜索、WebSocket 实时概率后置。概率推导与 Web itemToCard 对齐（ask×100；退化价差 ≥0.9 或未定价显示 — 而非 0%；volume 缺失为 null）。未执行 Git 操作。

## 2026-10-14 — 预测详情页、搜索与实时概率
用户确认本期范围：预测详情页（/prediction/:eventId 全屏、shell 外）、列表搜索（非 CJK 服务端 search、CJK 本地 500 条过滤、300ms 防抖）、实时概率（dart:io 自实现 SockJS+STOMP，无新依赖；/topic/pm/auction/{marketId}，ask 优先、退化价差跳过、最多 12 个领先 outcome 订阅）。协议先经 tool/ws_probe.dart 实测 dev：SockJS websocket transport 直连成功，o/a["..."] 帧格式确认，STOMP heart-beat 15000/15000 协商成功，心跳以 a["\n"] 形式到达。下单写入、概率曲线、liveScore、vob 不做。未执行 Git 操作。

## 2026-10-14 — 导航四项、顶栏合并与预测卡片版式
用户截图反馈后确认：底部导航改四项（首页/交易/资产/我的，移除探索/星球，explore/planet 文案 key 已删）；/account 改造为“我的”页（无守卫，访客显示登录/注册 CTA，已登录显示账户 ID + 设置/语言主题入口行 + 退出）；AppShell 移除 FHeader 消除双 NexusFT，SpotTopBar 成为交易页唯一顶栏（含设置齿轮），资产/我的/设置页各自带简洁页头；预测卡片按 Web 版式改 match/leaderboard/binary 三种，价格为美分格式（12¢），未定价显示 —。快捷下单不做。未执行 Git 操作。

## 2026-10-14 — 预测列表卡片按 Polymarket 风参考图改版
用户确认：列表卡片按其提供的 Polymarket 移动风参考图二次改版——大号百分比替代美分（event_price.dart 删除，compact_volume.dart 新增 $52M/$975K/$1.2B 紧凑格式，三语统一 K/M/B 不本地化为万/亿）；match 主/DRAW/客三胶囊、binary 是/否按选项着色（绿/红不按领先）、leaderboard 行尾是/否小胶囊；底部为交易量·分类（domain 末段，EventCard 补 domain 字段）· 截止时间 + 书签占位。胶囊按钮不做快捷下单，点击随整卡进详情。未执行 Git 操作。
