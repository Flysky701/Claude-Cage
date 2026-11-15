"""Account query/save diagnostics and Google account visibility fix for GBox virtual AccountManager."""
import json
from pathlib import Path


DIAG = "Lio/github/leexeo/cage/gbox/AccountDiag;"
CLIENT_ACCOUNTS = "Lcom/vlite/sdk/client/virtualservice/accounts/a;"
SERVER_ACCOUNTS = "Lcom/vlite/sdk/server/virtualservice/accounts/a;"


def _replace_once(text: str, target: str, replacement: str, label: str) -> str:
    hits = text.count(target)
    if hits != 1:
        raise ValueError(f"Expected 1 occurrence of {label}, found {hits}")
    return text.replace(target, replacement, 1)


def _patch_method_body(text: str, method_header: str, patch_fn, label: str) -> str:
    start = text.find(method_header)
    if start < 0 or text.count(method_header) != 1:
        raise ValueError(f"Expected unique method header for {label}: {method_header}")
    end_marker = "\n.end method"
    end = text.find(end_marker, start)
    if end < 0:
        raise ValueError(f"Missing .end method for {label}")
    end += len(end_marker)
    body = text[start:end]
    patched = patch_fn(body)
    return text[:start] + patched + text[end:]


def _wrap_method(text: str, old_header: str, orig_header: str, wrapper: str, label: str) -> str:
    return _replace_once(text, old_header, wrapper.rstrip() + "\n\n" + orig_header, label)


