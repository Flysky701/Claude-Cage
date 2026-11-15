.class final Lio/github/leexeo/cage/space/AccountTransport$Forwarder;
.super Ljava/lang/Object;
.source "AccountTransport.java"

# interfaces
.implements Ljava/lang/reflect/InvocationHandler;
.implements Landroid/os/IBinder$DeathRecipient;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/AccountTransport;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Forwarder"
.end annotation

.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;
    }
.end annotation


# instance fields
.field final closed:Ljava/util/concurrent/atomic/AtomicBoolean;

.field private final enqueueLock:Ljava/lang/Object;

.field final linked:Ljava/util/concurrent/atomic/AtomicBoolean;

.field final proxy:Landroid/os/IBinder;

.field final remote:Landroid/os/IBinder;

.field private final worker:Ljava/util/concurrent/ThreadPoolExecutor;


# direct methods
.method constructor <init>(Landroid/os/IBinder;)V
    .locals 10

    .line 67
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 58
    new-instance v0, Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-direct {v0}, Ljava/util/concurrent/atomic/AtomicBoolean;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->closed:Ljava/util/concurrent/atomic/AtomicBoolean;

    new-instance v0, Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-direct {v0}, Ljava/util/concurrent/atomic/AtomicBoolean;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->linked:Ljava/util/concurrent/atomic/AtomicBoolean;

    .line 59
    new-instance v0, Ljava/lang/Object;

    invoke-direct {v0}, Ljava/lang/Object;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->enqueueLock:Ljava/lang/Object;

    .line 60
    new-instance v1, Ljava/util/concurrent/ThreadPoolExecutor;

    sget-object v6, Ljava/util/concurrent/TimeUnit;->SECONDS:Ljava/util/concurrent/TimeUnit;

    new-instance v7, Ljava/util/concurrent/ArrayBlockingQueue;

    const/16 v0, 0x20

    invoke-direct {v7, v0}, Ljava/util/concurrent/ArrayBlockingQueue;-><init>(I)V

    new-instance v8, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$$ExternalSyntheticLambda0;

    invoke-direct {v8}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$$ExternalSyntheticLambda0;-><init>()V

    new-instance v9, Ljava/util/concurrent/ThreadPoolExecutor$AbortPolicy;

    invoke-direct {v9}, Ljava/util/concurrent/ThreadPoolExecutor$AbortPolicy;-><init>()V

    const/4 v2, 0x1

    const/4 v3, 0x1

    const-wide/16 v4, 0x1e

    invoke-direct/range {v1 .. v9}, Ljava/util/concurrent/ThreadPoolExecutor;-><init>(IIJLjava/util/concurrent/TimeUnit;Ljava/util/concurrent/BlockingQueue;Ljava/util/concurrent/ThreadFactory;Ljava/util/concurrent/RejectedExecutionHandler;)V

    iput-object v1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->worker:Ljava/util/concurrent/ThreadPoolExecutor;

    .line 68
    iput-object p1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->remote:Landroid/os/IBinder;

    .line 69
    const-class p1, Lio/github/leexeo/cage/space/AccountTransport;

    invoke-virtual {p1}, Ljava/lang/Class;->getClassLoader()Ljava/lang/ClassLoader;

    move-result-object p1

    const-class v0, Landroid/os/IBinder;

    filled-new-array {v0}, [Ljava/lang/Class;

    move-result-object v0

    invoke-static {p1, v0, p0}, Ljava/lang/reflect/Proxy;->newProxyInstance(Ljava/lang/ClassLoader;[Ljava/lang/Class;Ljava/lang/reflect/InvocationHandler;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Landroid/os/IBinder;

    iput-object p1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->proxy:Landroid/os/IBinder;

    .line 71
    iget-object p1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->worker:Ljava/util/concurrent/ThreadPoolExecutor;

    const/4 v0, 0x1

    invoke-virtual {p1, v0}, Ljava/util/concurrent/ThreadPoolExecutor;->allowCoreThreadTimeOut(Z)V

    .line 72
    return-void
.end method

.method private enqueue(ILandroid/os/Parcel;I)Z
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Landroid/os/RemoteException;
        }
    .end annotation

    .line 89
    iget-object v0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->enqueueLock:Ljava/lang/Object;

    monitor-enter v0

    .line 90
    :try_start_0
    iget-object v1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->closed:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {v1}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result v1

    if-nez v1, :cond_2

    iget-object v1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->remote:Landroid/os/IBinder;

    invoke-interface {v1}, Landroid/os/IBinder;->isBinderAlive()Z

    move-result v1

    if-eqz v1, :cond_2

    .line 93
    if-eqz p2, :cond_1

    invoke-virtual {p2}, Landroid/os/Parcel;->dataSize()I

    move-result v1

    const/high16 v2, 0x100000

    if-gt v1, v2, :cond_1

    .line 96
    invoke-static {}, Landroid/os/Parcel;->obtain()Landroid/os/Parcel;

    move-result-object v1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    .line 97
    nop

    .line 98
    nop

    .line 102
    const/4 v2, 0x0

    :try_start_1
    invoke-virtual {p2}, Landroid/os/Parcel;->dataSize()I

    move-result v3

    const/4 v4, 0x0

    invoke-virtual {v1, p2, v4, v3}, Landroid/os/Parcel;->appendFrom(Landroid/os/Parcel;II)V

    .line 103
    invoke-virtual {v1, v4}, Landroid/os/Parcel;->setDataPosition(I)V

    .line 104
    new-instance p2, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;

    and-int/lit8 p3, p3, -0x2

    invoke-direct {p2, p0, p1, p3, v1}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;-><init>(Lio/github/leexeo/cage/space/AccountTransport$Forwarder;IILandroid/os/Parcel;)V
    :try_end_1
    .catch Ljava/lang/RuntimeException; {:try_start_1 .. :try_end_1} :catch_3
    .catch Ljava/lang/Error; {:try_start_1 .. :try_end_1} :catch_2
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    .line 105
    :try_start_2
    iget-object p1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->worker:Ljava/util/concurrent/ThreadPoolExecutor;

    invoke-virtual {p1, p2}, Ljava/util/concurrent/ThreadPoolExecutor;->execute(Ljava/lang/Runnable;)V
    :try_end_2
    .catch Ljava/lang/RuntimeException; {:try_start_2 .. :try_end_2} :catch_1
    .catch Ljava/lang/Error; {:try_start_2 .. :try_end_2} :catch_0
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    .line 106
    nop

    .line 108
    nop

    .line 115
    :try_start_3
    monitor-exit v0
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_2

    .line 108
    const/4 p1, 0x1

    return p1

    .line 115
    :catchall_0
    move-exception p1

    move-object v2, p2

    goto :goto_2

    .line 112
    :catch_0
    move-exception p1

    move-object v2, p2

    goto :goto_0

    .line 109
    :catch_1
    move-exception p1

    move-object v2, p2

    goto :goto_1

    .line 115
    :catchall_1
    move-exception p1

    goto :goto_2

    .line 112
    :catch_2
    move-exception p1

    .line 113
    :goto_0
    :try_start_4
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->close()V

    throw p1

    .line 109
    :catch_3
    move-exception p1

    .line 110
    :goto_1
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->close()V

    .line 111
    invoke-static {}, Lio/github/leexeo/cage/space/AccountTransport;->access$000()Landroid/os/RemoteException;

    move-result-object p1

    throw p1
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_1

    .line 115
    :goto_2
    if-nez v2, :cond_0

    :try_start_5
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    goto :goto_3

    :cond_0
    invoke-virtual {v2}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->recycle()V

    .line 116
    :goto_3
    throw p1

    .line 94
    :cond_1
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->close()V

    invoke-static {}, Lio/github/leexeo/cage/space/AccountTransport;->access$000()Landroid/os/RemoteException;

    move-result-object p1

    throw p1

    .line 91
    :cond_2
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->close()V

    invoke-static {}, Lio/github/leexeo/cage/space/AccountTransport;->access$000()Landroid/os/RemoteException;

    move-result-object p1

    throw p1

    .line 117
    :catchall_2
    move-exception p1

    monitor-exit v0
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_2

    throw p1
.end method

.method static synthetic lambda$new$0(Ljava/lang/Runnable;)Ljava/lang/Thread;
    .locals 2

    .line 62
    new-instance v0, Ljava/lang/Thread;

    const-string v1, "Cage-account-transport"

    invoke-direct {v0, p0, v1}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 63
    const/4 p0, 0x1

    invoke-virtual {v0, p0}, Ljava/lang/Thread;->setDaemon(Z)V

    .line 64
    return-object v0
.end method


# virtual methods
.method public binderDied()V
    .locals 0

    .line 120
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->close()V

    return-void
.end method

.method close()V
    .locals 3

    .line 123
    iget-object v0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->closed:Ljava/util/concurrent/atomic/AtomicBoolean;

    const/4 v1, 0x0

    const/4 v2, 0x1

    invoke-virtual {v0, v1, v2}, Ljava/util/concurrent/atomic/AtomicBoolean;->compareAndSet(ZZ)Z

    move-result v0

    if-nez v0, :cond_0

    return-void

    .line 124
    :cond_0
    invoke-static {}, Lio/github/leexeo/cage/space/AccountTransport;->access$100()Ljava/util/concurrent/ConcurrentHashMap;

    move-result-object v0

    iget-object v1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->remote:Landroid/os/IBinder;

    invoke-virtual {v0, v1, p0}, Ljava/util/concurrent/ConcurrentHashMap;->remove(Ljava/lang/Object;Ljava/lang/Object;)Z

    .line 126
    iget-object v0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->worker:Ljava/util/concurrent/ThreadPoolExecutor;

    invoke-virtual {v0}, Ljava/util/concurrent/ThreadPoolExecutor;->shutdownNow()Ljava/util/List;

    move-result-object v0

    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v0

    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    move-result v1

    if-eqz v1, :cond_1

    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Ljava/lang/Runnable;

    check-cast v1, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;

    invoke-virtual {v1}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder$Call;->recycle()V

    goto :goto_0

    .line 127
    :cond_1
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->unlink()V

    .line 128
    return-void
.end method

.method public invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Throwable;
        }
    .end annotation

    .line 75
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getDeclaringClass()Ljava/lang/Class;

    move-result-object v0

    const-class v1, Ljava/lang/Object;

    const/4 v2, 0x1

    const/4 v3, 0x0

    if-ne v0, v1, :cond_3

    .line 76
    const-string v0, "equals"

    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_1

    aget-object p2, p3, v3

    if-ne p1, p2, :cond_0

    goto :goto_0

    :cond_0
    move v2, v3

    :goto_0
    invoke-static {v2}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object p1

    return-object p1

    .line 77
    :cond_1
    const-string v0, "hashCode"

    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_2

    invoke-static {p1}, Ljava/lang/System;->identityHashCode(Ljava/lang/Object;)I

    move-result p1

    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p1

    return-object p1

    .line 78
    :cond_2
    const-string p1, "toString"

    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_3

    const-string p1, "PrivateAccountTransport"

    return-object p1

    .line 80
    :cond_3
    const-string p1, "queryLocalInterface"

    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_4

    const/4 p1, 0x0

    return-object p1

    .line 81
    :cond_4
    const-string p1, "transact"

    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_5

    if-eqz p3, :cond_5

    array-length p1, p3

    const/4 v0, 0x4

    if-ne p1, v0, :cond_5

    const/4 p1, 0x3

    aget-object v0, p3, p1

    check-cast v0, Ljava/lang/Integer;

    .line 82
    invoke-virtual {v0}, Ljava/lang/Integer;->intValue()I

    move-result v0

    and-int/2addr v0, v2

    if-eqz v0, :cond_5

    .line 83
    aget-object p2, p3, v3

    check-cast p2, Ljava/lang/Integer;

    invoke-virtual {p2}, Ljava/lang/Integer;->intValue()I

    move-result p2

    aget-object v0, p3, v2

    check-cast v0, Landroid/os/Parcel;

    aget-object p1, p3, p1

    check-cast p1, Ljava/lang/Integer;

    invoke-virtual {p1}, Ljava/lang/Integer;->intValue()I

    move-result p1

    invoke-direct {p0, p2, v0, p1}, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->enqueue(ILandroid/os/Parcel;I)Z

    move-result p1

    invoke-static {p1}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object p1

    return-object p1

    .line 84
    :cond_5
    :try_start_0
    iget-object p1, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->remote:Landroid/os/IBinder;

    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1
    :try_end_0
    .catch Ljava/lang/reflect/InvocationTargetException; {:try_start_0 .. :try_end_0} :catch_0

    return-object p1

    .line 85
    :catch_0
    move-exception p1

    invoke-virtual {p1}, Ljava/lang/reflect/InvocationTargetException;->getCause()Ljava/lang/Throwable;

    move-result-object p1

    throw p1
.end method

.method unlink()V
    .locals 3

    .line 131
    iget-object v0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->linked:Ljava/util/concurrent/atomic/AtomicBoolean;

    const/4 v1, 0x1

    const/4 v2, 0x0

    invoke-virtual {v0, v1, v2}, Ljava/util/concurrent/atomic/AtomicBoolean;->compareAndSet(ZZ)Z

    move-result v0

    if-nez v0, :cond_0

    return-void

    .line 132
    :cond_0
    :try_start_0
    iget-object v0, p0, Lio/github/leexeo/cage/space/AccountTransport$Forwarder;->remote:Landroid/os/IBinder;

    invoke-interface {v0, p0, v2}, Landroid/os/IBinder;->unlinkToDeath(Landroid/os/IBinder$DeathRecipient;I)Z
    :try_end_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    .line 133
    :catch_0
    move-exception v0

    :goto_0
    nop

    .line 134
    return-void
.end method
