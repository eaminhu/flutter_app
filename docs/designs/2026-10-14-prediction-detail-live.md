# 预测市场详情页、列表搜索与实时概率设计

日期：2026-10-14
范围：Flutter 手机端。预测详情页（/prediction/:eventId，shell 外全屏）、列表搜索、auction 实时概率（SockJS+STOMP 自实现，无新依赖）。
状态：协议探针已实测 dev；实现完成；下单、概率历史曲线、liveScore、vob 订单簿不在本期。

## 协议探针实测结论（tool/ws_probe.dart，2026-10-14 dev 实测）

- SockJS websocket transport URL `wss://dev-nexusft-trade-api.nexuspb.com/swap_market/ws/{serverId三位数字}/{session}/websocket` 直连成功，**无需额外 Origin/握手头**。
- 帧序列：服务端先发 `o`；客户端发送 JSON 数组包装的 STOMP 帧字符串（如 `["CONNECT\naccept-version:1.2\nheart-beat:15000,15000\n\n\x00"]`）；服务端回 `a["CONNECTED\nversion:1.2\nheart-beat:15000,15000\n\n\x00"]`（heart-beat 协商成功 15000/15000）。
- SUBSCRIBE `/topic/pm/auction/{marketId}`（marketId 取自真实 /swap/pm/home 的 previewItems）被接受，无 ERROR 帧。
- 服务端心跳以 `a["\n"]` 形式每约 15s 到达（实测 19.4s、34.4s 两帧），不是 SockJS `h` 帧。
- 观测窗口（40s）内该市场无 auction 推送（dev 该市场无活动），属数据侧静默，非协议问题。

## core/realtime（新目录，允许 dart:io，禁止 Flutter）

`stomp_client.dart`：最小 SockJS+STOMP 客户端——`sockJsEncode/sockJsDecode`（o/a/h/c 帧）、`stompEncode/stompDecode`（裸换行=心跳）、StompClient（懒连接、o→CONNECT→CONNECTED、CONNECTED 后重放全部订阅、15s 双向心跳、两次未收心跳判定死连接、5s 重连、ReconnectPolicy 连续失败 6 次封顶且成功重置、revalidate() 立即重连、无订阅时主动断开）。帧编解码与 ReconnectPolicy 为纯函数/纯类，单测覆盖。

## 契约

- `core/api/stream.dart`：`AuctionTick{marketId, indicativePrice?, bestBid?, bestAsk?}`（Decimal，缺失为 null）；`RealtimeApi { Stream<AuctionTick> watchAuction(String marketId); void revalidate(); }`。`PlatformApi` 增加 `realtime` getter；`contract.dart` 导出 stream.dart。
- v1 adapter 实现 RealtimeApi：ws base 由 REST baseUrl 派生（https→wss + /swap_market/ws）；同 marketId 共享一条 STOMP 订阅（引用计数退订）；`decodeAuctionTick` 顶层纯函数，畸形帧丢弃不致命。
- `PredictionApi` 增加 `eventDetail(String eventId)` → `GET /swap/pm/detail/{id}`；`core/domain/event_detail.dart`：EventDetail/DetailOutcome（legs 映射通用行；itemType SINGLE 出 Yes/No 规范对；volume/liquidity/resolutionRule 缺失为 null）。eventId 仅允许 [A-Za-z0-9_-]。
- UnconfiguredAdapter：eventDetail 抛 backendNotConfigured；watchAuction 返回永不产生事件的空 Stream。

## 详情页（/prediction/:eventId，ShellRoute 之外）

自带返回栏（无底部导航）。REST 拉详情 → 渲染（标题 + 状态 pill、outcome 行含实时概率条与百分比、截止/成交量/流动性、结算规则与来源）。数据到达后按概率排序取前 12 个有 marketId 的 outcome 建立 auction 订阅；tick 到达经 `liveProbOf`（ask 优先、无 ask 退 bid、退化价差 ≥0.9 跳过保留上次值）覆盖概率；离开页面退订。三态沿用 PageStatus（key eventDetailError）。Yes/No 按钮 → toast“交易写入未接入”。App 回前台：realtime.revalidate() + 详情 provider 失效重拉（NexusApp 的 WidgetsBindingObserver）。

## 搜索（列表页）

搜索输入行（FTextField + 清除按钮，300ms 防抖）。非 CJK → `CardQuery.search` 走服务端；CJK → 一次拉 pageSize 500 本地按 title/outcome 名过滤（与 Web 一致），本地过滤态不再分页。搜索态显示结果计数，隐藏分类 chips，空结果给专用文案；清除恢复分类浏览。卡片点击改为 `context.push('/prediction/{id}')`。

## 测试

- `test/core/realtime_decode_test.dart`：SockJS/STOMP 编解码、ReconnectPolicy 封顶、decodeAuctionTick、decodeEventDetail、liveProbOf。
- `test/event_detail_test.dart`：详情页三态与渲染、FixtureRealtime 推 tick → 概率更新（退化价差保持上次值）、Yes/No 占位提示。
- `test/prediction_list_test.dart`：卡片点击进详情（全屏无底部导航）、非 CJK 搜索带 search 参数、CJK 本地过滤（pageSize 500 无 search）、清除恢复。
- FixtureApi 全部补 realtime getter；Foundation 三语 key 完整性测试继续覆盖新增 key。

## 明确不做

下单写入、概率历史曲线、liveScore、/topic/pm/vob、现货/合约行情订阅、新依赖、Git 操作。

<!-- 2026-10-14 | 详情页+搜索+实时概率设计 | 探针实测 SockJS/STOMP 握手通过后实现。 -->
