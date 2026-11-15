.class public final Lio/github/leexeo/cage/space/GuestSplits;
.super Ljava/lang/Object;
.source "GuestSplits.java"


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 13
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static apply(Landroid/content/pm/ApplicationInfo;I)Landroid/content/pm/ApplicationInfo;
    .locals 9

    .line 16
    if-eqz p0, :cond_a

    const-string v0, "com.anthropic.claude"

    iget-object v1, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_0

    goto/16 :goto_3

    .line 18
    :cond_0
    const/4 v0, 0x0

    :try_start_0
    invoke-static {}, Lio/github/leexeo/cage/space/GuestSplits;->host()Landroid/content/Context;

    move-result-object v1

    .line 19
    const-string v2, "top.niunaijun.microdem"

    invoke-virtual {v1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_1

    return-object p0

    .line 20
    :cond_1
    if-nez p1, :cond_9

    iget-object p1, p0, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    if-nez p1, :cond_2

    goto/16 :goto_2

    .line 21
    :cond_2
    new-instance p1, Ljava/io/File;

    iget-object v2, p0, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    invoke-direct {p1, v2}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {p1}, Ljava/io/File;->getCanonicalFile()Ljava/io/File;

    move-result-object p1

    .line 22
    invoke-virtual {p1}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v2

    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    invoke-static {v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->data(Landroid/content/Context;)Ljava/io/File;

    move-result-object v4

    invoke-virtual {v4}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v4

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    sget-object v4, Ljava/io/File;->separator:Ljava/lang/String;

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-nez v2, :cond_3

    return-object v0

    .line 23
    :cond_3
    invoke-static {v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->pending(Landroid/content/Context;)Z

    move-result v2

    if-eqz v2, :cond_5

    .line 26
    invoke-static {v1, p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->allowRegistration(Landroid/content/Context;Ljava/io/File;)Z

    move-result p1

    if-eqz p1, :cond_4

    goto :goto_0

    :cond_4
    move-object p0, v0

    :goto_0
    return-object p0

    .line 28
    :cond_5
    const/4 v2, 0x0

    invoke-static {v1, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object v3

    const-string v4, "active.json"

    invoke-static {v3, v4}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v3

    .line 29
    invoke-virtual {v3}, Ljava/io/File;->exists()Z

    move-result v4

    if-nez v4, :cond_6

    new-instance v4, Ljava/io/File;

    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v5, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v3

    const-string v5, ".bak"

    invoke-virtual {v3, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-direct {v4, v3}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v4}, Ljava/io/File;->exists()Z

    move-result v3

    if-nez v3, :cond_6

    .line 31
    return-object p0

    .line 33
    :cond_6
    invoke-static {v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v3

    invoke-virtual {p1, v3}, Ljava/io/File;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-nez p1, :cond_7

    return-object v0

    .line 34
    :cond_7
    invoke-static {v1, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->readState(Landroid/content/Context;Z)Lio/github/leexeo/cage/space/ClaudeBundle$State;

    move-result-object p1

    .line 35
    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    invoke-interface {v1}, Ljava/util/List;->size()I

    move-result v1

    add-int/lit8 v1, v1, -0x1

    .line 36
    new-array v3, v1, [Ljava/lang/String;

    new-array v4, v1, [Ljava/lang/String;

    .line 37
    move v5, v2

    :goto_1
    if-ge v5, v1, :cond_8

    .line 38
    iget-object v6, p1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    add-int/lit8 v7, v5, 0x1

    invoke-interface {v6, v7}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v6

    check-cast v6, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    .line 39
    iget-object v8, v6, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->split:Ljava/lang/String;

    aput-object v8, v4, v5

    .line 40
    iget-object v8, p1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directoryFile:Ljava/io/File;

    iget-object v6, v6, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    invoke-static {v8, v6}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v6

    invoke-virtual {v6}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v6

    aput-object v6, v3, v5

    .line 37
    move v5, v7

    goto :goto_1

    .line 42
    :cond_8
    iput-object v3, p0, Landroid/content/pm/ApplicationInfo;->splitSourceDirs:[Ljava/lang/String;

    .line 43
    invoke-virtual {v3}, [Ljava/lang/String;->clone()Ljava/lang/Object;

    move-result-object v3

    check-cast v3, [Ljava/lang/String;

    iput-object v3, p0, Landroid/content/pm/ApplicationInfo;->splitPublicSourceDirs:[Ljava/lang/String;

    .line 44
    const-class v3, Landroid/content/pm/ApplicationInfo;

    const-string v5, "splitNames"

    invoke-static {v3, v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->field(Ljava/lang/Class;Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v3

    invoke-virtual {v3, p0, v4}, Ljava/lang/reflect/Field;->set(Ljava/lang/Object;Ljava/lang/Object;)V

    .line 45
    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->nativeDir(Lio/github/leexeo/cage/space/ClaudeBundle$State;)Ljava/io/File;

    move-result-object p1

    invoke-virtual {p1}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object p1

    iput-object p1, p0, Landroid/content/pm/ApplicationInfo;->nativeLibraryDir:Ljava/lang/String;

    .line 46
    const-class p1, Landroid/content/pm/ApplicationInfo;

    const-string v3, "primaryCpuAbi"

    invoke-static {p1, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->field(Ljava/lang/Class;Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object p1

    const-string v3, "arm64-v8a"

    invoke-virtual {p1, p0, v3}, Ljava/lang/reflect/Field;->set(Ljava/lang/Object;Ljava/lang/Object;)V

    .line 47
    const-string p1, "secondaryCpuAbi"

    invoke-static {p0, p1, v0}, Lio/github/leexeo/cage/space/GuestSplits;->optional(Landroid/content/pm/ApplicationInfo;Ljava/lang/String;Ljava/lang/Object;)V

    .line 48
    const-string p1, "secondaryNativeLibraryDir"

    invoke-static {p0, p1, v0}, Lio/github/leexeo/cage/space/GuestSplits;->optional(Landroid/content/pm/ApplicationInfo;Ljava/lang/String;Ljava/lang/Object;)V

    .line 49
    const-string p1, "nativeLibraryRootDir"

    iget-object v3, p0, Landroid/content/pm/ApplicationInfo;->nativeLibraryDir:Ljava/lang/String;

    invoke-static {p0, p1, v3}, Lio/github/leexeo/cage/space/GuestSplits;->optional(Landroid/content/pm/ApplicationInfo;Ljava/lang/String;Ljava/lang/Object;)V

    .line 50
    const-string p1, "nativeLibraryRootRequiresIsa"

    invoke-static {v2}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object v2

    invoke-static {p0, p1, v2}, Lio/github/leexeo/cage/space/GuestSplits;->optional(Landroid/content/pm/ApplicationInfo;Ljava/lang/String;Ljava/lang/Object;)V

    .line 51
    const-string p1, "splitClassLoaderNames"

    new-array v1, v1, [Ljava/lang/String;

    invoke-static {p0, p1, v1}, Lio/github/leexeo/cage/space/GuestSplits;->optional(Landroid/content/pm/ApplicationInfo;Ljava/lang/String;Ljava/lang/Object;)V

    .line 52
    const-string p1, "splitDependencies"

    invoke-static {p0, p1, v0}, Lio/github/leexeo/cage/space/GuestSplits;->optional(Landroid/content/pm/ApplicationInfo;Ljava/lang/String;Ljava/lang/Object;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 53
    return-object p0

    .line 20
    :cond_9
    :goto_2
    return-object v0

    .line 54
    :catch_0
    move-exception p0

    .line 56
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "Claude split metadata unavailable: "

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    const-string p1, "CageDemo"

    invoke-static {p1, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 57
    return-object v0

    .line 16
    :cond_a
    :goto_3
    return-object p0
.end method

.method public static beforeContext(Landroid/content/pm/ApplicationInfo;)V
    .locals 2

    .line 104
    if-eqz p0, :cond_1

    const-string v0, "com.anthropic.claude"

    iget-object p0, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_0

    goto :goto_0

    .line 105
    :cond_0
    :try_start_0
    invoke-static {}, Lio/github/leexeo/cage/space/GuestSplits;->host()Landroid/content/Context;

    move-result-object p0

    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestSplits;->verify(Landroid/content/Context;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 106
    nop

    .line 107
    return-void

    .line 106
    :catch_0
    move-exception p0

    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Claude cannot load before bundle commit"

    invoke-direct {v0, v1, p0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw v0

    .line 104
    :cond_1
    :goto_0
    return-void
.end method

.method private static host()Landroid/content/Context;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 115
    const-string v0, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    const/4 v1, 0x0

    new-array v2, v1, [Ljava/lang/Class;

    const-string v3, "getContext"

    invoke-virtual {v0, v3, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    const/4 v2, 0x0

    new-array v1, v1, [Ljava/lang/Object;

    invoke-virtual {v0, v2, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/content/Context;

    return-object v0
.end method

.method private static optional(Landroid/content/pm/ApplicationInfo;Ljava/lang/String;Ljava/lang/Object;)V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 119
    :try_start_0
    const-class v0, Landroid/content/pm/ApplicationInfo;

    invoke-static {v0, p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->field(Ljava/lang/Class;Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object p1

    invoke-virtual {p1, p0, p2}, Ljava/lang/reflect/Field;->set(Ljava/lang/Object;Ljava/lang/Object;)V
    :try_end_0
    .catch Ljava/lang/NoSuchFieldException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    .line 120
    :catch_0
    move-exception p0

    :goto_0
    nop

    .line 121
    return-void
.end method

.method public static packageInfo(Landroid/content/pm/PackageInfo;I)Landroid/content/pm/PackageInfo;
    .locals 11

    .line 62
    if-eqz p0, :cond_b

    iget-object v0, p0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    const-string v1, "com.anthropic.claude"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_b

    iget-object v0, p0, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    if-nez v0, :cond_0

    goto/16 :goto_5

    .line 64
    :cond_0
    :try_start_0
    invoke-static {}, Lio/github/leexeo/cage/space/GuestSplits;->host()Landroid/content/Context;

    move-result-object v0

    .line 65
    const-string v2, "top.niunaijun.microdem"

    invoke-virtual {v0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_1

    return-object p0

    .line 66
    :cond_1
    const-class v2, Landroid/content/pm/ApplicationInfo;

    const-string v3, "splitNames"

    invoke-static {v2, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->field(Ljava/lang/Class;Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v2

    iget-object v3, p0, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    invoke-virtual {v2, v3}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, [Ljava/lang/String;

    .line 67
    const/4 v3, 0x0

    if-nez v2, :cond_2

    move-object v4, v3

    goto :goto_0

    :cond_2
    invoke-virtual {v2}, [Ljava/lang/String;->clone()Ljava/lang/Object;

    move-result-object v4

    check-cast v4, [Ljava/lang/String;

    :goto_0
    iput-object v4, p0, Landroid/content/pm/PackageInfo;->splitNames:[Ljava/lang/String;

    .line 68
    if-nez v2, :cond_3

    :goto_1
    goto :goto_2

    :cond_3
    array-length v2, v2

    new-array v3, v2, [I

    goto :goto_1

    :goto_2
    iput-object v3, p0, Landroid/content/pm/PackageInfo;->splitRevisionCodes:[I

    .line 69
    const v2, 0x8000040

    and-int/2addr v2, p1

    .line 70
    if-eqz v2, :cond_a

    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->pending(Landroid/content/Context;)Z

    move-result v2

    if-nez v2, :cond_a

    .line 71
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v2

    .line 72
    new-instance v3, Ljava/io/File;

    iget-object v4, p0, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget-object v4, v4, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    invoke-direct {v3, v4}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v3}, Ljava/io/File;->getCanonicalFile()Ljava/io/File;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/io/File;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_9

    .line 74
    const/4 v3, 0x0

    invoke-static {v0, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->readState(Landroid/content/Context;Z)Lio/github/leexeo/cage/space/ClaudeBundle$State;

    move-result-object v4

    .line 75
    invoke-virtual {v0}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object v0

    invoke-virtual {v2}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v2

    const/high16 v5, 0x8000000

    invoke-virtual {v0, v2, v5}, Landroid/content/pm/PackageManager;->getPackageArchiveInfo(Ljava/lang/String;I)Landroid/content/pm/PackageInfo;

    move-result-object v0

    .line 77
    if-eqz v0, :cond_8

    iget-object v2, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_8

    .line 78
    invoke-static {v0}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v1

    iget-wide v6, v4, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    cmp-long v1, v1, v6

    if-nez v1, :cond_8

    iget-object v1, v0, Landroid/content/pm/PackageInfo;->signingInfo:Landroid/content/pm/SigningInfo;

    if-eqz v1, :cond_8

    .line 80
    iget-object v1, v0, Landroid/content/pm/PackageInfo;->signingInfo:Landroid/content/pm/SigningInfo;

    invoke-virtual {v1}, Landroid/content/pm/SigningInfo;->getApkContentsSigners()[Landroid/content/pm/Signature;

    move-result-object v1

    .line 81
    if-eqz v1, :cond_7

    array-length v2, v1

    const/4 v6, 0x1

    if-ne v2, v6, :cond_7

    .line 83
    const-string v2, "SHA-256"

    invoke-static {v2}, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;

    move-result-object v2

    aget-object v6, v1, v3

    invoke-virtual {v6}, Landroid/content/pm/Signature;->toByteArray()[B

    move-result-object v6

    invoke-virtual {v2, v6}, Ljava/security/MessageDigest;->digest([B)[B

    move-result-object v2

    .line 84
    new-instance v6, Ljava/lang/StringBuilder;

    invoke-direct {v6}, Ljava/lang/StringBuilder;-><init>()V

    .line 85
    array-length v7, v2

    :goto_3
    if-ge v3, v7, :cond_4

    aget-byte v8, v2, v3

    sget-object v9, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    const-string v10, "%02x"

    and-int/lit16 v8, v8, 0xff

    invoke-static {v8}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v8

    filled-new-array {v8}, [Ljava/lang/Object;

    move-result-object v8

    invoke-static {v9, v10, v8}, Ljava/lang/String;->format(Ljava/util/Locale;Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/String;

    move-result-object v8

    invoke-virtual {v6, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    add-int/lit8 v3, v3, 0x1

    goto :goto_3

    .line 86
    :cond_4
    iget-object v2, v4, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    invoke-virtual {v6}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_6

    .line 90
    and-int v2, p1, v5

    if-eqz v2, :cond_5

    iget-object v0, v0, Landroid/content/pm/PackageInfo;->signingInfo:Landroid/content/pm/SigningInfo;

    iput-object v0, p0, Landroid/content/pm/PackageInfo;->signingInfo:Landroid/content/pm/SigningInfo;

    .line 91
    :cond_5
    and-int/lit8 p1, p1, 0x40

    if-eqz p1, :cond_a

    invoke-virtual {v1}, [Landroid/content/pm/Signature;->clone()Ljava/lang/Object;

    move-result-object p1

    check-cast p1, [Landroid/content/pm/Signature;

    iput-object p1, p0, Landroid/content/pm/PackageInfo;->signatures:[Landroid/content/pm/Signature;

    goto :goto_4

    .line 87
    :cond_6
    new-instance p0, Ljava/lang/SecurityException;

    const-string p1, "Original package signer changed"

    invoke-direct {p0, p1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 82
    :cond_7
    new-instance p0, Ljava/lang/SecurityException;

    const-string p1, "Unexpected original package signers"

    invoke-direct {p0, p1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 79
    :cond_8
    new-instance p0, Ljava/lang/SecurityException;

    const-string p1, "Original package signing metadata unavailable"

    invoke-direct {p0, p1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 73
    :cond_9
    new-instance p0, Ljava/lang/SecurityException;

    const-string p1, "Unexpected private package source"

    invoke-direct {p0, p1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p0
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 93
    :cond_a
    :goto_4
    return-object p0

    .line 94
    :catch_0
    move-exception p0

    new-instance p1, Ljava/lang/SecurityException;

    const-string v0, "Claude split metadata unavailable"

    invoke-direct {p1, v0, p0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw p1

    .line 62
    :cond_b
    :goto_5
    return-object p0
.end method

.method public static ready(Landroid/content/Context;)Z
    .locals 1

    .line 110
    const/4 v0, 0x0

    :try_start_0
    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->readState(Landroid/content/Context;Z)Lio/github/leexeo/cage/space/ClaudeBundle$State;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    const/4 p0, 0x1

    return p0

    .line 111
    :catch_0
    move-exception p0

    return v0
.end method

.method public static verify(Landroid/content/Context;)V
    .locals 2

    .line 99
    const/4 v0, 0x1

    :try_start_0
    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->readState(Landroid/content/Context;Z)Lio/github/leexeo/cage/space/ClaudeBundle$State;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 100
    nop

    .line 101
    return-void

    .line 100
    :catch_0
    move-exception p0

    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Claude original bundle verification failed"

    invoke-direct {v0, v1, p0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw v0
.end method
