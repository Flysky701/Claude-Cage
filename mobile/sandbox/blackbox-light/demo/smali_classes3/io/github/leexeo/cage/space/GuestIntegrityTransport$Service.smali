.class final Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;
.super Landroid/os/Binder;
.source "GuestIntegrityTransport.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/GuestIntegrityTransport;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x18
    name = "Service"
.end annotation


# instance fields
.field private final remote:Landroid/os/IBinder;


# direct methods
.method constructor <init>(Landroid/os/IBinder;)V
    .locals 1

    .line 40
    invoke-direct {p0}, Landroid/os/Binder;-><init>()V

    .line 41
    iput-object p1, p0, Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;->remote:Landroid/os/IBinder;

    .line 42
    const/4 p1, 0x0

    const-string v0, "com.google.android.play.core.integrity.protocol.IIntegrityService"

    invoke-virtual {p0, p1, v0}, Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;->attachInterface(Landroid/os/IInterface;Ljava/lang/String;)V

    .line 43
    return-void
.end method

.method private static rethrow(Ljava/lang/Throwable;)V
    .locals 0
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "<E:",
            "Ljava/lang/Throwable;",
            ">(",
            "Ljava/lang/Throwable;",
            ")V^TE;"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Throwable;
        }
    .end annotation

    .line 57
    throw p0
.end method


# virtual methods
.method public isBinderAlive()Z
    .locals 1

    .line 46
    iget-object v0, p0, Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;->remote:Landroid/os/IBinder;

    invoke-interface {v0}, Landroid/os/IBinder;->isBinderAlive()Z

    move-result v0

    return v0
.end method

.method public linkToDeath(Landroid/os/IBinder$DeathRecipient;I)V
    .locals 1

    .line 49
    :try_start_0
    iget-object v0, p0, Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;->remote:Landroid/os/IBinder;

    invoke-interface {v0, p1, p2}, Landroid/os/IBinder;->linkToDeath(Landroid/os/IBinder$DeathRecipient;I)V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    .line 54
    goto :goto_0

    .line 50
    :catch_0
    move-exception p1

    .line 53
    invoke-static {p1}, Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;->rethrow(Ljava/lang/Throwable;)V

    .line 55
    :goto_0
    return-void
.end method

.method protected onTransact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Landroid/os/RemoteException;
        }
    .end annotation

    .line 64
    const/4 v0, 0x2

    if-ne p1, v0, :cond_1

    const/4 v0, 0x1

    if-eq p4, v0, :cond_0

    goto :goto_0

    .line 72
    :cond_0
    invoke-static {}, Landroid/os/Parcel;->obtain()Landroid/os/Parcel;

    move-result-object p3

    .line 74
    :try_start_0
    iget-object p4, p0, Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;->remote:Landroid/os/IBinder;

    const/4 v0, 0x0

    invoke-interface {p4, p1, p2, p3, v0}, Landroid/os/IBinder;->transact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z

    move-result p1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 76
    invoke-virtual {p3}, Landroid/os/Parcel;->recycle()V

    .line 74
    return p1

    .line 76
    :catchall_0
    move-exception p1

    invoke-virtual {p3}, Landroid/os/Parcel;->recycle()V

    .line 77
    throw p1

    .line 65
    :cond_1
    :goto_0
    iget-object v0, p0, Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;->remote:Landroid/os/IBinder;

    invoke-interface {v0, p1, p2, p3, p4}, Landroid/os/IBinder;->transact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z

    move-result p1

    return p1
.end method

.method public pingBinder()Z
    .locals 1

    .line 45
    iget-object v0, p0, Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;->remote:Landroid/os/IBinder;

    invoke-interface {v0}, Landroid/os/IBinder;->pingBinder()Z

    move-result v0

    return v0
.end method

.method public unlinkToDeath(Landroid/os/IBinder$DeathRecipient;I)Z
    .locals 1

    .line 59
    iget-object v0, p0, Lio/github/leexeo/cage/space/GuestIntegrityTransport$Service;->remote:Landroid/os/IBinder;

    invoke-interface {v0, p1, p2}, Landroid/os/IBinder;->unlinkToDeath(Landroid/os/IBinder$DeathRecipient;I)Z

    move-result p1

    return p1
.end method
