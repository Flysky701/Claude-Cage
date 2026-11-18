# Cage 开发主线

2026-11-18 整理。产品以 [上游 main](https://github.com/Lee-xeo/Claude-Cage/tree/main) 为基准。个人 fork 的 [main](https://github.com/Flysky701/Claude-Cage/tree/main) 是仓库首页，保留了自己的提交历史。个人开发沿下面两条主线接续。

| 开发主线 | 工作分支 | 进度与停点 |
| --- | --- | --- |
| Android | [`codex/android`](https://github.com/Flysky701/Claude-Cage/tree/codex/android) | 远程客户端、Cage Open 及 Android 对照实验统一到此。Cage Open 已完成 Google 登录和商店安装 Claude，Claude 登录仍返回 HTTP 400。各设备与方案的验证结果见 [Android 状态](../mobile/STATUS.md)。 |
| Windows 原生轻量隔离 | `codex/windows-local-native`，仅本机 | Phase 1 的已有记录覆盖隔离边界、宿主清理和核心应用的离线验证。工作台接入与完整在线流程仍待验证。在本机该分支打开 `tools/windows-local/STATUS.md`，或运行 `git show codex/windows-local-native:tools/windows-local/STATUS.md`。 |

### Windows 的两条保留路线

- **AppContainer 已暂停。** 终端等限定流程有验证记录，Edge、编辑器图形界面和 Claude Desktop 尚未完整通过。原型与证据集中在 [AppContainer 状态页](https://github.com/Flysky701/Claude-Cage/blob/codex/windows-appcontainer/tools/windows-appcontainer/STATUS.md)。
- **Windows Lite 保留历史检查点。** Sandboxie 的既有实现与工作台集成实验可从 [Windows Lite 检查点](https://github.com/Flysky701/Claude-Cage/tree/codex/windows-lite-checkpoint-20261115) 找回。

### 协作分支

五个上游投稿各用一个分支，便于维护者单独审核。第六个 Windows 汇总分支保存另外两笔实现。代理提示词与临时测试凭据的两条分支分别是个人 fork [PR #1](https://github.com/Flysky701/Claude-Cage/pull/1) 的目标和来源。

## Windows 与共享功能

截至 2026-11-18，五个贡献 Issue 均开放并等待审核。表中验证范围沿用各 Issue 的原记录。

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

两个关联问题均已关闭。此状态只说明问题已结案，两笔 fork 实现的采纳情况仍需按提交核对。
