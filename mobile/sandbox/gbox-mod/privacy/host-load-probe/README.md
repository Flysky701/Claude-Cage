# 独立原生加载验证

当前诊断包为 `dist/Cage-Host-Load-Probe-02.apk`，第 01 版产物保留。两版使用独立包名 `io.github.leexeo.cage.hostloadprobe`，不修改 GBox 或现有隐私探针的数据。APK 的主原生库只有 ARM64；x86_64 辅助库和单独的 HostBridge DEX 存于 assets。清单没有网络、账号或其他权限。

Activity 将 HostBridge 交给以系统引导加载器为父级的独立 DexClassLoader，并确认该加载器不能解析应用的 Sentinel 类。x86 JNI 包装保留原 `Runtime.nativeLoad` 方法身份，直接调用保存的同架构原入口，避免第 10 版复制 ArtMethod 导致的 JNI_OnLoad 类加载器特判失效。包装只在成功时经真实 JNI 调用 ARM 回调，不直接跳转到 ARM 函数指针。辅助类与回调类在注册后保留全局引用，生命周期覆盖该测试进程。

一次冷启动依次检查：

1. 原路径加载 ARM 基线库，JNI_OnLoad 找到仅应用加载器可见的 Sentinel。
2. 安装包装并比较同一缺失路径在安装前后的原错误字符串。
3. 加载不同的 ARM 阳性库，再由第三个库的 JNI_OnLoad 嵌套加载第四个库；四个库各初始化一次。
4. 三次成功加载均通知 ARM 并返回，原方法元数据和 JNI 健康保持；Java 缺失库调用仍抛原异常且不产生成功通知。
5. 创建真实 WebView，用 `loadData` 加载本地空 HTML 至 `onPageFinished`；网络加载被明确禁用，不设置时区。此项只验证第 10 版 DrawFunctor 失败路径。

编译与签名：

```powershell
python mobile/sandbox/gbox-mod/privacy/host-load-probe/build.py --compile-only
python mobile/sandbox/gbox-mod/privacy/host-load-probe/build.py --finalize-only
```

脚本复用项目的 JDK 17、Android 工具与 NDK r27d，不执行设备操作。产物已通过定向编译、两个 DEX 的类隔离检查、ARM 主 ABI 检查和开发签名。第 02 版使用 `--compile-only --reuse-base mobile/.build/gbox-mod/host-load-probe01` 复用未改动的 x86 辅助库、Host DEX 和四个 ARM 哨兵库，随后只完成打包签名。

第 01 版实际通过了原方法身份、缺失路径前后错误对照、四个哨兵各初始化一次、三次 host 成功通知、嵌套深度及元数据检查；在 ARM 回调计数断言处失败，后续 Java 缺失路径与 WebView 尚未执行。该版没有在断言之前保存实际数组，因此不能从已有结果判断是哪一项不符。

第 02 版只补充诊断，未放宽原断言。open/install 的固定返回文字先记录再判断；每个阶段的 host、ARM state 和新增 details 数组先写日志、立即保存 JSON，再判断。ARM details 记录进入/退出次数、参数是否为空、类和方法查找、调用结果及固定异常阶段。相对第 01 版仅 Manifest、主 DEX 和 ARM 诊断库变化，其余非签名内容相同。第 02 版 MuMu 实测已通过：三次成功加载后的 ARM state 为 `[3,3,0]`，WebView 本地页面完成后为 `[5,5,0]`，原方法元数据保持，异常计数为零。第 01 版失败的根因仍未确定，不能把增加诊断视为已证明的修复；本探针通过也不代表 GBox、隐私屏蔽或登录通过。

设备执行方启动 `.HostLoadProbeActivity`。固定阶段日志标签为 `CageHostLoadProbe`；阶段记录保存到 `files/latest-host-load-report.txt`，结束摘要保存到 `files/latest-host-load-report.json`。完成标记为 `FINISHED passed=`。测试结束后只终止自身可丢弃进程，使进程内原生注册自然失效；若提前崩溃，文本记录保留已完成的阶段。
