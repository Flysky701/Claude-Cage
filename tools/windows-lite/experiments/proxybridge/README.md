# ProxyBridge Windows 对照实验

**本机结论：驱动加载受阻，未启用发布功能。** ProxyBridge Windows v4.3.0 官方安装包通过发布摘要和 Authenticode 校验。CLI 成功解析两条规则，随后引擎退出。SCM 事件 7000 为 Win32 1450。使用同一驱动、独立于 CLI 的 SCM 加载也得到 1450；未调整任何保护设置。

没有运行中的 ProxyBridge 规则可供本机验证。请勿把下列诊断命令用于长期放行业务流量。原 Cage Lite 的固定服务走代理出口，盒外运行同一文件时走宿主出口。result.json 分别用 `<proxy-egress-ip>` 和 `<host-egress-ip>` 记录两者。无引擎时，单独放行原始目的地址会让盒内两个 EXE 都通过宿主出口成功访问，专用上游新增连接数为零。

## 复现入口

在已安装 Sandboxie、Mihomo、64 位 Python、7-Zip 的 Windows 测试机上，从本目录运行。工作目录应为专用空目录。

```powershell
.\prepare.ps1 -Work D:\CagePB-test -SevenZip 'C:\Program Files\7-Zip\7z.exe'
python -B .\evaluate.py D:\CagePB-test
```

脚本按固定版本下载官方安装程序并仅解包，编译两份自有测试 EXE。盒内外都从同一路径启动，使用不同输出目录。普通测试进程不提权。引擎辅助脚本请求 UAC，把经过摘要验证的 CLI、DLL、驱动放入临时的 Program Files 目录；只为这两个 EXE 到 1.1.1.1:443 构造规则。使用的本地代理凭据仅在测试会话有效。若已有 WinDivert 或 ProxyBridge 实例，辅助脚本停止初始化。CLI 退出后清理本次驱动服务与临时目录。

在具备可用驱动的机器上，完整路径测试原有阻断策略和仅限实验目标的放行策略，分别终止会话 Mihomo、恢复它、再结束 CLI 引擎；有同路径的盒外对照。--control-only 只测无引擎的 DNS 与时区。--allow-control-only 在全新临时盒内验证目标放行带来的直连，只允许指定数字 IP 和端口，完全不启动 ProxyBridge。协议为未经代理配置的 TcpClient + SslStream，验证服务端 TLS 证书并解析公开出口回显。

result.json 包含本机已完成项目、失败阶段、分组内存和未测试项目。正常的独立启动器不使用此实验性规则。
