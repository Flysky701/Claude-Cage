"""Add a narrowly scoped guest privacy policy to the supplied GBox build tree."""
from pathlib import Path
from zipfile import ZipFile
import json
import importlib.util
import re
import shutil


RUNTIME = "Lio/github/leexeo/cage/privacy/GuestPrivacy;"
ORIGINAL = "Lio/github/leexeo/cage/privacy/OriginalCall;"
MODULE = Path(__file__).resolve().parent


def replace_once(path, old, new):
    text = path.read_text(encoding="utf-8")
    if text.count(old) != 1:
        raise ValueError(f"Privacy integration point changed in {path.name}: {text.count(old)} matches")
    path.write_text(text.replace(old, new), encoding="utf-8", newline="\n")


def method_entry(path, signature, instruction):
    text = path.read_text(encoding="utf-8")
    if text.count(signature) != 1:
        raise ValueError("Privacy method boundary changed: " + signature)
    start = text.index(signature)
    end = text.index(".end method", start)
    pos = start
    annotation = False
    for line in text[start:end].splitlines(keepends=True):
        stripped = line.strip()
        if stripped.startswith(".annotation"):
            annotation = True
        elif stripped.startswith(".end annotation"):
            annotation = False
        elif not annotation and stripped and not stripped.startswith((".", "#")):
            break
        pos += len(line)
    else:
        raise ValueError("Privacy method has no executable entry: " + signature)
    text = text[:pos] + instruction + "\n\n" + text[pos:]
    path.write_text(text, encoding="utf-8", newline="\n")


def replace_in_method(path, signature, old, new):
    text = path.read_text(encoding="utf-8")
    if text.count(signature) != 1:
        raise ValueError("Privacy method boundary changed: " + signature)
    start = text.index(signature)
    end = text.index(".end method", start)
    section = text[start:end]
    if section.count(old) != 1:
        raise ValueError("Privacy exception boundary changed: " + signature)
    path.write_text(text[:start] + section.replace(old, new) + text[end:], encoding="utf-8", newline="\n")


def add_bind_diagnostics(decoded: Path):
    path = Path(decoded) / "smali_classes4/com/vlite/sdk/client/k.smali"
    source = path.read_text(encoding="utf-8")
    if "cagePrivacyBindBefore" in source:
        raise ValueError("Privacy bind diagnostics already present")
    call = f"    invoke-static {{v4}}, {RUNTIME}->bindGuestContext(Landroid/content/Context;)V\n"
    replace_once(path, call,
        "    invoke-static {}, Lcom/vlite/sdk/client/k;->cagePrivacyBindBefore()V\n" + call
        + "    invoke-static {}, Lcom/vlite/sdk/client/k;->cagePrivacyBindAfter()V\n")
    # k is already initialized here. Separate methods avoid touching any live
    # caller register or adding another class-initialization dependency.
    with path.open("a", encoding="utf-8", newline="\n") as out:
        for name, label in (("cagePrivacyBindBefore", "stage.context.returned.beforeBind"),
                            ("cagePrivacyBindAfter", "stage.bind.returned")):
            out.write(f'''\n.method private static {name}()V
    .locals 2
    const-string v0, "CagePrivacy"
    const-string v1, "{label}"
    invoke-static {{v0, v1}}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    return-void
.end method
''')


