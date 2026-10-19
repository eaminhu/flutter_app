# 设计 token：当前实现清单

更新：2026-10-15。基于项目代码与锁定的 Forui 0.27.5 源码核对。
Token 是具有统一名称的颜色、字号、圆角等样式值。**2026-10-15 UI 重构后，项目有了自己的 App token 层**（见文末「应用 token 层」），Forui 仍是组件主题底座。

## 来源与接入

- App 入口：[nexus_app.dart](../lib/app/nexus_app.dart)，选择 FTheme.neutral.light.touch / dark.touch。
- Flutter 宿主映射：[app_theme.dart](../lib/design_system/theme/app_theme.dart)。
- 页面访问 Forui：context.theme.colors / typography / style。
- 基础样式来源：Forui 0.27.5 的 lib/src/theme/{colors,typography,style,border_radius}.dart，版本由 pubspec.lock 固定。

项目未覆盖默认字体/圆角，没有品牌色或交易专用 token。升级 Forui 时需要重新核对这份快照，不能把当前依赖默认值当作永久品牌规范。

## 语义颜色

普通颜色写为 #RRGGBB；透明色写为 #AARRGGBB。

| Forui 名称 | 用途 | 浅色 | 深色 |
| --- | --- | --- | --- |
| background | 页面背景 | #FFFFFF | #0A0A0A |
| foreground | 主要文字 | #0A0A0A | #FAFAFA |
| primary | 主要操作 | #171717 | #E5E5E5 |
| primaryForeground | 主要操作文字 | #FAFAFA | #171717 |
| secondary | 次要操作背景 | #F5F5F5 | #262626 |
| secondaryForeground | 次要操作文字 | #171717 | #FAFAFA |
| muted | 弱化背景 | #F5F5F5 | #262626 |
| mutedForeground | 次要文字 | #737373 | #A1A1A1 |
| card | 卡片背景 | #FFFFFF | #171717 |
| border | 边框 | #E5E5E5 | #1AFFFFFF |
| destructive / error | 破坏性操作 / 错误 | #E7000B | #FF6467 |
| destructiveForeground / errorForeground | 对应文字 | #FAFAFA | #FAFAFA |
| barrier | 遮罩 | #33000000 | #7A000000 |

这些是 Forui 语义颜色。Flutter 宿主只显式映射 primary、secondary、surface=background、error=destructive 及对应文字颜色，其他 Material ColorScheme 值仍由 fromSeed 派生；不能宣称两套全部颜色逐项相同。

## 字体与字号

Forui 默认字体为 packages/forui/Inter；项目未定义中文字体，缺字由平台字体回退，因此 Android/iOS 中文字形可能不同。两平台主题一致不等于每个字形一致。

Touch 模式默认值（单位为 Flutter 逻辑字号；height 为行高倍数）：

| token | 字号 | height | 当前用途 |
| --- | --- | --- | --- |
| typography.body.sm | 16 | 1.5 | 可用小号正文，项目未统一指定 |
| typography.body.md | 18 | 1.75 | Flutter textTheme.bodyMedium |
| typography.body.lg | 20 | 1.75 | Forui 默认图标尺寸来源 |
| typography.display.xl | 22 | 2 | 页面标题、Flutter headlineLarge |

以上依据 FTypeface.inherit(touch: true) 的实际实现；该版本部分字号注释与实现不一致，以实现为准。display 与 body 当前继承同一默认 FTypeface。交易价格、数量、涨跌幅及概率字号尚未定义；没有等宽数字的项目级约定。

## 圆角、边框与间距

Forui 默认 style.borderRadius：

| 名称 | 半径（逻辑像素） |
| --- | --- |
| xs2 / xs / sm / md | 4 / 6 / 8 / 10 |
| lg / xl / xl2 / xl3 | 14 / 18 / 22 / 26 |
| pill | 100 |

这是可用半径集，不代表每个控件实际都用 md；组件默认样式自行选择。style.borderWidth=1，默认 pagePadding 为水平 12 / 垂直 8。默认阴影为 #0D000000、偏移(0,1)、blurRadius=2。

