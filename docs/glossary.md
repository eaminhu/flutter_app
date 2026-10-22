# 术语表 — flutter_nexusft

> 当前术语以 `lib/core/domain/` 与 `lib/core/api/contract.dart` 为准；与 Web 项目 `dex_v2_fe` 共享平台契约词汇。
> 建立：2026-10-20。目标模型词汇不代表已实现能力；实现状态见 [status.md](status.md)。

## 平台与分层

| 术语 | 定义 |
|---|---|
| **PlatformApi** | 后端能力的唯一契约（`lib/core/api/contract.dart`），含目录/认证/注册/预测/实时子契约；UI 只面向它编程。 |
| **adapter** | `lib/core/adapters/*` 中的协议适配实现；当前仅 v1 一族（`V1Adapter`）。所有 wire 路径、字段方言、枚举 crosswalk 的唯一归属地。 |
| **环境（APP_ENV）** | `dev` / `uat` / `prod`，显式选择；默认 `dev` 指向开发环境 API。 |
| **pure core** | `core/domain`、`core/api`、`core/config`、`core/localization`：纯 Dart，不依赖 Flutter/Riverpod/存储插件。 |

## 目录与交易

| 术语 | 定义 |
|---|---|
| **Market** | 可交易标的身份，`marketId` + `symbol` + `instrumentType`；ID 沿用 Web 规则（去下划线后缀、斜杠变连字符）；`enable=0` 排除、`enable=2` 仍展示。当前不提供未接入的价格/余额/交易状态。 |
| **instrumentType** | 品种类型判别。当前交易页四模式：现货 / 合约 / CFD / 预测（合约、CFD 为占位）。 |
| **demo 数据** | 本地确定性生成的演示数据（盘口/订单/资产），UI 标注"演示数据"，不进入 API；真实接入后移除。 |

## 预测市场

| 术语 | 定义 |
|---|---|
| **EventCard / EventDetail** | 预测事件列表卡片与详情领域类型（`core/domain/event_card.dart`、`event_detail.dart`）。 |
| **outcome** | 事件的某个结果选项（如是/否、主/平/客）；详情页最多订阅前 12 个领先 outcome 的实时概率。 |
| **TradeStatus** | 事件交易状态枚举；与交易窗口共同判定卡片 pill（LIVE/UPCOMING）。 |
| **退化价差（degenerate spread）** | 买卖价差 ≥0.9 的盘口状态；概率推导遇退化价差跳过，UI 显示 `—` 而非 0%。口径与 Web `itemToCard` 对齐（INV-5）。 |
| **pmMenu** | `application_config` 返回的预测分类菜单，驱动列表分类 chips。 |
| **auction 通道** | 实时概率推送 `/topic/pm/auction/{marketId}`，SockJS（仅 websocket transport）+ STOMP 1.2，dart:io 自实现；ask 优先。 |

## 会话与存储

| 术语 | 定义 |
|---|---|
| **会话代次（generation）** | 会话单调递增代次，配合顺序写队列隔离旧请求/旧登录；旧请求的 401 不得清除新会话。 |
| **凭证命名空间** | secure storage 中按 环境 + API origin 隔离的凭证作用域。 |
| **languageForTags** | 纯 Dart 的语言判定（Hans/Hant），HTTP 请求头与 UI 本地化共用。 |
| **AppText** | i18n key 枚举；`en-US` 为基准树，`zh-CN`/`zh-TW` 保持 key 兼容。 |
