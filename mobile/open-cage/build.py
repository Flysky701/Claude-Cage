#!/usr/bin/env python3
"""Build Cage Open from pinned sources and bundle verified microG releases; no prebuilt host APK."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import urllib.request
import xml.etree.ElementTree as ET
from zipfile import ZipFile, ZIP_DEFLATED

HERE = Path(__file__).resolve().parent
LOCK = json.loads((HERE / "sources.lock.json").read_text())
BUNDLE = json.loads((HERE / "bundle.lock.json").read_text())


def run(*args, cwd=None):
    subprocess.run([os.fspath(x) for x in args], cwd=cwd, check=True)


def source(name, provided, cache):
    spec = LOCK[name]
    repo = provided or cache / name
    if not repo.exists():
        run("git", "init", repo)
        run("git", "-C", repo, "remote", "add", "origin", spec["url"])
        run("git", "-C", repo, "fetch", "--depth", "1", "origin", spec["commit"])
        run("git", "-C", repo, "checkout", "--detach", "FETCH_HEAD")
    commit = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD"], text=True).strip()
    if commit != spec["commit"]:
        raise ValueError(f"{name}: expected {spec['commit']}, got {commit}")
    return repo


def archive(repo, destination):
    destination.mkdir(parents=True, exist_ok=True)
    data = subprocess.check_output(["git", "-C", str(repo), "archive", "HEAD"])
    with tarfile.open(fileobj=io.BytesIO(data)) as tar:
        tar.extractall(destination, filter="data")


def replace(path, before, after):
    text = path.read_text()
    if text.count(before) != 1:
        raise ValueError(f"Pinned source no longer matches patch: {path.name}")
    path.write_text(text.replace(before, after))


def remove_region(path, first, last):
    text = path.read_text()
    start = text.index(first)
    end = text.index(last, start)
    path.write_text(text[:start] + text[end:])


def prepare(args, project):
    blackbox = source("blackbox", args.blackbox_source, args.work / "sources")
    dobby = source("dobby", args.dobby_source, args.work / "sources")
    archive(blackbox, project)
    shutil.rmtree(project / "app")
    shutil.copytree(HERE / "project", project, dirs_exist_ok=True)
    wrapper = project / "gradle/wrapper/gradle-wrapper.properties"
    with wrapper.open("a") as stream:
        stream.write("\ndistributionSha256Sum=6f74b601422d6d6fc4e1f9a1ab6522f642c2fdcbc15ae33ebd30ba3d7198e854\n")
    java = project / "Bcore/src/main/java/top/niunaijun/blackbox"
    core = java / "BlackBoxCore.java"
    # Remove collection/upload and the unrelated host-side token substitution experiment.
    replace(core, "import top.niunaijun.blackbox.utils.LogSender;", "")
    replace(core, "            startLogcat();", "            // Cage Open does not collect logcat on startup.")
    remove_region(core, "            // Phase 2: install Play Integrity token bridge", "        }\n        if (isServerProcess())")
    text = core.read_text()
    signature = "    public void sendLogs(String caption, boolean async, LogSendListener listener) {"
    start = text.index(signature); opening = text.index("{", start); depth = 1; end = opening + 1
    while depth:
        if text[end] == "{": depth += 1
        elif text[end] == "}": depth -= 1
        end += 1
    core.write_text(text[:start] + signature + '\n        if (listener != null) listener.onFailure("Log upload is not included in Cage Open");\n    }' + text[end:])
    (java / "utils/LogSender.java").unlink()
    (java / "hooks/IntegrityProxy.java").unlink()
    replace(java / "app/configuration/ClientConfiguration.java", 'return "-1003719573856";', "return null;")
    service = java / "fake/service/IActivityManagerProxy.java"
    remove_region(service, "            // Phase 2 / Fix 10:", "            if (intent == null) {")
    replace(service,
        "public static Object BindServiceCommon(Object who, Method method, Object[] args,int callingPackageIndex) throws Throwable {\n        try {",
        "public static Object BindServiceCommon(Object who, Method method, Object[] args,int callingPackageIndex) throws Throwable {\n"
        "        Intent requested = (Intent) args[2];\n"
        "        String requestedPackage = requested == null ? null : requested.getComponent() != null\n"
        "                ? requested.getComponent().getPackageName() : requested.getPackage();\n"
        "        boolean privateOnly = io.github.flysky701.cage.open.GuestServicePolicy.privateOnly(\n"
        "                requestedPackage, requested == null ? null : requested.getAction());\n        try {")
    replace(service,
        "            if (resolveInfo != null || AppSystemEnv.isOpenPackage(intent.getComponent())) {",
        "            if (privateOnly && resolveInfo == null) return 0;\n"
        "            if (resolveInfo != null || AppSystemEnv.isOpenPackage(intent.getComponent())) {")
    replace(service,
        '            Slog.e(TAG, "BindServiceCommon: Unexpected error", e);',
        '            Slog.e(TAG, "BindServiceCommon: Unexpected error", e);\n            if (privateOnly) return 0;')
    replace(service,
        "            return method.invoke(who, args);\n        } catch (Exception e) {\n            Slog.e(TAG, \"BindServiceCommon: Unexpected error\", e);",
        "            if (privateOnly) return 0;\n            return method.invoke(who, args);\n        } catch (Exception e) {\n            Slog.e(TAG, \"BindServiceCommon: Unexpected error\", e);")
    shutil.copytree(HERE / "runtime", project / "Bcore/src/main/java", dirs_exist_ok=True)
    # Reuse the existing source patch, rather than recovered APK/smali content.
    run("git", "apply", HERE.parent.parent / "patches/blackbox-reborn/android16-apk-import.patch", cwd=project)
    accounts = java / "core/system/accounts/BAccountManagerService.java"
    text = accounts.read_text(); start = text.index("        \n        BUserAccounts userAccounts", text.index("public AuthenticatorDescription[] getAuthenticatorTypes"))
    end = text.index("\n    }", start)
    accounts.write_text(text[:start] + "\n        return io.github.leexeo.cage.space.GuestAuthenticatorTypes.forCaller(userId, Binder.getCallingPid());" + text[end:])
    guest = project / "Bcore/src/main/java/io/github/leexeo/cage/space"
    guest.mkdir(parents=True, exist_ok=True)
    shutil.copy2(HERE.parent / "sandbox/blackbox-light/GuestAuthenticatorTypes.java", guest)
    prepare_microg_runtime(java)
    # Keep component declarations but narrow host permissions for this import/start milestone.
    manifest = project / "Bcore/src/main/AndroidManifest.xml"
    android = "{http://schemas.android.com/apk/res/android}"
    ET.register_namespace("android", android[1:-1])
    ET.register_namespace("tools", "http://schemas.android.com/tools")
    xml = ET.parse(manifest); root = xml.getroot()
    keep = {"android.permission.INTERNET", "android.permission.ACCESS_NETWORK_STATE",
            "android.permission.WAKE_LOCK", "android.permission.FOREGROUND_SERVICE"}
    seen = set()
    for child in list(root):
        if child.tag.startswith("uses-permission"):
            name = child.get(android + "name")
            if name not in keep or name in seen: root.remove(child)
            else: seen.add(name)
        elif child.tag == "uses-feature": child.set(android + "required", "false")
    xml.write(manifest, encoding="utf-8", xml_declaration=True)
    # Optional opaque JUnit asset is not needed by the import/start prototype.
    assets = project / "Bcore/src/main/assets"
    (assets / "junit.jar").unlink()
    (assets / "empty.jar").unlink()
    replace(java / "core/system/JarConfig.java", "new JarDefinition[]{EMPTY_JAR, JUNIT_JAR}", "new JarDefinition[]{EMPTY_JAR}")
    # Rebuild Dobby instead of linking the binary archives supplied by the container fork.
    for binary in (project / "Bcore/src/main/cpp/Dobby").rglob("*.a"): binary.unlink()
    replace(project / "Bcore/build.gradle", "abiFilters 'arm64-v8a', 'armeabi-v7a'", "abiFilters 'arm64-v8a'")
    (project / "local.properties").write_text("sdk.dir=" + args.sdk.as_posix() + "\n")
    return dobby


def prepare_microg_runtime(java):
    hooks = java / "fake/hook/HookManager.java"
    for name in ("GmsProxy", "GoogleAccountManagerProxy", "AuthenticationProxy"):
        replace(hooks, f"            addInjector(new {name}());", "")
    # Preserve the actual private APK signature instead of borrowing the phone's GMS identity.
    compat = java / "core/system/pm/PackageManagerCompat.java"
    text = compat.read_text()
    start = text.index("        PackageInfo base = null;")
    end = text.index("        return pi;", start)
    compat.write_text(text[:start] + '''        if ((flags & (PackageManager.GET_SIGNATURES | PackageManager.GET_SIGNING_CERTIFICATES)) != 0) {
            PackageInfo original = BlackBoxCore.getPackageManager().getPackageArchiveInfo(p.baseCodePath, flags);
            if (original == null) return null;
            pi.signatures = original.signatures;
            pi.signingInfo = original.signingInfo;
        }
''' + text[end:])
    # These newer account sessions have no guest implementation; never forward to personal accounts.
    accounts = java / "fake/service/IAccountManagerProxy.java"
    marker = '    public static final String TAG = "IAccountManagerProxy";'
    replace(accounts, marker, marker + '''
    @top.niunaijun.blackbox.fake.hook.ProxyMethods({"startAddAccountSession", "startUpdateCredentialsSession", "finishSessionAsUser"})
    public static class UnsupportedGuestSession extends MethodHook {
        @Override protected Object hook(Object who, Method method, Object[] args) throws Throwable {
            IAccountManagerResponse response = (IAccountManagerResponse) args[0];
            if (response == null) throw new IllegalArgumentException("response is null");
            response.onError(android.accounts.AccountManager.ERROR_CODE_UNSUPPORTED_OPERATION,
                    "Account sessions are not supported in this guest space");
            return null;
        }
    }
''')
    policy = java / "fake/service/IDevicePolicyManagerProxy.java"
    marker = "public class IDevicePolicyManagerProxy extends BinderInvocationStub {"
    replace(policy, marker, marker + '''
    @Override public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        if ("getAccountTypesWithManagementDisabledAsUser".equals(method.getName())
                && args != null && args.length == 3 && args[1] instanceof String)
            args[1] = top.niunaijun.blackbox.BlackBoxCore.getHostPkg();
        return super.invoke(proxy, method, args);
    }
''')


def build_bundle(args, project):
    assets = project / "app/src/main/assets/bundle"
    assets.mkdir(parents=True, exist_ok=True)
    cache = args.bundle_inputs or args.work / "bundle-downloads"
    cache.mkdir(parents=True, exist_ok=True)
    run("bash", project / "gradlew", "--no-daemon", ":probe:assembleDebug", cwd=project)
    probe = project / "probe/build/outputs/apk/debug/probe-debug.apk"
    shutil.copy2(probe, assets / "cage-probe.apk")
    entries = [{"label": "Cage 内置测试", "package": "io.github.flysky701.cage.probe",
                "versionCode": 1, "file": "cage-probe.apk", "sha256": hashlib.sha256(probe.read_bytes()).hexdigest()}]
    for spec in sorted(BUNDLE["apps"], key=lambda item: item["package"] != "com.google.android.gms"):
        apk = cache / spec["name"]
        if not apk.exists():
            temporary = apk.with_suffix(".download")
            with urllib.request.urlopen(spec["url"], timeout=90) as incoming, temporary.open("wb") as outgoing:
                shutil.copyfileobj(incoming, outgoing, 1024 * 1024)
            temporary.rename(apk)
        with apk.open("rb") as stream:
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
        if apk.stat().st_size != spec["size"] or digest != spec["sha256"]:
            raise ValueError("Bundled upstream APK checksum mismatch: " + spec["name"])
        signature = subprocess.check_output([str(args.sdk / "build-tools/36.1.0/apksigner"),
                                            "verify", "--print-certs", str(apk)], text=True)
        if "Signer #1 certificate SHA-256 digest: " + BUNDLE["signerSha256"] not in signature:
            raise ValueError("Unexpected microG signing certificate")
        shutil.copy2(apk, assets / spec["name"])
        entries.append({"label": spec["label"], "package": spec["package"], "versionCode": spec["versionCode"],
                        "file": spec["name"], "sha256": spec["sha256"]})
        print("Bundled verified upstream APK:", spec["name"], flush=True)
    (assets / "manifest.json").write_text(json.dumps({"apps": entries}, ensure_ascii=False, indent=2) + "\n")
    shutil.copy2(HERE / "THIRD-PARTY-NOTICES.txt", assets / "NOTICE.txt")
    shutil.copy2(HERE / "APACHE-2.0.txt", assets / "APACHE-2.0.txt")
    return entries


def build_assets(args, project):
    work = args.work / "empty-dex"; work.mkdir(exist_ok=True)
    java = work / "Empty.java"; java.write_text("package io.github.flysky701.cage.empty; public final class Empty {}\n")
    classes = work / "classes"; classes.mkdir(exist_ok=True)
    run(args.jdk / "bin/javac", "--release", "8", "-d", classes, java)
    jar = work / "empty-classes.jar"
    with ZipFile(jar, "w", ZIP_DEFLATED) as z:
        for file in classes.rglob("*.class"): z.write(file, file.relative_to(classes))
    run(args.sdk / "build-tools/36.1.0/d8", "--min-api", "28", "--output", work, jar)
    with ZipFile(project / "Bcore/src/main/assets/empty.jar", "w", ZIP_DEFLATED) as z:
        z.write(work / "classes.dex", "classes.dex")


def prepare_dobby(repo, work):
    destination = work / "dobby-source"
    if not destination.exists():
        archive(repo, destination)
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk", required=True, type=Path)
    parser.add_argument("--jdk", required=True, type=Path)
    parser.add_argument("--blackbox-source", type=Path)
    parser.add_argument("--dobby-source", type=Path)
    parser.add_argument("--bundle-inputs", type=Path, help="cache of the unchanged microG release APKs")
    parser.add_argument("--cmake", default="cmake")
    parser.add_argument("--ninja", default="ninja")
    parser.add_argument("--work", type=Path, default=HERE.parent / ".build/open-cage")
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--resume", action="store_true", help="reuse this run's prepared project")
    args = parser.parse_args()
    for name in ("sdk", "jdk", "work", "blackbox_source", "dobby_source", "bundle_inputs"):
        value = getattr(args, name)
        if value is not None: setattr(args, name, value.resolve())
    args.work.mkdir(parents=True, exist_ok=True)
    os.environ["JAVA_HOME"] = str(args.jdk)
    os.environ["ANDROID_HOME"] = str(args.sdk)
    os.environ["PATH"] = str(args.jdk / "bin") + os.pathsep + os.environ["PATH"]
    project = args.work / "project"
    if args.resume:
        dobby = source("dobby", args.dobby_source, args.work / "sources")
    else:
        if project.exists():
            raise ValueError("Prepared project exists. Use a fresh --work directory or --resume; no files were deleted.")
        dobby = prepare(args, project)
    if args.prepare_only:
        print(project); return
    dobby = prepare_dobby(dobby, args.work)
    native = args.work / "dobby-arm64-source"
    run(args.cmake, "-S", dobby, "-B", native, "-G", "Ninja", "-DCMAKE_MAKE_PROGRAM=" + args.ninja,
        "-DCMAKE_TOOLCHAIN_FILE=" + str(args.sdk / "ndk/27.0.12077973/build/cmake/android.toolchain.cmake"),
        "-DANDROID_ABI=arm64-v8a", "-DANDROID_PLATFORM=android-28", "-DCMAKE_BUILD_TYPE=Release",
        "-DDOBBY_BUILD_TEST=OFF", "-DDOBBY_BUILD_EXAMPLE=OFF")
    run(args.cmake, "--build", native, "--target", "dobby_static", "--parallel", "2")
    shutil.copy2(native / "libdobby.a", project / "Bcore/src/main/cpp/Dobby/arm64-v8a/libdobby.a")
    build_assets(args, project)
    bundled = build_bundle(args, project)
    run("bash", project / "gradlew", "--no-daemon", ":app:assembleDebug", cwd=project)
    apk = project / "app/build/outputs/apk/debug/app-debug.apk"
    run(args.sdk / "build-tools/36.1.0/apksigner", "verify", "--verbose", apk)
    output = args.work / "Cage-Open-Bundled-Preview-0.0.2.apk"; shutil.copy2(apk, output)
    report = {"artifact": output.name, "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
              "sources": LOCK, "bundledApps": bundled, "deviceTested": False, "claudeLoginTested": False}
    (args.work / "build-result.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__": main()
