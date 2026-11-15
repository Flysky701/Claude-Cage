.class public final Lio/github/leexeo/cage/localcore/CoreService;
.super Landroid/net/VpnService;
.source "CoreService.java"


# static fields
.field private static final NATIVE_LIFETIME:Ljava/lang/Object;

.field static volatile current:Lio/github/leexeo/cage/localcore/CoreService;

.field static volatile running:Z

.field static volatile startFailed:Z


# instance fields
.field private final dnsCancel:Landroid/os/CancellationSignal;

.field private volatile nativeReady:Z

.field private volatile optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

.field private started:Z

.field private final stopSignal:Ljava/util/concurrent/CountDownLatch;

.field private final stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

.field private volatile tunnel:Landroid/os/ParcelFileDescriptor;

.field private final upstreamAddresses:Ljava/util/concurrent/CompletableFuture;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/concurrent/CompletableFuture<",
            "Ljava/util/List<",
            "Ljava/net/InetAddress;",
            ">;>;"
        }
    .end annotation
.end field


# direct methods
.method public static synthetic $r8$lambda$v2rANnFj4WdWNSoOw44g6tTYa7A(Lio/github/leexeo/cage/localcore/CoreService;)V
    .locals 0

    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->runTunnel()V

    return-void
.end method

.method static constructor <clinit>()V
    .locals 1

    .line 18
    new-instance v0, Ljava/lang/Object;

    invoke-direct {v0}, Ljava/lang/Object;-><init>()V

    sput-object v0, Lio/github/leexeo/cage/localcore/CoreService;->NATIVE_LIFETIME:Ljava/lang/Object;

    return-void
.end method

.method public constructor <init>()V
    .locals 2

    .line 17
    invoke-direct {p0}, Landroid/net/VpnService;-><init>()V

    .line 21
    new-instance v0, Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-direct {v0}, Ljava/util/concurrent/atomic/AtomicBoolean;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

    .line 22
    new-instance v0, Ljava/util/concurrent/CountDownLatch;

    const/4 v1, 0x1

    invoke-direct {v0, v1}, Ljava/util/concurrent/CountDownLatch;-><init>(I)V

    iput-object v0, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopSignal:Ljava/util/concurrent/CountDownLatch;

    .line 23
    new-instance v0, Landroid/os/CancellationSignal;

    invoke-direct {v0}, Landroid/os/CancellationSignal;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/localcore/CoreService;->dnsCancel:Landroid/os/CancellationSignal;

    .line 24
    new-instance v0, Ljava/util/concurrent/CompletableFuture;

    invoke-direct {v0}, Ljava/util/concurrent/CompletableFuture;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/localcore/CoreService;->upstreamAddresses:Ljava/util/concurrent/CompletableFuture;

    return-void
.end method

.method static synthetic access$000(Lio/github/leexeo/cage/localcore/CoreService;)Ljava/util/concurrent/CompletableFuture;
    .locals 0

    .line 17
    iget-object p0, p0, Lio/github/leexeo/cage/localcore/CoreService;->upstreamAddresses:Ljava/util/concurrent/CompletableFuture;

    return-object p0
.end method

