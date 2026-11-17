# Windows 本机 AppContainer 候选状态

更新：2026-11-18。范围：先承接 Cage 本机功能，远程、云端及多设备连接后续处理。用户同意评估 AppContainer / LPAC，尚未决定替换 Sandboxie。

**当前暂停。** 按用户要求将代码、已通过的证据和未完成项保存到 `codex/windows-appcontainer`，不继续实现或测试。此分支与原生本机路线 `codex/windows-local-native` 分开；未切换产品默认后端。恢复需用户明确指示，优先处理下面记录的 Edge 与 Desktop 阻塞。

## 当前结论

**普通 AppContainer 的文件、进程隔离、真实交互终端、持久多终端环境及托管项目已有通过证据；目前不能完整承接本机工作台。** PowerShell、Node 的限定本地流程和 Claude Code 离线设置界面已通过；浏览器、编辑器 GUI 和 Desktop 尚未可用。LPAC 的运行库、子进程、注册表和网络初始化存在更多限制，不能直接作为统一默认模式。

Sandboxie 现有实现、数据和本轮已验证的改进保留，状态见 [Windows Lite](../windows-lite/STATUS.md)。两种后端的测试结果不互相沿用。

## 本轮证据

环境：Windows build 26300 x64；使用独立测试 package 和资料目录，持久环境测试在自己的新目录内重开同一身份；没有使用真实登录或付费模型请求。

| 项目 | 实测结果与范围 | 证据 |
| --- | --- | --- |
| 普通 AC 本地边界 | 14 项通过：私有文件拒读写；只读目录可读不可写；授权目录可写；宿主 HKCU 拒读写且不变；容器注册表可写；宿主秘密环境变量未继承；子进程同包；IPv4/IPv6 TCP/UDP 回环正反对照。仅工作目录增加自身权限调整能力后，5 项相关文件检查再次通过 | [首次结果](verification-boundary-ac.json)、[定向复验](verification-boundary-followup.json) |
| LPAC | 原生探针的 8 项文件、宿主注册表和环境检查通过；自身注册表写入及原生子进程创建拒绝，Winsock 初始化 10107，不能作为网络阻断通过。CLR 探针另有 `0x80131702` 初始化失败 | [原生结果](verification-boundary-lpac.json)、[原生调用复核](verification-boundary-followup.json)、[CLR 结果](verification-boundary-lpac-clr.json)；整体未通过 |
| 普通 AC 网络准入 | 7 个临时包规则读回；唯一许可端口连接成功，其他宿主端口及撤销后的原端口均拒绝。测试例外、动态规则会话和 profile 已清理 | [verification-network.json](verification-network.json)；仅新建 TCP 连接，不是完整代理/DNS/断线闭环 |
| 普通 AC 代理与既有连接 | 固定测试名通过本机模拟 HTTP 代理完成一问一答；撤销规则与代理主动关闭连接两种场景均阻止同一连接的第二次请求，新连接及其他宿主端口受阻，临时规则和 profile 清理成功 | [verification-network-proxy.json](verification-network-proxy.json)；无系统 DNS、真实上游、TLS 或多连接并发验证，不推定所有流量均已覆盖 |
| 真实交互终端 | AC 的 cmd 输入输出、同包子进程、100×30→117×41 窗口变化、Ctrl+C、中断后继续输入、退出清理全部通过。LPAC 内建输入输出通过，但外部子程序被拒绝 | [verification-terminal.json](verification-terminal.json)；其他应用见下方限定结果 |
| Cage 终端传输 | 复用 `startWindowsGuestTerminalRequest` 连接候选终端，真实命令计算、环境变量隔离、缩放请求和正常退出通过；宿主侧适配器负责 profile 清理，关闭仍在运行且无人读取输出的终端也通过清理检查 | [verification-terminal-rpc.json](verification-terminal-rpc.json)；没有启用默认后端或接入完整工作台页面 |
| 持久环境与托管项目 | 同一身份重开保留工作文件、工具及项目；双终端独立退出通过；项目只读/读写、源目录拒读写、新目录导出以及链接拒绝通过 | [verification-environment.json](verification-environment.json)；托管副本，不是宿主原目录实时共享，尚未接入正式界面 |
| PowerShell 与 Node 开发终端 | PowerShell 显式挂载已授权目录后，中文、子进程、resize、Ctrl+C 通过；Node 本地模块、中文文件及继承终端的子进程通过 | [verification-terminal-apps.json](verification-terminal-apps.json)、[使用入口](TerminalApps.md)；不覆盖 npm 下载或任意工具链 |
| Claude Code 2.1.296 | AC 与 LPAC 版本检查通过；AC 显式配置无服务的占位网关后，真实主题设置界面、resize 重绘和关闭终端清理通过。默认配置仍因联网预检失败退出 | [应用记录](verification-apps.json)、[终端记录](verification-terminal-apps.json)；主题页 Ctrl+C 未退出，登录、工具调用和模型会话未验证 |
| Node 24.21.0 | AC 的 `-e` 入口配合文件标准输出通过；显式使用 `--preserve-symlinks-main --preserve-symlinks` 后，真实脚本入口也通过文件与子进程检查。默认路径解析和默认管道仍有问题；LPAC Winsock 初始化失败 | [应用定向记录](verification-apps.json)；参数适配未改变宿主目录权限 |
| Edge 157.0.4341.60 | 原挂起已定位到输入法初始化；仅目标进程的 `ImmDisableIME(-1)` 处理越过该栈，但后续仍超时或退出 `0xC0000005`，无成功页面证据 | [暂停时定位记录](verification-edge-compat.json)；未关闭内部沙箱，原主线程 APC 初始化方案只有设计，尚未实现 |
| VS Code 1.144.0 | AC 的默认 CLI 路径解析失败；显式使用上述 Node 路径参数后，真实 Code 子进程身份和 CLI 版本输出通过。编辑器 GUI、项目编辑和扩展仍未验证 | [应用定向记录](verification-apps.json)，不能把 CLI 成功当编辑器完成 |
| Claude Desktop 5.11492.5.0 | 匹配的官方符号确认内部 broker 创建替代窗口站被拒后触发 CHECK；专属新窗口站的最小权限句柄传入后，切换、创建新子桌面、恢复及对象清理通过 | [verification-desktop-compat.json](verification-desktop-compat.json)；窄 IAT 适配尚未实现，真实客户端窗口/Chat/Code 均未通过，未注册安装或启动 Cowork 服务 |
| Git 路径兼容 | 窄 IAT 补偿已通过工作目录及边界检查，但 `init/add/status` 仍失败；相对路径与 reftable 对照也未解决后续父目录检查 | [verification-native-path.json](verification-native-path.json)；未修改原安装或扩大宿主目录权限，未接入正式终端 |

