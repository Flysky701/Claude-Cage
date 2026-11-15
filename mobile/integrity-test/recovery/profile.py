"""Build-only support for the owner's exact signed test app in the recovery copy."""
import re

PACKAGE = "io.github.flysky701.integritytest"
SIGNER = "6f364045cb06dc86bd1eaba22f81799fc5dda403c172b9789cd7fb72471be3bc"
RUNTIME = "Lio/github/leexeo/cage/space/OwnedIntegrityTest;"


def replace(path, old, new):
    text = path.read_text(encoding="utf-8")
    if text.count(old) != 1:
        raise ValueError("Owned test integration point changed: " + path.name)
    path.write_text(text.replace(old, new), encoding="utf-8", newline="\n")


def prepare(decoded, args, tools, env, run):
    apk = args.owned_integrity_test_apk.resolve()
    certs = run(tools / "apksigner.bat", "verify", "--print-certs", apk, env=env)
    actual = re.findall(r"^Signer #\d+ certificate SHA-256 digest: (\w+)\r?$", certs, re.M)
    badging = run(tools / "aapt2.exe", "dump", "badging", apk)
    if actual != [SIGNER] or not badging.startswith("package: name='" + PACKAGE + "' versionCode='1'"):
        raise ValueError("Unexpected test app package, version or signing certificate")
    guest = decoded / "smali_classes3/io/github/leexeo/cage/space"
    marker = '    const-string v5, "com.anthropic.claude"\n'
    replace(guest / "GuestNetwork.smali", marker, marker +
            "\n    invoke-static {p0, p1}, " + RUNTIME + "->verifiedGuest(Landroid/content/Context;Landroid/content/Context;)Z\n"
            "    move-result v6\n    if-nez v6, :goto_1\n")
    marker = '    const-string v2, "io.github.leexeo.cage.stablenet"'
    replace(guest / "GuestNetwork.smali", marker,
            "    invoke-static {v1}, " + RUNTIME + "->isOwn(Ljava/lang/Object;)Z\n"
            "    move-result v2\n    if-nez v2, :cond_1\n\n" + marker)
    marker = ".method private static supported(Ljava/lang/String;)Z\n    .locals 1\n"
    replace(guest / "GuestPackageIdentity.smali", marker, marker +
            "\n    invoke-static {p0}, " + RUNTIME + "->isOwn(Ljava/lang/Object;)Z\n"
            "    move-result v0\n    if-eqz v0, :owned_original\n    return v0\n    :owned_original\n")
    replace(guest / "GuestCallingUid.smali", "    .locals 4\n", "    .locals 5\n")
    replace(guest / "GuestCallingUid.smali", "    filled-new-array {v2, v3, v0, v1}, [Ljava/lang/String;",
            '    const-string v4, "' + PACKAGE + '"\n'
            "    filled-new-array {v2, v3, v0, v1, v4}, [Ljava/lang/String;")
    # Use the existing Binder compatibility adapter; request and response bytes are untouched.
    replace(guest / "GuestIntegrityTransport.smali",
            "    invoke-virtual {v0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z\n\n    move-result v0",
            "    invoke-static {v2}, " + RUNTIME + "->integrityClient(Ljava/lang/Object;)Z\n\n    move-result v0")
    replace(guest / "SpaceActivity.smali", "    :cond_17\n    return-void",
            "    :cond_17\n"
            "    iget-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->content:Landroid/widget/LinearLayout;\n"
            "    invoke-static {p0, p1}, " + RUNTIME + "->controls(Landroid/app/Activity;Landroid/widget/LinearLayout;)V\n"
            "    return-void")
    return {"assets/owned-integrity/test.apk": apk}
