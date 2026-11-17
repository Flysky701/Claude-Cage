# 本机开发终端候选

`verify-terminal-apps.ps1` 构建独立的 `tmp/windows-appcontainer/TerminalAppsProbe.exe`，不会覆盖共享的 `BoundaryProbe.exe`。每次使用新临时资料、零网络 capability 和独立 AppContainer profile，不读取真实账户资料。

```powershell
# 只验证指定应用；不会运行已通过的其他应用。
.\verify-terminal-apps.ps1 -App PowerShell
.\verify-terminal-apps.ps1 -App Node
.\verify-terminal-apps.ps1 -App Git

# Claude 默认首次启动需要联网；此显式占位配置只验证离线设置界面。
.\verify-terminal-apps.ps1 -App ClaudeCode -ClaudeOfflineGateway

# 只准备应用副本、空工作目录及可复用的终端启动描述。
.\verify-terminal-apps.ps1 -App Node -PrepareOnly

# 新建本机用户临时目录做位置对照；不会迁移现有数据。
.\verify-terminal-apps.ps1 -App Git,Node -TemporaryHostRoot -NodeDefaultEntry
```

`-RunDirectory` 可指定 `tmp/windows-appcontainer` 下尚不存在的目录。每个应用目录的 `prepared.json` 包含标准 `terminal-rpc` 参数及 `open` 消息；将其交给工作台现有 `startWindowsAppContainerTerminal`，由宿主管理临时 profile 生命周期。独立命令 `TerminalAppsProbe.exe app-rpc PowerShell <已准备目录>` 也提供相同 JSON 流，直接调用时由 relay 清理 profile。

PowerShell 的启动参数先把获准的工作目录挂为 `Cage:`、只读工具目录挂为 `CageTools:`，然后进入 `Cage:\`。本机系统 PowerShell 5.1 在不能检查磁盘根目录时，默认没有正确挂载文件系统盘符；显式挂载这些已授权目录后，真实中文输入输出、外部子进程同包、终端大小变化和 Ctrl+C 已通过。无需改变磁盘根或真实用户目录的权限。

Node 副本使用 `--preserve-symlinks-main --preserve-symlinks` 启动已准备的 `work/node-project/main.cjs`。本地 CommonJS 模块加载、中文文件往返、继承控制台句柄的原生子进程均已通过。这不代表 npm 下载、所有原生模块或默认管道捕获路径可用。

Claude Code 默认空配置会显示欢迎画面，然后因首次启动连通性检查失败而退出。显式 `-ClaudeOfflineGateway` 仅在本次空配置中设置文档支持的网关登录选项，地址为没有服务或凭据的 `https://cage-fixture.invalid`；本轮不会选择登录、输入模型提示或发送模型请求。此对照已进入真实主题选择界面并对 resize 重绘；该页面未响应两次 Ctrl+C，关闭终端 Job 可以回收进程并完成清理。这是设置界面和受控关闭的验证，不是登录后开发功能的验收。[Claude Code 官方错误说明](https://code.claude.com/docs/en/errors#unable-to-connect-to-anthropic-services)

Git 仅复制原生 `git.exe` 和同目录 DLL，禁用系统/真实用户配置、模板钩子、分页器与交互凭据。仓库盘和新建的 C 盘用户临时目录上，`git init` 都因取得完整工作目录路径而失败。原生诊断中，读取当前目录和打开目录句柄成功；`GetFinalPathNameByHandleW` 的 DOS 卷名模式返回访问拒绝，`VOLUME_NAME_NONE` 模式则成功。这将阻塞缩小到卷名路径转换，仍不是现成 Git 的修复；没有修改 Git 原件或宿主权限。Node 默认文件入口在 C 盘也仍因磁盘根 `lstat` 被拒而失败，不能仅靠换盘解决。[Git for Windows 路径实现](https://github.com/git-for-windows/git/blob/main/compat/mingw.c)

各轮结果保存在新实验目录的 `results.json`，原始终端输出位于各应用的 `out/terminal-app.txt`。脱敏汇总见 [verification-terminal-apps.json](verification-terminal-apps.json)。默认失败、配置对照和已通过范围分别记录；没有切换工作台默认后端。
