# Windows 原生轻量隔离当前状态

更新：2026-11-18。范围：绑定分支 `codex/windows-local-native`、离线构建产物 `CageLocal.exe`（由系统自带 `.NET Framework v4.0.30319 csc.exe` 编译）与 Phase 1 实测文件 [verification-phase1.json](verification-phase1.json)。使用说明与设计见 [README.md](README.md)。

> **路线独立原则**：本状态仅反映 `tools/windows-local/` 的 Windows 原生标准本地账户 + WFP 隔离路线，**不沿用** `tools/windows-lite/`（Sandboxie）或 `tools/windows-appcontainer/` 的任何通过结论。

## 总结论

**Phase 1 独立隔离底座与核心应用兼容基线已通过实测**：离线构建与自检通过（`SELFTEST_PASS`），无特权验证在 `PrivateCreateDesktop` 私有桌面模式下通过全部 18 项边界断言（`boundariesPassed: true`）、全部 6 项宿主完整性/零残留检查（`hostChecksPassed: true`，`lingeringWorkerProcesses: 0`）及全部 6 项核心应用检查（`coreAppsPassed: true`），官方解包 Claude Desktop 也在私有桌面内启动并呈现主窗口。**Phase 2（接入 Cage 工作台 `mode: "local"`）及完整在线业务链路尚未实施，状态为“未验证”。**

## 分类状态明细

### 1. 已完成（Phase 1 已取得通过证据）

| 项目 | 实测结果与范围 | 证据 |
| --- | --- | --- |
| 离线编译与内建单元自检 | `build.ps1` 编译 7 个 C# 源文件输出 `CageLocal.exe`（退出码 `0`）；`selftest` 通过 `wfp_key_derivation`、`dpapi_roundtrip_and_entropy`、`controller_only_acl`、`quoting_and_constant_time`、`broker_pid_gate_and_tunnel` 共 5 项断言，输出 `SELFTEST_PASS` | `build.ps1`、`LocalSelfTest.cs` |
| WFP 7 条规则与隔离档案读回 | 使用本机已预置隔离档案（标准本地账户 `CageLocal_e92f6fc5`，所属 `Users`，`integrityLabel: Medium` / `0x2000`），回读校验 7/7 条持久化 `ALE_USER_ID` 过滤规则全部就绪（`allVerified: true`：`connect-v4/v6`、`receive-v4/v6`、`udp-bind-v4/v6` 阻断，仅 `broker-connect-v4` 放行 `127.0.0.1:17981`） | [verification-phase1.json](verification-phase1.json) `wfpProvisionReceipt`、`workerInspect` |
| 无特权文件系统与注册表边界 | worker 无法列举 `<HOST_USERPROFILE>`（`5`）、无法读取宿主私有文件（`5`）和 `worker.dpapi`（`5`）；显式 `rw` 共享读写双向可见，`ro` 共享可读但写拒绝（`5`）；worker 仅写入自身独立 `HKCU`，测试前后宿主私有文件与宿主 `HKCU` 未改变 | [verification-phase1.json](verification-phase1.json) `boundaries`、`hostChecks` |
| 内核网络阻断、PID 门禁与断线闸门 | 直连 IPv4 TCP、IPv6 TCP、UDP 及其他宿主回环端口均返回 `WSAEACCES (10013)` 且宿主私有监听无挂起连接；非 worker 宿主进程访问 Broker 被拒（`nonWorkerBrokerRejected: true`，`rejectedCallerCount: 2`）；Broker HTTP `200` 与 `CONNECT` 隧道往返通过；关闭闸门返回 `503`（`blockedByGateCount: 1`），重开后恢复 `200`（`killSwitchPassed: true`） | [verification-phase1.json](verification-phase1.json) `boundaries`、`brokerStats` |
| 私有桌面、临时对象授权与零残留清理 | `PrivateCreateDesktop` 私有桌面运行；向 `WinSta0`（保持省略 `WINSTA_ACCESSCLIPBOARD`）、私有桌面、`\Sessions\<id>\BaseNamedObjects`、`\Sessions\<id>\AppContainerNamedObjects` 与 `\Device\NamedPipe\Sessions\<id>\AppContainerNamedObjects` 临时授予并恢复 `workerSid` + `workerLogonSid` DACL；退出后 `lingeringWorkerProcesses: 0` | [verification-phase1.json](verification-phase1.json) `desktopMode`、`hostChecks` |
| Claude Code CLI（Ring-1） | 位于受控标准用户会话运行 `--version`，输出 `2.1.296 (Claude Code)`，`exitCode: 0`，耗时 `874 ms`（仅版本检查，非联网登录或对话） | [verification-phase1.json](verification-phase1.json) `apps.ClaudeCodeRing1` |
| Claude Code CLI（Ring-2 AppContainer） | 在 worker 内创建零网络 capability（`capabilityCount: 0`、`isAppContainer: true`、`integrityLabel: Low` / `0x1000`）AppContainer 启动 `--version`，输出 `2.1.296 (Claude Code)`，`exitCode: 0`，隔离 Ring-1 私有夹具路径 | [verification-phase1.json](verification-phase1.json) `apps.ClaudeCodeRing2AppContainer` |
| Node 共享目录与环境边界 | Node `v24.21.0` 在 `shared-rw` 执行，验证 `realpath`、拒绝读取宿主私有文件（`privDenied: true`）、拒绝写入 `shared-ro`（`roWriteDenied: true`）、`rw` 写入成功且 `Intl` 时区为 `Asia/Tokyo`，输出 `CAGE_LOCAL_NODE_PASS`，`exitCode: 0` | [verification-phase1.json](verification-phase1.json) `apps.NodeSharedDDrive` |
| VS Code CLI 与 GUI 沙箱 | `VSCodeCli` 输出 `1.144.0`（`exitCode: 0`）；`VSCodeGuiSandbox` 在私有桌面 `observe-gui` 模式下启动，`1390 ms` 检测到可见主窗口（`1215x810`，标题 `editor-check.txt - Visual Studio Code`），峰值 `13` 个 Job 子进程且观察期末存活，`JobObject` 清空后 `0` 残留 | [verification-phase1.json](verification-phase1.json) `apps.VSCodeCli`、`apps.VSCodeGuiSandbox` |

