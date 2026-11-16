# 0.0.6 成功路径与单变量对照（最新）

2026-11-16，继续由独立 GPT-6.1 Terra 对话操作手机。本轮保留已有 GBox 会话，
另建独立 GBox 对照，并对开源版做可回退的诊断构建。**尚未修通开源版 Claude 登录。**

17:43，新 GBox 对照在无 JDWP 的情况下成功进入同版 Claude 首页；已采到完整性
调用经过 MGC、`pia_attest_e1`、本地 Embedded DroidGuard 初始化、返回 Classic
令牌、交付 Google 凭据的连续元数据。它明确走本地路径，不是已证明依赖云端转发。
成功令牌为 1854 字符、5 段；Cage + 上游 Companion 为 1443 字符、5 段后返回 HTTP 400。
包名、版本、32 字节 nonce 长度及原版 Claude 证书均匹配；长度差异不能当作解码判定。

| 定向对照 | 观察 |
|---|---|
| 保留 microG 原样算法注册，撤掉 Cage 的补齐 | 1443 字符，HTTP 400；已恢复 |
| 禁用 Claude 隐私模块 | 已确认未加载该隐私库，仍为 1443 / HTTP 400；已恢复 |
| 仅选择上游 Android 13 ARM64 配置 | 界面选择成功，但未确认请求进程采用该配置 |
| 配置字段对齐候选 | 请求进程未初始化目标配置，明确跳过；不能作为有效对齐试验 |
| 经 GMS Application context 初始化配置后对齐 | 目标配置生效，19 项匹配、14 项改变、0 失败，实际 SDK 不变；仍 HTTP 400 |
| 仅替换 DroidGuard 服务上下文 | 上下文所检查的属性原本一致；绑定时未初始化，随后请求阶段加载目标配置；仍 1443 / HTTP 400 |
| Companion 采用同类证书链策略 | 策略已安装，但未观察到 Companion 查询证书链；仍 1443 / HTTP 400 |
| API 31、初始 SDK 29 自定义配置及字符串对齐 | 三项配置布尔值均为真；19 项匹配、13 项改变、0 失败，实际系统 SDK 不变；仍 1443 / HTTP 400 |

上游已自带 `sdk_gphone64_arm64_33`，无需复制 GBox 的私有配置或二进制。
配置保存与冷启动持久化正常，现有日志出现过 profile 查询返回 null；后续同次诊断中，
Application context 查询有效并成功初始化。18:30 的记录进一步纠正了早前推断：
绑定时尚未初始化，随后请求阶段自然加载配置，因此不能据绑定时的字段状态认定
配置传递故障。服务上下文候选未证明有效，不作为正式修复。
当前构建没有包含全局 `GuestTelephonyPolicy`。

GBox 的配置虽以 Android 13 命名，实际 profile 数据为 SDK 31、初始 SDK 29。
18:39 已经通过上游自定义配置机制完成该数据对齐并确认生效，仍未改变失败结果。
这否定了“仅对齐这组配置即可修好”的判断。所有失败的诊断候选均已恢复，未合并进正式版本。
下一项有区分力的验证是独立副本内的组件交叉对照，以区分 Google 服务实现与容器行为。

新增 `diagnostics/attestation/capture_integrity_route.py` 只输出允许的事件、布尔值和长度，
不保留原始日志或令牌。已修复 CRLF 造成完整匹配事件漏采，并从同次缓冲补回元数据。
完整实验结果及补回事件见 `validation-success-path-2026-11-16.json`。测试候选不是发布版；
下面保留早前阶段记录，其中“本轮无新 APK”等描述只适用于对应历史阶段。

# 0.0.6 同版本新登录对照（接续）

2026-11-16，手机操作由单独的 GPT-6.1 Terra 对话执行，接续对话负责源码、诊断工具和记录。
本轮没有修改 Cage 运行时或生成新 Cage APK；沿用 `0.0.6-login-preview` 与 Claude `26111319`。

| 对照 | 结果及范围 |
|---|---|
| Cage 早前冷启动首次登录 | 旧证明 MINTED，5644 ms；新证明分支未触发；请求对象中的旧证明存在，client_attestation 为空 |
| Cage 配置观察 | 44 项配置；凭据绑定证明开关无服务端记录/本地覆盖；尝试计数 1，无封锁时间 |
| 原 GBox 新登录 | Google 账号认证完成，Claude 仍显示 Play 验证失败；不能再以昨日会话代替今天的新登录 |
| 独立 GBox，同版 Claude，附加调试器 | 旧证明 MINTED，6024 ms，新证明分支未触发；返回 missing_client_attestation |
| 独立 GBox，同版 Claude，无调试冷启动 | 17:11 进入已登录主页，显示 Free plan 和输入框；没有发送消息 |
| Cage，同一时间窗口，无调试冷启动 | 17:12 仍显示 Play 验证失败，/auth/verify_google_mobile 返回 HTTP 400；GBox 会话和网络设置保留 |
| Cage，临时上游 Companion，无调试登录 | 17:19 仍失败并返回 HTTP 400；日志确认 Companion 完整性服务被调用，随后恢复原商店及 CE/DE 数据 |

