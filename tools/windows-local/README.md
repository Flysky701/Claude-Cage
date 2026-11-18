# Windows 原生轻量隔离（Phase 1：`CageLocal.exe`）

本目录实现了 Cage 的 **Windows 原生轻量隔离底座（Phase 1）**：不依赖 Hyper-V 虚拟机、Sandboxie、闭源内核驱动或第三方商业软件，完全基于 100% 开源（MIT）代码与 Windows 系统内置安全机制构建独立执行边界，并通过 `verification-phase1.json` 完成离线编译、内核网络隔离、私有桌面、应用兼容与 Zero-Leak 清理验证。

> 当前状态与已测/未测范围见 [STATUS.md](STATUS.md)，最新 Phase 1 实测报告见 [verification-phase1.json](verification-phase1.json)。**Phase 2（接入 Cage 工作台 `mode: "local"`）尚未实施，当前处于未验证状态。**

## 架构分层

```text
+-------------------------------------------------------------------------+
| 控制器进程（普通宿主用户权限，例如未来 Cage Workbench / 当前 CLI）         |
|  - 解密 worker.dpapi（DPAPI + 实例/SID 绑定 Entropy）                    |
|  - LocalProxyBroker（127.0.0.1:17981，GetExtendedTcpTable PID 门禁 + 闸门）|
|  - CreateProcessWithLogonW + 私有 Win32 桌面 + JobObject（关闭即销毁）     |
|  - 临时授权/恢复 WinSta0、私有桌面、Session 对象目录与 NamedPipe 目录 DACL  |
+------------------------------------+------------------------------------+
                                     | 加密认证命名管道（拒绝 NetworkSid）
                                     v
+-------------------------------------------------------------------------+
| Ring-1 隔离会话（独立标准本地账户 CageLocal_<id>，无管理员权限）           |
|  - 独立 %USERPROFILE% 与 HKCU 注册表（写入隔离代理 127.0.0.1:<port>）      |
|  - 7 条持久化内核 WFP ALE_USER_ID 规则：阻断直连 v4/v6 TCP/UDP，仅放行 Broker|
|  - 独立私有桌面（S:(ML;;NW;;;LW)）与省略 WINSTA_ACCESSCLIPBOARD 的 WinSta0 |
|  - 显式目录共享（grant-share：ro / rw / revoke）与最小环境变量白名单         |
+------------------------------------+------------------------------------+
                                     | 可选二次收口（PROC_THREAD_ATTRIBUTE_*）
                                     v
+-------------------------------------------------------------------------+
| Ring-2 AppContainer（可选低完整性容器，capabilityCount = 0）              |
|  - 临时创建零网络 capability 的 AppContainer（Integrity: Low / 0x1000）   |
|  - 仅挂载 staging tools（只读执行）与独立 work/Temp，不可读 Ring-1 私有目录 |
+-------------------------------------------------------------------------+
```

## 使用的 Windows 内置机制与源码组成

本方案全部源码位于 `tools/windows-local/`，使用 Windows 自带 `.NET Framework 4` x64 C# 编译器（C# 5 语法）编译，遵循仓库根目录 MIT 协议：