### 2. 部分通过（仅验证限定测试路径，未覆盖完整生产场景）

| 项目 | 已通过部分 | 尚未覆盖 / 已知限制 |
| --- | --- | --- |
| Edge 无头沙箱与 `HKCU` 代理 | `EdgeHeadlessSandboxAndHkcuProxy` 在 `--headless=new --disable-gpu --disable-features=HttpsFirstBalancedModeAutoEnable,HttpsUpgrades` 下通过 worker `HKCU` 代理（`127.0.0.1:17981`）获取本地合成页面并输出 `CAGE_LOCAL_EDGE_PROXY_OK`（`exitCode: 0`，`1963 ms`） | 页面内 JS `Intl.DateTimeFormat().resolvedOptions().timeZone` 仍读回宿主系统时区 `Asia/Shanghai`（未跟随环境变量 `TZ=Asia/Tokyo`）；未验证有头浏览器交互、多标签页、扩展、下载及真实 HTTPS/TLS 上游 |
| Claude Desktop（官方解包） | `ClaudeDesktopSandbox` 在私有桌面内启动（`observe-gui`），`9287 ms` 检测到主窗口（`614x609`，标题 `Claude`），观察期末存活（`stillAliveAtEnd: true`，峰值 `7` 个进程，`exitCode: 0`），清理后无残留 | 仅完成冷启动与主窗口拉起观测；未验证真实账户登录、Chat/Code 交互、文件附件/下载、剪贴板传递与 Cowork 服务 |
| 网络代理与断线保护 | `LocalProxyBroker` 已验证 PID 门禁、本地合成源站 HTTP `GET` / `CONNECT` 往返及 `SetGateOpen(false)` 立即断流 | 尚未接入 Cage `internal/managedproxy` 真实上游链路、受控 DNS 解析、TLS 上游握手及高并发长连接场景 |
| 一键部署与完整卸载脚本 | 已在当前测试机实测生效预置的部署产物与 7/7 WFP 规则；`Initialize-CageLocal.ps1` 与 `Teardown-CageLocal.ps1` 已完成代码实现 | 本轮无特权验证未调用 `-Elevate` 销毁并重新部署现役档案，现场提权部署/卸载闭环待后续人工窗口确认 |
| `grant-share` 权限护栏 | 已在 `verify-local.ps1` 实测针对验证夹具目录的 `rw` / `ro` / `revoke` 授权与撤销 | 拒绝 `<HOST_USERPROFILE>`、系统目录、`rootDir` 及 `ReparsePoint` 的负向分支尚未有独立自动化单测报告 |

### 3. 未通过

- **Phase 1 必选核心断言无未通过项**：[verification-phase1.json](verification-phase1.json) 中 `boundariesPassed: true`、`hostChecksPassed: true`、`coreAppsPassed: true`、`suiteExitCode: 0`。
- **已知实测行为差异**：如上表所示，Edge/Chromium 渲染器 JS 运行时未采用 `TZ=Asia/Tokyo` 环境变量而返回宿主系统时区 `Asia/Shanghai`；若 Phase 2 要求浏览器 JS 时区与出口时区一致，需单独处理（当前阶段记录为部分通过与已知差距，不掩盖结果）。

### 4. 未验证（待 Phase 2 实施或后续取证）

- **Phase 2 Cage 工作台 `mode: "local"` 接入（待实施 / 未验证）**：`internal/guestos/windows_profile.go`、`internal/workbench/server.go`、`runtime.go`、`windows_guest.go`、`windows_safety.go`、`windows_projects.go`、`windows_cli.go`、`windows_browser.go` 与 `scripts/guest-os/guest-clipboard-windows/`（`Program.cs`、`LocalGuestTransport.cs`）尚未接入 `CageLocal.exe`。
- **真实在线与多应用日常工作流**：Claude Code / Desktop 真实登录与付费模型请求、VS Code 扩展与真实项目编辑、有头 Edge 完整浏览器操作、多会话并发共存、工作台内本机开发服务受控访问、以及受控主动剪贴板/文件上传下载通道均未验证。
- **全盘与非个人目录 ACL 审计**：本方案在共享宿主 Windows 上通过标准本地账户 ACL 隔离 `<HOST_USERPROFILE>` 与私有夹具目录，尚未对系统上其他非个人用户目录或全部系统服务做全盘遍历审计，不宣称与独立 Hyper-V 虚拟机等价。
