# Windows 沙箱本机功能承接清单

## 范围与完成标准

用户已确认：继续 Windows 沙箱路线，实现隔离环境，并为 Cage 原有功能提供对应实现；**先完成本机功能，手机远程、云端部署和多设备连接后续再做**。

本路线基于 Sandboxie；它与 Cage 现有 Hyper-V Windows 客机是不同后端。原客机已有的测试、登录、网络和隔离结论不能直接用于本路线。功能只有在沙箱版本上完成对应操作并留下结果，才能标为已验证。原界面存在入口、盒内能启动某个 EXE、代理端口握手成功，都不足以说明该项已完整承接。

本清单用于明确实现范围和复用位置。当前运行方式见 [README](README.md)，既有实测见 [verification.json](verification.json)。本清单中的“待接入”表示尚未在 Lite 上形成完整功能，不表示原 Cage 缺少该功能。

本轮新增实现与验证见 [Lite 当前状态](STATUS.md)；用户追加授权的底座评估见 [AppContainer 当前状态](../windows-appcontainer/STATUS.md)。下表保留原 Lite 基础与完整承接缺口，不能替代新结果记录。

## 当前基线

- Lite 是独立 Python 启动器，尚未被 `internal/workbench` 调用。它只读取 Cage 保存的出口配置及 Mihomo 路径，不等于已接入 Cage 工作台。
- 既有版本根据数据目录与 EXE 路径确定盒名；每个 EXE 使用自己的持久目录。主进程退出后关闭该盒内进程及专用代理。原 Cage 则是多个项目、终端、浏览器和工具共用一个持久环境。
- `verification.json` 记录的是既有 x64 父子探针：同步 DNS、东京时间、固定目标 TCP 转发、所测直连阻断及代理中断行为。它不覆盖后续策略改动，也不覆盖任意应用、所有 DNS 接口、浏览器完整功能或内核级网络隔离。
- [ProxyBridge 实验](experiments/proxybridge/README.md)的本机驱动加载未成功，没有可沿用的任意目的地址透明代理通过结论。
- 新增隔离策略、离线启动与浏览器代理适配需以各自产物和实际验证记录为准；不能把“已写规则”记成“隔离整体通过”。

## 本机功能对应表