独立 GBox 克隆的基础 APK 已核对与 `26111319` 原包一致。带调试的请求对象可能是组装中的
中间对象，不能把其旧证明字段为空当作最终发送字段。无调试成功时没有读取请求字段、
服务端成功状态或解码 Claude 令牌；调试器、时序、缓存和服务端变化尚未单独控制。
因此现在已有同版本、相近时间的新登录成功对照，但不能据此断言调试器是唯一失败原因。

上游 Companion 使用 `0.3.18.40226 / 84022636` 原包。替换前停止宿主并新建原商店备份，
原 CE/DE 目录移开保存；测试后通过原版 APK 恢复包登记，再移回原数据。恢复后的商店
为 `45.7.17-31 / 84571730`，原 APK 一致，测试账号与 Claude 数据保留，GBox 成功会话未动。
这轮只排除了“仅换上游 Companion 就能登录”的候选；不等于 GBox 的定制 MG/MGC 与上游
组件完全等价，也没有定位完整性响应中哪一项导致 Claude 服务端拒绝。

随后只读检查现有日志缓冲，未找到 GBox 17:11 成功登录那次的完整性请求事件，不能比较
该次令牌、证书绑定或 DroidGuard 路径；不把“未采到”写成“未发生”。没有为补日志退出
成功会话或重复登录。当前没有已证实的运行时修复；后续有效证据应来自成功请求的无调试
元数据/执行路径与 Cage 的定向对照，或服务端提供的具体拒绝原因。

### 对补充分析的校正

- 开关缺失能够解释已观察到的新证明分支未触发，不能单独证明服务器为什么拒绝旧证明。
- 凭据绑定的新证明仍经 Classic Play Integrity API 取得；“challenge”不等于 Standard API。
- 普通来宾硬件探针的证书含宿主身份是真实观察，但并不是 DroidGuard 收到了该证书的证明。
  已有 `MicrogKeystoreCompat` 仅补齐算法注册，保留上游证书链阻断；此前无调试请求已观察到
  `engineGetCertificateChain` 被拒绝。因此没有依据把复制 GBox Keybox 作为本轮登录修复。
