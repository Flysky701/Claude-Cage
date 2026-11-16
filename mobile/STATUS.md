# Android 开发状态

更新日期：2026-11-16（北京时间）。唯一长期开发分支：`codex/android`。

Android 远程客户端、Cage Open、GBox 定向修改和其他 Android 实验都在这条分支接续。
本文件统一记录当前结果、阻塞和下一步；各目录 README 保留构建方法，日期报告保留当时证据。
验证结论只属于对应产物、环境和读取路径，不能在不同路线之间沿用。

## 当前进展

| 路线 | 已完成或部分通过 | 未通过、未验证或暂停 |
| --- | --- | --- |
| Android 远程客户端 | 已合入上游 v0.1.8 同步记录，保留本地客户端的应用更新实现 | 本次仅整理分支与文档，没有新增客户端运行验证 |
| Cage Open `0.0.6-login-preview` | Android 16 真机 Google 测试账号登录及应用冷启动保留通过；原版商店下载并安装 Claude 的原签名分包通过；Google 登录结果回传已修复 | Claude `26111319` 仍返回 Play 验证失败、HTTP 400；尚未登录或发送消息 |
| Cross：GBox MG/MGC + BlackBox | 独立空间完成同款 MG/MGC、原版 Claude、DroidGuard 和 Google 凭据链路；关闭证明屏蔽、原生路径计数、撤销算法注册补齐及 maps 宿主路径处理均已实测 | 最新仍 1446 / HTTP 400；maps 处理确实命中但未改善登录，尚未定位具体拒绝信号 |
| Cage Open 隐私补丁 | 0.0.5 的 SIM、VPN 可见性、隧道元数据和东京时区在所测探针路径通过；0.0.6 保留策略代码，并观察到 Claude 进程内策略启用 | 0.0.6 未重跑整套探针；原生属性部分对照无有效读数；WebView 首脚本跨进程保证、断线保护、raw syscall/netlink、显式子进程环境仍未验证 |
| GBox 真机路线 | Checks02 保留原登录态与测试标记；SIM/VPN 及隧道元数据的所测路径通过；11-16 独立对照以同版 Claude 新登录成功 | Checks02 的 WebView 首脚本时区未通过；非隧道信息隔离部分完成；真机断线保护未验证。独立登录对照不替代 Checks02 的隐私验收 |
| MuMu / 官方 Android 模拟器 | 已保存诊断、失败对照和源码 | MuMu GBox 路线暂停；已测完整性组合及 Claude 登录未达标，不继续重试 |

## 当前阻塞与证据