| 功能 | 原 Cage 的用户行为 | Lite 已有基础 / 当前缺口 | 优先复用位置及沙箱实现要求 |
| --- | --- | --- | --- |
| 环境生命周期 | 启动、停止、重连；关窗口可保留后台任务；环境数据持久化 | 有单应用启动、退出清理及按 EXE 保存文件。缺少环境级会话管理、多应用共存、工作台重连 | `internal/workbench/runtime.go` 的 `attach`、`startEnvironment`、`stopEnvironment`；为 Lite 建立独立环境身份和进程生命周期，区分关闭视图、结束某应用、停止整个环境 |
| 文件与配置隔离 | 默认不读取宿主个人资料，只访问已授权项目；工具与登录保存在环境内 | 既有启动器只封闭少量配置目录，仍继承宿主环境变量。需要全盘默认边界、独立用户资料、注册表及环境变量策略 | `tools/windows-lite/shell.py` 的 `Sandbox.configure` / `launch`；验证未共享宿主文件不可读、盒内写入不修改宿主、真实凭据不继承、其他盒数据不可读 |
| 项目与多文件夹 | 添加、重命名、解绑、移除项目；首目录为默认工作目录，其余目录可访问 | 有 `workingDirectory`，没有项目列表、持久绑定和动态撤销共享。工作目录本身不应自动授权整目录 | `internal/workbench/project_groups.go`、`project_directories.go`、`projects.go` 的 `ensureProjectShare`；将显式只读/读写目录转为盒规则，保留 `.git` 行为；解绑前结束相关使用者，验证同名前缀目录与链接边界 |
| 普通终端与开发工具 | PowerShell、交互输入、Ctrl+C、调整大小、多个标签及重连；运行 Git、Node、Python 等 | 可启动外部 PowerShell 窗口。尚无嵌入终端、会话标签和工具组件管理 | `internal/workbench/terminal_service.go` 的 `createTerminalLocked`、`terminal_windows.go` 的 ConPTY、`terminal.go` 的流接口；需要验证 Sandboxie 启动链上的真实输入输出、尺寸与终止，不可只接普通管道 |
| Claude Code 与会话历史 | 登录、创建会话、历史列表、继续已有会话、项目附加目录、技能与记忆 | 可配置 x64 应用入口；没有已验证的 Claude Code 登录与工作台会话集成 | `internal/workbench/windows_cli.go`、`windows_ccs_launch.cjs`、`scripts/guest-os/guest-clipboard-windows/WindowsCliRpc.cs`；复用请求与会话管理，改为盒内执行和盒内账户目录。登录、历史读写和进程续接分别验证 |
| 编辑器 | 在工作台编辑已授权项目、多目录工作区、终端及文件操作 | 没有编辑器入口和组件就绪检查 | `internal/workbench/browser_service.go` 的 `editor` 路由、`WindowsEditorServer.cs`、`WindowsEditorPreferences.cs`；编辑器进程及扩展运行在同一受控环境，不能通过宿主编辑器代替 |
| 浏览器 | 地址栏、标签、收藏、无痕、Cookie、扩展、开发预览和登录回调 | 既有应用启动可运行浏览器，但无完整工作台协议；需解决会话代理认证、多进程策略及独立资料 | `internal/workbench/windows_browser_client.go` / `windows_browser.go`、`browser_settings.go`、`favorites.go`，以及 `scripts/guest-os/windows-browser.mjs` / `windows-browser-extensions.mjs`。代理适配仅是联网基础；首脚本时区、后台请求、下载及失联行为另验 |
| 本地开发服务 | 终端启动服务，浏览器访问环境内 `localhost` | Lite 与宿主共用网络栈，`127.0.0.1` 不是天然隔离的客机回环；既有规则只放行指定代理端口 | 为盒内服务提供受身份限制的访问，核验目标监听进程属于当前盒；拒绝任意宿主管理端口。不能全放行回环来实现预览 |
| 文件上传、附件、下载 | 明确选中文件上传；截图/文件粘贴；下载暂存、另存为、同名处理 | 有直接共享输出目录，尚无选择器、限额、下载完成确认和工作台文件传输 | `internal/workbench/file_input.go`、`image_input.go`、`windows_attachments.go`、`browser_files.go`；`WindowsFilePublication.cs`、`WindowsDesktopDownloads.cs`。保留用户明确选择与临时授权，不因上传一份文件开放整个宿主目录 |
| 输入法、剪贴板与音频 | 中文输入、双向文字/图片/文件传递、应用音频控制 | 不能将 Sandboxie 默认共享剪贴板当成 Cage 已授权的传递通道；相关能力缺少 Lite 验证 | `internal/workbench/shared_clipboard.go`、`windows_audio.go`、`WindowsIme.cs`、`WindowsAudioRpc.cs`。默认隔离与主动传递分开，确认目标进程和当前会话后传入；音频按实际能力报告 |
| Claude Desktop | 启动官方应用、显示窗口、登录、附件、下载、复制粘贴 | 无 Lite 对应组件和验收；能启动任意 EXE 不代表官方客户端已经可用 | `internal/workbench/claude_desktop.go`、`native_control.go`、`scripts/guest-os/claude-desktop-windows.ps1`、`claude-window-windows.ps1` 及 `WindowsDesktopFiles.cs`。复用应用控制协议，处理安装形态、进程树、登录回调和资料隔离 |
| Claude 多账户、额度与切换 | 独立登录、调度、额度显示、同组接续、共享技能；凭据互不覆盖 | 无 Lite 账户管理；当前每 EXE 一盒也无法直接表达同一环境里的独立账户目录 | `internal/workbench/claude_accounts.go`、`claude_accounts_http.go`、`claude_accounts_usage.go`、`claude_switch.go`、`windows_cli.go`。复用宿主账户元数据和调度，账户凭据留在盒内；真实付费模型请求需按既有批准范围执行 |
| 出口、DNS 与断线保护 | 订阅/节点/代理链、出口验证、暂停/恢复、出口变化规则；DNS 与业务同路 | 读取现有 SOCKS5/DoH 配置、专用 Mihomo、同步 DNS 和固定 TCP 目标已有旧版证据。透明任意 TCP、完整 DNS 接口、WFP 内核阻断和与现有准入报告的关联均有缺口 | 复用 `internal/managedproxy`、`internal/exitpolicy`、`internal/workbench/safety.go`、`windows_network.go` 中的业务策略。另建 Lite 观测与授权证据，禁止沿用 Hyper-V 无网卡证明；配置与验证失效时不自动直连 |
| 时区与语言 | 跟随出口或手动配置；系统、CLI、浏览器结果一致 | `addon/region.c` 固定东京，只适配列出 x64 映像的部分 Win32 时间与同步 DNS 调用 | `internal/workbench/settings.go`、`windows_safety.go` 的配置转换可复用。需把时区/语言作为环境配置传入，覆盖 JS 首次执行、运行库和子进程；不修改宿主系统时区 |
| Cage 账户、锁定与密码库 | 解锁工作台、锁定隐藏界面、受保护设置、密码库 | Lite 没有账户与锁定 UI；不能把盒内进程当作已授权宿主控制器 | `internal/workbench/account.go`、`account_store.go`、`account_device.go`、`vault_http.go`、`vault_store.go`。继续由可信宿主控制器持有账户和库，向盒内仅发放当次必要能力 |
| 维护、升级、资源与诊断 | 工具组件检查/更新、可恢复缓存清理、迁移、备份、日志；资源限制有真实范围 | Lite 保存文件但无组件管理、缓存恢复、迁移事务或版本匹配。VM CPU/内存与磁盘面板不能照搬到进程沙箱 | `internal/workbench/windows_components.go`、`cache_maintenance.go`、`storage.go`、`diagnostics.go`；沙箱目录迁移需停止本环境并保留原件。分别显示应用/组件/引擎版本；不支持的 VM 专属操作明确隐藏或解释 |
| 本机 Agent 操作 | Agent 通过产品接口发现能力并调用已有功能 | Lite 目前只有启动命令，没有产品操作接口与能力报告 | `internal/workbench/agent.go` 的 `AgentOperations`、`AgentCall`、路由发现；依托现有宿主授权和业务接口，明确区分本机 Agent 控制与盒内应用访问 |

