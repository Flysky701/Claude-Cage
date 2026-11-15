# 隐私探针记录与比较

普通模式测量本地状态，不主动联网；Cage 启动检查模式才调用固定 HTTPS 出口服务。网络元数据只保存数量、类别和布尔值，不保存 IP、MAC、DNS 地址、代理端点或域名。新增元数据字段版本为 `networkMetadataVersion: 1`，不升级应用版本。

报告始终原子写入来宾自己的私有文件。普通模式还输出 `REPORT2` 分段日志：每段最多 1800 字节，经 Base64 编码，结束记录含 SHA-256。启动检查模式不输出报告日志。旧逐字段日志的扩展 `network` 段可能被 Android 截断，不应继续用旧 `lab.py probe` 采集新报告。

在指定设备的探针完成读取后，使用本轮开始前的手机时间采集，只保存解析后的完整报告：

```powershell
python mobile/sandbox/gbox-mod/probe/capture_report.py --adb <adb路径> --serial <指定设备> --port <端口> --since "MM-DD HH:MM:SS.000" --output <新的报告路径>
```

工具只读取 `CageGBoxProbe` 日志，不启动应用、改设置或保存原始日志。按行数限定的 `--since` 可能受其他系统日志挤占，应优先使用准确时间窗口。记录可能被系统日志缓冲淘汰；缺段、截断、重复、摘要错误和对象缺失会报错，不用旧通过结果补齐。产物、前台应用/来宾身份和会话仍须单独核对。

```powershell
python mobile/sandbox/gbox-mod/probe/compare_network_metadata.py --outer <外层报告> --guest <来宾报告> --output <新对照文件>
python -m unittest discover -s mobile/sandbox/gbox-mod/probe -p "test_*.py"
```

元数据通过仅表示本轮活动 VPN 隧道同步查询及默认回调的所测字段为空，并且外层有有效阳性对照；不证明全部网络身份隔离、跨进程 Network 身份一致或网络中断时不直连。非隧道链路、Java 接口地址、实际 socket 本地端点和其他读取路径另行验收。旧 SIM/时区/VPN/标记比较继续使用 `compare_reports.py`。

本轮 Windows 离线测试及 Android16 真机采集通过；Python 标准库逻辑没有宿主平台分支，macOS/Linux 运行未实测。桌面三个平台的运行时未修改。
