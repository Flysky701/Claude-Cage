# Windows AppContainer 候选

这是本机隔离路线的可行性实验，尚未接入 Cage 工作台，也没有替换或卸载 Sandboxie。用户范围与最新结果见 [STATUS.md](STATUS.md)；已有实现的复用分析见 [ASSESSMENT.md](ASSESSMENT.md)，Cage 本机功能对照见 [LOCAL-FEATURES.md](../windows-lite/LOCAL-FEATURES.md)。

2026-11-18：按用户要求暂停并保存到 `codex/windows-appcontainer`。以下命令用于之后明确恢复时复现，不表示当前仍在运行实验。

## 启动器的边界

每个实验创建独有的 AppContainer profile。程序暂停创建后，先核验 AppContainer、精确包 SID、零网络 capability，再加入随控制器退出结束的 Job，最后恢复运行。当前 Windows 不支持读取 token class 46；因此另外用内存安全描述符的 `AccessCheck` 验证确切 package 可访问、`ALL APPLICATION PACKAGES` 在 AC 可访问而在 LPAC 被排除，不以环境变量代替令牌检查。

实验只对新建目录授权：`tools` 可读取与执行，`work` 可读写并可调整自身子目录权限，`private` 不可访问。`out` 仅通过明确继承的标准输出句柄发布日志。`work` 的修改权限用于 Chromium 给自己的内部沙箱设置缓存权限，没有给应用修改已有宿主目录权限的能力。

本机程序使用复制的代码或系统安装目录中的程序；HOME、APPDATA、TEMP 都指向新建工作目录。没有继承主机账号、API Key、代理凭据或个人应用资料。结束后终止测试进程并删除本次 profile，临时文件保留用于查看结果。

## 复现

在普通 Windows x64 PowerShell 中，从本目录执行。需要系统提供的 .NET Framework x64 C# 编译器；原生 Go 探针另需已有 Go 工具链。产物与实验数据写入仓库 `tmp/windows-appcontainer`，不提交二进制或安装包。

```powershell
# 编译并验证普通 AppContainer 的本地边界
.\verify-boundary.ps1 -Mode ac

# 仅编译；不创建或运行实验进程
.\verify-boundary.ps1 -BuildOnly

# LPAC 无 CLR 原生探针，使用本机已有 Go（当前仍有未通过项）
.\verify-boundary.ps1 -Native -Mode lpac -GoPath <本机go.exe>

# 基础应用兼容；每次生成新的工作目录
.\verify-apps.ps1 -App ClaudeCode -Mode both
.\verify-apps.ps1 -App Node -Mode ac -PreserveSymlinks
.\verify-apps.ps1 -App Edge -Mode ac
.\verify-apps.ps1 -App VSCode -Mode ac -PreserveSymlinks

# 单测试包的网络准入，需要 Windows 本人管理员确认
.\verify-network.ps1 -Mode ac -Elevate

# 模拟代理业务往返及已建立连接的切断，同样只作用于临时测试包
.\verify-network.ps1 -Mode ac -ProxyRoundTrip -Elevate

# 真实交互终端：输入、输出、缩放、Ctrl+C、子进程与清理
.\verify-terminal.ps1 -Mode ac

# 官方 Desktop 仅下载、验签、解包，然后离线试跑
.\prepare-desktop.ps1
.\verify-desktop.ps1 -Mode both
```

应用程序的位置可通过 `verify-apps.ps1` 的路径参数指定。脚本拒绝复用已有实验目录，保留每次结果。具体应用检查范围以脚本与状态表为准：版本号不是完整登录或交互验证。

