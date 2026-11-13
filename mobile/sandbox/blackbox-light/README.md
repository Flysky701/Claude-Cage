# BlackBox 轻量测试壳

### 没有 Google 账号时发现验证服务（2026-11-13）

BlackBoxReborn 2.1.0 的 `getAuthenticatorTypes()` 从已有账号反查服务，首次添加账号之前会返回空列表。实验壳改为按实际调用进程与虚拟用户查询空间里已注册的验证服务，然后按调用应用的包可见范围返回类型。这个只读接口只返回验证服务的描述。账号添加和服务绑定继续遵循 Android 的权限检查。

在同一台 Android 16 arm64 手机上运行了两个目标版本相同的测试 APK。两者都只输出数字，各自能看到的 Google 账号数均为 0。

| 空间和调用应用 | 修复前发现的 Google 验证服务数 | 修复后 |
| --- | --- | --- |
| 已导入独立 Google 套件，应用声明查询 Play 服务包 | 0 | 1 |
| 同一空间，应用未声明查询 | 0 | 0 |
| 同一轻量壳内的临时空间，没有安装 Google 套件，应用声明查询 Play 服务包 | 未测 | 0 |

修复后从实验版打开原版 Play 商店，再次点击「Sign in」，系统仍在验证服务处理添加账号请求时拒绝 `ACCOUNT_MANAGER` 权限，未进入账号输入页。服务发现修正未解决商店登录。以上对照只覆盖表中的包可见性场景。[Android 16 的服务发现实现](https://android.googlesource.com/platform/frameworks/base/+/android-16.0.0_r1/services/core/java/com/android/server/accounts/AccountManagerService.java#1714)

### Google 账号选择器的设备策略查询（2026-11-13）

在同一轻量空间的前台用 Google Play 服务的 `AccountPicker` 请求选择 `com.google` 账号。修复前，空间里的 Play 服务查询设备禁用管理的账号类型时向 Android 提交了来宾包名。系统发现该包名与实际调用进程不符，选择器随即崩溃。现在空间用自己的包名转发这一次只读查询，查询的用户、个人资料范围以及返回的策略仍由 Android 决定。[Google 账号选择器](https://developers.google.com/android/reference/com/google/android/gms/common/AccountPicker) · [Android 设备策略查询](https://developer.android.com/reference/android/app/admin/DevicePolicyManager#getAccountTypesWithManagementDisabled())

修复后，真机在空间内显示了 Google 的「Add account」。选中该项并点「OK」后，Android 在 `IAccountAuthenticator.Stub.addAccount_enforcePermission` 拒绝了 `android.permission.ACCOUNT_MANAGER`，选择器仍停在原页。原版商店的登录按钮和官方选择器都在添加账号时遇到同一权限检查。真机未出现可输入邮箱或电话号码的页面。验证用的选择器按钮仅存在于临时测试包。[Android 账号验证服务权限](https://developer.android.com/reference/android/Manifest.permission#ACCOUNT_MANAGER)

### 分两步添加账号的请求去了哪里（2026-11-13）

Android 的 `startAddAccountSession` 由指定账号类型的验证服务处理。`finishSession` 确认并保存账号。Android 16 的系统账号服务根据调用方所属的 Android 用户查找验证服务。普通应用不能在这两个公开调用中指定某个容器内的 APK。[Android 账号接口](https://developer.android.com/reference/android/accounts/AccountManager) · [Android 16 的验证服务选择](https://android.googlesource.com/platform/frameworks/base/+/android-16.0.0_r1/services/core/java/com/android/server/accounts/AccountManagerService.java#5444)

在原轻量空间导入了一个临时测试应用。它声明自己的验证服务和独有的测试账号类型，不创建账号。修复前，测试应用在空间内能发现该类型，发起会话后手机个人区的系统账号服务记录了该类型并返回绑定失败。修复后，开始添加、开始更新和结束会话均由空间返回“不支持”，请求不再转给个人区。测试应用使用的会话数据均为模拟数据。[Android 16 账号验证接口的权限](https://android.googlesource.com/platform/frameworks/base/+/android-16.0.0_r1/core/java/android/accounts/IAccountAuthenticator.aidl#110)

在这台 Android 16 手机上，空间也会把已确认的 Google 验证服务权限限制直接返回给普通添加请求。更新后从原版 Play 商店点「Sign in」，商店收到请求失败的回执，仍然显示「Sign in」。未出现邮箱或手机号输入框，未添加 Google 账号。

#### 手机安装包与系统授权核对

实测手机里的空间 APK、本地构建产物和分发 ZIP 中的空间 APK 字节完全一致。该版本沿用上游的旧权限查询处理，两个 DEX 中均未发现 `checkPermissionForDevice` 方法名。Android 16 的通用权限查询确实使用这一新入口。旧版拒绝日志能定位到账号验证接口的权限检查，但没有记录其底层经过哪次通用权限查询。[Android 16 通用权限查询](https://android.googlesource.com/platform/frameworks/base/+/android-16.0.0_r1/core/java/android/permission/PermissionManager.java#1734)

手机的系统包管理器把 `ACCOUNT_MANAGER` 列在空间壳的申请清单中，授权记录中没有此项。Android 16 将它定义为签名权限。当前 Android 用户的系统服务查询能找到个人区 Play 服务注册的 Google 账号验证器；以空间壳包名查询时返回零项。这条结果只描述系统注册表，空间内部的服务发现结果见上表。本轮仅做只读核对，未产生新的登录尝试。[Android 16 权限定义](https://android.googlesource.com/platform/frameworks/base/+/android-16.0.0_r1/core/res/AndroidManifest.xml#2696)

#### 当前版本实际收到添加请求的进程（2026-11-13）

在同一台 Android 16 真机的原轻量空间内，使用临时诊断包记录 Cage 收到请求、返回错误和进入正常转发这三个位置。对现有的权限自查做了一段 Android 方法跟踪，读取该次调用的进入和退出记录。进程归属按 Android 实际包 UID 核对。跟踪未记录账号、凭据或请求参数。

| 触发动作 | 发起方 | 接收方与结果 |
| --- | --- | --- |
| 打开 Google 官方账号选择器 | 空间内的 Google Play 服务自动发起添加。这次在手动确认前已返回 | Cage 账号服务收到请求，自查权限被拒，返回“不支持”。正常转发记录为 0 |
| 在空间内的原版 Play 商店手动点「Sign in」 | 空间内的 Play 商店 | Cage 账号服务收到请求，自查权限被拒，返回“不支持”。正常转发记录为 0，商店仍显示「Sign in」 |

两次记录都在 Cage 权限自查的调用线程上捕获到 `ContextImpl.checkSelfPermission → PermissionManager.checkPermissionUncached → IActivityManager$Stub$Proxy.checkPermissionForDevice`，每次各一次（中间方法已省略）。这两笔请求均在调用 Google 账号验证器前返回。该结果仅适用于当前版本；旧版曾出现的验证器端权限异常没有对应的方法跟踪。[本次筛选后的真机日志](../../.build/space-check/account-routing/route-evidence.json)

### 来宾主进程的域名 HTTPS（2026-11-13）

在未 Root、使用蜂窝网络的 Android 16 真机上，原版「Cage 持续进程」测试应用通过系统的 `HttpsURLConnection` 查询检测域名。旧壳在部分冷启动中返回 `SecurityException`。用同签名调试壳和标准 Java 调试器捕获到原应用的异常栈：

```text
SecurityException: Permission denied (missing INTERNET permission?)
Inet6AddressImpl.lookupHostByName → InetAddress.getAllByName
→ okhttp.Dns.lookup → RouteSelector.resetNextInetSocketAddress
→ RouteSelector.nextProxy → HttpURLConnectionImpl.getResponseCode
→ NetActivity.sample
```

异常时，OkHttp 和进程实际持有的选择器均为 `sun.net.spi.DefaultProxySelector`，和壳启动时设置的选择器不同；没有捕获改变该选择器的调用栈。另一次记录先收到测试站的 CONNECT 确认，约 6.5 秒后也报同一类权限错误。Android 的[代理配置更新](https://android.googlesource.com/platform/frameworks/base/+/android16-release/core/java/android/net/Proxy.java)可以恢复系统选择器，[OkHttp 的路由选择](https://android.googlesource.com/platform/external/okhttp/+/android16-release/okhttp/src/main/java/com/squareup/okhttp/internal/http/RouteSelector.java)会为隐式代理追加直连候选。由此可以解释异常为何表现为系统域名查询被拒；第一条受控连接的底层 I/O 失败原因仍可能因请求而异。

测试壳通过 Java URL 协议扩展将两个诊断来宾的允许列表 HTTPS 请求交给平台原有的 HTTPS 处理器，并显式传入壳的本地代理。目标 APK 的 TLS 校验、超时、请求选项及系统 curl 保持原状，来宾继续没有 INTERNET 权限。仅设置标准 Java 代理属性并在启动后重设选择器的中间版本，三次冷启动仍有一次相同异常。最终方案实测结果如下。

| 对照 | 结果 |
| --- | --- |
| 三次冷启原版持续探针 | 主进程域名 HTTPS 3/3 与代理同期出口相同；同轮主进程数字地址 3/3 成功 |
| 第四次冷启后只停本地核心 | 主进程域名在线成功，停机后为 IOException。该轮主进程在线固定地址出现一次 IOException。核心停止期间手机蜂窝仍能访问同一 IP |
| 同一系统 curl 子进程，跨越停机与恢复 | 按原程序的域名／指定地址顺序共六次，新连接的退出码为 0、0、97、97、97、0。最后一次指定地址请求在核心恢复后再次返回代理出口 |

范围仅为所测 Java 标准 URL API、固定检测站和新建 IPv4 HTTPS，不覆盖其他 App 自带网络栈或所有上游超时。测试完已恢复原壳和助手并清除临时节点配置。[原始异常栈](../../.build/domain-debug/route-stack.txt) · [三次冷启动结果](../../.build/domain-debug/domain-cold-fixed.txt) · [停机恢复记录](../../.build/domain-debug/domain-fault-fixed.txt)
