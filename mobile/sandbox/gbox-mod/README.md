# GBox 定向修改构建

手机版开发见 [Cage 个人版分支状态](https://github.com/Flysky701/Claude-Cage/blob/codex/android-personal/mobile/STATUS.md)。设备对照实验见 [Android 研究分支](https://github.com/Flysky701/Claude-Cage/blob/codex/android-research/mobile/STATUS.md)。以下日期段落保留对应阶段的构建与验证记录。

以用户提供的 GBox 1.8.4.02 APK 为输入，保留原 VLite 引擎与四个预置组件，构建独立测试副本。此目录保存本项目新增的构建、重定位和屏蔽代码；它不是 GBox 原始 Java/C++ 工程的完整恢复。原 APK 仍是构建必需输入。

**后续真机与补充验收：** Android16 路线见 [真机报告](../../PHONE-GBOX-VALIDATION-2026-11-15.md)，当前 SIM/VPN 已测路径通过，WebView 首脚本时区仍未通过。用户提供的 Claude 静态分析及新增遗漏项已整理为 [隐私风险与补充验收](PRIVACY-REVIEW-2026-11-15.md)，按优先级列出 12 项待办。以下暂停状态及 `acceptance.json` 属于 MuMu 路线，不能替代真机结果。

**18:26 后续实现：** 新 UI 与隐私/检测已合入 `dist/Cage-Android-Review-Checks02.apk` 并同签名原位安装，原 Claude 登录态和测试标记保留。VPN 隧道地址/DNS/路由等元数据的所测同步查询及回调通过；非隧道网络信息、WebView 首脚本和实际断线保护仍有未完成项。未修改手机全局网络设置。精确产物哈希、测试与剩余范围见 [本轮交接](PRIVACY-REVIEW-2026-11-15.md#本轮实现验证与交接)。

**2026-11-15 MuMu 路线暂停记录。** 最后测试包为 Privacy15-ContextFix-05。已定向修复 GMS 初次 Context 的旧包信息缓存，DroidGuard 非空服务连接通过；初始化随后在 MuMu ARM 转译调用链崩溃，Claude 仍未登录。两轮新来宾探针在记录路径通过并保留原标记，外层对照沿用历史报告。当时尚不能区分 MuMu 自身缺陷与容器交互；后续真机结果须单独阅读，不能据此重写模拟器结论。此路线停止继续测试和登录重试，保留数据与当时网关状态。详情见 [暂停检查点](checkpoint-2026-11-15.json)、[接续说明](../../HANDOFF-2026-11-15.md) 和 [验收记录](acceptance.json)。本次上传仅保存相关源码和记录，不恢复测试、不升级版本或发版。

## 当前产物与边界

- `dist/Cage-GBox-Privacy-15-ContextFix-05.apk`：最终暂停时安装的诊断候选。源码缓存修复已实测连通服务，但登录仍因后续原生进程崩溃失败；不是完整验收通过版本。以下 Privacy15 原包条目保留接手时结论。

- `dist/Cage-GBox-Privacy-15.apk`：SHA-256 已复核，使用 Privacy13 外层与 Privacy15 来宾报告的离线重算与保存结果一致。SIM、时区、VPN 可见性及普通私有标记仅在已记录路径通过；本轮未重跑完整探针或停止网关。Google 账号返回不代表 Claude 登录通过。
- `diagnostics/observe_login.py`：显式指定 ADB 和实例，仅记录固定事件、时间、布尔、计数和组件名。原始日志不保存、不输出；可用 `--duration 1..60` 观察新事件。观察器不自行发起登录，UI 操作另行记录。测试覆盖认证字段不进入输出。

以下逐版条目保留各版本当时结论，不覆盖上面的 Privacy15 当前状态。

- `dist/Cage-GBox-Baseline-03.apk`：并存基线，未启用屏蔽；在第 02 版基础上修正原生包名常量。
- `dist/Cage-GBox-Privacy-12.apk`：MuMu 单次冷启动取得完整 Probe06 报告，所测 SIM 属性、Tokyo 时区、VPN 可见状态及未选中属性对照通过；四项原生钩子均成功安装并实际命中。两辅助入口已在 UID 回调发布前就绪，最终槽核验通过，新进程保留既有测试标记。随后真实 Claude 未登录启动通过；Google 正确密码与条款步骤完成，但返回后账号列表仍空，账号添加和 Claude 登录未验收成功。
- `dist/Cage-GBox-Privacy-11.apk`：真实 GBox 中宿主 JNI 桥安装成功，两次 ARM 同步刷新完成，WebView 准备阶段正常返回；但更早的 Binder 线程在原 `startFp` 期间调用空 PID 原入口并崩溃，未取得完整报告。时间线显示故障先于隐私绑定和新桥安装，不能将新桥当作已证明的原因；屏蔽及登录尚未验收。
- `dist/Cage-GBox-Privacy-10.apk`：MuMu 实测在 WebView 的 `JNI_OnLoad` 查找 `DrawFunctor` 时中止，未产生完整来宾报告。独立备份的 `Runtime.nativeLoad` 方法未命中 ART 对原方法身份的特判，导致使用错误类加载器；该观察器已从第 11 版移除。此前一次刷新已返回，不能把本次中止解释为刷新死锁。
- `dist/Cage-GBox-Privacy-09.apk`：MuMu 实测确认接口所有权校验已通过，选中来宾的 ARM 库在稍后采样中出现，但既有屏蔽任务和加载观察回调没有发现它。子进程与 WebView 仍通过；父原生读取和整体屏蔽未通过，账号尚未登录。
- `dist/Cage-GBox-Privacy-08.apk`：真实来宾运行确认首次绑定时序已修复，子进程属性屏蔽和 WebView 首脚本时区生效。父模块通过 API 校验并登记任务，但没有命中选中来宾库，原生属性和接口枚举仍未通过；整体屏蔽及登录仍未验收。
- `dist/Cage-GBox-Privacy-07.apk`：已完成真实来宾运行，确认首次隐私绑定早于原生兼容验证，父模块遇到错误 Context 身份，子进程入口看到未完成状态；之后同包绑定未重试。该版的完整 ByteHook 版本检查及环境限制保留到第 08 版，屏蔽仍未整体通过。
- `dist/Cage-GBox-Privacy-06.apk`：增加固定阶段标记后已完成真实来宾报告，WebView 首个 HTML 脚本和加载后读数均为 Tokyo / +540；父原生模块因版本字符串比较不匹配而拒绝安装，子进程属性仍未过滤。屏蔽整体未通过；没有证据把第 05 版未复现的等待归因于此版本检查。
- `dist/Cage-GBox-Privacy-05.apk`：新增选中来宾 ARM 库属性/接口读取、x86_64 子进程属性继承，以及精确 WebView 版本的真实渲染器时区启动配置。一次真实来宾启动 45 秒未产生完整报告、未见相关崩溃，屏蔽未验收；旧上下文标记实际包含整个隐私绑定，不能据此断定 Context 调用未返回。
- `dist/Cage-GBox-Privacy-04.apk`：已在 MuMu 完成一次真实来宾运行，Java VPN 可见状态及 Java/ICU/原生本地时间部分生效；原生与子进程 SIM 属性、WebView 时区和原生接口枚举仍未通过。屏蔽未整体通过，账号尚未登录。
- `dist/Cage-GBox-Privacy-03.apk`：保留第 02 版 SIM、时区和 VPN 可见状态屏蔽代码，只增量修正同一原生包名常量。屏蔽效果尚未通过运行验收。
- `dist/Cage-GBox-Native-Trace-03.apk`：同一原生包名修正加初始化阶段和 PID 共享文件状态日志；不启用屏蔽，不关闭原生 hook。
- `dist/Cage-GBox-Native-Trace-04.apk`：第一个带 MuMu ART 兼容模块的诊断候选，不启用屏蔽；已通过 11 项 native 安装及两项 Binder 辅助原入口检查，随后在来宾 Context 的 APK 资源加载处失败。
- `dist/Cage-GBox-Native-Trace-05.apk`：只增加 I/O 原返回码和 APK 路径分层读取诊断。已确认原返回码为 0、映射与真实 APK 有效，但虚拟路径在 Java、ARM 和框架三类读取中均失败。
- `dist/Cage-GBox-Native-Trace-06.apk`：在已确认的 MuMu 来宾进程中，把框架消费的应用信息副本转为对应真实隔离路径；不启用屏蔽。一次 MuMu 冷启动已完成 GMS Context、Application 和 onCreate，未见原生崩溃；这不等于账号登录或屏蔽通过。
- `dist/Cage-GBox-Resign-Control-01.apk`：原包名重签对照，全部 2502 个非签名 ZIP 条目与原 APK 字节相同。只能用于没有原安装数据的独立对照实例。
- `dist/Cage-GBox-Network-Probe-02.apk`：保留原网络探针 DEX、三个目的地、权限和开发签名，新增不被调用的 ARM64 ABI 标记库以适配 GBox 导入；版本号由原 3 升为 4。此产物只完成离线打包，不代表导入或网络检测通过。

第 12 版的通过范围是 Probe06 实际记录的接口路径，不是任意读取方式的全面隔离证明。Java SIM 在同版外层和来宾都为空，没有阳性对照，不能单独归功于屏蔽；原生三种属性入口与默认子进程的运营商信息有阳性对照。构造函数、JNI_OnLoad 内读取、纯 native 加载、加载返回前的并发使用、直接解析函数地址及原始 syscall/netlink 等边界仍保留。真实 Claude 和 Google 登录仍未验收。

并存产物应用编号为 `com.cage.android`，互相覆盖安装时使用同一本机开发签名，与原版 `com.gbox.android` 分开。应用显示名称为 Cage。重签对照保留原包名。构建脚本不执行安装、卸载、清理账号、登录或网络配置。

第 03 版基线与屏蔽包复用各自第 02 版全部 DEX、Manifest、资源和四个预置 APK，未重新汇编 DEX。签名后逐条比较非签名 ZIP 内容，仅四个已知 core 库的数据区变化，其余字节全部相同；保留原有类与 126 个无冲突 Provider authority 的结论因此不变。第 01 版遗漏了分号连接的第二个 authority，第 02 版修正了该元数据，第 03 版进一步修正原生包名常量。

MuMu 中的诊断第 03 版已正常创建和读取 PID 共享文件，旧的并存包提前中止已消失；其后原版 ART `GetMethodID` 崩溃由第 04 版兼容模块解决到 `start_fp_with_arr` 正常返回、安装验证通过。第 04 版仍未完成来宾 Context，框架加载虚拟 GMS APK 路径时返回文件不存在。I/O 初始化调用虽已返回，但该版未记录其返回码，不能据此认定路径转换成功。基线和屏蔽第 03 版本轮只做离线增量打包，没有新的设备运行记录，第 12 版的实测结论不能反推到这些旧产物。Google 与 Claude 登录仍未验收，不可由构建或签名成功推定。

本轮设备验证仅限 MuMu 的独立测试实例，手机不在测试范围。运行结论以 `mobile/.build/gbox-mod/mumu/compatibility-matrix.json`、`native-trace03-result.json` 及后续实测报告为准。

## 构建

默认复用项目已有的 JDK 17、Android Build Tools、Android API JAR、apktool 和开发签名，均可通过参数指定。构建缓存、临时文件和运行记录保存在 `mobile/.build/gbox-mod/`。默认输入为 `mobile/.build/gbox-test/GBox-1.8.4.02.apk`。

```powershell
python mobile/sandbox/gbox-mod/build.py --output dist/Cage-GBox-Baseline-Local.apk
python mobile/sandbox/gbox-mod/build.py --privacy --output dist/Cage-GBox-Privacy-Local.apk
python mobile/sandbox/gbox-mod/build.py --native-trace --output dist/Cage-GBox-Native-Trace-Local.apk
```

已有输出不会被覆盖。可用 `--privacy-modules sim`、`--privacy-modules timezone,vpn` 等组合逐项验证。当前时区配置为 `Asia/Tokyo`，实际 UTC 时钟保持原值。隐私策略及尚未验证的读取路径见 [privacy/README.md](privacy/README.md)。

已有第 02 版产物可使用增量入口，只修正四个原生包名数据区并重新签名，避免重组已通过装配的 DEX。基线和屏蔽第 03 版使用此路径生成：

```powershell
python mobile/sandbox/gbox-mod/refresh_native.py --base dist/Cage-GBox-Baseline-02.apk --output dist/Cage-GBox-Baseline-Native-Refresh.apk
python mobile/sandbox/gbox-mod/refresh_native.py --base dist/Cage-GBox-Privacy-02.apk --output dist/Cage-GBox-Privacy-Native-Refresh.apk
```

`--identity original` 仅保留原应用编号以便隔离环境中的对照分析；重新签名的产物不能覆盖原签名安装包，该模式不会自动处理安装。

本机受限执行环境可能让 `zipalign.exe` 以访问异常退出。此前装配结果会保留；使用正常本机执行环境只重跑打包，不需要重新汇编：

```powershell
python mobile/sandbox/gbox-mod/finalize.py --unsigned <构建目录/unsigned.apk> --output <新的产物路径.apk>
```

自定义签名通过 `--keystore` 指定，密码从 `CAGE_GBOX_KEYSTORE_PASSWORD` 环境变量读取，不写入命令行、报告或安装包。

## 并存修改范围

宿主 Java 类名保持原样。应用编号、shared UID、Provider authority、宿主权限和相关 URI 常量使用独立标识；四个 `libloader32/64.so` 中的原宿主私有路径采用等长重定位。

第 03 版构建还分别重编码四个 `libvlitecore32/64.so` 的固定 256 字节数据区，使 `mapPidSelfFile` 所读取的宿主名从 `com.gbox.android` 变为 `com.cage.android`。每个库有独立的整库及数据区样本核对；不匹配即停止。其余解码数据、全部可执行代码、路径匹配条件、文件权限、打开模式和失败处理均不变。原包名模式不应用此修改。

原始 MG 与 helper 中的两个宿主 Provider 地址保持不变。新增 `HostRelocation` 仅在这两个来宾调用者内，把 `check_env` 与 `host_api` 送往新宿主，并转换对应 Provider 请求的 authority/URI。原 Provider、调用身份、鉴权及结果保持原逻辑；不伪造宿主签名、不放开权限、不替换 Play 判定或许可。

## 崩溃定位

可选诊断包通过 `CageNativeTrace` 标签记录固定的 `before` / `after` 阶段：库加载、PID 共享文件映射、`start_fp_with_arr`、I/O 盒初始化、来宾 Context 创建、Application 创建和 `onCreate`。PID 映射额外记录创建/读取分支、文件存在/可读/可写、父目录状态、路径是否匹配宿主等布尔值。不记录路径内容、账号、令牌或返回数据，不屏蔽原异常。

并存第 02 版曾在更早的 `mapPidSelfFile` 中主动中止。原生创建分支只接受包含原包名的路径，改名会跳过创建；后续读取分支在打开失败时主动中止。第 03 版诊断实测已确认修正有效：创建与读取分支均有正常返回，文件存在、可读、可写。原包名重签对照和修正后的并存诊断包都仍复现原版 ART `GetMethodID` 崩溃。

原 ART 兼容阻塞已定位到原生入口字段探测：引擎用 `Native.mark()` 地址扫描方法元数据，未命中会返回 0，之后将该值直接用于 hook 写入。MuMu 转译入口与 ARM 函数地址不同，与现场方法首字段被回调地址覆盖的证据吻合。第 04 版通过保留原回调、调整安装与原函数转调方式推进了此处启动链；已交付的基线和屏蔽第 03 版产物未加入 ART 修改。

兼容候选使用可选 `--mumu-compat` 构建入口，默认构建仍不加入该模块。候选只针对已记录的 MuMu API 31/32 ARM64 来宾，检查精确环境属性、实际宿主 ART 架构和原库样本后，才会在内存中转接通用 helper 与 Binder 的辅助原入口读取。原始 ARM 回调和 I/O 引擎保留。自有探针第 03 版验证了普通 JNI 的独立方法备份转调；第 05 版验证了 Java 调用 CriticalNative 替换函数、原 x86 无参入口转调及后续 JNI 健康检查。第 04 版嵌套 ARM JNI 调用仍有失败记录，这一边界没有被第 05 版结果消除。GBox 第 04 版诊断候选用于验证真实启动链，不能作为隔离或登录验收结果。

```powershell
python mobile/sandbox/gbox-mod/build.py --mumu-compat --native-trace --output dist/Cage-GBox-Compat-Trace-Local.apk
python mobile/sandbox/gbox-mod/build.py --privacy --mumu-compat --native-trace --output dist/Cage-GBox-Privacy-Compat-Local.apk
```

此选项额外使用项目缓存的 Android NDK r27d（可由 `--ndk` 指定），编译一个 ARM64 兼容库。APK 内原 core 库的可执行指令不改动；新增库只在确认的进程环境中安装入口转接，初始化失败会阻止后续重入，成功返回后再核对实际安装和原方法备份。

最新诊断构建还记录 `start_iobox_with_error` 的原返回码。`--mumu-compat --native-trace` 组合会在 GMS Context 创建前追加一次只读路径对照：检查虚拟前缀是否匹配当前宿主、查询原引擎映射，再分别用 Java 流、ARM libc 和框架 `ApkAssets` 读取虚拟与映射路径。流读取仅检查四字节 ZIP 头，独立的 `ApkAssets` 对象随后关闭。新增日志只有固定阶段、布尔、计数、返回码和异常类型；不记录路径、异常消息、文件内容或账号，不修改实际路径和 I/O 规则。

第 06 版的框架适配只在原生兼容校验完成、原 I/O 初始化返回 0、当前来宾的 code/CE/DE 既有目录确认后启用。它转换 `bindData.c` 和来宾包信息查询的 `ApplicationInfo` 副本，包括源 APK、split APK、native 库及数据目录别名；已在对应隔离目录内的物理路径不重复映射。映射只来自原 `Native.a` 规则，超出当前包对应目录即拒绝；必要的资源和数据路径仍无法解析时明确失败。全局包记录、PM 原缓存对象、包名、UID、签名、权限、ABI 和原 I/O 规则不改动。

此适配允许来宾的 Framework/Context API 看见真实的宿主私有隔离路径，不伪装或隐藏目录字符串。它不等于任意 native syscall 的强隔离。第 06 版保留的路径诊断中，历史标签 `virtual` 指 PM 返回的可见路径，此时可能已经是物理路径；读取成功不能证明原 seccomp 路径转换恢复。应以 `CageFrameworkPaths` 的 bind/PM/context 归属标记及 Context/Application 阶段作为本次验证依据。

屏蔽第 04 版在诊断第 06 版基础上增量加入现有隐私模块，仅重组 `classes4.dex` 并新增 `classes10.dex`；兼容库、兼容 DEX、原诊断 DEX、core 库、资源和四个预置 APK 均复用原字节。组合检查确认通用 Binder 原调用、包信息原调用包装各自唯一，`GuestPrivacy.bind` 保留在来宾 Context 创建后、Application 创建前，后续生命周期刷新入口保留。实际运行报告为 `privacy04-result.json` 和 `privacy04-comparison.json`，结论为部分生效、整体未通过。

屏蔽第 05 版同样从诊断第 06 版增量生成：原有条目仅 `classes4.dex` 改变，新增隐私 DEX、一份 ARM64 隐私库和一份仅存于 assets 的 x86_64 子进程库；宿主 ABI 仍为 ARM64/ARM32。子进程库与已实测的独立第 01 版字节相同，两个调制解调器容量属性保持原值；默认子进程环境通过可恢复的 `LD_PRELOAD` 配置继承，显式或较早缓存的环境副本不在保证范围。

第 05 版保留最早的 Context 后绑定，在原 `mInitialApplication` 发布后再刷新 WebView 配置。WebView 仅针对核对过的 `110.0.5481.154.1`，在引擎启动前设置 Chromium 原生时区开关，不改页面脚本；实际首个脚本仍需探针验证。已初始化的 provider/renderer 不能仅靠移除开关恢复到另一来宾，因此状态会持久标记为不可复用。构建接入在公开绑定的缓存前、异步实际绑定入口检查该状态，并只对该状态从原 makeApplication fallback、最终异常处理和 Instrumentation 委托处继续抛出失败；未新增进程 kill，也未改变普通异常处理。跨包复用的设备行为尚未验收。具体组合证据位于产物同名 JSON 的 `combinedIntegration` 和 `privacyProfile`。

第 06 版只重组 `classes4.dex`、隐私 DEX 和父进程隐私库中的固定诊断日志；相对第 05 版其余非签名条目字节不变。新增 `CagePrivacy` 日志 `stage.context.returned.beforeBind` 紧接 Context 的返回值接收，`stage.bind.returned` 则紧接隐私绑定返回。增量组合中旧的 `after.createPackageContext` 位于后者之后，保留该历史标记，但定位时必须使用新的精确分界。Java/native 内部记录固定进入/返回阶段，不记录参数值、路径、异常消息或账号；没有将未定位的等待预先认定为某个 hook 死锁。

第 07 版相对第 06 版仅替换 `classes10.dex` 和父进程隐私库。父库精确核对原字符串 `bytehook version 1.0.8`、表地址及全部 19 个函数槽位置，拒绝时记录固定原因；未放宽为任意版本匹配。子进程的父入口仍要求 SDK 31/32、64 位进程、选中且匹配的来宾身份和 `NativeCompat.isActive()` 的完成验证状态。该状态已经由真实系统属性、ARM 转译桥、x86 ART 及原库样本校验控制；Java Build 的三项缓存改为布尔诊断，原 VLite 确有反射改写这些缓存的代码。第 07 版实测三项缓存均匹配，不能将缓存改写当作本次失败原因；实际问题是绑定早于原生初始化完成。

第 07 版复用已通过独立探针的 x86_64 子进程库原字节；该库在每个子进程中仍独立检查真实属性和实际可执行文件架构。宿主 ABI、原环境恢复和原 `LD_PRELOAD` 保留行为均不变。签名后的增量核对确认其余非签名条目完全相同；GBox 内实际加载和属性过滤仍需本版运行报告确认。

第 08 版仅修改 `classes4.dex`、兼容 Java DEX 和隐私 DEX。`bindGuestContext` 位于实际 `createPackageContext` 返回和框架路径观察之后、`makeApplication` 之前；Instrumentation 的原 `bind` 不再发起首次初始化。只读状态明确区分未完成、已选择原路径、已验证兼容、失败：未完成或失败时不捕获半成品策略；已验证兼容还必须通过当前 Context 的包名、代码及 CE/DE 路径归属检查。没有兼容类的旧构建和明确选择原路径的环境仍使用专用接点及 Context 身份验证，不依赖 MuMu 状态才能使用基础隐私模块。

第 08 版离线直接调用检查覆盖早期宿主 Context 不改变状态、随后正确来宾可以首次绑定、重复调用不重复安装、原路径及无兼容类分支。该检查将 native、子进程和 WebView 副作用替换为测试桩，只验证生命周期状态；不能据此声称真实屏蔽通过。原生准备状态映射另通过六种只读检查。该版同时将 `after.createPackageContext` 标记移到真正的 Context 返回处，后续隐私阶段使用独立日志分界。

第 09 版相对第 08 版仅替换隐私 DEX 和父进程隐私库；首次绑定逻辑、兼容模块、子进程库与 Java 类、WebView helper 及原 core 均复用。系统库列表解析格式只有五个赋值字段，原先要求六个会拒绝所有候选行；该判断已改为五，其他映像与样本限制保留，并通过标准格式的实际 C 解析验证。本版还加入观察型加载回调、命中计数和拒绝阶段记录，不主动刷新或重新注册屏蔽任务。

第 09 版详细映像路径和样本信息仅写入当前选中来宾 `files/cage-native-privacy-diagnostic.txt`，日志只输出阶段与计数。验证应等到 `CageNativePrivacy: observation.privateFile.written.3` 出现，再保存私有记录和停止进程；该标记表示延迟 8 秒的最后采样已经写入。零加载回调本身不能证明转译器绕过监视，因为回调登记接口没有成功回执；应结合实际映像枚举、任务状态和调用命中判断。

第 09 版实际采样在延迟 4/8 秒时看见一个符合来宾目录的 ARM 映像，过滤器的调用总数仍停在 40、放行数为 0，加载后观察回调也为 0。该证据支持在确定的加载完成边界调用原引擎刷新路径，而不是用定时重试碰运气。私有详细文件及进程映像列表未能通过设备 shell 读取，不能声称已经取得它们；本次结论来自实际固定日志与计数。

第 10 版相对第 09 版只替换 `classes10.dex`、ARM64 兼容库及 ARM64 父进程隐私库；其他非签名 ZIP 条目逐字节相同。它在已验证的兼容状态下，为普通 JNI 方法 `Runtime.nativeLoad(String, ClassLoader, Class)` 建立独立备份转调，保留原来的参数、返回值和异常。仅当原调用返回 null 且没有待处理异常时，才同步调用精确样本核对过的原 `post_dlopen(task_manager)`，让原引擎发现新库并应用已有任务。没有重复调用 JNI_OnLoad，没有定时刷新，也没有改动原 core 的可执行代码。

第 10 版的加载观察器独立于原 17 个适配项和 11 个必需安装检查。安装时用确定不存在的来宾私有库路径核对原调用和替换调用返回相同错误字符串且没有刷新；该失败路径实测通过，但不足以证明成功加载时的 JNI 类加载器语义。真实 WebView 成功加载随后触发上述方法身份问题。原初始化准入、child 与 WebView 不变，未重复已通过的生命周期检查。

第 11 版仅重组隐私 DEX、替换父进程隐私库，并把兼容库恢复为第 09 版原字节；原 17 项适配与 11 项必需安装保持。新增的独立 helper DEX 与 x86_64 桥库只存入 assets，宿主 APK 仍只有 ARM64/ARM32 原 ABI。已核对的宿主 Context 将这两个资产放入自身私有缓存，使用 bootstrap 父加载器及空 native 搜索路径加载，不能继承来宾类。注册时通过显式 JNI Class 引用连接到 ARM 回调，并保留 helper、回调类和加载器的进程期引用。

这个 x86 桥在原 `Runtime.nativeLoad` 方法上转接，直接调用保存的真实 x86 JNI 入口，不复制该方法，不使用 Java 转调包装。成功返回后通过普通 JNI 调用 ARM 策略库；原加载异常保持，观察器新增的异常也不再静默清除。注册开始后若无法确认完整状态，沿用已有持久失败守卫停止来宾绑定。独立 Host Load Probe02 已通过应用独有类的 `JNI_OnLoad` 查找、嵌套加载、错误返回对照、ARM 回调返回及真实 WebView 本地页面；Probe01 的早期回调计数失败原因仍未确定，不能将第 02 版增加诊断称为已证明的修复。

第 11 版与第 10 版签名后的非签名条目比较，仅 `classes10.dex`、两份新增 ARM64 库发生替换，另增加两份 host assets；其中兼容库与第 09 版逐字节相同。GuestPrivacy、child、WebView 的既有 Java 类、框架与诊断 DEX、原 core 和四个 preset 均保持原字节。第 11 版只推进到 host 安装及两次刷新，第 12 版才取得目标映像被选中、四项读取钩子实际命中和完整探针报告的证据；单独的成功通知计数不等于刷新或屏蔽成功。

第 11 版的 Binder 空入口现场与一个原初始化并发窗口一致：UID 回调先安装，PID/WorkSource 原入口随后才写入 core 数据槽，另一线程可能提前读取并缓存零值。兼容准备阶段已经取得并验证两个原入口，但旧版仅保存在自身结构中；原最终验证也只确认辅助读取发生，不能发现此前的零值读取。该窗口是已确认的代码缺口，但尚不能单凭时序和静态分析认定为唯一故障原因。

第 12 版在 UID 注册前，先确认两个槽位属于同一 core 的可写数据段且当前为零或期望值，再发布已验证的原入口、执行顺序屏障并读回。原 getter 调用与写入序列继续执行，最终验证再核对两槽。新增精确样本检查覆盖完整 Binder callback 和 installer，原代码及返回逻辑不改。日志中的两条 `BINDER_AUXILIARY_SLOT_READY` 应在 `INSTALLED binder_uid` 前出现，`BINDER_AUXILIARY_FINAL_SLOTS_MATCH` 应在 `VERIFY_COMPLETE` 前出现。相对第 11 版，签名后只有 `lib/arm64-v8a/libcage_compat.so` 一个非签名条目改变；没有重编 DEX 或其他原生模块，也没有新增独立探针或压力测试。

第 12 版实际日志确认上述发布和最终核验顺序，原 11 项必需安装全部通过。三次 host→ARM 回调均返回，三次原刷新均完成且没有拒绝；稍后加载的来宾 ARM 库被选中，属性 get/read/read_callback 与 getifaddrs 四项状态均为 0，并分别记录实际 first.call。完整报告确认运营商属性不再暴露，Java/ICU、原生本地时间与三种属性读取、默认子进程以及 WebView 首脚本和后续读数均为 Tokyo / +540；已识别 VPN 状态和接口在所测读取路径中不再暴露。非目标 SDK 属性及原本缺失的两个硬件容量属性保持原结果，调制解调器容量数没有被作为 SIM 存在或屏蔽判据。

该次运行是新进程中的一次冷启动，既有来宾标记保留，无相关崩溃，也没有重新导入、清除数据、手动刷新、账号操作或公网探针请求。证据见 `mumu/privacy12-result.json`、`privacy12-comparison.json` 和 `privacy12-native-privacy.log`；延迟八秒日志已取得，未读取此前无权限访问的私有诊断文件或进程内存。当前下一步是现有第 12 版上的真实 Claude 无账号启动与读取路径观察，再据结果推进登录，不能将自有探针通过直接算作 Claude 或 Google 登录通过。

此修复覆盖成功 Java 加载返回后的读取。ELF 构造函数、JNI_OnLoad 内部、纯 native 加载、其他线程在 Java 加载返回前的使用，以及刷新过程中同线程内层加载刚返回的瞬间均不在该保证范围。后者记录真实待处理事件并由外层刷新处理，不把内层返回时点算作完成。x86 父库、直接解析函数地址和原始系统调用等既有边界也仍保留；若真实应用在这些阶段读取目标信息，不能据本探针通过而放行登录。

独立子进程属性探针第 01 版已在 MuMu 通过三种 libc 属性读取、系统 getprop/date 的实际加载与架构核对、原值阳性对照及停用恢复；后续 GBox 第 08/09 版也已确认该子进程属性屏蔽生效。隐私探针第 05 版补充父进程 read/read_callback 和未选中属性对照，外层运行已完成，旧报告标签遗漏单独记录；第 06 版保留同一原生库，修正报告版本并增加 WebView 首个 HTML 脚本读数，与加载后读数一并比较。所有旧产物和报告保留。

后续调用链是 `client/k.s0()` → `Native.i()` → `start_fp_with_arr()` → 路径规则与 `start_iobox_with_error()` → `createPackageContext()` → `makeApplication()`。`start_fp_with_arr` 的 boolean 参数来自 `context/k.e()`，表示 ART 判别，不是 64 位标志。`--identity original --native-trace` 仅加入诊断 DEX，保留原始包名、资源和原生库；现有诊断已确定失败边界，未为此重复生成另一份对照。