def apply(decoded: Path, work: Path, context: dict) -> dict:
    decoded, work = Path(decoded), Path(work)
    root = Path(context["root"])
    jdk, tools = Path(context["jdk"]), Path(context["tools"])
    android = Path(context["android_jar"])
    apktool = Path(context["apktool"])
    run, env = context["run"], context["env"]
    modules = set(context.get("privacy_modules", ["sim", "timezone", "vpn"]))
    if not modules or not modules.issubset({"sim", "timezone", "vpn"}):
        raise ValueError("privacy_modules must contain sim, timezone and/or vpn")
    zone = context.get("privacy_timezone", "Asia/Tokyo")
    if zone != "Asia/Tokyo":
        raise ValueError("This tested build profile is scoped to Asia/Tokyo")
    output = work / "privacy"
    output.mkdir()
    native_components = {}
    extra_entries = {}
    for name in ("native", "child", "host"):
        spec = importlib.util.spec_from_file_location("cage_privacy_" + name, MODULE / name / "build.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        component = module.build(work, context)
        native_components[name] = component["metadata"]
        for entry, file in component["extra_entries"].items():
            if entry in extra_entries:
                raise ValueError("Duplicate privacy asset: " + entry)
            extra_entries[entry] = file
    base = decoded / "smali_classes4/com/vlite/sdk"
    proxy = base / "ІӀӏ/g7.smali"
    text = proxy.read_text(encoding="utf-8")
    if "cageOriginalInvoke" in text:
        raise ValueError("Privacy policy is already present")
    replace_once(proxy, '.source "SourceFile"\n', '.source "SourceFile"\n\n.implements ' + ORIGINAL + '\n')
    signature = ".method public invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;"
    replace_once(proxy, signature, signature.replace(" invoke(", " cageOriginalInvoke("))
    with proxy.open("a", encoding="utf-8", newline="\n") as out:
        out.write(f"""
{signature}
    .locals 1
    invoke-static {{p0, p1, p2, p3}}, {RUNTIME}->invoke({ORIGINAL}Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v0
    return-object v0
.end method
""")
    # This context is created after Native.i(package), before LoadedApk.makeApplication
    # and guest providers. It is earlier than Application.onCreate.
    bind = base / "client/k.smali"
    anchor = ("    invoke-virtual {v6, v14, v15}, Landroid/content/Context;->createPackageContext(Ljava/lang/String;I)Landroid/content/Context;\n"
              "\n    move-result-object v4\n")
    # The full build adds compatibility after privacy. An incremental overlay
    # can already contain its Context observation; keep that before binding.
    observation = "    invoke-static {v4}, Lio/github/leexeo/cage/gbox/FrameworkPaths;->contextCreated(Landroid/content/Context;)V\n"
    current = bind.read_text(encoding="utf-8")
    if observation in current:
        if current.count(anchor) != 1 or current.count(observation) != 1:
            raise ValueError("Prepared guest Context observation changed")
        if current.index(observation) < current.index(anchor) + len(anchor):
            raise ValueError("Guest Context observation occurs before its producer")
        gap = current[current.index(anchor) + len(anchor):current.index(observation)]
        allowed = "    invoke-static {}, Lio/github/leexeo/cage/gbox/NativeTrace;->stage13()V"
        if any(line.strip() and line != allowed for line in gap.splitlines()):
            raise ValueError("Unexpected work between Context return and observation")
        anchor = observation
    replace_once(bind, anchor, anchor + f"\n    invoke-static {{v4}}, {RUNTIME}->bindGuestContext(Landroid/content/Context;)V\n")
    # WebView provider preparation needs ActivityThread.currentApplication.
    # Keep the earliest policy bind above, then refresh after the original
    # application publication and before providers/application onCreate.
    application_anchor = (
        "    sget-object v5, Lcom/vlite/sdk/reflect/android/app/f;->mInitialApplication:Lcom/vlite/sdk/reflect/e;\n"
        "\n    invoke-static {}, Lcom/vlite/sdk/context/i;->e()Landroid/app/ActivityThread;\n"
        "\n    move-result-object v7\n"
        "\n    invoke-virtual {v5, v7, v3}, Lcom/vlite/sdk/reflect/e;->set(Ljava/lang/Object;Ljava/lang/Object;)V\n")
    replace_once(bind, application_anchor, application_anchor + f"\n    invoke-static {{v3}}, {RUNTIME}->apply(Landroid/content/Context;)V\n")
    # The original public method can return from its application cache, and
    # its posted Runnable calls s0 directly. Check both before original work.
    for signature in (".method public bindApplication(Ljava/lang/String;Ljava/lang/String;)V",
                      ".method public final s0(Ljava/lang/String;Ljava/lang/String;)V"):
        method_entry(bind, signature, f"    invoke-static/range {{p1 .. p1}}, {RUNTIME}->beforeBind(Ljava/lang/String;)V")
    s0 = ".method public final s0(Ljava/lang/String;Ljava/lang/String;)V"
    # Only the helper's persistent blocked condition is rethrown. Other
    # original makeApplication failures retain their original fallback.
    fallback = "    :goto_3\n    :try_start_6\n"
    replace_in_method(bind, s0, fallback, "    :goto_3\n"
        + f"    invoke-static {{v5}}, {RUNTIME}->rethrowIfBlocked(Ljava/lang/Throwable;)V\n\n"
        + "    :try_start_6\n")
    failure = "    :goto_d\n    move-object v3, v0\n"
    replace_in_method(bind, s0, failure, failure
        + f"\n    invoke-static {{v3}}, {RUNTIME}->rethrowIfBlocked(Ljava/lang/Throwable;)V\n")
    instrumentation = base / "client/hook/service/app/InstrumentationLiteApp.smali"
    method_entry(instrumentation, ".method public onException(Ljava/lang/Object;Ljava/lang/Throwable;)Z",
                 f"    invoke-static/range {{p2 .. p2}}, {RUNTIME}->rethrowIfBlocked(Ljava/lang/Throwable;)V")
    method_entry(instrumentation,
                 ".method public newApplication(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Context;)Landroid/app/Application;",
                 f"    invoke-static {{p3}}, {RUNTIME}->bind(Landroid/content/Context;)V")
    method_entry(instrumentation, ".method public callApplicationOnCreate(Landroid/app/Application;)V",
                 f"    invoke-static {{p1}}, {RUNTIME}->bind(Landroid/content/Context;)V")
    for sig in [".method public callActivityOnCreate(Landroid/app/Activity;Landroid/os/Bundle;)V",
                ".method public callActivityOnCreate(Landroid/app/Activity;Landroid/os/Bundle;Landroid/os/PersistableBundle;)V"]:
        method_entry(instrumentation, sig, f"    invoke-static {{p1}}, {RUNTIME}->apply(Landroid/content/Context;)V")
    if context.get("native_trace", False):
        add_bind_diagnostics(decoded)

    generated = output / "generated/io/github/leexeo/cage/privacy/Profile.java"
    generated.parent.mkdir(parents=True)
    generated.write_text("package io.github.leexeo.cage.privacy;\nfinal class Profile {\n"
                         + "\n".join(f" static final boolean {name.upper()} = {str(name in modules).lower()};"
                                     for name in ["sim", "timezone", "vpn"])
                         + f'\n static final String ZONE = "{zone}";\n}}\n', encoding="utf-8")
    classes = output / "classes"
    classes.mkdir()
    sources = sorted((MODULE / "java").rglob("*.java")) + [generated]
    run(jdk / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8", "-g", "-cp", android,
        "-d", classes, *sources, env=env)
    jar = output / "privacy.jar"
    with ZipFile(jar, "w") as archive:
        for path in classes.rglob("*.class"):
            archive.write(path, path.relative_to(classes).as_posix())
    dex = output / "dex"
    dex.mkdir()
    run(tools / "d8.bat", "--min-api", "28", "--lib", android, "--output", dex, jar, env=env)
    stub = output / "privacy-only.apk"
    with ZipFile(stub, "w") as archive:
        archive.write(decoded / "AndroidManifest.xml", "AndroidManifest.xml")
        archive.write(dex / "classes.dex", "classes.dex")
    smali = output / "smali-output"
    run(jdk / "bin/java.exe", "-jar", apktool, "d", "--no-res", "--no-assets", "-o", smali, stub, env=env)
    indexes = [1]
    for directory in decoded.glob("smali_classes*"):
        match = re.fullmatch(r"smali_classes(\d+)", directory.name)
        if match:
            indexes.append(int(match[1]))
    index = max(indexes) + 1
    added = decoded / ("smali_classes" + str(index))
    shutil.copytree(smali / "smali", added)
    metadata = {
        "scope": ["com.anthropic.claude", "io.github.leexeo.cage.gboxprobe"],
        "modules": sorted(modules), "zone": zone,
        "guestBind": "Only bindGuestContext after VLite client package Context returns, before makeApplication",
        "instrumentationBind": "Refresh an already bound same-guest policy only; never initializes policy from an early Context",
        "preparationGate": "Absent compatibility class or explicitly chosen original path uses Context identity; verified compatibility additionally requires matching Framework roots; pending/failed preparation cannot bind",
        "fixedBindDiagnostics": bool(context.get("native_trace", False)),
        "afterApplicationPublication": "Refresh after original mInitialApplication assignment, before providers and onCreate",
        "processReuse": {
            "guard": "helper persistent blocked condition, independent of active privacy flag",
            "beforeBinding": ["public bindApplication before cache lookup", "s0 before its original try blocks"],
            "exceptionPropagation": ["s0 makeApplication fallback", "s0 final exception handler", "Instrumentation.onException before delegate"],
            "ordinaryExceptionsChanged": False, "explicitProcessKillAdded": False,
            "runtimeValidation": "NOT_RUN"
        },
        "binderEntry": "VLite g7.invoke delegates to unmodified original implementation",
        "googleComponentsModified": False, "wallClockModified": False,
        "nativeComponents": native_components,
        "webView": {
            "provider": "com.android.webview 110.0.5481.154.1 (548115537)",
            "mechanism": "Real Chromium time-zone-for-testing startup switch before engine initialization",
            "android16Provider": "com.google.android.webview 156.0.8078.47 (807804703)",
            "android16Mechanism": "Version-guarded native monitor notification; isolated renderer initial update is asynchronous",
            "android16FirstScript": "KNOWN_FAILURE: three Test07 cold starts initially Shanghai before Tokyo; see WEBVIEW-ANDROID16.md",
            "dataDirectorySuffix": "Existing GBox suffix required and preserved",
            "guestChange": "Restore switch and persistently reject reuse of the initialized provider process",
            "pageJavaScriptModified": False, "runtimeFirstScriptValidation": "NOT_RUN"
        },
        "coveredPaths": ["phone Binder read methods", "VLite process-local native telephony properties",
                         "Java and ICU defaults plus TZ environment", "Connectivity return values",
                         "Messenger network callbacks", "Java NetworkInterface through Libcore.os.getifaddrs",
                         "Selected ARM guest library property reads and getifaddrs; original MuMu or separate API36 ByteHook",
                         "Guarded x86_64/API31-32 and native arm64/API36 default child environment property APIs",
                         "Exact WebView110 startup switch; WebView156 subsequent timezone only, first-script race remains"],
        "requiresRuntimeVerification": ["VLite native-property hook behavior", "WebView timezone",
                                        "native/subprocess timezone", "real nonempty host SIM contrast",
                                        "VPN-active callback and interface contrast", "Google and Claude login"],
        "notClaimed": ["host x86 parent library reads", "directly resolved function pointers or raw syscalls/netlink",
                       "child explicit/cached environment enforcement", "child VPN interface enumeration", "network route enforcement",
                       "Android16 WebView first-script timezone guarantee",
                       "kernel isolation", "Play Integrity or app licensing verdicts"]
    }
    (output / "metadata.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    return {"changed_dex": ["classes4.dex", f"classes{index}.dex"], "extra_entries": extra_entries, "metadata": metadata}
