.class public Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;
.super Landroid/app/IServiceConnection$Stub;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# static fields
.field private static final sServiceConnectDelegate:Ljava/util/Map;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/Map<",
            "Landroid/os/IBinder;",
            "Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;",
            ">;"
        }
    .end annotation
.end field


# instance fields
.field private final mComponentName:Landroid/content/ComponentName;

.field private final mConn:Landroid/app/IServiceConnection;


# direct methods
.method static constructor <clinit>()V
    .locals 1

    .line 1
    new-instance v0, Ljava/util/HashMap;

    .line 2
    .line 3
    invoke-direct {v0}, Ljava/util/HashMap;-><init>()V

    .line 4
    .line 5
    .line 6
    sput-object v0, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->sServiceConnectDelegate:Ljava/util/Map;

    .line 7
    .line 8
    return-void
.end method

.method private constructor <init>(Landroid/app/IServiceConnection;Landroid/content/ComponentName;)V
    .locals 0

    .line 1
    invoke-direct {p0}, Landroid/app/IServiceConnection$Stub;-><init>()V

    .line 2
    .line 3
    .line 4
    iput-object p1, p0, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->mConn:Landroid/app/IServiceConnection;

    .line 5
    .line 6
    iput-object p2, p0, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->mComponentName:Landroid/content/ComponentName;

    .line 7
    .line 8
    return-void
.end method

.method public static bridge synthetic a()Ljava/util/Map;
    .locals 1

    .line 1
    sget-object v0, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->sServiceConnectDelegate:Ljava/util/Map;

    .line 2
    .line 3
    return-object v0
.end method

.method public static createProxy(Landroid/app/IServiceConnection;Landroid/content/Intent;)Landroid/app/IServiceConnection;
    .locals 3

    .line 1
    invoke-interface {p0}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    sget-object v1, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->sServiceConnectDelegate:Ljava/util/Map;

    .line 6
    .line 7
    invoke-interface {v1, v0}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 8
    .line 9
    .line 10
    move-result-object v1

    .line 11
    check-cast v1, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;

    .line 12
    .line 13
    if-nez v1, :cond_0

    .line 14
    .line 15
    :try_start_0
    new-instance v1, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate$1;

    .line 16
    .line 17
    invoke-direct {v1, v0}, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate$1;-><init>(Landroid/os/IBinder;)V

    .line 18
    .line 19
    .line 20
    const/4 v2, 0x0

    .line 21
    invoke-interface {v0, v1, v2}, Landroid/os/IBinder;->linkToDeath(Landroid/os/IBinder$DeathRecipient;I)V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    .line 22
    .line 23
    .line 24
    goto :goto_0

    .line 25
    :catch_0
    move-exception v1

    .line 26
    invoke-virtual {v1}, Ljava/lang/Throwable;->printStackTrace()V

    .line 27
    .line 28
    .line 29
    :goto_0
    new-instance v1, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;

    .line 30
    .line 31
    invoke-virtual {p1}, Landroid/content/Intent;->getComponent()Landroid/content/ComponentName;

    .line 32
    .line 33
    .line 34
    move-result-object p1

    .line 35
    invoke-direct {v1, p0, p1}, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;-><init>(Landroid/app/IServiceConnection;Landroid/content/ComponentName;)V

    .line 36
    .line 37
    .line 38
    sget-object p0, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->sServiceConnectDelegate:Ljava/util/Map;

    .line 39
    .line 40
    invoke-interface {p0, v0, v1}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 41
    .line 42
    .line 43
    :cond_0
    return-object v1
.end method

.method public static getDelegate(Landroid/os/IBinder;)Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;
    .locals 1

    .line 1
    sget-object v0, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->sServiceConnectDelegate:Ljava/util/Map;

    .line 2
    .line 3
    invoke-interface {v0, p0}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 4
    .line 5
    .line 6
    move-result-object p0

    .line 7
    check-cast p0, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;

    .line 8
    .line 9
    return-object p0
.end method


# virtual methods
.method public connected(Landroid/content/ComponentName;Landroid/os/IBinder;)V
    .locals 1

    const/4 v0, 0x0

    .line 1
    invoke-virtual {p0, p1, p2, v0}, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->connected(Landroid/content/ComponentName;Landroid/os/IBinder;Z)V

    return-void
.end method

