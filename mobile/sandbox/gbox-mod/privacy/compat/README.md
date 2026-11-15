# MuMu 受限兼容诊断模块

`runtime.cpp` 与 `typed_adapters.inc` 由上层 `compat/apply.py` 编入同一 ARM64 库。上层负责精确原库样本、MuMu Android 12 / x86_64 ART 环境和两个入口的匹配及重定向；本模块替代原有 JNI 安装 helper 和两个 Binder 原入口读取点。当前是诊断候选，尚未完成 GBox 启动或隐私验收。

普通 JNI 保留独立的 32 字节 ArtMethod 及独立 Method 强引用，原实现通过类型正确的 ARM → JNI → Method.invoke 适配器调用。只接受不可移动 boot `.art` 映像中的类，并核验真实 x86 原入口、JNI/quick 入口、方法身份及引用生命周期。已有 Probe03 实测支持这一代表性路径；GBox 的实例方法和多参数适配仍需集成验证。

Binder 的 UID/PID/WorkSourceUid 保持 CriticalNative 无参 int ABI。安装前各自比较原 JNI 调用与 raw 原入口返回，只记录比较结果；仍调用 GBox 原 UID 回调。Probe05 已验证 Java → ARM CriticalNative → 原 x86 无参入口与后续独立 JNI 健康检查；Probe04 中 ARM 控制器嵌套调用替换后的方法再检查异常会崩溃，该边界保留，不宣称通用兼容。

原回调、IO 引擎、返回值及原异常传播保留。缺失必要方法、签名或架构不符、备份无效、未知安装调用和两个辅助读取不完整均明确失败。旧版不存在的重载及 Java 兼容包装仍按原 helper 逻辑跳过，不将它们强制变成 native 方法。
