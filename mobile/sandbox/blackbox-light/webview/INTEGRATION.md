# microdem 的 WebView 传输模块

仅供 `top.niunaijun.microdem` 轻量 DEMO、Android arm64/API 28+。宿主壳继续不申请 INTERNET。此目录不修改现有空间构建或设备；运行验证由主对话完成。

```powershell
python mobile/sandbox/blackbox-light/webview/build_module.py --ndk mobile/.build/tools/android-ndk-r28c --sdk mobile/.build/tools/sdk --jdk E:/Dependencies/Runtimes/jdk-17.0.12 --build-tools E:/Tool/Android/sdk/build-tools/36.0.0
```

输出本目录 `.build/libcage_webview.so`、`webview-route.jar` 和 `classes.dex`。编译使用 Android API 28、16 KiB 最大页大小、完整 RELRO、立即绑定和 BTI/PAC。Windows/macOS/Linux 工具名分别处理，设备和其他平台运行尚未验证。

接入只需：

1. 将该 Java 模块加入修改后的 microG APK 的 DEX；将 SO 放入同一来宾可加载的 `lib/arm64-v8a/libcage_webview.so`。类名必须保留 `io.github.leexeo.cage.webviewroute.RouteWebView`；需确认 APK 保留 `androidx.webkit.WebViewFeature`、`ProxyController`、`ProxyConfig$Builder`，否则补入 AndroidX WebKit 运行库。仅有 WebViewClientCompat 不足以保证 R8 保留上述类。
2. `LoginActivity.createWebView(Context)` 中把构造指令的 `new-instance` 和 `<init>(Context)` 所属类一起替换为 `Lio/github/leexeo/cage/webviewroute/RouteWebView;`，返回类型仍为 WebView，其他登录逻辑不变。
3. 壳须先用原 GuestExitCheck 启动当前进程的 `space-<真实PID>-egress.sock`。路径固定为 `/data/user/0/top.niunaijun.microdem/cache/space-<PID>-egress.sock`；socket 必须归当前真实 UID、权限不向组或其他用户开放。助手沿用现有 Binder 域名流，不改 TLS、Cookie 或 HTTP 内容。

JNI 导出名称：

```text
Java_io_github_leexeo_cage_webviewroute_RouteWebView_nativeInstall  ()I
Java_io_github_leexeo_cage_webviewroute_RouteWebView_nativeStatus   ()Ljava/lang/String;
```

Java 构造后立即阻止加载，安装原生映射，再反射设置单个 HTTP 代理 `127.0.0.1:38491`，无 DIRECT、无隐式本地绕过。只在代理回调后解除加载阻断，按顺序释放最多八个提前到达的 `loadUrl`/`postUrl`。回调缺失或任一步失败保持阻断。日志不含 URL、请求体、Cookie 或凭据。microG 原有 WebViewClient、JS bridge、Cookie 与证书校验均继续使用。

原生仅修改已加载的四个精确库名：`libmonochrome_64.so`、`libmonochrome.so`、`libwebviewchromium.so`、`libwebviewchromium_64.so` 的函数导入槽，支持标准 RELA 与 Android APS2；不改 libc，不根据导入槽原值执行未知代码。IPv4 TCP socket 变成 Unix stream，connect 只准 `127.0.0.1:38491`；IPv6/UDP 在 Chromium 导入入口拒绝。保留原非阻塞/CLOEXEC，SO_ERROR 使用真实 Unix 内核结果；仅为已追踪的 Unix FD 适配 TCP_NODELAY、keepalive 参数及 IP 地址查询。安装前后从本模块未经替换的 libc 入口验证四项 INET 创建仍获 EACCES/EPERM。解析、覆盖或写保护恢复失败则关闭路由并尝试回滚。

日志标签 `CageWebViewRoute`、`CageWebViewNative`。`RouteWebView.routeStatus()` 可输出安装与连接计数。nativeInstall 负值：`-1` 原始内核边界不符；`-2` Unix 入口缺失/归属不符；`-3` ELF/import 扫描失败；`-4` 已装钩子覆盖改变；`-5` 页大小不支持；`-6` 写入/恢复失败。只有本地编译不能证明 WebView 已联网；真机优先查看安装成功、proxy applied、proxy connect 与原转发层 CONNECT 日志，再确认登录页，最后只停核心验证新请求不直连。
