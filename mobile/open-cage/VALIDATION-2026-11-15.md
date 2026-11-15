# Cage Open 源码重建验证：2026-11-15

这是云端源码构建记录，**不是 Android 真机验收报告**。
基线为 Android 实验分支 `82c67862dcef2756b068ac8c4e10bbe28dd3d3cb`，
架构参考为报告分支 `5f72f6250cba74ff0f99f2a3332bee040a4734f0`。

## 实际执行

| 检查 | 结果 | 边界 |
|---|---|---|
| 新目录准备固定提交源码 | 通过 | 用 `git archive` 读取公开源码提交；未使用 GBox、旧 BlackBox APK 或恢复的 Smali |
| Dobby ARM64 静态库构建 | 通过，57 个构建步骤 | 固定 `b0176de574104726bb68dff3b77ee666300fc338`；不链接容器附带的预编译静态库 |
| Java/Kotlin 与容器 JNI 构建 | 通过 | `:app:assembleDebug`，64 项任务执行，最终轮次 46 秒；工具和依赖缓存已存在 |
| Google 服务目标分类 | 10 / 10 通过 | 覆盖显式包、隐式 action、相似包名、普通系统服务；仅为策略单元用例，不验证 Binder 动态路径 |
| Python 构建脚本语法 | 通过 | `python3 -m py_compile` |
| APK 签名校验 | 通过 | `apksigner verify --verbose`，v2 调试签名 |
| APK 包信息与权限 | 通过 | 独立包名；仅联网、网络状态、唤醒、前台服务权限 |
| 移除组件产物检查 | 未检出目标标记 | DEX/SO 中无上游日志上传域名、`LogSender` 与 `IntegrityProxy` 类标记；不是完整安全审计 |
| 手机安装、启动、导入应用 | 未执行 | 当前环境没有连接手机 |
| Google / Claude 登录、重启后保留会话、对话 | 未执行 | 尚未集成并验证 microG 与目标应用 |
| SIM、VPN 标志、时区、网络故障关闭 | 未执行 | 本版未接入历史隐私实验，不继承旧版本结论 |

## 本轮产物

- 文件名：`Cage-Open-Source-Preview.apk`，8,189,047 字节。
- 包名：`io.github.flysky701.cage.open`。
- 版本：`0.0.1-source-preview`，版本号 `1`。
- ABI：仅 `arm64-v8a`；原生文件为 `libblackbox.so`。
- minSdk / targetSdk：`28 / 28`，compileSdk：`36`。
- SHA-256：`28eaeab080a88432365067195e465b3f83c5a5880a98881576d2c8d85ad16591`。

该哈希标识本轮本地调试构建。不同机器的调试签名、时间戳和工具状态会影响 APK 字节，
目前没有声称实现逐字节可复现构建。APK 和调试密钥未提交到 Git，也未创建公开发行版。

## 构建中处理的问题

- Dobby 最新源码在本轮 NDK 环境中出现 Android 汇编及平台结构编译错误，
  改用已验证可编译的公开固定提交；不继续沿用不明来源预编译库。
- 独立工程明确声明插件仓库、依赖仓库和工具版本，替换原演示 App 的二进制 UI 依赖。
- 受控代理环境下为 Gradle JVM 配置代理及系统可信 CA，保留 TLS 校验。
- 由本仓库 Java 源码生成空 DEX 资产，移除不需要的旧 JUnit 资产。

后续阻塞仍是设备侧动态兼容与登录，不是 APK 能否生成。Google 服务路由、账号发现与
原始应用签名必须在同一候选包上共同验证，取得非空完整性凭证不能单独认定 Claude 可登录。
上游容器的 LICENSE 与 README 许可声明冲突仍需核实，见主说明的发行边界。
