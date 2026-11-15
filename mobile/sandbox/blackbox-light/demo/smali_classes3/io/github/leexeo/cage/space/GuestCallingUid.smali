.class public final Lio/github/leexeo/cage/space/GuestCallingUid;
.super Ljava/lang/Object;
.source "GuestCallingUid.java"


# static fields
.field private static final PACKAGES:[Ljava/lang/String;

.field private static final resolving:Ljava/lang/ThreadLocal;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/lang/ThreadLocal<",
            "Ljava/lang/Boolean;",
            ">;"
        }
    .end annotation
.end field


# direct methods
.method static constructor <clinit>()V
    .locals 4

    .line 11
    new-instance v0, Ljava/lang/ThreadLocal;

    invoke-direct {v0}, Ljava/lang/ThreadLocal;-><init>()V

    sput-object v0, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    .line 12
    const-string v0, "com.google.android.gsf"

    const-string v1, "com.anthropic.claude"

    const-string v2, "com.google.android.gms"

    const-string v3, "com.android.vending"

    filled-new-array {v2, v3, v0, v1}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lio/github/leexeo/cage/space/GuestCallingUid;->PACKAGES:[Ljava/lang/String;

    return-void
.end method

.method public constructor <init>()V
    .locals 0

    .line 10
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static incoming(I)Ljava/lang/Integer;
    .locals 14

    .line 16
    sget-object v0, Ljava/lang/Boolean;->TRUE:Ljava/lang/Boolean;

    sget-object v1, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    invoke-virtual {v1}, Ljava/lang/ThreadLocal;->get()Ljava/lang/Object;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/Boolean;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_0

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0

    return-object p0

    .line 17
    :cond_0
    invoke-static {}, Landroid/os/Binder;->getCallingPid()I

    move-result v0

    .line 19
    :try_start_0
    const-string v1, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    .line 20
    const-string v2, "getHostUid"

    const/4 v3, 0x0

    new-array v4, v3, [Ljava/lang/Class;

    invoke-virtual {v1, v2, v4}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    new-array v4, v3, [Ljava/lang/Object;

    const/4 v5, 0x0

    invoke-virtual {v2, v5, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Ljava/lang/Integer;

    invoke-virtual {v2}, Ljava/lang/Integer;->intValue()I

    move-result v2

    if-eq p0, v2, :cond_1

    .line 21
    const-string v1, "outside_host"

    invoke-static {p0, v0, p0, v1}, Lio/github/leexeo/cage/space/GuestIntegrityTrace;->callerUid(IIILjava/lang/String;)V
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 22
    nop

    .line 66
    sget-object p0, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    invoke-virtual {p0}, Ljava/lang/ThreadLocal;->remove()V

    .line 22
    return-object v5

    .line 24
    :cond_1
    :try_start_1
    invoke-static {}, Landroid/os/Process;->myPid()I

    move-result v2

    if-ne v0, v2, :cond_2

    .line 25
    const-string v1, "local"

    invoke-static {p0, v0, p0, v1}, Lio/github/leexeo/cage/space/GuestIntegrityTrace;->callerUid(IIILjava/lang/String;)V
    :try_end_1
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_1 .. :try_end_1} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 26
    nop

    .line 66
    sget-object p0, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    invoke-virtual {p0}, Ljava/lang/ThreadLocal;->remove()V

    .line 26
    return-object v5

    .line 28
    :cond_2
    :try_start_2
    const-string v2, "top.niunaijun.blackbox.app.BActivityThread"

    invoke-static {v2}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v2

    .line 29
    const-string v4, "getAppPackageName"

    new-array v6, v3, [Ljava/lang/Class;

    invoke-virtual {v2, v4, v6}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v4

    new-array v6, v3, [Ljava/lang/Object;

    invoke-virtual {v4, v5, v6}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Ljava/lang/String;

    .line 30
    nop

    .line 31
    sget-object v6, Lio/github/leexeo/cage/space/GuestCallingUid;->PACKAGES:[Ljava/lang/String;

    array-length v7, v6

    move v8, v3

    move v9, v8

    :goto_0
    const/4 v10, 0x1

    if-ge v8, v7, :cond_4

    aget-object v11, v6, v8

    invoke-virtual {v11, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v11
    :try_end_2
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_2 .. :try_end_2} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_2 .. :try_end_2} :catch_0
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    if-eqz v11, :cond_3

    move v9, v10

    :cond_3
    add-int/lit8 v8, v8, 0x1

    goto :goto_0

    .line 32
    :cond_4
    if-nez v9, :cond_5

    .line 66
    sget-object p0, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    invoke-virtual {p0}, Ljava/lang/ThreadLocal;->remove()V

    .line 32
    return-object v5

    .line 35
    :cond_5
    if-gtz v0, :cond_6

    .line 36
    :try_start_3
    const-string v1, "pid_unavailable"

    invoke-static {p0, v0, p0, v1}, Lio/github/leexeo/cage/space/GuestIntegrityTrace;->callerUid(IIILjava/lang/String;)V

    .line 37
    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0
    :try_end_3
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_3 .. :try_end_3} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_3 .. :try_end_3} :catch_0
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 66
    sget-object v0, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    invoke-virtual {v0}, Ljava/lang/ThreadLocal;->remove()V

    .line 37
    return-object p0

    .line 39
    :cond_6
    :try_start_4
    sget-object v4, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    invoke-static {v10}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object v6

    invoke-virtual {v4, v6}, Ljava/lang/ThreadLocal;->set(Ljava/lang/Object;)V

    .line 40
    const-string v4, "getUserId"

    new-array v6, v3, [Ljava/lang/Class;

    invoke-virtual {v2, v4, v6}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    new-array v4, v3, [Ljava/lang/Object;

    invoke-virtual {v2, v5, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Ljava/lang/Integer;

    invoke-virtual {v2}, Ljava/lang/Integer;->intValue()I

    move-result v2

    .line 41
    const-string v4, "getBActivityManager"

    new-array v6, v3, [Ljava/lang/Class;

    invoke-virtual {v1, v4, v6}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v4

    new-array v6, v3, [Ljava/lang/Object;

    invoke-virtual {v4, v5, v6}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v4

    .line 42
    invoke-virtual {v4}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v6

    const-string v7, "getRunningAppProcesses"

    const-class v8, Ljava/lang/String;

    sget-object v9, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v8, v9}, [Ljava/lang/Class;

    move-result-object v8

    invoke-virtual {v6, v7, v8}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v6

    .line 43
    const-string v7, "getBPackageManager"

    new-array v8, v3, [Ljava/lang/Class;

    invoke-virtual {v1, v7, v8}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v7, v3, [Ljava/lang/Object;

    invoke-virtual {v1, v5, v7}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    .line 44
    invoke-virtual {v1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v5

    const-string v7, "getService"

    new-array v8, v3, [Ljava/lang/Class;

    invoke-virtual {v5, v7, v8}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v5

    new-array v7, v3, [Ljava/lang/Object;

    invoke-virtual {v5, v1, v7}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    .line 45
    if-nez v1, :cond_7

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0
    :try_end_4
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_4 .. :try_end_4} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_4 .. :try_end_4} :catch_0
    .catchall {:try_start_4 .. :try_end_4} :catchall_0

    .line 66
    sget-object v0, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    invoke-virtual {v0}, Ljava/lang/ThreadLocal;->remove()V

    .line 45
    return-object p0

    .line 46
    :cond_7
    :try_start_5
    const-string v5, "top.niunaijun.blackbox.core.system.pm.IBPackageManagerService"

    invoke-static {v5}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v5

    const-string v7, "getApplicationInfo"

    const-class v8, Ljava/lang/String;

    sget-object v9, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    sget-object v10, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v8, v9, v10}, [Ljava/lang/Class;

    move-result-object v8

    .line 47
    invoke-virtual {v5, v7, v8}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v5

    .line 48
    sget-object v7, Lio/github/leexeo/cage/space/GuestCallingUid;->PACKAGES:[Ljava/lang/String;

    array-length v8, v7

    move v9, v3

    :goto_1
    if-ge v9, v8, :cond_d

    aget-object v10, v7, v9

    .line 49
    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v11

    filled-new-array {v10, v11}, [Ljava/lang/Object;

    move-result-object v11

    invoke-virtual {v6, v4, v11}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v11

    .line 50
    if-nez v11, :cond_8

    goto :goto_5

    .line 51
    :cond_8
    invoke-virtual {v11}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v12

    const-string v13, "mAppProcessInfoList"

    invoke-virtual {v12, v13}, Ljava/lang/Class;->getField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v12

    invoke-virtual {v12, v11}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v11

    check-cast v11, Ljava/util/List;

    .line 52
    invoke-interface {v11}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v11

    :goto_2
    invoke-interface {v11}, Ljava/util/Iterator;->hasNext()Z

    move-result v12

    if-eqz v12, :cond_c

    invoke-interface {v11}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v12

    .line 53
    check-cast v12, Landroid/app/ActivityManager$RunningAppProcessInfo;

    .line 54
    iget v12, v12, Landroid/app/ActivityManager$RunningAppProcessInfo;->pid:I

    if-eq v12, v0, :cond_9

    goto :goto_2

    .line 55
    :cond_9
    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v3

    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    filled-new-array {v10, v3, v2}, [Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {v5, v1, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Landroid/content/pm/ApplicationInfo;

    .line 56
    if-eqz v1, :cond_b

    iget v2, v1, Landroid/content/pm/ApplicationInfo;->uid:I

    const/16 v3, 0x2710

    if-ge v2, v3, :cond_a

    goto :goto_3

    :cond_a
    iget v1, v1, Landroid/content/pm/ApplicationInfo;->uid:I

    goto :goto_4

    :cond_b
    :goto_3
    move v1, p0

    .line 57
    :goto_4
    const-string v2, "process_match"

    invoke-static {p0, v0, v1, v2}, Lio/github/leexeo/cage/space/GuestIntegrityTrace;->callerUid(IIILjava/lang/String;)V

    .line 58
    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0
    :try_end_5
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_5 .. :try_end_5} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_5 .. :try_end_5} :catch_0
    .catchall {:try_start_5 .. :try_end_5} :catchall_0

    .line 66
    sget-object v0, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    invoke-virtual {v0}, Ljava/lang/ThreadLocal;->remove()V

    .line 58
    return-object p0

    .line 48
    :cond_c
    :goto_5
    add-int/lit8 v9, v9, 0x1

    goto :goto_1

    .line 61
    :cond_d
    :try_start_6
    const-string v1, "process_missing"

    invoke-static {p0, v0, p0, v1}, Lio/github/leexeo/cage/space/GuestIntegrityTrace;->callerUid(IIILjava/lang/String;)V

    .line 62
    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0
    :try_end_6
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_6 .. :try_end_6} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_6 .. :try_end_6} :catch_0
    .catchall {:try_start_6 .. :try_end_6} :catchall_0

    .line 66
    sget-object v0, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    invoke-virtual {v0}, Ljava/lang/ThreadLocal;->remove()V

    .line 62
    return-object p0

    .line 63
    :catch_0
    move-exception v1

    .line 64
    :try_start_7
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "lookup_unavailable_"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {p0, v0, p0, v1}, Lio/github/leexeo/cage/space/GuestIntegrityTrace;->callerUid(IIILjava/lang/String;)V

    .line 65
    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_0

    .line 66
    sget-object v0, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    invoke-virtual {v0}, Ljava/lang/ThreadLocal;->remove()V

    .line 65
    return-object p0

    .line 66
    :catchall_0
    move-exception p0

    sget-object v0, Lio/github/leexeo/cage/space/GuestCallingUid;->resolving:Ljava/lang/ThreadLocal;

    invoke-virtual {v0}, Ljava/lang/ThreadLocal;->remove()V

    throw p0
.end method
