# Android 轻量空间分析记录（2026-11-14）

## 今日结论

已修复空间内的 Google 服务路由、调用方身份查询及 Claude 签名元数据。开启空间内 microG 的设备认证后，Claude 已多次取得真实 Play Integrity 凭证，最后一轮在 19:11:07 返回 `error=0、tokenPresent=true`，但仍显示“此应用无法经 Google Play 验证”，**Claude 登录和实际对话尚未通过**。

设备完整性判定、Claude 的应用识别判定和 Play 许可判定仍未知。取得凭证、Google 账号授权成功或 APK 官方签名匹配，都不能证明上述判定通过。本次未解码凭证，也未取得 Claude 服务端的具体拒绝代码，不能认定必须满足 Strong／“三绿”。

用户要求结束今日工作，已停止新的修复与登录重测。本文上传到现有实验分支；本轮新增修复源码和 APK 仍保留本机，本文不代表源码已全部上传或产品已经可用。

## 环境与数据边界

- Windows 构建，Android 16 arm64 真机测试；Claude 输入版本为 `1.261111.19 / 26111119`。
- 轻量空间：`top.niunaijun.microdem`；独立网关：`io.github.leexeo.cage.microdemo`。与原 microG 空间并存。
- 使用原有 Webshare 出口配置。网关覆盖当前 Android 用户的流量，要求“始终开启”和“阻止未连接流量”同时开启。
- 保留现有账号、来宾数据和个人区 Google 服务隔离；未清数据、重建账号、刷认证模块或迁移到其他资料空间。
- 原始 Google／Claude APK 不因兼容修复而改写；不生成或替换验证凭证，不伪造 Play 许可或安装来源。
- 本报告不含账号、密码、IP、代理凭据、nonce、token、设备序列号或原始日志。

## 已确认的阻塞与修复

| 环节 | 证据与处理 | 当前结论 |
| --- | --- | --- |
| Google 登录网页 | 原独立空间的网络限制未覆盖 WebView；轻量 DEMO 使用系统网关并适配已加载的登录页 | 空间内 Google 登录成功，账号保留 |
| 私有 Google 授权 | 凭据入口与结果容器按原类型、结果码和数据适配，阻止回退到个人区服务 | 授权可返回 Claude；不等于 Claude 已登录 |
| Integrity 服务绑定 | 基础壳把验证服务送向真实系统，遭个人区隔离检查拒绝 | 改为空间内 Play 服务后，连接与回调通过 |
| `-7 / APP_UID_MISMATCH` | 空间安装记录正确，但 UID 归属接口没有接入；单向 Binder 请求又无法提供调用 PID | 补齐双向查询；按实际进程记录映射，未知身份不冒充接收方；只调整指定请求的传输方式以保留调用 PID。原请求和回调内容保留，`-7` 已消失 |
| 随后的 `-17` | 日志及设置页显示空间内 microG 设备认证关闭 | 开启后取得非空凭证；不能据此推定设备判定通过 |
| 商店设置页 | 跨资料查询的系统包名检查导致崩溃 | 只报告此空间支持的资料范围，不访问个人区／工作资料；菜单和设置可打开 |
| 新版签名接口 | 旧版接口有官方签名，新版接口返回空签名 | 从实际原始 APK 读取并核对版本、证书及签名历史；新旧接口均有 1 个匹配签名 |
| 安装来源接口 | 基础壳旧接口一律返回 Play，新接口报未安装 | 两种接口现在如实返回“由空间导入”；这不构成 Play 许可 |
| 商店下载安装 | 页面曾停留“等待中”；私有安装会话尚未实现 | 商店可浏览，尚不支持完整的商店安装流程 |

