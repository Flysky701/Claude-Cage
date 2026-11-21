# Cage 开发主线

2026-11-21 整理。产品以 [上游 main](https://github.com/Lee-xeo/Claude-Cage/tree/main) 为基准；个人 fork 的 [main](https://github.com/Flysky701/Claude-Cage/tree/main) 对齐上游主线并作为仓库导航首页。Android 三条线路独立开发、互不合并，Windows 原生轻量隔离在独立分支接续。

| 开发主线 | 工作分支 | 进度与停点 |
| --- | --- | --- |
| Android · 研究 | [`codex/android-research`](https://github.com/Flysky701/Claude-Cage/blob/codex/android-research/mobile/STATUS.md) | 设备与容器实验、对照验证和研究记录，状态由该分支的 `mobile/STATUS.md` 维护。 |
| Android · Cage 个人版 | [`codex/android-personal`](https://github.com/Flysky701/Claude-Cage/blob/codex/android-personal/mobile/STATUS.md) | 基于 GBox 的 Android 个人版本，状态由该分支的 `mobile/STATUS.md` 维护。 |
| Android · Open Cage | [`codex/android-open-cage`](https://github.com/Flysky701/Claude-Cage/blob/codex/android-open-cage/mobile/STATUS.md) | 从源码构建的 Android 产品，状态由该分支的 `mobile/STATUS.md` 维护。 |
| Windows 原生轻量隔离 | [`codex/windows-local-native`](https://github.com/Flysky701/Claude-Cage/blob/codex/windows-local-native/tools/windows-local/STATUS.md) | Phase 1 覆盖隔离边界、宿主清理和核心应用的离线验证；工作台接入与完整在线流程继续在该分支 `tools/windows-local/STATUS.md` 维护。 |

### 历史基线与保留路线

- **Android 分线前基线**：2026-11-21 分线前的共享历史保留在 [`codex/android`](https://github.com/Flysky701/Claude-Cage/tree/codex/android)。
- **AppContainer 已暂停**：终端等限定流程有验证记录，Edge、编辑器图形界面和 Claude Desktop 尚未完整通过。原型与证据见 [AppContainer 状态页](https://github.com/Flysky701/Claude-Cage/blob/codex/windows-appcontainer/tools/windows-appcontainer/STATUS.md)。
- **Windows Lite 历史检查点**：Sandboxie 既有实现与工作台集成实验保留在 [Windows Lite 检查点](https://github.com/Flysky701/Claude-Cage/tree/codex/windows-lite-checkpoint-20261115)。

### 协作分支与标签归档

- 单节点中转投稿对应上游仍开放的 [#360](https://github.com/Lee-xeo/Claude-Cage/issues/360)，继续保留远端分支 [`codex/261116-Flysky701-imported-proxy-chain`](https://github.com/Flysky701/Claude-Cage/tree/codex/261116-Flysky701-imported-proxy-chain)。
- 已关闭的四个投稿用同名标签（`codex/261116-Flysky701-*`）归档；Windows 缓存与恢复汇总分支、早期代理提示词与一次性测试凭据分支及旧首页快照统一转为 `archive/*` 标签保存，旧分支已清理。

## Windows 与共享功能

截至 2026-11-21，贡献 #352、#353、#359、#361 已关闭并由上游主线落地，#360 仍开放。表中验证范围沿用各 Issue 的原记录。

| 修复 | 已记录的验证 | 待完成与提交入口 |
| --- | --- | --- |
| Windows 安装器拒绝 `/D=` 后续参数污染目录 | 14 项参数测试及 NSIS 3.13 脚本编译通过；Windows 安装、升级已确认通过 | 其他 Windows 版本及 NSIS 3.11 未测；[贡献 #352](https://github.com/Lee-xeo/Claude-Cage/issues/352)，提交 [`c50be19`](https://github.com/Flysky701/Claude-Cage/commit/c50be196730b417eb0de4726f2786e0aec9fe131) |
| Trojan 明文与 Base64 订阅导入 | 定向测试、原有 YAML 兼容、Mihomo 配置校验及前端检查通过；Windows 实际导入、应用与联网通过 | macOS/Linux 真机及完整发布构建未测；[贡献 #353](https://github.com/Lee-xeo/Claude-Cage/issues/353)，提交 [`37394c5`](https://github.com/Flysky701/Claude-Cage/commit/37394c5341352b57df7ea4870c5bee10676b6342) |
| code-server 首次查询过滤初始化日志 | 4 个定向用例通过，覆盖实际版本、初始化日志、无版本及失败输出 | 真实 Linux 客机首次运行、macOS/Linux 主机未测；[贡献 #359](https://github.com/Lee-xeo/Claude-Cage/issues/359)，提交 [`166bf09`](https://github.com/Flysky701/Claude-Cage/commit/166bf09e1b24263cb99b8a0dd438126818d764c2) |
| 单节点应用保留订阅内置中转并显示实际链路 | 代理路由定向测试、Windows Edge 界面对照、前端构建及改动文件检查通过 | 真实订阅联网及 macOS/Linux 未测；[贡献 #360](https://github.com/Lee-xeo/Claude-Cage/issues/360)，提交 [`ad93911`](https://github.com/Flysky701/Claude-Cage/commit/ad9391178196538f8bea41aba1718b769e654683) |
| 未签名 Windows 构建在下载前提示手动升级 | 更新器定向测试和 Windows Edge 界面测试通过；实际未签名程序确认未触发安装包下载 | 正式签名包的完整升级与回滚未验收；[贡献 #361](https://github.com/Lee-xeo/Claude-Cage/issues/361)，提交 [`e69ad4e`](https://github.com/Flysky701/Claude-Cage/commit/e69ad4eb4bd5bd9326e46609441e42d9579de6b2) |

另有两项早期实现保存在归档标签 [`archive/261116-Flysky701-windows-cache-fixes`](https://github.com/Flysky701/Claude-Cage/releases/tag/archive%2F261116-Flysky701-windows-cache-fixes)（上游相关问题均已结案并落地）：

- 缓存恢复目录只写入 DACL，避免改写所有者和审计信息：[`bb59b2b`](https://github.com/Flysky701/Claude-Cage/commit/bb59b2b3b9d37c828b141c8f24b7bfc1fe5c8a4e)，关联 [#303](https://github.com/Lee-xeo/Claude-Cage/issues/303)。
- 云部署核心下载支持缓存与续传：[`bf2c959`](https://github.com/Flysky701/Claude-Cage/commit/bf2c9598ca4d4616ffb3bf7a2f2bb4a82159bdc2)，关联 [#279](https://github.com/Lee-xeo/Claude-Cage/issues/279)。