- Claude 的真实令牌未解码。它是加密的 JWE/JWS；Google 解码需要关联项目的服务账号，
  本地解密需要该应用的响应解密密钥。本项目自有探针的解码权限不能代替 Claude 项目权限。
  参见 [Google 官方解码说明](https://developer.android.com/google/play/integrity/classic#decrypt-verify)。

### 上游和工具

microG `v0.3.18.252432...master` 在本轮仍为 `identical / ahead_by=0`。
BlackBoxReborn 锁定提交之后的 3 个提交涉及 WhatsApp 完整性桥接与会话导入；
[最新提交](https://github.com/fdavids77/BlackBoxReborn/commit/7b86a9d62a974650e0659825758931cd91140827)
自身记录了令牌替换路线未奏效。没有将其认定为 Claude 修复或直接升级运行时。

已归档同版本只读 `FlagState.java`，修正 `LoginTrace` 观察超时提示，使请求和分支对象是否
观察到分别呈现；轮询保持完整 45 秒窗口，避免看到中间对象和分支后提前退出而漏掉
后续请求对象。这个修正尚未追加真机诊断，不将其视为对最终请求正文的取证。
两者使用 JDK 17 编译通过，不进入 APK。
结构化对照与后续 Companion 登录实验以本目录 `validation-login-2026-11-16.json` 中
`continuationSameVersionControls` 为准。下面保留各历史阶段当时的结论。

# 0.0.6 Google Play 验证后续定位

2026-11-16 16:13（北京时间），沿用已安装的 0.0.6，在同一真机、原版 Claude
`1.261113.19` 上继续测试。**尚未修通 Claude 登录；本轮没有新的 APK 或已证实有效的运行时补丁。**

| 新证据 | 可以得出的结论 |
|---|---|
| 商店 `ownership` 中 Claude 的一条记录与授权测试账号匹配 | 不能简单归因为账号从未获取过应用；数据库记录不等于 Google 解码的 `LICENSED` 判定 |
| Claude 实际登录请求对象的 Google 凭据存在，`play_integrity_token` 非空（1443 字符） | 旧式证明并未在请求组装前丢失；没有输出或解码令牌 |
| 可选 `client_attestation` 为空 | 新字段没有随这次请求提供；不能据此推定强行补字段就会获准 |
| 服务器错误对象为 `InvalidRequestError`，枚举 `MISSING_CLIENT_ATTESTATION`、错误码 `missing_client_attestation` | 缩小了服务端错误分类，但不能唯一判定是设备、应用、许可或请求绑定未被采信 |
| 断开调试、重启 Claude 来宾后重新登录，仍显示 Google Play 验证失败 | 失败可在无调试请求中复现；请求结束后才只读取得该次错误分类 |

GBox 的经典请求绑定字段（包名、版本、证书摘要、nonce 摘要及编码后的请求参数）与上游
[IntegrityService.kt](https://github.com/microg/GmsCore/blob/v0.3.18.252432/vending-app/src/main/kotlin/com/google/android/finsky/integrityservice/IntegrityService.kt)
大体一致。当前安装的是原版完整商店，不能把 Companion 的静态代码比较当作完整商店的运行跟踪。
[上游 tag 与 master 比较](https://github.com/microg/GmsCore/compare/v0.3.18.252432...master)
本次返回 `identical / ahead_by=0`，没有更新的提交可直接用于修复。
GBox 之前成功使用的是较早的 Claude `26111119` 与既有会话，尚不是同版本、同时间的新登录阳性对照。
两版 Claude 均含有上述新旧证明字段，不能只按版本差异认定原因。

新增的 [只读诊断器](diagnostics/login/README.md) 已在本机编译并运行，记录存在性、长度与
错误类别，不进入 APK 构建，不修改账号、凭据或验证结果。早期方法事件/断点诊断遇到
Android 16 JDWP 不稳定与来宾退出，已从最终诊断器移除；最终无调试复测能正常到达原错误页。
未清空数据、未修改 GBox、未更改手机网络、未发送 Claude 消息。原有屏蔽补丁与 0.0.6 安装保留。

没有 Claude 项目的令牌解码权限或服务端校验日志，仍不能把 `missing_client_attestation`
解释成某一个具体 Integrity verdict。后续修复需要证明输入或请求绑定的具体差异；本轮没有把
可选字段为空、商店数据库记录或上游代码相似当作“已找到修复”。

# 0.0.6 Claude Google 登录真机记录

2026-11-16，用户提供并授权直接使用 Google 测试账号。沿用已打隐私补丁的空间，覆盖安装
同包名、同签名的 0.0.6；未清空来宾数据，未修改手机网络或 GBox 版 Cage。

**Claude 尚未登录成功。** Google 账号认证和真实凭据回传已走通，随后 Claude 显示：
“登录无法完成，因为此应用无法经 Google Play 验证。”同次请求记录为
`HTTP 400 /auth/verify_google_mobile`。Claude 已连接空间内原版商店的完整性服务并收到请求
回调；没有解码 Claude 项目的令牌，不能用这条提示唯一归因于 DEVICE、应用识别或许可。

| 观察到的问题 | 本轮修改与复测 |
|---|---|
| 系统 CredentialManager 以宿主身份进入认证，返回 `[16] Account reauth failed` | 来宾进程将系统凭据服务标为不可用，启用 Claude 原包自带的 AndroidX Play Services 回退；新调用的客户端包名为 Claude |
| microG 已取得真实结果，宿主 PendingIntent 中转却提前返回取消 | 复用仓库 `GuestPendingActivity.java` 的私有回传实现；先由 Android 消费原始一次性能力，再保留原调用页与请求号派发来宾页面，注册、领取、系统接受和私有派发均有记录 |
| 回传恢复后出现 `No provider data returned` | 复用 `GuestCredentialResult.java`，仅把 microG 的结果容器转为 Android 14+ Parcelable，凭据数据 Bundle 原样保留；适配后进入 Claude 的 Google Play 验证错误页 |

回传入口限制为当前空间的原签名 microG 与 Claude；保留真实 PendingIntent 的所有者、
可变性、一次性消费及私有页面检查。不生成账号、成功结果或凭据，不替换完整性令牌。
框架入口处理参考 AndroidX 的
[CredentialProviderFactory](https://github.com/androidx/androidx/blob/androidx-main/credentials/credentials/src/main/java/androidx/credentials/CredentialProviderFactory.kt)
与 [CredentialProviderFrameworkImpl](https://github.com/androidx/androidx/blob/androidx-main/credentials/credentials/src/main/java/androidx/credentials/CredentialProviderFrameworkImpl.kt)。

测试账号存在于 Cage 私有账号文件，系统账号列表不包含该账号。文件中的邮箱密码与 Google
密码是不同字段；一次误用邮箱密码被 Google 拒绝后，改用对应 Google 密码完成认证。
未注册人脸视频、未发送 Claude 消息、未购买或消耗付费服务。报告不包含账号或凭据值。

此次新增构建已通过；从全新目录重新准备源码并与编译目录核对。0.0.5 隐私代码保留，
本轮未重跑已通过的整套隐私探针，未把 Google 登录回传通过视作设备完整性或 Claude 登录通过。
具体交付身份与验证结果见 [validation-login-2026-11-16.json](validation-login-2026-11-16.json)。

# 0.0.5 屏蔽补丁真机记录（历史）

2026-11-16，用户将顺序改为先打屏蔽补丁、由用户测试 Claude 登录。本版不以设备完整性通过
作为安装或启动门槛。沿用同一包名和签名，以 `adb install -r` 覆盖安装，未清空现有空间。

复用本仓库此前 Android 16 隐私模块的 Java、原生和子进程实现，通过 `privacy.py` 将来宾
身份、文件路径、生命周期和服务分发入口适配到 BlackBox。不输入 GBox APK、DEX 或容器库。
额外的开源依赖固定为 ByteHook 1.1.2 / ShadowHook 2.0.1，原有哈希校验与许可证一起保留。
SIM 和时区属性通过当前选定进程的读取适配生效，不写 Android 共享属性，不改变设备身份。

补丁选择 Claude、独立隔离验收探针及内置基础探针；microG、商店和宿主不启用屏蔽策略。
时区为 `Asia/Tokyo`。真实 VPN 路由和手机网络配置保持现状，VPN 补丁改变的是应用可见信息。
UI 增加“打开 Claude · 测试登录”，不自动提交账号、认证或消息。

在同一台 Android 16 ARM64 手机上，使用原有 Probe06 原包取得外层阳性对照，并导入开源
Cage 私有空间验证。首个候选包的默认 SIM 订阅号仍有效；定位为 BlackBox 缺少 ISub 服务
入口后补齐，由相同选定进程策略处理。最终包在新进程中复测如下：

| 检查 | 最终结果 |
|---|---|
| SIM | `PASS_FOR_RECORDED_PATHS`；Java、默认订阅号、三种原生属性接口和默认环境子进程均无所测 SIM 信号 |
| VPN 可见性 | `PASS_FOR_RECORDED_PATHS`；网络能力、回调、Java 接口与原生 getifaddrs 不显示 VPN / tun0 |
| 活动隧道 LinkProperties | `PASS_FOR_RECORDED_ACTIVE_TUNNEL`；已识别隧道的地址、DNS、路由等元数据被屏蔽 |
| 时区 | `PASS_FOR_RECORDED_PATHS`；Java/ICU、原生、子进程、WebView 本次首脚本及后续读取均为东京 / +540 |
| 内置基础探针 | 原计数延续到 12；GMS/商店版本、私有 UID、原包签名、兼容签名、安装状态与 Claude 启动查询均通过 |
| Claude 启动 | 原版 `1.261113.19` 正常显示“使用 Google 继续”和邮箱登录页；实际进程 UID 为开源 Cage 的 UID |
| Claude 补丁激活 | 同一 Claude 进程记录 SIM/timezone/VPN 均启用、原生绑定返回 2、子进程策略启用、WebView 监视器在引擎前准备 |
| Claude 登录 | 留给用户实测；本轮没有点击 Google 登录、输入账号或发送消息 |
| 设备完整性 | 本轮未重测；此前未取得 DEVICE，不能以屏蔽探针通过代替完整性通过 |

结果仅覆盖探针记录路径。WebView 的跨进程首次时区仍没有同步完成保证，本次与首个候选包
各观察到一次首脚本为东京，不能据此消除既有竞态。直接 syscall/netlink、显式子进程环境、
网络故障时禁止直连未验证。原生属性负对照仍有 legacy read 长键无效项，报告保留
`INCONCLUSIVE_MISSING_OR_INVALID_READINGS`。本轮没有新建完整的四进程数据隔离测试，
只确认同签名覆盖、原有探针计数及组件保留，不扩大为完整隔离结论。

最终 APK 为 `Cage-Open-Bundled-Preview-0.0.5.apk`，对应
[validation-privacy-2026-11-16.json](validation-privacy-2026-11-16.json)。具体原始测量保存在
本机 `mobile/.build/open-cage-store-test/privacy-test/`，交付摘要不含账号、令牌、设备标识或
代理地址。手机停留在开源 Cage 的 Claude 登录页，供用户继续操作。

# 0.0.4 商店与设备完整性真机记录（历史）

2026-11-16，沿用现有工作目录及测试实例，使用 ADB 在 Android 16 / API 36 / ARM64 真机验证。microG 仍为上游最新正式版 `0.3.18.252432` 原包；未另建实现分支。

| 项目 | 实测结果 |
|---|---|
| 原版 Play 商店 | 测试账号保留，目录、搜索和 Claude 详情可用 |
| 真实下载与私有安装 | 5 个下载载荷，27,995,566 字节；校验并安装 4 个原签名 APK；安装提交状态 0 |
| Claude 安装状态 | `1.261113.19` / `26111319`；商店显示“已安装”“打开”，未启动登录 |
| 内置探针 1.5 | 数据计数保留；UID、原包及兼容签名、安装状态、来源及启动查询检查通过 |
| Cage 经典完整性请求 | 取得真实令牌，Google 解码返回设备标签空数组；应用和许可均 `UNEVALUATED` |
| Cage 标准完整性请求 | 修复 JNI 崩溃后取得真实令牌；Google 解码同样返回空设备标签 |
| 手机系统环境对照 | 同一自有测试 APK 返回 `MEETS_DEVICE_INTEGRITY`，应用识别 `UNRECOGNIZED_VERSION`、许可 `UNEVALUATED` |

**Cage 内设备完整性未通过。** 令牌已校验包名、nonce/requestHash 和十分钟时效；没有替换令牌、借用系统环境结果或改写 Google 判定。系统对照只用于定位问题，不能算 Cage 通过。

**判定范围修正（2026-11-16）：** 下文 `[]` 是助手对缺失设备标签的显示归一化；已保存的 Cage
原始结果通常为 `deviceIntegrity: {}`。本测试项目未关联 Play Console，也未上架取得 Play
许可。[官方文档](https://developer.android.com/google/play/integrity/verdicts#optional_device_information)
规定 BASIC/STRONG 属于可选标签，且 Android 13 以上还要求请求应用具有 Play 许可才返回。
所以本记录确认的是“Cage 未取得 `MEETS_DEVICE_INTEGRITY`”；不能据此写成“BASIC 已失败”。
`UNEVALUATED` 不能单独定位宿主身份、某个容器特征或 microG 本身。尚缺少可比的、脱离容器的
上游 microG 基线，不能从当前组合失败推导所有 microG 或所有容器必定失败。同日补做的 GBox
实测也未返回 DEVICE 标签，见下节。下一步应优先补齐设备信号路径的证据；Binder/PM
只在出现新的具体异常时修复，不再用无针对性的兼容补丁碰运气。

## 同机 GBox 对照与 DroidGuard 执行证据（2026-11-16）

用户没有备用 microG 手机，继续使用当前预装官方 GMS 的手机。没有卸载系统 GMS、变更 ROM
或重新配置签名兼容，因此仍不能声称已补齐“脱离容器的上游 microG”基线。本轮补的是同机、
同网络、同一自有测试 APK 的 GBox 对照，并重做当前系统与开源 Cage 的经典请求。

| 环境 | 新请求 | Google 解码结果 |
|---|---|---|
| 已成功登录 Claude 的 GBox 版 Cage `com.cage.android` | 经典、标准各一次 | 两次均未返回设备标签；应用识别、许可均 `UNEVALUATED` |
| 系统官方 GMS | 经典一次 | `MEETS_DEVICE_INTEGRITY`；应用识别 `UNRECOGNIZED_VERSION`，许可 `UNEVALUATED` |
| Cage Open 0.0.4，保留算法注册修复 | 经典一次 | 未返回设备标签；应用识别、许可均 `UNEVALUATED` |

四次判定均使用 Google 返回值，并通过包名、nonce/requestHash 和时效校验；没有附加调试器。
GBox 中测试应用、MGC 和 microG unstable 进程都属于 GBox 宿主 UID。没有将系统结果转用给
容器，也没有重签测试 APK。GBox 既有隐私补丁与 MG/MGC 版本仍保留，所以它是整个可运行环境
的比较，不能单独隔离 microG 或容器影响。

**此前 GBox 的 Claude 登录成功，与本次自有探针没有 DEVICE 标签可以同时成立。** 这不证明
Claude 也能在 Cage Open 登录，也不证明 GBox 在之前登录时得到过 DEVICE 标签。不能再把
“GBox 曾登录成功”当成完整性已通过的正对照；继续遵守先完整性、再屏蔽、最后 Claude 登录。
本轮没有打开 Claude、重新认证、清空数据或发送消息。

新增独立诊断工具 `diagnostics/attestation/SignalTrace.java`，不进入 Android APK。它只观察
选定方法与调用栈、允许的键名/路径类别，以及 VM 初始化布尔和输出长度；不记录信号值、账号、
文件内容、密钥别名、证明链或令牌。两次有请求的短时跟踪均仅用于诊断，没有拿去解码验收。
一次先前空闲采集没有触发请求，单独保留，不作为调用证据。

第二次跟踪确认以下实际执行链：

- DroidGuard `init()` 返回 `true`，`rb()` 返回非空对象。
- microG `DroidGuardHandleImpl.snapshot()` 调用实际 VM 的 `ss()`，返回 34,530 字节。
- 本次未观察到 `FallbackCreator.create()`；VM 随后正常 `close()`。因此，本次不是仅返回
  microG 错误回退数据的路径；这仍不能说明 Google 采信其结果。
- 实际 VM 栈下查询了 GMS、商店、Android 和自有测试应用的包信息，调用了 `Build.getSerial`、
  `TelephonyManager.getImei`、`getPhoneType`、Settings、系统服务以及文件 open/access/stat。
- 证书链读取到达 microG 阻断器并抛出其预期的 `UnsupportedOperationException`；未重现
  已修复的 `NoSuchAlgorithmException`。另观察到非显示 Context 的 `getDisplay` 异常、文件
  访问错误和 `getFlashLockState` 的 `SecurityException`，这些没有阻止本次 VM 产出字节。

系统包管理器显示官方 GMS 获授 `READ_OEM_UNLOCK_STATE`、`READ_PRIVILEGED_PHONE_STATE`
和 `DUMP`；两个 Cage 宿主均无这些授权记录。启动锁定查询的权限检查与
[AOSP 对应实现](https://android.googlesource.com/platform/frameworks/base/+/refs/tags/android-14.0.0_r11/services/core/java/com/android/server/PersistentDataBlockService.java)
一致；本机 Android 16 的实际拒绝由调用栈确认。这是可观测的权限差异，尚不是 Google 空标签
的因果证明，没有为此伪造权限、标识或锁定状态。

**采集盲区仍在：** Android 16 对不少启动类库帧的参数读取返回 `InternalException` 或
`InconsistentDebugInfoException`，所以本轮没有确认具体文件路径或设置键；原生直接 syscall
也不在此工具覆盖范围。不能据此宣称已观察到 `/proc/self/maps`、Dobby、宿主路径的读取或上传。
下一轮应先补这类具体观测或验证独立差异，不能仅凭存在权限异常继续添加通用 Binder/PM 补丁。

本轮复用了上游 VM 生命周期接口和现有 Google 解码器，未找到可以直接验收 DEVICE 通过的
上游修复。未改运行时、未重建 APK、未切换手机网络。临时系统测试应用已用保留数据的方式
卸载回原状态；USB 解码进程、端口转发和调试连接已关闭。GBox 原有 Claude 与账号数据未改。
脱敏摘要与原始私有判定分别保存在本机 `mobile/.build/open-cage-store-test/gbox-control/`，
原始判定含请求绑定，不随交付报告发布。机器可读结果同步到 `validation-store-2026-11-16.json`。

## 已有修复与验收范围

已补齐的缺口：单向 Binder 的实际调用进程传递、仅对原始证书及声明均匹配的 microG 启用兼容签名、未知安装来源与不存在应用的语义区别、私有启动查询、Android 16 安装元数据和 ART 辅助文件处理。另移除了框架自带的固定 Pixel 6 原生属性替换。

标准请求原先在 `IBinder.dump` 的原生调用中触发 Android 16 JNI 返回类型检查崩溃。兼容层只把 microG 的两个动态代理包装成具体 IBinder 方法，所有调用仍委托原代理；其 dump 策略、硬件请求和判定内容不变。修复后 warm-up 和请求回调成功。

microG 自带硬件认证屏蔽开关的开、关状态均已对照，均未取得设备标签；最后恢复其默认开启状态。没有使用远程 DroidGuard 服务。临时系统对照应用已撤下并保留其原有测试数据；手机代理恢复原模式及原节点。

完整性仍是当前阻塞点。按用户指定顺序，本轮尚未接入 SIM/时区/VPN 屏蔽补丁，也未测试 Claude 登录。现有证据只能把范围缩小到 Cage＋microG 环境，不能证明某一个后续补丁一定能获得 Google 的通过判定。

完整商店和 Claude 均未放进分发包；此测试实例已在 Cage 私有空间安装，后续同签名覆盖更新保留。安装器当前仅支持 Claude，不能推及任意商店应用。报告不含账号、密码、令牌、设备标识或代理地址。

## REA 报告复核与上游 Companion 对照

已复核 `GBOX-REA-ANALYSIS-2026-11-15.md`。它的参考价值是组件分工和调用链：原版商店负责下载，
独立 MGC 负责 Integrity/Express；定制 MG 提供本地 DroidGuard。报告同时指出 `/mg/ngd`
云端分支只适用于特定预装环境，不是普通 GBox 的通用认证服务。该报告没有动态通过证据。

上游 microG 已包含对应的 Companion 请求流程、`ensureContainsLockBootloader`、服务 dump 代理
和可选硬件证明屏蔽。本次直接使用上游 `0.3.18.40226` 原始 Companion APK，临时替换 Cage
私有空间中的原版商店。替换前保留完整回滚副本并移开商店原数据；测试后恢复原 APK 和原数据。

| 对照 | 结果 |
|---|---|
| Companion 经典请求 | Google 真实解码成功；应用、许可 `UNEVALUATED`，设备标签 `[]` |
| Companion 标准请求 | Google 真实解码成功；应用、许可 `UNEVALUATED`，设备标签 `[]` |
| 原版商店恢复 | 恢复 `84571730` 及原数据；商店可打开，Claude 保留 |

这次补齐 Companion 与 Services 相同的受限签名兼容：要求私有目录、包名、原始 microG 签名、
`FAKE_PACKAGE_SIGNATURE` 权限和声明证书全部匹配。Google 原版商店不匹配 microG 原始签名，
因此不进入该分支。没有改写上游 APK、借用系统 token 或修改解码结果。

独立诊断应用通过 Android KeyStore 生成一次临时 EC 密钥，取回公开证明链后删除密钥。
证书挑战值匹配，链内签名验证通过；证明记录安全级别为 TEE、启动锁定且 verified boot 为 Verified，
但应用身份为 `io.github.flysky701.cage.open` / versionCode 4 及宿主签名，非申请的来宾包。
这与 [Android 对 AttestationApplicationId 的定义](https://source.android.com/docs/security/features/keystore/attestation#attestationapplicationid)
一致：该字段反映系统认为可以使用此密钥的应用。该诊断没有验证根信任及吊销状态，不能替代
Play Integrity 判定，也不能证明该身份差异就是本次空标签的唯一原因；microG 默认还会阻断
DroidGuard 的证书链读取。尝试新增系统诊断对照被手机安装策略拒绝，未更改该策略，也未安装成功。
此前完整性测试 APK 的系统对照结果仍为 `MEETS_DEVICE_INTEGRITY`。

现有证据不支持“加入上游 Companion 就能通过”或“加上隐私补丁就能通过”。尚未找到经过本机
实测可用的上游完整性修复；仍按先完整性、再屏蔽补丁、最后 Claude 登录的顺序保留后续阶段。

## 硬件身份调用跟踪与算法注册修复

沿宿主身份线索检查了 AOSP 的
[Keystore2 调用身份处理](https://android.googlesource.com/platform/system/security/+/refs/heads/main/keystore2/src/security_level.rs)
和 [AAID 系统服务](https://android.googlesource.com/platform/frameworks/base/+/main/services/core/java/com/android/server/security/KeyAttestationApplicationIdProviderService.java)。
生成密钥时系统使用真实 Binder 调用 UID，再由系统包管理器填入应用身份；容器内查询层的
虚拟 UID 不能改变这条路径。普通诊断应用拿到宿主证明并不等于 DroidGuard 已收到同一证明。

真机短时 JDWP 跟踪确认：上游阻断器已启用，底层 SPI 是 Android 16 的 AndroidKeyStoreSpi；
DroidGuard 进入 `KeyPairGenerator.getInstance` 后抛出 `NoSuchAlgorithmException`，没有走到
`getCertificateChain`。原因是替换 Provider 仅注册 KeyStore，遗漏平台原有算法注册。
跟踪只记录方法名、调用栈和次数，不读别名、密钥、请求参数或返回内容；附加调试器的那次请求
仅用于定位，不作为完整性验收。

`MicrogKeystoreCompat` 参考上游
[ProxyProvider 保留原注册的方式](https://github.com/kdrag0n/safetynet-fix/blob/89a4cf49360a1fc4c10a09e9ff56deda08e922e4/java/app/src/main/java/dev/kdrag0n/safetynetfix/proxy/ProxyProvider.kt)，
仅在 Android 16 来宾 microG DroidGuard 服务绑定后补回缺少的注册，保持 microG 的 KeyStore SPI
和证书链读取策略。没有接入该项目的 root 模块、指纹替换或其他功能，没有改动 microG 原 APK。

修复后、不附加调试器的请求记录：补回 28 项注册，EC/RSA 可用，原阻断器保留；日志明确出现
`Block DroidGuard from accessing engineGetCertificateChain`。经典请求和标准请求均取得真实
令牌并通过 Google 解码，设备标签仍是 `[]`。这证明算法缺失已修复，但不能证明设备完整性通过；
也不再支持直接把“宿主证书被读取”认定为当前阻断模式下的失败原因。

对 GBox 原样本只读核查还确认，它的 Provider 构造器同样只注册 KeyStore；另有把 microG
已选 Profile 的 19 个字符串字段同步到 Android Build 的逻辑，不是改写签名证书。当前 Cage
运行时 Profile 为 `native`，19 项中 18 项相同，仅序列号不同。此核查只记录字段是否一致，
不输出字段值；GBox 的闭源代码及样本没有进入 Cage 构建输入。

随后仅在临时编译目录加入序列号同步作对照。第一次因 Profile 尚未初始化而跳过，未作为
有效对照；纠正初始化时机后，日志确认 `aligned=true; changed=true`，经典请求仍解码为
空设备标签。该临时同步已撤掉，最终运行时只保留算法注册兼容。此轮未调整手机网络、
microG 默认阻断开关或个人区应用；尚未执行 SIM/时区/VPN 补丁及 Claude 登录。

配套结果：[validation-store-2026-11-16.json](validation-store-2026-11-16.json)。以下保留 0.0.3 的历史记录，其未验证项目以本节的新结果为准。

# 0.0.3 真机修复记录

2026-11-15 至 2026-11-16，在 Android 16 / API 36 / ARM64 真机上通过 ADB 测试。
沿用 `codex/android-open-source-rebuild-20261115` 的 0.0.2 集成版源码与 microG 原包，
修复后已完成 Google 测试账号登录，并确认强制停止 Cage、重新打开后账号仍保留。
机器可读记录见 [validation-2026-11-16.json](validation-2026-11-16.json)。

## 修复与证据

| 问题 | 修复 | 真机结果 |
|---|---|---|
| 来宾查询 GMS 时收到个人区包信息或上游伪造信息 | 私有包直接查询来宾包管理服务，UID 与原 APK 签名保持一致 | Services、Companion 版本、UID、新旧签名接口一致；未安装 GSF 正确返回不存在 |
| microG 自检页打开时报任务重排权限不足 | 宿主保留 `REORDER_TASKS` | 自检页可以打开；不代表自检全部通过 |
| 登录 WebView 长时间隐藏，内部错误为 `ERR_CACHE_MISS` | 适配 `checkPermissionForDevice(permission,pid,uid,deviceId)`，只映射当前来宾 UID，并要求来宾声明权限 | 联网权限与 WebView 联网检查通过；未声明通讯录权限仍拒绝；Google 登录表单正常显示 |
| 提交账号时 microG 报调用 UID 与 GMS 包名不符 | 进程列表除进程名外，同时返回已注册来宾的 UID 和 `pkgList` | 探针进程归属通过；实际账号和密码校验成功；登录期间两个 microG 进程未记录 Fatal Exception 或原身份异常 |
| 旧探针无法提供本轮诊断 | 仅更新自有探针至 versionCode 4，保留其数据 | 计数从旧版 2 延续至 5，microG 组件与数据保留 |

账号密码仅用于用户授权的测试账号登录；不写入源码、APK 或本记录。完成 Google 条款确认后，
microG 账号列表中出现该测试账号；应用强制停止后的新进程中再次确认账号存在。
该检查是应用冷启动，未重启整部手机，也未验证其他应用的 OAuth/令牌调用或长期会话续期。

调用身份故障对应 microG `v0.3.18.252432` 的
[PackageUtils.getAndCheckPackage](https://github.com/microg/GmsCore/blob/v0.3.18.252432/play-services-base/core/src/main/java/org/microg/gms/common/PackageUtils.java)：
它优先按调用 PID 查询进程的 `pkgList`。本次修正容器提供的信息，没有取消 microG 的校验。

## 安装包与数据

- 文件：`Cage-Open-Bundled-Preview-0.0.3.apk`，121,489,672 字节。
- 包名：`io.github.flysky701.cage.open`；versionCode 3；ARM64。
- APK SHA-256：`c65d6f8d821f2503e36f4a543c9f3cea004dd514aeb1191af9cbc7991319f247`。
- 本机调试签名 SHA-256：`1dba72036c407f4a8bf85254f2e4827f756d808cf9354fbb309abd3031a0d6ab`。
- 本机签名不同于此前云端 0.0.1 / 0.0.2，不能直接覆盖旧签名版本。本次在账号登录前备份
  独立测试实例的来宾数据，重装后恢复，之后的同签名修复包均直接覆盖安装。
- microG Services `0.3.18.252432`、Companion `0.3.18.40226` 继续使用锁文件指定的原包；
  原始签名保留，未重签。已有组件在准备时跳过，自有探针按版本更新并保留数据。

构建通过；10 项现有服务路由用例通过；最终补丁可从锁定上游重新应用，11 个相关源码/配置
文件与实际编译目录逐字节一致。最终 APK 的包名、版本、架构和签名已核对。
临时 WebView 调试入口已移除。`build-result.json` 是构建阶段记录，设备结果以本文件及配套 JSON 为准。

## 当前边界

microG 自检并非全部通过；未开启签名伪装，也未验证设备认证、推送或完整性服务。
Companion 不是完整 Play 商店。本包未包含 Claude，Claude 登录和对话尚未测试。
没有改变手机全局网络设置，没有操作其他已安装容器的数据；本轮没有创建公开发行版。
上游许可声明冲突及完整隔离能力的限制仍见 [README](README.md)。

0.0.2 历史产物为 120,942,906 字节，SHA-256
`b31b641dbd2294fbcc8a61ac39717c60782cae5a88d4e3340b2c99a228425c1e`。
它完成了离线构建与签名检查，但上述真机问题是在后续测试中发现并由 0.0.3 修复的。
