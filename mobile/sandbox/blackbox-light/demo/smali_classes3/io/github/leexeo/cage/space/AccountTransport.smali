.class public final Lio/github/leexeo/cage/space/AccountTransport;
.super Ljava/lang/Object;
.source "AccountTransport.java"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lio/github/leexeo/cage/space/AccountTransport$Forwarder;
    }
.end annotation


# static fields
.field private static final DESCRIPTOR:Ljava/lang/String; = "android.accounts.IAccountAuthenticator"

.field private static final MAX_PARCEL_BYTES:I = 0x100000

.field private static final MAX_PENDING:I = 0x20

.field private static final SERVICE:Ljava/lang/String; = "org.microg.gms.auth.loginservice.GoogleLoginService"

.field private static final channels:Ljava/util/concurrent/ConcurrentHashMap;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/concurrent/ConcurrentHashMap<",
            "Landroid/os/IBinder;",
            "Lio/github/leexeo/cage/space/AccountTransport$Forwarder;",
            ">;"
        }
    .end annotation
.end field


# direct methods
.method static constructor <clinit>()V
    .locals 1

    .line 25
    new-instance v0, Ljava/util/concurrent/ConcurrentHashMap;

    invoke-direct {v0}, Ljava/util/concurrent/ConcurrentHashMap;-><init>()V

    sput-object v0, Lio/github/leexeo/cage/space/AccountTransport;->channels:Ljava/util/concurrent/ConcurrentHashMap;

    return-void
.end method

.method private constructor <init>()V
    .locals 0

    .line 27
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method static synthetic access$000()Landroid/os/RemoteException;
    .locals 1

    .line 21
    invoke-static {}, Lio/github/leexeo/cage/space/AccountTransport;->unavailable()Landroid/os/RemoteException;

    move-result-object v0

    return-object v0
.end method

.method static synthetic access$100()Ljava/util/concurrent/ConcurrentHashMap;
    .locals 1

    .line 21
    sget-object v0, Lio/github/leexeo/cage/space/AccountTransport;->channels:Ljava/util/concurrent/ConcurrentHashMap;

    return-object v0
.end method

.method private static unavailable()Landroid/os/RemoteException;
    .locals 2

    .line 202
    new-instance v0, Landroid/os/RemoteException;

    const-string v1, "Private authenticator channel unavailable"

    invoke-direct {v0, v1}, Landroid/os/RemoteException;-><init>(Ljava/lang/String;)V

    return-object v0
.end method

.method public static wrap(Landroid/content/ComponentName;Landroid/os/IBinder;)Landroid/os/IBinder;
    .locals 3

    .line 30
    const-string v0, "Private authenticator unavailable"

    if-eqz p0, :cond_6

    if-eqz p1, :cond_6

    const-string v1, "com.google.android.gms"

    invoke-virtual {p0}, Landroid/content/ComponentName;->getPackageName()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_6

    .line 31
    invoke-virtual {p0}, Landroid/content/ComponentName;->getClassName()Ljava/lang/String;

    move-result-object p0

    const-string v1, "org.microg.gms.auth.loginservice.GoogleLoginService"

    invoke-virtual {v1, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_0

    goto :goto_0

    .line 32
    :cond_0
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object p0

    invoke-static {p0}, Ljava/lang/reflect/Proxy;->isProxyClass(Ljava/lang/Class;)Z

    move-result p0

    if-eqz p0, :cond_1

    invoke-static {p1}, Ljava/lang/reflect/Proxy;->getInvocationHandler(Ljava/lang/Object;)Ljava/lang/reflect/InvocationHandler;

    move-result-object p0

    instance-of p0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;

    if-eqz p0, :cond_1

    .line 33
    return-object p1

    .line 35
    :cond_1
    :try_start_0
    const-string p0, "android.accounts.IAccountAuthenticator"

    invoke-interface {p1}, Landroid/os/IBinder;->getInterfaceDescriptor()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_1

    if-nez p0, :cond_2

    return-object p1

    .line 38
    :cond_2
    nop

    .line 39
    sget-object p0, Lio/github/leexeo/cage/space/AccountTransport;->channels:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {p0, p1}, Ljava/util/concurrent/ConcurrentHashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;

    .line 40
    if-eqz p0, :cond_3

    iget-object p0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->proxy:Landroid/os/IBinder;

    return-object p0

    .line 41
    :cond_3
    new-instance p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;

    invoke-direct {p0, p1}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;-><init>(Landroid/os/IBinder;)V

    .line 42
    sget-object v1, Lio/github/leexeo/cage/space/AccountTransport;->channels:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {v1, p1, p0}, Ljava/util/concurrent/ConcurrentHashMap;->putIfAbsent(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;

    .line 43
    if-eqz v1, :cond_4

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->close()V

    iget-object p0, v1, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->proxy:Landroid/os/IBinder;

    return-object p0

    .line 45
    :cond_4
    const/4 v1, 0x0

    :try_start_1
    invoke-interface {p1, p0, v1}, Landroid/os/IBinder;->linkToDeath(Landroid/os/IBinder$DeathRecipient;I)V

    .line 46
    iget-object p1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->linked:Ljava/util/concurrent/atomic/AtomicBoolean;

    const/4 v1, 0x1

    invoke-virtual {p1, v1}, Ljava/util/concurrent/atomic/AtomicBoolean;->set(Z)V

    .line 48
    iget-object p1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->closed:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {p1}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result p1

    if-eqz p1, :cond_5

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->unlink()V
    :try_end_1
    .catch Landroid/os/RemoteException; {:try_start_1 .. :try_end_1} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_1 .. :try_end_1} :catch_0

    .line 52
    :cond_5
    nop

    .line 53
    iget-object p0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->proxy:Landroid/os/IBinder;

    return-object p0

    .line 49
    :catch_0
    move-exception p1

    .line 50
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->close()V

    .line 51
    new-instance p0, Ljava/lang/IllegalStateException;

    invoke-direct {p0, v0, p1}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw p0

    .line 36
    :catch_1
    move-exception p0

    .line 37
    new-instance p1, Ljava/lang/IllegalStateException;

    invoke-direct {p1, v0, p0}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw p1

    .line 31
    :cond_6
    :goto_0
    return-object p1
.end method
