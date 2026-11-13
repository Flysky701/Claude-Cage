"""Adapt the pinned shell's account service to the isolated guest space."""
from pathlib import Path
import re
from subprocess import run
from zipfile import ZipFile


def replace_method(source, signature, body):
    start_marker = ".method public " + signature + "\n"
    if source.count(start_marker) != 1:
        raise ValueError("Unexpected BlackBox method: " + signature)
    start = source.index(start_marker) + len(start_marker)
    end = source.index(".end method", start)
    return source[:start] + body + "\n" + source[end:]


def account_runtime(base, work, java, apktool):
    # Only rebuild the primary dex. Resources, native libraries and manifests keep their IDs.
    source_apk = work / "primary.apk"
    with ZipFile(base) as old, ZipFile(source_apk, "w") as archive:
        archive.writestr("classes.dex", old.read("classes.dex"))
        archive.writestr("AndroidManifest.xml", old.read("AndroidManifest.xml"))
    decoded = work / "primary"
    run([java, "-jar", apktool, "d", "-r", "-o", decoded, source_apk], check=True)
    root = decoded / "smali/top/niunaijun/blackbox"
    accounts = root / "core/system/accounts/BAccountManagerService.smali"
    source = accounts.read_text(encoding="utf-8")
    source = replace_method(source, "getAuthenticatorTypes(I)[Landroid/accounts/AuthenticatorDescription;", """    .locals 1
    invoke-static {}, Landroid/os/Binder;->getCallingPid()I
    move-result v0
    invoke-static {p1, v0}, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes;->forCaller(II)[Landroid/accounts/AuthenticatorDescription;
    move-result-object v0
    return-object v0""")
    # The authenticator transport is one-way. A denied transaction cannot complete
    # the caller's AccountManagerFuture. Return an explicit error before opening a session.
    add = "addAccount(Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;ZLandroid/os/Bundle;I)V"
    anchor = ".method public " + add + "\n    .locals 15\n"
    if source.count(anchor) != 1:
        raise ValueError("Unexpected BlackBox addAccount implementation")
    source = source.replace(anchor, anchor + """
    if-eqz p1, :normal_add
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mContext:Landroid/content/Context;
    move-object/from16 v1, p2
    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes;->cannotAddAccount(Landroid/content/Context;Ljava/lang/String;)Z
    move-result v0
    if-eqz v0, :normal_add
    const-string v0, "Cage cannot call the Google account authenticator on this Android version"
    sget v1, Landroid/accounts/AccountManager;->ERROR_CODE_UNSUPPORTED_OPERATION:I
    move-object/from16 v2, p1
    invoke-interface {v2, v1, v0}, Landroid/accounts/IAccountManagerResponse;->onError(ILjava/lang/String;)V
    return-void
  :normal_add
""")
    accounts.write_text(source, encoding="utf-8", newline="\n")
    # These public two-step APIs have no guest implementation in the pinned release.
    # Without a guest hook the generic dispatcher forwards them to Android's personal store.
    proxy = root / "fake/service/IAccountManagerProxy.smali"
    source = proxy.read_text(encoding="utf-8")
    hook_class = "Lio/github/leexeo/cage/space/UnsupportedAccountSession;"
    hook_file = decoded / "smali" / (hook_class[1:-1] + ".smali")
    hook_file.parent.mkdir(parents=True, exist_ok=True)
    hook_file.write_text(f""".class public final {hook_class}
.super Ltop/niunaijun/blackbox/fake/hook/MethodHook;

.method public constructor <init>()V
    .locals 0
    invoke-direct {{p0}}, Ltop/niunaijun/blackbox/fake/hook/MethodHook;-><init>()V
    return-void
.end method

.method public hook(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 3
    const/4 v0, 0x0
    aget-object v0, p3, v0
    check-cast v0, Landroid/accounts/IAccountManagerResponse;
    if-eqz v0, :missing_response
    sget v1, Landroid/accounts/AccountManager;->ERROR_CODE_UNSUPPORTED_OPERATION:I
    const-string v2, "Cage does not support account sessions in this space"
    invoke-interface {{v0, v1, v2}}, Landroid/accounts/IAccountManagerResponse;->onError(ILjava/lang/String;)V
    const/4 v0, 0x0
    return-object v0
  :missing_response
    new-instance v0, Ljava/lang/IllegalArgumentException;
    const-string v1, "response is null"
    invoke-direct {{v0, v1}}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
    throw v0
.end method
""", encoding="utf-8", newline="\n")
    bind = """    .locals 2
    invoke-super {p0}, Ltop/niunaijun/blackbox/fake/hook/BinderInvocationStub;->onBindMethod()V
"""
    bind += f"    new-instance v0, {hook_class}\n    invoke-direct {{v0}}, {hook_class}-><init>()V\n"
    for name in ("startAddAccountSession", "startUpdateCredentialsSession", "finishSessionAsUser"):
        bind += f'    const-string v1, "{name}"\n'
        bind += "    invoke-virtual {p0, v1, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ljava/lang/String;Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V\n"
    source = replace_method(source, "onBindMethod()V", bind + "    return-void")
    proxy.write_text(source, encoding="utf-8", newline="\n")
    # Android 16 authenticates the caller package even for an ordinary same-user policy
    # query. Attribute it to the shell's real, unprivileged UID. Preserve Android's user,
    # parent flag, actual policy result and any permission error.
    policy = root / "fake/service/IDevicePolicyManagerProxy.smali"
    source = policy.read_text(encoding="utf-8")
    signature = "invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;"
    if ".method public " + signature in source:
        raise ValueError("Unexpected device-policy proxy implementation")
    source += """
.method public invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 2
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;
    move-result-object v0
    const-string v1, "getAccountTypesWithManagementDisabledAsUser"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :forward
    if-eqz p3, :forward
    array-length v0, p3
    const/4 v1, 0x3
    if-ne v0, v1, :forward
    const/4 v1, 0x1
    aget-object v0, p3, v1
    instance-of v0, v0, Ljava/lang/String;
    if-eqz v0, :forward
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostPkg()Ljava/lang/String;
    move-result-object v0
    aput-object v0, p3, v1
  :forward
    invoke-super {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/fake/hook/BinderInvocationStub;->invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v0
    return-object v0
.end method
"""
    policy.write_text(source, encoding="utf-8", newline="\n")
    hooks = root / "fake/hook/HookManager.smali"
    source = hooks.read_text(encoding="utf-8")
    # Keep the per-user account service; omit only the three demonstration hooks.
    for name in ("GmsProxy", "GoogleAccountManagerProxy", "AuthenticationProxy"):
        cls = "Ltop/niunaijun/blackbox/fake/service/" + name + ";"
        pattern = (r"(?m)^    new-instance (v\d+), " + cls + r"\n(?:\s*\.line \d+\n|\s*\n)*"
                   r"    invoke-direct \{\1\}, " + cls + r"-><init>\(\)V\n(?:\s*\.line \d+\n|\s*\n)*"
                   r"    invoke-virtual \{p0, \1\}, Ltop/niunaijun/blackbox/fake/hook/HookManager;->addInjector\([^)]+\)V\n")
        source, count = re.subn(pattern, "", source)
        if count != 1:
            raise ValueError("Unexpected registration of " + name)
    hooks.write_text(source, encoding="utf-8", newline="\n")
    assembler = Path(__file__).with_name("AssembleSpaceDex.java").resolve()
    dex = work / "account-runtime.dex"
    run([java, "--class-path", apktool, assembler, decoded / "smali", dex], check=True)
    return dex.read_bytes()