| 文件 | 职责与对应 Windows 原生机制 |
| --- | --- |
| [LocalProfile.cs](LocalProfile.cs) | Profile 模型（`schema = 1`）、DPAPI（`crypt32.dll` `CryptProtectData` / `CryptUnprotectData` + SHA-256 绑定 Entropy）、仅控制者可读文件 ACL、重解析点校验与常量时间比较 |
| [LocalWfpPolicy.cs](LocalWfpPolicy.cs) | 内核 WFP 引擎（`fwpuclnt.dll`）创建持久化子层与 7 条绑定 `workerSid` 的 `ALE_USER_ID` 规则：`connect-v4/v6`、`receive-v4/v6`、`udp-bind-v4/v6` 全阻断，仅 `broker-connect-v4` 放行 `127.0.0.1:<brokerPort>` TCP |
| [LocalProvisioner.cs](LocalProvisioner.cs) | 一次性账户与目录部署（`netapi32.dll` 创建仅属 `Users` 的标准本地账户、Winlogon 登录界面隐藏）、`teardown` 完整回收（`DeleteProfile` + `NetUserDel` + WFP 清理）、无特权 `grant-share` 显式读写授权与路径护栏 |
| [LocalProxyBroker.cs](LocalProxyBroker.cs) | 回环 HTTP / `CONNECT` 代理门禁：通过 `iphlpapi.dll` `GetExtendedTcpTable` 反查连接所属 PID 并核验是否属于当前会话 JobObject；支持 `SetGateOpen(false)` 立即断开活跃套接字并返回 `503` |
| [LocalWorkerDaemon.cs](LocalWorkerDaemon.cs) | `CreateProcessWithLogonW` 会话托管、`CreateDesktop` 私有桌面、`JobObject`（`JobLimitKillOnJobClose` + `WaitForJobDrain`）、`HKCU` 隔离代理、`workerLogonSid`（`S-1-5-5-...`）会话对象目录与命名管道目录临时 DACL 授权/恢复，以及 `WorkerRing2Exec` 低完整性 AppContainer 执行 |
| [LocalSelfTest.cs](LocalSelfTest.cs) | 离线自检（WFP 键值派生、DPAPI 往返与篡改拒绝、文件 ACL、参数转义、Broker PID 门禁与 `CONNECT` / Kill-Switch 单元测试） |
| [Program.cs](Program.cs) | CLI 子命令入口（`selftest` / `provision` / `teardown` / `grant-share` / `worker-daemon` / `run-suite`）与 Phase 1 验证套件调度 |

## 离线构建与日常操作

所有命令在普通 Windows x64 PowerShell 下从仓库根目录执行。

### 1. 离线构建与单元测试（普通权限）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\windows-local\build.ps1
```

- 调用系统自带 `%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe`（`/target:exe /platform:x64 /optimize+ /unsafe /r:System.Web.Extensions.dll`）生成 `tmp/windows-local/CageLocal.exe`。
- 编译后自动运行 `CageLocal.exe selftest`，5 项单元自检全部通过时输出 `SELFTEST_PASS`。

### 2. 一次性管理员初始化（仅首次部署需 UAC）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\windows-local\Initialize-CageLocal.ps1 -Elevate
```

- 若目标 profile（默认 `tmp/windows-local/profile/local-profile.json`）已存在则直接读回并退出，不重复创建。
- 提权阶段执行 `CageLocal.exe provision`，完成本地标准账户创建、Winlogon 隐藏、目录与 DPAPI 凭据初始化、以及 7 条持久化 WFP 规则安装与回读校验（默认 broker 端口 `17981`）。

### 3. 日常无特权隔离与兼容验证（无需管理员）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\windows-local\verify-local.ps1
```

- 全程在**当前普通用户权限**下运行；若 `tmp/windows-local/CageLocal.exe` 与部署目录 `binDir` 中副本哈希不一致，自动同步更新。
- 默认启用 `PrivateCreateDesktop`（独立私有桌面，支持可选 `-UseDefaultDesktop` 开关对照）。
- 依次验证：18 项文件/注册表/WFP 网络/Broker PID/Kill-Switch 边界检查、Ring-1/Ring-2 CLI、Node 共享目录与 `TZ`、Edge 无头沙箱经 `HKCU` 代理访问、VS Code CLI 与 GUI、官方解包版 Claude Desktop 启动观测，以及结束后 0 残留进程与宿主 `HKCU` 未受污染校验。
- 脱敏报告输出至 [verification-phase1.json](verification-phase1.json)；未脱敏的原始夹具与诊断报告仅留在 `tmp/windows-local/verify-<id>/` 下（不纳入版本控制）。

### 4. 显式共享授权与撤销（普通权限）

```powershell
.\tmp\windows-local\CageLocal.exe grant-share --profile .\tmp\windows-local\profile\local-profile.json --target <项目目录> --access ro
.\tmp\windows-local\CageLocal.exe grant-share --profile .\tmp\windows-local\profile\local-profile.json --target <项目目录> --access rw
.\tmp\windows-local\CageLocal.exe grant-share --profile .\tmp\windows-local\profile\local-profile.json --target <项目目录> --access revoke
```

- `ro` 授予 `ReadAndExecute` 并显式添加 `Write` / `Delete` 拒绝 ACE；`rw` 授予 `Modify`；`revoke` 清除该 worker SID 的全部授权规则。
- 内置路径护栏：拒绝盘符根路径、宿主用户个人目录（`<HOST_USERPROFILE>`）及其子目录、`%WINDIR%` 子目录、`CageLocal` 控制根 `rootDir` 及其子目录，以及目录树上的任何 `ReparsePoint`（符号链接/联接点）。

### 5. 完整卸载清理（需 UAC）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\windows-local\Teardown-CageLocal.ps1 -Elevate
```

