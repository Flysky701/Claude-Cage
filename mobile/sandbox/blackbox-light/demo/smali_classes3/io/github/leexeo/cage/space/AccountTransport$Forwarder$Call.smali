.class final Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;
.super Ljava/lang/Object;
.source "AccountTransport.java"

# interfaces
.implements Ljava/lang/Runnable;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/AccountTransport$Forwarder;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x12
    name = "Call"
.end annotation


# instance fields
.field final code:I

.field final data:Landroid/os/Parcel;

.field final flags:I

.field private final recycled:Ljava/util/concurrent/atomic/AtomicBoolean;

.field final synthetic this$0:Lio/github/leexeo/cage/space/AccountTransport$Forwarder;


# direct methods
.method constructor <init>(Lio/github/leexeo/cage/space/AccountTransport$Forwarder;IILandroid/os/Parcel;)V
    .locals 0

    .line 141
    iput-object p1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->this$0:Lio/github/leexeo/cage/space/AccountTransport$Forwarder;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 139
    new-instance p1, Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-direct {p1}, Ljava/util/concurrent/atomic/AtomicBoolean;-><init>()V

    iput-object p1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->recycled:Ljava/util/concurrent/atomic/AtomicBoolean;

    .line 141
    iput p2, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->code:I

    iput p3, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->flags:I

    iput-object p4, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->data:Landroid/os/Parcel;

    return-void
.end method

.method private workerRequest()Landroid/os/Parcel;
    .locals 6

    .line 169
    const-string v0, "android.accounts.IAccountAuthenticator"

    invoke-static {}, Landroid/os/StrictMode;->getThreadPolicy()Landroid/os/StrictMode$ThreadPolicy;

    move-result-object v1

    .line 170
    invoke-static {}, Landroid/os/Binder;->clearCallingWorkSource()J

    move-result-wide v2

    .line 173
    :try_start_0
    iget-object v4, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->data:Landroid/os/Parcel;

    const/4 v5, 0x0

    invoke-virtual {v4, v5}, Landroid/os/Parcel;->setDataPosition(I)V

    .line 176
    iget-object v4, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->data:Landroid/os/Parcel;

    invoke-virtual {v4, v0}, Landroid/os/Parcel;->enforceInterface(Ljava/lang/String;)V

    .line 177
    iget-object v4, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->data:Landroid/os/Parcel;

    invoke-virtual {v4}, Landroid/os/Parcel;->dataPosition()I

    move-result v4
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    .line 179
    :try_start_1
    invoke-static {v1}, Landroid/os/StrictMode;->setThreadPolicy(Landroid/os/StrictMode$ThreadPolicy;)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 180
    invoke-static {v2, v3}, Landroid/os/Binder;->restoreCallingWorkSource(J)V

    .line 181
    nop

    .line 182
    invoke-static {}, Landroid/os/Parcel;->obtain()Landroid/os/Parcel;

    move-result-object v1

    .line 188
    :try_start_2
    invoke-virtual {v1, v0}, Landroid/os/Parcel;->writeInterfaceToken(Ljava/lang/String;)V

    .line 189
    iget-object v0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->data:Landroid/os/Parcel;

    iget-object v2, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->data:Landroid/os/Parcel;

    invoke-virtual {v2}, Landroid/os/Parcel;->dataSize()I

    move-result v2

    sub-int/2addr v2, v4

    invoke-virtual {v1, v0, v4, v2}, Landroid/os/Parcel;->appendFrom(Landroid/os/Parcel;II)V

    .line 190
    invoke-virtual {v1, v5}, Landroid/os/Parcel;->setDataPosition(I)V
    :try_end_2
    .catch Ljava/lang/RuntimeException; {:try_start_2 .. :try_end_2} :catch_0
    .catch Ljava/lang/Error; {:try_start_2 .. :try_end_2} :catch_0

    .line 191
    return-object v1

    .line 192
    :catch_0
    move-exception v0

    .line 193
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 194
    throw v0

    .line 180
    :catchall_0
    move-exception v0

    invoke-static {v2, v3}, Landroid/os/Binder;->restoreCallingWorkSource(J)V

    throw v0

    .line 179
    :catchall_1
    move-exception v0

    :try_start_3
    invoke-static {v1}, Landroid/os/StrictMode;->setThreadPolicy(Landroid/os/StrictMode$ThreadPolicy;)V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_2

    .line 180
    invoke-static {v2, v3}, Landroid/os/Binder;->restoreCallingWorkSource(J)V

    .line 181
    throw v0

    .line 180
    :catchall_2
    move-exception v0

    invoke-static {v2, v3}, Landroid/os/Binder;->restoreCallingWorkSource(J)V

    throw v0
.end method


# virtual methods
.method recycle()V
    .locals 3

    .line 198
    iget-object v0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->recycled:Ljava/util/concurrent/atomic/AtomicBoolean;

    const/4 v1, 0x0

    const/4 v2, 0x1

    invoke-virtual {v0, v1, v2}, Ljava/util/concurrent/atomic/AtomicBoolean;->compareAndSet(ZZ)Z

    move-result v0

    if-eqz v0, :cond_0

    iget-object v0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->data:Landroid/os/Parcel;

    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    :cond_0
    return-void