## 接入现有工作台的最小切入点

### 1. 先独立识别运行后端

`internal/workbench/server.go` 当前通过 `guestos.LoadWindowsProfile` 加载 `windowsGuest`，其余路径按非空字段选择 Windows 客机逻辑。`internal/guestos/windows_profile.go` 的 `WindowsProfile.validate` 仅接受 Hyper-V 与专用远端 Windows 模式。

Lite 应有独立的绑定记录和后端选择，不把盒名包装成 VMID，也不修改现有 Hyper-V 核验为“总是通过”。`windowsStatus` 在 `internal/workbench/windows_guest.go` 中验证虚拟机代际、安全启动、虚拟 TPM、网卡和图形账户身份，这些都不是 Sandboxie 的证明。Lite 状态必须报告自己的引擎、盒、策略、进程和组件状态。

最先需要显式分流的位置：

- `server.go`：读取后端绑定、生成能力状态，暂未实现的能力返回不可用。
- `runtime.go`：`environmentPrepared`、`attach`、`startEnvironment`、`stopEnvironment` 与设置应用。
- `terminal_service.go`：`createTerminalLocked`；复用现有终端管理器及 WebSocket，不重新建立一套工作台。
- `projects.go`：`ensureProjectShare`；复用项目组和授权关系，使用 Sandboxie 实际目录规则替换 VM 挂载传输。
- `browser_service.go`：`guestAPI`、浏览器事件订阅与编辑器分流，接入相同前端请求形状。

