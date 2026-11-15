# Android 16 / Google WebView 156 时区接入

本文件记录 `WebViewTimezone.java` 的精确兼容范围和静态依据。主任务 Test02 已确认后续 WebView 读数为 Tokyo，但首脚本仍为 Shanghai；**当前手机路径没有通过首脚本验收**。

Test07 后续复验：首次安装后的单次首脚本恰好为 Tokyo，随后三次独立来宾进程冷启动均再次得到 Shanghai/+480，分别在 13、9、11 ms 后变成 Tokyo/+540。因此不能用首次偶然通过覆盖重复失败。问题发生在首次创建独立 WebView renderer 的初始化通知时序，不是打开 Cage 主界面即改变所有应用时区；renderer 重建和其他应用尚未逐一测量。

后续 [独立 renderer 实验](renderer-lab/README.md) 已验证：同一 WebView 的初始空白文档确认 Tokyo 后，受控目标页面的首脚本、iframe、worker、刷新与重建路径可通过。20 个独立应用进程、35 个目标页面已测；这不是 Cage 来宾接入结果。同步历史恢复、JS 关闭及 profile 选择的接口语义仍限制通用接入，生产状态仍未通过。

再后续 [独立渲染服务初始化实验](renderer-lab/service-experiment/README.md) 在保留隔离 UID 的新 renderer 中提前初始化原生时区，并继续由浏览器监视器提供 Tokyo。目标页面不经预热或等待，10 个独立应用进程、15 个目标页面和 5 次 renderer 重建通过。此路线有可运行的独立实验源码；实际 Cage 的 Application/服务装配尚未接入和验证，原 UI 的风险判定仍保留。

## 支持范围

| 环境 | 精确提供程序 | 路径 |
| --- | --- | --- |
| API 31–32 / 原 MuMu | `com.android.webview`，`110.0.5481.154.1`，`548115537` | 保留原 `M` / `ug` / `tg` 原生命令行路径。 |
| API 36 / 当前手机 | `com.google.android.webview`，`156.0.8078.47`，`807804703` | 启动前安装仅针对该提供程序的时区监视器 Context 包装。 |

手机样本来自本任务已拉取的 WebView APK，SHA-256：`a1f88b58dfaec5b5f5078f38191a79690378ac813b73ca346e16a977ca163e97`。本地解包目录为 `mobile/.build/gbox-mod/android16-webview/decoded/`。版本、API、字段类型、对象引用关系或未启动状态不匹配时不尝试猜测映射。

## 为什么新版本不用旧参数

