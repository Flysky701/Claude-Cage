# MGC 本地连接实验

此构建把用户提供的 GBox 1.8.4.02 中的三个组件接入恢复版空间，先验证组件安装、服务路由与 Binder 接口。使用独立应用编号 `top.niunaijun.mgclab00`（Cage 验证 DEMO）和独立数据；原 DEMO、恢复 DEMO、账号与网关配置不迁移。

## 已实现

- 从本机 GBox APK 提取原始 `MGC.apk`、`MG-250952077.apk`、`gpstore400013.apk`；构建与导入时核对包名、版本和签名。原组件不重签名。
- 增加应用内的组件导入入口。已有不同版本或不同签名时停止，不覆盖其他 Google 套件。相同组件可重复执行，安装中断后可继续。
- 在当前来宾用户中，把 Claude 和自有连接探针的 Classic／Standard 请求转交私有 MGC。原版商店自身、其他用户、无关 Action 和外部显式组件不重定向。
- 保留已修复的调用身份查询，加入 MGC 和探针的真实虚拟 UID 映射，不把所有调用者冒充成商店。
- 两种协议分别保留原始请求与回调，适配已核对的同步 Binder 接口。日志只记录模式、错误码、令牌是否存在、预热结果是否存在与耗时，不记录凭证、账号、nonce、请求哈希或会话 ID。
- 实验包通过自己的宿主进程核对现有 VPN 与断网保护。宿主网络状态不经过来宾的网络显示适配；不修改系统 VPN 选择或出口配置。
- 增加私有连接探针。它通过普通 `bindService()` 调用两种 API 入口，检查实际连接包名和接口描述符；不请求完整性令牌。

当前没有自有 Play 测试应用与关联 Cloud 项目，用户已选择先完成本地组件与连接验证。报告中的示例 JSON 不作为真实解码结果。

## 本轮实际结果（2026-11-14）

| 检查 | 结果 |
| --- | --- |
| 三个原始组件与自有探针导入独立空间 | 通过，四个组件身份核对完成 |
| 宿主读取现有 VPN 与系统断网保护 | 通过：VPN、断网保护均开启，实验包未被排除 |
| 路由、Parcel 与 Binder 定向检查 | 59 项断言通过；使用模拟请求，没有请求 Google 令牌 |
| 第 03 版构建及安装 | 通过编译、签名及代码和资源回读校验；已安装到手机 |
| Classic 实际服务连接 | 通过，界面和日志均为 `connected_companion`，目标 MGC、接口匹配 |
| Standard 实际服务连接 | 通过，界面和日志均为 `connected_companion`，目标 MGC、接口匹配 |

第 03 版修复探针启动时未设置包名的问题。容器的启动页要求同时提供目标 Intent 和包名；此前只设置组件，启动页会直接退出。当前已按容器现有启动方式补齐包名、主入口 Action 和启动分类。

本轮交付为 `dist/Cage-Integrity-Lab-03.apk`，构建记录和本轮验证记录分别在同目录的 `.json`、`.validation.json` 文件中。连接探针通过普通来宾 `bindService()` 入口触发路由；界面结果与 `CageIntegrityProbe` 日志相符。本轮未调用令牌请求接口，未进行 Google 账号登录。

## 构建与运行

需要恢复说明中的原 APK、开发签名、Android SDK，以及本机 GBox 样本。当前构建使用 JDK 17 与 Build Tools 34.0.0。

```powershell
python mobile/sandbox/blackbox-light/demo/build.py `
  --jdk '<JDK 17 目录>' --sdk '<Android SDK 目录>' `
  --mode test-copy --integrity-lab-apk '<GBox 1.8.4.02 APK>' `
  --output '<新的实验包输出路径.apk>'
```

`--integrity-lab-apk` 仅用于独立实验构建。默认恢复包不包含这些集成修改，也不嵌入上述组件。构建输出路径已存在时保留原产物并停止。

安装生成的实验包后，打开“Cage 验证 DEMO”，点击“导入完整性实验组件”，再点击“检查 Classic / Standard 连接”。探针和 MGC、GMS、Play 均在这个新空间内安装。原网关需要处于运行状态，系统“始终开启”和“阻止未连接流量”保持开启。

实验组件及源 APK 仅在本机用于当前验证；构建不上传或发布它们。

## 定向检查

```powershell
python mobile/sandbox/blackbox-light/demo/integrity-lab/tests/run.py `
  --jdk '<JDK 17 目录>' --sdk '<Android SDK 目录>'
```

此检查在连接的 Android 设备上使用真实 Parcel／Binder 和模拟数据，验证路由边界、请求保留、同步传输、回调和错误原样返回。已通过 59 项断言，不需要账号、网络请求或付费服务。

恢复构建继续回读汇编后的指令和资源。跳转标签按实际指令位置比较，允许反汇编工具改名或合并标签；仍区分不同的分支目标、switch 目标与字符串。

## 验证边界

连接成功只证明请求到达指定私有服务，并且接口匹配。以下尚未完成：

- Google 账号授权、FDFE 请求、DroidGuard 实际执行与缓存恢复。
- Classic／Standard 令牌的 Google 后端解码，以及 Basic／Device／Strong、应用识别和许可判定。
- 目标应用服务端验收。
- 原报告中的 VLite Native 适配与 KeyStore 策略移植、云端代算配置。

新增容器代码没有把安装来源改成 Play，没有增加 Keybox、修改设备完整性判定或清空账号权限检查。第三方组件内部已有的策略需要另行运行验证。当前测试不配置云端代算，也不迁移真实账号。
