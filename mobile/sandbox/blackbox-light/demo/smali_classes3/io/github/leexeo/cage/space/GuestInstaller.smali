.class public final Lio/github/leexeo/cage/space/GuestInstaller;
.super Ljava/lang/Object;
.source "GuestInstaller.java"


# static fields
.field private static instance:Ljava/lang/Object;


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 9
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static declared-synchronized get()Ljava/lang/Object;
    .locals 5

    const-class v0, Lio/github/leexeo/cage/space/GuestInstaller;

    monitor-enter v0

    .line 13
    :try_start_0
    sget-object v1, Lio/github/leexeo/cage/space/GuestInstaller;->instance:Ljava/lang/Object;

    if-eqz v1, :cond_0

    sget-object v1, Lio/github/leexeo/cage/space/GuestInstaller;->instance:Ljava/lang/Object;
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    monitor-exit v0

    return-object v1

    .line 15
    :cond_0
    :try_start_1
    const-string v1, "android.content.pm.IPackageInstaller"

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    .line 16
    new-instance v2, Landroid/os/Binder;

    invoke-direct {v2}, Landroid/os/Binder;-><init>()V

    .line 17
    const-class v3, Lio/github/leexeo/cage/space/GuestInstaller;

    invoke-virtual {v3}, Ljava/lang/Class;->getClassLoader()Ljava/lang/ClassLoader;

    move-result-object v3

    filled-new-array {v1}, [Ljava/lang/Class;

    move-result-object v1

    new-instance v4, Lio/github/leexeo/cage/space/GuestInstaller$$ExternalSyntheticLambda0;

    invoke-direct {v4, v2}, Lio/github/leexeo/cage/space/GuestInstaller$$ExternalSyntheticLambda0;-><init>(Landroid/os/Binder;)V

    invoke-static {v3, v1, v4}, Ljava/lang/reflect/Proxy;->newProxyInstance(Ljava/lang/ClassLoader;[Ljava/lang/Class;Ljava/lang/reflect/InvocationHandler;)Ljava/lang/Object;

    move-result-object v1

    .line 34
    move-object v3, v1

    check-cast v3, Landroid/os/IInterface;

    const-string v4, "android.content.pm.IPackageInstaller"

    invoke-virtual {v2, v3, v4}, Landroid/os/Binder;->attachInterface(Landroid/os/IInterface;Ljava/lang/String;)V

    .line 35
    sput-object v1, Lio/github/leexeo/cage/space/GuestInstaller;->instance:Ljava/lang/Object;
    :try_end_1
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 36
    monitor-exit v0

    return-object v1

    .line 37
    :catch_0
    move-exception v1

    .line 38
    :try_start_2
    new-instance v2, Ljava/lang/IllegalStateException;

    const-string v3, "Private installer unavailable"

    invoke-direct {v2, v3, v1}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw v2

    .line 12
    :catchall_0
    move-exception v1

    monitor-exit v0
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    throw v1
.end method

.method static synthetic lambda$get$0(Landroid/os/Binder;Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Throwable;
        }
    .end annotation

    .line 19
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v0

    .line 20
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getDeclaringClass()Ljava/lang/Class;

    move-result-object p2

    const-class v1, Ljava/lang/Object;

    if-ne p2, v1, :cond_3

    .line 21
    const-string p2, "equals"

    invoke-virtual {p2, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2

    if-eqz p2, :cond_1

    const/4 p0, 0x0

    aget-object p2, p3, p0

    if-ne p1, p2, :cond_0

    const/4 p0, 0x1

    :cond_0
    invoke-static {p0}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object p0

    return-object p0

    .line 22
    :cond_1
    const-string p2, "hashCode"

    invoke-virtual {p2, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2

    if-eqz p2, :cond_2

    invoke-static {p1}, Ljava/lang/System;->identityHashCode(Ljava/lang/Object;)I

    move-result p0

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0

    return-object p0

    .line 23
    :cond_2
    const-string p1, "toString"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_3

    const-string p0, "PrivateSpaceInstaller"

    return-object p0

    .line 25
    :cond_3
    const-string p1, "asBinder"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_4

    return-object p0

    .line 26
    :cond_4
    const-string p0, "getMySessions"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_8

    const-string p0, "getAllSessions"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_8

    .line 27
    const-string p0, "getStagedSessions"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_5

    goto :goto_1

    .line 30
    :cond_5
    const-string p0, "getSessionInfo"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_7

    const-string p0, "registerCallback"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_7

    .line 31
    const-string p0, "unregisterCallback"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_6

    goto :goto_0

    .line 32
    :cond_6
    new-instance p0, Ljava/lang/UnsupportedOperationException;

    const-string p1, "Private space install sessions are not implemented"

    invoke-direct {p0, p1}, Ljava/lang/UnsupportedOperationException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 31
    :cond_7
    :goto_0
    const/4 p0, 0x0

    return-object p0

    .line 28
    :cond_8
    :goto_1
    const-string p0, "android.content.pm.ParceledListSlice"

    invoke-static {p0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p0

    const-class p1, Ljava/util/List;

    filled-new-array {p1}, [Ljava/lang/Class;

    move-result-object p1

    .line 29
    invoke-virtual {p0, p1}, Ljava/lang/Class;->getConstructor([Ljava/lang/Class;)Ljava/lang/reflect/Constructor;

    move-result-object p0

    invoke-static {}, Ljava/util/Collections;->emptyList()Ljava/util/List;

    move-result-object p1

    filled-new-array {p1}, [Ljava/lang/Object;

    move-result-object p1

    invoke-virtual {p0, p1}, Ljava/lang/reflect/Constructor;->newInstance([Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    .line 28
    return-object p0
.end method
