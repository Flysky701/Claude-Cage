.class final Lio/github/leexeo/cage/space/GuestIntegrityTrace$Service;
.super Landroid/os/Binder;
.source "GuestIntegrityTrace.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/GuestIntegrityTrace;
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

    .line 173
    invoke-direct {p0}, Landroid/os/Binder;-><init>()V

    .line 174
    iput-object p1, p0, Lio/github/leexeo/cage/space/GuestIntegrityTrace$Service;->remote:Landroid/os/IBinder;

    .line 175
    const/4 p1, 0x0

    const-string v0, "com.google.android.play.core.integrity.protocol.IIntegrityService"

    invoke-virtual {p0, p1, v0}, Lio/github/leexeo/cage/space/GuestIntegrityTrace$Service;->attachInterface(Landroid/os/IInterface;Ljava/lang/String;)V

    .line 176
    return-void
.end method

.method private withObservedCallback(Landroid/os/Parcel;)Landroid/os/Parcel;
    .locals 7

    .line 190
    const-string v0, "CageIntegrity"

    invoke-static {}, Landroid/os/Parcel;->obtain()Landroid/os/Parcel;

    move-result-object v1

    .line 191
    nop

    .line 193
    const/4 v2, 0x0

    :try_start_0
    invoke-virtual {p1}, Landroid/os/Parcel;->dataSize()I

    move-result v3

    const/4 v4, 0x0

    invoke-virtual {v1, p1, v4, v3}, Landroid/os/Parcel;->appendFrom(Landroid/os/Parcel;II)V

    .line 194
    invoke-virtual {v1, v4}, Landroid/os/Parcel;->setDataPosition(I)V

    .line 195
    const-string v3, "com.google.android.play.core.integrity.protocol.IIntegrityService"

    invoke-virtual {v1, v3}, Landroid/os/Parcel;->enforceInterface(Ljava/lang/String;)V

    .line 196
    invoke-virtual {v1}, Landroid/os/Parcel;->readInt()I

    move-result v3
    :try_end_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_1
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    const/4 v5, 0x1

    if-eq v3, v5, :cond_0

    .line 213
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 196
    return-object v2

    .line 197
    :cond_0
    :try_start_1
    sget-object v3, Landroid/os/Bundle;->CREATOR:Landroid/os/Parcelable$Creator;

    invoke-interface {v3, v1}, Landroid/os/Parcelable$Creator;->createFromParcel(Landroid/os/Parcel;)Ljava/lang/Object;

    .line 198
    invoke-virtual {v1}, Landroid/os/Parcel;->dataPosition()I

    move-result v3

    .line 199
    invoke-virtual {v1}, Landroid/os/Parcel;->readStrongBinder()Landroid/os/IBinder;

    move-result-object v5

    .line 200
    if-eqz v5, :cond_2

    invoke-virtual {v1}, Landroid/os/Parcel;->dataAvail()I

    move-result v6

    if-eqz v6, :cond_1

    goto :goto_0

    .line 201
    :cond_1
    invoke-static {}, Landroid/os/Parcel;->obtain()Landroid/os/Parcel;

    move-result-object v6
    :try_end_1
    .catch Ljava/lang/RuntimeException; {:try_start_1 .. :try_end_1} :catch_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 203
    :try_start_2
    invoke-virtual {v6, p1, v4, v3}, Landroid/os/Parcel;->appendFrom(Landroid/os/Parcel;II)V

    .line 204
    invoke-virtual {v6, v3}, Landroid/os/Parcel;->setDataPosition(I)V

    .line 205
    new-instance p1, Lio/github/leexeo/cage/space/GuestIntegrityTrace$Callback;

    invoke-direct {p1, v5}, Lio/github/leexeo/cage/space/GuestIntegrityTrace$Callback;-><init>(Landroid/os/IBinder;)V

    invoke-virtual {v6, p1}, Landroid/os/Parcel;->writeStrongBinder(Landroid/os/IBinder;)V

    .line 206
    const-string p1, "Classic request forwarded with original payload"

    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/RuntimeException; {:try_start_2 .. :try_end_2} :catch_0
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    .line 207
    nop

    .line 213
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 207
    return-object v6

    .line 208
    :catch_0
    move-exception p1

    goto :goto_1

    .line 213
    :cond_2
    :goto_0
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 200
    return-object v2

    .line 213
    :catchall_0
    move-exception p1

    goto :goto_2

    .line 208
    :catch_1
    move-exception p1

    move-object v6, v2

    .line 209
    :goto_1
    if-eqz v6, :cond_3

    :try_start_3
    invoke-virtual {v6}, Landroid/os/Parcel;->recycle()V

    .line 210
    :cond_3
    const-string p1, "Unknown request shape; original request retained"

    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 211
    nop

    .line 213
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 211
    return-object v2

    .line 213
    :goto_2
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 214
    throw p1
.end method


# virtual methods
.method protected onTransact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Landroid/os/RemoteException;
        }
    .end annotation

    .line 180
    const/4 v0, 0x2

    if-ne p1, v0, :cond_0

    invoke-direct {p0, p2}, Lio/github/leexeo/cage/space/GuestIntegrityTrace$Service;->withObservedCallback(Landroid/os/Parcel;)Landroid/os/Parcel;

    move-result-object v0

    goto :goto_0

    :cond_0
    const/4 v0, 0x0

    .line 183
    :goto_0
    :try_start_0
    iget-object v1, p0, Lio/github/leexeo/cage/space/GuestIntegrityTrace$Service;->remote:Landroid/os/IBinder;

    if-nez v0, :cond_1

    goto :goto_1

    :cond_1
    move-object p2, v0

    :goto_1
    invoke-interface {v1, p1, p2, p3, p4}, Landroid/os/IBinder;->transact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z

    move-result p1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 185
    if-eqz v0, :cond_2

    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    .line 183
    :cond_2
    return p1

    .line 185
    :catchall_0
    move-exception p1

    if-eqz v0, :cond_3

    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    .line 186
    :cond_3
    throw p1
.end method
