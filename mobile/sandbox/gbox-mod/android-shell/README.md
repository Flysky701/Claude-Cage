# Cage 安卓界面预览

2026-11-15：已按用户要求把现有容器作为 Cage 安卓初步版本，完成原生首页、启动检查展示及设置页。用户随后要求先停止排查未通过项，把隐私补丁交给另一个聊天，本目录的最终阶段因此仅更新 UI。没有升级版本、提交、推送或发布。

## 当前合并包（18:32 独立复核）

用户要求等待补丁完成后合并新 UI，并保留现有登录与数据。补丁任务已完成，本任务随后只读核对手机实装和完整证据，不重复安装。

- 当前已安装：[Cage-Android-Review-Checks02.apk](../dist/Cage-Android-Review-Checks02.apk)
- SHA-256：1567aaf6c84e7af7dbecbcd90211358f9fc40602273b4541a63f5618b9075b61
- 相对下面 UI 基线，仅改变 classes8.dex、classes11.dex、assets/cage-android/preflight.apk；没有新增或删除条目。新首页 UI 类、Manifest、图标、全部原生库及四个预置 APK 保留。
- 独立复现最终 classes11.dex，确认 APK 内代码对应已校验的类缓存；UI 的四个类文件与基线逐字节一致。包名、版本、证书和手机 UID 10382 保持。
- 最终包 Claude 直接进入已登录界面，未重新认证或发送消息。重新对比完整的更新前后报告，外层/来宾原 SharedPreferences 标记分别保留、彼此不同，四个独立进程会话证据齐全。该结论不等于全部私有数据备份/恢复验收。
- 实装哈希与以上合并包一致，手机停留在新 Cage 首页。没有再次重装，没有清数据、改全局网络设置、升级版本或发布。

独立记录：mobile/.build/gbox-mod/ui-merge-verification/checks02-static.json 和 final-installed-and-data.json。补丁运行证据与仍未解决项见 [本轮补丁交接](../PRIVACY-REVIEW-2026-11-15.md#本轮实现验证与交接)。当前 UI 为 10 项通过、1 项未通过、4 项未确认；WebView 首脚本时区、断线保护和非隧道网络信息隔离尚未全部完成。

## UI 基线（原交付）

- 安装包：[Cage-Android-UI-Preview-20261115.apk](../dist/Cage-Android-UI-Preview-20261115.apk)
- SHA-256：55b7b21e72bea49e7019f71e0abcd43829dc46887a92096c677b9d6ece2602c7
- 应用：com.cage.android，versionCode 1080402 / versionName 1.8.4.02
- 证书 SHA-256：0e5eff3a71f39a5df1602fbc3691a35622d0b9d429b4f66ed6f4de6590a6fafb
- 当前手机 UID 10382 保持；同签名 install -r 原位更新，无卸载、清数据、迁移目录或重建账户。

真机界面检查、安装哈希核验和本任务装机操作已结束。可将此包作为下一轮隐私补丁的精确输入；覆盖时保留 classes11.dex、新首页 Manifest 和 assets/cage-android/。相关补丁任务已告知将另行接入网络元数据检测；本 UI 包没有提前纳入其未验证源码。

## 设计与交互

- 风格取自共用桌面 ui/src/appearance-presets.mjs 的 Codex 配色、style.css 的首页/检查列表，以及 ui/src/logo.png。中性背景、细边框、黑白主按钮，蓝色只用于当前导航；无新生成 Logo。
- 首页：现有默认空间、时区/网络/SIM 策略摘要、启动入口、真实应用列表。预置 helper 和 microG Companion 从日常列表收起，组件与数据保留。
- 启动检查：汇总计数、可展开项目、固定底部操作、脱敏摘要复制。手动继续不改变检查结论；历史报告可查看，但不能授权启动。
- 设置：空间管理、外观、环境配置说明、适配边界与检测服务说明。支持跟随系统、浅色和深色，仅影响 Cage 外观。
- 应用添加和 Google 账户仍调用原有管理页；本次没有重写其认证/安装实现。
- 当前为一个真实空间，不提供尚未实现的多空间创建入口。

用户选择测试模式：显示未通过/未能确认项后，允许明确手动继续。授权保存在内存中，重建 Activity 不恢复授权；5 分钟或网络/系统环境变化后需要重新检查。该入口门禁不覆盖外部通知、快捷方式和原管理页，不是系统级网络防火墙。

## 文件范围与构建

UI 源码为 java/io/github/leexeo/cage/shell/ 下的 HomeActivity.java、CageTheme.java、LineIcon.java。其余文件是此前接入的容器桥、检测解析、探针运行与放行策略；java/io/github/leexeo/cage/preflight/NetworkProbe.java 为固定 HTTPS 出口查询。manifest.py 只迁移原 Splash 的桌面启动入口并注册新 Activity，不重编译原资源。

初始 Preview-Test01 在 Android16 Partial 包上新增 classes11.dex 与检测 APK，调整 Manifest 启动入口。最终 UI-only 构建相对 Preview-Test01：

- 仅替换 classes11.dex 并添加原项目 assets/cage-android/logo.png。
- 编译前用基准缓存重新生成 DEX 并校验与基准相同；非 UI .class 字节完全保留。
- 原 Manifest、其他 DEX、隐私原生库、容器核心、预置 APK、检测 APK、资源均逐字节保留。
- 最终签名包重新核对证书、包名、版本、启动 Activity、每个非签名 ZIP 条目及重复类。

本地 UI-only 复现需要基准 APK、初始构建缓存及原开发密钥；不是空克隆即可执行的完整源码构建：

~~~powershell
python mobile/sandbox/gbox-mod/android-shell/build.py --ui-only --base mobile/sandbox/gbox-mod/dist/Cage-Android-Preview-Test01.apk --base-sha256 70e923053ba098cbd320ff5f8baae05434d1c0be4b7b459e12cf93dc5978f1b6 --output <新的本地APK路径>
~~~

初始构建缓存 mobile/.build/gbox-mod/android-shell-b3065109；最终构建缓存 android-shell-8c595304。APK、缓存与开发私钥不进入 Git。默认完整构建路径会编译当时的检测源码，不应在其他任务尚未完成补丁时混入其工作区变化。后续隐私覆盖可使用该任务的 recipes/build_android16_overlay.py --base <本次最终包> --base-sha256 <以上最终哈希>，其余参数按该脚本要求。

## 验证与未完成范围

Windows 构建、签名、ZIP 差异及 21 项原有放行策略测试通过。Xiaomi 15 Pro / Android16 上已查看浅色和深色的首页、历史检查页、设置页，核对导航、边框、图标和应用显示；完成后恢复“跟随系统”。实机截图在 mobile/.build/gbox-mod/phone-20261115/ui-preview/，结构化验证记录为同目录上一级 ui-preview-validation.json。

此前 UI 接入阶段曾观察到 9 项通过、1 项未通过、4 项未能确认的界面；后续检查出现“未取得本轮结果”。此问题尚未归因。用户要求转为 UI 工作后，本任务没有继续启动检查或排查该问题；因此不能把初始一次结果视为启动检测整体稳定通过。

本最终阶段未重新验证 Claude 登录、消息发送、断线保护或隐私屏蔽。已有登录成功结论属于之前的真机报告和用户确认。当前底层仍有 WebView 首脚本时区缺口，检查语义保持未通过；补丁任务后续负责新证据与判定接入。

桌面 macOS / Windows / Linux 功能源码未修改。视觉沿用三平台共用设计；本地构建工具仍为既有 Windows 工具链，macOS/Linux 构建、其他 Android 设备和横屏未实测。
