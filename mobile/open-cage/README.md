# Cage Open Android：源码重建与集成测试包

本目录根据 `docs/gbox-rea-analysis-20261115` 的架构报告和
`codex/android-experiments-20261115` 的历史实验，建立**不输入 GBox APK、不恢复 GBox
DEX/原生库、也不依赖旧 BlackBox APK** 的独立构建入口。

这是第一阶段的容器源码构建实验，**不是已验证的 GBox 等价替代品**。
当前 `0.0.2-bundled-preview` 内置 microG Services、Companion 原包和独立测试 APK，首次
打开自动将缺少的组件安装到 Cage 来宾空间。已有组件保留，不覆盖数据。界面提供 microG
设置、Google 登录、测试应用及单 APK 导入入口。Google 登录、Claude 登录/对话、split APK、
网络断线保护、SIM/VPN/时区屏蔽均未完成本版本的真机验收。不能沿用旧版本的成功记录。

本轮已完成一次全新工作目录的完整构建、签名检查与服务路由用例，
详见[首轮验证记录](VALIDATION-2026-11-15.md)；集成版另见[集成测试说明](BUNDLED-TESTING.md)。

## 手机直接测试

安装 `Cage-Open-Bundled-Preview-0.0.2.apk`，可覆盖本项目先前提供的 `0.0.1` 调试包。
打开后等待“准备完成”，再依次运行内置测试、打开 microG 设置、添加 Google 测试账号。
内置组件离线解包；Google 联网与登录仍需要手机本身能访问对应服务。
失败时可点“复制准备记录”，重试不会清空已有来宾数据。

内置测试 APK 验证来宾启动、本地计数保存、包可见性、本地 WebView 和手动触发的 Google
HTTPS 请求。Companion 提供兼容服务，**不是完整 Play 商店**；本包不包含 Claude APK，
也未接入商店下载或 Claude 分包导入。因此可以直接测试容器与 microG，不能声称开箱即用 Claude。

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
| 可选硬件证明屏蔽 | `HardwareAttestationBlockingProvider.kt`、`DroidGuardPreferences.kt` | 已存在于上游；不从报告复制实现，也不替用户开启 |
| Play Integrity / Express 服务 | `vending-app/.../integrityservice/`、`expressintegrityservice/` | 使用上游实现开展后续兼容验证，不复制闭源 MGC |
| `ensureContainsLockBootloader` | `vending-app/.../IntegrityExtensions.kt` | 上游已有，不能视为 GBox 独占能力 |
| 虚拟包、账号、Binder、进程与文件路径 | BlackBoxReborn 的 `Bcore` | 从固定公开提交编译，先解决可复现构建 |

当前主线是“开源容器 + 上游 microG + 自有桥接与检查界面”。首要动态验证目标是
**真实服务绑定、UID/包归属、原始签名、Google 账号与 Claude 登录**，不是继续堆叠隐私 hook。
完整性凭证和服务端判定保持原样，不用伪造成功、替换其他应用 token 或伪造商店安装来源来验收。

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

成功输出 `Cage-Open-Bundled-Preview-0.0.2.apk` 和 `build-result.json`。
独立包名为 `io.github.flysky701.cage.open`，不会作为 `com.cage.android` 的覆盖更新。
调试签名仅供独立实验，不用于覆盖已有测试实例或迁移其账号。

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
8. 此阶段宿主只请求联网、网络状态、唤醒和前台服务权限。
   其他权限涉及的应用功能尚未适配；不以静默授权补齐。
9. 集成版移除上游三个演示性 Google/账号 hook 的注册；私有应用签名查询使用实际 APK，
   不借用手机个人区同包名应用的签名。尚未实现的两阶段账号会话明确返回不支持。
10. 自动准备直接访问来宾包管理服务；不把宿主的同包名应用误判为来宾已安装。

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

## 下一阶段的最小闭环

1. 在独立测试实例运行自有探针，验证安装、重启、数据和服务边界。
2. 验证已内置 microG 原包的账号添加与冷启动保留。
3. 补齐原签名 split 安装和新旧签名查询，完整记录安装来源。
4. 使用未修改的 Claude 原包验证登录；失败时按服务连接、调用身份和真实结果逐层定位。
5. 登录路径稳定后再接入网络策略、SIM/时区和独立 WebView renderer 实验。

当前云端没有连接用户手机。本轮不操作已有手机包、不改全局 VPN、不登录账号、不发送测试消息。
