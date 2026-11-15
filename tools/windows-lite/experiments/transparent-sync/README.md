# 本地同步 TCP 透明代理实验

这是免费、自有适配代码的独立实验，不接入真实应用准入，不使用 Sandboxie 的付费代理设置，也不修改或绕过许可证检查。

`sync_proxy.c` 通过 Sandboxie 的普通 `InjectDll64` 扩展入口，仅对本次登记的三个 x64 探针映像挂接同步 `connect`。探针仍向原来的数值 IPv4 地址和端口发起普通阻塞 TCP 连接；适配器在同一 socket 上连接本次回环 SOCKS 服务，完成临时会话认证及 CONNECT 后才返回成功。失败时不重新连接原目标。

`probe.c` 编译为父、子、孙三个独立 EXE。它们不读取代理选项、代理环境变量或个人配置。每次请求携带随机挑战，由两个本地合成目标回应；第三个本地目标是禁止访问的对照。探针报告各自的 PID、盒归属以及当前进程中 DLL 回调的实际完成状态，避免以继承的环境变量代替加载证据。

`run.py` 编译组件并创建随机 `_output/windows-lite/transparent-sync-*` 数据目录和唯一 `CageProbeSync_*` 盒。每次配置写入都读回核对。整盒默认 `NetworkAccess=*,Block`，仅放行本次 SOCKS 回环端口；合成 SOCKS 服务只能连接两个测试目标。它既不使用互联网，也不读取真实代理密码或个人文件。

运行需要 Windows x64、64 位 Python、已有的 MSVC x64 Build Tools/Windows SDK，以及 Sandboxie Plus 1.18.8。WFP 必须已由外部安装流程启用；脚本读取驱动状态位确认后才创建盒，不改变全局 WFP、系统代理、路由或时区。

```powershell
python .\tools\windows-lite\experiments\transparent-sync\run.py --build-only
python .\tools\windows-lite\experiments\transparent-sync\run.py
```

可以通过 `--sandboxie` 指定安装目录。生成目录中的 `build.log`、`build.json`、`results/*.json` 和 `verification.json` 保留源码构建摘要和完整结果。退出时先保留整盒默认阻断，再终止所有所属进程，直接从驱动核对进程列表为空，最后禁用本次测试盒；不会删除配置、文件或注册表数据。初始化失败、控制接口失败和进程未退出会使总结果失败。

验收包括：

- 无适配 DLL 的探针不能直连合成目标，而宿主对照能访问三个目标。
- 父、子、孙进程都进入同一盒，自动代理访问两个不同目标；第三目标被拒绝。
- 关闭本次 SOCKS 服务后，已有连接、新连接及断线后新派生进程均不能访问目标；宿主对照继续成功。
- 错误会话凭据不能联网；恢复正确的新会话后，只能重新经过代理访问允许目标。
- 每次成功请求能在 SOCKS 连接记录和目标挑战记录中对应；最终盒内无遗留进程。

2026-11-15 的完整本地实验已连续三次通过，结果目录为 `transparent-sync-20261115-145333-e29b89d5`、`transparent-sync-20261115-145510-be15069b` 和 `transparent-sync-20261115-145702-f8c6bb5e`。最后一轮同时验证每项配置写入后的读回结果。此前调试运行有 DLL 初始化和进程枚举错误，均已修正；另一次断线阶段探针提前退出未复现，失败证据仍保留，不能据此宣称长期稳定或开放真实应用。

**验证范围仅为自建 x64 探针的本地 IPv4 阻塞 Winsock `connect` 路径。** 未验证真实互联网出口、DNS、IPv6、UDP/QUIC、非阻塞连接、WSAConnect、ConnectEx/IOCP、32 位程序、浏览器或任意桌面应用。它不替代隐私隔离、完整应用兼容性或第一阶段整体验收；不改变 `space.py` 的启动阻断。
