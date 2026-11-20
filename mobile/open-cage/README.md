# Cage Open Android：源码重建与集成测试包

产品开发见 [Open Cage 分支状态](https://github.com/Flysky701/Claude-Cage/blob/codex/android-open-cage/mobile/STATUS.md)。对照实验与诊断记录见 [Android 研究分支](https://github.com/Flysky701/Claude-Cage/blob/codex/android-research/mobile/STATUS.md)。

本目录有两条构建入口，验证结果分开记录：

| 入口 | 用途 | 说明 |
| --- | --- | --- |
| `build.py` | `0.0.6-login-preview` 容器与组件集成实验 | 构建与手机测试说明见下文，后续实验由研究分支维护。 |
| 本机 `candidate.py` | `1.0.0-rc.3.9` 产品候选，版本码 `10011` | 使用保留的 RC2 基线构建。见[RC3.9 公开源码与兼容性补丁](releases/rc3.9/README.md)及[验收范围](../STATUS.md)。 |

下文保留 0.0.6 实验版的集成与手机测试记录。RC3.9 的验证结果单独记录在本分支的状态页。

本目录根据 [GBox 架构报告](../GBOX-REA-ANALYSIS-2026-11-15.md) 和
既有 Android 实验，建立**不输入 GBox APK、不恢复 GBox
DEX/原生库、也不依赖旧 BlackBox APK** 的独立构建入口。

这是第一阶段的容器源码构建实验，**不是已验证的 GBox 等价替代品**。
当前 `0.0.6-login-preview` 内置 microG Services、Companion 原包和独立测试 APK，首次
打开自动将缺少的组件安装到 Cage 来宾空间。已有 microG 组件保留；自有测试 APK 可更新，保留数据。界面提供 microG
设置、Google 登录、测试应用及单 APK 导入入口。已在 Android 16 真机完成 Google 测试账号
登录及应用冷启动保留检查。0.0.4 已通过原版 Play 商店下载并安装 Claude 的四个签名 APK，商店显示“已安装”和“打开”。完整性请求能取得并解码真实令牌，但未取得 DEVICE；系统对照返回 `MEETS_DEVICE_INTEGRITY`。用户随后要求先打屏蔽补丁：0.0.5 的 SIM、VPN 可见性和东京时区通过所测探针路径。0.0.6 使用用户提供的测试账号修通私有 Google 登录入口、PendingIntent 回传和 Android 14+ 结果格式；Claude 随后提示“此应用无法经 Google Play 验证”，对应 `/auth/verify_google_mobile` HTTP 400，**尚未登录成功**。不能仅凭该提示区分设备标签、应用识别和许可判定。WebView 首脚本时区仍无跨进程同步保证，网络断线保护未验证。

本轮已完成一次全新工作目录的完整构建、签名检查与服务路由用例，
详见[首轮验证记录](VALIDATION-2026-11-15.md)；集成版另见[集成测试说明](BUNDLED-TESTING.md)。

## 手机直接测试

安装 `Cage-Open-Bundled-Preview-0.0.6.apk`。本次在 Windows 本机签名，与此前云端
`0.0.1` / `0.0.2` 的调试签名不同，不能直接覆盖旧签名版本；真机修复时已先备份
独立测试实例的来宾数据，再重装并恢复。相同本机签名的后续构建可以覆盖更新。
打开后等待“准备完成”，再依次运行内置测试、打开 microG 设置、添加 Google 测试账号。
内置组件离线解包；Google 联网与登录仍需要手机本身能访问对应服务。
失败时可点“复制准备记录”，重试不会清空已有来宾数据。

内置测试 APK 验证来宾启动、本地计数保存、包与进程归属、原包签名、联网权限、本地 WebView 和手动触发的 Google
HTTPS 请求。Companion 提供兼容服务，**不是完整 Play 商店**；本包不包含 Claude APK，
已接入原版商店的 Claude 分包下载、原签名校验及私有安装；这条安装通道当前仅支持 Claude。完整商店不随包提供，已有完整商店在更新时保留，不能声称全新安装即可使用 Claude。

本次使用的报告版本：

- [GBox REA 架构分析](https://github.com/Flysky701/Claude-Cage/blob/5f72f6250cba74ff0f99f2a3332bee040a4734f0/mobile/GBOX-REA-ANALYSIS-2026-11-15.md)。
- [Android 实验与 microG 登录分析](https://github.com/Flysky701/Claude-Cage/blob/82c67862dcef2756b068ac8c4e10bbe28dd3d3cb/mobile/ANDROID-ANALYSIS-2026-11-14.md)。
- [GBox 手机验证记录](https://github.com/Flysky701/Claude-Cage/blob/82c67862dcef2756b068ac8c4e10bbe28dd3d3cb/mobile/PHONE-GBOX-VALIDATION-2026-11-15.md)。

## 为什么不用报告直接重写整个 GBox

报告提供了组件职责和静态调用线索，没有还原完整的 VLite 原生内核，也没有证明
“开源 microG + 任意容器”能满足 Claude 的服务端判定。
11 月 14 日的旧 microG 实验取得非空凭证后仍登录失败，不能因新架构报告而忽略这一反例。

对 microG 源码 `f686900c68aa84d1605b52304f6615f3593c6f50` 的直接检查还发现：

| 报告涉及的职责 | 开源上游已有入口 | 本次处理 |
|---|---|---|
| DroidGuard 服务及本地运行时 | `play-services-droidguard/core/` | 内置上游 microG 原包，不打包 GBox 定制 MG |
| 可选硬件证明屏蔽 | `HardwareAttestationBlockingProvider.kt`、`DroidGuardPreferences.kt` | 复用上游开关完成开/关对照，最后恢复默认屏蔽状态 |
| Play Integrity / Express 服务 | `vending-app/.../integrityservice/`、`expressintegrityservice/` | 原版商店与上游 Companion 均已实测经典和标准请求，两种环境都返回空设备标签；对照后恢复原版商店及数据，不复制闭源 MGC |
| `ensureContainsLockBootloader` | `vending-app/.../IntegrityExtensions.kt` | 上游已有，不能视为 GBox 独占能力 |
| 虚拟包、账号、Binder、进程与文件路径 | BlackBoxReborn 的 `Bcore` | 从固定公开提交编译，先解决可复现构建 |

当前主线是“开源容器 + 上游 microG + 自有桥接与检查界面”。首要动态验证目标是
**真实服务绑定、UID/包归属、原始签名、Google 账号与 Claude 登录**，不是继续堆叠隐私 hook。
完整性凭证和服务端判定保持原样，不用伪造成功、替换其他应用 token 或伪造商店安装来源来验收。

2026-11-16 按 REA 报告补做了上游 Companion 对照，并将其原始证书、私有安装路径和声明
共同约束的签名兼容接入现有实现。它修复组件兼容性，没有取得 Google 的设备通过判定。
独立硬件身份诊断还观察到：来宾申请的证明记录的是 Cage 宿主包名及签名；这不能单独证明
Google 空标签的根因，但说明查询层的虚拟 UID 并不改变系统签发证明中的应用身份。
诊断源码位于 `diagnostics/attestation/`，不随正式测试包内置，不用于伪造证明或判断完整性通过。

后续调用跟踪确认，上游的硬件证明阻断器确实启用，但替换 Provider 时遗漏算法注册，导致
DroidGuard 在密钥生成入口报 `NoSuchAlgorithmException`。已按开源 Provider 保留原算法的
方式补齐，范围仅为 Android 16 的来宾 microG DroidGuard 进程。修复后证书链读取明确被原
阻断器拒绝，经典和标准请求仍返回空设备标签。因此“普通探针取得宿主证明”不能直接解释
当前阻断模式下的 Google 判定；尚不能宣称修复了硬件身份或通过了设备完整性。

同日补做同手机、同网络、同测试 APK 的 GBox 对照：GBox 经典/标准请求也未返回 DEVICE，
而当前系统官方 GMS 仍返回 DEVICE。GBox 之前 Claude 登录成功不能作为完整性通过证据。
开源 Cage 的实际 VM 跟踪已确认初始化成功并输出 34,530 字节，未观察到错误回退；记录了
包信息、标识、文件和启动锁定查询，以及系统权限拒绝。具体文件路径和上传信号仍未确认。
该轮只新增独立诊断工具和测试记录；之后用户改为先打屏蔽补丁并实测 Claude，见本文开头的最新结果。
详细证据和局限见[同机对照记录](BUNDLED-TESTING.md)。

## 构建输入与输出

- Python 3.12+、Git、JDK 17、CMake 3.31、Ninja。
- Android SDK Platform 36、Build Tools 36.1.0、NDK 27.0.12077973。
- 容器公共源码版本固定在 [sources.lock.json](sources.lock.json)。microG 原包由
  [bundle.lock.json](bundle.lock.json) 单独锁定为 `v0.3.18.252432`，包含 URL、大小、SHA-256 和签名证书。
- 原生目标先限定 ARM64。`targetSdk=28` 沿用容器兼容限制，不能描述为现代 Android 权限模型已适配。

从本仓库根目录运行：

```sh
python3 mobile/open-cage/build.py \
  --sdk "$ANDROID_HOME" --jdk "$JAVA_HOME"
```

脚本克隆固定提交，在 `mobile/.build/open-cage/` 准备源码、编译 Dobby、生成空 DEX 资产、
编译独立测试 APK，核对并内置 microG 官方发布包，再编译容器和独立界面。
`--bundle-inputs` 可指定已下载的原包缓存目录；缺少时只从锁文件固定地址下载。
两个 microG APK 保留原始字节和签名，不将其重签或反编译重打包。
`--blackbox-source` / `--dobby-source` 可以复用本地 checkout，
但 HEAD 必须与锁文件相同；归档读取已提交内容，不读取本地未提交改动。
需要从中断处继续时使用 `--resume`；修改构建输入后应使用新的 `--work` 目录。
不删除已有工作目录、不自动安装、不发版。

成功输出 `Cage-Open-Bundled-Preview-0.0.6.apk` 和 `build-result.json`。
独立包名为 `io.github.flysky701.cage.open`，不会作为 `com.cage.android` 的覆盖更新。
调试签名仅供独立实验；覆盖更新要求新旧包签名一致。

受控代理环境中的 JVM 需要适当的 `GRADLE_OPTS` 与可信 CA；不要关闭 TLS 验证。
Gradle wrapper 固定 8.14.5，并核对官方分发 SHA-256。

## 本次实际变动

1. 使用自有 Java 首页，移除上游示例 UI 的三个二进制 AAR 及其 UI 依赖。
2. Dobby 从公开固定提交编译，不使用容器仓库附带的 `libdobby.a`。
3. 删除可选的旧 JUnit DEX 资产，从本次公开的 Java 源码生成空 DEX 资产。
4. 移除上游日志上传实现、默认接收方和启动时的 logcat 收集入口。
5. 移除上游 `IntegrityProxy` 的宿主 token 替换实验及其安装/服务连接入口。
6. Google 服务显式请求和已识别的隐式 action 只能在来宾空间解析；解析失败/绑定异常不回退个人区。
   这仅是该服务绑定入口的约束，不构成整个容器与个人区隔离已证明。
7. 复用本仓库已有 Android16 APK 解析补丁和 `GuestAuthenticatorTypes.java` 的
   按实际调用进程、空间和包可见性查询实现；没有复制恢复目录里的 Smali。
8. 此阶段宿主请求联网、网络状态、唤醒、前台服务和任务重排权限。
   其他权限涉及的应用功能尚未适配；不以静默授权补齐。
9. 集成版移除上游三个演示性 Google/账号 hook 的注册；私有应用签名查询使用实际 APK，不借用个人区同包名签名。0.0.4 仅对经过原始证书和声明校验的 microG 返回其声明的兼容签名；原 APK 不改写，其他包查询保持原签名。尚未实现的两阶段账号会话明确返回不支持。
10. 自动准备直接访问来宾包管理服务；不把宿主的同包名应用误判为来宾已安装。
11. `0.0.3` 修复包信息与进程列表仍返回宿主身份的问题；按已注册来宾返回 UID、包名和实际 APK 签名。
12. 适配 Android 16 的 `checkPermissionForDevice`，将当前来宾的 UID 映射给系统检查，
    同时要求来宾声明该权限。修复 WebView 被误判为没有联网权限的问题，不将权限检查统一改成允许。
13. 保留任务重排权限，使 microG 自检页面可以正常打开。
14. 复用现有私有安装器，补齐 Android 16 安装元数据和 ART 辅助文件处理，保存真实商店安装来源；无来源的导入应用返回未知，不伪装为商店安装。
15. 修复单向 Binder 的实际调用进程传递、账号可见性及原版商店服务通信；完整性请求和响应不改写。
16. 移除上游固定 Pixel 6 设备属性替换；对 Android 16 的 microG 原生服务调用使用具体 IBinder 方法，保留上游 dump 策略并修复标准请求的 JNI 崩溃。
17. 自有探针 1.5 检查私有 UID、原包/兼容签名、安装来源和启动查询；此次真机检查通过。

`--prepare-only` 可检查准备后的源码而不构建。新增的服务路由用例可用 JDK 直接运行：

```sh
mkdir -p mobile/.build/open-cage-tests
javac -d mobile/.build/open-cage-tests \
  mobile/open-cage/runtime/io/github/flysky701/cage/open/GuestServicePolicy.java \
  mobile/open-cage/tests/GuestServicePolicyTest.java
java -cp mobile/.build/open-cage-tests GuestServicePolicyTest
```

## 开源来源与发行边界

自有新增源码按本仓库 MIT 许可。BlackBoxReborn 的固定提交 `LICENSE` 内容为 Apache-2.0，
而 README 声称 GPL-3.0，存在明确冲突；在分发组合 APK 前应确认其声明及传递依赖。
本目录不把上游代码重新标为 MIT，也不宣称已完成完整许可证审计。
Dobby 保留其 Apache-2.0 许可。microG 原包与 Apache-2.0 许可、来源说明一起打入测试包。
没有上传 GBox、Google 官方商店/服务或 Claude APK、账号或签名私钥。

“不含 GBox 二进制”只是依赖来源边界，不等于已经达到安全沙箱或应用兼容目标。
本应用与来宾仍共用 Linux UID，不能宣称具备虚拟机级或系统工作资料级的对抗性隔离。

## 当前测试顺序与结果

1. Google 登录及商店搜索、下载、Claude 原签名分包安装已通过；商店“打开”入口已恢复。
2. 设备完整性链路已打通，但 Google 返回空标签；系统环境对照通过，Cage 环境未通过。包名、请求绑定及返回时间均经本地校验，未把令牌成功当作完整性通过。
3. 用户在 2026-11-16 改为先打 SIM/时区/VPN 补丁、亲自测试 Claude 登录。0.0.5 已接入并完成定向真机验证，未将屏蔽检查结果计作设备完整性通过。

详见[真机记录](BUNDLED-TESTING.md)、[0.0.5 屏蔽结果](validation-privacy-2026-11-16.json)及[此前商店与完整性结果](validation-store-2026-11-16.json)。此前商店下载临时切换的代理设置已恢复，本次没有修改手机网络。
