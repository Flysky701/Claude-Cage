# 隔离渲染进程的原生时区初始化实验

此目录只构建 `io.github.leexeo.cage.timezonelab`。**不是 Cage 补丁，不进入 Cage 构建源目录，不自动安装，不声明 R01 已完成。** 自有离线实验已运行，实际 Cage 的服务和 Application 装配尚未获准接入。

## 已验证的路线

程序将自己的 WebView renderer 请求转到自己的 `isolatedProcess=true`、`externalService=true` 服务。它保持 Android 隔离 UID，并继续加载手机上原 Google WebView 的 `SandboxedProcessService`，未修改 Google WebView APK。当前只测 API36、Google WebView `156.0.8078.47 / 807804703`、ARM64。

在加载 Chromium 原服务之前，实验在这个专用隔离进程内初始化 ShadowHook 2.0.1，只将三个原生系统属性入口读取 `persist.sys.timezone` 的结果设为 Tokyo，其他属性转发原实现。它不写系统共享属性区，不改全手机时区或网络。浏览器侧仍使用现有 `MonitorContext`，防止后续通知把时区重新改回 Shanghai。

实验的目标页面直接加载，没有提前求值、等待、固定延时或改写 `Date`/`Intl`。不声明通用 hook 完整性：这是已测 WebView 初始化入口，不是所有 native 读取方式的隔离证明。

## 对照和结果

- 仅设置子进程 Java 默认时区和 `TZ` 环境变量：无通知对照的最早空白文档和目标页面仍为 Shanghai，不能算修复。
- 提前初始化原生时区，但浏览器侧保留系统通知：最早空白文档读取到 Tokyo，随后目标页面变回 Shanghai。这证明两端必须保持一致；不能只靠首个偶然成功值。
- 两端均设置为 Tokyo，目标页面不预热：最终 `renderer-service05.apk`，SHA-256 `ce107042714c22c73166682550647e208cb785d6930f0cc6c81761f8150f8a77`；五轮直接冷启动和五轮含 renderer 重建的运行通过，共 10 个不同应用进程、15 个目标页面、60 组首脚本/iframe/worker/后续读数。5 次 renderer 主动结束后均收到退出回调，新对象重新经过原生初始化。

结果及源码身份见 [VALIDATION-2026-11-15.json](VALIDATION-2026-11-15.json)。完整实验数据留在本地 `mobile/.build/gbox-mod/webview-firstscript-lab/renderer-service05-results.json`。首两项对照来自本轮观察记录，不与最终重复运行混为同一批数据。

## 仍需批准的实际接入范围

拟议接入仅限下一份同版本、同签名 Cage 测试包：

1. 增加专用隔离渲染服务；只在已选中的 Claude/自有探针、精确 WebView 版本与当前策略仍有效时转发。
2. 为该专用隔离进程提供最小 Application，使它不运行 GBox 的账户/私有存储初始化；主进程及其他组件继续委托原 `CoreComponentFactory`。
3. 增加仅供该隔离进程加载的原生时区模块。初始化失败必须终止本次受保护加载，不静默回退未保护 renderer。
4. 核对 Manifest 和包条目差异后，保留现有 UI、签名、版本、原容器核心和预置 APK，使用原始来宾探针复验。另检查历史恢复、多个 WebView/profile、后台恢复和真实已登录页面；不清数据、不重新认证、不发送消息、不改手机全局网络设置。

风险在于服务启动、组件工厂和原生初始化会影响实际应用的渲染流程，独立应用通过不能证明 GBox 接入兼容。自动审批因此拒绝了生产接入；部分新建的未引用草案已移出生产源码目录，仅在本地保留不可编译的审阅副本。本次 GitHub 上传不包含这些生产草案、不修改 Manifest 或自动开启该机制。

## 构建与使用边界

```text
python mobile/sandbox/gbox-mod/privacy/renderer-lab/service-experiment/build.py --output mobile/.build/gbox-mod/renderer-service-new.apk
```

除父目录构建说明中的输入，还使用本地 Checks02 APK 中已有的 ShadowHook 库；该 APK 和开发签名不上传。NDK LLVM 目录可用 `--llvm` 显式指定。仅 Windows 构建和当前 Android16 手机运行经过实测；macOS/Linux 未实测，桌面三端未修改。

在已有明确设备授权且已安装精确实验 APK 后，运行 `run.py`，参数与父目录相同，使用 `--modes renderer renderer-recreate --repeat 5` 复验。脚本只操作独立实验包，不操作 Cage。服务桥和原生 hook 仍是原型，不应直接复制到产品：运行时样本确认、并发、失败处理、组件生命周期和作用域验证都必须在接入时补齐。