- **优先继续容器及其 Google 服务集成。** 19:06 的独立 Cross 已换成 GBox 原版 MG/MGC，完成真实 Claude 登录请求，仍为 1443 字符 / HTTP 400。单独替换这组组件不足以修通；此前只完成组件安装、连接的 11-14 结果不再作为当前验证范围。
- **本样本配置没有选中 bit 2 证书重签分支。** 读取成功 GBox 的规则白名单，结合默认集合和唯一静态掩码写入路径，推导 GMS=1、Play=0、MGC=0。继续开源容器路线；不将静态存在的 keybox 分支当作本次成功所必需。掩码来自配置与源码推导，未读取成功请求当时的进程字段。
- **关闭证明屏蔽已在同款 MG 的 Cross 上重测。** 20:06–20:07 仅将该偏好改为 false 后冷启动，VM 输出为 38,085 字节（此前同款 MG 基线为 34,906），令牌仍 1443 / HTTP 400；原偏好缺省已恢复。这是本轮新实验，不沿用 0.0.4 的结果。单独关闭屏蔽不再作为修复候选。
- **三条数据路径重定向没有命中。** 20:09 的实际 Claude 请求中，原生 openat 计数在 15/30/45 秒为 190/192/196，映射计数均为 0。令牌为 1446 / HTTP 400；已记录其密文比关闭屏蔽那轮多 2 字节，但没有对应的路径修复或登录改善。停止扩展这三条路径，下一步只针对实际查询过的路径和操作。
- **撤销算法注册补齐也已结束。** 20:21 的同款 MG Cross 实测 Provider 和 KeyStore 实现均为 microG blocker，EC/RSA 服务均不存在，证明候选生效；VM 输出 33,502 字节，令牌 1446 / HTTP 400。单独撤销这项容器兼容处理没有修通登录；integration2 与原偏好均已恢复。
- **自有探针没有分出两边差异，已停止扩展。** 本轮 GBox/Cross 各一次预热、一次采样请求，解码均为 DEVICE 空、APP/许可 UNEVALUATED；这不是 Claude 的成功/失败对照。原生采样未覆盖冷启动，且 GBox 的 seccomp 事件不能直接当作最终文件返回值；不据此新增路径修复。后续冷启动采样、属性采集和采集器扩展均已停止。
- **21:12 的真实 Cross 登录仍为 1446 / HTTP 400。** 请求结束后读取错误对象得到 `missing_client_attestation`。原版客户端有凭据绑定的 Classic 证明分支，但本地单键设置未执行；不把该准备工作记作失败实验，也不继续扩展开关设置工具。该错误码仍未说明 Google 拒绝的具体判定。
- **未找到可直接使用的本机独立 DroidGuard 通道。** 同款 MG 的 Network 模式需要另一个兼容 HTTP 执行服务；现有仓库和构建缓存没有该服务，本轮不新增服务工程。
- **22:02 的 maps 最小对照确实生效，但未修通。** 在独立 Cross 的 GMS DroidGuard 进程中，3 次读取返回了处理后的 maps，共移除宿主安装 APK 路径 72 行、7272 字节，回退为 0。原版 Claude 仍为 1446 / HTTP 400，JWE 各段尺寸与 21:12 基线一致；VM 输出为 34,774 字节，不能据此声称 Google 判定改变。该候选结束，已恢复 integration2。
- **隐私验收仍未完成。** 本轮未扩大 SIM、VPN、WebView 时区及断线保护的通过范围。继续以[补丁验收范围](sandbox/gbox-mod/PRIVACY-REVIEW-2026-11-15.md#补丁验收范围)和上表的对应产物为准。

## 下一步

1. **本轮候选已结束，保留基线。** maps 对照完成一次真实 Claude 登录；不将这个无改善的诊断候选合入正式版本，也不继续追加路径隐藏变体。
2. 后续仍优先回答最初的具体问题：成功 GBox 的 DroidGuard 实际命中了哪个 KeyStore/Provider，与 Cross 的 blocker 调用有何差异。静态配置已不支持本样本选中 bit 2，但成功请求当时的实际调用链仍未取得；该问题不能用自有探针 DEVICE 判定或总长度替代。
3. 组件替换、配置对齐、单独关闭屏蔽、算法注册撤销、三路径映射和本次宿主 maps 路径处理均已有记录。只有新的具体差异才进入下一次修改，不重复上述候选。

手机交互统一由一个 GPT-6.1 Terra 操作员执行，其他并行任务只做本地源码、构建和结果分析。
手机全局网络设置限制和 MuMu 暂停状态继续有效；既有 GBox 会话及正式 Cage Open 数据保留。
本轮真实基线和 maps 对照均失败，最终已恢复 integration2 并核对安装身份；开关准备未改变应用数据。Claude 登录尚未修通。诊断候选未作为开源发布产物；未向飞书写入。

## 证据入口

- Cage Open：[构建说明](open-cage/README.md)、[最新定向对照](open-cage/BUNDLED-TESTING.md)、
  [登录记录](open-cage/validation-login-2026-11-16.json)、[成功路径对照](open-cage/validation-success-path-2026-11-16.json)、
  [0.0.5 隐私结果](open-cage/validation-privacy-2026-11-16.json)、[商店与完整性结果](open-cage/validation-store-2026-11-16.json)。
- 本轮交叉与根因筛选：[组件交叉及原生计数](open-cage/validation-cross-2026-11-16.json)、[分流配置及关闭屏蔽实验](open-cage/validation-keystore-2026-11-16.json)、[Provider 安装顺序](open-cage/validation-provider-order-2026-11-16.json)。
- 继续实验：[maps 最小对照](open-cage/validation-maps-2026-11-16.json)、[已结束的自有探针对照](open-cage/validation-native-queries-2026-11-16.json)、[真实错误及停止的开关准备](open-cage/validation-credential-attestation-2026-11-16.json)。
- GBox：[真机阶段记录](PHONE-GBOX-VALIDATION-2026-11-15.md)、[隐私风险与验收条件](sandbox/gbox-mod/PRIVACY-REVIEW-2026-11-15.md)。
- 历史：[11-15 GBox / MuMu 交接归档](HANDOFF-2026-11-15.md)、[模拟器对照](EMULATOR-VALIDATION-2026-11-15.md)、
  [11-14 microG 分析](ANDROID-ANALYSIS-2026-11-14.md)、[GBox 架构分析](GBOX-REA-ANALYSIS-2026-11-15.md)。

## 分支归并记录

2026-11-16 将以下旧分支汇入 `codex/android`，清理旧分支引用。对应提交均保留在主干历史中，可按提交恢复引用。

| 旧分支 | 归并前提交 |
| --- | --- |
| `codex/android-microg-checkpoint-20261114` | 远端 `448eab7`；本地上游同步后为 `633bc67` |
| `codex/gbox-privacy-review-20261115` | `448eab7`（与旧 microG 远端同一提交） |
| `codex/android-experiments-20261115` | `82c6786` |
| `codex/android-open-source-rebuild-20261115` | `d72a5fa` |
| `codex/android-adb-progress-20261116` | `4cf86e7` |
| `docs/gbox-rea-analysis-20261115` | `5f72f62` |

历史中的同名 checkpoint 来自变基前后保留的两套提交，旧历史已在 `2e83b7c` 合并。
本次直接归并现存历史，不重复应用这些补丁。后续日常进展直接提交到 `codex/android`，不再按日期或实验名新建 checkpoint 分支。