### 2. 复用 Windows 组件协议，重新实现本机沙箱传输

`internal/guestos/windows_profile.go` 的 `WindowsRelayCommand` 是现有 Windows 业务的集中传输入口，覆盖 `terminal`、`cli`、`browser`、`desktop`、`attachments`、`audio`、`safety`、`project-mount`、`cache-maintenance` 等操作。盒内运行的 Windows 组件可以继续接受已有业务请求，宿主侧 UI、账户调度、收藏、下载状态和终端管理无需重写。

`scripts/guest-os/guest-clipboard-windows/Program.cs` 的 `GuestOperations` 注册器与各 `Windows*Rpc` 组件是复用入口。其 `serve-local` 和 `LocalGuestTransport.cs` 已有命名管道实现，但绑定专用云机器、Windows 用户及配对密钥，不能原样视为 Sandboxie 通道。需要对盒身份、进程归属、会话期限和受限操作重新绑定；配对材料不能通过整目录共享暴露给盒内应用。

`windows_browser_client.go` 已使用可注入的 `start` 函数创建业务连接，适合复用浏览器请求与返回解析。`windows_terminal.go` 的流协议与 `terminal_windows.go` 的 ConPTY 也可分别复用，但 Sandboxie 中的实际启动、退出和窗口继承必须验证。

### 3. 调整生命周期后再接完整多应用工作台

当前 `home + program` 生成盒身份，且 `Sandbox.run` 退出会结束整盒。要承接原 Cage 的并行终端、浏览器、编辑器和 Desktop，应由环境级会话拥有盒与代理，各应用只是环境内的子任务。环境身份不能随当前应用切换；关闭一个应用也不能杀掉其他工具。

这一调整需要保留旧 Lite 数据，不自动搬入旧盒中可能已复制的宿主配置。迁移应有显式来源、目标及回退办法；首次严格隔离验证使用新环境，避免旧数据影响结论。

### 4. 使用能力状态限制入口，隔离检查独立取证

原 `windowsCapabilitiesLocked` 已区分注册、安装、可用及过期状态。Lite 应延续这一含义：浏览器进程启动不代表网络已验证，组件文件存在不代表登录、传输和界面可用。

隔离验收至少应包括：未共享文件读取失败、盒内写入可持久且宿主未改变、只读/读写项目按声明生效、盒间隔离、宿主凭据环境变量不继承、未经授权的宿主回环/局域网与直接公网访问失败、代理及 DNS 故障不回落、真实应用子进程受同一策略约束。每项标记产物、环境、读取或调用路径；尚未覆盖的底层接口保持“未验证”。

## 接续顺序

1. **独立启动基础**：补齐文件/配置/环境变量隔离、离线运行、显式项目目录和浏览器代理；用自有临时数据检查实际效果。
2. **环境级运行与普通终端**：固定环境身份、多应用生命周期、ConPTY，接入既有项目与工作台状态。
3. **日常工作闭环**：浏览器与编辑器、上传下载、受控剪贴板、本地开发预览；在同一环境内验证。
4. **Claude 功能**：Code 登录/历史、多账户/额度/切换、Desktop 与附件；保持其原有授权及数据保留语义。
5. **完整本机交付**：出口准入与变化规则、动态时区语言、锁定与密码库、组件更新、备份迁移、诊断和本机 Agent 接口。只运行本次变更相关检查，不以大规模回归代替实际功能验收。

手机远程、云端部署、多设备连接、私网接续和相关远程传输不属于当前交付范围。它们保留为后续阶段，当前不为实现本机功能而隐式开启远程访问。

## 需求沟通边界

本机表中的对应功能均在已确认范围内，可按上述顺序实施。只有实际发现无法等价承接的功能、必须改变用户数据保留/共享方式，或需要使用新的付费能力时，再将具体差异、影响与可选实现交给用户决定。普通兼容修复和定向验证不需要逐步确认。
