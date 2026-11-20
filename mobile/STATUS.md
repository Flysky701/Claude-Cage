# Open Cage 开发状态

长期分支为 `codex/android-open-cage`。从源码构建的 Android 产品，维护自己的候选版本、构建说明和验收记录。

Android 分为[Android 研究](https://github.com/Flysky701/Claude-Cage/blob/codex/android-research/mobile/STATUS.md)、[Cage 个人版](https://github.com/Flysky701/Claude-Cage/blob/codex/android-personal/mobile/STATUS.md)、[Open Cage](https://github.com/Flysky701/Claude-Cage/blob/codex/android-open-cage/mobile/STATUS.md)三条长期分支，各自在自己的分支开发、验证和发布，三条分支互不合并。

三条线路于 2026-11-21 从同一公开版本分开。此前的构建与验证记录见[分线前的 Android 状态](https://github.com/Flysky701/Claude-Cage/blob/40da83ed00727658f3eb69d38f7bcbe107304b34/mobile/STATUS.md)。后续进展和待验证事项记录在各分支自己的本页。

## 当前候选版 RC3.9

2026-11-21，Open Cage 已接续 **`1.0.0-rc.3.9`（版本码 `10011`，Android ARM64）**。本分支公开了空间应用管理、启动检查、界面资源和容器兼容性修复的[对应源码及补丁](open-cage/releases/rc3.9/README.md)。下表记录完整候选版的验证范围。

| 范围 | 结果 |
| --- | --- |
| 构建与产物 | APK 和配套源码 ZIP 的 SHA-256 均与构建报告一致。源码包中的 Gradle 版本为 RC3.9；包内 README 标题仍为 RC3.8，工作区说明已更新。 |
| 已有真机记录 | 原工作区记录了 Android 16 ARM64 同签名覆盖安装，读回版本码 10011。空间自检 16/16 通过，任务标题已去掉 `[B0]`。microG 设置可打开并返回，Google 邮箱登录页可加载，Google Play 登录页可返回商店主页。 |
| 待验证 | 在商店实际完成 Google 账号登录、下载安装 Claude、完成 Claude 邮箱登录和对话、冷启动后继续同一会话，以及运行中真实断开 VPN 后来宾进程是否终止。 |

构建报告中的 `realDeviceTested: false` 记录构建阶段的状态。表中真机结果来自之后的设备记录，本次整理未重新构建或上机。

本机交付目录为 `outputs/cage-open-1.0.0-rc.3.9/`，保存安装包、完整配套源码和构建报告。前一工作区版本的回退副本保存在本机 `outputs/cage-open-local-history/`。

## 上一版 RC3.8

`1.0.0-rc.3.8` 的真机记录读回版本码 `10010`，覆盖设置分组、出口绑定与解绑、主题弹窗和 Google Play 入口。RC3.9 的验收范围见上表。
