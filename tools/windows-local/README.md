# Windows 原生本地账户

本目录实现了 Cage 的 **Windows 原生轻量隔离底座（Phase 1）**：不依赖 Hyper-V 虚拟机、Sandboxie、闭源内核驱动或第三方商业软件，完全基于 100% 开源（MIT）代码与 Windows 系统内置安全机制构建独立执行边界，并通过 `verification-phase1.json` 完成离线编译、内核网络隔离、私有桌面、应用兼容与 Zero-Leak 清理验证。

工作台可在既有的 Windows 标准账户中打开 PowerShell、Edge、VS Code、项目共享、Claude 账号和 Tailscale。Claude Desktop 需要单独准备官方安装包。[实测范围](STATUS.md) 和 [第一阶段记录](verification-phase1.json)。

## 打开工作台原型

在 Windows x64 上，从仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\windows-local\Start-CageLocalWorkbench.ps1
```

脚本在 Edge 中打开本机工作台，默认读取 `tmp/windows-local/profile/local-profile.json`，也可通过 `-ProfilePath` 指定已有档案。首次打开时按提示设置原型的 Cage 登录账户，在「Windows 原生本地账户」页确认显示的是已部署的 Windows 标准账户，然后点「进入工作台」。这一步会保存账户绑定。之后用同一档案打开原型，可以继续使用原有的 Cage 登录和工作目录。首次部署见下方「一次性管理员初始化」。

在工作台首页点「新建终端」，或点项目侧栏「隔离工作目录」右侧的终端按钮。PowerShell 标签打开后，在底部输入命令并按 Enter，结果和错误会出现在上方。上下方向键可以找回本次会话的命令。下列示例分两行输入，第二行会读到第一行设置的变量。

```powershell
$n = 40
$n + 2
```

每次连接都会重新核对专用账户和七条网络隔离规则，再在私有桌面上启动低完整性的 PowerShell。当前目录和变量在这次连接中保留。默认工作目录为该 Windows 账户下的 `AppData\LocalLow\CageTerminal`，其中的文件跨会话保留。关闭终端或页面会结束 Shell 及其所属的子进程。原型一次打开一个隔离会话。PowerShell 支持按行输入，全屏控制台及交互式密码提示仍待接入。

- 点「浏览器」可操作隔离 Edge，点旁边的 Claude 图标可打开 claude.ai。
- 点「项目」选择要共享的宿主目录，确认读写权限后保存。已授权项目可在隔离 VS Code 打开。Windows 的完整性保护可能进一步限制编辑器对宿主目录的写入。
- 点「Claude 账号管理」可添加或切换档案、查看登录状态。登录及额度查询需要可用的 Cage 节点。打开新的 PowerShell 时，Claude Code 会使用当前选定的账号档案。
- 点「Tailscale」查看专用账户的节点状态。连网后可登录私网，管理获准通过 SSH 登录此节点的公钥。关闭窗口会结束本次节点进程。
- 点「SSH → 连接远程主机」可创建专用 SSH 密钥，在手动应用的 Cage 代理节点上向一个指定的公网地址逐条执行远程命令。连接前需要目标服务器的主机公钥，并在目标账号上授权专用账户公钥。此模式使用非交互式密钥认证，每条命令建立独立连接。
- 首次联网时，进入「设置 → 网络与代理」，从本地配置导入或手动填写节点，选中节点后点「应用代理」。隔离应用会在出口验证通过后联网。停止代理或验证失败会关闭出口。

可按需用 `Install-CageLocalProxyCore.ps1` 准备受支持的离线代理核心，用 `Install-CageLocalServices.ps1 -CageResources <Cage资源目录>` 准备本机已安装的 Claude Code、Git Bash 和 Cage 私网组件。选好节点并取得官方 Windows x64 安装包后，进入「Claude Desktop」，点「选择官方安装包」，在系统对话框中选择 .msix 文件。工作台核验签名、包清单和账户归属后可打开应用。命令行也可使用 `Import-CageLocalDesktop.ps1 -PackagePath <本机MSIX路径>`，导入后在页面点「重新检查安装状态」。

关闭原型窗口会请求退出本次工作台。开发调试可使用 `-NoBrowser` 创建独立的临时工作台配置，取得一次性入口、进程号与配置路径，再以 `-StopConfigPath` 传入同一配置路径退出。前端或 Go 源码变动后使用 `-RebuildBackend` 更新工作台。

如需继续使用早期原型的 Cage 登录和 Edge 窗口资料，启动时用 `-ResumeConfigPath` 指定当时的 `_output/windows-local/run-…/config.json`。脚本会在原目录中打开工作台。

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

## 工作台接线与后续范围

Windows 原型由 `Start-CageLocalWorkbench.ps1` 显式启用。绑定保存在当前工作台的配置目录内。普通 Cage、macOS 和 Linux 继续使用各自已有的运行环境。

- `internal/workbench/windows_local_prototype.go` 校验账户并提供能力状态。`windows_local_terminal.go`、`windows_local_browser.go`、`windows_local_apps.go` 和 `windows_local_projects.go` 承接登录后同源工作台操作。
- `LocalWorkbenchTerminal.cs`、`LocalWorkbenchBrowser.cs`、`LocalWorkbenchApps.cs` 和 `LocalWorkbenchServices.cs` 在专用账户会话内启动相应组件。
- `windows_local_network.go` 和 `LocalWorkbenchNetwork.cs` 将本次会话的代理转发到工作台选定的 Cage 节点。每一跳须提供公网 IPv4 地址，支持用独立 TLS 域名校验证书。
- 尚待实测的项目包括真实账号登录、节点出口、SSH 私网连接和 Claude Desktop 日常使用。Chromium 时区、并行会话及文件传输的覆盖情况见 [STATUS.md](STATUS.md)。
