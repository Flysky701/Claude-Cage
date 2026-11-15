# Android DEMO 代码恢复（2026-11-14）

本目录用于在原始源码无法取回时，继续维护手机上已经验证过的轻量 DEMO。恢复输入是从手机读取的两个 APK，内容与 `mobile/ANDROID-ANALYSIS-2026-11-14.md` 记录的文件摘要一致。

**这是从 DEX 恢复的可汇编 Smali 代码，不是找回了原始 Java、构建脚本或签名私钥。** 不把这次恢复称为原源码的完整还原。

## 已恢复的范围

- `../blackbox-light/demo/`：123 个源文件，包括 18 个主 DEX 兼容层文件和两个附加 DEX 的 105 个文件。覆盖账号隔离、Google 服务路由、调用身份、签名读取、导入来源、跨资料限制、登录页面和应用升级逻辑。
- `../light-gateway/`：20 个源文件，覆盖 VPN 生命周期、连接配置、隧道启动、状态查询和界面。
- `rebuild.py`：从指定的原 APK 取得基础代码、原生库和资源，再覆盖上述可编辑文件；重新汇编所有 DEX、核对汇编后的代码和未修改资源，最后打包。
- 其他基础框架类、原生库、资源和 assets 仍来自原 APK。未恢复原生库的新版 C/C++ 源码。空间中两个原生库与本机旧版的对应库相同。

恢复没有改动 Google 或 Claude APK，没有新增设备判定、许可或安装来源的伪造逻辑。恢复版仍只运行其 Google/Claude 应用。初次恢复时商店安装会话尚未实现；后续已补齐 Claude 完整安装会话，并完成成功与失败路径的真机验证，详见文末。

## 构建

在仓库根目录运行。需要 Python 3、JDK 17、Android SDK Build Tools、项目已有的 `mobile/.build/blackbox-source/apktool.jar`（本次为 3.0.3）。两个输入 APK 的路径和 SHA-256 写在各模块的 `recovery.json` 中，默认位于 `mobile/.build/report-resume/`。输入位于其他目录时传 `--input`。

```powershell
python mobile/sandbox/blackbox-light/demo/build.py --jdk '<JDK目录>' --sdk '<Android SDK目录>' --mode test-copy
python mobile/sandbox/light-gateway/build.py --jdk '<JDK目录>' --sdk '<Android SDK目录>' --mode test-copy
```

`--build-tools` 可指定版本或完整目录。默认使用 34.0.0。`--apktool`、`--output` 可指定其他文件位置。输出已存在时停止，不覆盖之前的产物。

- 默认 `--mode unsigned`：保留原应用编号，生成未签名 APK，仅供分析或取得原密钥后签名。
- `--mode test-copy`：生成签名后的并存测试包。空间为 `top.niunaijun.microrec`，网关为 `io.github.leexeo.cage.microtest`，名称分别为“Cage 恢复 DEMO”和“Cage 恢复网关”。默认引用对应副本；最新空间也可使用系统当前已选择且开启断网保护的网关。它们不会读取原 DEMO 的私有账号或代理配置。
- 测试副本默认沿用本机已有的 `mobile/.build/sandbox/development.p12`。可用 `--keystore` 指定其他开发密钥，并通过 `CAGE_RECOVERY_KEYSTORE_PASSWORD` 环境变量传入口令。
- 不自动安装 APK，不修改系统 VPN 设置，不迁移账号或复制网关凭据。

本机受限执行环境会使 `zipalign.exe` 以访问异常退出；正常本机环境运行成功。这是打包工具的执行限制，不能据此修改 APK 网络或账号逻辑。

## 校验边界

每次构建将新 DEX 再次反汇编，与本次编译输入的类内容逐个比较，并确认原生库和其他资源保持相同。测试副本只额外修改应用编号、相互引用的编号与界面名称。构建结果旁的 JSON 记录通过的检查和源文件数量。

这些检查证明代码成功重建，不等同于 Google 登录、Claude 登录、完整性判定或商店安装通过。真机结论应另行记录。

初次恢复验证时，两个并存测试 APK 已构建、签名，并在原 Android 16 手机上安装和启动成功。空间的 4,291 个类、网关的 20 个类全部通过回读核对；分别保留了 1,021 项和 5 项资源及原生库条目。当时新空间显示组件待导入，新网关显示尚未保存出口。没有把原空间账号或网关配置复制到副本，也没有启动恢复网关。当时手机已返回原 DEMO，原网关的始终开启与断网保护保持开启，尚未重测 Claude 登录或停网关断流。后续安装与登录结果见文末。

原手机版两个 APK 的签名证书相同，但与本机两个项目开发密钥及 Android 默认调试密钥均不匹配。原签名私钥不能从 APK 的公开证书中恢复。因此不得卸载原 DEMO 来安装恢复包；原空间与账号继续保留，后续修改先使用独立测试副本。

## 当前推进依据

2026-11-14 的 Play 商店内置检查：同一手机和网关下，个人区返回 `MEETS_BASIC_INTEGRITY`、`MEETS_DEVICE_INTEGRITY`、`MEETS_STRONG_INTEGRITY`，空间内返回 `Labels: []`。原始账号、验证令牌和 TestId 未写入本目录。

这把下一步定位重点收窄到空间与 microG 的认证环境，但没有取得 Claude 服务端的具体判定。不能据此认定 Claude 要求 Strong，也不能用商店设备检查代替 Claude 的安装许可。方法与解释见 [Google 官方检查流程](https://developer.android.com/google/play/integrity/additional-tools#check-device)和[判定字段说明](https://developer.android.com/google/play/integrity/verdicts)。

初次恢复代码中的 `GuestInstaller` 是未实现占位。后续已由新增 Java 实现覆盖：实际写入原版分包、私有安装和成功回执通过；实际 Play 会话创建也通过。商店下载仍卡在后台任务分发，已使用现成原版分包完成安装；Claude 的 Google 和邮件登录均被 Play 验证拦截。详见 [验证记录](play-installer-validation.json) 和 [当前模块说明](../blackbox-light/demo/README.md)。

独立测试包使用与恢复副本相同的开发证书，仅针对 `top.niunaijun.microrec`：

```powershell
python mobile/sandbox/recovery/tests/build.py --jdk '<JDK目录>' --sdk '<Android SDK目录>'
adb install --no-incremental -r dist/Cage-Installer-Test.apk
adb shell am instrument -w io.github.leexeo.cage.installertest/io.github.leexeo.cage.test.InstallerSmoke
```

`InstallerSmoke` 测试临时会话和无效 APK 的失败回执。`--claude-bundle <原版分包>` 可打包 `ExistingClaudeInstall` 的输入，该测试会真实安装 Claude 到恢复空间，来源记为空间导入。`--report-store-apk <38.4.22 APK>` 仅用于 `ReportStoreSetup`：在原签名与版本检查后，备份恢复空间中新导入的 45.7.17 测试商店及数据，再换用报告版本；不会处理其他版本或原空间。测试工具不应打入正常空间应用。