## 实现与限制

- 已提供可复现的通用启动器、边界探针、应用兼容检查、临时网络准入测试，以及官方 Desktop 下载/验签/解包脚本，入口见 [README](README.md)。
- 已复用仓库 `RemoteSandbox`、`TerminalRpc` 和 `RemoteBrokerPolicy` 的边界思路；未直接执行其专用云端账户部署脚本。
- 本机启动不创建专用 Windows 账户。临时网络及专属窗口站试验使用管理员辅助程序，只作用于本次新包/新对象，结束清理；应用仍以受限令牌启动。
- 没有授予测试应用公网 capability，也没有为应用开放宿主盘根、关闭浏览器内部沙箱或导入真实资料。
- AppContainer 共用宿主 Windows；身份、语言、时区、剪贴板、所有系统服务代理调用和全部设备接口尚未验证，不能视为虚拟机等价隔离。

## 恢复后接续优先级（当前不执行）

1. Edge：区分远程初始化线程的副作用与后续真实崩溃；原主线程 APC 初始化方案尚未实现，最后一项排队的崩溃跟踪按暂停要求没有启动。
2. Desktop：将已通过的专属句柄路径接到最小兼容层，保留外层 AppContainer 和内部渲染器限制，再验证真实窗口；目前尚无 shim 实现。
3. 将已验证的包级单端口许可与主动连接清理接到实际代理，补 DNS、真实 TLS 上游、多连接和失联场景；不把本机模拟响应当业务出口验证。
4. 将已通过的持久环境、托管项目及开发终端接入工作台；继续处理 Git 后续目录检查、Claude 登录与正式业务流程。完整对应范围见 [本机功能承接清单](../windows-lite/LOCAL-FEATURES.md)。

当前没有需要购买的资源，也没有等待用户提供的安装包。技术缺口如上；本轮停止原因是用户明确暂停。源码和脱敏结果进入分支，二进制、安装包、调试 dump 与公开符号缓存保留为本机临时产物，不纳入提交。