手机样本的 ARM64 `libwebviewchromium.so` 中没有 `time-zone-for-testing` 字符串。Chromium 官方[移除该参数的变更](https://chromium.googlesource.com/chromium/src/+/3b61e5143807d4efd97a67d930e91b54e9c3d2dd%5E%21/)与此一致。因此，仅向新版本命令行写入该键再读回，不能证明时区生效。

当前官方 [ICU 初始化实现](https://raw.githubusercontent.com/chromium/chromium/main/base/i18n/icu_util.cc)在 Android 使用原生 ICU 默认时区；这与本样本 Java 时区读取点的检查一起，说明不能把 `java.util.TimeZone.setDefault()` 等同于 Chromium ICU 已刷新。

## 手机 APK 中已核对的调用链

以下均为实际 APK 的 Smali 观察，路径以解包目录的 `smali/` 为根：

- `com/android/webview/chromium/WebViewChromiumFactoryProvider.smali`：字段 `i` 为共享静态对象 `com.android.webview.chromium.b`，其 `b` 指向 `WV.yf2`；工厂 `a` 与 `WV.yf2.a` 指向同一初始化委托。
- `WV/yf2.smali`：静态 `m` 为启动控制器；`c` / `g` 是初值为零的 `AtomicInteger`，分别记录启动状态和请求状态；`l` 为启动任务，`b` 为完成闩锁。`d` 锁只保护 UI 线程选择，所以代码同时检查两项原子状态、任务空值、闩锁及异常字段，不把该锁当作完整的启动互斥锁。
- `WV/y10.smali`：静态字段 `a` 为 Chromium Context；`c(Context, BroadcastReceiver, IntentFilter)` 保留参数并调用五参数 `registerReceiver`。工厂实际给这个字段放入 `WV.tv` Context 包装，代码不假定它是 `Application`。
- `org/chromium/device/time_zone_monitor/TimeZoneMonitor.smali`：`getInstance(long)` 先创建对象及 `WV.aq2`，互相保存引用，将原生指针写入 `b`，然后注册 `TIMEZONE_CHANGED` 接收器。
- `WV/aq2.smali`：检查事件 action 和非空 `Intent.EXTRA_TIMEZONE`，以对象 `b` 中的原生指针调用 `J.N.VJO(0x56, pointer, zone)`。实现调用原接收器，不直接拼装 JNI 分发号或原生指针。

包装只识别这个精确接收器类，并验证接收器、监视器的双向引用、非零指针和单一事件过滤器。其他接收器、权限、调度 Handler、flags 及注册返回的 Intent 保持原值。

## 通知时机与恢复

安装发生在已有来宾 Application、数据目录后缀与提供程序身份确认之后，且 Chromium 启动状态仍为空闲。新分支只安装包装，不创建页面或执行脚本，不主动启动引擎。

监视器随后注册时，保留真实 Android 注册，并在同一调用线程内给原接收器一次内部时区事件。这不发送 Android 广播、不修改系统设置。后续真实系统时区事件仅在该来宾仍启用策略时将此监视器收到的时区值改为目标值，其他元数据和其他系统接收器保持原行为。

构造期间同步通知的依据来自当前官方 [Android 监视器实现](https://raw.githubusercontent.com/chromium/chromium/main/services/device/time_zone_monitor/time_zone_monitor_android.cc)及[基类实现](https://raw.githubusercontent.com/chromium/chromium/main/services/device/time_zone_monitor/time_zone_monitor.cc)：进入 Java `getInstance` 前，基类已构造默认时区与客户端集合；通知更新的是这部分基类状态，不使用派生类尚未赋值的 Java 引用。其更新路径同步采用新的 ICU 默认时区，后续新增客户端会收到缓存的目标时区。这里是源码支持的安全性分析，**没有把当前源码冒充此发行二进制的逐指令证明**。代码额外保护同步重入和原生对象已停止/变更的情况。

注销时将原接收器映射回实际注册的包装接收器。停用后不再改写系统事件；最后一个监视器注销后恢复原 Context 引用。由于 ICU 与已有 renderer 状态无法靠移除 Java 包装完整回退，停用或换来宾仍要求结束当前进程，不能复用到另一个来宾。已注册监视器仍存在时暂时保留注销映射，避免破坏提供程序清理。

## 状态与验证

- `ARMED_BEFORE_ENGINE`：仅证明启动前安装了包装。
- `MONITOR_NOTIFIED_RUNTIME_UNVERIFIED`：至少一次原接收器调用返回；`monitorNotifications` 是这种调用的计数，不是渲染结果。
- `monitorError`：接收器或对象一致性检查失败时的固定类别，不记录地址、URL、账号或凭据。
- `firstScriptRuntimeVerified` 仍固定为 `false`；实际首脚本 `Date` / `Intl`、后续读数、UTC 对照及重复启动必须由独立探针观察。不能仅用安装、JNI 返回或 Java 时区替代这些结果。

本模块用 Windows 上的 JDK 17、Android API 35 JAR 编译，并经 D8 转为 DEX。Java 源码和构建输入未加入宿主系统分支；macOS/Linux 构建及 Android 设备运行不在本子任务的本地编译结论内，桌面端三个平台均未修改。

## Test02 的首脚本边界

主任务真实手机记录 `mobile/.build/gbox-mod/phone-20261115/android16-test02.json`：

| 观察 | 时区 | 偏移 | epochMillis |
| --- | --- | --- | --- |
| 本次页面首个脚本 | Asia/Shanghai | +480 分钟 | 1794732271664 |
| 后续页面读取 | Asia/Tokyo | +540 分钟 | 1794732271688 |

两次观察相差 24 ms。主任务同时只读确认此探针使用独立的 Google WebView sandboxed renderer，不能把 browser 进程内的 ICU 更新推定为 renderer 已同步更新。

当前官方 [renderer 时区实现](https://raw.githubusercontent.com/chromium/chromium/main/third_party/blink/renderer/core/timezone/timezone_controller.cc)先从本进程 ICU 取得初始值，再通过 Mojo 订阅；收到通知才更新 ICU、V8 和 worker。对应[时区接口](https://raw.githubusercontent.com/chromium/chromium/main/services/device/public/mojom/time_zone_monitor.mojom)的订阅及通知均没有完成回执；已检查的 [InitializeRenderer 接口](https://raw.githubusercontent.com/chromium/chromium/main/content/common/renderer.mojom)也不携带初始时区。源码与实测支持“跨进程初始通知竞态”这一解释，不构成全部原生路径分析。

样本确有 `ProfileBoundaryInterface.warmUpRendererProcess()V`，其 `WV.cj2` 实现最终调用 `J.N.VJ(2, browserContextPointer)`，但没有 Java 完成回调。空白页的 `onPageFinished`、visual-state 回调及固定延时都不是时区接口的确认回执。当前 GBox 接入点位于主线程的 Application 发布后、providers/onCreate 前；同步等待异步预热会阻塞主 Looper，嵌套处理消息又会重入来宾生命周期。

因此本轮没有加入概率性的预热放行、通用 WebViewProvider 导航代理或固定延时，也没有修改探针结果。后续要达到严格首脚本保证，需要一个可验证的 renderer 初始化时区入口，或原生 IPC 确认与页面放行机制，并覆盖 renderer 重建、多个 profile 和进程复用；当前 Java 模块检查范围内尚未建立这一能力。
