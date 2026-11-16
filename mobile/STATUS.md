# Android 开发状态

更新日期：2026-11-16（北京时间）。唯一长期开发分支：`codex/android`。

Android 远程客户端、Cage Open、GBox 定向修改和其他 Android 实验都在这条分支接续。
本文件统一记录当前结果、阻塞和下一步；各目录 README 保留构建方法，日期报告保留当时证据。
验证结论只属于对应产物、环境和读取路径，不能在不同路线之间沿用。

## 当前进展

| 路线 | 已完成或部分通过 | 未通过、未验证或暂停 |
| --- | --- | --- |
| Android 远程客户端 | 已合入上游 v0.1.8 同步记录，保留本地客户端的应用更新实现 | 本次仅整理分支与文档，没有新增客户端运行验证 |
| Cage Open `0.0.6-login-preview` | Android 16 真机 Google 测试账号登录及应用冷启动保留通过；原版商店下载并安装 Claude 的原签名分包通过；Google 登录结果回传已修复 | Claude `26111319` 仍返回 Play 验证失败、HTTP 400；尚未登录或发送消息 |
| Cage Open 隐私补丁 | 0.0.5 的 SIM、VPN 可见性、隧道元数据和东京时区在所测探针路径通过；0.0.6 保留策略代码，并观察到 Claude 进程内策略启用 | 0.0.6 未重跑整套探针；原生属性部分对照无有效读数；WebView 首脚本跨进程保证、断线保护、raw syscall/netlink、显式子进程环境仍未验证 |
| GBox 真机路线 | Checks02 保留原登录态与测试标记；SIM/VPN 及隧道元数据的所测路径通过；11-16 独立对照以同版 Claude 新登录成功 | Checks02 的 WebView 首脚本时区未通过；非隧道信息隔离部分完成；真机断线保护未验证。独立登录对照不替代 Checks02 的隐私验收 |
| MuMu / 官方 Android 模拟器 | 已保存诊断、失败对照和源码 | MuMu GBox 路线暂停；已测完整性组合及 Claude 登录未达标，不继续重试 |

## 当前阻塞与证据

- **Cage Open 登录仍未修通。** 同版 Claude 的独立 GBox 无调试新登录成功，Cage 同期对照仍失败。
  最新 GBox 成功路径采到本地 Embedded DroidGuard 初始化、Classic 令牌返回及 Google 凭据交付。
  令牌长度差异不是解码判定；尚未隔离具体失败原因，也没有 Claude 项目的令牌解码结果。
- **失败候选已恢复。** 算法注册、隐私模块开关、配置字段和服务上下文等定向对照均未修通登录；
  不能把配置生效、取得令牌或 Google 账号登录记作 Claude 登录通过。
- **隐私验收未完成。** 已确认范围包括 SIM/运营商、双卡/eSIM、驻留网络/基站、VPN/本机地址、
  系统/应用标识、首次读取/传出字段、WebView 时区、实际出口/断线保护。
  具体范围与通过条件见[补丁验收范围](sandbox/gbox-mod/PRIVACY-REVIEW-2026-11-15.md#补丁验收范围)。
  Cage Open 已接入其中部分能力，其结果按上表单独归属；GBox 的剩余项继续保留。

## 下一步

1. 在独立测试副本内做 Google 服务组件交叉对照，区分服务实现和容器行为；保留现有 GBox 登录会话与来宾数据。
2. 按已确认的补丁验收范围补齐剩余项，逐项记录通过、未通过和未验证；保留原签名、登录与数据。
3. 取得新证据后直接更新本文件，并链接对应报告；日期报告不再承载未来安排。

手机全局网络设置限制和 MuMu 暂停状态继续有效。本次整理没有操作设备、重新登录、构建 APK 或发版。

## 证据入口

- Cage Open：[构建说明](open-cage/README.md)、[最新定向对照](open-cage/BUNDLED-TESTING.md)、
  [登录记录](open-cage/validation-login-2026-11-16.json)、[成功路径对照](open-cage/validation-success-path-2026-11-16.json)、
  [0.0.5 隐私结果](open-cage/validation-privacy-2026-11-16.json)、[商店与完整性结果](open-cage/validation-store-2026-11-16.json)。
- GBox：[真机阶段记录](PHONE-GBOX-VALIDATION-2026-11-15.md)、[隐私风险与验收条件](sandbox/gbox-mod/PRIVACY-REVIEW-2026-11-15.md)。
- 历史：[11-15 GBox / MuMu 交接归档](HANDOFF-2026-11-15.md)、[模拟器对照](EMULATOR-VALIDATION-2026-11-15.md)、
  [11-14 microG 分析](ANDROID-ANALYSIS-2026-11-14.md)、[GBox 架构分析](GBOX-REA-ANALYSIS-2026-11-15.md)。

## 分支归并记录

2026-11-16 将以下旧分支汇入 `codex/android`，清理旧分支引用。对应提交均保留在主干历史中，可按提交恢复引用。

| 旧分支 | 归并前提交 |
| --- | --- |
| `codex/android-microg-checkpoint-20261114` | 远端 `448eab7`；本地上游同步后为 `633bc67` |
| `codex/gbox-privacy-review-20261115` | `448eab7`（与旧 microG 远端同一提交） |
| `codex/android-experiments-20261115` | `82c6786` |
| `codex/android-open-source-rebuild-20261115` | `d72a5fa` |
| `codex/android-adb-progress-20261116` | `4cf86e7` |
| `docs/gbox-rea-analysis-20261115` | `5f72f62` |

历史中的同名 checkpoint 来自变基前后保留的两套提交，旧历史已在 `2e83b7c` 合并。
本次直接归并现存历史，不重复应用这些补丁。后续日常进展直接提交到 `codex/android`，不再按日期或实验名新建 checkpoint 分支。
