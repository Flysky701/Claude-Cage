# Cage Lite for Windows x64

解压到本地目录，双击 `Start.cmd`。默认打开 Windows PowerShell。退出程序或在启动窗口按 Ctrl+C 会结束本次盒内进程和专用代理。会话跟随配置中的主进程；使用启动器转交给其他程序的应用，应选择最终运行的 EXE。每个程序的盒内文件和输出保存在 `%LOCALAPPDATA%\CageLite`，下次启动同一路径的程序会使用原有目录。

## 选择程序

编辑 `config.json`。把 `selected` 改成 `probe` 可以运行随包的父子探针；窗口显示后会自动检测并写入结果，完成后关闭窗口即可。增加程序时，在 `applications` 中添加一个名字、EXE 的完整路径和参数数组，然后将 `selected` 改为该名字。例如下面是一个应用条目。

```json
"myapp": {
  "program": "D:\\Apps\\MyApp\\MyApp.exe",
  "arguments": [],
  "workingDirectory": "D:\\Apps\\MyApp"
}
```

选择新的 EXE 不用重新编译。命令行也可运行 `Start.cmd --app myapp`，或用 `Start.cmd --config D:\Configs\my-shell.json` 指定另一份配置。程序路径相对于配置文件解析，支持 `%SystemRoot%` 等 Windows 环境变量。参数逐项传入，支持 `{root}`（启动器目录）、`{output}`（此应用的共享输出目录）、`{run}`（本次运行标识）和 `{proxy}`（此次本地 HTTP 代理地址）。

## 普通 TCP 客户端与子程序

将 selected 设为 raw-tcp，或执行 Start.cmd --app raw-tcp，可运行示例。RawParent.exe 启动另一个 x64 映像 RawChild.exe。两者不读取代理参数或代理环境变量，仅用 TcpClient、SslStream 和普通 DNS、时间接口。默认各做一次请求后退出，结果在输出目录内本次运行的子目录中。

在应用条目中用 childPrograms 列出需要同步 DNS 和东京时间的其他 x64 EXE 完整路径（也支持相对于配置文件的路径）。仅列出路径不会启动子程序；由应用自行启动。网络规则作用于整个盒，时间和同步 DNS 适配仅作用于列出的映像。

在 tcpServices 中定义固定服务。host 支持 IP 或域名，port 是真实服务端口，listenPort 可省略以自动分配回环端口。对指定域名的查询同样经过 DNS 转发器。以名为 resolver 的服务为例：

```json
"tcpServices": {
  "resolver": { "host": "1.1.1.1", "port": 443 }
}
```

将应用的服务器地址填为 127.0.0.1，端口参数可以写成 {tcpPort:resolver}；需要一整段地址时用 {tcp:resolver}。没有命令行选项但可以在界面填写端口的程序，可使用启动窗口显示的端口，或预先设置固定 listenPort。TLS 名称仍应使用真正的服务名。每个入口只允许本盒进程连接，并仅通往配置的一个目标。入口出现 TCP 握手成功只说明与本地转发器连通，示例使用认证成功的 TLS 业务应答判断远端是否可用。

此模式需要应用能够选择服务地址。直接向原始公网 IP 和端口发起的套接字仍被拒绝，未实现任意目的地址的透明重定向。配置服务不会为宿主创建 TUN、路由或全局防火墙规则。

## 本机依赖与出口

需要 Sandboxie Plus（实测免费版 1.18.8）、64 位 Python 3.10 或以上（本机实测 3.13）、Mihomo 核心和可用的 SOCKS5 上游。包内已有编译好的 x64 兼容组件、探针和 dnspython 2.7.0，无需 pip 安装。启动器默认只读 Cage 已保存的连接配置及其记录的 Mihomo 路径。Cage 工作台无需打开；若连接配置指向本机代理端口，该端口仍需在线。独立部署时可指定 `proxyCore`、`connectionFile` 和 `sandboxieDirectory`。连接文件使用 `proxy_url`、`dns_url` 两个字段。SOCKS5 入口和 HTTPS DoH 解析器使用 IP 地址，避免引导连接向宿主查询 DNS。

本机启动会话后，Python 启动器与 DNS 转发器共占约 22 MiB 私有内存，专用 Mihomo 约占 61 MiB。这是一次运行中采样，不含目标应用、Sandboxie 和原有上游进程。每个运行会话放行两个基础回环端口和显式配置的固定服务端口。一个处理同步 DNS，另一个是需要会话认证的 HTTP/SOCKS 混合代理。DNS 和业务连接都使用同一指定上游。上游凭据通过标准输入交给专用 Mihomo，盒内应用只获得本次会话的代理凭据。启动器设置 `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY`，并清空 `NO_PROXY`。需要自己选择代理的程序可读取 `CAGE_LITE_PROXY`、`CAGE_LITE_USER` 和 `CAGE_LITE_PASSWORD`。PowerShell 示例在当前进程中设置 .NET 默认代理。需要观察解析时加 `--trace-dns`，查询域名和返回码只显示在控制台。

## 已测范围

兼容组件按盒名和配置中的完整 EXE 路径生效，支持对应 x64 映像的同步 `GetAddrInfoW`、`FreeAddrInfoW` 和东京的 Win32 时间读取。同一 EXE 派生的子进程也适配。显式列入 childPrograms 的其他 x64 映像也会应用这套适配；未列出的辅助进程仅受盒网络规则约束。支持 A/AAAA 结果、ASCII 域名和基本地址族筛选；异步 DNS、IDN、全部 Winsock 标志以及直接读取时区注册表未覆盖。

未配置应用代理的原始公网套接字受阻，不会被自动转换成代理连接。启动器沿用宿主已有的 Sandboxie WFP 状态。此次机器未开启全局 WFP，验证范围是所测程序和调用路径，不能据此保证任意底层网络接口都被内核拦截。壳不修改宿主时区或系统代理，也不替代 Cage 的完整隔离检查。

`verification.json` 保存此版本的运行结果。修改源码时，可用 MinGW-w64 运行 `gcc -shared -Os -Wall -Wextra -s -o addon/CageRegion.dll addon/region.c -lws2_32` 重建兼容组件。