.method private requestStop()V
    .locals 3

    .line 163
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

    const/4 v1, 0x1

    const/4 v2, 0x0

    invoke-virtual {v0, v2, v1}, Ljava/util/concurrent/atomic/AtomicBoolean;->compareAndSet(ZZ)Z

    move-result v0

    if-nez v0, :cond_0

    return-void

    .line 164
    :cond_0
    iput-boolean v2, p0, Lio/github/leexeo/cage/localcore/CoreService;->nativeReady:Z

    .line 165
    sget-object v0, Lio/github/leexeo/cage/localcore/CoreService;->current:Lio/github/leexeo/cage/localcore/CoreService;

    if-ne v0, p0, :cond_1

    sput-boolean v2, Lio/github/leexeo/cage/localcore/CoreService;->running:Z

    const/4 v0, 0x0

    sput-object v0, Lio/github/leexeo/cage/localcore/CoreService;->current:Lio/github/leexeo/cage/localcore/CoreService;

    .line 166
    :cond_1
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreService;->dnsCancel:Landroid/os/CancellationSignal;

    invoke-virtual {v0}, Landroid/os/CancellationSignal;->cancel()V

    .line 167
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreService;->upstreamAddresses:Ljava/util/concurrent/CompletableFuture;

    new-instance v1, Ljava/io/IOException;

    const-string v2, "stopped"

    invoke-direct {v1, v2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    invoke-virtual {v0, v1}, Ljava/util/concurrent/CompletableFuture;->completeExceptionally(Ljava/lang/Throwable;)Z

    .line 168
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    .line 169
    if-eqz v0, :cond_2

    invoke-virtual {v0}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->cancel()V

    .line 170
    :cond_2
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopSignal:Ljava/util/concurrent/CountDownLatch;

    invoke-virtual {v0}, Ljava/util/concurrent/CountDownLatch;->countDown()V

    .line 171
    return-void
.end method

.method private resolveUpstream(Ljava/lang/String;)Ljava/lang/String;
    .locals 13
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 133
    const/16 v0, 0x3a

    invoke-virtual {p1, v0}, Ljava/lang/String;->indexOf(I)I

    move-result v0

    if-gez v0, :cond_6

    const-string v0, "[0-9]+(?:\\.[0-9]+){3}"

    invoke-virtual {p1, v0}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_0

    move-object v8, p1

    goto/16 :goto_2

    .line 135
    :cond_0
    const-class v0, Landroid/net/ConnectivityManager;

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/localcore/CoreService;->getSystemService(Ljava/lang/Class;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/net/ConnectivityManager;

    .line 136
    nop

    .line 137
    invoke-virtual {v0}, Landroid/net/ConnectivityManager;->getAllNetworks()[Landroid/net/Network;

    move-result-object v1

    array-length v2, v1

    const/4 v3, 0x0

    const/4 v4, 0x0

    move v5, v3

    :goto_0
    if-ge v5, v2, :cond_3

    aget-object v6, v1, v5

    .line 138
    invoke-virtual {v0, v6}, Landroid/net/ConnectivityManager;->getNetworkCapabilities(Landroid/net/Network;)Landroid/net/NetworkCapabilities;

    move-result-object v7

    .line 139
    if-eqz v7, :cond_2

    const/16 v8, 0xc

    invoke-virtual {v7, v8}, Landroid/net/NetworkCapabilities;->hasCapability(I)Z

    move-result v8

    if-eqz v8, :cond_2

    .line 140
    const/4 v8, 0x4

    invoke-virtual {v7, v8}, Landroid/net/NetworkCapabilities;->hasTransport(I)Z

    move-result v8

    if-nez v8, :cond_2

    .line 141
    nop

    .line 142
    const/16 v4, 0x10

    invoke-virtual {v7, v4}, Landroid/net/NetworkCapabilities;->hasCapability(I)Z

    move-result v4

    if-eqz v4, :cond_1

    move-object v7, v6

    goto :goto_1

    :cond_1
    move-object v4, v6

    .line 137
    :cond_2
    add-int/lit8 v5, v5, 0x1

    goto :goto_0

    :cond_3
    move-object v7, v4

    .line 145
    :goto_1
    if-eqz v7, :cond_5

    .line 146
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {v0}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result v0

    if-nez v0, :cond_4

    .line 148
    invoke-static {}, Landroid/net/DnsResolver;->getInstance()Landroid/net/DnsResolver;

    move-result-object v6

    new-instance v10, Lio/github/leexeo/cage/localcore/CoreService$$ExternalSyntheticLambda0;

    invoke-direct {v10}, Lio/github/leexeo/cage/localcore/CoreService$$ExternalSyntheticLambda0;-><init>()V

    iget-object v11, p0, Lio/github/leexeo/cage/localcore/CoreService;->dnsCancel:Landroid/os/CancellationSignal;

    new-instance v12, Lio/github/leexeo/cage/localcore/CoreService$1;

    invoke-direct {v12, p0}, Lio/github/leexeo/cage/localcore/CoreService$1;-><init>(Lio/github/leexeo/cage/localcore/CoreService;)V

    const/4 v9, 0x0

    move-object v8, p1

    invoke-virtual/range {v6 .. v12}, Landroid/net/DnsResolver;->query(Landroid/net/Network;Ljava/lang/String;ILjava/util/concurrent/Executor;Landroid/os/CancellationSignal;Landroid/net/DnsResolver$Callback;)V

    .line 159
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreService;->upstreamAddresses:Ljava/util/concurrent/CompletableFuture;

    const-wide/16 v0, 0xa

    sget-object v2, Ljava/util/concurrent/TimeUnit;->SECONDS:Ljava/util/concurrent/TimeUnit;

    invoke-virtual {p1, v0, v1, v2}, Ljava/util/concurrent/CompletableFuture;->get(JLjava/util/concurrent/TimeUnit;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Ljava/util/List;

    invoke-interface {p1, v3}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Ljava/net/InetAddress;

    invoke-virtual {p1}, Ljava/net/InetAddress;->getHostAddress()Ljava/lang/String;

    move-result-object p1

    return-object p1

    .line 146
    :cond_4
    new-instance p1, Ljava/io/IOException;

    const-string v0, "stopped"

    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 145
    :cond_5
    new-instance p1, Ljava/io/IOException;

    const-string v0, "no underlying network"

    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 133
    :cond_6
    move-object v8, p1

    .line 134
    :goto_2
    invoke-static {v8}, Ljava/net/InetAddress;->getByName(Ljava/lang/String;)Ljava/net/InetAddress;

    move-result-object p1

    invoke-virtual {p1}, Ljava/net/InetAddress;->getHostAddress()Ljava/lang/String;

    move-result-object p1

    return-object p1
.end method

.method private runTunnel()V
    .locals 9

    .line 69
    sget-object v0, Lio/github/leexeo/cage/localcore/CoreService;->NATIVE_LIFETIME:Ljava/lang/Object;

    monitor-enter v0

    .line 70
    nop

    .line 72
    const/4 v1, 0x1

    const/4 v2, 0x0

    const/4 v3, 0x0

    :try_start_0
    iget-object v4, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {v4}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result v4
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_8
    .catch Ljava/lang/LinkageError; {:try_start_0 .. :try_end_0} :catch_8
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    if-eqz v4, :cond_2

    .line 120
    :try_start_1
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V

    .line 122
    nop

    .line 123
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;

    iput-object v2, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    .line 124
    if-eqz v1, :cond_0

    :try_start_2
    invoke-virtual {v1}, Landroid/os/ParcelFileDescriptor;->close()V
    :try_end_2
    .catch Ljava/io/IOException; {:try_start_2 .. :try_end_2} :catch_0
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    goto :goto_0

    :catch_0
    move-exception v1

    .line 125
    :cond_0
    :goto_0
    :try_start_3
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    .line 126
    if-eqz v1, :cond_1

    invoke-virtual {v1}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->close()V

    .line 127
    :cond_1
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->stopSelf()V

    .line 128
    monitor-exit v0
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    .line 72
    return-void

    .line 75
    :cond_2
    :try_start_4
    invoke-static {p0}, Lio/github/leexeo/cage/localcore/Settings;->vlessFile(Landroid/content/Context;)Ljava/io/File;

    move-result-object v4

    invoke-virtual {v4}, Ljava/io/File;->isFile()Z

    move-result v4

    if-eqz v4, :cond_4

    .line 76
    new-instance v4, Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    invoke-direct {v4}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;-><init>()V

    .line 77
    iput-object v4, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    .line 78
    iget-object v5, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {v5}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result v5

    if-eqz v5, :cond_3

    invoke-virtual {v4}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->cancel()V

    .line 81
    :cond_3
    new-instance v5, Ljava/io/File;

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;

    move-result-object v6

    iget-object v6, v6, Landroid/content/pm/ApplicationInfo;->nativeLibraryDir:Ljava/lang/String;

    const-string v7, "libmihomo.so"

    invoke-direct {v5, v6, v7}, Ljava/io/File;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    .line 82
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->getFilesDir()Ljava/io/File;

    move-result-object v6

    invoke-static {p0}, Lio/github/leexeo/cage/localcore/Settings;->loadVless(Landroid/content/Context;)Ljava/lang/String;

    move-result-object v7

    .line 81
    invoke-virtual {v4, v5, v6, v7}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->start(Ljava/io/File;Ljava/io/File;Ljava/lang/String;)Lio/github/leexeo/cage/localcore/Upstream;

    move-result-object v4

    .line 83
    iget-object v5, v4, Lio/github/leexeo/cage/localcore/Upstream;->host:Ljava/lang/String;

    .line 84
    goto :goto_1

    .line 85
    :cond_4
    invoke-static {p0}, Lio/github/leexeo/cage/localcore/Settings;->load(Landroid/content/Context;)Lio/github/leexeo/cage/localcore/Upstream;

    move-result-object v4

    .line 86
    iget-object v5, v4, Lio/github/leexeo/cage/localcore/Upstream;->host:Ljava/lang/String;

    invoke-direct {p0, v5}, Lio/github/leexeo/cage/localcore/CoreService;->resolveUpstream(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    .line 88
    :goto_1
    iget-object v6, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {v6}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result v6
    :try_end_4
    .catch Ljava/lang/Exception; {:try_start_4 .. :try_end_4} :catch_8
    .catch Ljava/lang/LinkageError; {:try_start_4 .. :try_end_4} :catch_8
    .catchall {:try_start_4 .. :try_end_4} :catchall_0

    if-eqz v6, :cond_7

    .line 120
    :try_start_5
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V

    .line 122
    nop

    .line 123
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;

    iput-object v2, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_1

    .line 124
    if-eqz v1, :cond_5

    :try_start_6
    invoke-virtual {v1}, Landroid/os/ParcelFileDescriptor;->close()V
    :try_end_6
    .catch Ljava/io/IOException; {:try_start_6 .. :try_end_6} :catch_1
    .catchall {:try_start_6 .. :try_end_6} :catchall_1

    goto :goto_2

    :catch_1
    move-exception v1

    .line 125
    :cond_5
    :goto_2
    :try_start_7
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    .line 126
    if-eqz v1, :cond_6

    invoke-virtual {v1}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->close()V

    .line 127
    :cond_6
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->stopSelf()V

    .line 128
    monitor-exit v0
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_1

    .line 88
    return-void

    .line 89
    :cond_7
    :try_start_8
    new-instance v6, Ljava/io/File;

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->getFilesDir()Ljava/io/File;

    move-result-object v7

    const-string v8, "tunnel-runtime.yaml"

    invoke-direct {v6, v7, v8}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    .line 90
    new-instance v7, Landroid/util/AtomicFile;

    invoke-direct {v7, v6}, Landroid/util/AtomicFile;-><init>(Ljava/io/File;)V

    .line 91
    invoke-virtual {v7}, Landroid/util/AtomicFile;->startWrite()Ljava/io/FileOutputStream;

    move-result-object v8
    :try_end_8
    .catch Ljava/lang/Exception; {:try_start_8 .. :try_end_8} :catch_8
    .catch Ljava/lang/LinkageError; {:try_start_8 .. :try_end_8} :catch_8
    .catchall {:try_start_8 .. :try_end_8} :catchall_0

    .line 93
    :try_start_9
    invoke-static {v4, v5}, Lio/github/leexeo/cage/localcore/TunnelConfig;->render(Lio/github/leexeo/cage/localcore/Upstream;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v4

    sget-object v5, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-virtual {v4, v5}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object v4

    invoke-virtual {v8, v4}, Ljava/io/FileOutputStream;->write([B)V

    .line 94
    invoke-virtual {v7, v8}, Landroid/util/AtomicFile;->finishWrite(Ljava/io/FileOutputStream;)V
    :try_end_9
    .catch Ljava/lang/Exception; {:try_start_9 .. :try_end_9} :catch_7
    .catch Ljava/lang/LinkageError; {:try_start_9 .. :try_end_9} :catch_8
    .catchall {:try_start_9 .. :try_end_9} :catchall_0

    .line 95
    nop

    .line 96
    :try_start_a
    new-instance v4, Landroid/net/VpnService$Builder;

    invoke-direct {v4, p0}, Landroid/net/VpnService$Builder;-><init>(Landroid/net/VpnService;)V

    const-string v5, "Cage \u5168\u624b\u673a SOCKS5 \u7f51\u5173"

    invoke-virtual {v4, v5}, Landroid/net/VpnService$Builder;->setSession(Ljava/lang/String;)Landroid/net/VpnService$Builder;

    move-result-object v4

    .line 97
    const/16 v5, 0x5dc

    invoke-virtual {v4, v5}, Landroid/net/VpnService$Builder;->setMtu(I)Landroid/net/VpnService$Builder;

    move-result-object v4

    invoke-virtual {v4, v3}, Landroid/net/VpnService$Builder;->setBlocking(Z)Landroid/net/VpnService$Builder;

    move-result-object v4

    const-string v5, "198.18.0.1"

    .line 98
    const/16 v7, 0x20

    invoke-virtual {v4, v5, v7}, Landroid/net/VpnService$Builder;->addAddress(Ljava/lang/String;I)Landroid/net/VpnService$Builder;

    move-result-object v4

    const-string v5, "fc00::1"

    const/16 v7, 0x80

    invoke-virtual {v4, v5, v7}, Landroid/net/VpnService$Builder;->addAddress(Ljava/lang/String;I)Landroid/net/VpnService$Builder;

    move-result-object v4

    const-string v5, "0.0.0.0"

    .line 99
    invoke-virtual {v4, v5, v3}, Landroid/net/VpnService$Builder;->addRoute(Ljava/lang/String;I)Landroid/net/VpnService$Builder;

    move-result-object v4

    const-string v5, "::"

    invoke-virtual {v4, v5, v3}, Landroid/net/VpnService$Builder;->addRoute(Ljava/lang/String;I)Landroid/net/VpnService$Builder;

    move-result-object v4

    const-string v5, "198.18.0.2"

    invoke-virtual {v4, v5}, Landroid/net/VpnService$Builder;->addDnsServer(Ljava/lang/String;)Landroid/net/VpnService$Builder;

    move-result-object v4

    new-instance v5, Landroid/content/Intent;

    const-class v7, Lio/github/leexeo/cage/localcore/CoreActivity;

    invoke-direct {v5, p0, v7}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

    .line 100
    const/high16 v7, 0x4000000

    invoke-static {p0, v3, v5, v7}, Landroid/app/PendingIntent;->getActivity(Landroid/content/Context;ILandroid/content/Intent;I)Landroid/app/PendingIntent;

    move-result-object v5

    invoke-virtual {v4, v5}, Landroid/net/VpnService$Builder;->setConfigureIntent(Landroid/app/PendingIntent;)Landroid/net/VpnService$Builder;

    move-result-object v4

    .line 103
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->getPackageName()Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v4, v5}, Landroid/net/VpnService$Builder;->addDisallowedApplication(Ljava/lang/String;)Landroid/net/VpnService$Builder;

    .line 104
    iget-object v5, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {v5}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result v5
    :try_end_a
    .catch Ljava/lang/Exception; {:try_start_a .. :try_end_a} :catch_8
    .catch Ljava/lang/LinkageError; {:try_start_a .. :try_end_a} :catch_8
    .catchall {:try_start_a .. :try_end_a} :catchall_0

    if-eqz v5, :cond_a

    .line 120
    :try_start_b
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V

    .line 122
    nop

    .line 123
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;

    iput-object v2, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;
    :try_end_b
    .catchall {:try_start_b .. :try_end_b} :catchall_1

    .line 124
    if-eqz v1, :cond_8

    :try_start_c
    invoke-virtual {v1}, Landroid/os/ParcelFileDescriptor;->close()V
    :try_end_c
    .catch Ljava/io/IOException; {:try_start_c .. :try_end_c} :catch_2
    .catchall {:try_start_c .. :try_end_c} :catchall_1

    goto :goto_3

    :catch_2
    move-exception v1

    .line 125
    :cond_8
    :goto_3
    :try_start_d
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    .line 126
    if-eqz v1, :cond_9

    invoke-virtual {v1}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->close()V

    .line 127
    :cond_9
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->stopSelf()V

    .line 128
    monitor-exit v0
    :try_end_d
    .catchall {:try_start_d .. :try_end_d} :catchall_1

    .line 104
    return-void

    .line 105
    :cond_a
    :try_start_e
    invoke-virtual {v4}, Landroid/net/VpnService$Builder;->establish()Landroid/os/ParcelFileDescriptor;

    move-result-object v4

    iput-object v4, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;

    .line 106
    iget-object v4, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;

    if-eqz v4, :cond_17

    iget-object v4, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {v4}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result v4

    if-nez v4, :cond_17

    .line 107
    invoke-virtual {v6}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    move-result-object v4

    iget-object v5, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;

    invoke-virtual {v5}, Landroid/os/ParcelFileDescriptor;->getFd()I

    move-result v5

    invoke-static {v4, v5}, Lhev/htproxy/TProxyService;->TProxyStartService(Ljava/lang/String;I)Z

    move-result v3

    .line 108
    if-eqz v3, :cond_16

    .line 110
    iget-object v4, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopSignal:Ljava/util/concurrent/CountDownLatch;

    sget-object v5, Ljava/util/concurrent/TimeUnit;->MILLISECONDS:Ljava/util/concurrent/TimeUnit;

    const-wide/16 v6, 0x2ee

    invoke-virtual {v4, v6, v7, v5}, Ljava/util/concurrent/CountDownLatch;->await(JLjava/util/concurrent/TimeUnit;)Z

    move-result v4
    :try_end_e
    .catch Ljava/lang/Exception; {:try_start_e .. :try_end_e} :catch_8
    .catch Ljava/lang/LinkageError; {:try_start_e .. :try_end_e} :catch_8
    .catchall {:try_start_e .. :try_end_e} :catchall_0

    if-eqz v4, :cond_e

    .line 120
    :try_start_f
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V
    :try_end_f
    .catchall {:try_start_f .. :try_end_f} :catchall_1

    .line 122
    if-eqz v3, :cond_b

    :try_start_10
    invoke-static {}, Lhev/htproxy/TProxyService;->TProxyStopService()Z
    :try_end_10
    .catch Ljava/lang/LinkageError; {:try_start_10 .. :try_end_10} :catch_3
    .catchall {:try_start_10 .. :try_end_10} :catchall_1

    goto :goto_4

    :catch_3
    move-exception v1

    .line 123
    :cond_b
    :goto_4
    :try_start_11
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;

    iput-object v2, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;
    :try_end_11
    .catchall {:try_start_11 .. :try_end_11} :catchall_1

    .line 124
    if-eqz v1, :cond_c

    :try_start_12
    invoke-virtual {v1}, Landroid/os/ParcelFileDescriptor;->close()V
    :try_end_12
    .catch Ljava/io/IOException; {:try_start_12 .. :try_end_12} :catch_4
    .catchall {:try_start_12 .. :try_end_12} :catchall_1

    goto :goto_5

    :catch_4
    move-exception v1

    .line 125
    :cond_c
    :goto_5
    :try_start_13
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    .line 126
    if-eqz v1, :cond_d

    invoke-virtual {v1}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->close()V

    .line 127
    :cond_d
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->stopSelf()V

    .line 128
    monitor-exit v0
    :try_end_13
    .catchall {:try_start_13 .. :try_end_13} :catchall_1

    .line 110
    return-void

    .line 111
    :cond_e
    :try_start_14
    invoke-static {}, Lhev/htproxy/TProxyService;->TProxyIsRunning()Z

    move-result v4

    if-eqz v4, :cond_15

    .line 112
    iput-boolean v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->nativeReady:Z

    .line 113
    :cond_f
    :goto_6
    iget-object v4, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopSignal:Ljava/util/concurrent/CountDownLatch;

    sget-object v5, Ljava/util/concurrent/TimeUnit;->MILLISECONDS:Ljava/util/concurrent/TimeUnit;

    const-wide/16 v6, 0x12c

    invoke-virtual {v4, v6, v7, v5}, Ljava/util/concurrent/CountDownLatch;->await(JLjava/util/concurrent/TimeUnit;)Z

    move-result v4

    if-nez v4, :cond_12

    .line 114
    invoke-static {}, Lhev/htproxy/TProxyService;->TProxyIsRunning()Z

    move-result v4

    if-eqz v4, :cond_11

    .line 115
    iget-object v4, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    if-eqz v4, :cond_f

    iget-object v4, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    invoke-virtual {v4}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->isAlive()Z

    move-result v4

    if-eqz v4, :cond_10

    goto :goto_6

    :cond_10
    new-instance v4, Ljava/io/IOException;

    const-string v5, "optional core stopped"

    invoke-direct {v4, v5}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v4

    .line 114
    :cond_11
    new-instance v4, Ljava/io/IOException;

    const-string v5, "HEV stopped"

    invoke-direct {v4, v5}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v4
    :try_end_14
    .catch Ljava/lang/Exception; {:try_start_14 .. :try_end_14} :catch_8
    .catch Ljava/lang/LinkageError; {:try_start_14 .. :try_end_14} :catch_8
    .catchall {:try_start_14 .. :try_end_14} :catchall_0

    .line 120
    :cond_12
    :try_start_15
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V
    :try_end_15
    .catchall {:try_start_15 .. :try_end_15} :catchall_1

    .line 122
    if-eqz v3, :cond_13

    :try_start_16
    invoke-static {}, Lhev/htproxy/TProxyService;->TProxyStopService()Z
    :try_end_16
    .catch Ljava/lang/LinkageError; {:try_start_16 .. :try_end_16} :catch_5
    .catchall {:try_start_16 .. :try_end_16} :catchall_1

    goto :goto_7

    :catch_5
    move-exception v1

    .line 123
    :cond_13
    :goto_7
    :try_start_17
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;

    iput-object v2, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;
    :try_end_17
    .catchall {:try_start_17 .. :try_end_17} :catchall_1

    .line 124
    if-eqz v1, :cond_14

    :try_start_18
    invoke-virtual {v1}, Landroid/os/ParcelFileDescriptor;->close()V
    :try_end_18
    .catch Ljava/io/IOException; {:try_start_18 .. :try_end_18} :catch_6
    .catchall {:try_start_18 .. :try_end_18} :catchall_1

    goto :goto_8

    :catch_6
    move-exception v1

    .line 125
    :cond_14
    :goto_8
    :try_start_19
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    .line 126
    if-eqz v1, :cond_1b

    invoke-virtual {v1}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->close()V
    :try_end_19
    .catchall {:try_start_19 .. :try_end_19} :catchall_1

    goto :goto_b

    .line 111
    :cond_15
    :try_start_1a
    new-instance v4, Ljava/io/IOException;

    const-string v5, "HEV initialization failed"

    invoke-direct {v4, v5}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v4

    .line 108
    :cond_16
    new-instance v4, Ljava/io/IOException;

    const-string v5, "HEV refused start"

    invoke-direct {v4, v5}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v4

    .line 106
    :cond_17
    new-instance v4, Ljava/io/IOException;

    const-string v5, "TUN unavailable"

    invoke-direct {v4, v5}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v4

    .line 95
    :catch_7
    move-exception v4

    invoke-virtual {v7, v8}, Landroid/util/AtomicFile;->failWrite(Ljava/io/FileOutputStream;)V

    throw v4
    :try_end_1a
    .catch Ljava/lang/Exception; {:try_start_1a .. :try_end_1a} :catch_8
    .catch Ljava/lang/LinkageError; {:try_start_1a .. :try_end_1a} :catch_8
    .catchall {:try_start_1a .. :try_end_1a} :catchall_0

    .line 120
    :catchall_0
    move-exception v1

    goto :goto_c

    .line 117
    :catch_8
    move-exception v4

    .line 118
    :try_start_1b
    iget-object v4, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {v4}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result v4

    if-nez v4, :cond_18

    sput-boolean v1, Lio/github/leexeo/cage/localcore/CoreService;->startFailed:Z
    :try_end_1b
    .catchall {:try_start_1b .. :try_end_1b} :catchall_0

    .line 120
    :cond_18
    :try_start_1c
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V
    :try_end_1c
    .catchall {:try_start_1c .. :try_end_1c} :catchall_1

    .line 122
    if-eqz v3, :cond_19

    :try_start_1d
    invoke-static {}, Lhev/htproxy/TProxyService;->TProxyStopService()Z
    :try_end_1d
    .catch Ljava/lang/LinkageError; {:try_start_1d .. :try_end_1d} :catch_9
    .catchall {:try_start_1d .. :try_end_1d} :catchall_1

    goto :goto_9

    :catch_9
    move-exception v1

    .line 123
    :cond_19
    :goto_9
    :try_start_1e
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;

    iput-object v2, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;
    :try_end_1e
    .catchall {:try_start_1e .. :try_end_1e} :catchall_1

    .line 124
    if-eqz v1, :cond_1a

    :try_start_1f
    invoke-virtual {v1}, Landroid/os/ParcelFileDescriptor;->close()V
    :try_end_1f
    .catch Ljava/io/IOException; {:try_start_1f .. :try_end_1f} :catch_a
    .catchall {:try_start_1f .. :try_end_1f} :catchall_1

    goto :goto_a

    :catch_a
    move-exception v1

    .line 125
    :cond_1a
    :goto_a
    :try_start_20
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    .line 126
    if-eqz v1, :cond_1b

    invoke-virtual {v1}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->close()V

    .line 127
    :cond_1b
    :goto_b
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->stopSelf()V

    .line 128
    nop

    .line 129
    monitor-exit v0

    .line 130
    return-void

    .line 120
    :goto_c
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V
    :try_end_20
    .catchall {:try_start_20 .. :try_end_20} :catchall_1

    .line 122
    if-eqz v3, :cond_1c

    :try_start_21
    invoke-static {}, Lhev/htproxy/TProxyService;->TProxyStopService()Z
    :try_end_21
    .catch Ljava/lang/LinkageError; {:try_start_21 .. :try_end_21} :catch_b
    .catchall {:try_start_21 .. :try_end_21} :catchall_1

    goto :goto_d

    :catch_b
    move-exception v3

    .line 123
    :cond_1c
    :goto_d
    :try_start_22
    iget-object v3, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;

    iput-object v2, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;
    :try_end_22
    .catchall {:try_start_22 .. :try_end_22} :catchall_1

    .line 124
    if-eqz v3, :cond_1d

    :try_start_23
    invoke-virtual {v3}, Landroid/os/ParcelFileDescriptor;->close()V
    :try_end_23
    .catch Ljava/io/IOException; {:try_start_23 .. :try_end_23} :catch_c
    .catchall {:try_start_23 .. :try_end_23} :catchall_1

    goto :goto_e

    :catch_c
    move-exception v2

    .line 125
    :cond_1d
    :goto_e
    :try_start_24
    iget-object v2, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    .line 126
    if-eqz v2, :cond_1e

    invoke-virtual {v2}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->close()V

    .line 127
    :cond_1e
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->stopSelf()V

    .line 128
    throw v1

    .line 129
    :catchall_1
    move-exception v1

    monitor-exit v0
    :try_end_24
    .catchall {:try_start_24 .. :try_end_24} :catchall_1

    throw v1
.end method


# virtual methods
.method public onCreate()V
    .locals 1

    .line 31
    invoke-super {p0}, Landroid/net/VpnService;->onCreate()V

    .line 32
    sput-object p0, Lio/github/leexeo/cage/localcore/CoreService;->current:Lio/github/leexeo/cage/localcore/CoreService;

    const/4 v0, 0x1

    sput-boolean v0, Lio/github/leexeo/cage/localcore/CoreService;->running:Z

    const/4 v0, 0x0

    sput-boolean v0, Lio/github/leexeo/cage/localcore/CoreService;->startFailed:Z

    .line 33
    return-void
.end method

.method public onDestroy()V
    .locals 1

    .line 176
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V

    const/4 v0, 0x1

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/localcore/CoreService;->stopForeground(I)V

    invoke-super {p0}, Landroid/net/VpnService;->onDestroy()V

    .line 177
    return-void
.end method

.method public onRevoke()V
    .locals 0

    .line 173
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->stopSelf()V

    return-void
.end method

.method public onStartCommand(Landroid/content/Intent;II)I
    .locals 3

    .line 36
    const-string p2, "gateway"

    const/4 p3, 0x2

    if-eqz p1, :cond_0

    const-string v0, "STOP"

    invoke-virtual {p1}, Landroid/content/Intent;->getAction()Ljava/lang/String;

    move-result-object p1

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_0

    .line 37
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->stopSelf()V

    return p3

    .line 39
    :cond_0
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {p1}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result p1

    if-eqz p1, :cond_1

    return p3

    .line 41
    :cond_1
    const/4 p1, 0x1

    :try_start_0
    invoke-static {p0}, Landroid/net/VpnService;->prepare(Landroid/content/Context;)Landroid/content/Intent;

    move-result-object v0

    if-nez v0, :cond_3

    .line 42
    const-class v0, Landroid/app/NotificationManager;

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/localcore/CoreService;->getSystemService(Ljava/lang/Class;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/app/NotificationManager;

    .line 43
    new-instance v1, Landroid/app/NotificationChannel;

    const-string v2, "\u7a7a\u95f4\u7f51\u5173"

    invoke-direct {v1, p2, v2, p3}, Landroid/app/NotificationChannel;-><init>(Ljava/lang/String;Ljava/lang/CharSequence;I)V

    invoke-virtual {v0, v1}, Landroid/app/NotificationManager;->createNotificationChannel(Landroid/app/NotificationChannel;)V

    .line 44
    new-instance v0, Landroid/content/Intent;

    const-class v1, Lio/github/leexeo/cage/localcore/CoreActivity;

    invoke-direct {v0, p0, v1}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

    const/high16 v1, 0x4000000

    const/4 v2, 0x0

    invoke-static {p0, v2, v0, v1}, Landroid/app/PendingIntent;->getActivity(Landroid/content/Context;ILandroid/content/Intent;I)Landroid/app/PendingIntent;

    move-result-object v0

    .line 45
    new-instance v1, Landroid/app/Notification$Builder;

    invoke-direct {v1, p0, p2}, Landroid/app/Notification$Builder;-><init>(Landroid/content/Context;Ljava/lang/String;)V

    .line 46
    const p2, 0x108007c

    invoke-virtual {v1, p2}, Landroid/app/Notification$Builder;->setSmallIcon(I)Landroid/app/Notification$Builder;

    move-result-object p2

    const-string v1, "Cage \u5168\u624b\u673a\u7f51\u5173"

    invoke-virtual {p2, v1}, Landroid/app/Notification$Builder;->setContentTitle(Ljava/lang/CharSequence;)Landroid/app/Notification$Builder;

    move-result-object p2

    const-string v1, "\u5168\u624b\u673a\u6d41\u91cf\u7ecf SOCKS5\uff1b\u65ad\u7f51\u9501\u72b6\u6001\u8bf7\u67e5\u770b\u7f51\u5173"

    .line 47
    invoke-virtual {p2, v1}, Landroid/app/Notification$Builder;->setContentText(Ljava/lang/CharSequence;)Landroid/app/Notification$Builder;

    move-result-object p2

    .line 48
    invoke-virtual {p2, v0}, Landroid/app/Notification$Builder;->setContentIntent(Landroid/app/PendingIntent;)Landroid/app/Notification$Builder;

    move-result-object p2

    invoke-virtual {p2, p1}, Landroid/app/Notification$Builder;->setOngoing(Z)Landroid/app/Notification$Builder;

    move-result-object p2

    invoke-virtual {p2}, Landroid/app/Notification$Builder;->build()Landroid/app/Notification;

    move-result-object p2

    .line 45
    invoke-virtual {p0, p1, p2}, Lio/github/leexeo/cage/localcore/CoreService;->startForeground(ILandroid/app/Notification;)V
    :try_end_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    .line 51
    nop

    .line 52
    iget-boolean p2, p0, Lio/github/leexeo/cage/localcore/CoreService;->started:Z

    if-nez p2, :cond_2

    .line 53
    iput-boolean p1, p0, Lio/github/leexeo/cage/localcore/CoreService;->started:Z

    .line 54
    new-instance p2, Ljava/lang/Thread;

    new-instance p3, Lio/github/leexeo/cage/localcore/CoreService$$ExternalSyntheticLambda1;

    invoke-direct {p3, p0}, Lio/github/leexeo/cage/localcore/CoreService$$ExternalSyntheticLambda1;-><init>(Lio/github/leexeo/cage/localcore/CoreService;)V

    const-string v0, "Cage-HEV-lifetime"

    invoke-direct {p2, p3, v0}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    invoke-virtual {p2}, Ljava/lang/Thread;->start()V

    .line 56
    :cond_2
    return p1

    .line 41
    :cond_3
    :try_start_1
    new-instance p2, Ljava/lang/SecurityException;

    const-string v0, "VPN consent missing"

    invoke-direct {p2, v0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p2
    :try_end_1
    .catch Ljava/lang/RuntimeException; {:try_start_1 .. :try_end_1} :catch_0

    .line 49
    :catch_0
    move-exception p2

    .line 50
    sput-boolean p1, Lio/github/leexeo/cage/localcore/CoreService;->startFailed:Z

    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->stopSelf()V

    return p3
.end method

.method public onTimeout(II)V
    .locals 0

    .line 174
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreService;->requestStop()V

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->stopSelf()V

    return-void
.end method

.method safeReady()Z
    .locals 1

    .line 65
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->tunnelReady()Z

    move-result v0

    if-eqz v0, :cond_0

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->isAlwaysOn()Z

    move-result v0

    if-eqz v0, :cond_0

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreService;->isLockdownEnabled()Z

    move-result v0

    if-eqz v0, :cond_0

    const/4 v0, 0x1

    goto :goto_0

    :cond_0
    const/4 v0, 0x0

    :goto_0
    return v0
.end method

.method tunnelReady()Z
    .locals 2

    .line 60
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreService;->optionalCore:Lio/github/leexeo/cage/localcore/EmbeddedProxy;

    .line 61
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->stopped:Ljava/util/concurrent/atomic/AtomicBoolean;

    invoke-virtual {v1}, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z

    move-result v1

    if-nez v1, :cond_1

    iget-boolean v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->nativeReady:Z

    if-eqz v1, :cond_1

    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreService;->tunnel:Landroid/os/ParcelFileDescriptor;

    if-eqz v1, :cond_1

    if-eqz v0, :cond_0

    invoke-virtual {v0}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->isAlive()Z

    move-result v0

    if-eqz v0, :cond_1

    .line 62
    :cond_0
    invoke-static {}, Lhev/htproxy/TProxyService;->TProxyIsRunning()Z

    move-result v0

    if-eqz v0, :cond_1

    const/4 v0, 0x1

    goto :goto_0

    :cond_1
    const/4 v0, 0x0

    .line 61
    :goto_0
    return v0
.end method