.method public connected(Landroid/content/ComponentName;Landroid/os/IBinder;Z)V
    .locals 2

    iget-object v0, p0, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->mComponentName:Landroid/content/ComponentName;

    invoke-static {v0, p2}, Lio/github/leexeo/cage/space/GuestIntegrityTransport;->adapt(Landroid/content/ComponentName;Landroid/os/IBinder;)Landroid/os/IBinder;

    move-result-object p2

    .line 2
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isOreo()Z

    move-result v0

    if-eqz v0, :cond_0

    .line 3
    iget-object p1, p0, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->mConn:Landroid/app/IServiceConnection;

    .line 4
    const-class v0, Lblack/android/app/IServiceConnectionOContext;

    const/4 v1, 0x0

    invoke-static {v0, p1, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Lblack/android/app/IServiceConnectionOContext;

    .line 5
    iget-object v0, p0, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->mComponentName:Landroid/content/ComponentName;

    invoke-interface {p1, v0, p2, p3}, Lblack/android/app/IServiceConnectionOContext;->connected(Landroid/content/ComponentName;Landroid/os/IBinder;Z)Ljava/lang/Void;

    return-void

    .line 6
    :cond_0
    iget-object p3, p0, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->mConn:Landroid/app/IServiceConnection;

    invoke-interface {p3, p1, p2}, Landroid/app/IServiceConnection;->connected(Landroid/content/ComponentName;Landroid/os/IBinder;)V

    return-void
.end method

.method public onTransact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z
    .locals 3

    .line 1
    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    .line 2
    .line 3
    const/16 v1, 0x25

    .line 4
    .line 5
    if-lt v0, v1, :cond_3

    .line 6
    .line 7
    const/4 v0, 0x1

    .line 8
    if-ne p1, v0, :cond_3

    .line 9
    .line 10
    const-string p1, "android.app.IServiceConnection"

    .line 11
    .line 12
    invoke-virtual {p2, p1}, Landroid/os/Parcel;->enforceInterface(Ljava/lang/String;)V

    .line 13
    .line 14
    .line 15
    invoke-virtual {p2}, Landroid/os/Parcel;->readInt()I

    .line 16
    .line 17
    .line 18
    move-result p1

    .line 19
    if-eqz p1, :cond_0

    .line 20
    .line 21
    sget-object p1, Landroid/content/ComponentName;->CREATOR:Landroid/os/Parcelable$Creator;

    .line 22
    .line 23
    invoke-interface {p1, p2}, Landroid/os/Parcelable$Creator;->createFromParcel(Landroid/os/Parcel;)Ljava/lang/Object;

    .line 24
    .line 25
    .line 26
    move-result-object p1

    .line 27
    check-cast p1, Landroid/content/ComponentName;

    .line 28
    .line 29
    goto :goto_0

    .line 30
    :cond_0
    const/4 p1, 0x0

    .line 31
    :goto_0
    invoke-virtual {p2}, Landroid/os/Parcel;->readStrongBinder()Landroid/os/IBinder;

    .line 32
    .line 33
    .line 34
    move-result-object p4

    .line 35
    invoke-virtual {p2}, Landroid/os/Parcel;->dataAvail()I

    .line 36
    .line 37
    .line 38
    move-result v1

    .line 39
    const/4 v2, 0x4

    .line 40
    if-le v1, v2, :cond_1

    .line 41
    .line 42
    invoke-virtual {p2}, Landroid/os/Parcel;->readStrongBinder()Landroid/os/IBinder;

    .line 43
    .line 44
    .line 45
    :cond_1
    invoke-static {p2}, Lm1/z;->h(Landroid/os/Parcel;)Z

    .line 46
    .line 47
    .line 48
    move-result p2

    .line 49
    invoke-virtual {p0, p1, p4, p2}, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->connected(Landroid/content/ComponentName;Landroid/os/IBinder;Z)V

    .line 50
    .line 51
    .line 52
    if-eqz p3, :cond_2

    .line 53
    .line 54
    invoke-virtual {p3}, Landroid/os/Parcel;->writeNoException()V

    .line 55
    .line 56
    .line 57
    :cond_2
    return v0

    .line 58
    :cond_3
    invoke-super {p0, p1, p2, p3, p4}, Landroid/app/IServiceConnection$Stub;->onTransact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z

    .line 59
    .line 60
    .line 61
    move-result p1

    .line 62
    return p1
.end method
