"""Adapt this repository's privacy module to BlackBox; no GBox APK/code input."""
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
SOURCE = HERE.parent / "sandbox/gbox-mod/privacy"
BB = "top.niunaijun.blackbox"


def replace(text, before, after):
    if text.count(before) != 1:
        raise ValueError("Privacy source changed: " + before[:90])
    return text.replace(before, after)


def method(text, signature, body):
    start = text.index(signature)
    opening = text.index("{", start)
    depth, end = 1, opening + 1
    while depth:
        depth += (text[end] == "{") - (text[end] == "}")
        end += 1
    return text[:opening + 1] + "\n" + body + "\n    }" + text[end:]


def prepare(project):
    java = project / "Bcore/src/main/java"
    out = java / "io/github/leexeo/cage/privacy"
    out.mkdir(parents=True, exist_ok=True)
    for src in (SOURCE / "java/io/github/leexeo/cage/privacy").glob("*.java"):
        s = src.read_text(encoding="utf-8")
        # The original standalone probe remains a comparable control APK.
        s = s.replace('|| "io.github.leexeo.cage.gboxprobe".equals(packageName);',
                      '|| "io.github.leexeo.cage.gboxprobe".equals(packageName)\n'
                      '            || "io.github.flysky701.cage.probe".equals(packageName);')
        if src.name == "GuestPrivacy.java":
            s = method(s, "private static String currentPackage()", f"        return {BB}.app.BActivityThread.getAppPackageName();")
            s = method(s, "private static boolean runtimePrepared(Context guest, String pkg)",
                       "        return android.os.Build.VERSION.SDK_INT == 36\n"
                       "            && android.os.Process.is64Bit() && pkg.equals(currentPackage());")
            s = method(s, "private static boolean applyProperties()",
                       "        return io.github.flysky701.cage.open.OpenPrivacyProperties.activate(Profile.SIM, Profile.TIMEZONE);")
            s = replace(s, '''            Class<?> nativeApi = Class.forName("com.vlite.sdk.jni.Native");
            Method set = nativeApi.getMethod("addNativeProp", String.class, String.class);
            for (Map.Entry<String, String> value : originalProperties.entrySet())
                set.invoke(null, value.getKey(), value.getValue());''',
                        "            io.github.flysky701.cage.open.OpenPrivacyProperties.deactivate();")
        if src.name == "NativePrivacy.java":
            s = replace(s, 'long api = (Long) Class.forName("com.vlite.sdk.jni.Native").getMethod("getBhookApi").invoke(null);',
                        "long api = 0L; // API36 uses the separately pinned open-source ByteHook.")
            s = method(s, "private static boolean verifiedCompatibility()", "        return false; // No native bridge or host loader in Cage Open.")
            s = method(s, "private static void addAndroid16Roots(Set<String> roots, ApplicationInfo info, String pkg)", f'''
        Context host = {BB}.BlackBoxCore.getContext();
        if (!"io.github.flysky701.cage.open".equals(host.getApplicationInfo().packageName)
                || !pkg.equals({BB}.app.BActivityThread.getAppPackageName()))
            throw new IllegalStateException("Native policy host/guest mismatch");
        int user = {BB}.app.BActivityThread.getUserId();
        File base = {BB}.core.env.BEnvironment.getVirtualRoot();
        File[] selected = {{{BB}.core.env.BEnvironment.getAppDir(pkg),
            {BB}.core.env.BEnvironment.getDataDir(pkg, user),
            {BB}.core.env.BEnvironment.getDeDataDir(pkg, user)}};
        String prefix = physicalPath(base) + "/data/";
        for (File root : selected) {{
            String path = physicalPath(root);
            if (!path.startsWith(prefix) || !path.endsWith("/" + pkg))
                throw new IllegalStateException("Native policy private root mismatch");
            roots.add(path);
        }}
        Log.i("CageNativePrivacy", "java.bind.blackboxRoots.verified");''')
            s = replace(s, '''            Object client = Class.forName("com.vlite.sdk.client.k").getMethod("getInst").invoke(null);
            String current = (String) client.getClass().getMethod("getVirtualClientPkgName").invoke(client);''',
                        f"            String current = {BB}.app.BActivityThread.getAppPackageName();")
        if src.name == "ChildPolicy.java":
            s = replace(s, '''            Object client = Class.forName("com.vlite.sdk.client.k").getMethod("getInst").invoke(null);
            String current = (String) client.getClass().getMethod("getVirtualClientPkgName").invoke(client);''',
                        f"            String current = {BB}.app.BActivityThread.getAppPackageName();")
            s = replace(s, 'Context host = (Context) Class.forName("com.vlite.sdk.context.i").getMethod("c").invoke(null);',
                        f"Context host = {BB}.BlackBoxCore.getContext();")
            s = s.replace('"com.cage.android".equals(host.getApplicationInfo().packageName)',
                          '"io.github.flysky701.cage.open".equals(host.getApplicationInfo().packageName)')
        (out / src.name).write_text(s, encoding="utf-8")
    (out / "Profile.java").write_text('''package io.github.leexeo.cage.privacy;
final class Profile {
    static final boolean SIM = true, TIMEZONE = true, VPN = true;
    static final String ZONE = "Asia/Tokyo";
}
''', encoding="utf-8")
    thread = java / "top/niunaijun/blackbox/app/BActivityThread.java"
    s = thread.read_text(encoding="utf-8")
    if "GuestPrivacy.bindGuestContext(packageContext)" not in s:
        s = replace(s, "public synchronized void handleBindApplication(String packageName, String processName) {",
                    "public synchronized void handleBindApplication(String packageName, String processName) {\n"
                    "        io.github.leexeo.cage.privacy.GuestPrivacy.beforeBind(packageName);")
        s = replace(s, "            onBeforeCreateApplication(packageName, processName, packageContext);",
                    "            io.github.leexeo.cage.privacy.GuestPrivacy.bindGuestContext(packageContext);\n"
                    "            onBeforeCreateApplication(packageName, processName, packageContext);")
        s = replace(s, "            installProviders(mInitialApplication, bindData.processName, bindData.providers);",
                    "            io.github.leexeo.cage.privacy.GuestPrivacy.bindGuestContext(mInitialApplication);\n"
                    "            installProviders(mInitialApplication, bindData.processName, bindData.providers);")
    thread.write_text(s, encoding="utf-8")
    hook = java / "top/niunaijun/blackbox/fake/hook/ClassInvocationStub.java"
    s = hook.read_text(encoding="utf-8")
    if "cageOriginalInvoke" not in s:
        s = replace(s, "public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {",
                    "public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {\n"
                    "        return io.github.leexeo.cage.privacy.GuestPrivacy.invoke(this::cageOriginalInvoke, proxy, method, args);\n"
                    "    }\n\n"
                    "    private Object cageOriginalInvoke(Object proxy, Method method, Object[] args) throws Throwable {")
    hook.write_text(s, encoding="utf-8")
    manager = java / "top/niunaijun/blackbox/fake/hook/HookManager.java"
    s = manager.read_text(encoding="utf-8")
    s = s.replace("new ISubProxy()", "new top.niunaijun.blackbox.fake.service.ISubProxy()")
    if "new top.niunaijun.blackbox.fake.service.ISubProxy()" not in s:
        s = replace(s, "addInjector(new ITelephonyManagerProxy());",
                    "addInjector(new ITelephonyManagerProxy());\n            addInjector(new top.niunaijun.blackbox.fake.service.ISubProxy());")
    manager.write_text(s, encoding="utf-8")
    native = project / "Bcore/src/main/cpp"
    shutil.copy2(HERE / "privacy-native/OpenPrivacyProperties.cpp", native)
    mk = native / "Android.mk"
    s = mk.read_text(encoding="utf-8")
    if "OpenPrivacyProperties.cpp" not in s:
        s = replace(s, "LOCAL_SRC_FILES := BoxCore.cpp \\\n", "LOCAL_SRC_FILES := BoxCore.cpp \\\nOpenPrivacyProperties.cpp \\\n")
    mk.write_text(s, encoding="utf-8")


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def build_native(args, project):
    def run(*cmd, env=None):
        subprocess.run([str(x) for x in cmd], check=True, env=env)
    deps = load("cage_privacy_dependencies", SOURCE / "native/dependencies.py")
    deps.prepare(args.work / "privacy-dependencies", fetch=True)
    native = load("cage_privacy_native", SOURCE / "native/build.py")
    built = native.build(args.work, {"root": HERE.parent.parent, "ndk": args.sdk / "ndk/27.0.12077973",
                                    "run": run, "env": dict(os.environ)})
    for target, source in built["extra_entries"].items():
        if target.startswith("lib/"):
            destination = project / "Bcore/src/main/jniLibs" / target[4:]
        else:
            destination = project / "app/src/main" / target
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
    child = load("cage_privacy_child", SOURCE / "child/build.py")
    import toolchain
    llvm = toolchain.llvm_prebuilt(args.sdk / "ndk/27.0.12077973")
    library, _, _ = child.build_library(args.work / "privacy-child-arm64", run, dict(os.environ), llvm, "arm64-v8a")
    destination = project / "app/src/main/assets/cage-child/arm64-v8a/libcage_child_properties.so"
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(library, destination)