Google 对 `-7` 的定义是调用方 UID 与安装记录不一致，见[官方错误说明](https://developer.android.com/google/play/integrity/reference/com/google/android/play/core/integrity/model/IntegrityErrorCode#APP_UID_MISMATCH)。

## 最后几轮结果

以下时间均为 UTC+8；事件只保存固定标签、数字错误码和布尔值。

| 时间 | 实际结果 |
| --- | --- |
| 18:04 | 连接私有 Play 服务，但返回 `-7`，无凭证 |
| 18:42–18:44 | 身份与通信修复后，回调由 `-7` 变为 `-17` |
| 18:47 | 开启 microG 设备认证后，首次观察到 `error=0、tokenPresent=true`；Claude 仍拒绝登录 |
| 18:58 | 缓存就绪后约 4.8 秒取得凭证；Claude 仍拒绝登录，不能仅以首次请求较慢解释问题 |
| 19:08 | 新旧签名查询均匹配官方 APK；取得凭证后仍失败 |
| 19:11 | 新旧安装来源均为真实的空间导入；19:11:07.728 取得凭证，19:11:08.576 私有 Google 授权返回；Claude 仍显示验证失败 |

本轮相关脱敏证据留在本机 `mobile/.build/light-demo/`：`identity-microg-enabled.json`、`integrity-warm-cache.json`、`integrity-signatures-fixed.json`、`integrity-provenance-fixed.json`。没有上传原始日志或凭证。

## 已排除与仍未知的事项

- **不是仅限 Wi-Fi 下载设置。** 修复商店菜单后，下载偏好显示“通过任何网络”；手机当时使用蜂窝网络。但商店等待的完整原因尚未查清。
- **不能把本轮身份错误归给 microG。** `-7` 已定位在空间兼容层；microG 设备认证关闭是后续另一处阻塞。
- **不能把本轮最终失败归给签名。** 新旧签名接口现已与真实官方 APK 一致，重测仍失败。
- **不能宣称 Play 许可或设备完整性通过。** `appRecognitionVerdict`、`appLicensingVerdict`、`deviceRecognitionVerdict` 是分别判定的；本机尚未读取这些结果。参见[Google 完整性结果说明](https://developer.android.com/google/play/integrity/verdicts)。
- **没有 Claude 服务端的具体拒绝证据。** 当前只有凭证回调、授权回传和界面错误，未确认具体 HTTP 状态、后端错误代码或使用哪项判定拒绝。
- 个别复测出现过 Android／原生进程崩溃，长期稳定性未通过。网关恢复后此前的出口与断网检查通过，不能扩展为长期稳定保证。

## 数据保留与验证范围

此前已在两个独立、无真实账号的测试空间验证：篡改 APK 拒绝、升级失败回滚、进程中断恢复、正常升级、同签名覆盖重装，以及明确使用 `pm uninstall -k` 后恢复。测试覆盖 CE/DE 文件、目录权限、setgid/sticky、所属组与所有者；实际 DEMO 升级后 Google 账号仍可见，授权继续返回。备份和测试现场保留。

普通 Android 卸载会删除应用私有数据，不能将保留数据卸载的测试结果推广到普通卸载。未删除原空间、个人区或备份。

本轮只实际执行 Windows 构建和这台 Android 真机验证。macOS／Linux 构建未实测，桌面三平台运行时代码未修改。未升级 Cage 版本、创建发布标签或发版。

## 收尾状态（19:17 核对）

- 已保留数据覆盖安装关闭临时诊断的正常包 `Cage-Light-Space-Identity-Fix.apk`，大小 4,072,359 字节。
- 已安装文件与本地 SHA-256 一致：`7052ffded2a9bf00358b752528db40f0e5acc62e1b1f43f35cbb050053336e69`。
- 原网关包未改变，已安装文件与本地 SHA-256 一致：`dc61db581a3b9da26726eb63e233ce493e9ea165ba8460efa28e449766c16ad3`。
- 正常包未插入临时 Integrity 连接观察器；返回手机主屏幕，停止新的登录重试。
- 网关仍运行；“始终开启”和“阻止未连接流量”仍开启；USB 屏幕常亮为原值 `0`。
- 本次收尾仅核对安装身份及保护状态，没有重测出口或登录。最后一次登录结论仍是失败。
- 本机核对文件：`mobile/.build/light-demo/end-of-day-verification.json`。

## 下次继续时的顺序

1. 先读取空间内 Play 商店的设备检查：设置 → 关于 → 连续点商店版本 7 次 → 常规 → 开发者选项 → Play Integrity → 检查完整性。该流程是 [Google 官方检查方法](https://developer.android.com/google/play/integrity/additional-tools#check-device)。今天因结束工作尚未执行，不能把“未测”写成“未通过”。
2. 独立确认 Claude 的真实 Play 安装与账号许可证据。当前没有私有安装会话，不能用安装来源字符串或其他应用的设备检查结果代替 Claude 的许可判定。
3. 依据新证据决定后续修改；保留已经完成的身份和签名修复，避免没有新证据时反复修改这些接口。
4. 如考虑原生私密空间／工作资料与官方 Google 服务对照，另行确定方案，并重新核实该资料空间的 Webshare 出口及断网保护；不直接迁移现有账号或替换个人区服务。

本机待保留的修复主要位于 `mobile/sandbox/blackbox-light/demo/`（身份、通信、签名、安装来源、跨资料与升级），以及 `mobile/sandbox/light-gateway/`。源码仍未随本次分析报告提交；继续开发应使用当前保留的工作区。
