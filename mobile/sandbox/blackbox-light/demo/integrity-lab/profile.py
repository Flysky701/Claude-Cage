"""Build-only integration of the supplied components into a separate test space."""
import json
import re
from zipfile import ZipFile


COMPONENTS = {
    "MGC.apk": ("com.android.vending.mgc", 84024869,
                "bfb3464ed3343b8ce5825b8d3606a3a7fc64a7433ff6eb7fccff6aacfa971335"),
    "MG-250952077.apk": ("com.google.android.gms", 250952077,
                         "bfb3464ed3343b8ce5825b8d3606a3a7fc64a7433ff6eb7fccff6aacfa971335"),
    "gpstore400013.apk": ("com.android.vending", 84001300,
                         "f0fd6c5b410f25cb25c3b53346c8972fae30f8ee7411df910480ad6b2d60db83"),
}


def replace(path, old, new):
    text = path.read_text(encoding="utf-8")
    if text.count(old) != 1:
        raise ValueError("Integration point changed: " + path.name)
    path.write_text(text.replace(old, new), encoding="utf-8", newline="\n")


def prepare(module, decoded, work, args, tools, env, run):
    assets = {}
    evidence = []
    with ZipFile(args.integrity_lab_apk) as sample:
        for name, (package, version, signer) in COMPONENTS.items():
            path = work / name
            path.write_bytes(sample.read("assets/preset_apps/" + name))
            certs = run(tools / "apksigner.bat", "verify", "--print-certs", path, env=env)
            actual = re.findall(r"^Signer #\d+ certificate SHA-256 digest: (\w+)\r?$", certs, re.M)
            badging = run(tools / "aapt2.exe", "dump", "badging", path)
            if actual != [signer] or not badging.startswith(
                    "package: name='" + package + "' versionCode='" + str(version) + "'"):
                raise ValueError("Unexpected component identity: " + name)
            assets["assets/cage-integrity/" + name] = path
            evidence.append({"package": package, "versionCode": version, "signerSha256": signer})

    # The probe uses the same development certificate as this independent test copy.
    probe = module / "integrity-lab/probe"
    android = args.sdk / "platforms/android-35/android.jar"
    classes, dex = work / "probe-classes", work / "probe-dex"
    classes.mkdir()
    dex.mkdir()
    run(args.jdk / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8", "-g", "-cp",
        android, "-d", classes, *sorted(probe.rglob("*.java")))
    jar = work / "probe.jar"
    with ZipFile(jar, "w") as out:
        for path in classes.rglob("*.class"):
            out.write(path, path.relative_to(classes).as_posix())
    run(tools / "d8.bat", "--min-api", "28", "--lib", android, "--output", dex, jar, env=env)
    base = work / "probe-base.apk"
    run(tools / "aapt2.exe", "link", "-I", android, "--manifest", probe / "AndroidManifest.xml", "-o", base)
    with ZipFile(base, "a") as out:
        out.write(dex / "classes.dex", "classes.dex")
    aligned, signed = work / "probe-aligned.apk", work / "integrity-probe.apk"
    run(tools / "zipalign.exe", "-p", "-f", "4", base, aligned)
    run(tools / "apksigner.bat", "sign", "--ks", args.keystore,
        "--ks-pass", "env:CAGE_RECOVERY_KEYSTORE_PASSWORD", "--out", signed, aligned, env=env)
    assets["assets/cage-integrity/integrity-probe.apk"] = signed
    report = work / "components.json"
    report.write_text(json.dumps(evidence, indent=2), encoding="utf-8")
    assets["assets/cage-integrity/components.json"] = report

    core = decoded / "smali/top/niunaijun/blackbox"
    guest = decoded / "smali_classes3/io/github/leexeo/cage/space"
    replace(core / "fake/service/IConnectivityManagerProxy.smali",
            "Lio/github/leexeo/cage/space/GuestNetwork;->invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;",
            "Lio/github/leexeo/cage/space/IntegrityLabRuntime;->networkInvoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;")
    replace(core / "fake/service/IActivityManagerProxy.smali",
            "    :cond_4\n    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBPackageManager()",
            "    :cond_4\n"
            "    invoke-static {v2, v6}, Lio/github/leexeo/cage/space/IntegrityLabRuntime;->route(Landroid/content/Intent;I)Landroid/content/Intent;\n"
            "    move-result-object v2\n    const/4 v7, 0x2\n    aput-object v2, p2, v7\n"
            "    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBPackageManager()")
    marker = '    const-string v5, "com.anthropic.claude"\n'
    replace(guest / "GuestNetwork.smali", marker, marker +
            "\n    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/IntegrityLabRuntime;->componentGuest(Landroid/content/Context;Landroid/content/Context;)Z\n"
            "    move-result v6\n    if-nez v6, :goto_1\n")
    network = (guest / "GuestNetwork.smali").read_text(encoding="utf-8")
    start = network.index("    :try_start_1\n")
    end = network.index("    move-result-object v5", start) + len("    move-result-object v5")
    (guest / "GuestNetwork.smali").write_text(network[:start] +
        "    :try_start_1\n    invoke-static {p0}, Lio/github/leexeo/cage/space/SharedGateway;->status(Landroid/content/Context;)Landroid/os/Bundle;\n"
        "    move-result-object v5" + network[end:], encoding="utf-8", newline="\n")

    replace(core / "core/system/SystemCallProvider.smali", "    .locals 4\n",
            "    .locals 4\n\n"
            "    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/IntegrityLabRuntime;->call(Landroid/content/ContentProvider;Ljava/lang/String;)Landroid/os/Bundle;\n"
            "    move-result-object v0\n    if-eqz v0, :lab_continue\n    return-object v0\n    :lab_continue\n")
    # Use the existing refresh callback so controls survive screen refreshes.
    replace(guest / "SpaceActivity.smali", "    :cond_17\n    return-void",
            "    :cond_17\n"
            "    iget-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->content:Landroid/widget/LinearLayout;\n"
            "    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/IntegrityLabRuntime;->controls(Landroid/app/Activity;Landroid/widget/LinearLayout;)V\n"
            "    return-void")
    # The private identity service must know both new guests; unknown callers remain rejected.
    replace(guest / "GuestCallingUid.smali", "    .locals 4\n", "    .locals 6\n")
    replace(guest / "GuestCallingUid.smali", "    filled-new-array {v2, v3, v0, v1}, [Ljava/lang/String;",
            "    const-string v4, \"com.android.vending.mgc\"\n"
            "    const-string v5, \"io.github.leexeo.cage.integrityprobe\"\n"
            "    filled-new-array/range {v0 .. v5}, [Ljava/lang/String;")
    marker = ".method private static supported(Ljava/lang/String;)Z\n    .locals 1\n"
    replace(guest / "GuestPackageIdentity.smali", marker, marker +
            "\n    invoke-static {p0}, Lio/github/leexeo/cage/space/IntegrityLabRuntime;->extraPackage(Ljava/lang/String;)Z\n"
            "    move-result v0\n    if-eqz v0, :lab_original\n    return v0\n    :lab_original\n")
    return assets
