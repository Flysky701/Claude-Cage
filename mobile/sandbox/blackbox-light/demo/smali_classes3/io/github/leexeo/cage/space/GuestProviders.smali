.class public final Lio/github/leexeo/cage/space/GuestProviders;
.super Ljava/lang/Object;
.source "GuestProviders.java"


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 8
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static internal(Ljava/lang/String;)Z
    .locals 1

    .line 10
    const-string v0, "com.google.android.gms"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, "com.android.vending"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    .line 11
    const-string v0, "com.google.android.gsf"

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

    .line 10
    :goto_1
    return p0
.end method

.method public static invoke(Landroid/os/IInterface;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Throwable;
        }
    .end annotation

    .line 15
    const/4 v0, 0x0

    if-nez p2, :cond_0

    move-object p2, v0

    goto :goto_0

    :cond_0
    invoke-virtual {p2}, [Ljava/lang/Object;->clone()Ljava/lang/Object;

    move-result-object p2

    check-cast p2, [Ljava/lang/Object;

    .line 16
    :goto_0
    if-eqz p2, :cond_3

    sget v1, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v2, 0x1f

    if-lt v1, v2, :cond_3

    .line 17
    const-string v1, "top.niunaijun.blackbox.app.BActivityThread"

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    .line 18
    invoke-interface {p0}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    move-result-object v2

    instance-of v2, v2, Landroid/os/Binder;

    .line 19
    const/4 v3, 0x0

    if-eqz v2, :cond_1

    invoke-static {}, Landroid/os/Binder;->getCallingUid()I

    move-result v2

    goto :goto_1

    :cond_1
    const-string v2, "getBUid"

    new-array v4, v3, [Ljava/lang/Class;

    invoke-virtual {v1, v2, v4}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    new-array v4, v3, [Ljava/lang/Object;

    invoke-virtual {v2, v0, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Ljava/lang/Integer;

    invoke-virtual {v2}, Ljava/lang/Integer;->intValue()I

    move-result v2

    .line 20
    :goto_1
    const-string v4, "getAppPackageName"

    new-array v5, v3, [Ljava/lang/Class;

    invoke-virtual {v1, v4, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v4, v3, [Ljava/lang/Object;

    invoke-virtual {v1, v0, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/lang/String;

    .line 21
    nop

    :goto_2
    array-length v1, p2

    if-ge v3, v1, :cond_3

    aget-object v1, p2, v3

    instance-of v1, v1, Landroid/content/AttributionSource;

    if-eqz v1, :cond_2

    .line 22
    aget-object v1, p2, v3

    check-cast v1, Landroid/content/AttributionSource;

    .line 23
    new-instance v4, Landroid/content/AttributionSource$Builder;

    invoke-direct {v4, v1}, Landroid/content/AttributionSource$Builder;-><init>(Landroid/content/AttributionSource;)V

    invoke-virtual {v4}, Landroid/content/AttributionSource$Builder;->build()Landroid/content/AttributionSource;

    move-result-object v1

    .line 24
    const-class v4, Landroid/content/AttributionSource;

    const-string v5, "mAttributionSourceState"

    invoke-virtual {v4, v5}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v4

    .line 25
    const/4 v5, 0x1

    invoke-virtual {v4, v5}, Ljava/lang/reflect/Field;->setAccessible(Z)V

    .line 26
    invoke-virtual {v4, v1}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v4

    .line 27
    invoke-virtual {v4}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v5

    const-string v6, "uid"

    invoke-virtual {v5, v6}, Ljava/lang/Class;->getField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v5

    invoke-virtual {v5, v4, v2}, Ljava/lang/reflect/Field;->setInt(Ljava/lang/Object;I)V

    .line 28
    invoke-virtual {v4}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v5

    const-string v6, "packageName"

    invoke-virtual {v5, v6}, Ljava/lang/Class;->getField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v5

    invoke-virtual {v5, v4, v0}, Ljava/lang/reflect/Field;->set(Ljava/lang/Object;Ljava/lang/Object;)V

    .line 29
    aput-object v1, p2, v3

    .line 21
    :cond_2
    add-int/lit8 v3, v3, 0x1

    goto :goto_2

    .line 32
    :cond_3
    :try_start_0
    invoke-virtual {p1, p0, p2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0
    :try_end_0
    .catch Ljava/lang/reflect/InvocationTargetException; {:try_start_0 .. :try_end_0} :catch_0

    return-object p0

    .line 33
    :catch_0
    move-exception p0

    invoke-virtual {p0}, Ljava/lang/reflect/InvocationTargetException;->getCause()Ljava/lang/Throwable;

    move-result-object p0

    throw p0
.end method
