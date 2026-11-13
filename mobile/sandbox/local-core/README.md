# 手机本地 Mihomo 测试助手

此 APK 以一个独立的普通 Android UID 启动前台数据传输服务，使用通知显示测试状态。Mihomo 仅在手机回环地址上监听，使用每次启动生成的认证口令，TUN 关闭。核心通过手机网络直连已选节点。ADB 只负责安装、传入配置与读数，不承载测试业务流量。

测试助手使用项目相同版本的[上游 Mihomo v1.19.33](https://github.com/MetaCubeX/mihomo/releases/tag/v1.19.33)。构建脚本校验官方 Android arm64 压缩包摘要，APK 包含未改动的核心可执行文件。这个可调试构建供本机 ADB 测试使用。

## 运行

通过 Cage 安卓实验版的「本机沙箱 → 配置与启停代理」可以在手机上保存 SOCKS5 地址、启动或停止核心。支持 `socks5://server:port` 和 `socks5://username:password@server:port`；凭证含 URI 分隔符时应使用百分号编码。保存的单节点配置位于助手私有目录，运行中的核心下次启动时读取新配置。界面的「启动时已验证出口」仅表示本次启动已完成一次 HTTPS 查询。使用桌面现有节点配置做开发测试时，也可沿用以下 ADB 流程。

1. 先按手机诊断应用的说明构建 Cage 0.3，以生成项目开发签名。在 Windows 上设置 `ANDROID_HOME` 和 `JAVA_HOME`，然后运行 `mobile/sandbox/local-core/build.ps1`。也可传入 `-Sdk` 和 `-Jdk`。
2. 用 `adb -d install -r mobile/.build/on-device-core/Cage-LocalCore.apk` 安装辅助应用。
3. 在仓库根目录运行 `python mobile/sandbox/local-core/provision.py --adb <adb.exe路径>`。脚本适用于当前 Cage 生成的单节点配置，只把节点、代理组和出口规则传入应用私有目录，不复制桌面接口、控制端口或宿主 TUN 设置。
4. 打开「Cage 本地核心测试」，点「启动本地核心」。助手使用带认证的本地连接，向检测站点发起校验证书的 HTTPS 请求。私有文件 `files/online-reference` 记录 Unix 毫秒时间和检测站点看到的 IPv4。测试日志只标记成功或错误类别。
5. 点「停止本地核心」，或在真机来宾对照期间用 `adb -d shell run-as io.github.leexeo.cage.localcore touch files/stop` 仅停止本次核心。结束后用 `adb -d shell run-as io.github.leexeo.cage.localcore rm -f files/upstream.yaml files/upstream.tmp files/runtime.yaml` 清理本次节点配置。

助手保留了两个仅面向已安装测试壳 UID、目的地限于出口检测站点的本机 Unix 套接字入口，以便复用上一轮诊断 APK。端点沿用了原来的名字，不会建立 ADB 转发。在所测 Android 16 手机上，来宾连接另一普通应用创建的这一入口返回权限拒绝。此助手可以验证手机核心、认证代理和出口，无法单靠这些入口接管任意来宾的普通 IP 套接字。

配合[来宾启动补丁](../../../patches/blackbox-reborn/guest-exit-check.patch)时，`ExitCheckService` 接受测试壳的显式绑定。它检查签名权限、消息发送 UID 和签名，只允许通过已启动的核心执行一次固定站点的 HTTPS 查询，并用 Messenger 回传 IPv4。核心停止后同一服务回传空值。探针 APK 和系统 curl 仍使用各自原有的网络接口。测试时可分别查看 `CageBoundExit`、`CageGuestExit` 和 `CagePlainNet` 日志，对照助手调用、来宾收到的结果及原程序自身的网络连接。

同一 Messenger 还支持[双向字节流](FixedSiteStream.java)。消息 1 保留服务端代查，消息 2 连接检测域名，消息 3 按来宾提交的指定地址连接。助手只接受检测域名和源码中允许的检测用 IPv4，端口固定为 443。连接成功后，助手将两条单向管道的来宾端作为文件描述符返回，由来宾完成 TLS 握手、主机名和证书校验、HTTP 请求及响应读取。核心停止时请求不会得到管道。

旧版已安装助手可能只支持消息 2。要复测系统 curl 的 `--connect-to` 路径，请用 `python mobile/sandbox/blackbox-light/build.py --only relay --sdk <Android-SDK> --jdk <JDK>` 构建当前助手，并与对应的 Curl4 测试壳配套安装。[真机三阶段记录](../../README.md#配套助手与系统-curl-的在线停机恢复2026-11-13)
