# P3 模拟器核对验证记录

日期：2026-10-15。环境：AVD Medium_Phone_API_36（API 36 / x86_64），APK 为 2026-10-14 构建的 app-debug.apk（lib/ 无更新代码，直接覆盖安装）。截图在 build/p3-*.png。

## 环境变更（重要）

- handoff 原记录的 AVD `NexusFT_API_36` 已不存在，本机现有 AVD 为 `Medium_Phone_API_36`。
- 该 AVD 的 config.ini 原指向未安装的 `google_apis_playstore` 系统镜像导致无法启动（FATAL: Cannot find AVD system path）。已备份为 `config.ini.bak`，改为已安装的 `google_apis` 镜像（image.sysdir.1 / tag.* / PlayStore.enabled=false）后正常启动。无 Play Store 对测试无影响。

## 已核对通过（截图证据）

| 项 | 截图 | 结论 |
|---|---|---|
| 底部四项导航逐项跳转 | p3-01/02/03/04 | Home→占位页（Coming soon.）、Trade→现货、Assets→资产页、Profile→我的页，选中态正确 |
| 合并顶栏 SpotTopBar | p3-01/05/06 | 唯一顶栏：Logo + 搜索 + Sign up 按钮 + 设置齿轮 + 菜单；AppShell 无 FHeader |
| 我的页（访客态） | p3-04 | "Profile" 标题 + Sign in / Sign up CTA；已登录态待真实账号 |
| 资产页 | p3-03 | 总资产卡带 Demo data 标注、Deposit/Withdraw/Transfer、USDT/BTC/ETH 列表、Sign in/Sign up CTA |
| 交易页四 tab | p3-05/06 | Spot/Futures/CFD/Prediction 切换正常 |
| match 卡片 | p3-06 | Everton vs Chelsea 等 LIVE，主/DRAW/客三胶囊、未定价 `—`、Premier League · 时间 + 书签 |
| leaderboard 卡片 | p3-12/13 | 多行选项（前 4 行 +N）行尾 Yes/No 小胶囊、未定价 `—` |
| binary 卡片 | p3-14 | Yes/No 行 + 大胶囊（Yes —/No —） |
| 预测详情页 | p3-07/09 | ShellRoute 外全屏、返回栏、LIVE pill、Yes/No 行 + 按钮、Closes 时间；resolutionRule 为 null 时结算规则不渲染（event_detail_screen.dart:221 条件渲染，符合设计） |
| match 主/客顺序 | p3-06 | 卡片胶囊顺序与标题对阵顺序一致（Everton 主 | Draw | Chelsea 客）；venue previewItems 语义仍未有官方校准依据 |

## 未通过 / 未闭环

- **实时概率真机更新**：在 Brentford vs Liverpool 详情页（LIVE 事件）停留 2 分钟，两张截图仅状态栏时钟变化，价格保持 `—`，未收到 auction 推送。与 2026-10-14 探针结论一致：dev 数据侧静默，非协议问题。真机更新表现仍待有行情推送的事件核对。
- **真实账号验收**：登录/注册/恢复/失效/退出需用户在 App 输入测试账号，未做。我的页已登录态也因此未核对。

## 备注

- 顶栏深色 "Sign up" 胶囊是 SpotTopBar 的注册按钮本体（uiautomator 确认为 Button），不是悬浮 bug。
- 过程中未执行 Git 操作，未改动业务代码；唯一改动是 AVD config.ini（工作目录外，已备份）。
