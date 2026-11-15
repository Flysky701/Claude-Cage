"""Opt-in fixed-stage diagnostics for the exact Privacy15 service sources.

The default operation validates and prints a plan. With --apply, patch only a
NEW copied decode tree under mobile/.build/gbox-mod. The original build cache,
APK, presets, authentication results and exception behavior are not modified.
Only classes4 sources are changed; the caller owns assembly/signing/install.
"""

import argparse
import hashlib
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
CACHE = ROOT / "mobile/.build/gbox-mod"
BASELINE = CACHE / "w74e50b5"
DEX_SHA256 = "5b6c96ec61b3eb0f3ace387e8ac27e125a851402ab291ddf1f0542406a5f81e8"
EXPECTED = {
    "com/vlite/sdk/client/k.smali": "bfa92cf74eed359faf580451479e12b4ef95ba8f5449f546a35d0350f444e8b6",
    "com/vlite/sdk/client/virtualservice/g$d.smali": "0c3ca5f3b23914efeed3d550ee5bc4d40ec442bbe9359349e6b10fae4147ac7b",
    "com/vlite/sdk/servicehook/utils/b.smali": "1ff9db7d8d59529b14d6bca0f01fbedcc528cae9aa3a6f24a36efeac7ba7739d",
    "com/vlite/sdk/client/hook/service/am/c$b.smali": "19d9946a45b1868940d1e72ae4274843c101f9d6c063619fae317cd3a95ef4e5",
}
HELPER = "Lio/github/leexeo/cage/gbox/ServiceDiag;"
HELPER_PATH = "io/github/leexeo/cage/gbox/ServiceDiag.smali"

# No static initializer: allocation and logging failures stay within diagnostic
# catch boundaries. The map does not keep service connections alive.
HELPER_SMALI = r'''.class public final Lio/github/leexeo/cage/gbox/ServiceDiag;
.super Ljava/lang/Object;

.field private static connections:Ljava/util/WeakHashMap;

.method public static matchesName(Ljava/lang/String;)Z
    .locals 1
    :try_start
    const-string v0, "org.microg.gms.droidguard.core.DroidGuardService"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :done
    const-string v0, "com.gbox.android.components.DGService"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    :done
    :try_end
    return v0
    :failed
    move-exception v0
    const/4 v0, 0x0
    return v0
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :failed
.end method

.method public static matchesInfo(Landroid/content/pm/ServiceInfo;)Z
    .locals 1
    :try_start
    if-eqz p0, :no
    iget-object v0, p0, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;
    invoke-static {v0}, Lio/github/leexeo/cage/gbox/ServiceDiag;->matchesName(Ljava/lang/String;)Z
    move-result v0
    :try_end
    return v0
    :failed
    move-exception v0
    :no
    const/4 v0, 0x0
    return v0
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :failed
.end method

.method public static matchesComponent(Landroid/content/ComponentName;)Z
    .locals 1
    :try_start
    if-eqz p0, :no
    invoke-virtual {p0}, Landroid/content/ComponentName;->getClassName()Ljava/lang/String;
    move-result-object v0
    invoke-static {v0}, Lio/github/leexeo/cage/gbox/ServiceDiag;->matchesName(Ljava/lang/String;)Z
    move-result v0
    :try_end
    return v0
    :failed
    move-exception v0
    :no
    const/4 v0, 0x0
    return v0
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :failed
.end method

.method public static markConnection(Ljava/lang/Object;Landroid/content/pm/ServiceInfo;)V
    .locals 3
    const-class v2, Lio/github/leexeo/cage/gbox/ServiceDiag;
    monitor-enter v2
    :try_start
    invoke-static {p1}, Lio/github/leexeo/cage/gbox/ServiceDiag;->matchesInfo(Landroid/content/pm/ServiceInfo;)Z
    move-result v0
    if-eqz v0, :done
    if-eqz p0, :done
    sget-object v0, Lio/github/leexeo/cage/gbox/ServiceDiag;->connections:Ljava/util/WeakHashMap;
    if-nez v0, :ready
    new-instance v0, Ljava/util/WeakHashMap;
    invoke-direct {v0}, Ljava/util/WeakHashMap;-><init>()V
    sput-object v0, Lio/github/leexeo/cage/gbox/ServiceDiag;->connections:Ljava/util/WeakHashMap;
    :ready
    sget-object v1, Ljava/lang/Boolean;->TRUE:Ljava/lang/Boolean;
    invoke-virtual {v0, p0, v1}, Ljava/util/WeakHashMap;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
    const-string v0, "bind.proxy.registered"
    invoke-static {v0}, Lio/github/leexeo/cage/gbox/ServiceDiag;->event(Ljava/lang/String;)V
    :try_end
    :done
    monitor-exit v2
    return-void
    :failed
    move-exception v0
    monitor-exit v2
    return-void
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :failed
.end method

.method public static matchesConnection(Ljava/lang/Object;Landroid/content/ComponentName;)Z
    .locals 2
    const-class v1, Lio/github/leexeo/cage/gbox/ServiceDiag;
    monitor-enter v1
    :try_start
    invoke-static {p1}, Lio/github/leexeo/cage/gbox/ServiceDiag;->matchesComponent(Landroid/content/ComponentName;)Z
    move-result v0
    if-nez v0, :done
    sget-object v0, Lio/github/leexeo/cage/gbox/ServiceDiag;->connections:Ljava/util/WeakHashMap;
    if-eqz v0, :no
    invoke-virtual {v0, p0}, Ljava/util/WeakHashMap;->containsKey(Ljava/lang/Object;)Z
    move-result v0
    goto :done
    :no
    const/4 v0, 0x0
    :try_end
    :done
    monitor-exit v1
    return v0
    :failed
    move-exception v0
    const/4 v0, 0x0
    monitor-exit v1
    return v0
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :failed
.end method

.method public static event(Ljava/lang/String;)V
    .locals 1
    :try_start
    const-string v0, "CageServiceDiag"
    invoke-static {v0, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end
    return-void
    :failed
    move-exception v0
    return-void
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :failed
.end method

.method public static result(Ljava/lang/String;Ljava/lang/Object;)V
    .locals 2
    :try_start
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0, p0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
    if-nez p1, :present
    const-string v1, " resultNull=true"
    goto :append
    :present
    const-string v1, " resultNull=false"
    :append
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    invoke-static {v0}, Lio/github/leexeo/cage/gbox/ServiceDiag;->event(Ljava/lang/String;)V
    :try_end
    return-void
    :failed
    move-exception v0
    return-void
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :failed
.end method
'''


