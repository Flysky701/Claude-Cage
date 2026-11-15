# WebView 首脚本时区隔离实验

2026-11-15：已在原 Android 16 手机完成独立实验，**尚未接入 Cage，R01 仍未完成**。本目录验证一种有条件的放行机制，不把自有页面结果当作 Claude 或任意 WebView 的修复证明。

后续进展：[独立渲染服务初始化实验](service-experiment/README.md) 已进一步验证更早的原生初始化路径，目标页面不经本节的等待机制。该实验通过 10 个独立应用进程、15 个目标页面及 5 次 renderer 重建；仍未接入 Cage。本页保留前一条“确认后加载”路线及其边界。

## 实验机制与范围

程序为 `io.github.leexeo.cage.timezonelab`，没有 INTERNET 权限。它只加载内置 HTML、srcdoc iframe 和 Blob worker，不访问真实页面、账号、Cookie 或 Cage 数据。

仅接受 API 36、Google WebView `156.0.8078.47 / 807804703`。实验复用当前 `WebViewTimezone.MonitorContext`，由原 Chromium 接收器更新原生时区；直接构造此包装是实验入口，**没有执行完整的来宾绑定、策略启停与生产准备链**。访问框架所需 helper 只从现有原始容器样本中提取，没有改系统隐藏 API 设置。

应用自己控制页面加载：在同一个 WebView 的初始 `about:blank` 上异步读取真实 `Intl`、`Date`，同时确认 `Asia/Tokyo` 与 `+540`，才调用目标页面加载。10 ms 仅是未确认时的重试间隔，经过该时间并不放行；5 秒截止后报告失败，目标页面不加载。代码不替换 `Date`/`Intl`，不修改目标测试页面读数，不打开调试端口。

每次创建新的 WebView 都重新确认。`gate-recreate` 使用公开 API 结束本实验自己的 renderer，接到 `onRenderProcessGone` 后销毁旧 WebView，再创建和确认新对象。它不结束 Cage 或其他应用的进程。

## 实测结果

最终实验 APK SHA-256：`fe921de3258baf9bbfb77cb948c3b5793fdc0257f0a16890e2404c7afd8b2302`。测试前核对手机实装包与本地 APK 完全一致，报告通过每次唯一会话标识排除旧文件。

| 检查 | 结果与界限 |
| --- | --- |
| 外层未安装时区包装的自有页面 | 首脚本、iframe、worker、后续值均为 Shanghai/+480。 |
| 只安装原监视器，无放行确认 | 本实验这一轮恰好为 Tokyo；不覆盖 Cage 已复现的竞态。 |
| 确认后首次加载、刷新、新 WebView、renderer 重建 | 每种 5 轮，共 20 个不同应用进程、35 份目标页面结果；140 组 `Intl`、偏移、UTC 读数通过。 |
| 初始化竞态 | 30 个 WebView 确认阶段中，25 个首次仍读到 Shanghai，随后确认 Tokyo 才加载目标页面。 |
| renderer 重建 | 5 次主动终止均收到退出回调；重建后的目标页面、iframe、worker 首次读数为 Tokyo。 |
| 确认条件故意不满足 | 5 秒截止后目标页面数为 0，未回退放行。仅测试放行条件，不改写引擎值。 |
| JavaScript 关闭 | 真实确认结果为空，实验没有加载页面，也没有自行打开 JavaScript。这是接入限制，不算通用兼容性通过。 |

应用进程不同不等于已逐一记录 renderer PID；本实验没有重启系统 WebView zygote。源码与完整证据的摘要见 [VALIDATION-2026-11-15.json](VALIDATION-2026-11-15.json)。原始脱敏报告保存在 `mobile/.build/gbox-mod/webview-firstscript-lab/monitor04-*.json`。

## 为什么没有直接替换 Cage 的导航接口

1. 本实验由自有 Activity 控制异步加载。任意来宾的 WebView API 还包括同步返回历史列表的 `restoreState(Bundle)`。[Android 原接口](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/main/core/java/android/webkit/WebView.java)以及手机样本 `WebViewChromium.smali:17826` 都保留同步返回；把它排进异步队列并先返回空值会改变应用恢复行为。在主线程同步等待本实验的回调则会阻塞回调所需的 Looper。
2. 提前调用公开 `evaluateJavascript` 会阻止随后选择其他 profile。当前 [Chromium 实现](https://raw.githubusercontent.com/chromium/chromium/main/android_webview/java/src/org/chromium/android_webview/AwContents.java)有显式检查，手机样本 `AwContents.smali:4403` 也包含对应错误分支。不能无条件在 WebView 构造后抢先执行。
3. JavaScript 关闭时，这个公开入口无法确认；强行改设置会改变页面行为。多个 profile、弹窗、历史恢复、页面自行导航、后台恢复和真实 Claude WebView 流程仍未验证。

因此，这是一条**由应用控制加载时可行的候选机制**，不是可直接推广的通用 `WebViewProvider` 代理。生产接入仍需在不改变上述接口语义的前提下建立 renderer 初始化保证或原生确认/放行点，再用原始来宾探针复验。不得把 `firstScriptRuntimeVerified` 改为 true，也不得用本实验为生产 UI 标记通过。

## 数据与平台边界

本轮未构建或覆盖安装 Cage、未重启其来宾、未清数据、未重新登录、未发送消息，也未写入手机全局网络或时区设置。只读核对 Cage 仍是原 Checks02 哈希 `1567aaf6c84e7af7dbecbcd90211358f9fc40602273b4541a63f5618b9075b61`；系统时区仍为 `Asia/Shanghai`。登录态本轮没有重新打开检查，沿用上轮记录，不把包未变当作重新认证验收。

实验程序保留安装，已结束其进程。Windows 上完成 Java/DEX 构建与真机测试；macOS/Linux 仅保留显式工具路径和可移植文件操作，未实机构建。桌面三平台代码、数据格式和 UI 都未修改。未升级 Cage 版本、提交、推送或发版。

## 复现

从仓库根目录运行；构建只写独立实验包，不自动安装：

```text
python mobile/sandbox/gbox-mod/privacy/renderer-lab/build.py --output mobile/.build/gbox-mod/renderer-lab-new.apk
```

Windows 默认使用本仓库已有工具。其他主机或工具位置可指定 `--jdk`、`--build-tools`、`--android-jar`、`--apktool`、`--hidden-api-smali`。需要原容器中已有的 `org/lsposed/hiddenapibypass` Smali 目录及本地开发签名；本目录不分发第三方输入或签名密钥。

设备操作须沿用任务的设备授权。测试脚本要求显式选择设备、端口和已经安装的精确 APK：

```text
python mobile/sandbox/gbox-mod/privacy/renderer-lab/run.py --adb <adb-path> --port <port> --serial <serial> --apk <installed-lab-apk> --output <new-result-json>
```

默认逐项运行上述八种模式，`--modes` 可选择子集，`--repeat` 为 1–10。脚本只停止/启动实验包、读取它的私有报告并核对实验 APK，不安装、不卸载、不清理应用。失败报告保留并返回非零退出码；预期的禁止放行检查与 JS 关闭观察有各自结果，不算目标页面通过。
