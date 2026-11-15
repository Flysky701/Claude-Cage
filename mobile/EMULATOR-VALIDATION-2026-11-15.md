# Android 模拟器完整性与 Claude 登录验证（2026-11-15）

## 追加对照的最新结论（16:24）

按要求补测 AlwaysStrong，并换用 Google 官方 Android Emulator 的独立 Google Play 镜像。**MuMu 加 AlwaysStrong、官方模拟器未 root、官方模拟器加 AlwaysStrong，三组均为 Basic / Device / Strong 全部失败，官方 Claude 均明确提示无法经 Google Play 验证，未进入对话页。** 下文的“首轮”记录保留；本节与文末追加对照是后续结果。

这排除了“仅 MuMu 出现该现象”和“最终轮模块只是安装、没有实际加载”这两种简单解释，但没有定位 Google 服务端拒绝的唯一原因，也不证明所有模拟器或配置均不可能通过。原有三项完整性、Claude 登录和完整隔离标准没有降低；当前不满足正式集成条件。

## 首轮结论

本轮选择本机 MuMu 6.8.8.0 的独立 Android 12 实例，实测 ROOT + PIF + Tricky Store + NeoZygisk。**未达到“三项 Play 完整性全部通过、官方 Claude 登录和对话正常、原有隔离要求同时成立”的验收标准。** 停止该组合的本轮验证，不进入 Cage 正式集成。

- Google 测试账号登录成功，Play 能下载并安装应用。
- 确认 Zygisk、PIF companion 和 Tricky Store 进程运行后，Basic、Device、Strong 仍全部显示失败。
- 官方 Claude 由 Play 下载并安装；选择已登录的测试账号后，提示“登录无法完成，因为此应用无法经 Google Play 验证”。没有进入对话页。
- 网络失效保护通过下列有限测试；完整隔离验收未通过，尤其不能把电话服务缺失后的 SIM `UNKNOWN` 当作无卡 `ABSENT`。

以上仅否定本次具体组合和配置，不证明所有模拟器、所有模块配置均不可能通过，也没有确定 Claude 服务端要求的具体完整性等级。

## 环境与实际加载状态

| 项目 | 实测配置 |
| --- | --- |
| 宿主 | Windows；仅此平台实测 |
| 模拟器 | MuMu 6.8.8.0，Android 12 / API 32，x86_64，Hyper-V |
| 独立实例 | `Cage-Integrity-Lab-20261115`，实例编号 `3` |
| ROOT | `31.0-kitsune:MAGISK:R`，非官方 Magisk 分支；安装后关闭 MuMu 原生 root |
| PIF | Play Integrity Fix `v4.9-inject-s` |
| Tricky Store | `v1.4.1 (245-72b2e84-release)` |
| Zygisk | NeoZygisk `v2.4 (289-08080ef-release)`；替换未实际启动的内置 Zygisk |
| Google Play 服务 | 经 Play 更新为 `26.44.32 (190800-1015688330)` |
| Play 商店 | Google 签名 `38.4.22-21 [0] [PR] 582466152` |
| 检测器 | Play Integrity API Checker `2.2`，包名 `gr.nikolasspyr.integritycheck` |
| Claude | `1.261113.19`，包名 `com.anthropic.claude`，安装来源 `com.android.vending` |

首轮发现内置 Zygisk 没有运行，因此没有把“模块安装成功”视作完整组合生效。安装并校验 NeoZygisk 后重启，实际存在 `zygisk-ptrace64`、`zygiskd64`、`zygiskd64-playintegrityfix` 和 `TrickyStore` 进程。没有导入外部设备的证明密钥。

MuMu 安装器附带的部分 Google 组件未通过 APK 签名校验，因此改用可验证的 Google 签名组件。之后补齐商店包自带的 x86_64 原生库，解决下载无法开始的问题。测试账号在本实例登录，云端备份已关闭；本报告不包含账号或密码。

## 完整性与 Claude 的实际结果

