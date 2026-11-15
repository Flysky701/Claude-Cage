.class public final Lio/github/leexeo/cage/localcore/StatusProvider;
.super Landroid/content/ContentProvider;
.source "StatusProvider.java"


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 11
    invoke-direct {p0}, Landroid/content/ContentProvider;-><init>()V

    return-void
.end method

.method private static unavailable()Ljava/lang/UnsupportedOperationException;
    .locals 2

    .line 38
    new-instance v0, Ljava/lang/UnsupportedOperationException;

    const-string v1, "status only"

    invoke-direct {v0, v1}, Ljava/lang/UnsupportedOperationException;-><init>(Ljava/lang/String;)V

    return-object v0
.end method


# virtual methods
.method public call(Ljava/lang/String;Ljava/lang/String;Landroid/os/Bundle;)Landroid/os/Bundle;
    .locals 5

    .line 15
    const-string v0, "caller rejected"

    invoke-static {}, Landroid/os/Binder;->getCallingUid()I

    move-result v1

    .line 17
    :try_start_0
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/StatusProvider;->getContext()Landroid/content/Context;

    move-result-object v2

    invoke-virtual {v2}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object v2

    .line 18
    const-string v3, "top.niunaijun.microdem"

    const/4 v4, 0x0

    invoke-virtual {v2, v3, v4}, Landroid/content/pm/PackageManager;->getApplicationInfo(Ljava/lang/String;I)Landroid/content/pm/ApplicationInfo;

    move-result-object v3

    iget v3, v3, Landroid/content/pm/ApplicationInfo;->uid:I

    if-ne v3, v1, :cond_2

    .line 19
    invoke-static {}, Landroid/os/Process;->myUid()I

    move-result v3

    invoke-virtual {v2, v3, v1}, Landroid/content/pm/PackageManager;->checkSignatures(II)I

    move-result v1
    :try_end_0
    .catch Landroid/content/pm/PackageManager$NameNotFoundException; {:try_start_0 .. :try_end_0} :catch_0

    if-nez v1, :cond_2

    .line 21
    nop

    .line 22
    const-string v0, "status"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_1

    if-nez p2, :cond_1

    if-nez p3, :cond_1

    .line 24
    invoke-static {}, Landroid/os/Binder;->clearCallingIdentity()J

    move-result-wide p1

    .line 26
    :try_start_1
    sget-object p3, Lio/github/leexeo/cage/localcore/CoreService;->current:Lio/github/leexeo/cage/localcore/CoreService;

    .line 27
    new-instance v0, Landroid/os/Bundle;

    invoke-direct {v0}, Landroid/os/Bundle;-><init>()V

    .line 28
    const-string v1, "protectionReady"

    if-eqz p3, :cond_0

    invoke-virtual {p3}, Lio/github/leexeo/cage/localcore/CoreService;->safeReady()Z

    move-result p3

    if-eqz p3, :cond_0

    const/4 v4, 0x1

    :cond_0
    invoke-virtual {v0, v1, v4}, Landroid/os/Bundle;->putBoolean(Ljava/lang/String;Z)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 29
    nop

    .line 30
    invoke-static {p1, p2}, Landroid/os/Binder;->restoreCallingIdentity(J)V

    .line 29
    return-object v0

    .line 30
    :catchall_0
    move-exception p3

    invoke-static {p1, p2}, Landroid/os/Binder;->restoreCallingIdentity(J)V

    throw p3

    .line 23
    :cond_1
    new-instance p1, Ljava/lang/UnsupportedOperationException;

    const-string p2, "status only"

    invoke-direct {p1, p2}, Ljava/lang/UnsupportedOperationException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 20
    :cond_2
    :try_start_2
    new-instance p1, Ljava/lang/SecurityException;

    invoke-direct {p1, v0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p1
    :try_end_2
    .catch Landroid/content/pm/PackageManager$NameNotFoundException; {:try_start_2 .. :try_end_2} :catch_0

    .line 21
    :catch_0
    move-exception p1

    new-instance p1, Ljava/lang/SecurityException;

    invoke-direct {p1, v0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

.method public delete(Landroid/net/Uri;Ljava/lang/String;[Ljava/lang/String;)I
    .locals 0

    .line 36
    invoke-static {}, Lio/github/leexeo/cage/localcore/StatusProvider;->unavailable()Ljava/lang/UnsupportedOperationException;

    move-result-object p1

    throw p1
.end method

.method public getType(Landroid/net/Uri;)Ljava/lang/String;
    .locals 0

    .line 34
    invoke-static {}, Lio/github/leexeo/cage/localcore/StatusProvider;->unavailable()Ljava/lang/UnsupportedOperationException;

    move-result-object p1

    throw p1
.end method

.method public insert(Landroid/net/Uri;Landroid/content/ContentValues;)Landroid/net/Uri;
    .locals 0

    .line 35
    invoke-static {}, Lio/github/leexeo/cage/localcore/StatusProvider;->unavailable()Ljava/lang/UnsupportedOperationException;

    move-result-object p1

    throw p1
.end method

.method public onCreate()Z
    .locals 1

    .line 12
    const/4 v0, 0x1

    return v0
.end method

.method public query(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;
    .locals 0

    .line 33
    invoke-static {}, Lio/github/leexeo/cage/localcore/StatusProvider;->unavailable()Ljava/lang/UnsupportedOperationException;

    move-result-object p1

    throw p1
.end method

.method public update(Landroid/net/Uri;Landroid/content/ContentValues;Ljava/lang/String;[Ljava/lang/String;)I
    .locals 0

    .line 37
    invoke-static {}, Lio/github/leexeo/cage/localcore/StatusProvider;->unavailable()Ljava/lang/UnsupportedOperationException;

    move-result-object p1

    throw p1
.end method
