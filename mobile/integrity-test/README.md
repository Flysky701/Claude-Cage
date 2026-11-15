# Flysky701 Play Integrity 测试应用

独立的 Android 测试应用，用自己的包名向 Google 请求 Play Integrity 令牌，再由电脑上的本地助手调用 Google 解码。支持标准请求和经典请求，分别显示应用识别、应用许可和设备完整性原始结果。

| 配置 | 值 |
| --- | --- |
| 应用包名 | `io.github.flysky701.integritytest` |
| Google Cloud 项目 | `flysky701-integrity-test` |
| Cloud 项目编号 | `650458347604` |
| Android 要求 | Android 8.0+ |
| Google 库 | `com.google.android.play:integrity:1.6.0` |

Cloud 项目已创建，Play Integrity API 已启用。应用在请求中使用项目编号关联该项目。当前未在 Google Play 管理中心登记或发布应用，也没有完成 Play 管理中心的项目关联；这与 APK 中设置项目编号是两个不同步骤。当前登录账号在 Play 管理中心显示的是开发者注册页。

2026-11-14 已在连接的 Android 真机安装并成功取得一次经典请求令牌，电脑端使用该项目的专用服务账号完成 Google 解码及包名、nonce、时间戳验证。返回 `MEETS_DEVICE_INTEGRITY`、`UNRECOGNIZED_VERSION`、`UNEVALUATED`。标准请求和手机上的 USB 解码按钮尚未联测；手机交由另一个正在进行的测试继续使用，本轮未继续操作其界面。

## 使用

1. 安装 `mobile/.build/integrity-test/Flysky701-Integrity-Test.apk`。保持设备上的 Google Play 服务、Play 商店和网络可用。
2. 打开应用，点“标准请求”或“经典请求”。每次点击只发起一次请求，不自动轮询或批量调用。
3. 成功取得令牌时，界面仍显示“待解码”；这不表示完整性通过。令牌保存在应用私有目录的 `request.json`，不会写入日志或复制到剪贴板。
4. 要读取判定，需为此 Cloud 项目配置专用服务账号 JSON 凭证，将凭证保留在电脑的 `mobile/.build/integrity-test/` 下，并运行本机解码助手。不要将服务账号 JSON 放入 APK 或提交到仓库。

解码助手依赖可安装到本项目的输出目录：

```powershell
python -m pip install --target mobile/.build/integrity-test/python -r mobile/integrity-test/requirements.txt
```

连接已启用 USB 调试的设备，在仓库根目录运行：

```powershell
./mobile/integrity-test/start-decoder.ps1 -Credentials <服务账号JSON路径> -Adb <adb.exe路径>
```

多台设备时再传 `-Serial <目标设备>`。助手仅监听电脑 `127.0.0.1:8787`，脚本通过 USB 转发该端口；结束时移除转发。启动后重新生成一个令牌，点应用中的“读取判定（USB 连接电脑）”。助手验证返回包名、请求绑定和十分钟内的时间戳，同一令牌重复点击读取时使用本进程已验证的结果，避免重复解码标准令牌。

经典请求的 nonce 按 Base64URL 解码后的字节进行比较，兼容 Google 返回补位符 `=` 的格式；标准请求的 `requestHash` 仍逐字匹配。校验失败时，原始 Google 响应保存为 `latest-google-response.json` 供排查，与已验证的 `latest-verdict.json` 区分。

也可用 `decode.py --credentials <JSON路径> --request <request.json路径>` 解码本应用私有目录导出的单个请求。最后一份真实判定保存在本机 `mobile/.build/integrity-test/latest-verdict.json`。

## 结果含义

- `appIntegrity.appRecognitionVerdict`：Google Play 是否识别本应用及签名。
- `accountDetails.appLicensingVerdict`：当前账号对本应用的 Play 许可状态。
- `deviceIntegrity.deviceRecognitionVerdict`：Google 返回的设备完整性标签；空数组保持显示为空，不当作通过。
- API 错误或网络错误单独显示，不能当作设备判定。

直接安装、未在 Play 发布的应用可能得到 `UNRECOGNIZED_VERSION`、`UNLICENSED` 或 `UNEVALUATED`。本应用的结果不能代替其他应用的服务端判定。本工具只用于手动诊断，不作为生产鉴权服务，也不修改任何完整性结果。

## 构建

### 恢复空间对照测试

`recovery/` 提供仅针对 `top.niunaijun.microrec` 的可选构建配置。它校验本应用的包名、版本及独立开发签名，将同一个原始 APK 加入恢复空间；不更换 microG、Play 商店、Google 账号或网关，也不改变请求包名、nonce、令牌或判定。默认的恢复空间构建不启用此配置，不能与 MGC 实验配置同时启用。

```powershell
python mobile/sandbox/blackbox-light/demo/build.py --jdk <JDK目录> --sdk <SDK目录> --mode test-copy --owned-integrity-test-apk mobile/.build/integrity-test/Flysky701-Integrity-Test.apk --output <新的恢复空间APK路径>
python mobile/integrity-test/recovery/build_probe.py --jdk <JDK目录> --sdk <SDK目录>
```

以原开发签名覆盖安装恢复副本后，主页增加“打开自有完整性测试”按钮，首次打开会将 APK 导入私有空间。临时助手 `Recovery-Probe.apk` 使用恢复副本的开发签名，仅用于自动发起一次经典请求并读取该应用的私有结果；测试后可卸载助手。

```powershell
python mobile/integrity-test/recovery/run_probe.py --adb <adb路径> --serial <目标设备> --credentials <电脑上的服务账号JSON> --name <本次记录名称>
```

`run_probe.py` 不安装程序；运行前需安装上述恢复空间和临时助手。它将请求及解码结果私下保存在 `mobile/.build/integrity-test/comparison/`，终端仅输出不含令牌的摘要。请求成功时会核对私有空间安装包与个人区对照包完全相同，并校验 Google 返回的包名、nonce 和时间戳。API 错误与已解码的设备判定分开记录。

### 测试应用本身

在本目录使用 JDK 17、Android SDK Platform 35、Gradle 8.7：

```powershell
./build.ps1 -Sdk <Android-SDK目录> -Jdk <JDK目录> -Gradle <gradle.bat路径>
```

可传 `-ReadOnlyGradleCache <已有Gradle缓存目录>` 复用依赖。脚本将缓存、临时文件和独立开发签名保留在 `mobile/.build/integrity-test/`，安装包使用仅供测试的开发签名。

参考：[Google 官方接入说明](https://developer.android.com/google/play/integrity/setup)、[标准请求和解码](https://developer.android.com/google/play/integrity/standard)、[直接安装应用的项目编号](https://developer.android.com/google/play/integrity/reference/com/google/android/play/core/integrity/IntegrityTokenRequest.Builder)、[判定字段](https://developer.android.com/google/play/integrity/verdicts)。
