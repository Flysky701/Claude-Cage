"""Resolve local JDK, Android SDK, NDK, apktool, and Clang runtime resource paths."""
import os
from pathlib import Path

MOD_ROOT = Path(__file__).resolve().parent


def _first_existing(candidates):
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return path
    return Path(candidates[0])


def default_jdk() -> Path:
    candidates = [
        Path("D:/Code/DevEnv/JAVA/jdk-17"),
        Path("E:/Dependencies/Runtimes/jdk-17.0.12"),
    ]
    java_home = os.environ.get("JAVA_HOME")
    if java_home:
        candidates.append(Path(java_home))
    return _first_existing(candidates)


def default_tools(root: Path) -> Path:
    return _first_existing([
        root / "mobile/.build/client-integration/build-tools35/android-15",
        Path("E:/Tool/Android/sdk/build-tools/36.0.0"),
        Path("C:/Android/sdk/build-tools/34.0.0"),
    ])


def default_android_jar(root: Path) -> Path:
    return _first_existing([
        root / "mobile/.build/gbox-test/android.jar",
        root / "mobile/.build/tools/sdk/platforms/android-35/android.jar",
        root / "mobile/.build/sdk/platforms/android-34/android.jar",
    ])


def default_apktool(root: Path) -> Path:
    return _first_existing([
        root / "mobile/.build/blackbox-source/apktool.jar",
        root / "mobile/.build/tools/apktool.jar",
    ])


def default_ndk(root: Path) -> Path:
    return _first_existing([
        root / "mobile/.build/client-integration/ndk",
        root / "mobile/.build/tools/android-ndk-r28c",
    ])


def llvm_prebuilt(ndk: Path) -> Path:
    return Path(ndk) / "toolchains/llvm/prebuilt/windows-x86_64"


def clang_resource_dir(llvm: Path) -> Path:
    clang_root = Path(llvm) / "lib/clang"
    preferred = clang_root / "18"
    if preferred.is_dir():
        return preferred
    candidates = (
        [p for p in clang_root.iterdir() if p.is_dir() and (p / "lib/linux").is_dir()]
        if clang_root.is_dir() else []
    )
    if not candidates:
        raise FileNotFoundError(f"No Clang resource directory found under {clang_root}")
    candidates.sort(key=lambda p: [int(part) if part.isdigit() else 0 for part in p.name.split(".")], reverse=True)
    return candidates[0]


def clang_builtins(llvm: Path, arch: str) -> Path:
    return clang_resource_dir(llvm) / "lib/linux" / f"libclang_rt.builtins-{arch}-android.a"
