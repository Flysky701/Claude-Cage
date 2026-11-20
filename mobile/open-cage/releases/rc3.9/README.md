# Open Cage 1.0.0-rc.3.9 · 公开源码

Android ARM64，版本码 `10011`。本目录保存 RC3.9 的部分产品源码。Java 文件、界面资源和检查用例取自该版本配套源码包，保留包内路径。本目录不能独立构建完整 APK。

| 内容 | 源码入口 |
| --- | --- |
| 空间应用列表、安装与移除、商店入口，以及 microG 设置返回时的处理 | [SpaceApps.java](app/src/main/java/io/github/flysky701/cage/open/SpaceApps.java) |
| 安装包读取与空间内卸载 | [ClaudeBundle.java](Bcore/src/main/java/io/github/leexeo/cage/space/ClaudeBundle.java) · [CandidateClaudeRemoval.java](Bcore/src/main/java/io/github/leexeo/cage/space/CandidateClaudeRemoval.java) |
| 用户发起的 microG 设备注册设置 | [GuestMicrogSetup.java](Bcore/src/main/java/io/github/flysky701/cage/privacy/GuestMicrogSetup.java) |
| 启动条件、检查报告与判定用例 | [CheckPolicy.java](app/src/main/java/io/github/flysky701/cage/open/CheckPolicy.java) · [CheckReport.java](app/src/main/java/io/github/flysky701/cage/open/CheckReport.java) · [CheckPolicyTest.java](verification/CheckPolicyTest.java) |
| 界面主题、图标和对话框资源 | [CageTheme.java](app/src/main/java/io/github/flysky701/cage/open/CageTheme.java) · [LineIcon.java](app/src/main/java/io/github/flysky701/cage/open/LineIcon.java) · [Android 资源](app/src/main/res/) |
| 登录页稳定性和任务标题修复 | [RC3.8 到 RC3.9 的运行时补丁](rc3.8-to-rc3.9-runtime.patch) |

运行时补丁以 RC3.8 配套源码为基线，涵盖四个文件。它保留应用所需的共享库信息，使主线程遇到致命异常时能退出，并在任务标题中保留应用名称和图标。本次将补丁应用到对应的四份 RC3.8 源码，逐一核对了结果与 RC3.9 的一致性。该版本沿用的 Android Service 生命周期与 Activity 路由补丁见[项目补丁目录](../../../../patches/blackbox-reborn/)。

原配套源码 ZIP 的 SHA-256 为 `e88266c332a6db17ea745150ce3f32f7a8e4bf490c817702bdcaa45a8c9706d4`。原包内 README 标题沿用 RC3.8，Gradle 中的版本为 RC3.9。设备验收结果与待测项目见[本分支状态](../../../STATUS.md)。许可见[项目 LICENSE](../../../../LICENSE)和[BlackBoxReborn 原始许可文件](licenses/BlackBoxReborn-LICENSE.txt)。
