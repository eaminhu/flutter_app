# Invariants — flutter_nexusft

> 必须始终成立的规则，每条标注来源。代码偏离 invariant 就是 bug：在同一变更里修代码或更新 invariant，不允许留下"文档化的差距"。
> 建立：2026-10-20，由 architecture.md / decisions.md 的已实现行为提炼；只收录当前已验证成立的约束，规划能力不写入。

## 数据与金融正确性

- **INV-1 — 金融值只用 Decimal。** 金额、价格、数量的解析、计算、渲染一律 `Decimal`（`package:decimal`）；禁止 `double` 参与金融运算。_来源：project-rules.md 映射表；`lib/core/domain/money.dart`。_
- **INV-2 — 不编造场所拥有的值。** 缺失的价格、余额、状态、过期时间保持 `null` 或显式报错；不得用 `0`、空串、猜测值、中间价或借用字段顶替。未接入的报价/余额显示 `--` / `—` 占位。_来源：decisions.md 2026-10-13/10-14；`docs/architecture.md`。_
- **INV-3 — demo 数据隔离。** 本地演示数据（`demo_order_book.dart` / `demo_orders.dart` / `demo_assets.dart`）必须确定性生成、UI 明确标注"演示数据"、不进入任何 API 请求路径；真实行情接入后移除。预测市场列表/详情不使用 demo 数据。_来源：decisions.md 2026-10-13/10-14。_
- **INV-4 — 缺失即 null，不伪造时间。** 后端未提供 `expiresAt` 时保留 `null`，不猜测。_来源：docs/architecture.md 会话节。_
- **INV-5 — 退化价差口径唯一。** 预测概率推导口径（ask 优先、退化价差 ≥0.9 跳过、未定价显示 `—` 而非 0%、volume 缺失为 null）与 Web `itemToCard` 对齐；该金融口径规则只允许一份权威实现，当前已知存在两份（`lib/core/adapters/v1/v1_adapter.dart` 与 `lib/modules/prediction/detail/event_detail_view_model.dart`），属待偿还债务，新增第三份即违规。_来源：decisions.md 2026-10-14；2026-10-20 代码评审。_

## 架构边界

- **INV-6 — UI 不越界。** 页面（modules/shell/design_system）只经 `core` providers / `PlatformApi` 访问后端；不得直接导入 adapter、Dio、存储插件。由 `tool/check_architecture.dart` + `test/architecture_test.dart` 强制。_来源：project-rules.md；`tool/check_architecture.dart`。_
- **INV-7 — 模块互不导入。** `lib/modules/*` 之间不得互相 import；跨模块能力提升到 shell/core/design_system。_来源：同上门禁。_
- **INV-8 — 纯 core。** `core/domain`、`core/api`、`core/config`、`core/localization` 保持纯 Dart，不依赖 Flutter SDK / Riverpod / Forui / 存储插件。_来源：同上门禁。_
- **INV-9 — wire 方言只在 adapter。** 后端路径、字段映射、枚举 crosswalk、venue 特有能力修正只存在于 `lib/core/adapters/*`；非 0 code 抛 serverError 并保留后端 message；单行解码失败跳过、整页全失败才报错。_来源：docs/architecture.md。_

## 会话与安全

- **INV-10 — 凭证存储与隔离。** token 存 `flutter_secure_storage`，按环境 + API origin 命名空间隔离；普通偏好用 SharedPreferencesAsync 且 JSON 严格解码。_来源：docs/architecture.md；`lib/core/storage/native_stores.dart`。_
- **INV-11 — 会话代次隔离。** 退出、401 失效、旧请求由 generation + 顺序写队列隔离：旧请求的 401 不得清除新会话；先确认身份再持久化会话。_来源：docs/architecture.md 会话节；`test/core/network_session_test.dart`。_
- **INV-12 — HTTP 防泄漏。** 禁止跨 origin 请求、禁止跟随重定向；不默认重试；日志只记错误类型，不记正文/凭证/token。_来源：docs/architecture.md；`lib/core/http/dio_http.dart`。_
- **INV-13 — 降级必须可观测。** 降级路径必须记录日志或显式呈现失败；禁止裸吞异常（已知违规点：`lib/core/realtime/stomp_client.dart` 连接失败静默，属待修复项，不得扩散）。_来源：dex 规则移植；2026-10-20 代码评审。_

## UI 与文案

- **INV-14 — 三语言 key 兼容。** `en-US` 为基准 key 树，`zh-CN`/`zh-TW` 必须保持 key 兼容；HTTP 与 UI 共用纯 Dart `languageForTags` 的 Hans/Hant 判定。场所数据（代码、队名）是后端内容，不进 i18n。_来源：docs/architecture.md。_
- **INV-15 — 图表只渲染。** 图表经 WebView 仅渲染，Dart 层管理数据与交易；图表不得持有凭证或发起交易。_来源：decisions.md 2026-10-12；project-rules.md。_
- **INV-16 — 环境显式选择。** 其他环境不静默复用 dev 配置；`API_BASE_URL` 需显式传入。_来源：docs/architecture.md；`lib/main.dart`。_