| 检测轮次 | 条件 | Basic / Device / Strong |
| --- | --- | --- |
| 首轮 | PIF、Tricky Store 已安装，但内置 Zygisk 未启动 | 全部失败；不能代表完整组合效果 |
| 第二轮 | NeoZygisk 和 PIF companion 已运行；受控网络恢复，系统时间校准 | 全部失败 |
| 最终复核 | 网络稳定后，仅重启 Google 服务及检测器进程，不清数据 | 全部失败 |

最终检测器返回的原始响应中没有 `deviceRecognitionVerdict`；应用识别、许可、Play Protect 为 `UNEVALUATED`。按 Google 文档，没有满足任何设备标签时会省略该设备判定字段；`UNEVALUATED` 表示未评估，不能改写成“证书错误”或“未购买”。见 [Google Play Integrity 判定说明](https://developer.android.com/google/play/integrity/verdicts)。

检测器结果只属于检测器的包名。Claude 自身另行实测：从 Play 下载、安装、打开，选择测试 Google 账号后，显示无法经 Google Play 验证。期间有 MuMu 悬浮层挡住账号选择窗口，关闭该悬浮层后才取得上述明确拒绝结果。本轮没有解码 Claude 凭证或取得其服务端拒绝详情，不能断言 Claude 必须要求 Strong，也不能将检测器的许可字段当作 Claude 的许可字段。

Tricky Store 日志包含缺少 vbmeta 公钥、未找到 StrongBox、无法运行 `lshal` 等错误；Google 服务日志还出现过 DroidGuard 初始化及 Keystore 错误。这些是候选问题线索，不足以单独证明根因。

## 隔离与网络检查

| 项目 | 实测结果与边界 |
| --- | --- |
| 独立数据 | 新建空白实例；没有复用手机空间或导入已有模拟器账号。测试账号与安装应用保留在实例 3 |
| 宿主共享目录 | 个人目录、APK、产品和按键目录映射到本次独立测试目录；`private_shared` 指向实例 3 自身目录。未完成任意宿主文件越界读取测试 |
| 剪贴板 | 虚拟机配置读回 `disabled`；未完成双向标记传输实测 |
| 应用可见 VPN | 两轮普通应用探针均为 `vpn=false`，活动接口为 Wi-Fi；未启用 Android VPN |
| SIM | 首轮为虚拟 SIM 就绪、中国移动信息；最终为 `UNKNOWN(0)`、无有效订阅、运营商字段为空，电话服务不完整。**不能判为无卡隔离通过**；系统属性仍保留模拟运营商值 |
| 时区 | 首轮探针 `Asia/Shanghai`；最终 Java、ICU、WebView 均为 `UTC`。未完成完整的配置切换、语言及重启持久性验收 |
| 网络路径 | Android TCP/DNS 经本地透明代理、专用 ADB reverse，再到宿主独立测试代理；宿主出口检查为日本，Google HTTPS 正常 |
| ADB 转发消失 | 移除测试端口转发后 HTTP 新连接失败；恢复后返回 204。此项不是物理拔线或整个 ADB 服务退出测试 |
| Android 代理停止 | 停止来宾代理后 HTTP 请求超时；恢复后成功 |
| 宿主代理退出 | 退出前 HTTP 返回 204；停止身份核对过的独立测试代理后，域名和数字 IPv4 HTTP 请求均失败 |
| IPv4 / IPv6 直连 | 客机内 IPv4/IPv6 输出阻断规则存在；数字 IPv4 ICMP 失败，IPv6 ICMP 无路由。没有完成全部 UDP、DNS 泄漏、IPv6 业务和既有长连接矩阵 |
| 重启 | 开机规则和模块实际读回存在；启动过程没有做全程抓包，不能宣称已证明不存在启动竞态 |

宿主原有出口防火墙规则保持不动。原 Cage 美国出口被其阻断后，使用现有可用的日本节点进行本次实验；这不等同于完成原美国 Webshare 出口要求或 Cage 的出口绑定、代理链及完整网络设置集成。

## 保存与收尾

本次实例已关闭，独立宿主代理已停止，测试 ADB reverse 已移除。账号、应用和持久磁盘没有清除；保留空白实例及 ROOT 安装后的离线备份，不覆盖现有备份。当前完整测试状态保留在实例原磁盘中，旧备份不包含后加的测试账号。

原有实例编号 0、1、2 的 12 个配置文件中，最终 11 个哈希与初始一致；实例 0 的 `customer_config.json` 不同。该实例测试期间原本就在运行，初始只保存了哈希，不能据此确定变化来源或内容；没有擅自覆盖恢复，也不能声称所有原实例配置逐字未变。

本轮仅新增本报告及本机被忽略的实验材料，没有修改 Cage 共用接口或数据格式，没有升级版本、提交、推送或发版。macOS、Linux 没有运行验证；现阶段没有三平台产品能力结论。

本机证据目录：`mobile/.build/emulator-integrity-20261115/`。该目录含测试账号状态、代理私有配置及原始诊断材料，不应整体上传。适合复核的文件：

- `integrity-final.png`、`integrity-final.xml`、`integrity-final.json`：最终三项结果及移除 nonce 的响应。
- `claude-login-failed.png`、`claude-login-failed.xml`：Claude 实际拒绝登录。
- `final-components.txt`：模块运行进程、版本及安装来源。
- `network-verification.json`、`host-proxy-stop-verification.txt`：网络中断与恢复结果。
- `privacy-baseline.json`、`privacy-final.json`：隔离探针两轮结果。
- `google-signature-verification.json`：Google 组件签名检查。
- `existing-config-hashes-final.json`、`final-stopped-state.json`：原配置比较及测试实例停止状态。

后续只有在有新的可验证依据时才继续本组合，例如定位 DroidGuard/Keystore 的具体不兼容点。若转向未 root、认证系统的独立真机加 ADB，需要重新验证三项完整性、Claude 实际登录，以及同等隔离和失效断网；不能预设真机自动满足全部要求。

## 追加对照：AlwaysStrong 与 Google 官方模拟器

### 测试条件和修正

本次使用 [AlwaysStrong 项目](https://gitlab.com/Evokerr/AlwaysStrong) 的 `v1.0.6.1`。下载的默认整合包仅带 ARM Zygisk 库，不能直接代表本次 x86_64 设备的完整方案，因此实际采用 **AlwaysStrong Lite / nopif + 独立 PIF v4.9-inject-s + NeoZygisk v2.4**。没有把不匹配的整合包测试结果当作最终结果，也没有同时运行原 Tricky Store。

MuMu 中核对并调整了 Google 服务的目标配置，验证 TEESimulator 对 Google 服务 UID 实际生成新证明链。随后在另一个独立环境对照：Google Android Emulator `37.2.13`，Google Play Android 12 / API 32 / x86_64 revision 4 镜像。官方模拟器先保留未 root 基线，再使用官方 Magisk `31.1` 安装同版本模块。

两边固定相同的 PIF 指纹、keybox 和安全补丁配置，关闭自动更新；Google Play 服务、商店、检测器和 Claude 版本与首轮表格对齐。官方模拟器最终读回 Magisk、NeoZygisk、PIF companion、TEESimulator 均运行；内置 Zygisk 关闭，由 NeoZygisk 提供加载。AlwaysStrong 启动时会重写目标清单，已在重启后重新核对并恢复实验目标，验证普通探针和 Google 服务确实经过模块。官方模拟器保持 SELinux Enforcing；两环境仍存在镜像、root 实现等差异，这不是严格单变量实验。

没有清除账号或 Google 服务数据。官方模拟器 Google 登录成功，检测器与 Claude 从 Google Play 下载；Claude 最终版本 `1.261113.19`，安装来源读回 `com.android.vending`。rootAVD 安装过程中额外授予三个用户应用的“所有文件访问”权限已恢复为默认，并逐一读回核对。

### 实际结果

| 环境 | Basic | Device | Strong | 官方 Claude 的 Google 登录 |
| --- | --- | --- | --- | --- |
| MuMu + PIF / Tricky Store / NeoZygisk（首轮） | 失败 | 失败 | 失败 | Google Play 验证拒绝 |
| MuMu + PIF / AlwaysStrong Lite / NeoZygisk | 失败 | 失败 | 失败 | Google Play 验证拒绝 |
| 官方 Android Emulator，未 root | 失败 | 失败 | 失败 | Google Play 验证拒绝 |
| 官方 Android Emulator + PIF / AlwaysStrong Lite / NeoZygisk | 失败 | 失败 | 失败 | Google Play 验证拒绝 |

官方模拟器安装模块后的首次请求返回 `CLIENT_TRANSIENT_ERROR (-17)`，没有设备等级判定，未计作三项失败。仅重启 Google 服务和检测器进程后重试，得到正式响应并保存：三个图标均为 Fail，响应仍省略 `deviceRecognitionVerdict`，其余相关字段为 `UNEVALUATED`。随后单独打开 Claude、选择已登录测试账号，16:24 实际出现“此应用无法经 Google Play 验证”的拒绝窗口。所有组均没有进入 Claude 对话页。

### 已定位的问题与尚未确定的根因

- 首轮确实存在内置 Zygisk 未启动、部分默认包 ABI 不适用、目标清单需重新核对等配置问题；最终对照已处理这些问题，不能把最终失败简单归为模块没加载。
- 未经模块处理的 Keystore 探针在两种模拟器中均报告软件安全级别，StrongBox 不可用。该事实不等于 StrongBox 是三项通过的必要条件。
- 原 Tricky Store 配置生成的证书链未匹配所下载的 Google 公布根公钥，证书有效期检查也未全部通过。AlwaysStrong 的测试输出改为匹配公布根公钥、链签名有效，MuMu 快照的有效期和吊销列表检查也未发现对应问题；官方模拟器的链签名与根公钥匹配已独立验证。
- 上述内容只是本地证明链验证。模块报告 `securityLevel=1`、`insideSecureHardware=true` 不证明模拟器拥有真实硬件 TEE，更不代表 Google 服务端接受了设备或 Claude 应用身份。
- 官方模拟器重现相同失败，因此 **MuMu 特有缺陷不是解释全部结果的充分条件**。仍未分离出服务端对模拟环境、指纹、应用识别及其他信号的具体拒绝原因；不能宣称已证明所有模拟器都不支持，也不能确定 Claude 所需的最低完整性等级。

### 追加网络与隔离验证

官方模拟器使用独立磁盘和目录，以宿主 HTTP 代理连接本轮专用出口；Android 内未使用 VPN。经用户授权添加仅针对这套实验程序的 Windows 出口规则，阻断非回环 IPv4 / IPv6 目标。新版模拟器的网络路径曾导致 DNS 不通，切换到另一内置网络实现后，实际 DNS 和 TCP 应用访问成功，才开始登录对照。

结束前同一脚本实测：专用代理运行时，数字 IPv4 HTTP 返回 301，域名 HTTP 返回 204；直接 ICMP 无响应。停止身份核对后的专用代理后，两个 HTTP 请求均不再收到任何 HTTP 响应，ICMP 仍无响应。`nc` 在代理关闭连接时可能以 0 退出，因此本记录以是否取得应用响应判断，不将退出码 0 误报为外网请求成功，也不将无响应扩写为所有 TCP 连接均无法建立。

这些是有限的失效保护检查，没有完成完整 UDP、DNS 泄漏、IPv6 业务、启动竞态、共享目录、剪贴板和全部 SIM / 语言 / 时区切换矩阵。MuMu 的普通应用探针仍为 VPN 不可见、SIM UNKNOWN，不能判定完整隔离通过；官方模拟器没有重复该完整探针矩阵。测试出口仍为日本，未完成原美国出口及 Cage 设置集成。

### 追加证据

以下路径均相对于被忽略的本机证据目录 `mobile/.build/emulator-integrity-20261115/`，不应整体上传其私有配置、账号状态或证明材料：

- `diagnosis/alwaysstrong-online.json` 与根目录 `alwaysstrong-online.png`：MuMu 加 AlwaysStrong 的正式结果。
- 根目录 `claude-alwaysstrong-online.png`、`diagnosis/claude-alwaysstrong-online.xml`：MuMu 上的 Claude 拒绝。
- `diagnosis/trust-comparison.json`、`diagnosis/final-module-diagnostics.txt`：证明链对照与 MuMu 模块实际运行证据。
- `diagnosis/avd/official-stock.json`、`official-stock.png`、`claude-official-stock.png`：官方模拟器未 root 基线（后两个文件在同一 avd 目录）。
- `diagnosis/avd/official-alwaysstrong-final.json`、`official-alwaysstrong-final.png`、`claude-official-alwaysstrong.png`、`claude-official-alwaysstrong.xml`：官方模拟器最终对照（均在同一 avd 目录）。
- `diagnosis/avd/final-module-diagnostics.txt`、`official-proof-validation.json`：官方模拟器实际加载、权限恢复与证明链验证。
- `diagnosis/avd/network-before-core-stop.txt`、`network-after-core-stop.txt`、`firewall-final-active.json`、`firewall-final-addresses.json`：关闭代理前后的请求与保护规则状态。

官方模拟器 root 前已离线备份完整 AVD 目录（包含账号所在数据盘、增量盘和加密文件）及原始 ramdisk，位于 `diagnosis/avd/checkpoint-before-root/`。本轮继续保留两套测试环境及既有备份；未升级版本、提交、推送或发版，仅 Windows 实测。

16:29 收尾：MuMu 实例 3 与官方模拟器均已停止，专用代理、网关和独立 ADB 服务已退出；授权的防火墙助手在确认实验模拟器进程全部停止后移除了三条临时规则。没有删除账号、应用、持久磁盘或备份。停止与清理证据见 `diagnosis/avd/final-stopped-state.json`、`firewall-status.json` 和 `cleanup-verification.json`。

## 继续定位 Basic 失败：指纹、模块与 Google 服务

本轮继续使用上述独立官方 API 32 模拟器，先离线备份当前 AVD 和 ramdisk 至 `diagnosis/basic-cause/checkpoint-before-basic/`。未清除账号、Google 服务或 Claude 数据，未降低 Claude 登录、三项完整性及原有隔离验收要求。

### 对照结果

下表中“失败”均表示取得正式完整性响应、三个图标均为 Fail；单纯请求异常不计入。检测器为 Google Play 安装的 Play Integrity API Checker 2.2。

| 对照 | 改动与有效性检查 | Basic / Device / Strong |
| --- | --- | --- |
| 原配置加调试记录 | 实际 GMS unstable 进程中出现 PIF 的属性映射和 Build 字段覆盖；AlwaysStrong 有生成证明密钥记录 | 均失败 |
| 关闭 PIF 属性映射 | 仅 `spoofProps=false`，其余沿用原配置 | 均失败 |
| 只更新指纹 | 从 10 月 Canary 换成 Google 目录当前活动的 11 月同机型 Canary | 均失败 |
| 新指纹及匹配补丁 | PIF 与证明配置均使用 2026-11-05；初次请求混入 GMS 恢复模式，剔除该轮；仅重启 unstable 后重测，无恢复模式和缺失实现错误 | 均失败 |
| 停用 AlwaysStrong | 重启确认模块停用，PIF 改为自身 `spoofProvider=true`，避免两种证明处理并行 | 均失败 |
| 修复 DNS 后 | 保持上一项模块配置，普通 UDP DNS 已恢复，Android 网络进入 VALIDATED | 均失败 |
| 更新 Google Play 商店后 | 通过商店自身更新到 54.1.11，再独立重测 | 均失败 |
| 临时补齐缺失启动状态 | 在上项条件下临时设置 verifiedbootstate、flash.locked、vbmeta.device_state；随后删除并通过重启确认恢复为空 | 均失败 |
| 恢复 AlwaysStrong 的最终组合 | 新指纹、匹配补丁、修复后的 DNS、商店 54.1.11；`spoofProvider=false`，模块运行、GMS 目标和 PIF 日志均核对 | 均失败 |

旧指纹为 `google/bluejay_beta/bluejay:CANARY/ZP11.260918.007/16484274:user/release-keys`，Google Flash 官方目录将该版本列为非活动；新指纹为 `google/bluejay_beta/bluejay:CANARY/ZP11.261016.008/16754936:user/release-keys`，对应 11 月活动版本。目录状态只证明版本选择依据，**不证明该指纹能通过 Google 完整性校验**。元数据保存在 `bluejay-google-builds.json`，实际进程覆盖值见各轮 `*-errors.txt`。

另从 Google Play 安装 SPIC 1.4.0，采用其本地 nonce / 解码方式交叉验证：返回 `NO_INTEGRITY`，设备标签为空，应用和账号为 `UNEVALUATED`。这排除了“只在一个检测器上发生”的解释；仍不能将检测器的应用许可判定套用到 Claude。

### 确认存在的问题及其影响

1. **DNS 配置确实不完整。** 修复前，普通 UDP DNS 大量超时，Android 网络验证受影响；部分 TLS DNS 成功不能代表普通 DNS 正常。加入仅走专用代理的来宾 DNS 转发后，UDP 查询得到响应，网络显示 VALIDATED / NOT_VPN。修复后的多轮正式检测仍失败，所以 DNS 不是足以解释剩余失败的唯一因素。
2. **连续强制停止整个 Google 服务干扰了实验。** 第一次匹配补丁测试中，GMS 启动恢复模式并出现 `Proxy without Impl`。后续改成只停止检测器、只重启 `com.google.android.gms.unstable`，保留主服务和商店；重测没有同类异常，仍失败。`Checking safeboot` 仅是检查日志，不能当作进入恢复模式。
3. **PIF 对空启动属性存在处理缺口。** 当前镜像的三个启动验证属性为空，而本版本脚本只修改已有属性。临时补齐后仍失败；已恢复原状态，未据此宣称修复了真实启动信任链。
4. **旧商店和旧 Canary 已排查。** 商店由 38.4.22 更新至 54.1.11，指纹与补丁也完成单项对照；这些调整均未带来 Basic 通过。

### 证明模块是否真的能签名

新增仅访问自身诊断 alias 的本地探针，不联网、不读取账号、不删除既有密钥。AlwaysStrong 生效时，首次生成带 challenge 的 EC 密钥，随后以该密钥签名，并用从证书 DER 重新解析的公钥验签；同一轮重新打开 Keystore 后再次签名。第二次启动应用复用原 alias，再比较证书链和公钥并签名。

两次运行均为 `OK`：生成公钥与叶证书一致，四次签名均验签成功，证书链和密钥在应用重开后保持一致。宿主另用独立密码库验证四次签名及两份证书链，均成功。这排除了本次探针范围内“只替换证书、私钥操作无法对应”的问题，但不证明 Google 接受该证明，也不证明模拟器具有硬件 TEE。API 返回的硬件安全级别仍可能由模块改写。

对 AlwaysStrong 对应的 [TEESimulator 源码](https://github.com/Enginex0/TEESimulator-RS/blob/v6.0.1-307/app/src/main/java/org/matrix/TEESimulator/interception/keystore/shim/KeyMintSecurityLevelInterceptor.kt) 复核：唯一 ID 权限被拒后会移除可选参数继续；针对旧 key ID 的未找到日志也可能进入原 HAL。不能只凭这两条日志宣称整个证明流程失败。此前的原生库缺失提示也出现在消息应用，后续有效请求未见 DroidGuardRunner 初始化失败，不能把它当作已确认的 GMS 根因。

### Google 拒绝原因的证据边界

最终请求正常完成并返回可读取的判定，但 `deviceRecognitionVerdict` 缺失，相关应用、账号字段为 `UNEVALUATED`；没有提供唯一的服务端拒绝原因码。[Google 判定文档](https://developer.android.com/google/play/integrity/verdicts) 将空设备判定关联到设备不可信、修改或不满足检查的模拟环境等情形，不能从空值区分其中哪项。Basic 也不等同于“只要证书链能验签”；本机为 Android 12，不能直接套用 Android 13 以上的额外标签条件。

本地已观察到残留的模拟器特征：`ro.kernel.qemu=1`、`ro.hardware=ranchu`、x86_64 ABI；实际 GMS unstable 进程加载 `libEGL_emulation` / `libGLES_emulation`。与此同时，PIF 将该进程的部分属性呈现为 Pixel 6a Canary。**设备环境一致性、模拟环境特征和其他运行时信号因此仍是候选方向，不是已证明的唯一根因。** 未 root 官方镜像先前同样失败，也说明不能仅归因于后来安装的 root 模块。

Claude 单独复测：官方 Play 版本 1.261113.19，选择已有测试 Google 账号后，17:11 再次显示无法经 Google Play 验证，未进入对话页。未使用网页版代替验收，也未放宽隔离规则。仍不能确定 Claude 要求的最低完整性等级。

### 本轮证据与状态

本节文件均在被忽略的本机目录 `mobile/.build/emulator-integrity-20261115/diagnosis/basic-cause/`：

- 各轮同名 `.json` / `.ui.json` / `-errors.txt`，以及 `log-comparison.json`：正式判定、界面与脱敏日志；受恢复模式干扰的首次匹配补丁结果单独保留。
- `spic-current.json`：第二检测器结果；`boot-properties-before.txt` / `boot-properties-test.txt`：临时属性对照。
- `signing-probe/first-run.json`、`second-run.json`、`host-independent-verification.json`：首次生成、持久复用与宿主独立验签。
- `dns/after.txt`、`final-components.txt`：DNS 恢复、网络验证及最终模块/版本状态。
- `claude-final.xml` 与相邻 `../avd/basic-claude-final.png`：Claude 实际拒绝；`../avd/basic-alwaysstrong-final-fixed.png`：最终三项失败。

原始日志、账号状态、代理配置和证明材料继续仅保存在本机，不整体上传。仍未通过原有全部隔离矩阵或原美国出口验收；仅 Windows 实测，未提交、推送、升级版本或发布。

收尾前补测：专用出口运行时，数字 IPv4 HTTP 返回 301、域名 HTTP 返回 204，全新随机域名的 UDP DNS 查询收到匹配请求 ID 的有效响应。停止身份核对后的专用代理后，两种 HTTP 均无应用响应；另一全新随机域名返回 DNS `SERVFAIL`、零答案。直接 ICMP 在两种状态下均失败。本轮仅验证这些请求，没有扩大为全部 UDP、IPv6、既有连接或 DNS 泄漏矩阵通过。证据为 `before-stop-network.json`、`after-stop-network.json` 及对应 HTTP 文本和 DNS 报文。

17:19 已完成正常关机后的清理：实验模拟器、专用网关、代理和独立 ADB 均退出，相关测试 TCP 监听为空，三条本轮临时防火墙规则已由原助手撤除。账号、应用、持久磁盘、诊断密钥和备份保留。临时启动属性已恢复；最终保留 AlwaysStrong + PIF 新指纹/补丁配置，新增 DNS 方案仍为实验脚本，未接入 Cage 或设置为开机服务。停止证据为本节目录的 `final-stopped-state.json`。现阶段结论是**已缩小和排除多项配置问题，尚未获得 Basic 通过或唯一根因，Claude 与完整隔离验收仍未通过**。