- 终止归属 `workerSid` 的所有存活进程、删除 7 条 WFP 过滤规则与子层、恢复登录显示设置、调用 `DeleteProfile` 与 `NetUserDel` 删除账户与用户目录，并清除 `rootDir` 与 profile 文件。

## 安全与隐私模型

1. **身份与凭据隔离**：worker 仅隶属标准 `Users` 组，绝不加入 `Administrators`；随机密码经 DPAPI（绑定实例与双方 SID 的 SHA-256 Entropy）封装为仅控制者、`SYSTEM`、`Administrators` 可读的 `worker.dpapi`，worker 进程自身返回 `ERROR_ACCESS_DENIED (5)`。
2. **宿主数据与注册表保护**：worker 无权列举 `<HOST_USERPROFILE>` 或读取控制者私有文件（实测错误码 `5`）；应用配置写入独立 `HKCU` 与 `<WORKER_USERPROFILE>`，宿主 `HKCU` 代理与系统时区保持不变。
3. **内核网络与回环门禁**：7 条 `ALE_USER_ID` 规则按 `workerSid` 在内核态阻断直连 IPv4/IPv6 TCP、UDP 及其他宿主回环服务（实测 `WSAEACCES 10013`），仅放行 `127.0.0.1:<brokerPort>`；Broker 再按 `dwOwningPid` 核验连接归属当前会话 `JobObject`，且关闭闸门后立即切断活跃会话。
4. **会话边界与对象清理**：默认使用独立私有桌面并省略 `WinSta0` 的 `WINSTA_ACCESSCLIPBOARD` 权限；针对跨用户 `CreateProcessWithLogonW` 在交互会话中所需的 `WinSta0`、`\Sessions\<id>\BaseNamedObjects`、`\Sessions\<id>\AppContainerNamedObjects` 与 `\Device\NamedPipe\Sessions\<id>\AppContainerNamedObjects` 临时权限（同时覆盖 `workerSid` 与临时登录会话 `workerLogonSid`），均在 `LocalWorkerSession.Dispose()` 时恢复为会话前原 DACL；`WaitForJobDrain` 确保退出时 `lingeringWorkerProcesses == 0`。
5. **报告脱敏**：`verify-local.ps1` 中的 `Protect-VerificationJson` 会在生成 [verification-phase1.json](verification-phase1.json) 前剥离 `hostStateBefore`/`hostStateAfter` 并替换宿主用户名、机器名、`S-1-5-21-...` SID、宿主与 worker 本地路径及工作区绝对路径，确保仓库文档与验证文件不泄露主机隐私。

## Phase 2：接入 Cage 工作台（`mode: "local"`）实施规划

以下为后续在分支或工作台主干接入 `mode: "local"` 的具体落点（**当前尚未实现与验证**）：