def replace_once(source: str, old: str, new: str) -> str:
    if source.count(old) != 1:
        raise ValueError("Expected exactly one reviewed patch anchor")
    return source.replace(old, new, 1)


NULL_REASONS = {
    "applicationNotReady": "createService aborted: application is null or Application.onCreate did not complete -> ",
    "classNotFound": "    :catch_2\n    move-exception v0\n",
    "bindingNotReady": "createService aborted: app not bound yet (info=null) -> ",
}


def create_null_reasons(source: str) -> str:
    declaration = ".method public createService(Landroid/content/pm/ServiceInfo;Landroid/content/Intent;Landroid/os/IBinder;)Landroid/app/Service;"
    begin = source.index(declaration)
    end = source.index(".end method", begin)
    method = source[begin:end]
    if method.count("    .locals 16\n") != 1 or method.count("    return-object v3\n") != 3:
        raise ValueError("Unreviewed createService register/null-return shape")
    # p1 is v17 with .locals 16. Neither name is an instruction destination
    # in this reviewed method, so every reason helper receives the original
    # ServiceInfo. invoke-static/range handles this high parameter register.
    for line in method.splitlines():
        match = re.match(r"\s*([a-z][\w/-]*)\s+(p1|v17)\b", line)
        if match and not match[1].startswith(("if-", "return", "throw", "monitor-", "iput", "sput", "aput")):
            raise ValueError("createService may write its ServiceInfo parameter")
    for reason, anchor in NULL_REASONS.items():
        if method.count(anchor) != 1:
            raise ValueError("Expected one reviewed createService null-reason branch")
        start = method.index(anchor)
        position = method.index("    return-object v3\n", start)
        helper = f"    invoke-static/range {{p1 .. p1}}, {HELPER}->null_{reason}(Landroid/content/pm/ServiceInfo;)V\n"
        method = method[:position] + helper + method[position:]
    return source[:begin] + method + source[end:]


