.class public final Lio/github/leexeo/cage/space/GuestIntegrityTransport;
.super Ljava/lang/Object;
.source "GuestIntegrityTransport.java"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;
    }
.end annotation


# static fields
.field private static final SERVICE:Ljava/lang/String; = "com.google.android.play.core.integrity.protocol.IIntegrityService"


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 14
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static adapt(Landroid/content/ComponentName;Landroid/os/IBinder;)Landroid/os/IBinder;
    .locals 5

    .line 17
    if-eqz p0, :cond_5

    if-eqz p1, :cond_5

    .line 18
    invoke-virtual {p0}, Landroid/content/ComponentName;->getPackageName()Ljava/lang/String;

    move-result-object v0

    const-string v1, "com.android.vending"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_5

    .line 19
    invoke-virtual {p0}, Landroid/content/ComponentName;->getClassName()Ljava/lang/String;

    move-result-object p0

    const-string v0, "com.google.android.finsky.integrityservice.IntegrityService"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_0

    goto/16 :goto_2

    .line 22
    :cond_0
    :try_start_0
    const-string p0, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {p0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p0

    .line 23
    const-string v0, "getContext"

    const/4 v1, 0x0

    new-array v2, v1, [Ljava/lang/Class;

    invoke-virtual {p0, v0, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    new-array v2, v1, [Ljava/lang/Object;

    const/4 v3, 0x0

    invoke-virtual {v0, v3, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/content/Context;

    .line 24
    const-string v2, "top.niunaijun.microdem"

    invoke-virtual {v0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v2, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_4

    const-string v0, "isBlackProcess"

    new-array v2, v1, [Ljava/lang/Class;

    .line 25
    invoke-virtual {p0, v0, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    const-string v2, "get"

    new-array v4, v1, [Ljava/lang/Class;

    invoke-virtual {p0, v2, v4}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    new-array v2, v1, [Ljava/lang/Object;

    invoke-virtual {p0, v3, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    new-array v2, v1, [Ljava/lang/Object;

    invoke-virtual {v0, p0, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Ljava/lang/Boolean;

    invoke-virtual {p0}, Ljava/lang/Boolean;->booleanValue()Z

    move-result p0

    if-nez p0, :cond_1

    goto :goto_1

    .line 27
    :cond_1
    const-string p0, "top.niunaijun.blackbox.app.BActivityThread"

    invoke-static {p0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p0

    .line 28
    const-string v0, "com.anthropic.claude"

    const-string v2, "getAppPackageName"

    new-array v4, v1, [Ljava/lang/Class;

    invoke-virtual {p0, v2, v4}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    new-array v4, v1, [Ljava/lang/Object;

    invoke-virtual {v2, v3, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {v0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_3

    const-string v0, "getUserId"

    new-array v2, v1, [Ljava/lang/Class;

    .line 29
    invoke-virtual {p0, v0, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    new-array v0, v1, [Ljava/lang/Object;

    invoke-virtual {p0, v3, v0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Ljava/lang/Integer;

    invoke-virtual {p0}, Ljava/lang/Integer;->intValue()I

    move-result p0

    if-nez p0, :cond_3

    const-string p0, "com.google.android.play.core.integrity.protocol.IIntegrityService"

    .line 30
    invoke-interface {p1}, Landroid/os/IBinder;->getInterfaceDescriptor()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_2

    goto :goto_0

    .line 31
    :cond_2
    new-instance p0, Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;

    invoke-direct {p0, p1}, Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;-><init>(Landroid/os/IBinder;)V
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    return-object p0

    .line 30
    :cond_3
    :goto_0
    return-object p1

    .line 26
    :cond_4
    :goto_1
    return-object p1

    .line 32
    :catch_0
    move-exception p0

    .line 33
    new-instance p1, Ljava/lang/SecurityException;

    const-string v0, "Private service identity unavailable"

    invoke-direct {p1, v0, p0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw p1

    .line 20
    :cond_5
    :goto_2
    return-object p1
.end method
