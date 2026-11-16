# Flysky701 开发进度

更新日期：2026-11-17（北京时间）。本页汇总本 Fork 的 Windows 修复、共享功能修复及 Android 实验进展。
Android 的逐项状态与下一步统一维护在 [mobile/STATUS.md](../mobile/STATUS.md)，后续在长期分支 `codex/android` 接续。

## 当前阶段

- Windows 及共享功能：五项独立修复已推送并提交上游 Contribution Issue，均为待审核状态，尚未创建对应 PR。
- Android：Cage Open 已完成 Google 测试账号登录、冷启动保留，以及原版商店下载并安装 Claude；Claude 登录仍未通过。
- Android 已补齐 GBox 实际 KeyStore 注册链、零命中原因及后续失败对照；Cross 保留 integration2，尚未定位登录拒绝的具体原因。隐私与断线保护的验收范围没有扩大。

## Windows 与共享功能

下表验证结果沿用各贡献 Issue 的已有记录；本次整理没有重新运行开发测试。
2026-11-17 再次核对，五个 Issue 均为 open，尚无 `accepted` 标签；未发现这五项修复的对应 PR。

| 修复 | 已记录的验证 | 待完成与提交入口 |
| --- | --- | --- |
| Windows 安装器拒绝 `/D=` 后续参数污染目录 | 14 项参数测试及 NSIS 3.13 脚本编译通过；Windows 安装、升级已确认通过 | 其他 Windows 版本及 NSIS 3.11 未测；[贡献 #352](https://github.com/Lee-xeo/Claude-Cage/issues/352)，提交 [`c50be19`](https://github.com/Flysky701/Claude-Cage/commit/c50be196730b417eb0de4726f2786e0aec9fe131) |
| Trojan 明文与 Base64 订阅导入 | 定向测试、原有 YAML 兼容、Mihomo 配置校验及前端检查通过；Windows 实际导入、应用与联网通过 | macOS/Linux 真机及完整发布构建未测；[贡献 #353](https://github.com/Lee-xeo/Claude-Cage/issues/353)，提交 [`37394c5`](https://github.com/Flysky701/Claude-Cage/commit/37394c5341352b57df7ea4870c5bee10676b6342) |
| code-server 首次查询过滤初始化日志 | 4 个定向用例通过，覆盖实际版本、初始化日志、无版本及失败输出 | 真实 Linux 客机首次运行、macOS/Linux 主机未测；[贡献 #359](https://github.com/Lee-xeo/Claude-Cage/issues/359)，提交 [`166bf09`](https://github.com/Flysky701/Claude-Cage/commit/166bf09e1b24263cb99b8a0dd438126818d764c2) |
| 单节点应用保留订阅内置中转并显示实际链路 | 代理路由定向测试、Windows Edge 界面对照、前端构建及改动文件检查通过 | 真实订阅联网及 macOS/Linux 未测；[贡献 #360](https://github.com/Lee-xeo/Claude-Cage/issues/360)，提交 [`ad93911`](https://github.com/Flysky701/Claude-Cage/commit/ad9391178196538f8bea41aba1718b769e654683) |
| 未签名 Windows 构建在下载前提示手动升级 | 更新器定向测试和 Windows Edge 界面测试通过；实际未签名程序确认未触发安装包下载 | 正式签名包的完整升级与回滚未验收；[贡献 #361](https://github.com/Lee-xeo/Claude-Cage/issues/361)，提交 [`e69ad4e`](https://github.com/Flysky701/Claude-Cage/commit/e69ad4eb4bd5bd9326e46609441e42d9579de6b2) |

另有两项实现已保存在 [Windows 汇总分支](https://github.com/Flysky701/Claude-Cage/tree/codex/261116-Flysky701-windows-cache-fixes)：

- 缓存恢复目录只写入 DACL，避免改写所有者和审计信息：[`bb59b2b`](https://github.com/Flysky701/Claude-Cage/commit/bb59b2b3b9d37c828b141c8f24b7bfc1fe5c8a4e)，关联 [#303](https://github.com/Lee-xeo/Claude-Cage/issues/303)。
- 云部署核心下载支持缓存与续传：[`bf2c959`](https://github.com/Flysky701/Claude-Cage/commit/bf2c9598ca4d4616ffb3bf7a2f2bb4a82159bdc2)，关联 [#279](https://github.com/Lee-xeo/Claude-Cage/issues/279)。

这两项包含对应测试修改；本次未重新运行，也未确认独立贡献审核状态。

Windows Lite 的既有定向结果与使用限制见 [README](../tools/windows-lite/README.md)。
它已验证所列 x64 程序的同步 DNS、东京时间及固定目标 TCP 转发；任意目的地址透明代理、异步 DNS 和完整内核网络拦截仍不在已测范围内。

## Android

以下结果分别属于对应产物及环境；详细证据见 [Android 状态](../mobile/STATUS.md)。

| 路线 | 已完成或部分通过 | 当前限制 |
| --- | --- | --- |
| Android 远程客户端 | 已同步上游 v0.1.8，保留本地客户端更新实现 | 本次未新增客户端运行验证 |
| Cage Open `0.0.6-login-preview`，Android 16 arm64 真机 | Google 测试账号登录及冷启动保留通过；商店下载、安装 Claude 原签名分包通过；Google 登录结果回传已修复 | Claude `26111319` 仍为 Play 验证失败、HTTP 400；尚未登录或发送消息 |
| 独立 Cross 组件对照 | 同款 MG/MGC、原版 Claude、本地 DroidGuard 及 Google 凭据回传链路已完成；maps 与平台 KeyStore 预探测等候选已结束 | 11-17 00:13 仍为 1446 字符令牌、HTTP 400；请求鉴权与 GSF ID 的运行时状态未知 |
| 隐私补丁 | 0.0.5 的 SIM、VPN 可见性、隧道元数据和东京时区在所测路径通过；0.0.6 保留策略代码，并观察到 Claude 进程内启用 | 0.0.6 未重跑整套探针；WebView 首脚本跨进程保证、断线保护等仍未验证 |
| GBox 真机对照 | 所测 SIM/VPN 和隧道元数据通过；11-16 22:21 同版 Claude 无调试登录成功；后续原数据已归位并恢复已登录主页 | Checks02 的 WebView 首脚本时区未通过；非隧道信息隔离部分完成，真机断线保护未验证；独立登录对照不替代这些验收 |
| MuMu / 官方 Android 模拟器 | 已保存失败对照和诊断记录 | MuMu GBox 路线暂停；已测组合未达到 Claude 登录目标 |

### 最新实验与阻塞

- 11-16 21:12 的 Cross 基线仍为 HTTP 400，返回 `missing_client_attestation`。凭据绑定证明开关的准备工作在执行前停止，没有新增登录请求或应用数据修改，详见 [记录](../mobile/open-cage/validation-credential-attestation-2026-11-16.json)。
- 11-16 22:02 的宿主 APK maps 路径对照确实生效：3 次读取、72 行处理、0 次回退；实际 Claude 登录仍失败，令牌各段尺寸与基线一致。候选已结束并恢复 integration2，详见 [记录](../mobile/open-cage/validation-maps-2026-11-16.json)。
- **KeyStore 零命中原因已确认。** 11-16 22:21 无调试登录成功后，只读快照确认 GBox 注册链为 microG blocker → GBox `o7` → 系统 `AndroidKeyStoreSpi`，GMS 掩码为 1、未设 bit 2。另一次诊断请求在 EC 生成器查找处抛出 `NoSuchAlgorithmException`，尚未进入密钥生成或证书读取。该结论解释了本次零命中，不能推出 Cross 登录失败的根因，详见 [记录](../mobile/open-cage/validation-gbox-keystore-live-2026-11-16.json)。
- **平台 KeyStore 预探测未修通，已撤回。** 11-16 23:47 的候选完成平台 EC 探测及临时密钥清理，仍为 1446 / HTTP 400；它未完整复现 GBox 更早的初始化时序。本轮不追加时序变体，已恢复 integration2。GBox 原数据已归位，普通无调试登录已恢复主页；没有合入新的运行时补丁，详见 [同一记录](../mobile/open-cage/validation-gbox-keystore-live-2026-11-16.json)。
- **Classic 请求输入仍未知。** 11-17 00:10、00:13 两次观察均未捕获目标 POST，不能判断 Play OAuth 鉴权或 GSF 设备 ID 是否缺失；两次实际登录仍为 1446 / HTTP 400。观察已结束并完成清理，没有据此改动账号或设备登记，详见 [记录](../mobile/open-cage/validation-classic-request-inputs-2026-11-17.json)。
- 自有探针对照的两边判定相同，不能替代真实 Claude 的成功与失败对照；采样覆盖与 seccomp 语义仍有限制，详见 [记录](../mobile/open-cage/validation-native-queries-2026-11-16.json)。
- Claude 令牌的服务端判定仍未解码；现有证据尚未支持新的具体修复点。令牌总长度、VM 输出长度和 Google 账号登录均不能单独证明 Claude 登录或完整性验收通过。

## 接续安排

1. Windows：等待五项贡献方案审核；按维护者意见补充对应验证，再进入 PR 流程。
2. Android：保留 integration2、GBox 已恢复的会话及原数据。KeyStore 零命中问题已解释，平台预探测与请求头观察已结束；只有新的实际请求证据支持具体差异时才进入下一次修改。主线验收仍为原版 Claude 实际登录成功，当前未达到。
3. 隐私补丁继续按 [验收范围](../mobile/sandbox/gbox-mod/PRIVACY-REVIEW-2026-11-15.md#补丁验收范围)逐项记录产物、环境、路径和结论；Google/Claude 登录与隐私验收分别判定。

本次同步范围为进度文档与脱敏结构化记录，不包含 APK、签名密钥、账号凭据、代理配置或设备原始日志。
