"""Fixed-label diagnostic markers; no native hooks or return values are changed."""
import json
from pathlib import Path
import re


TRACE = "Lio/github/leexeo/cage/gbox/NativeTrace;"


def apply(decoded, work, host_package="com.cage.android", asset_paths=False):
    core = Path(decoded) / "smali_classes4/com/vlite/sdk"
    methods, records = [], []

    def marker(label):
        name = "stage" + str(len(methods))
        methods.append((name, label))
        return "    invoke-static {}, " + TRACE + "->" + name + "()V\n"

    def instrument(path, targets, make_application=False):
        lines = path.read_text("utf-8").splitlines(keepends=True)
        before, after = {}, {}
        for needle, label in targets:
            hits = [i for i, line in enumerate(lines) if line.strip().startswith("invoke-") and needle in line]
            if not hits:
                raise ValueError("Native diagnostic boundary absent: " + label)
            records.append({"source": str(path.relative_to(decoded)), "boundary": label, "sites": len(hits)})
            enter, leave = marker("before." + label), marker("after." + label)
            for index in hits:
                before.setdefault(index, []).append(enter)
                following = index + 1
                while following < len(lines) and (not lines[following].strip() or lines[following].lstrip().startswith(".line")):
                    following += 1
                finish = following if following < len(lines) and lines[following].lstrip().startswith("move-result") else index
                after.setdefault(finish, []).append(leave)
                if label == "startIobox":
                    result = re.fullmatch(r"\s*move-result ([vp]\d+)\s*", lines[finish])
                    if not result:
                        raise ValueError("I/O initialization result register was not found")
                    after[finish].append("    invoke-static {" + result[1] + "}, " + TRACE + "->ioboxResult(I)V\n")
        if make_application:
            start = next(i for i, line in enumerate(lines) if "->makeApplication:" in line)
            finish = next(i for i in range(start, len(lines)) if "->invokeWithException(" in lines[i])
            before.setdefault(finish, []).append(marker("before.makeApplication"))
            result = next(i for i in range(finish + 1, len(lines)) if lines[i].lstrip().startswith("move-result-object"))
            after.setdefault(result, []).append(marker("after.makeApplication"))
            records.append({"source": str(path.relative_to(decoded)), "boundary": "makeApplication", "sites": 1})
        output = []
        for index, line in enumerate(lines):
            output.extend(before.get(index, []))
            output.append(line)
            output.extend(after.get(index, []))
        path.write_text("".join(output), encoding="utf-8", newline="\n")

    instrument(core / "jni/Native.smali", [
        ("Ljava/lang/System;->loadLibrary(", "loadLibrary"),
        ("Ljava/lang/System;->load(", "loadFile"),
        ("->start_fp_with_arr(", "startFp"),
        ("->start_iobox_with_error(", "startIobox"),
    ])
    instrument(core / "client/k.smali", [
        ("Lcom/vlite/sdk/jni/Native;->i(", "guestNativeInit"),
        ("Lcom/vlite/sdk/jni/Native;->b(", "guestIobox"),
        ("Landroid/content/Context;->createPackageContext(", "createPackageContext"),
        ("Landroid/app/Instrumentation;->callApplicationOnCreate(", "callApplicationOnCreate"),
    ], make_application=True)
    if asset_paths:
        context_path = core / "client/k.smali"
        source = context_path.read_text("utf-8")
        boundary = "    invoke-virtual {v6, v14, v15}, Landroid/content/Context;->createPackageContext(Ljava/lang/String;I)Landroid/content/Context;"
        if source.count(boundary) != 1:
            raise ValueError("Expected the unique bindApplication Context boundary")
        bind_type = (core / "client/k$d.smali").read_text("utf-8")
        producer = ("    invoke-virtual {v1, v2, v12}, Lcom/vlite/sdk/client/k;->S0(Ljava/lang/String;Ljava/lang/String;)Lcom/vlite/sdk/client/k$d;\n\n"
                    "    move-result-object v13")
        if (".field public c:Landroid/content/pm/ApplicationInfo;" not in bind_type
                or source.count(producer) != 1 or source.index(producer) >= source.index(boundary)):
            raise ValueError("Context diagnostic bindData type/field/source changed")
        source = source.replace(boundary,
                "    invoke-static {v6, v13}, Lio/github/leexeo/cage/gbox/AssetPathTrace;->beforeContext(Landroid/content/Context;Ljava/lang/Object;)V\n"
                + boundary)
        context_path.write_text(source, encoding="utf-8", newline="\n")
    map_path = core / "i.smali"
    source = map_path.read_text("utf-8")
    pattern = r"(?m)^    invoke-static \{(p0), (p1|v2)\}, Lcom/vlite/sdk/jni/Native;->mapPidSelfFile\(Ljava/lang/String;Z\)V$"
    bridge = "Lio/github/leexeo/cage/gbox/MapPidTrace;"
    def map_markers(match):
        arguments = "{" + match[1] + ", " + match[2] + "}"
        return ("    invoke-static " + arguments + ", " + bridge + "->before(Ljava/lang/String;Z)V\n"
                + match[0] + "\n"
                + "    invoke-static " + arguments + ", " + bridge + "->after(Ljava/lang/String;Z)V")
    source, map_sites = re.subn(pattern, map_markers, source)
    if map_sites != 2:
        raise ValueError("Expected two native PID-map boundaries")
    map_path.write_text(source, encoding="utf-8", newline="\n")
    records.append({"source": str(map_path.relative_to(decoded)), "boundary": "mapPidSelfFile", "sites": map_sites})
    numbers = [1]
    for path in Path(decoded).glob("smali_classes*"):
        match = re.fullmatch(r"smali_classes(\d+)", path.name)
        if match:
            numbers.append(int(match[1]))
    number = max(numbers) + 1
    output = Path(decoded) / f"smali_classes{number}/io/github/leexeo/cage/gbox/NativeTrace.smali"
    output.parent.mkdir(parents=True)
    text = ".class public final " + TRACE + "\n.super Ljava/lang/Object;\n"
    for name, label in methods:
        text += ("\n.method public static " + name + "()V\n    .locals 2\n"
                 '    const-string v0, "CageNativeTrace"\n'
                 '    const-string v1, "' + label + '"\n'
                 "    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I\n"
                 "    return-void\n.end method\n")
    text += ("\n.method public static ioboxResult(I)V\n    .locals 2\n"
             "    new-instance v0, Ljava/lang/StringBuilder;\n"
             "    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V\n"
             '    const-string v1, "startIobox.returnCode="\n'
             "    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;\n"
             "    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;\n"
             "    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;\n"
             "    move-result-object v0\n"
             '    const-string v1, "CageNativeTrace"\n'
             "    invoke-static {v1, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I\n"
             "    return-void\n.end method\n")
    output.write_text(text, encoding="utf-8", newline="\n")
    template = Path(__file__).resolve().parent / "diagnostics/MapPidTrace.smali"
    if host_package not in ("com.gbox.android", "com.cage.android"):
        raise ValueError("Unknown diagnostic host package")
    output.with_name("MapPidTrace.smali").write_text(
        template.read_text("utf-8").replace("@HOST_PACKAGE@", host_package), encoding="utf-8", newline="\n")
    metadata = {"fixedLabelsBooleansCountsReturnCodesAndExceptionTypesOnly": True, "nativeCallsPreserved": True,
                "sensitiveParametersLogged": False, "pathsLogged": False,
                "exceptionMessagesLogged": False,
                "mapPidObservations": ["creator", "hostPathMatches", "exists", "readable", "writable", "parentDirectory", "parentWritable"],
                "boundaries": records, "startFpBoolean": "is ART; not is64bit",
                "ioboxReturnCodeObserved": True, "ioboxReturnDoesNotProveHooksInstalled": True,
                "readOnlyAssetPathDiagnostic": asset_paths}
    (Path(work) / "native-trace.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    return {"smali_classes4", f"smali_classes{number}"}, metadata
