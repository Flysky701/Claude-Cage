# VPN 网关恢复代码

从手机现有网关 APK 恢复的 20 个 Smali 源文件，输入身份记录在 `recovery.json`。本目录使用报告中的 Android VPN 网关方案。当前原网关覆盖当前 Android 用户；始终开启和断网保护由系统设置管理。

`build.py` 重建网关代码，保留输入 APK 的原生隧道库与资源。恢复了可编辑代码，未找回原始 Java、原生库源码或原签名私钥。

`--mode test-copy` 生成独立的“Cage 恢复网关”，使用独立应用编号与配置目录。不会自动继承原网关凭据，也不会自动替换系统正在使用的 VPN。完整步骤见 [恢复说明](../recovery/README.md)。
