.class public final Lio/github/leexeo/cage/space/GuestCredentials;
.super Ljava/lang/Object;
.source "GuestCredentials.java"


# static fields
.field private static privateFetcher:Ljava/lang/Object;


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 18
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static declared-synchronized beforeContext(Landroid/content/pm/ApplicationInfo;)V
    .locals 6

    const-class v0, Lio/github/leexeo/cage/space/GuestCredentials;

    monitor-enter v0

    .line 63
    :try_start_0
    sget v1, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v2, 0x22

    if-lt v1, v2, :cond_7

    if-eqz p0, :cond_7

    const-string v1, "com.anthropic.claude"

    iget-object p0, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v1, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    if-nez p0, :cond_0

    goto/16 :goto_0

    .line 65
    :cond_0
    :try_start_1
    const-string p0, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {p0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p0

    .line 66
    const-string v1, "getContext"

    const/4 v2, 0x0

    new-array v3, v2, [Ljava/lang/Class;

    invoke-virtual {p0, v1, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v3, v2, [Ljava/lang/Object;

    const/4 v4, 0x0

    invoke-virtual {v1, v4, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Landroid/content/Context;

    .line 67
    const-string v3, "top.niunaijun.microdem"

    invoke-virtual {v1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v3, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1
    :try_end_1
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_1 .. :try_end_1} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    if-nez v1, :cond_1

    monitor-exit v0

    return-void

    .line 68
    :cond_1
    :try_start_2
    const-string v1, "get"

    new-array v3, v2, [Ljava/lang/Class;

    invoke-virtual {p0, v1, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v3, v2, [Ljava/lang/Object;

    invoke-virtual {v1, v4, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    .line 69
    const-string v3, "isBlackProcess"

    new-array v5, v2, [Ljava/lang/Class;

    invoke-virtual {p0, v3, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    new-array v3, v2, [Ljava/lang/Object;

    invoke-virtual {p0, v1, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Ljava/lang/Boolean;

    invoke-virtual {p0}, Ljava/lang/Boolean;->booleanValue()Z

    move-result p0
    :try_end_2
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_2 .. :try_end_2} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_2 .. :try_end_2} :catch_0
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    if-nez p0, :cond_2

    monitor-exit v0

    return-void

    .line 70
    :cond_2
    :try_start_3
    const-string p0, "top.niunaijun.blackbox.app.BActivityThread"

    invoke-static {p0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p0

    .line 71
    const-string v1, "com.anthropic.claude"

    const-string v3, "getAppPackageName"

    new-array v5, v2, [Ljava/lang/Class;

    invoke-virtual {p0, v3, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v3

    new-array v5, v2, [Ljava/lang/Object;

    invoke-virtual {v3, v4, v5}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v3

    invoke-virtual {v1, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_6

    const-string v1, "getUserId"

    new-array v3, v2, [Ljava/lang/Class;

    .line 72
    invoke-virtual {p0, v1, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    new-array v1, v2, [Ljava/lang/Object;

    invoke-virtual {p0, v4, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Ljava/lang/Integer;

    invoke-virtual {p0}, Ljava/lang/Integer;->intValue()I

    move-result p0

    if-nez p0, :cond_6

    .line 74
    const-string p0, "android.app.SystemServiceRegistry"

    invoke-static {p0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p0

    .line 75
    const-string v1, "SYSTEM_SERVICE_FETCHERS"

    invoke-virtual {p0, v1}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object p0

    .line 76
    const/4 v1, 0x1

    invoke-virtual {p0, v1}, Ljava/lang/reflect/Field;->setAccessible(Z)V

    .line 78
    invoke-virtual {p0, v4}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Ljava/util/Map;

    .line 79
    monitor-enter p0
    :try_end_3
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_3 .. :try_end_3} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_3 .. :try_end_3} :catch_0
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    .line 80
    :try_start_4
    sget-object v1, Lio/github/leexeo/cage/space/GuestCredentials;->privateFetcher:Ljava/lang/Object;

    if-eqz v1, :cond_4

    .line 81
    const-string v1, "credential"

    invoke-interface {p0, v1}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    sget-object v2, Lio/github/leexeo/cage/space/GuestCredentials;->privateFetcher:Ljava/lang/Object;

    if-ne v1, v2, :cond_3

    .line 83
    monitor-exit p0
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_0

    monitor-exit v0

    return-void

    .line 82
    :cond_3
    :try_start_5
    new-instance v1, Ljava/lang/SecurityException;

    const-string v2, "Guest credential isolation changed"

    invoke-direct {v1, v2}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw v1

    .line 85
    :cond_4
    const-string v1, "android.app.SystemServiceRegistry$ServiceFetcher"

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    .line 86
    invoke-virtual {v1}, Ljava/lang/Class;->isInterface()Z

    move-result v2

    if-eqz v2, :cond_5

    .line 87
    invoke-virtual {v1}, Ljava/lang/Class;->getClassLoader()Ljava/lang/ClassLoader;

    move-result-object v2

    filled-new-array {v1}, [Ljava/lang/Class;

    move-result-object v1

    new-instance v3, Lio/github/leexeo/cage/space/GuestCredentials$$ExternalSyntheticLambda0;

    invoke-direct {v3}, Lio/github/leexeo/cage/space/GuestCredentials$$ExternalSyntheticLambda0;-><init>()V

    invoke-static {v2, v1, v3}, Ljava/lang/reflect/Proxy;->newProxyInstance(Ljava/lang/ClassLoader;[Ljava/lang/Class;Ljava/lang/reflect/InvocationHandler;)Ljava/lang/Object;

    move-result-object v1

    .line 99
    const-string v2, "credential"

    invoke-interface {p0, v2, v1}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 100
    sput-object v1, Lio/github/leexeo/cage/space/GuestCredentials;->privateFetcher:Ljava/lang/Object;

    .line 101
    monitor-exit p0
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_0

    .line 102
    :try_start_6
    const-string p0, "CageDemo"

    const-string v1, "Claude credentials: private Play Services fallback enabled"

    invoke-static {p0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_6
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_6 .. :try_end_6} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_6 .. :try_end_6} :catch_0
    .catchall {:try_start_6 .. :try_end_6} :catchall_1

    .line 105
    nop

    .line 106
    monitor-exit v0

    return-void

    .line 86
    :cond_5
    :try_start_7
    new-instance v1, Ljava/lang/SecurityException;

    const-string v2, "Unsupported credential registry"

    invoke-direct {v1, v2}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw v1

    .line 101
    :catchall_0
    move-exception v1

    monitor-exit p0
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_0

    :try_start_8
    throw v1

    .line 73
    :cond_6
    new-instance p0, Ljava/lang/SecurityException;

    const-string v1, "Unexpected credential guest identity"

    invoke-direct {p0, v1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p0
    :try_end_8
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_8 .. :try_end_8} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_8 .. :try_end_8} :catch_0
    .catchall {:try_start_8 .. :try_end_8} :catchall_1

    .line 103
    :catch_0
    move-exception p0

    .line 104
    :try_start_9
    new-instance v1, Ljava/lang/SecurityException;

    const-string v2, "Personal credential provider is unavailable in this guest"

    invoke-direct {v1, v2, p0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw v1
    :try_end_9
    .catchall {:try_start_9 .. :try_end_9} :catchall_1

    .line 63
    :cond_7
    :goto_0
    monitor-exit v0

    return-void

    .line 62
    :catchall_1
    move-exception p0

    :try_start_a
    monitor-exit v0
    :try_end_a
    .catchall {:try_start_a .. :try_end_a} :catchall_1

    throw p0
.end method

.method public static guardSystemBind([Ljava/lang/Object;)V
    .locals 7

    .line 34
    nop

    .line 35
    const/4 v0, 0x0

    const/4 v1, 0x0

    if-eqz p0, :cond_2

    array-length v2, p0

    move v3, v0

    move-object v4, v1

    :goto_0
    if-ge v3, v2, :cond_3

    aget-object v5, p0, v3

    instance-of v6, v5, Landroid/content/Intent;

    if-eqz v6, :cond_1

    .line 36
    if-nez v4, :cond_0

    .line 37
    move-object v4, v5

    check-cast v4, Landroid/content/Intent;

    goto :goto_1

    .line 36
    :cond_0
    new-instance p0, Ljava/lang/SecurityException;

    const-string v0, "Ambiguous service request"

    invoke-direct {p0, v0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 35
    :cond_1
    :goto_1
    add-int/lit8 v3, v3, 0x1

    goto :goto_0

    :cond_2
    move-object v4, v1

    .line 39
    :cond_3
    if-nez v4, :cond_4

    return-void

    .line 40
    :cond_4
    invoke-virtual {v4}, Landroid/content/Intent;->getComponent()Landroid/content/ComponentName;

    move-result-object p0

    .line 41
    const-string v2, "top.niunaijun.microdem"

    if-eqz p0, :cond_5

    invoke-virtual {p0}, Landroid/content/ComponentName;->getPackageName()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_5

    .line 42
    invoke-virtual {p0}, Landroid/content/ComponentName;->getClassName()Ljava/lang/String;

    move-result-object v3

    const-string v5, "top\\.niunaijun\\.blackbox\\.proxy\\.ProxyService\\$P[0-9]{1,2}"

    invoke-virtual {v3, v5}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_5

    return-void

    .line 43
    :cond_5
    if-nez p0, :cond_6

    invoke-virtual {v4}, Landroid/content/Intent;->getPackage()Ljava/lang/String;

    move-result-object p0

    goto :goto_2

    :cond_6
    invoke-virtual {p0}, Landroid/content/ComponentName;->getPackageName()Ljava/lang/String;

    move-result-object p0

    .line 44
    :goto_2
    invoke-virtual {v4}, Landroid/content/Intent;->getAction()Ljava/lang/String;

    move-result-object v3

    .line 45
    const-string v4, "com.google.android.gms"

    invoke-virtual {v4, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-nez v4, :cond_8

    const-string v4, "com.android.vending"

    invoke-virtual {v4, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_8

    if-eqz v3, :cond_7

    .line 46
    const-string p0, "com.google.android.gms."

    invoke-virtual {v3, p0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result p0

    if-nez p0, :cond_8

    .line 47
    const-string p0, "com.android.vending."

    invoke-virtual {v3, p0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result p0

    if-nez p0, :cond_8

    .line 48
    const-string p0, "com.google.android.play.core.integrityservice."

    invoke-virtual {v3, p0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result p0

    if-nez p0, :cond_8

    .line 49
    const-string p0, "com.google.android.play.core.expressintegrityservice."

    invoke-virtual {v3, p0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result p0

    if-nez p0, :cond_8

    :cond_7
    return-void

    .line 51
    :cond_8
    :try_start_0
    const-string p0, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {p0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p0

    const-string v4, "getContext"

    new-array v5, v0, [Ljava/lang/Class;

    .line 52
    invoke-virtual {p0, v4, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    new-array v0, v0, [Ljava/lang/Object;

    invoke-virtual {p0, v1, v0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Landroid/content/Context;

    .line 53
    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {v2, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_0

    if-nez p0, :cond_9

    return-void

    .line 56
    :cond_9
    nop

    .line 57
    if-eqz v3, :cond_a

    const-string p0, "[a-zA-Z0-9_.$]{1,180}"

    invoke-virtual {v3, p0}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_a

    goto :goto_3

    :cond_a
    const-string v3, "unspecified"

    .line 58
    :goto_3
    new-instance p0, Ljava/lang/StringBuilder;

    invoke-direct {p0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "Blocked personal Google service fallback: "

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    const-string v0, "CageDemo"

    invoke-static {v0, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 59
    new-instance p0, Ljava/lang/SecurityException;

    const-string v0, "Google services must resolve inside this space"

    invoke-direct {p0, v0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 54
    :catch_0
    move-exception p0

    .line 55
    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Private service identity unavailable"

    invoke-direct {v0, v1, p0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw v0
.end method

.method public static invokeSystemBind(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 0
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Throwable;
        }
    .end annotation

    .line 21
    :try_start_0
    invoke-static {p2}, Lio/github/leexeo/cage/space/GuestCredentials;->guardSystemBind([Ljava/lang/Object;)V
    :try_end_0
    .catch Ljava/lang/SecurityException; {:try_start_0 .. :try_end_0} :catch_1

    .line 27
    nop

    .line 28
    :try_start_1
    invoke-virtual {p1, p0, p2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0
    :try_end_1
    .catch Ljava/lang/reflect/InvocationTargetException; {:try_start_1 .. :try_end_1} :catch_0

    return-object p0

    .line 29
    :catch_0
    move-exception p0

    invoke-virtual {p0}, Ljava/lang/reflect/InvocationTargetException;->getCause()Ljava/lang/Throwable;

    move-result-object p0

    throw p0

    .line 22
    :catch_1
    move-exception p0

    .line 25
    invoke-virtual {p1}, Ljava/lang/reflect/Method;->getReturnType()Ljava/lang/Class;

    move-result-object p1

    sget-object p2, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    if-ne p1, p2, :cond_0

    .line 26
    const/4 p0, 0x0

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0

    return-object p0

    .line 25
    :cond_0
    throw p0
.end method

.method static synthetic lambda$beforeContext$0(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Throwable;
        }
    .end annotation

    .line 89
    invoke-virtual {p1}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/String;->hashCode()I

    move-result v0

    const/4 v1, 0x1

    const/4 v2, 0x0

    sparse-switch v0, :sswitch_data_0

    :cond_0
    goto :goto_0

    :sswitch_0
    const-string v0, "hashCode"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_0

    const/4 p1, 0x3

    goto :goto_1

    :sswitch_1
    const-string v0, "getService"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_0

    move p1, v2

    goto :goto_1

    :sswitch_2
    const-string v0, "equals"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_0

    const/4 p1, 0x4

    goto :goto_1

    :sswitch_3
    const-string v0, "toString"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_0

    const/4 p1, 0x2

    goto :goto_1

    :sswitch_4
    const-string v0, "supportsFetchWithoutContext"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_0

    move p1, v1

    goto :goto_1

    :goto_0
    const/4 p1, -0x1

    :goto_1
    packed-switch p1, :pswitch_data_0

    .line 95
    new-instance p0, Ljava/lang/SecurityException;

    const-string p1, "Unsupported credential lookup"

    invoke-direct {p0, p1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 94
    :pswitch_0
    if-eqz p2, :cond_1

    array-length p1, p2

    if-ne p1, v1, :cond_1

    aget-object p1, p2, v2

    if-ne p0, p1, :cond_1

    goto :goto_2

    :cond_1
    move v1, v2

    :goto_2
    invoke-static {v1}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object p0

    return-object p0

    .line 93
    :pswitch_1
    invoke-static {p0}, Ljava/lang/System;->identityHashCode(Ljava/lang/Object;)I

    move-result p0

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0

    return-object p0

    .line 92
    :pswitch_2
    const-string p0, "Cage private credential route"

    return-object p0

    .line 91
    :pswitch_3
    invoke-static {v2}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object p0

    return-object p0

    .line 90
    :pswitch_4
    const/4 p0, 0x0

    return-object p0

    nop

    :sswitch_data_0
    .sparse-switch
        -0x7c1c0803 -> :sswitch_4
        -0x69e9ad94 -> :sswitch_3
        -0x4d378041 -> :sswitch_2
        -0x4beefd81 -> :sswitch_1
        0x8cdac1b -> :sswitch_0
    .end sparse-switch

    :pswitch_data_0
    .packed-switch 0x0
        :pswitch_4
        :pswitch_3
        :pswitch_2
        :pswitch_1
        :pswitch_0
    .end packed-switch
.end method
