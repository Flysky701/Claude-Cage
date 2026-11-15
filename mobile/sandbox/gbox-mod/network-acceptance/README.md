# 网络断线保护验收

此目录补齐 R02 的可执行验收入口，分为**只读设备前置检查**和**离线证据判定**。工具不会停止 VPN、修改设置、安装应用、发起请求或读取账号；真实网络验证仍须由设备任务安排受控目的地及出口观察。

当前用户仅授权完善 Cage 和检测，明确不进行全手机网络修改或断线实验。本轮只运行授权范围内的只读检查，R02 运行验收继续保留未完成；下述故障场景仅说明未来验收所需证据，不授权执行。

`network-probe/build.py` 的旧探针只测试三个 HTTPS 目标。请求失败不等于零外泄，也不覆盖 DNS、UDP、QUIC、IPv6 可用性和已建立连接。当前 `acceptance.json` 中列出的部分旧 `mumu/network-guest-*.json` 路径在本工作区不存在；缺少原文件的历史结论不能直接转成新的通过记录。

## 只读前置检查

```powershell
python mobile/sandbox/gbox-mod/network-acceptance/preflight.py --adb <adb绝对路径> --serial <明确设备> --port <独立ADB端口> --expected-artifact-sha256 <当前Cage包SHA256> --expected-vpn-package <实际VPN包名> --output <新的报告路径>
```

核对当前安装的 `com.cage.android` 单 APK 哈希、用户 0 的 always-on 包名和 lockdown 设置。报告不保存设备序列号、IP、安装路径或原始 `dumpsys`。连接状态中的 VPN 字样可能属于旧记录，故只记 `vpnMentionInConnectivityDump`，不会当作活动 VPN 或路由证明。

- `BLOCKED_PRECONDITION`：安装包、always-on 包名或 lockdown 至少一项不匹配，退出码 2。此时不能把停止 VPN 作为安全的断线实验。
- `REQUIRES_ONLINE_CONTROL`：静态前置条件存在，退出码 0；仍未确认来宾身份、活动路由、有效出口或断线行为。必须先取得当前来宾的在线阳性对照。

工具对每条 ADB 操作设 20 秒上限。没有设备操作授权或另一任务占用设备时，只完成本地检查，不执行该命令。源代码本身没有自动修正系统设置的分支。

## 离线判定

复制 `input.template.json` 到本机证据目录，在实际测试后填入标准化观察。空模板返回 `NOT_RUN`，不包含假结果。

```powershell
python mobile/sandbox/gbox-mod/network-acceptance/evaluate.py <标准化观察.json> --output <新的判定.json>
python -m unittest discover -s mobile/sandbox/gbox-mod/network-acceptance -p test_acceptance.py
```

判定器只在完整矩阵通过时退出 0；失败、未执行和证据不足退出 2。输入损坏或不受支持的结构报错，不自动改写为通过。所有输出路径必须是新文件。

`scenario` 选择 `gateway-stop`、`gateway-crash`、`gateway-startup`、`network-switch`、`device-restart` 或 `background-resume`。一次记录只覆盖一个场景，其他场景始终在 `untestedScenarios` 中列出。

`context` 需要绑定 `artifactSha256`、`policySha256`、`probeSha256`，以及 `guestIdentityVerified`、`sameArtifactAndPolicy`、`blockConditionVerified`、`lockdownVerified` 四项真实观察。`policySha256` 必须对应经脱敏的策略清单，不能用 VPN 包名/开关的前置指纹冒充完整策略身份。`evidence` 指向相应本机脱敏证据。

每个 evidence 使用 `{"path":"相对输入文件的本机证据路径","sha256":"对应文件SHA256"}`。判定器验证文件存在及哈希，输出只保留固定结果，不复制路径或证据内容。归一化字段必须来自人工核对或可靠采集器；文件哈希只能保证内容未变，不能证明字段陈述真实。

`cases` 中每项格式如下（此为字段说明，不是测量值）：

```text
id: 以下固定矩阵中的一项
sameFlowAcrossTransition: 已建立连接跨故障前后是否确为同一连接
online:
  outcome: EXPECTED_EGRESS | NO_PUBLIC_RESPONSE | UNSUPPORTED | NOT_RUN
  freshResponseCorrelated: 唯一请求标记对应真实受控端响应，排除缓存
  evidence: 在线阳性对照的文件与哈希
blocked:
  outcome: NO_PUBLIC_RESPONSE | PUBLIC_RESPONSE | NOT_RUN
  freshResponseCorrelated: 是否确为本轮请求的响应
  attemptCount: 1 至 20
  durationMs: 1 至 60000
  evidence: 断线阶段的文件与哈希
egressObservation:
  attributedToGuest: 能把观察流量归属于当前来宾
  coversFullWindow: 完整覆盖测量窗口及故障切换
  allRelevantInterfaces: 覆盖所有可能实际出口
  lossFree: 观察过程无丢包或采样缺口
  directPacketCount: 本窗口观察到的直连包数
  evidence: 脱敏的出口观察结果与哈希
```

固定矩阵为 `https-domain-new`、`https-v4-new`、`https-v6-new`、`dns-udp-v4-new`、`dns-udp-v6-new`、`udp-v4-new`、`udp-v6-new`、`quic-v4-new`、`quic-v6-new`、`tcp-v4-established`、`tcp-v6-established`、`udp-v4-established`、`udp-v6-established`。目标、随机请求标记和原始地址仅在采集器内存或私有受控端中使用，不写入此报告。

未配置支持 IPv6/UDP/QUIC 的在线受控端时，该项为 `INCONCLUSIVE`，不能因请求本来就失败而认定阻断成功。缺少原文件、在线阳性对照、完整出口观察或已建立连接，也只能保留未测/不确定。确认归属于来宾的直连包或断线后的新鲜公网响应，在完整上下文验证后才记 `FAIL_OBSERVED`；若产物、身份、策略或阻断条件未核验，保留 `INCONCLUSIVE / OBSERVED_TRAFFIC_UNVERIFIED_CONTEXT`，并单独记录 `trafficObservation`。公网响应只能说明阻断后仍有响应，不能单凭响应排除代理缓冲或证明直接绕过。所有矩阵通过只返回 `PASS_FOR_RECORDED_MATRIX`，永远不输出普遍“零泄漏”。

## 设备接续与已发现边界

1. 当前真机使用外部 FlClash；先在设备空闲后采集上述只读前置状态。旧 MuMu lockdown 或其他模拟器的防火墙不构成真机证据。
2. 明确受控目标和出口观察能力，再由自有来宾探针产生有界请求。普通 ADB shell 请求的 UID 不是 GBox 来宾，不能拿它冒充来宾验证。
3. 校验在线阳性对照，之后才安排被授权的停止/故障场景；按原设置恢复并验证，保持所有账号和应用数据。此工具不执行这些操作。
4. 当前 `light-gateway/CoreService.java` 关闭 TUN 后依赖 Android always-on + lockdown 阻止普通路由；`safeReady()` 检查二者。没有启用 lockdown 就不能声称服务退出后仍保护流量。
5. `light-gateway/StatusProvider.java` 目前只允许 `top.niunaijun.microdem` 且签名匹配的调用者；当前 GBox 包名为 `com.cage.android`。该接口不能未经适配直接作为 GBox 的真实就绪检查。此处只记录问题，未修改网关鉴权或扩大允许调用者。

本目录只做离线代码测试，未执行手机、MuMu、macOS 或 Linux 网络验证。Python 标准库实现无宿主平台分支；Windows 上的单元检查不等于三平台设备实测。
