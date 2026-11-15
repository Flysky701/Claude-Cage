# 独立 WebView 加载开关诊断

包名 `io.github.leexeo.cage.webviewprobe`，Android 9+，目标 API 35。应用不声明任何权限，使用本目录独立生成的开发签名，不读取或修改已有空间、账号与代理配置。不使用原生钩子，不设置代理，不处理登录。

两个按钮分别启动 `:plain`、`:wrapped` 进程，并使用不同 WebView 数据目录：

- `plain`：普通 Activity Context，权限方法只观察并返回系统原值。
- `wrapped`：只将 WebView 的 Context 换成窄 ContextWrapper。仅为本进程的 `INTERNET` 自查返回逻辑授权，其他权限及 calling-only 查询保持原值；`getApplicationContext()` 仍返回原应用 Context。WebView 派生的配置 Context 保持包装。应用、包管理器和内核均不获得权限。

JSON 记录权限调用的方法、阶段、实际/返回值及少量调用栈；WebView 提供程序版本；初始 `getBlockNetworkLoads()`；设置为 false 的结果；创建 WebView 前、设置后、加载结束后各四项原始 `Os.socket` 检查。只创建后立即关闭套接字，不连接或发送。`EACCES`/`EPERM` 记为 `permission_denied`，不把不支持地址族等错误当作权限拒绝。

默认仅加载固定的 `https://example.com/`，无登录、脚本或自定义 URL 参数。其他导航被阻止；TLS 错误一律取消。记录主框架错误，15 秒后保存观察结果。`onPageFinished` 也可能对应错误文档，不能作为联网成功证据。**本实验只验证第一层加载开关；即使 wrapped 能设为 false，也未解决 Chromium 的代理传输。**

## 构建

只需本地 Python 3.8+、JDK 17+、Android SDK 的 `platforms/android-35` 和 Build Tools（包含 aapt2、zipalign、lib/d8.jar、lib/apksigner.jar），无需 Gradle 或联网下载。脚本按宿主系统选择 Windows `.exe` 或 macOS/Linux 工具名；D8 和签名工具直接由 Java 运行，不依赖 `.bat`/shell 包装器。

```powershell
python mobile/sandbox/webview-probe/build.py --sdk E:/Workspace/Claude-Cage/mobile/.build/tools/sdk --jdk E:/Dependencies/Runtimes/jdk-17.0.12 --build-tools E:/Tool/Android/sdk/build-tools/36.0.0
```

macOS/Linux 使用相同参数，替换为各自 SDK/JDK/Build Tools 路径。可用 `--platform` 指定已安装的平台目录名，用 `--output-dir` 指定产物目录。默认输出本目录 `.build/Cage-WebView-Probe.apk`，同时生成并保留自己的 `webview-probe-development.p12`；重复构建复用此开发密钥。开发密钥口令为 `android`，仅用于本独立诊断包，不用于发布。

构建会验证 APK 签名、ZIP 对齐和最终权限清单。源码编译不等于设备验证，ContextWrapper 是否被实际提供程序保留由真机 JSON 判断。

## 安装与采样（由拥有设备的主对话执行）

```text
adb install -r mobile/sandbox/webview-probe/.build/Cage-WebView-Probe.apk
adb shell am force-stop io.github.leexeo.cage.webviewprobe
adb shell am start -W -n io.github.leexeo.cage.webviewprobe/.MainActivity --es mode plain
adb shell run-as io.github.leexeo.cage.webviewprobe cat files/probe-plain.json
adb shell am start -W -n io.github.leexeo.cage.webviewprobe/.MainActivity --es mode wrapped
adb shell run-as io.github.leexeo.cage.webviewprobe cat files/probe-wrapped.json
```

等待 JSON 的 `completed` 为 true（通常立即报告错误，最迟约 15 秒）。如只测设置、跳过页面，启动时添加 `--ez load_page false`。每种模式只保留最近一份小 JSON；`run_id`、`pid`、`process_instance`、`run_in_process` 用于识别样本。严格冷启对照可在每种模式前分别 force-stop 本诊断包；这不会停止其他空间。

预期比较：两种模式的 manifest/Activity/包管理器授权均为拒绝，三轮内核四项均为权限拒绝；对照初始开关及 setter 结果。若 wrapped 仍被拒，查看 permission_events 判断 WebView 是否调用了包装 Context，或先取了原 application Context。不得据此扩大 manifest 权限、绕过 TLS 或宣布代理已修复。
