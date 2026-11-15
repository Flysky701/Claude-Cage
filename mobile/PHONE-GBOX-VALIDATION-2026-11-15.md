# GBox 修改版真机实验（2026-11-15）

**18:32 合并状态：新 Cage UI 与补丁已完成合并并同签名覆盖安装。** 当前包为 Cage-Android-Review-Checks02.apk，SHA-256 为 1567aaf6c84e7af7dbecbcd90211358f9fc40602273b4541a63f5618b9075b61；本任务独立核对手机实装哈希一致。新 UI、原 Claude 登录态及外层/来宾测试标记保留，未重认证、清数据或发送消息。VPN 隧道元数据过滤通过所测路径；WebView 首脚本时区、断线保护及非隧道信息隔离仍有未完成项。详情见 [合并复核](sandbox/gbox-mod/android-shell/README.md) 与 [补丁交接](sandbox/gbox-mod/PRIVACY-REVIEW-2026-11-15.md#本轮实现验证与交接)。以下保留早先阶段的历史结论。

**17:10 后续状态：SIM 与 VPN 的已测 Java/原生路径通过，子进程 SIM/时区通过；WebView 首脚本仍泄露原系统时区，整体修复尚未完成。最终本地包已同签名原位安装，Claude 原登录态和原有测试数据保留。** 具体见文末第二阶段；以下原始登录实验结论保留为历史记录。

## 第一阶段：原 Privacy15 登录实验

**结果：Cage 内的 Google 账户添加和 Claude 登录成功。用户看到结果后明确确认通过，并要求不再测试。** 本轮因此没有发送测试消息，也没有继续做登录后的冷启动验证。

## 实际环境与产物

- Windows 主机；Xiaomi 15 Pro，Android 16 / API 36，原生 arm64-v8a。不是 MuMu 模拟器。
- Cage：`sandbox/gbox-mod/dist/Cage-GBox-Privacy-15.apk`，应用编号 `com.cage.android`，SHA-256 `8c2125b8a0bb20221a7b36c5ab8d1fc8ceb42e7578785d80f3db9128db36ff93`；安装前哈希与签名校验通过。本次没有使用后续 MuMu ContextFix 试验包。
- Claude：`1.261111.19 / 26111119`，base、arm64_v8a、xhdpi 三个原签名分包，签名验证通过，哈希与本地既有校验记录一致。没有修改或重签 Claude。
- 网络使用手机原有 FlClash，查看时为规则模式；本轮未改变节点、模式、VPN 或系统时区。
- 测试账号来自用户指定的本地文件。凭据仅在内存中读取后输入，没有写入本报告或实验记录。

## 登录与安装结果

| 项目 | 实际结果 |
| --- | --- |
| Cage 安装、主界面和内部应用启动 | 通过；与原版 `com.gbox.android` 并存 |
| Google 添加账号 | 通过；容器账号诊断记录一个 Google 账号，内部 GMS 和 Play 可查询到它；账号管理页当时未及时刷新 |
| Cage 内 Google Play | 官方应用详情和搜索可打开 |
| Google Play 下载 Claude | 未通过；多次零字节重试，记录 `CANNOT_CONNECT (8)`、`ERR_TIMED_OUT`，最终安装任务代码 6566。尚未确定下载连接超时的根因 |
| Claude 本地导入 | 通过；手机原先没有该包，安装已核验的三个分包作为克隆来源，再通过 Cage 的克隆入口导入。此路径不能记为 Play 安装成功 |
| Claude Google 登录 | 通过；标准账号授权返回后，实际看到已登录主界面、Free plan 和对话输入入口；用户随后确认通过 |
| 实际发送消息、模型回复、登录后冷启动 | 未执行；用户明确要求停止进一步测试 |

Claude 的运行进程 Linux UID 与 Cage 相同，外层 Claude 仅作为克隆来源，本任务没有启动或登录它。认证记录在 16:14:56–16:14:58 观察到 DroidGuard 服务连接、句柄初始化及成功返回，16:15:18 观察到 GoogleSignInAccount 返回。这说明本次真实流程跨过了此前模拟器的连接缺口，但不等于已解码或验证 Play Integrity 的全部判定标签。

## 隔离与屏蔽对照

使用 Probe06，先后取得外层与容器各两份完整报告，核对容器进程身份。外层存在真实 SIM 信号、上海时区及活动 VPN，可作为阳性对照。屏蔽结论以两份全新进程报告比较为准；测试标记另由四份报告核验。

| 项目 | 真机结果 |
| --- | --- |
| 普通私有测试标记 | `PASS_DISTINCT_AND_PERSISTENT`；外层与容器标记不同，各自重启后保留，四个独立进程会话证据齐全。仅覆盖测试 SharedPreferences，不代表对抗性隔离 |
| SIM 可见性 | 整体未通过；Java 路径隐藏，原生 get/read/read_callback 及子进程仍可读取运营商属性 |
| 时区 | 整体未通过；Java/ICU 为 Tokyo / +540，WebView 首脚本与后续读数仍为 Shanghai / +480，原生和子进程时区属性仍为 Shanghai |
| VPN 可见性 | 整体未通过；Java 能力查询隐藏 VPN，原生接口枚举仍有 `tun0` |
| 网络中断时禁止直连 | 未测试；查看时 Android always-on 和 lockdown 未启用，不能宣称失效断网已通过 |

运行日志明确出现 `nativeReadsRequested=false`、子进程策略 `sdk=false` / `nativeProfileVerified=false`，以及 `webview.UNSUPPORTED_ANDROID_VERSION`。对应当前模块的 API31/32 与 MuMu 环境限制。因此 **Claude 登录成功不代表 Android 16 的完整隐私屏蔽已通过**；本轮没有为了通过探针而放宽这些限制。

## 证据与保留状态

脱敏记录位于本机 `mobile/.build/gbox-mod/phone-20261115/`（不作为发布产物）：

- `outer-before.json`、`guest-before.json`、`outer-after.json`、`guest-after.json`
- `comparison-cold-start.json`、`comparison-persistence.json`
- `google-account-added.json`、`play-download-timeout.json`、`claude-google-attempt-01.json`

认证采集按 Cage 的实际 Linux UID 限定，仅保留固定事件、计数、布尔、组件名与安装状态。原始认证日志和界面 XML 未保存；页面操作时的邮箱与密码被隐藏。保存的商店截图仅用于确认 Claude 下载状态。

手机上的 Cage、测试账户、容器 Claude、测试探针以及用于克隆的外层原版 Claude 均保留；未清除原版 GBox 或其他个人数据。用户确认后停止设备实验，没有发送测试对话。

本轮没有修改应用功能源码、升级版本、创建标签、提交、推送或发布。仅验证 Windows 操作这台 Android 真机的流程；macOS、Linux 和桌面运行时未测试，也未修改。

## 第二阶段：Android 16 屏蔽修复，保留原数据

用户随后明确要求补齐 SIM、时区、VPN 并保留登录状态，重新授权了该范围的更新和验证；仍未发送 Claude 消息。

最终保留的本地包：`sandbox/gbox-mod/dist/Cage-GBox-Android16-Partial-20261115.apk`，SHA-256 `7094ba026f7c66740e6a8cd530b909e77857cf9e48340268e7a4a2aeb3982bc2`。包名、sharedUserId、版本号及签名证书与原 Privacy15 相同。构建脚本检查最终签名包的每个非签名 ZIP 条目：仅替换 `classes8.dex`、`lib/arm64-v8a/libcage_privacy.so`，添加 ARM64 子进程库、独立 ByteHook/ShadowHook 库与许可证。Manifest、其他 DEX、原容器核心、原 x86 子进程资产、四个预置 APK 和资源保持逐字节一致。没有升级版本、提交、推送或发布。

全部设备安装使用同签名 `adb install -r`，没有卸载、清除数据、迁移目录或重建账号。当前应用不能 `run-as`，因此没有可核验的完整私有数据备份；APK 基包和密钥不是账号数据的完整恢复备份。

### 修改内容与实测

- 原生 API36 路径使用单独的固定版本 ByteHook 1.1.2 / ShadowHook 2.0.1。原容器内 ByteHook 1.0.8 在该手机初始化失败，不修改其状态或代码。
- 根据实际手机 libc 验证 `getifaddrs` 节点所有权，使用原来的释放函数移除 VPN 节点；校验不匹配时不冒险处理未知布局。
- 修正 VLite 的实际加载路径范围：`getCanonicalPath` 会把物理目录转回虚拟目录，改为严格验证同一宿主环境提供的绝对路径，仅选中当前来宾。
- 增加带真实 ELF/API/来宾身份校验的 ARM64 子进程属性库，保留原 x86 路径。
- 新 WebView 156 仅支持进程内原生时区通知；独立 renderer 的首次异步同步仍存在竞态。没有用固定延时、修改探针结果或修改页面 Date/Intl 来宣称通过。

| 项目 | 最终结果 |
| --- | --- |
| SIM | 五轮记录均为 `PASS_FOR_RECORDED_PATHS`。Java、原生 get/read/read_callback、默认环境 getprop 子进程不再显示外层真实 SIM 属性 |
| VPN | 五轮记录均为 `PASS_FOR_RECORDED_PATHS`。外层有活动 VPN 和 `tun0`；来宾网络能力、回调、Java 接口及原生 getifaddrs 隐藏 VPN |
| Java / ICU / 原生 / 子进程时区 | Tokyo / +540；所测 UTC 时间戳保持一致 |
| WebView 后续读取 | Tokyo / +540 |
| WebView 首脚本 | **未通过**。Test07 安装后的首次读数偶然为东京，随后 3 次独立进程冷启动及最终包仍先读到上海；3 次冷启动分别在 13、9、11 ms 后切换到东京 |
| 原有数据标记 | 与本阶段前的标记一致。外层/容器四个独立进程会话验证 `PASS_DISTINCT_AND_PERSISTENT`，仅覆盖所测 SharedPreferences 标记 |
| Claude 登录态 | 最终包直接进入已登录主界面，Free plan、输入入口可见；Claude 进程 UID 与 Cage 一致（10382）。没有重新认证或发送消息 |

“首脚本”问题发生在测试应用首次创建独立 WebView 渲染进程时，不能归结为打开空间即影响所有应用。纯原生接口已通过。renderer 被回收后的重建、其他应用和多 profile 没有逐一验证，不能把本次探针范围推广为所有应用。

### 仍未解决及验证边界

- 首脚本完整时区保证需要 renderer 初始化入口，或能确认 renderer 已采用目标时区、且在此之前阻止目标页面脚本执行的机制。当前 Java 监视器通知没有完成回执；预热/延时不构成保证。
- 直接 `dlsym`、raw syscall/netlink、子进程 VPN 接口、显式/缓存的子进程环境不在已通过范围；未验证网络故障时禁止直连。
- 原生负对照中，超过旧属性名缓冲区长度的 `telephony.active_modems.max_count` 在外层和来宾的 legacy read 都被探针判为无效；因此负对照项仍为 `INCONCLUSIVE_MISSING_OR_INVALID_READINGS`，不能描述为所有控制项通过。
- Windows 构建和这台 Android16 真机已验证；macOS/Linux 构建、其他 Android16 libc/WebView、旧 MuMu 运行路径未在本阶段重测，桌面三平台功能源码均未修改。

最终证据仍位于 `mobile/.build/gbox-mod/phone-20261115/`：`android16-final-guest.json`、`android16-final-outer.json`、`comparison-android16-final.json`、`comparison-android16-persistence.json`、`android16-validation-rounds.json`、`android16-final-login.json`。各候选包独立保留；最终安装校验另存 `android16-installed-artifact.json`。登录状态文件仅含状态布尔、UID 和时间，不保存原始页面或账号名称。