.end method

.method public run()V
    .locals 7

    .line 144
    nop

    .line 146
    const/4 v0, 0x0

    :try_start_0
    iget-object v1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->this$0:Lio/github/leexeo/cage/space/AccountTransport$Forwarder;

    iget-object v1, v1, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->closed:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {v1}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result v1
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_3
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_3
    .catch Ljava/lang/Error; {:try_start_0 .. :try_end_0} :catch_2
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    if-eqz v1, :cond_0

    .line 162
    nop

    .line 163
    nop

    .line 164
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->recycle()V

    .line 146
    return-void

    .line 147
    :cond_0
    :try_start_1
    invoke-direct {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->workerRequest()Landroid/os/Parcel;

    move-result-object v1
    :try_end_1
    .catch Landroid/os/RemoteException; {:try_start_1 .. :try_end_1} :catch_3
    .catch Ljava/lang/RuntimeException; {:try_start_1 .. :try_end_1} :catch_3
    .catch Ljava/lang/Error; {:try_start_1 .. :try_end_1} :catch_2
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 148
    :try_start_2
    invoke-static {}, Landroid/os/Parcel;->obtain()Landroid/os/Parcel;

    move-result-object v0

    .line 151
    iget-object v2, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->this$0:Lio/github/leexeo/cage/space/AccountTransport$Forwarder;

    iget-object v2, v2, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->remote:Landroid/os/IBinder;

    iget v3, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->code:I

    iget v4, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->flags:I

    invoke-interface {v2, v3, v1, v0, v4}, Landroid/os/IBinder;->transact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z

    move-result v2

    if-eqz v2, :cond_3

    .line 154
    invoke-virtual {v0}, Landroid/os/Parcel;->dataSize()I

    move-result v2

    if-eqz v2, :cond_1

    const/4 v2, 0x0

    invoke-virtual {v0, v2}, Landroid/os/Parcel;->setDataPosition(I)V

    invoke-virtual {v0}, Landroid/os/Parcel;->readException()V
    :try_end_2
    .catch Landroid/os/RemoteException; {:try_start_2 .. :try_end_2} :catch_1
    .catch Ljava/lang/RuntimeException; {:try_start_2 .. :try_end_2} :catch_1
    .catch Ljava/lang/Error; {:try_start_2 .. :try_end_2} :catch_0
    .catchall {:try_start_2 .. :try_end_2} :catchall_2

    .line 162
    :cond_1
    if-eqz v0, :cond_2

    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    .line 163
    :cond_2
    if-eqz v1, :cond_5

    goto :goto_2

    .line 151
    :cond_3
    :try_start_3
    invoke-static {}, Lio/github/leexeo/cage/space/AccountTransport;->access$000()Landroid/os/RemoteException;

    move-result-object v2

    throw v2
    :try_end_3
    .catch Landroid/os/RemoteException; {:try_start_3 .. :try_end_3} :catch_1
    .catch Ljava/lang/RuntimeException; {:try_start_3 .. :try_end_3} :catch_1
    .catch Ljava/lang/Error; {:try_start_3 .. :try_end_3} :catch_0
    .catchall {:try_start_3 .. :try_end_3} :catchall_2

    .line 159
    :catch_0
    move-exception v2

    move-object v6, v1

    move-object v1, v0

    move-object v0, v6

    goto :goto_0

    .line 155
    :catch_1
    move-exception v2

    goto :goto_1

    .line 162
    :catchall_0
    move-exception v2

    move-object v1, v0

    goto :goto_3

    .line 159
    :catch_2
    move-exception v2

    move-object v1, v0

    .line 160
    :goto_0
    :try_start_4
    iget-object v3, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->this$0:Lio/github/leexeo/cage/space/AccountTransport$Forwarder;

    invoke-virtual {v3}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->close()V

    throw v2
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_1

    .line 162
    :catchall_1
    move-exception v2

    move-object v6, v1

    move-object v1, v0

    move-object v0, v6

    goto :goto_3

    .line 155
    :catch_3
    move-exception v2

    move-object v1, v0

    .line 157
    :goto_1
    :try_start_5
    const-string v3, "CageAccountTransport"

    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    const-string v5, "Private channel closed: "

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v2}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v4, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-static {v3, v2}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 158
    iget-object v2, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->this$0:Lio/github/leexeo/cage/space/AccountTransport$Forwarder;

    invoke-virtual {v2}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->close()V
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_2

    .line 162
    if-eqz v0, :cond_4

    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    .line 163
    :cond_4
    if-eqz v1, :cond_5

    :goto_2
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 164
    :cond_5
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->recycle()V

    .line 165
    nop

    .line 166
    return-void

    .line 162
    :catchall_2
    move-exception v2

    :goto_3
    if-eqz v0, :cond_6

    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    .line 163
    :cond_6
    if-eqz v1, :cond_7

    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 164
    :cond_7
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->recycle()V

    .line 165
    throw v2
.end method
