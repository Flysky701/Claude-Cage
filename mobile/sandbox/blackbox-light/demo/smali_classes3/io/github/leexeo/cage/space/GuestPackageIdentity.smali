.class public final Lio/github/leexeo/cage/space/GuestPackageIdentity;
.super Ljava/lang/Object;
.source "GuestPackageIdentity.java"


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 16
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static prepare(Landroid/content/Context;)V
    .locals 3

    .line 39
    :try_start_0
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPackageIdentity;->privateUser()I

    .line 40
    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object p0

    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestPackageIdentity;->supported(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_1

    .line 43
    sget p0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v0, 0x1e

    if-lt p0, v0, :cond_0

    const-string p0, "android.app.ApplicationPackageManager"

    invoke-static {p0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p0

    const-string v0, "disableGetPackagesForUidCache"

    const/4 v1, 0x0

    new-array v2, v1, [Ljava/lang/Class;

    .line 44
    invoke-virtual {p0, v0, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    new-array v0, v1, [Ljava/lang/Object;

    const/4 v1, 0x0

    invoke-virtual {p0, v1, v0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 47
    :cond_0
    nop

    .line 48
    return-void

    .line 40
    :cond_1
    new-instance p0, Ljava/lang/SecurityException;

    const-string v0, "Unexpected identity context"

    invoke-direct {p0, v0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p0
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_0

    .line 45
    :catch_0
    move-exception p0

    .line 46
    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Private UID lookup unavailable"

    invoke-direct {v0, v1, p0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw v0
.end method

.method private static privateUser()I
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/ReflectiveOperationException;
        }
    .end annotation

    .line 24
    const-string v0, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    .line 25
    const/4 v1, 0x0

    new-array v2, v1, [Ljava/lang/Class;

    const-string v3, "getContext"

    invoke-virtual {v0, v3, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    new-array v3, v1, [Ljava/lang/Object;

    const/4 v4, 0x0

    invoke-virtual {v2, v4, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Landroid/content/Context;

    .line 26
    const-string v3, "top.niunaijun.microdem"

    invoke-virtual {v2}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v3, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_2

    new-array v2, v1, [Ljava/lang/Class;

    .line 27
    const-string v3, "isBlackProcess"

    invoke-virtual {v0, v3, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    const-string v3, "get"

    new-array v5, v1, [Ljava/lang/Class;

    invoke-virtual {v0, v3, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    new-array v3, v1, [Ljava/lang/Object;

    invoke-virtual {v0, v4, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    new-array v3, v1, [Ljava/lang/Object;

    invoke-virtual {v2, v0, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/lang/Boolean;

    invoke-virtual {v0}, Ljava/lang/Boolean;->booleanValue()Z

    move-result v0

    if-eqz v0, :cond_2

    .line 29
    const-string v0, "top.niunaijun.blackbox.app.BActivityThread"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    .line 30
    const-string v2, "getAppPackageName"

    new-array v3, v1, [Ljava/lang/Class;

    invoke-virtual {v0, v2, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    new-array v3, v1, [Ljava/lang/Object;

    invoke-virtual {v2, v4, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Ljava/lang/String;

    invoke-static {v2}, Lio/github/leexeo/cage/space/GuestPackageIdentity;->supported(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_1

    .line 32
    const-string v2, "getUserId"

    new-array v3, v1, [Ljava/lang/Class;

    invoke-virtual {v0, v2, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    new-array v1, v1, [Ljava/lang/Object;

    invoke-virtual {v0, v4, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/lang/Integer;

    invoke-virtual {v0}, Ljava/lang/Integer;->intValue()I

    move-result v0

    .line 33
    if-nez v0, :cond_0

    .line 34
    return v0

    .line 33
    :cond_0
    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Unsupported private identity user"

    invoke-direct {v0, v1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 31
    :cond_1
    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Private identity guest required"

    invoke-direct {v0, v1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 28
    :cond_2
    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Private identity process required"

    invoke-direct {v0, v1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw v0
.end method

.method public static query(Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 16
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Throwable;
        }
    .end annotation

    .line 51
    move-object/from16 v0, p1

    invoke-virtual/range {p0 .. p0}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v1

    .line 52
    const-string v2, "getPackagesForUid"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    .line 53
    const-string v4, "getInstallerPackageName"

    invoke-virtual {v4, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    const-string v5, "getInstallSourceInfo"

    const/4 v7, 0x0

    .line 69
    invoke-static {v7}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v8

    .line 53
    if-nez v4, :cond_1

    invoke-virtual {v5, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_0

    goto :goto_0

    :cond_0
    move v4, v7

    goto :goto_1

    :cond_1
    :goto_0
    const/4 v4, 0x1

    .line 54
    :goto_1
    const/4 v9, 0x0

    if-nez v3, :cond_2

    if-nez v4, :cond_2

    const-string v10, "getPackageUid"

    invoke-virtual {v10, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v10

    if-nez v10, :cond_2

    return-object v9

    .line 55
    :cond_2
    if-nez v3, :cond_4

    if-eqz v0, :cond_3

    array-length v10, v0

    if-eqz v10, :cond_3

    aget-object v10, v0, v7

    check-cast v10, Ljava/lang/String;

    invoke-static {v10}, Lio/github/leexeo/cage/space/GuestPackageIdentity;->supported(Ljava/lang/String;)Z

    move-result v10

    if-nez v10, :cond_4

    :cond_3
    return-object v9

    .line 57
    :cond_4
    :try_start_0
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPackageIdentity;->privateUser()I

    move-result v10

    .line 58
    const-string v11, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v11}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v11

    .line 59
    const-string v12, "getBPackageManager"

    new-array v13, v7, [Ljava/lang/Class;

    invoke-virtual {v11, v12, v13}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v12

    new-array v13, v7, [Ljava/lang/Object;

    invoke-virtual {v12, v9, v13}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v12

    .line 60
    invoke-virtual {v12}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v13

    const-string v14, "getService"

    new-array v15, v7, [Ljava/lang/Class;

    invoke-virtual {v13, v14, v15}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v13

    new-array v14, v7, [Ljava/lang/Object;

    invoke-virtual {v13, v12, v14}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v12

    .line 61
    if-eqz v12, :cond_1a

    .line 62
    const-string v13, "top.niunaijun.blackbox.core.system.pm.IBPackageManagerService"

    invoke-static {v13}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v13

    .line 63
    const-string v14, "getApplicationInfo"

    const-class v15, Ljava/lang/String;

    const/16 p0, 0x1

    sget-object v6, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    sget-object v9, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v15, v6, v9}, [Ljava/lang/Class;

    move-result-object v6

    invoke-virtual {v13, v14, v6}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v6

    .line 64
    const/4 v9, 0x2

    if-eqz v4, :cond_b

    .line 65
    invoke-virtual {v5, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    .line 66
    array-length v2, v0

    if-eqz v1, :cond_5

    goto :goto_2

    :cond_5
    move/from16 v9, p0

    :goto_2
    if-ne v2, v9, :cond_a

    if-eqz v1, :cond_6

    aget-object v2, v0, p0

    instance-of v2, v2, Ljava/lang/Integer;

    if-eqz v2, :cond_a

    aget-object v2, v0, p0

    check-cast v2, Ljava/lang/Integer;

    .line 67
    invoke-virtual {v2}, Ljava/lang/Integer;->intValue()I

    move-result v2

    if-ne v2, v10, :cond_a

    .line 69
    :cond_6
    aget-object v2, v0, v7

    invoke-static {v10}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v3

    filled-new-array {v2, v8, v3}, [Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {v6, v12, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Landroid/content/pm/ApplicationInfo;

    .line 70
    if-eqz v2, :cond_9

    aget-object v0, v0, v7

    iget-object v2, v2, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v0, v2}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    move-result v0
    :try_end_0
    .catch Ljava/lang/reflect/InvocationTargetException; {:try_start_0 .. :try_end_0} :catch_0

    if-eqz v0, :cond_9

    .line 74
    const-string v0, "top.niunaijun.microdem"

    if-nez v1, :cond_7

    return-object v0

    .line 75
    :cond_7
    :try_start_1
    const-string v1, "getContext"

    new-array v2, v7, [Ljava/lang/Class;

    invoke-virtual {v11, v1, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v2, v7, [Ljava/lang/Object;

    const/4 v3, 0x0

    invoke-virtual {v1, v3, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Landroid/content/Context;

    .line 76
    invoke-virtual {v1}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object v2

    .line 77
    invoke-virtual {v1}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;

    move-result-object v1

    iget-object v1, v1, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    .line 76
    const/high16 v3, 0x8000000

    invoke-virtual {v2, v1, v3}, Landroid/content/pm/PackageManager;->getPackageArchiveInfo(Ljava/lang/String;I)Landroid/content/pm/PackageInfo;

    move-result-object v1

    .line 78
    if-eqz v1, :cond_8

    iget-object v2, v1, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_8

    iget-object v2, v1, Landroid/content/pm/PackageInfo;->signingInfo:Landroid/content/pm/SigningInfo;

    if-eqz v2, :cond_8

    .line 80
    const-string v2, "android.content.pm.InstallSourceInfo"

    invoke-static {v2}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v2

    const-class v3, Ljava/lang/String;

    const-class v4, Landroid/content/pm/SigningInfo;

    const-class v5, Ljava/lang/String;

    const-class v6, Ljava/lang/String;

    filled-new-array {v3, v4, v5, v6}, [Ljava/lang/Class;

    move-result-object v3

    .line 81
    invoke-virtual {v2, v3}, Ljava/lang/Class;->getConstructor([Ljava/lang/Class;)Ljava/lang/reflect/Constructor;

    move-result-object v2

    iget-object v1, v1, Landroid/content/pm/PackageInfo;->signingInfo:Landroid/content/pm/SigningInfo;

    const/4 v3, 0x0

    filled-new-array {v0, v1, v3, v0}, [Ljava/lang/Object;

    move-result-object v0

    .line 82
    invoke-virtual {v2, v0}, Ljava/lang/reflect/Constructor;->newInstance([Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    .line 80
    return-object v0

    .line 79
    :cond_8
    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Installing package signing metadata unavailable"

    invoke-direct {v0, v1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 71
    :cond_9
    new-instance v0, Ljava/lang/IllegalArgumentException;

    const-string v1, "Package is not installed in this space"

    invoke-direct {v0, v1}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 68
    :cond_a
    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Unsupported private install source query"

    invoke-direct {v0, v1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 84
    :cond_b
    if-nez v3, :cond_10

    .line 85
    array-length v1, v0

    const/4 v2, 0x3

    if-ne v1, v2, :cond_f

    aget-object v1, v0, p0

    instance-of v1, v1, Ljava/lang/Number;

    if-eqz v1, :cond_f

    aget-object v1, v0, v9

    instance-of v1, v1, Ljava/lang/Integer;

    if-eqz v1, :cond_f

    .line 87
    aget-object v1, v0, p0

    check-cast v1, Ljava/lang/Number;

    invoke-virtual {v1}, Ljava/lang/Number;->longValue()J

    move-result-wide v1

    .line 88
    aget-object v3, v0, v9

    check-cast v3, Ljava/lang/Integer;

    invoke-virtual {v3}, Ljava/lang/Integer;->intValue()I

    move-result v3

    const/4 v4, -0x1

    if-ne v3, v10, :cond_e

    long-to-int v3, v1

    int-to-long v8, v3

    cmp-long v1, v1, v8

    if-eqz v1, :cond_c

    goto :goto_4

    .line 89
    :cond_c
    aget-object v0, v0, v7

    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    invoke-static {v10}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    filled-new-array {v0, v1, v2}, [Ljava/lang/Object;

    move-result-object v0

    invoke-virtual {v6, v12, v0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/content/pm/ApplicationInfo;

    .line 90
    if-nez v0, :cond_d

    goto :goto_3

    :cond_d
    iget v4, v0, Landroid/content/pm/ApplicationInfo;->uid:I

    :goto_3
    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    return-object v0

    .line 88
    :cond_e
    :goto_4
    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    return-object v0

    .line 86
    :cond_f
    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Unsupported package UID query"

    invoke-direct {v0, v1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 92
    :cond_10
    if-eqz v0, :cond_19

    array-length v1, v0

    move/from16 v3, p0

    if-ne v1, v3, :cond_19

    aget-object v1, v0, v7

    instance-of v1, v1, Ljava/lang/Integer;

    if-eqz v1, :cond_19

    .line 94
    aget-object v0, v0, v7

    check-cast v0, Ljava/lang/Integer;

    invoke-virtual {v0}, Ljava/lang/Integer;->intValue()I

    move-result v0

    .line 95
    const-string v1, "getHostUid"

    new-array v3, v7, [Ljava/lang/Class;

    invoke-virtual {v11, v1, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v3, v7, [Ljava/lang/Object;

    const/4 v4, 0x0

    invoke-virtual {v1, v4, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Ljava/lang/Integer;

    invoke-virtual {v1}, Ljava/lang/Integer;->intValue()I

    move-result v1

    .line 98
    if-ne v0, v1, :cond_15

    .line 99
    invoke-static {}, Landroid/os/Binder;->getCallingPid()I

    move-result v0

    invoke-static {}, Landroid/os/Process;->myPid()I

    move-result v3

    if-ne v0, v3, :cond_12

    .line 100
    const-string v0, "top.niunaijun.blackbox.app.BActivityThread"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    const-string v1, "getAppPackageName"

    new-array v3, v7, [Ljava/lang/Class;

    .line 101
    invoke-virtual {v0, v1, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    new-array v1, v7, [Ljava/lang/Object;

    const/4 v3, 0x0

    invoke-virtual {v0, v3, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/lang/String;

    .line 102
    invoke-static {v10}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    filled-new-array {v0, v8, v1}, [Ljava/lang/Object;

    move-result-object v0

    invoke-virtual {v6, v12, v0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/content/pm/ApplicationInfo;

    .line 103
    if-nez v0, :cond_11

    new-array v0, v7, [Ljava/lang/String;

    return-object v0

    .line 104
    :cond_11
    iget v0, v0, Landroid/content/pm/ApplicationInfo;->uid:I

    .line 105
    goto :goto_6

    .line 109
    :cond_12
    invoke-static {v1}, Lio/github/leexeo/cage/space/GuestCallingUid;->incoming(I)Ljava/lang/Integer;

    move-result-object v0

    .line 110
    if-eqz v0, :cond_14

    invoke-virtual {v0}, Ljava/lang/Integer;->intValue()I

    move-result v3

    if-ne v3, v1, :cond_13

    goto :goto_5

    .line 111
    :cond_13
    invoke-virtual {v0}, Ljava/lang/Integer;->intValue()I

    move-result v0

    goto :goto_6

    .line 110
    :cond_14
    :goto_5
    new-array v0, v7, [Ljava/lang/String;

    return-object v0

    .line 114
    :cond_15
    :goto_6
    sget-object v1, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    sget-object v3, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v1, v3}, [Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {v13, v2, v1}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    .line 115
    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    invoke-static {v10}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v3

    filled-new-array {v2, v3}, [Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {v1, v12, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, [Ljava/lang/String;

    .line 116
    new-instance v2, Ljava/util/LinkedHashSet;

    invoke-direct {v2}, Ljava/util/LinkedHashSet;-><init>()V

    .line 117
    if-eqz v1, :cond_18

    array-length v3, v1

    move v4, v7

    :goto_7
    if-ge v4, v3, :cond_18

    aget-object v5, v1, v4

    .line 118
    invoke-static {v5}, Lio/github/leexeo/cage/space/GuestPackageIdentity;->supported(Ljava/lang/String;)Z

    move-result v9

    if-nez v9, :cond_16

    goto :goto_8

    .line 119
    :cond_16
    invoke-static {v10}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v9

    filled-new-array {v5, v8, v9}, [Ljava/lang/Object;

    move-result-object v9

    invoke-virtual {v6, v12, v9}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v9

    check-cast v9, Landroid/content/pm/ApplicationInfo;

    .line 122
    if-eqz v9, :cond_17

    iget-object v11, v9, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v5, v11}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v11

    if-eqz v11, :cond_17

    iget v9, v9, Landroid/content/pm/ApplicationInfo;->uid:I

    if-ne v9, v0, :cond_17

    invoke-virtual {v2, v5}, Ljava/util/LinkedHashSet;->add(Ljava/lang/Object;)Z

    .line 117
    :cond_17
    :goto_8
    add-int/lit8 v4, v4, 0x1

    goto :goto_7

    .line 124
    :cond_18
    new-array v1, v7, [Ljava/lang/String;

    invoke-virtual {v2, v1}, Ljava/util/LinkedHashSet;->toArray([Ljava/lang/Object;)[Ljava/lang/Object;

    move-result-object v1

    check-cast v1, [Ljava/lang/String;

    .line 125
    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    filled-new-array {v0}, [Ljava/lang/Object;

    move-result-object v0

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/GuestIntegrityTrace;->uidLookup([Ljava/lang/Object;[Ljava/lang/String;)V

    .line 126
    return-object v1

    .line 93
    :cond_19
    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Unsupported UID ownership query"

    invoke-direct {v0, v1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 61
    :cond_1a
    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Private package service unavailable"

    invoke-direct {v0, v1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw v0
    :try_end_1
    .catch Ljava/lang/reflect/InvocationTargetException; {:try_start_1 .. :try_end_1} :catch_0

    .line 127
    :catch_0
    move-exception v0

    .line 128
    invoke-virtual {v0}, Ljava/lang/reflect/InvocationTargetException;->getCause()Ljava/lang/Throwable;

    move-result-object v0

    throw v0
.end method

.method private static supported(Ljava/lang/String;)Z
    .locals 1

    .line 19
    const-string v0, "com.google.android.gms"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, "com.google.android.gsf"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    .line 20
    const-string v0, "com.android.vending"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, "com.anthropic.claude"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    goto :goto_0

    :cond_0
    const/4 p0, 0x0

    goto :goto_1

    :cond_1
    :goto_0
    const/4 p0, 0x1

    .line 19
    :goto_1
    return p0
.end method