def apply(decoded, work, host_package="com.cage.android"):
    decoded_dir = Path(decoded)
    diag_smali = decoded_dir / "smali_classes7/io/github/leexeo/cage/gbox/AccountDiag.smali"
    if not diag_smali.is_file():
        raise FileNotFoundError(
            f"AccountDiag.smali missing at {diag_smali}; build with --identity coexist so java/ sources compile"
        )

    client_path = decoded_dir / "smali_classes4/com/vlite/sdk/client/virtualservice/accounts/a.smali"
    server_path = decoded_dir / "smali_classes4/com/vlite/sdk/server/virtualservice/accounts/a.smali"
    if not client_path.is_file() or not server_path.is_file():
        raise FileNotFoundError("Missing virtual account smali targets under smali_classes4")

    # 1. Client accounts/a.smali: wrap S(String, String) and log S.catch
    client_text = client_path.read_text("utf-8").replace("\r\n", "\n")
    s_old = ".method public S(Ljava/lang/String;Ljava/lang/String;)[Landroid/accounts/Account;"
    s_orig = ".method private cageOriginalS(Ljava/lang/String;Ljava/lang/String;)[Landroid/accounts/Account;"
    s_wrap = (
        f"{s_old}\n"
        "    .locals 1\n\n"
        f"    invoke-direct {{p0, p1, p2}}, {CLIENT_ACCOUNTS}->cageOriginalS(Ljava/lang/String;Ljava/lang/String;)[Landroid/accounts/Account;\n\n"
        "    move-result-object v0\n\n"
        f"    invoke-static {{p1, p2, v0}}, {DIAG}->logS(Ljava/lang/String;Ljava/lang/String;[Landroid/accounts/Account;)V\n\n"
        "    return-object v0\n"
        ".end method"
    )
    client_text = _wrap_method(client_text, s_old, s_orig, s_wrap, "client.accounts.a.S")
    client_text = _patch_method_body(
        client_text,
        s_orig,
        lambda body: _replace_once(
            body,
            "    :catch_0\n    move-exception p1\n",
            "    :catch_0\n    move-exception p1\n\n"
            f"    invoke-static {{p1}}, {DIAG}->logSCatch(Ljava/lang/Throwable;)V\n",
            "client.accounts.a.S.catch_0",
        ),
        "client.accounts.a.cageOriginalS",
    )
    with client_path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(client_text)

    # 2. Server accounts/a.smali: wrap z, O, t0, V0, t (+branches), x1, Y (+catch_0)
    server_text = server_path.read_text("utf-8").replace("\r\n", "\n")

    z_old = ".method public final z(IILjava/lang/String;)Ljava/util/List;"
    z_orig = ".method private cageOriginalZ(IILjava/lang/String;)Ljava/util/List;"
    z_wrap = (
        f"{z_old}\n"
        "    .locals 1\n\n"
        f"    invoke-direct {{p0, p1, p2, p3}}, {SERVER_ACCOUNTS}->cageOriginalZ(IILjava/lang/String;)Ljava/util/List;\n\n"
        "    move-result-object v0\n\n"
        f"    invoke-static {{p1, p2, p3, v0}}, {DIAG}->logZ(IILjava/lang/String;Ljava/util/List;)V\n\n"
        "    return-object v0\n"
        ".end method"
    )
    server_text = _wrap_method(server_text, z_old, z_orig, z_wrap, "server.accounts.a.z")

    o_old = ".method public O(Landroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;Ljava/util/Map;)Z"
    o_orig = ".method private cageOriginalO(Landroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;Ljava/util/Map;)Z"
    o_wrap = (
        f"{o_old}\n"
        "    .locals 1\n\n"
        f"    invoke-direct {{p0, p1, p2, p3, p4}}, {SERVER_ACCOUNTS}->cageOriginalO(Landroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;Ljava/util/Map;)Z\n\n"
        "    move-result v0\n\n"
        f"    invoke-static {{p1, p3, p4, v0}}, {DIAG}->logO(Landroid/accounts/Account;Landroid/os/Bundle;Ljava/util/Map;Z)V\n\n"
        "    return v0\n"
        ".end method"
    )
    server_text = _wrap_method(server_text, o_old, o_orig, o_wrap, "server.accounts.a.O")

    t0_old = ".method public final t0(Lcom/vlite/sdk/server/virtualservice/accounts/f;Landroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;ILjava/util/Map;)Z"
    t0_orig = ".method private cageOriginalT0(Lcom/vlite/sdk/server/virtualservice/accounts/f;Landroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;ILjava/util/Map;)Z"
    t0_wrap = (
        f"{t0_old}\n"
        "    .locals 1\n\n"
        f"    invoke-direct/range {{p0 .. p6}}, {SERVER_ACCOUNTS}->cageOriginalT0(Lcom/vlite/sdk/server/virtualservice/accounts/f;Landroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;ILjava/util/Map;)Z\n\n"
        "    move-result v0\n\n"
        f"    invoke-static {{p2, p5, p6, v0}}, {DIAG}->logT0(Landroid/accounts/Account;ILjava/util/Map;Z)V\n\n"
        "    return v0\n"
        ".end method"
    )
    server_text = _wrap_method(server_text, t0_old, t0_orig, t0_wrap, "server.accounts.a.t0")

    v0_old = ".method public final V0(Ljava/lang/String;ILjava/lang/String;ILjava/lang/String;Z)[Landroid/accounts/Account;"
    v0_orig = ".method private cageOriginalV0(Ljava/lang/String;ILjava/lang/String;ILjava/lang/String;Z)[Landroid/accounts/Account;"
    v0_wrap = (
        f"{v0_old}\n"
        "    .locals 7\n\n"
        f"    invoke-direct/range {{p0 .. p6}}, {SERVER_ACCOUNTS}->cageOriginalV0(Ljava/lang/String;ILjava/lang/String;ILjava/lang/String;Z)[Landroid/accounts/Account;\n\n"
        "    move-result-object v6\n\n"
        "    move-object v0, p1\n\n"
        "    move v1, p2\n\n"
        "    move-object v2, p3\n\n"
        "    move v3, p4\n\n"
        "    move-object v4, p5\n\n"
        "    move v5, p6\n\n"
        f"    invoke-static/range {{v0 .. v6}}, {DIAG}->logV0(Ljava/lang/String;ILjava/lang/String;ILjava/lang/String;Z[Landroid/accounts/Account;)V\n\n"
        "    return-object v6\n"
        ".end method"
    )
    server_text = _wrap_method(server_text, v0_old, v0_orig, v0_wrap, "server.accounts.a.V0")

    t_old = ".method public t(Lcom/vlite/sdk/server/virtualservice/accounts/f;Ljava/lang/String;ILjava/lang/String;Z)[Landroid/accounts/Account;"
    t_orig = ".method private cageOriginalT(Lcom/vlite/sdk/server/virtualservice/accounts/f;Ljava/lang/String;ILjava/lang/String;Z)[Landroid/accounts/Account;"
    t_wrap = (
        f"{t_old}\n"
        "    .locals 1\n\n"
        f"    invoke-direct/range {{p0 .. p5}}, {SERVER_ACCOUNTS}->cageOriginalT(Lcom/vlite/sdk/server/virtualservice/accounts/f;Ljava/lang/String;ILjava/lang/String;Z)[Landroid/accounts/Account;\n\n"
        "    move-result-object v0\n\n"
        f"    invoke-static {{p2, p3, p4, p5, v0}}, {DIAG}->logT(Ljava/lang/String;ILjava/lang/String;Z[Landroid/accounts/Account;)V\n\n"
        "    return-object v0\n"
        ".end method"
    )
    server_text = _wrap_method(server_text, t_old, t_orig, t_wrap, "server.accounts.a.t")

    def _patch_t_branches(body: str) -> str:
        body = _replace_once(
            body,
            "    if-nez p2, :cond_0\n\n    .line 5\n    sget-object p1, Lcom/vlite/sdk/server/virtualservice/accounts/a;->n:[Landroid/accounts/Account;",
            "    if-nez p2, :cond_0\n\n"
            f"    invoke-static {{}}, {DIAG}->logTNullTypeMap()V\n\n"
            "    .line 5\n    sget-object p1, Lcom/vlite/sdk/server/virtualservice/accounts/a;->n:[Landroid/accounts/Account;",
            "server.accounts.a.t.nullTypeMap",
        )
        body = _replace_once(
            body,
            "    if-nez v2, :cond_3\n\n    .line 11\n    sget-object p1, Lcom/vlite/sdk/server/virtualservice/accounts/a;->n:[Landroid/accounts/Account;",
            "    if-nez v2, :cond_3\n\n"
            f"    invoke-static {{}}, {DIAG}->logTEmptyAllMap()V\n\n"
            "    .line 11\n    sget-object p1, Lcom/vlite/sdk/server/virtualservice/accounts/a;->n:[Landroid/accounts/Account;",
            "server.accounts.a.t.emptyAllMap",
        )
        return body

    server_text = _patch_method_body(server_text, t_orig, _patch_t_branches, "server.accounts.a.cageOriginalT")

    x1_old = ".method public final x1(Lcom/vlite/sdk/server/virtualservice/accounts/f;[Landroid/accounts/Account;ILjava/lang/String;Z)[Landroid/accounts/Account;"
    x1_orig = ".method private cageOriginalX1(Lcom/vlite/sdk/server/virtualservice/accounts/f;[Landroid/accounts/Account;ILjava/lang/String;Z)[Landroid/accounts/Account;"
    x1_wrap = (
        f"{x1_old}\n"
        "    .locals 1\n\n"
        f"    invoke-direct/range {{p0 .. p5}}, {SERVER_ACCOUNTS}->cageOriginalX1(Lcom/vlite/sdk/server/virtualservice/accounts/f;[Landroid/accounts/Account;ILjava/lang/String;Z)[Landroid/accounts/Account;\n\n"
        "    move-result-object v0\n\n"
        f"    invoke-static {{p2, p3, p4, p5, v0}}, {DIAG}->logX1([Landroid/accounts/Account;ILjava/lang/String;Z[Landroid/accounts/Account;)V\n\n"
        "    return-object v0\n"
        ".end method"
    )
    server_text = _wrap_method(server_text, x1_old, x1_orig, x1_wrap, "server.accounts.a.x1")

    y_old = ".method public final Y(Landroid/accounts/Account;Ljava/lang/String;Lcom/vlite/sdk/server/virtualservice/accounts/f;)Ljava/lang/Integer;"
    y_orig = ".method private cageOriginalY(Landroid/accounts/Account;Ljava/lang/String;Lcom/vlite/sdk/server/virtualservice/accounts/f;)Ljava/lang/Integer;"
    y_wrap = (
        f"{y_old}\n"
        "    .locals 1\n\n"
        f"    invoke-direct {{p0, p1, p2, p3}}, {SERVER_ACCOUNTS}->cageOriginalY(Landroid/accounts/Account;Ljava/lang/String;Lcom/vlite/sdk/server/virtualservice/accounts/f;)Ljava/lang/Integer;\n\n"
        "    move-result-object v0\n\n"
        f"    invoke-static {{p1, p2, v0}}, {DIAG}->resolveY(Landroid/accounts/Account;Ljava/lang/String;Ljava/lang/Integer;)Ljava/lang/Integer;\n\n"
        "    move-result-object v0\n\n"
        "    return-object v0\n"
        ".end method"
    )
    server_text = _wrap_method(server_text, y_old, y_orig, y_wrap, "server.accounts.a.Y")
    server_text = _patch_method_body(
        server_text,
        y_orig,
        lambda body: _replace_once(
            body,
            "    :catch_0\n    move-exception p1\n\n    .line 33\n    new-instance p2, Ljava/lang/StringBuilder;",
            "    :catch_0\n    move-exception p1\n\n"
            f"    invoke-static {{p2}}, {DIAG}->logYNameNotFound(Ljava/lang/String;)V\n\n"
            "    .line 33\n    new-instance p2, Ljava/lang/StringBuilder;",
            "server.accounts.a.Y.catch_0",
        ),
        "server.accounts.a.cageOriginalY",
    )

    with server_path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(server_text)

    metadata = {
        "readOnly": False,
        "googleAccountVisibilityFix": True,
        "piiLogged": False,
        "exceptionMessagesLogged": False,
        "hostPackage": host_package,
        "hooks": [
            "client.accounts.a.S",
            "client.accounts.a.S.catch_0",
            "server.accounts.a.z",
            "server.accounts.a.O",
            "server.accounts.a.t0",
            "server.accounts.a.V0",
            "server.accounts.a.t",
            "server.accounts.a.t.nullTypeMap",
            "server.accounts.a.t.emptyAllMap",
            "server.accounts.a.x1",
            "server.accounts.a.Y",
            "server.accounts.a.Y.catch_0",
        ],
    }
    (Path(work) / "account-diag.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    return {"smali_classes4"}, metadata