项目页面还有独立布局值：

- 登录、账户、设置：外边距 16，常见段间距 8 / 16 / 24 / 32。
- 现货标题：左/上/右 24、下 16；目录行：水平 16、垂直 14。
- PageStatus：外边距 24、内容间距 16。

以上是当前代码快照，尚未抽成共享 spacing token；不能宣称已完成统一间距体系。

## 交易专用 token（2026-10-13 已实现）

代码入口：[trading_tokens.dart](../lib/design_system/tokens/trading_tokens.dart)，含 `TradingColors`（明/暗两套）、`TradingText`（等宽数字字号档位）、`TradingMetrics`（行高/间距）。深色取值来自用户提供的 Binance 深色截图取色，浅色为对应可读值；设计稿见 [2026-10-13-spot-trading-home.md](designs/2026-10-13-spot-trading-home.md)。

| token | 用途 | 浅色 | 深色 | 来源 |
| --- | --- | --- | --- | --- |
| up | 涨/买（绿） | #2EBD85 | #2EBD85 | Binance 截图买盘/涨色 |
| down | 跌/卖（红） | #F6465D | #F6465D | Binance 截图卖盘/跌色；禁止用 Forui destructive 替代 |
| bidDepth | 买盘深度底色 | #142EBD85 | #1F2EBD85 | up 低透明度 |
| askDepth | 卖盘深度底色 | #14F6465D | #1FF6465D | down 低透明度 |
| surface | 交易面板底 | #FFFFFF | #0B0E11 | Binance 截图面板底 |
| surfaceRaised | 抬升区域底 | #F5F6F7 | #161A1E | Binance 截图输入区底 |
| border | 细描边/分隔线（2026-10-15 新增） | #E8EAED | #2B2F36 | 浅色与卡片投影配合建立层级 |

字号档位：priceLarge 20/w700（最新价）、priceMedium 13/w500（盘口与表单数值）、caption 12（标签与说明），全部 `FontFeature.tabularFigures()` 等宽数字。布局：盘口行高 20，页面水平内边距 12，双栏间距 10，表单段间距 10（逻辑像素，按截图密度定值）。

蜡烛、图表网格、动效时长仍未定义，待图表阶段确认。

## 应用 token 层（2026-10-15 UI 重构新增）

UI 重构（浅色优先，参考币安/欧易/Polymarket）建立的项目自有 token 层，代码在 `lib/design_system/tokens/`：

- **app_spacing.dart**：`AppSpacing`（xxs2/xs4/sm8/md12/lg16/xl24/xxl32，pagePadding=lg）+ `AppInsets`（page/card）+ `AppGap`（v2–v32/h2–h16）。间距不再散写字面量。
- **app_typography.dart**：`AppTextStyle`（display 28/w700、title 20/w700、heading 16/w600、body 15、label 13/w500、caption 12）+ `AppNumber`（large 24/w700、medium 16/w600、small 13/w500，全部 tabular figures）。注意与本地化枚举 `AppText` 同名域区分。
- **app_radius.dart**：`AppRadius`（sm6/md10/lg14/pill999 + *All BorderRadius 常量）。
- **app_shadows.dart**：`AppShadows.card/raised(brightness)`——浅色卡片 = 细描边 + 6% 黑 y2/blur12 单层柔和投影；深色返回空（靠表面色分层）。
- **primitives**：`AppCard`（统一卡片容器）、`AppIconButton`（44dp 触摸目标）、`AppListRow`（统一列表行，替代 Material ListTile）、`PageStatus`（统一空态/错误页，48 图标 + maxWidth 320）。

ThemeData 宿主映射（app_theme.dart）：TextTheme 补全 bodySmall→caption、titleMedium→heading、titleLarge→title、headlineLarge→display。AppShell 对内容统一 `SafeArea(bottom: false)`。

<!-- 2026-10-13 | 现货首页交易 token | 用户确认 Binance 深色配色，交易 token 首次落地并归档。 -->

