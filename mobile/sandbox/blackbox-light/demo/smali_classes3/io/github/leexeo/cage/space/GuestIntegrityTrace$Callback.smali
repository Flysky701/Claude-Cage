.class final Lio/github/leexeo/cage/space/GuestIntegrityTrace$Callback;
.super Landroid/os/Binder;
.source "GuestIntegrityTrace.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/GuestIntegrityTrace;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x18
    name = "Callback"
.end annotation


# instance fields
.field private final remote:Landroid/os/IBinder;


# direct methods
.method constructor <init>(Landroid/os/IBinder;)V
    .locals 1

    .line 220
    invoke-direct {p0}, Landroid/os/Binder;-><init>()V

    .line 221
    iput-object p1, p0, Lio/github/leexeo/cage/space/GuestIntegrityTrace$Callback;->remote:Landroid/os/IBinder;

    .line 222
    const/4 p1, 0x0

    const-string v0, "com.google.android.play.core.integrity.protocol.IIntegrityServiceCallback"

    invoke-virtual {p0, p1, v0}, Lio/github/leexeo/cage/space/GuestIntegrityTrace$Callback;->attachInterface(Landroid/os/IInterface;Ljava/lang/String;)V

    .line 223
    return-void
.end method

.method private inspect(Landroid/os/Parcel;)V
    .locals 7

    .line 232
    const-string v0, "CageIntegrity"

    invoke-static {}, Landroid/os/Parcel;->obtain()Landroid/os/Parcel;

    move-result-object v1

    .line 234
    :try_start_0
    invoke-virtual {p1}, Landroid/os/Parcel;->dataSize()I

    move-result v2

    const/4 v3, 0x0

    invoke-virtual {v1, p1, v3, v2}, Landroid/os/Parcel;->appendFrom(Landroid/os/Parcel;II)V

    .line 235
    invoke-virtual {v1, v3}, Landroid/os/Parcel;->setDataPosition(I)V

    .line 236
    const-string p1, "com.google.android.play.core.integrity.protocol.IIntegrityServiceCallback"

    invoke-virtual {v1, p1}, Landroid/os/Parcel;->enforceInterface(Ljava/lang/String;)V

    .line 237
    invoke-virtual {v1}, Landroid/os/Parcel;->readInt()I

    move-result p1
    :try_end_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    const/4 v2, 0x1

    if-eq p1, v2, :cond_0

    .line 247
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 237
    return-void

    .line 238
    :cond_0
    :try_start_1
    sget-object p1, Landroid/os/Bundle;->CREATOR:Landroid/os/Parcelable$Creator;

    invoke-interface {p1, v1}, Landroid/os/Parcelable$Creator;->createFromParcel(Landroid/os/Parcel;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Landroid/os/Bundle;

    .line 239
    invoke-virtual {v1}, Landroid/os/Parcel;->dataAvail()I

    move-result v4
    :try_end_1
    .catch Ljava/lang/RuntimeException; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    if-eqz v4, :cond_1

    .line 247
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 239
    return-void

    .line 240
    :cond_1
    :try_start_2
    const-string v4, "error"

    invoke-virtual {p1, v4}, Landroid/os/Bundle;->getInt(Ljava/lang/String;)I

    move-result v4

    .line 241
    const-string v5, "token"

    invoke-virtual {p1, v5}, Landroid/os/Bundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    .line 242
    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    const-string v6, "Classic response error="

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5, v4}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v4

    const-string v5, " tokenPresent="

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    if-eqz p1, :cond_2

    .line 243
    invoke-virtual {p1}, Ljava/lang/String;->isEmpty()Z

    move-result p1

    if-nez p1, :cond_2

    move v3, v2

    goto :goto_0

    :cond_2
    nop

    :goto_0
    invoke-virtual {v4, v3}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    .line 242
    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/RuntimeException; {:try_start_2 .. :try_end_2} :catch_0
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    goto :goto_1

    .line 247
    :catchall_0
    move-exception p1

    goto :goto_2

    .line 244
    :catch_0
    move-exception p1

    .line 245
    :try_start_3
    const-string p1, "Unknown callback shape; original result retained"

    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 247
    :goto_1
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 248
    nop

    .line 249
    return-void

    .line 247
    :goto_2
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 248
    throw p1
.end method


# virtual methods
.method protected onTransact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Landroid/os/RemoteException;
        }
    .end annotation

    .line 227
    const/4 v0, 0x2

    if-ne p1, v0, :cond_0

    invoke-direct {p0, p2}, Lio/github/leexeo/cage/space/GuestIntegrityTrace$Callback;->inspect(Landroid/os/Parcel;)V

    .line 228
    :cond_0
    iget-object v0, p0, Lio/github/leexeo/cage/space/GuestIntegrityTrace$Callback;->remote:Landroid/os/IBinder;

    invoke-interface {v0, p1, p2, p3, p4}, Landroid/os/IBinder;->transact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z

    move-result p1

    return p1
.end method
