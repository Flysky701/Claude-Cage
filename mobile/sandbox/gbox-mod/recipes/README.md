# 历史增量构建记录

这里归档停止开发时仍位于 `mobile/.build/gbox-mod/` 的一次性组合和核对脚本，保留当前产物如何形成的依据。模块的可编辑源码仍在本目录上级，不在此复制。

这些不是可在空克隆中顺序运行的安装器：它们依赖具体历史 APK、编译缓存目录、工具链和当前源码状态。执行会生成新输出，部分脚本还修改所选缓存；本次上传没有执行它们。

- `prepare_*`、`finish_*`、`verify_*`：原位置为 `mobile/.build/gbox-mod/` 下同名文件。
- `build_privacy11_native.py`：原位置为 `mobile/.build/gbox-mod/native-privacy-check/`。
- `check_binder_publication12.py`：原位置为 `mobile/.build/gbox-mod/native-analysis/`。

文件按原内容归档，`__file__` 的父目录计算对应**原位置**。若要复用，应先恢复到原位置、准备其明确引用的输入，并核对本机工具路径；不能直接从本归档目录运行。缺失缓存时应重新生成相应构建输入，而非关闭样本检查或伪造旧元数据。

Privacy12 增量只替换 Privacy11 的 `libcage_compat.so`，保留其余非签名条目。Privacy11 则用真正的 host x86 JNI 包装替换失败的 Privacy10 复制方法路径，并复用 Privacy09 的原兼容库；Privacy12 再加入 Binder 辅助原入口提前发布。完整阶段和失败边界见 [接续说明](../../../HANDOFF-2026-11-15.md)。
