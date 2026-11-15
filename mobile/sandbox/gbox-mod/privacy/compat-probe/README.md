# MuMu JNI 兼容性探针

当前状态：**第三版独立备份与转调、第五版 Java 发起的 CriticalNative 调用已在 MuMu 全部通过。** 第一版因 ARM 文件视图重定向停止架构证明；第二版从实际映像确认了 x86 原入口，普通 JNI 注册与替换成功，但直接转调原入口 SIGILL。第三版改用独立备份和 JNI 反射调用，替换前后及一次 GC 请求后的完整调用均通过。

第四版验证 `Binder.getCallingUid()I` 的 CriticalNative 特殊 ABI。注册、再次查找、标志和包装入口检查通过；ARM 控制方法内嵌套 JNI 调用已返回正确标记，随后在 `ExceptionCheck` 阶段崩溃。不能把跳过异常检查当修复。第五版将原入口直接调用放到注册前，并改由 Java 发起替换调用，再单独进入普通 ARM JNI 方法检查健康状态；单次实测所有阶段通过，正常退出、无崩溃。第四版的嵌套限制仍存在，真实 GBox 启动及屏蔽尚未因此验收。

GBox 的完整崩溃现场已确认：原生入口偏移探测失败后返回 `0`，随后把 AudioRecord 回调写入 `ArtMethod` 的类引用字段；下一次查找 `native_start` 时崩溃。此探针验证可替代的桥接路径，不修改 GBox 或其屏蔽模块。

探针仅支持 **Android 12（API 31/32）、ARM64 翻译环境**。在校验可读边界后从实际内存映像读取 ELF 头，并核对执行段、入口地址和映射文件偏移，确认原入口是 x86 后才注册。前三版只读不存在的属性键；第四、五版只比较 Binder 调用返回值，不记录真实 UID。没有网络、账号、系统属性写入，也不直接写原方法或运行时方法数组。完成后退出本进程，替换随进程结束失效。

第三版为范围受限的实验：只为已确认处于不可移动 boot `.art` 映像、且与 `Object` 使用同一加载器的类，建立独立的 32 字节方法备份和独立反射 `Method`。保留原 JNI/quick 入口，使用进程期对齐存储及全局强引用，再通过 JNI 调用备份的 `Method.invoke`。验证内容包括替换前后原返回值、递归哨兵、独立元数据与入口，以及一次正常 `System.gc()` 请求后的再次调用。这不是通用 ART 备份实现，尚未应用到 GBox。

从仓库根目录离线构建：

```powershell
python -X utf8 mobile/sandbox/gbox-mod/privacy/compat-probe/build_probe.py
```

当前产物为 `dist/Cage-NativeBridge-Probe-05.apk`，构建说明在同名 `.json`；此前已签名的各版产物和实测报告独立保留。工具链复用项目已缓存的 NDK、JDK 与 Android 构建工具。

获准执行后，由负责 MuMu 的操作聊天统一验证：

1. 仅向明确指定的可丢弃 MuMu Android 12 实例安装 APK。
2. 启动 `io.github.leexeo.cage.nativebridgeprobe/.NativeBridgeProbeActivity` 一次。
3. 读取该包私有文件 `files/latest-native-bridge-report.txt`（可用 `run-as`），同时保存 `CageNativeBridgeProbe` 日志；若崩溃，仅保留此探针的崩溃记录。正常完成会自行结束进程，并非启动失败。

第五版按以下顺序判断：

1. `PASS critical.raw.original.matches.baseline.value.not.logged`：注册前 ARM 直接调用原 x86 无参 CriticalNative 入口，返回值与 Java 基线相同。此结果及环境表检查先经预打开文件描述符写入并同步，随后才调用 JNI 检查。
2. `PASS critical.install.returned.to.Java`：注册方法已返回 Java；尚未证明替换调用可用。
3. `PASS critical.Java.replacement.marker`：Java 直接调用特殊方法得到 ARM 替换标记。
4. `PASS critical.separate.ARM.JNI.health`：另一次普通 ARM JNI 进入后，环境表、回调次数及异常检查通过。
5. `PASS critical.Java.direct.original.matches.baseline.value.not.logged`：Java → ARM 回调 → 原 x86 无参入口的返回值正确；随后再次做独立健康检查。
6. `PASS all.critical.Java.caller.stages`：本条 Java 调用路径通过。第四版嵌套调用失败的边界仍保留，不能据此自动宣称全部 CriticalNative 调用兼容。

第三版已通过阶段保留如下，供核对独立备份方案的证据：

| 阶段 | 判断 |
| --- | --- |
| `PASS baseline.original.value` | 原方法正常返回默认值。 |
| `PASS original.entry.is.x86` | 已从入口所属 ELF 确认原入口是宿主架构；无法确认则 `STOP`，不安装替换。 |
| `backup.integrity ...=true` | 备份方法地址独立，类/DEX 身份、原 JNI/quick 入口和强引用均保持。 |
| `PASS backup.before.registration.call` | 安装替换前，独立备份已真实调用原实现并返回原值。 |
| `register.after result=0` | 翻译侧注册返回成功；尚未证明回调可执行。 |
| `PASS lookup.after.registration` | 替换后仍能查询方法；另检查类引用、DEX 方法编号及 native/static 标志。 |
| `PASS replacement.only.call` | 宿主到 ARM 替换回调的路径实际成功。 |
| `PASS backup.after.registration.call` | 原方法已被替换，但独立备份仍返回原值。 |
| `callback.before.JNI.backup.Method.invoke` | 即将从 ARM 回调经 JNI/反射调用备份；递归会被哨兵明确标为失败。 |
| `PASS backup.delegate.call` | 上述完整转调链和返回值实际成功。 |
| `PASS backup.delegate.after.normal.gc` | 一次普通 GC 请求后，元数据/强引用复核和完整调用再次成功。 |
| `PASS all.backup.bridge.stages` | 本代表性调用全部通过；仍需随后验证 GBox 的对应改动及实例/CriticalNative 签名。 |

各阶段独立判断。最后的原入口转调失败，不能抹去此前注册、查询和替换回调已经通过的证据；`STOP` 也不能视为兼容性通过。