def null_reason_helpers() -> str:
    methods = []
    for reason in NULL_REASONS:
        methods.append(f'''
.method public static null_{reason}(Landroid/content/pm/ServiceInfo;)V
    .locals 1
    :try_start
    invoke-static {{p0}}, {HELPER}->matchesInfo(Landroid/content/pm/ServiceInfo;)Z
    move-result v0
    if-eqz v0, :done
    const-string v0, "create.null.{reason}"
    invoke-static {{v0}}, {HELPER}->event(Ljava/lang/String;)V
    :try_end
    :done
    return-void
    :failed
    move-exception v0
    return-void
    .catch Ljava/lang/Throwable; {{:try_start .. :try_end}} :failed
.end method
''')
    return "".join(methods)


def wrap(source, owner, name, signature, renamed, selection, arguments, stage, returns_object):
    declaration = f".method public {name}{signature}"
    if f" {renamed}{signature}" in source:
        raise ValueError("Diagnostic wrapper name already exists")
    begin = source.index(declaration)
    end = source.index(".end method", begin)
    annotations = "".join(re.findall(r"(?ms)^    \.annotation\b.*?^    \.end annotation\n", source[begin:end]))
    source = replace_once(source, declaration, f".method public {renamed}{signature}")
    before = (
        f'    const-string v1, "{stage}.enter"\n'
        f"    invoke-static {{v1}}, {HELPER}->event(Ljava/lang/String;)V\n"
        if returns_object else
        f'    const-string v1, "{stage}.enter.binder"\n'
        f"    invoke-static {{v1, p2}}, {HELPER}->result(Ljava/lang/String;Ljava/lang/Object;)V\n"
    )
    call = f"    invoke-virtual {{{arguments}}}, {owner}->{renamed}{signature}\n"
    if returns_object:
        call += "    move-result-object v1\n"
        after = (f'    const-string v2, "{stage}.return"\n'
                 f"    invoke-static {{v2, v1}}, {HELPER}->result(Ljava/lang/String;Ljava/lang/Object;)V\n")
        ret = "    return-object v1\n"
    else:
        after = (f'    const-string v1, "{stage}.return"\n'
                 f"    invoke-static {{v1}}, {HELPER}->event(Ljava/lang/String;)V\n")
        ret = "    return-void\n"
    source += (
        f"\n{declaration}\n    .locals 3\n{annotations}{selection}"
        "    move-result v0\n    if-eqz v0, :original\n" + before +
        "    :original\n    :try_start\n" + call +
        "    :try_end\n    if-eqz v0, :done\n" + after +
        "    :done\n" + ret +
        "    :failed\n    move-exception v1\n    if-eqz v0, :rethrow\n"
        f'    const-string v2, "{stage}.throw"\n'
        f"    invoke-static {{v2}}, {HELPER}->event(Ljava/lang/String;)V\n"
        "    :rethrow\n    throw v1\n"
        "    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :failed\n.end method\n"
    )
    return source


