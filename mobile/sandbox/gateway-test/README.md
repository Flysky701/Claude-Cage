# 复测代理网关断网行为

此实验在 WSL 2 内创建三个临时 Linux 网络空间。普通客户端进程和它启动的 curl 子进程只接触一条以太网链路。网关将下游 TCP 转入 Mihomo，交给当前 Windows Cage 代理；对客户端的 DNS 查询由网关通过代理解析。测试同时建立一条备用公网路线，以便在停止代理后判断流量是否改走该路线。

在仓库根目录，使用 Ubuntu WSL 的 root 身份执行。第一个参数是本机 Windows Python 3 的 WSL 路径，第二个可选参数是已下载的 Mihomo 压缩包。

```bash
bash mobile/sandbox/gateway-test/verify.sh /mnt/c/path/to/python.exe
```

运行条件为可用的 WSL Windows 互操作、网络命名空间、TUN、nftables 内核支持，以及正在运行的本机 Cage SOCKS5 代理。脚本通过项目 Linux 依赖清单校验核心；Ubuntu 的 slirp4netns 和 nft 工具只解包到临时目录。Windows 侧从现有配置读取代理凭证，只通过本机进程的标准输入输出承载流量。

验证依次覆盖备用公网正对照、代理在线、测试上游停止、网关核心停止和恢复。每个阶段检查备用公网仍可用及客户端是否建立了新的备用 NAT 流。输出 `same-exit` 表示检测服务观测到的 IPv4 与同期 Cage 参考值相同。域名和固定数字地址均保留 TLS 主机名验证。脚本退出时清理临时网络空间和测试进程。

本目录供复测，不会把 Windows 热点或手机接入台架。实际部署需将测试中的客户端链路替换为专用下游接口，并确保手机无法通过蜂窝或其他 Wi-Fi 回落。