1. **Profile 识别与命令分流（`internal/guestos/windows_profile.go`）**
   - 扩展 `WindowsProfile.Mode` 校验（目前仅允许 `""` / `"hyperv"` / `"remote"`），新增 `"local"` 与 `func (p *WindowsProfile) Local() bool`。
   - `local` 绑定使用已有的 `VMID`（对应 `instanceId`）、`GUIUserSID`（对应 `workerSid`）、`GUIUser`（对应 `workerUsername`）、`InstanceDirectory`（`rootDir`）、`RelayExecutable` 与 `PairingFile`（`worker.dpapi` / `local-profile.json`），不要求 Hyper-V `MachineID` 或 `NetworkPairingFile`。
   - 在 `WindowsRelayCommand` 中为 `p.Local()` 接入受控操作路由，保持路径参数只通过 `stdin` 传递、不经命令行暴露凭据。
2. **服务器状态与生命周期（`internal/workbench/server.go`、`runtime.go`、`windows_guest.go`）**
   - 在 `server.go` 中识别 `s.windowsGuest.Local()`，对外暴露对应的 `guest_system` 与能力矩阵。
   - 在 `runtime.go`（`environmentPrepared`、`attach`、`startEnvironment`、`stopEnvironment`、`apply`）与 `windows_guest.go`（`windowsStatus`、`attachWindowsGuestContext`、`startWindowsGuest`、`stopWindowsGuest`、`windowsCapabilitiesLocked`）增加 `Local()` 分支：
     - 跳过 `guestos.InspectHyperV`（Hyper-V 二代机、SecureBoot、vTPM、零网卡检查）及云端 `appcontainer-headless` / Session 0 校验；
     - 改为核验本地 `LocalProfileModel`、DPAPI/ACL 完整性、WFP 7/7 规则状态（`allVerified`）与 `LocalWorkerSession` 会话健康度；
     - 能力状态按实际已接入组件逐步放开，未接入项保持不可用。
3. **项目授权与工作台组件 RPC 复用（`internal/workbench/windows_projects.go`、`windows_cli.go`、`windows_terminal.go`、`windows_browser_client.go`、`scripts/guest-os/guest-clipboard-windows/`）**
   - **项目共享**：在 `projects.go` `ensureProjectShare` / `windows_projects.go` 中对 `Local()` 模式调用 `CageLocal.exe grant-share --access <ro|rw|revoke>` 替代 Hyper-V `reversesshfs` 挂载链路。
   - **认证命名管道与组件宿主**：在 Phase 1 已打通的 `LocalWorkerSession` 标准账户会话 + 私有桌面内托管组件进程，复用 `scripts/guest-os/guest-clipboard-windows/Program.cs` 的 `GuestOperations` 注册表与 `LocalGuestTransport.cs` 的命名管道 ACL 护栏（禁用继承、显式拒绝 `NetworkSid`、只允许 `workerSid` + `SYSTEM` + `Administrators`、`TokenImpersonationLevel.Identification`）。对同机 `mode: "local"` 跳过或重绑定 `LocalGuestTransport.VerifyMachine` 检查，使现有 `terminal`、`cli`、`browser`、`desktop`、`attachments`、`cache-maintenance` 等协议逐项落地。
4. **受控出口、真实上游与时区一致性（`internal/workbench/windows_safety.go`、`windows_network.go`、`internal/managedproxy`）**
   - 将 Phase 1 的合成源站 `SyntheticOriginServer` 替换为接入 `internal/managedproxy` 的受控上游出口与受控 DNS 解析，并将 `LocalProxyBroker.SetGateOpen` 与工作台安全闸门（`cage.GateClient`）联动，同时把 `windows_safety.go` 的观测逻辑对接 `LocalWorkerDaemon` 实际边界读回，不沿用 Hyper-V 无网卡或 `windows-remote` 策略结论。
   - 补齐浏览器/应用级时区一致性方案（解决 Phase 1 观测到的 Chromium/Edge ICU JS 时区读取宿主系统时区问题）。