def prepare(decoded: Path, source_dex: Path):
    if hashlib.sha256(source_dex.read_bytes()).hexdigest() != DEX_SHA256:
        raise ValueError("Source DEX is not the reviewed Privacy15 classes4.dex")
    smali = decoded / "smali_classes4"
    result = {}
    for relative, expected in EXPECTED.items():
        path = smali / relative
        raw = path.read_bytes()
        if hashlib.sha256(raw).hexdigest() != expected:
            raise ValueError(f"Unreviewed source shape: {relative}")
        result[relative] = raw.decode("utf-8").replace("\r\n", "\n")
    if (smali / HELPER_PATH).exists():
        raise ValueError("ServiceDiag helper already exists")

    name = "com/vlite/sdk/client/k.smali"
    result[name] = create_null_reasons(result[name])
    result[name] = wrap(
        result[name], "Lcom/vlite/sdk/client/k;", "createService",
        "(Landroid/content/pm/ServiceInfo;Landroid/content/Intent;Landroid/os/IBinder;)Landroid/app/Service;",
        "cageServiceDiagOriginalCreateService",
        f"    invoke-static {{p1}}, {HELPER}->matchesInfo(Landroid/content/pm/ServiceInfo;)Z\n",
        "p0, p1, p2, p3", "create", True,
    )
    name = "com/vlite/sdk/client/virtualservice/g$d.smali"
    result[name] = wrap(
        result[name], "Lcom/vlite/sdk/client/virtualservice/g$d;", "onBind",
        "(Landroid/app/IServiceConnection;Landroid/content/Intent;)Landroid/os/IBinder;",
        "cageServiceDiagOriginalOnBind",
        "    iget-object v1, p0, Lcom/vlite/sdk/client/virtualservice/g$d;->component:Landroid/content/ComponentName;\n"
        f"    invoke-static {{v1}}, {HELPER}->matchesComponent(Landroid/content/ComponentName;)Z\n",
        "p0, p1, p2", "service.bind", True,
    )
    name = "com/vlite/sdk/servicehook/utils/b.smali"
    for signature, arguments, stage in [
        ("(Landroid/content/ComponentName;Landroid/os/IBinder;Z)V", "p0, p1, p2, p3", "connected3"),
        ("(Landroid/content/ComponentName;Landroid/os/IBinder;Landroid/app/IBinderSession;Z)V",
         "p0, p1, p2, p3, p4", "connected4"),
    ]:
        result[name] = wrap(
            result[name], "Lcom/vlite/sdk/servicehook/utils/b;", "connected", signature,
            "cageServiceDiagOriginalConnected",
            f"    invoke-static {{p0, p1}}, {HELPER}->matchesConnection(Ljava/lang/Object;Landroid/content/ComponentName;)Z\n",
            arguments, stage, False,
        )
    name = "com/vlite/sdk/client/hook/service/am/c$b.smali"
    anchor = (
        "    invoke-static {v13}, Lcom/vlite/sdk/client/hook/utils/a;->getOrCreateProxy(Landroid/app/IServiceConnection;)Lcom/vlite/sdk/servicehook/utils/b;\n"
        "\n    move-result-object v4\n"
    )
    result[name] = replace_once(
        result[name], anchor,
        anchor + f"    invoke-static {{v4, v15}}, {HELPER}->markConnection(Ljava/lang/Object;Landroid/content/pm/ServiceInfo;)V\n",
    )
    result[HELPER_PATH] = HELPER_SMALI + null_reason_helpers()
    return {smali / relative: source for relative, source in result.items()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--decoded", required=True, type=Path, help="Copied Privacy15 decode tree (containing smali_classes4)")
    parser.add_argument("--source-dex", type=Path, default=BASELINE / "classes4.dex")
    parser.add_argument("--apply", action="store_true", help="Apply to the new cache copy; otherwise validate only")
    args = parser.parse_args()
    decoded = args.decoded.resolve()
    changes = prepare(decoded, args.source_dex.resolve())
    if args.apply:
        if not decoded.is_relative_to(CACHE.resolve()) or decoded == (BASELINE / "d").resolve():
            raise ValueError("Apply requires a new copied decode tree inside the project gbox-mod cache")
        for path in changes:
            if not path.resolve().is_relative_to(decoded):
                raise ValueError("Patch target escapes the copied decode tree")
        for path, source in changes.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(source, encoding="utf-8", newline="\n")
    print(json.dumps({
        "mode": "applied" if args.apply else "validated_read_only",
        "sourceDexSha256": DEX_SHA256,
        "tag": "CageServiceDiag",
        "targetClassNames": ["org.microg.gms.droidguard.core.DroidGuardService", "com.gbox.android.components.DGService"],
        "changedSources": [str(path.relative_to(decoded)) for path in changes],
        "outputFields": ["fixed_stage", "resultNull_boolean"],
        "normalNullReturnReasons": list(NULL_REASONS),
        "originalReturnValuesAndThrownObjectsPreserved": True,
        "presetsModified": False,
        "installed": False,
        "deviceValidation": "NOT_RUN",
    }, indent=2))


if __name__ == "__main__":
    main()
