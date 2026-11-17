# Windows AppContainer / LPAC 候选评估

本文是本轮**运行前的源码与已有材料盘点**。随后完成的本机实验、应用版本检查和失败定位，以 [STATUS.md](STATUS.md) 及其独立结果记录为准；下文“未验证”保留盘点时的证据范围。

## 评估结论与边界

本轮授权是评估 Windows 本机轻量隔离候选，**尚未决定用 AppContainer 或 LPAC 替换 Sandboxie**。本文件记录源码调查、旧探针证据及候选应用；随后新增的实际应用结果见 [verification-apps.json](verification-apps.json)，仍不代表完整应用兼容验收。

基线调查确认：仓库已有零网络 capability 的 AppContainer 启动、ConPTY、进程令牌检查、盒内账户目录、浏览器管道适配和受控出口候选代码；已有自有探针验证过文件 ACL 与部分网络阻断。现有完整组件面向专用云端 Windows 普通账户、Session 0 后台任务，不能直接视为本机交互桌面的可用实现。基线没有 LPAC 验证材料；本轮新增候选与应用结果分别记录，不能借用原远端实现的结论。

AppContainer 使用 Windows 令牌、包 SID、capability 和对象 ACL 实施访问约束；LPAC 进一步收紧普通 AppContainer 默认可访问的系统资源。它们不是虚拟机，也不自动让任意桌面程序拥有兼容的文件、注册表、网络和桌面环境。[Microsoft：启动 AppContainer / LPAC](https://learn.microsoft.com/en-us/windows/win32/secauthz/implementing-an-appcontainer)

## 已有材料与证据

| 材料 | 已能确认的内容 | 不能据此确认的内容 |
| --- | --- | --- |
| `tmp/appcontainer-probe/Probe.cs`、`probe.exe`、`result.txt` | 本地旧自有 .NET 探针；结果文件修改时间为 2026-11-12。启动时创建唯一 profile，限定共享临时目录，结束后删除自己的 profile | 非仓库交付产物；不是 Claude、Electron、浏览器或编辑器的实测 |
| 旧探针 `AppContainer (0 capabilities)` 结果 | 显式共享文件读取成功；私有文件返回 5；宿主回环连接超时且监听器未接到连接；公网 IPv4 TCP 返回 10013；对应普通进程对照均成功 | 不能外推到 UDP、IPv6、系统服务代发 DNS/HTTP、注册表、GUI、跨包与所有凭据接口 |
| 旧探针资源采样 | 同一自有探针空闲时 AppContainer 私有内存约 11.7 MiB、工作集约 14.3 MiB；5 秒采样 CPU 为 0 ms | 不含真实应用、代理、UI、安装组件；不能用于承诺完整 Cage 的内存或启动速度 |
| `RemoteSandbox.cs` | 创建/派生包 SID、零 capability、安全环境变量、工具只读授权；暂停态子进程核验 AppContainer 标志、精确 SID 和 capability 数量 | 是普通 AppContainer，不包含 LPAC 额外属性；没有本机通用 EXE 产品接口 |
| `TerminalRpc.cs:NativeTerminal` | ConPTY 或受控 stdio；仅继承明确句柄；暂停创建后核验令牌并加入 `KILL_ON_JOB_CLOSE` Job，再恢复执行 | 源码存在不等于本机 Claude Code/PowerShell/所有子进程实测通过 |
| `RemoteBrowserRpc.cs`、`windows-remote-browser.mjs` | 复用 Windows 浏览器业务服务，独立浏览器目录和下载目录；以 Node 驱动 headless Chromium | 是专用 headless 浏览器，不是已安装 Edge / Chrome / Claude Desktop 的兼容证明；编辑器路由明确未接通 |
| `windows-appcontainer-spawn.mjs` | 对 Playwright Chromium 启动使用包内 `\\.\pipe\LOCAL\…` stdio/CDP 管道，避免依赖非包内管道；代码注释记录 Node/libuv 兼容问题 | 需要对本轮 Node、浏览器版本重验；不能把代码注释当作本机新验证结果 |
| `RemoteNetworkPolicy.cs`、`RemoteBrokerPolicy.cs` | 专用账户直连阻断，加包 SID 阻断、单代理端口许可、UDP 绑定过滤和包回环例外的候选代码；输出仍标 `workload_ready=false` | 未发现当前机器这套部署的完整验收记录；不能把“过滤器安装”直接当成工作负载全部网络路径受控 |
| `internal/guestos/windows_profile_test.go:TestRemoteWindowsBindingIsLimitedToHeadlessRelay` | 原有测试用例检查远端绑定仅允许已定义的 headless 操作 | 本次只读取测试源码，未运行；它检查路由限制，不证明应用兼容 |

这次在 `scripts`、`tmp`、`_output`、`outputs` 的定向文件名查询中，未找到可直接复用的 `Cage.GuestClipboard.exe` 或 `chrome-headless-shell.exe` 发布包。源码仍需按现有项目构建，或使用单独的最小候选启动器；不应把“源码存在”标成“安装就绪”。

## 是否要求专用 Windows 账户

**仓库现有远端实现要求，AppContainer 最小候选不应据此默认创建账户。**

- `RemoteSandbox` 构造函数要求进程用户 SID 等于绑定用户，并拒绝管理员；`CreateHeadlessDesktop` 明确要求 `SessionId == 0`，使用非交互窗口站。
- `deploy/windows/prepare-remote.ps1` 必须由管理员运行，会新建专用普通账户、安装目录、配对材料、计划任务和账户级 WFP 基线，并将该账户加入远程桌面用户组。这是云端部署行为，不适合为本机候选评估直接执行。
- `deploy/windows/install-remote-headless.ps1` 从既有专用账户部署读取凭据，创建 `RunLevel Limited` 的后台任务。
- `RemoteSandboxPolicy` 的安装动作会给指定包补路径元数据和设备等权限；`RemoteBrokerPolicy` 会调整包回环例外及 WFP。均不是“只启动一个 EXE”的无状态动作。
- 旧 `Probe.cs` 直接在调用用户下创建临时 AppContainer profile，没有创建 Windows 用户或计划任务。其结果只记录父进程非 AppContainer，未记录父进程是否提权，不能声称已经验证普通用户安装路径。

因此，本机候选应独立验证当前交互会话下的最小启动与资源授权；不要为复用远端类而将当前用户绑定为云端专用账户，更不能把账户级断网规则套在日常登录用户上。

## 当前机器的可用程序

下列为开始应用测试前的只读文件发现与版本元数据。新实测结果单独记在 [verification-apps.json](verification-apps.json)，不能由安装元数据推定程序可用。`%USERPROFILE%` 表示实际安装这些程序的交互用户目录；受限执行进程的环境变量可能指向不同位置，启动前应用已核对的绝对路径。

| 程序 | 发现的安装位置 | 文件版本 / 状态 |
| --- | --- | --- |
| Claude Code 原生 EXE | `%USERPROFILE%\.local\bin\claude.exe` | `2.1.296.0`；普通文件，未发现符号链接；可先仅测 `--version` |
| Microsoft Edge | `%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe` | `157.0.4341.60`；实际文件存在；使用全新临时浏览器资料目录 |
| Visual Studio Code | `%USERPROFILE%\AppData\Local\Programs\Microsoft VS Code\Code.exe` | `1.144.0`；实际文件存在。`bin\code.cmd` 是 Electron CLI 包装器，优先直接选 EXE 并显式传参数 |
| Node.js | `D:\DevTools\node-v24.21.0-win-x64\node.exe` | 命令路径已定位；文件名中的版本未单独通过运行核实 |
| Git | `D:\DevTools\Git\cmd\git.exe` | 命令路径已定位；未运行版本检查 |
| Python | `%USERPROFILE%\AppData\Local\Programs\Python\Python313\python.exe` | 命令路径已定位；Python 运行库不能仅复制 EXE 后假设可用 |
| Windows PowerShell | `%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe` | 系统提供；与仓库 headless 使用的私有 PowerShell 7 不是同一产物 |
| Claude Desktop | 用户随后确认本机未安装 | 初次只读查询受权限限制，未据此判断安装状态；后续独立官方 MSIX 候选见 `verification-desktop.json`，未读取登录资料 |
| Google Chrome / code-server | 本轮未定位可直接使用的安装文件 | 可先使用已定位 Edge 与 VS Code；未额外下载或安装 |

Claude Desktop 若是 MSIX，需进一步识别其进程模型、依赖和激活方式。MSIX 打包并不代表程序默认在 AppContainer 中运行；不能把启动某个包内 EXE 与完整包激活等同。[Microsoft：MSIX 容器化概览](https://learn.microsoft.com/en-us/windows/msix/msix-containerization-overview)

## 任意 EXE 兼容需解决的具体问题

1. **程序与依赖可读不等于程序可写。** 需要分别授权 EXE、DLL、运行库与工作目录，给新 profile 提供可写 HOME、TEMP、应用资料目录。尽量使用单独副本或候选专用目录，避免改变真实安装目录和个人数据权限。AppContainer 的权限取用户权限与包/capability 权限的交集。[Microsoft：AppContainer 隔离](https://learn.microsoft.com/en-us/windows/win32/secauthz/appcontainer-isolation)
2. **GUI 与后台模式分别验证。** 仓库的 Session 0 非交互窗口站不能直接承接当前桌面的可见应用；Edge、VS Code、Claude Desktop 还涉及 USER32、COM、子进程、GPU、单实例 IPC 和应用更新。仅进程创建成功或 `--version` 成功不能代表窗口可用。
3. **stdio、ConPTY 与包内管道。** 命令行工具可能在创建子进程、打开 `NUL` 或命名管道时失败。已有 `windows-appcontainer-spawn.mjs` 只覆盖特定 Chromium/Playwright 启动链，其他工具仍需实际取证。
4. **联网必须通过受控通道。** 零网络 capability 的默认隔离能作为离线基线；HTTP_PROXY 环境变量并不能让被禁止的回环连接自动可用。若采用包回环例外，必须同时证明它没有放开其他宿主服务。不能为了浏览器可用直接授予不受控公网网络能力。
5. **系统和程序身份不自动变成客机。** AppContainer 共用宿主内核；时区、语言及应用自身可见信息需要独立配置与验证。不能沿用 Sandboxie 的注入插件通过结论。
6. **LPAC 是另一候选。** 仓库当前 AppContainer 实现没有 `PROC_THREAD_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY` 的 opt-out 设置。LPAC 还可能需要显式的注册表、COM 或系统库能力；先验证自身令牌及最小工作负载，再按失败的具体资源逐项决定权限，不能直接打开一组宽泛能力。[Microsoft：启动 LPAC](https://learn.microsoft.com/en-us/windows/win32/secauthz/implementing-an-appcontainer)
7. **生命周期和数据语义需要产品实现。** AppContainer profile、权限授权及应用数据的创建、复用、撤销应独立记录；停止进程与删除数据是不同操作。后续要支持多终端、浏览器、编辑器共用环境，不能只提供一次性启动命令。

## 当前判定

| 项目 | 判定 |
| --- | --- |
| 最小自有 EXE 的 AppContainer 文件/IPv4 TCP 隔离 | 有旧本机证据，范围有限；本轮未复跑 |
| 当前交互用户下的通用 EXE 启动器 | 待本轮新候选验证 |
| LPAC 启动与应用兼容 | 本轮新增启动器已验证应用候选令牌；Claude Code 仅版本输出通过，其余本表应用未通过；不推定完整兼容 |
| Claude Code 实际运行 | AC / LPAC 均仅 `--version` 通过；登录、交互与工具调用未验证 |
| Node 实际运行 | AC 内联脚本通过；文件入口加 preserve-symlinks 参数后也通过；子进程须使用临时文件 stdio 的已测路径。LPAC 启动失败；完整模块与包管理未验证 |
| Edge 实际运行 | AC / LPAC 均未得到本地页面 DOM，未通过 |
| VS Code 实际运行 | AC 默认 CLI 入口失败，加明确的 preserve-symlinks NODE_OPTIONS 后版本输出通过；编辑器 GUI 未验证。LPAC 创建实际 Code 子进程被拒 |
| Claude Desktop 实际运行 | 官方 MSIX 独立候选见 `verification-desktop.json`，不沿用其他 Electron 应用结果 |
| 代理、DNS、断线保护与非回环隔离闭环 | 有远端候选实现参考；本机候选未验证 |
| Cage 工作台全部本机功能 | 未接入，不能声称可替代现有路线 |

本轮候选结果应另记具体启动器、应用版本、AppContainer 或 LPAC 模式、失败阶段与可观察结果。只有应用可用性和隔离边界都得到实际证据后，才能决定后端选择。
