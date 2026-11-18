# Windows 原生轻量隔离当前状态

更新：2026-11-18。范围：绑定分支 `codex/windows-local-native`、离线构建产物 `CageLocal.exe`（由系统自带 `.NET Framework v4.0.30319 csc.exe` 编译）与 Phase 1 实测文件 [verification-phase1.json](verification-phase1.json)。使用说明与设计见 [README.md](README.md)。

> **路线独立原则**：本状态仅反映 `tools/windows-local/` 的 Windows 原生标准本地账户 + WFP 隔离路线，**不沿用** `tools/windows-lite/`（Sandboxie）或 `tools/windows-appcontainer/` 的任何通过结论。

## 总结论

第一阶段的离线报告记录了私有桌面的 18 项隔离断言、6 项宿主检查和 6 项核心应用检查通过，官方解包 Claude Desktop 能在私有桌面呈现主窗口。下表保留该次验证范围。

工作台原型使用现有专用账户，每次打开隔离会话均核对账户和七条 WFP 规则。PowerShell、Edge、VS Code、项目共享、Tailscale 与 Claude 账号页共用该绑定。未选择并应用 Cage 节点时，工作台保持离线。[启动说明](README.md#打开工作台原型)

本次在 Windows x64 上实际操作了隔离 Edge 的本地表单、在 VS Code 搜索框输入文字，并对临时空目录做了授权和撤销。在可见工作台里打开了截图对应的五个侧栏入口。账号页和隔离终端均能从官方 Claude Code 读取未登录状态。Tailscale 返回了实际版本和停用状态。入站 SSH 的用户名、地址和端口来自该节点。出站 SSH 使用系统 OpenSSH，已离线检查主机公钥校验、单节点代理转发和双向字节传输。

受控出口使用实际 Windows 命名管道和本机模拟上游验证了双向传输、无节点时阻断，以及停用后立即断流。节点与中转均需要公网 IPv4，可保留 TLS 域名。真实公网出口、Claude 登录及额度、Tailscale 入网和 SSH 登录仍需手动选择节点及授权。本轮使用的账户尚未安装 Claude Desktop。Linux 工作台包与 macOS 共用代理模块已交叉编译。macOS 工作台的两项依赖未在本机离线缓存中，完整编译未验证。macOS 与 Linux 本轮没有运行原生客户端验收。

2026-11-18 在可见的 Windows Edge 窗口中，从首次设置进入原图形工作台，刷新后仍显示项目侧栏。从首页「新建终端」打开 PowerShell 标签，`whoami.exe` 返回预置标准账户。连续输入验证了变量计算结果 42、相同的进程 ID 和切换后的工作目录。在隔离目录中写入一个临时文件，关闭标签后从新终端读回相同内容并清理了该文件。

2026-11-18 在 Windows x64 上用 Edge 进行了终端验收。同一页面连续执行两条命令，确认进程 ID 相同，先前设置的变量参与计算并返回 42。中文和标准错误均显示在页面，默认工作目录为专用账户下的 `AppData\LocalLow\CageTerminal`。对宿主开发目录测试文件的写入请求被拒绝。运行 60 秒等待命令时点击「关闭终端」，页面收到清理完成的通知并重新开放启动按钮。独立的工具验证也覆盖了 `exit`。此次复用了上一轮的 Windows 账户和网络规则。

2026-11-18 在 Windows x64 新建并保留了一个专用标准账户。以普通控制用户运行工作台，用 Edge 从首次设置页点击「试运行 PowerShell」，页面显示实际版本 `5.1.26100.9444`。该次调用读回 7/7 条 WFP 规则，验证 worker 和 PowerShell 进程的 SID 均匹配档案，完整性等级为 Medium。测试工作台按本次配置正常退出。macOS 和 Linux 没有启用此入口，两平台客户端本次未实测。

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
| 网络代理与断线保护 | 第一阶段验证了 PID 门禁和本地合成源站。工作台现接入 `internal/managedproxy`，离线验证了活动连接撤销 | 真实节点的出口、DNS、TLS 上游握手及高并发长连接场景尚未验收 |
| 一键部署与完整卸载脚本 | 已在当前测试机实测生效预置的部署产物与 7/7 WFP 规则；`Initialize-CageLocal.ps1` 与 `Teardown-CageLocal.ps1` 已完成代码实现 | 本轮无特权验证未调用 `-Elevate` 销毁并重新部署现役档案，现场提权部署/卸载闭环待后续人工窗口确认 |
| `grant-share` 权限护栏 | 已在 `verify-local.ps1` 实测针对验证夹具目录的 `rw` / `ro` / `revoke` 授权与撤销 | 拒绝 `<HOST_USERPROFILE>`、系统目录、`rootDir` 及 `ReparsePoint` 的负向分支尚未有独立自动化单测报告 |

### 3. 未通过

- **Phase 1 必选核心断言无未通过项**：[verification-phase1.json](verification-phase1.json) 中 `boundariesPassed: true`、`hostChecksPassed: true`、`coreAppsPassed: true`、`suiteExitCode: 0`。
- **已知实测行为差异**：如上表所示，Edge/Chromium 渲染器 JS 运行时未采用 `TZ=Asia/Tokyo` 环境变量而返回宿主系统时区 `Asia/Shanghai`；若 Phase 2 要求浏览器 JS 时区与出口时区一致，需单独处理（当前阶段记录为部分通过与已知差距，不掩盖结果）。

### 4. 未验证（待 Phase 2 实施或后续取证）

- **多会话支持**仍待实现。目前一次使用一个隔离会话。关闭终端后保留其工作目录。
- **真实在线与多应用日常工作流**：Claude Code / Desktop 真实登录与付费模型请求、VS Code 扩展与真实项目编辑、有头 Edge 完整浏览器操作、多会话并发共存、工作台内本机开发服务受控访问、以及受控主动剪贴板/文件上传下载通道均未验证。
- **全盘与非个人目录 ACL 审计**：本方案在共享宿主 Windows 上通过标准本地账户 ACL 隔离 `<HOST_USERPROFILE>` 与私有夹具目录，尚未对系统上其他非个人用户目录或全部系统服务做全盘遍历审计，不宣称与独立 Hyper-V 虚拟机等价。
