# 登录注册完善、订单/仓位区与资产页设计

日期：2026-10-14
范围：Flutter 手机端。登录完善、邮箱注册（/register）、现货页订单/仓位区（demo）、资产页（/assets，demo）。
参考：Web 端 v1 认证契约（dex-v2_fe src/core/adapters/v1-server/index.ts）与 Login.vue/Signup.vue 字段结构。
状态：用户已确认范围后实施；Google 登录、MFA、忘记密码、真实订单/资产 API 不在本期。

## 契约与 adapter

AuthApi 新增三方法：
- `countries()` → v1 `POST /uc/support/country?isReg=1`，data[]={zhName,enName,areaCode}；注册提交的国家字段为后端匹配的 zhName。
- `sendRegisterCode(email)` → `GET /uc/verify/email/register?email=...`；信封 code==0 即成功（data 为 null，不是失败）。
- `register(RegisterInput)` → `POST /uc/register/email`（form-urlencoded：email,username,password,code,protocol=true,promotion,superPartner='',country,phone；空 data 即成功）。

`core/domain/country.dart`：Country 与 RegisterInput 纯值类型。`core/domain/register_rules.dart`：纯函数校验（email、username 5–30 含字母不含 @、手机纯数字 ≥5、邮箱码 6 位字母数字、密码五条规则 checklist、确认密码一致），页面与单测共用。

adapter 信封解码调整：非 0 code 抛 serverError 并保留后端 message（UI 原样展示优先，本地文案兜底）；新增容忍空 data 的解码变体供发码/注册使用。UnconfiguredAdapter 三方法抛 backendNotConfigured。

## 登录页

密码可见性切换（suffix 眼睛图标）、忘记密码（toast 即将上线）、“没有账户？注册”跳 /register、分隔线 + Google 按钮占位（toast，不接插件）；错误横幅改为 FAlert.destructive，serverError 展示后端 message，其余沿用本地文案。

## 注册页（/register）

单页表单：国家/地区下拉（countries()，失败可重试）、手机号（hint 显示所选 areaCode）、邮箱 + 验证码（发送后 60s 倒计时，按钮显示剩余秒数并禁用）、用户名、密码（实时 5 条规则 checklist）、确认密码（不一致即时提示）、邀请码（选填）、《条款和条件》《风险披露声明》两个勾选（文档链接为独立图标按钮，toast 占位）。全部合法 + 双协议勾选才可提交；防重复提交；成功 → register → 既有 login+me 自动登录 → 守卫跳 /account；失败 FAlert 展示后端 message，表单保留可重试。已登录访问 /register 由守卫重定向 /account。

## 订单/仓位区（现货页底部）

`modules/spot/demo_orders.dart`：按 symbol 种子确定性生成（当前委托 2、历史委托 3 含已成交/已撤销状态、仓位 1 含成本/现价/盈亏额与盈亏%），Decimal 数值，固定基准时间，不依赖墙钟。`widgets/orders_tabs.dart`：三 tab（带条数）+ 列表，行内标注“演示数据”；未登录在列表上方显示登录引导条。接入 spot_screen 底部（图表入口条下方，固定高度 230，列表内部滚动）。

## 资产页（/assets）

`modules/assets/`：`demo_assets.dart`（固定 USDT/BTC/ETH 可用/冻结/折合估值与今日盈亏，确定性）+ `assets_screen.dart`（总资产卡大号等宽数字 + 今日盈亏正负着色 + 演示标注；充值/提现/划转 toast 占位；币种列表；账户区：已登录显示账户 ID + 退出，未登录显示登录/注册 CTA → /login）。不加路由守卫；/account 及既有守卫保留。底部导航 assetsTab 改指 /assets，AppShell 白名单 /assets→4。

## 数据策略

demo 数据（盘口/订单/仓位/资产）全部本地确定性生成、UI 标注“演示数据”、不进入任何 API 请求；真实目录继续走 spotMarketsProvider。注册/发码/国家列表为真实 v1 接口；不假成功。

## 验收

架构门禁、analyze、全部 75 项测试、原生依赖预检通过；注册校验纯函数、注册页全流程（禁用→可提交→成功自动登录跳账户/失败展示后端 message/倒计时）、登录页新交互、订单 tab 切换与演示标注、资产页渲染与未登录 CTA、注册页输入框 Android/iOS × 三语言长按选择菜单均有覆盖。模拟器截图验证由后续会话执行。

<!-- 2026-10-14 | 登录注册+订单仓位+资产页设计 | 用户确认范围；Google/MFA/忘记密码/真实资产订单 API 明确不做。 -->
