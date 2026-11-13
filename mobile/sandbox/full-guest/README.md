# 独立来宾网卡实验

这套真机实验把两层分开：应用 UID 内的 Limbo/QEMU 运行 x86 整机；来宾只有一个 E1000 设备。QEMU 的帧后端是应用私有 Unix socketpair，`FrameBackend` 处理 ARP，将 IPv4 TCP 和本地映射 DNS 交给 HEV，再经手机本地 Mihomo 出网。最终测试没有使用 QEMU 默认 NAT、宿主 TUN、Android VPN 或 ADB 网络转发。

当前启动包只含 Android-x86 9.0-r2 的内核和早期用户空间、对应 E1000 内核模块、诊断启动脚本和本机已有的 x86_64 curl 及其库。PID 1 在独立来宾内配置静态 Ethernet 地址。普通 curl 校验原站 TLS 证书；数字地址采用 `--connect-to`，不会把数字地址用作 TLS 证书名称。代码仅允许来宾 IPv4 TCP 和内部 DNS，不提供外部 UDP 或 IPv6 转发。

## 本次的可复用输入

- [Limbo 6.0.1](https://github.com/limboemu/limbo/releases/tag/v6.0.1-LimboEmulator) 的 x86 版本 APK，取其中 ARM64 宿主引擎和 PC 固件。
- [HEV 2.19.3](https://github.com/heiher/hev-socks5-tunnel/releases/tag/2.19.3) 的官方 Android AAR。使用公开 JNI 接口和应用创建的数据报文件描述符，未打开手机的 `/dev/tun`。
- [Android-x86 9.0-r2](https://www.android-x86.org/releases/releasenote-9-0-r2.html) 的 x86_64 内核、初始 ramdisk 及完全匹配版本的 `e1000.ko`。本次按 HTTPS Range 取启动文件和模块所需的索引及数据块，总量约 10 MiB；未下载完整 ISO，未做整盘摘要校验。

## 从仓库根目录复测

已有实验输入和预生成的 `test-initrd.gz` 位于 `mobile/.build/full-guest/`。APK 不内置节点、上游凭证或完整系统盘。

1. 如需重新打包，在 Windows 用 `mobile/sandbox/full-guest/build.ps1 -LimboApk <上游APK> -TunnelAar <HEV的AAR> -Sdk <AndroidSDK目录> -Jdk <JDK目录>`。签名沿用 Cage 本地实验开发签名。
2. 如需重制启动包，工作目录内要有原始 `initrd.img`、匹配的 `e1000.ko` 和 `site-address`（检测域名当时确实可达的公网 IPv4）。从本机 x86_64 Ubuntu 运行 `sh mobile/sandbox/full-guest/local-curl.sh <工作目录>`，再运行 `python mobile/sandbox/full-guest/prepare_ramdisk.py <工作目录>`。
3. 按[本地核心说明](../local-core/README.md)启动手机上的 Mihomo，确认手机取得 HTTPS 参考出口。安装 `Cage-GuestBench.apk`，运行 `python mobile/sandbox/full-guest/provision.py --adb <adb路径> --workdir <工作目录>`，再从手机打开「Cage 来宾启动实验」。配置位于各应用私有目录。核心每次冷启动生成新口令；重启后须重新暂存后端配置、冷启动来宾。
4. 用 `adb -d shell run-as io.github.leexeo.cage.fullguest cat files/serial.log` 观察来宾内核和两种请求。可在已取得匹配出口后，用 `adb -d shell run-as io.github.leexeo.cage.localcore touch files/stop` 只停手机测试核心，观察同一来宾后续请求。宿主蜂窝独立对照须继续可达。
5. 测完使用 `adb -d shell am force-stop io.github.leexeo.cage.fullguest` 收回来宾内存，删除来宾运行器私有的 `files/backend.yaml`，并按核心说明清理节点配置。

## 边界

当前 APK 是无显示的启动及网卡实验。完整 Android 验收还需可用的 Android 系统盘、Android 框架启动和普通 APK 安装路径；完整系统还要配置静态 Ethernet 或补充 DHCP。本次没有运行 Android 的包管理器、电话服务或应用框架，因此不能从这些结果推断 APK 的 SIM、语言、时区、Android 网络类型或特定官方应用兼容性。x86_64 来宾运行仅含 ARM 原生库的 APK 还涉及 ABI 支持。