`-PreserveSymlinks` 是针对本次 Node / Electron 入口路径解析失败的显式实验参数，默认未加参数的失败仍保留在证据中。它改变模块路径解析，不代表兼容全部项目依赖或符号链接布局。[Node.js 参数说明](https://nodejs.org/api/cli.html#--preserve-symlinks-main)

通用启动接口为：

```powershell
..\..\tmp\windows-appcontainer\BoundaryProbe.exe launch ac <新实验目录> <程序路径> 20 <程序参数...>
```

实验目录必须位于编译产物目录内。自定义程序放在该目录的 `tools` 下；已安装的系统程序允许从 Windows / Program Files 启动，但不修改其原有权限。回执为 `launch.json`，标准输出在 `out/launch`。直接启动返回成功只表示启动器完成流程，应同时核对回执的应用退出码、超时和实际输出。

## 网络实验的范围

`BoundaryNetwork.cs` 为本次唯一的新 package 安装动态 WFP 拒绝规则，读取规则确认后只许可一个 IPv4 回环 TCP 端口，并仅为该 package 添加回环例外。规则不按日常 Windows 用户匹配。撤销许可后验证同端口的新连接失败，结束时删除本次例外、关闭动态规则会话并删除 profile。

`-ProxyRoundTrip` 另外建立固定测试名到本机模拟服务的 HTTP 往返，分别观察撤销许可与主动关闭代理现有连接。实测两种场景均阻止第二次业务响应，并完成规则、例外和 profile 清理。撤销规则的结果只代表本机所测连接，不应替代代理主动清理所有连接。

这些测试不代表已经实现生产代理、受控 DNS、真实 TLS 上游或所有网络接口的完整断线保护。默认无网络能力的离线边界实验不需要管理员权限；网络实验需要 Windows 管理员确认。

## Cage 终端协议候选

`BoundaryProbe.exe terminal-rpc ac <新实验目录> <shell-exe> [args...]` 使用 Cage 已有终端 JSON 流：首条 `open` 指定 `workspace: home`、shell、cols、rows，随后支持 base64 `input`、`resize`、`close`；返回 `ready`、base64 `data` 和 `exit`。程序路径只由本机启动参数提供，不接受消息中的路径或项目授权。支持的 shell 名称是 `cmd`、`powershell`、`claude`，名称对应所选程序；目前完整交互证据仅覆盖 cmd。

候选宿主适配器 `internal/workbench/windows_appcontainer_terminal.go` 复用现有工作台传输，由宿主创建和删除临时 profile。这样关闭仍运行的终端、强制结束 relay 时，也不依赖 relay 自身的 `finally` 完成清理。直接运行 `terminal-rpc` 的独立命令仍自行管理 profile；工作台适配器内部使用宿主管理的入口。

设置 `CAGE_TEST_APPCONTAINER_LAUNCHER` 为构建后的 EXE 绝对路径，然后执行 `go test ./internal/workbench -run '^TestWindowsAppContainerTerminal(Transport|ActiveClose)$' -count=1` 可复现正常退出及关闭活跃终端两项实测。测试需普通本机权限，默认跳过，不会改变现有后端选择。结果与范围见 [verification-terminal-rpc.json](verification-terminal-rpc.json)。

一次性 `terminal-rpc` 入口仍创建临时环境。新增 Go 环境控制器 `internal/workbench/windows_appcontainer_environment.go` 提供固定身份、新建/重开、多个独立终端与托管项目的导入导出；持久 RPC 不重复初始化项目权限，也不在单终端退出时删除环境。项目采用显式副本，同环境终端共享已授权项目，未改宿主源目录权限。实际结果见 [verification-environment.json](verification-environment.json)，开发终端准备与验证入口见 [TerminalApps.md](TerminalApps.md)。这些接口尚未接入正式界面或产品默认后端。

## Desktop 范围

官方 MSIX 及解包应用只作为实验输入，不注册包、不安装服务、不修改 Windows 功能。原 Cage 的 Desktop 范围是 Chat / Code，Cowork 原本不支持，本轮不追加承接 Cowork。官方包的 `Windows.FullTrustApplication` 声明也不能被当成已经支持受限 AppContainer 的证明。
