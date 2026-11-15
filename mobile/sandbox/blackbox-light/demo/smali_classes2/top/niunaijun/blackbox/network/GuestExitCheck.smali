.class public final Ltop/niunaijun/blackbox/network/GuestExitCheck;
.super Ljava/lang/Object;
.source "GuestExitCheck.java"

# interfaces
.implements Landroid/content/ServiceConnection;


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;
    }
.end annotation


# static fields
.field private static final HELPER:Ljava/lang/String; = "io.github.leexeo.cage.localcore"

.field static final JAVA_PROXY:Ljava/net/InetSocketAddress;

.field static final PIN:Ljava/lang/String; = "104.16.185.241"

.field static final SITE:Ljava/lang/String; = "ipv4.icanhazip.com"

.field static final TAG:Ljava/lang/String; = "CageLightNet"

.field private static attempted:Z


# instance fields
.field private final bound:Ljava/util/concurrent/CountDownLatch;

.field private final clients:Ljava/util/concurrent/Semaphore;

.field private final main:Landroid/os/Handler;

.field private volatile service:Landroid/os/Messenger;

.field private spaceApp:Z

.field private stableProbe:Z


# direct methods
.method static constructor <clinit>()V
    .locals 3

    .line 28
    new-instance v0, Ljava/net/InetSocketAddress;

    const-string v1, "127.0.0.1"

    const v2, 0x965b

    invoke-direct {v0, v1, v2}, Ljava/net/InetSocketAddress;-><init>(Ljava/lang/String;I)V

    sput-object v0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->JAVA_PROXY:Ljava/net/InetSocketAddress;

    return-void
.end method

.method public constructor <init>()V
    .locals 2

    .line 22
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 30
    new-instance v0, Ljava/util/concurrent/CountDownLatch;

    const/4 v1, 0x1

    invoke-direct {v0, v1}, Ljava/util/concurrent/CountDownLatch;-><init>(I)V

    iput-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->bound:Ljava/util/concurrent/CountDownLatch;

    .line 32
    new-instance v0, Landroid/os/Handler;

    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;

    move-result-object v1

    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    iput-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->main:Landroid/os/Handler;

    .line 33
    new-instance v0, Ljava/util/concurrent/Semaphore;

    const/4 v1, 0x4

    invoke-direct {v0, v1}, Ljava/util/concurrent/Semaphore;-><init>(I)V

    iput-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->clients:Ljava/util/concurrent/Semaphore;

    return-void
.end method

.method static synthetic access$000(Ltop/niunaijun/blackbox/network/GuestExitCheck;)Z
    .locals 0

    .line 22
    iget-boolean p0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->spaceApp:Z

    return p0
.end method

.method public static declared-synchronized bind(Landroid/content/Context;Landroid/content/Context;)V
    .locals 12

    const-class v0, Ltop/niunaijun/blackbox/network/GuestExitCheck;

    monitor-enter v0

    .line 39
    :try_start_0
    invoke-virtual {p1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object p1

    .line 40
    const-string v1, "com.anthropic.claude"

    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    const/4 v2, 0x0

    const/4 v3, 0x1

    if-nez v1, :cond_1

    const-string v1, "com.google.android.gsf"

    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_1

    const-string v1, "com.google.android.gms"

    .line 41
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_1

    const-string v1, "com.android.vending"

    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_0

    goto :goto_0

    :cond_0
    move v1, v2

    goto :goto_1

    :cond_1
    :goto_0
    move v1, v3

    .line 42
    :goto_1
    sget-boolean v4, Ltop/niunaijun/blackbox/network/GuestExitCheck;->attempted:Z

    if-nez v4, :cond_7

    if-nez v1, :cond_2

    const-string v4, "io.github.leexeo.cage.plainnet"

    invoke-virtual {p1, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-nez v4, :cond_2

    const-string v4, "io.github.leexeo.cage.stablenet"

    .line 43
    invoke-virtual {p1, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-nez v4, :cond_2

    goto :goto_6

    .line 44
    :cond_2
    sput-boolean v3, Ltop/niunaijun/blackbox/network/GuestExitCheck;->attempted:Z
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 47
    :try_start_1
    sget v3, Landroid/system/OsConstants;->AF_INET:I

    sget v4, Landroid/system/OsConstants;->AF_INET6:I

    filled-new-array {v3, v4}, [I

    move-result-object v3

    move v4, v2

    :goto_2
    const/4 v5, 0x2

    if-ge v4, v5, :cond_6

    aget v6, v3, v4

    .line 48
    sget v7, Landroid/system/OsConstants;->SOCK_STREAM:I

    sget v8, Landroid/system/OsConstants;->SOCK_DGRAM:I

    filled-new-array {v7, v8}, [I

    move-result-object v7

    move v8, v2

    :goto_3
    if-ge v8, v5, :cond_5

    aget v9, v7, v8
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 50
    :try_start_2
    invoke-static {v6, v9, v2}, Landroid/system/Os;->socket(III)Ljava/io/FileDescriptor;

    move-result-object v9

    .line 51
    invoke-static {v9}, Landroid/system/Os;->close(Ljava/io/FileDescriptor;)V

    .line 52
    const-string v9, "CageLightNet"

    const-string v10, "unexpected Internet socket permission; stopping test guest"

    invoke-static {v9, v10}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 53
    invoke-static {}, Landroid/os/Process;->myPid()I

    move-result v9

    invoke-static {v9}, Landroid/os/Process;->killProcess(I)V
    :try_end_2
    .catch Landroid/system/ErrnoException; {:try_start_2 .. :try_end_2} :catch_0
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_1
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    .line 54
    monitor-exit v0

    return-void

    .line 55
    :catch_0
    move-exception v9

    .line 56
    :try_start_3
    iget v10, v9, Landroid/system/ErrnoException;->errno:I

    sget v11, Landroid/system/OsConstants;->EACCES:I

    if-eq v10, v11, :cond_4

    iget v10, v9, Landroid/system/ErrnoException;->errno:I

    sget v11, Landroid/system/OsConstants;->EPERM:I

    if-eq v10, v11, :cond_4

    iget v10, v9, Landroid/system/ErrnoException;->errno:I

    sget v11, Landroid/system/OsConstants;->EAFNOSUPPORT:I

    if-ne v10, v11, :cond_3

    goto :goto_4

    .line 57
    :cond_3
    throw v9

    .line 48
    :cond_4
    :goto_4
    add-int/lit8 v8, v8, 0x1

    goto :goto_3

    .line 47
    :cond_5
    add-int/lit8 v4, v4, 0x1

    goto :goto_2

    .line 61
    :cond_6
    const-string v2, "CageLightNet"

    const-string v3, "kernel denied direct IPv4/IPv6 TCP/UDP sockets"

    invoke-static {v2, v3}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 62
    new-instance v2, Ltop/niunaijun/blackbox/network/GuestExitCheck;

    invoke-direct {v2}, Ltop/niunaijun/blackbox/network/GuestExitCheck;-><init>()V

    .line 63
    iput-boolean v1, v2, Ltop/niunaijun/blackbox/network/GuestExitCheck;->spaceApp:Z

    .line 64
    invoke-direct {v2, p0, p1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->install(Landroid/content/Context;Ljava/lang/String;)V
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_1
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 67
    goto :goto_5

    .line 65
    :catch_1
    move-exception p0

    .line 66
    :try_start_4
    const-string p1, "CageLightNet"

    const-string v1, "guest routing unavailable"

    invoke-static {p1, v1, p0}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_0

    .line 68
    :goto_5
    monitor-exit v0

    return-void

    .line 43
    :cond_7
    :goto_6
    monitor-exit v0

    return-void

    .line 38
    :catchall_0
    move-exception p0

    monitor-exit v0

    throw p0
.end method

.method private configureJavaProxy(Ljava/net/Proxy;)V
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/net/MalformedURLException;
        }
    .end annotation

    .line 132
    new-instance v0, Ljava/net/URL;

    const-string v1, "https://ipv4.icanhazip.com/"

    invoke-direct {v0, v1}, Ljava/net/URL;-><init>(Ljava/lang/String;)V

    .line 133
    new-instance v1, Ltop/niunaijun/blackbox/network/GuestExitCheck$1;

    invoke-direct {v1, p0, p1, v0}, Ltop/niunaijun/blackbox/network/GuestExitCheck$1;-><init>(Ltop/niunaijun/blackbox/network/GuestExitCheck;Ljava/net/Proxy;Ljava/net/URL;)V

    .line 146
    new-instance v0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda4;

    invoke-direct {v0, v1}, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda4;-><init>(Ljava/net/URLStreamHandler;)V

    invoke-static {v0}, Ljava/net/URL;->setURLStreamHandlerFactory(Ljava/net/URLStreamHandlerFactory;)V

    .line 147
    invoke-static {p1}, Ljava/util/Collections;->singletonList(Ljava/lang/Object;)Ljava/util/List;

    move-result-object p1

    .line 148
    new-instance v0, Ltop/niunaijun/blackbox/network/GuestExitCheck$2;

    invoke-direct {v0, p0, p1}, Ltop/niunaijun/blackbox/network/GuestExitCheck$2;-><init>(Ltop/niunaijun/blackbox/network/GuestExitCheck;Ljava/util/List;)V

    invoke-static {v0}, Ljava/net/ProxySelector;->setDefault(Ljava/net/ProxySelector;)V

    .line 152
    return-void
.end method

.method private static copy(Ljava/io/InputStream;Ljava/io/OutputStream;)V
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 245
    const/16 v0, 0x2000

    new-array v0, v0, [B

    .line 246
    :goto_0
    invoke-virtual {p0, v0}, Ljava/io/InputStream;->read([B)I

    move-result v1

    const/4 v2, -0x1

    if-eq v1, v2, :cond_0

    const/4 v2, 0x0

    invoke-virtual {p1, v0, v2, v1}, Ljava/io/OutputStream;->write([BII)V

    goto :goto_0

    .line 247
    :cond_0
    return-void
.end method

.method private forward(Landroid/net/LocalSocket;)V
    .locals 9
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 221
    const/16 v0, 0x3a98

    invoke-virtual {p1, v0}, Landroid/net/LocalSocket;->setSoTimeout(I)V

    .line 222
    new-instance v0, Ljava/io/DataInputStream;

    invoke-virtual {p1}, Landroid/net/LocalSocket;->getInputStream()Ljava/io/InputStream;

    move-result-object v1

    invoke-direct {v0, v1}, Ljava/io/DataInputStream;-><init>(Ljava/io/InputStream;)V

    .line 223
    invoke-virtual {p1}, Landroid/net/LocalSocket;->getOutputStream()Ljava/io/OutputStream;

    move-result-object v1

    .line 224
    invoke-virtual {v0}, Ljava/io/DataInputStream;->readUnsignedByte()I

    move-result v2

    .line 225
    const/4 v3, 0x5

    if-ne v2, v3, :cond_0

    const/4 v3, 0x1

    goto :goto_0

    :cond_0
    const/4 v3, 0x0

    .line 226
    :goto_0
    if-nez v3, :cond_2

    const/16 v4, 0x43

    if-ne v2, v4, :cond_1

    goto :goto_1

    :cond_1
    new-instance p1, Ljava/io/IOException;

    const-string v0, "unknown proxy protocol"

    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 227
    :cond_2
    :goto_1
    if-eqz v3, :cond_3

    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->socksDestination(Ljava/io/DataInputStream;Ljava/io/OutputStream;)Ljava/lang/String;

    move-result-object v2

    goto :goto_2

    :cond_3
    invoke-static {v0}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->httpDestination(Ljava/io/DataInputStream;)Ljava/lang/String;

    move-result-object v2

    .line 228
    :goto_2
    iget-boolean v4, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->spaceApp:Z

    if-eqz v4, :cond_4

    invoke-static {v2}, Lio/github/leexeo/cage/space/SpaceSites;->allows(Ljava/lang/String;)Z

    move-result v4

    if-eqz v4, :cond_5

    goto :goto_3

    :cond_4
    const-string v4, "ipv4.icanhazip.com"

    invoke-virtual {v4, v2}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result v4

    if-nez v4, :cond_6

    const-string v4, "104.16.185.241"

    invoke-virtual {v4, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_5

    goto :goto_3

    .line 229
    :cond_5
    new-instance p1, Ljava/io/IOException;

    const-string v0, "destination outside space route"

    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 230
    :cond_6
    :goto_3
    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    const-string v5, "requested "

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    const-string v5, "SOCKS "

    const-string v6, "CONNECT "

    if-eqz v3, :cond_7

    move-object v7, v5

    goto :goto_4

    :cond_7
    move-object v7, v6

    :goto_4
    invoke-virtual {v4, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    const-string v7, " peerPid="

    invoke-virtual {v4, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    .line 231
    invoke-virtual {p1}, Landroid/net/LocalSocket;->getPeerCredentials()Landroid/net/Credentials;

    move-result-object p1

    invoke-virtual {p1}, Landroid/net/Credentials;->getPid()I

    move-result p1

    invoke-virtual {v4, p1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    .line 230
    const-string v4, "CageLightNet"

    invoke-static {v4, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 232
    invoke-direct {p0, v2}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->open(Ljava/lang/String;)Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;

    move-result-object p1

    .line 233
    if-eqz v3, :cond_8

    const/16 v7, 0xa

    :try_start_0
    new-array v7, v7, [B

    fill-array-data v7, :array_0

    invoke-virtual {v1, v7}, Ljava/io/OutputStream;->write([B)V

    goto :goto_5

    .line 234
    :cond_8
    const-string v7, "HTTP/1.1 200 Connection Established\r\n\r\n"

    sget-object v8, Ljava/nio/charset/StandardCharsets;->US_ASCII:Ljava/nio/charset/Charset;

    invoke-virtual {v7, v8}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object v7

    invoke-virtual {v1, v7}, Ljava/io/OutputStream;->write([B)V

    .line 235
    :goto_5
    new-instance v7, Ljava/lang/StringBuilder;

    invoke-direct {v7}, Ljava/lang/StringBuilder;-><init>()V

    const-string v8, "proxy accepted "

    invoke-virtual {v7, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v7

    if-eqz v3, :cond_9

    goto :goto_6

    :cond_9
    move-object v5, v6

    :goto_6
    invoke-virtual {v7, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-static {v4, v2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 236
    new-instance v2, Ljava/lang/Thread;

    new-instance v3, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda5;

    invoke-direct {v3, v0, p1}, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda5;-><init>(Ljava/io/DataInputStream;Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;)V

    const-string v0, "Cage-client-to-core"

    invoke-direct {v2, v3, v0}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 239
    invoke-virtual {v2}, Ljava/lang/Thread;->start()V

    .line 240
    iget-object v0, p1, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->down:Ljava/io/InputStream;

    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->copy(Ljava/io/InputStream;Ljava/io/OutputStream;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 241
    if-eqz p1, :cond_a

    invoke-virtual {p1}, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->close()V

    .line 242
    :cond_a
    return-void

    .line 232
    :catchall_0
    move-exception v0

    if-eqz p1, :cond_b

    :try_start_1
    invoke-virtual {p1}, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->close()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    goto :goto_7

    :catchall_1
    move-exception p1

    invoke-virtual {v0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_b
    :goto_7
    throw v0

    nop

    :array_0
    .array-data 1
        0x5t
        0x0t
        0x0t
        0x1t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
    .end array-data
.end method

.method private static httpDestination(Ljava/io/DataInputStream;)Ljava/lang/String;
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 207
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "C"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const/16 v1, 0x200

    invoke-static {p0, v1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->readLine(Ljava/io/InputStream;I)Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    .line 208
    const-string v1, " "

    invoke-virtual {v0, v1}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object v0

    .line 209
    array-length v1, v0

    const/4 v2, 0x3

    if-ne v1, v2, :cond_1

    const/4 v1, 0x0

    aget-object v2, v0, v1

    const-string v3, "CONNECT"

    invoke-virtual {v2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_1

    const/4 v2, 0x1

    aget-object v3, v0, v2

    const-string v4, ":443"

    invoke-virtual {v3, v4}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_1

    .line 211
    const/16 v3, 0x2000

    .line 213
    :goto_0
    invoke-static {p0, v3}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->readLine(Ljava/io/InputStream;I)Ljava/lang/String;

    move-result-object v4

    .line 214
    invoke-virtual {v4}, Ljava/lang/String;->isEmpty()Z

    move-result v5

    if-eqz v5, :cond_0

    .line 217
    aget-object p0, v0, v2

    aget-object v0, v0, v2

    invoke-virtual {v0}, Ljava/lang/String;->length()I

    move-result v0

    add-int/lit8 v0, v0, -0x4

    invoke-virtual {p0, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    return-object p0

    .line 215
    :cond_0
    invoke-virtual {v4}, Ljava/lang/String;->length()I

    move-result v4

    add-int/lit8 v4, v4, 0x2

    sub-int/2addr v3, v4

    .line 216
    goto :goto_0

    .line 210
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string v0, "HTTPS CONNECT required"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private install(Landroid/content/Context;Ljava/lang/String;)V
    .locals 11
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 71
    const-string v0, "LD_PRELOAD"

    const-string v1, "io.github.leexeo.cage.stablenet"

    invoke-virtual {p2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    iput-boolean v1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->stableProbe:Z

    .line 72
    iget-boolean v1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->spaceApp:Z

    const/4 v2, 0x1

    if-eqz v1, :cond_0

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "space-"

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-static {}, Landroid/os/Process;->myPid()I

    move-result v3

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    goto :goto_0

    :cond_0
    const/16 v1, 0x2e

    invoke-virtual {p2, v1}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v1

    add-int/2addr v1, v2

    invoke-virtual {p2, v1}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v1

    .line 73
    :goto_0
    new-instance v9, Ljava/io/File;

    invoke-virtual {p1}, Landroid/content/Context;->getCacheDir()Ljava/io/File;

    move-result-object v3

    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v4, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v4, "-egress.sock"

    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-direct {v9, v3, v1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    .line 74
    invoke-virtual {v9}, Ljava/io/File;->exists()Z

    move-result v1

    if-eqz v1, :cond_2

    invoke-virtual {v9}, Ljava/io/File;->delete()Z

    move-result v1

    if-eqz v1, :cond_1

    goto :goto_1

    :cond_1
    new-instance p1, Ljava/io/IOException;

    const-string p2, "could not replace private listener"

    invoke-direct {p1, p2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 75
    :cond_2
    :goto_1
    new-instance v7, Landroid/net/LocalSocket;

    invoke-direct {v7}, Landroid/net/LocalSocket;-><init>()V

    .line 76
    new-instance v1, Landroid/net/LocalSocketAddress;

    invoke-virtual {v9}, Ljava/io/File;->toString()Ljava/lang/String;

    move-result-object v3

    sget-object v4, Landroid/net/LocalSocketAddress$Namespace;->FILESYSTEM:Landroid/net/LocalSocketAddress$Namespace;

    invoke-direct {v1, v3, v4}, Landroid/net/LocalSocketAddress;-><init>(Ljava/lang/String;Landroid/net/LocalSocketAddress$Namespace;)V

    invoke-virtual {v7, v1}, Landroid/net/LocalSocket;->bind(Landroid/net/LocalSocketAddress;)V

    .line 77
    new-instance v5, Landroid/net/LocalServerSocket;

    invoke-virtual {v7}, Landroid/net/LocalSocket;->getFileDescriptor()Ljava/io/FileDescriptor;

    move-result-object v1

    invoke-direct {v5, v1}, Landroid/net/LocalServerSocket;-><init>(Ljava/io/FileDescriptor;)V

    .line 78
    invoke-virtual {v9}, Ljava/io/File;->toString()Ljava/lang/String;

    move-result-object v1

    const/16 v3, 0x180

    invoke-static {v1, v3}, Landroid/system/Os;->chmod(Ljava/lang/String;I)V

    .line 79
    invoke-static {}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->kernelUid()I

    move-result v6

    .line 80
    const-string v1, "top.niunaijun.microdem"

    invoke-virtual {p1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v1, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_3

    .line 81
    const-string v1, "io.github.leexeo.cage.microcore"

    goto :goto_2

    :cond_3
    const-string v1, "io.github.leexeo.cage.localcore"

    .line 82
    :goto_2
    new-instance v3, Landroid/content/Intent;

    invoke-direct {v3}, Landroid/content/Intent;-><init>()V

    const-string v4, "io.github.leexeo.cage.localcore.ExitCheckService"

    invoke-virtual {v3, v1, v4}, Landroid/content/Intent;->setClassName(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;

    move-result-object v1

    .line 83
    invoke-virtual {p1, v1, p0, v2}, Landroid/content/Context;->bindService(Landroid/content/Intent;Landroid/content/ServiceConnection;I)Z

    move-result v1

    if-eqz v1, :cond_9

    .line 84
    new-instance v1, Ljava/lang/Thread;

    new-instance v10, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;

    move-object v3, v10

    move-object v4, p0

    move-object v8, v9

    invoke-direct/range {v3 .. v8}, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;-><init>(Ltop/niunaijun/blackbox/network/GuestExitCheck;Landroid/net/LocalServerSocket;ILandroid/net/LocalSocket;Ljava/io/File;)V

    const-string v3, "Cage-private-proxy"

    invoke-direct {v1, v10, v3}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 104
    invoke-virtual {v1}, Ljava/lang/Thread;->start()V

    .line 105
    new-instance v1, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda1;

    invoke-direct {v1, p0, v9}, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda1;-><init>(Ltop/niunaijun/blackbox/network/GuestExitCheck;Ljava/io/File;)V

    invoke-static {v1}, Ljava/net/Socket;->setSocketImplFactory(Ljava/net/SocketImplFactory;)V

    .line 106
    new-instance v1, Ljava/net/Proxy;

    sget-object v3, Ljava/net/Proxy$Type;->HTTP:Ljava/net/Proxy$Type;

    sget-object v4, Ltop/niunaijun/blackbox/network/GuestExitCheck;->JAVA_PROXY:Ljava/net/InetSocketAddress;

    invoke-direct {v1, v3, v4}, Ljava/net/Proxy;-><init>(Ljava/net/Proxy$Type;Ljava/net/SocketAddress;)V

    .line 107
    invoke-direct {p0, v1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->configureJavaProxy(Ljava/net/Proxy;)V

    .line 110
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "socks5h://localhost"

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v9}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    .line 111
    invoke-virtual {p1}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;

    move-result-object p1

    iget-object p1, p1, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    .line 112
    const-string v3, "lib/arm64-v8a/libcage_curl4.so"

    .line 113
    new-instance v4, Ljava/util/zip/ZipFile;

    invoke-direct {v4, p1}, Ljava/util/zip/ZipFile;-><init>(Ljava/lang/String;)V

    .line 114
    :try_start_0
    iget-boolean v5, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->spaceApp:Z
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    const-string v6, "CageLightNet"

    if-nez v5, :cond_6

    :try_start_1
    invoke-static {}, Landroid/os/Process;->is64Bit()Z

    move-result v5

    if-eqz v5, :cond_6

    invoke-virtual {v4, v3}, Ljava/util/zip/ZipFile;->getEntry(Ljava/lang/String;)Ljava/util/zip/ZipEntry;

    move-result-object v5

    if-eqz v5, :cond_6

    .line 115
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v1, "!/"

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    .line 116
    invoke-static {v0}, Landroid/system/Os;->getenv(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v1

    .line 117
    const-string v3, "CAGE_CURL4_LOCAL"

    invoke-virtual {v9}, Ljava/io/File;->toString()Ljava/lang/String;

    move-result-object v5

    invoke-static {v3, v5, v2}, Landroid/system/Os;->setenv(Ljava/lang/String;Ljava/lang/String;Z)V

    .line 118
    if-eqz v1, :cond_5

    invoke-virtual {v1}, Ljava/lang/String;->isEmpty()Z

    move-result v3

    if-eqz v3, :cond_4

    goto :goto_3

    :cond_4
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v3, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v3, ":"

    invoke-virtual {p1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    :cond_5
    :goto_3
    invoke-static {v0, p1, v2}, Landroid/system/Os;->setenv(Ljava/lang/String;Ljava/lang/String;Z)V

    .line 119
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "socks5h://127.0.0.1:"

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    sget-object v0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->JAVA_PROXY:Ljava/net/InetSocketAddress;

    invoke-virtual {v0}, Ljava/net/InetSocketAddress;->getPort()I

    move-result v0

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    .line 120
    const-string p1, "signed shell provides a local IPv4 proxy endpoint for the system curl"

    invoke-static {v6, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 122
    :cond_6
    invoke-virtual {v4}, Ljava/util/zip/ZipFile;->close()V

    .line 123
    const-string p1, "ALL_PROXY"

    const-string v0, "all_proxy"

    const-string v3, "http_proxy"

    const-string v4, "https_proxy"

    filled-new-array {v3, v4, p1, v0}, [Ljava/lang/String;

    move-result-object p1

    const/4 v0, 0x0

    move v3, v0

    :goto_4
    const/4 v4, 0x4

    if-ge v3, v4, :cond_7

    aget-object v4, p1, v3

    .line 124
    invoke-static {v4, v1, v2}, Landroid/system/Os;->setenv(Ljava/lang/String;Ljava/lang/String;Z)V

    .line 123
    add-int/lit8 v3, v3, 0x1

    goto :goto_4

    .line 125
    :cond_7
    const-string p1, "no_proxy"

    const-string v1, "NO_PROXY"

    filled-new-array {p1, v1}, [Ljava/lang/String;

    move-result-object p1

    :goto_5
    const/4 v1, 0x2

    if-ge v0, v1, :cond_8

    aget-object v1, p1, v0

    invoke-static {v1}, Landroid/system/Os;->unsetenv(Ljava/lang/String;)V

    add-int/lit8 v0, v0, 0x1

    goto :goto_5

    .line 126
    :cond_8
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "installed Java and child proxy defaults for "

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v6, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 127
    return-void

    .line 113
    :catchall_0
    move-exception p1

    :try_start_2
    invoke-virtual {v4}, Ljava/util/zip/ZipFile;->close()V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    goto :goto_6

    :catchall_1
    move-exception p2

    invoke-virtual {p1, p2}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_6
    throw p1

    .line 83
    :cond_9
    new-instance p1, Ljava/io/IOException;

    const-string p2, "helper not installed"

    invoke-direct {p1, p2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

.method private static kernelUid()I
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 164
    new-instance v0, Ljava/io/BufferedReader;

    new-instance v1, Ljava/io/FileReader;

    const-string v2, "/proc/self/status"

    invoke-direct {v1, v2}, Ljava/io/FileReader;-><init>(Ljava/lang/String;)V

    invoke-direct {v0, v1}, Ljava/io/BufferedReader;-><init>(Ljava/io/Reader;)V

    .line 165
    :cond_0
    :try_start_0
    invoke-virtual {v0}, Ljava/io/BufferedReader;->readLine()Ljava/lang/String;

    move-result-object v1

    if-eqz v1, :cond_1

    .line 166
    const-string v2, "Uid:"

    invoke-virtual {v1, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_0

    invoke-virtual {v1}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v1

    const-string v2, "\\s+"

    invoke-virtual {v1, v2}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object v1

    const/4 v2, 0x1

    aget-object v1, v1, v2

    invoke-static {v1}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result v1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 167
    invoke-virtual {v0}, Ljava/io/BufferedReader;->close()V

    .line 166
    return v1

    .line 167
    :cond_1
    invoke-virtual {v0}, Ljava/io/BufferedReader;->close()V

    .line 168
    new-instance v0, Ljava/io/IOException;

    const-string v1, "missing kernel UID"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 164
    :catchall_0
    move-exception v1

    :try_start_1
    invoke-virtual {v0}, Ljava/io/BufferedReader;->close()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    goto :goto_0

    :catchall_1
    move-exception v0

    invoke-virtual {v1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_0
    throw v1
.end method

.method static synthetic lambda$configureJavaProxy$3(Ljava/net/URLStreamHandler;Ljava/lang/String;)Ljava/net/URLStreamHandler;
    .locals 1

    .line 146
    const-string v0, "https"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_0

    goto :goto_0

    :cond_0
    const/4 p0, 0x0

    :goto_0
    return-object p0
.end method

.method static synthetic lambda$forward$4(Ljava/io/DataInputStream;Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;)V
    .locals 1

    .line 237
    :try_start_0
    iget-object v0, p1, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->up:Ljava/io/OutputStream;

    invoke-static {p0, v0}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->copy(Ljava/io/InputStream;Ljava/io/OutputStream;)V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_2
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 238
    :try_start_1
    iget-object p0, p1, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->up:Ljava/io/OutputStream;

    invoke-virtual {p0}, Ljava/io/OutputStream;->close()V
    :try_end_1
    .catch Ljava/io/IOException; {:try_start_1 .. :try_end_1} :catch_0

    goto :goto_1

    :catch_0
    move-exception p0

    goto :goto_1

    :catchall_0
    move-exception p0

    :try_start_2
    iget-object p1, p1, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->up:Ljava/io/OutputStream;

    invoke-virtual {p1}, Ljava/io/OutputStream;->close()V
    :try_end_2
    .catch Ljava/io/IOException; {:try_start_2 .. :try_end_2} :catch_1

    goto :goto_0

    :catch_1
    move-exception p1

    :goto_0
    throw p0

    .line 237
    :catch_2
    move-exception p0

    .line 238
    :try_start_3
    iget-object p0, p1, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->up:Ljava/io/OutputStream;

    invoke-virtual {p0}, Ljava/io/OutputStream;->close()V
    :try_end_3
    .catch Ljava/io/IOException; {:try_start_3 .. :try_end_3} :catch_0

    .line 239
    :goto_1
    return-void
.end method

.method static synthetic lambda$requestStream$5(ZLjava/lang/String;Ljava/util/concurrent/CompletableFuture;Landroid/os/Message;)Z
    .locals 4

    .line 282
    invoke-virtual {p3}, Landroid/os/Message;->getData()Landroid/os/Bundle;

    move-result-object v0

    const-string v1, "send"

    invoke-virtual {v0, v1}, Landroid/os/Bundle;->getParcelable(Ljava/lang/String;)Landroid/os/Parcelable;

    move-result-object v0

    check-cast v0, Landroid/os/ParcelFileDescriptor;

    .line 283
    invoke-virtual {p3}, Landroid/os/Message;->getData()Landroid/os/Bundle;

    move-result-object p3

    const-string v1, "receive"

    invoke-virtual {p3, v1}, Landroid/os/Bundle;->getParcelable(Ljava/lang/String;)Landroid/os/Parcelable;

    move-result-object p3

    check-cast p3, Landroid/os/ParcelFileDescriptor;

    .line 284
    const/4 v1, 0x0

    const/4 v2, 0x1

    if-nez p0, :cond_1

    new-instance p0, Ljava/lang/StringBuilder;

    invoke-direct {p0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "exact-address reply for "

    invoke-virtual {p0, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string p1, " stream="

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    if-eqz v0, :cond_0

    if-eqz p3, :cond_0

    move p1, v2

    goto :goto_0

    :cond_0
    move p1, v1

    :goto_0
    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    const-string p1, "CageLightNet"

    invoke-static {p1, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 286
    :cond_1
    if-eqz v0, :cond_3

    if-nez p3, :cond_2

    goto :goto_1

    .line 291
    :cond_2
    new-instance p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;

    invoke-direct {p0, v0, p3}, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;-><init>(Landroid/os/ParcelFileDescriptor;Landroid/os/ParcelFileDescriptor;)V

    .line 292
    invoke-virtual {p2, p0}, Ljava/util/concurrent/CompletableFuture;->complete(Ljava/lang/Object;)Z

    move-result p1

    if-nez p1, :cond_6

    :try_start_0
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->close()V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_4

    :catch_0
    move-exception p0

    goto :goto_4

    .line 287
    :cond_3
    :goto_1
    filled-new-array {v0, p3}, [Landroid/os/ParcelFileDescriptor;

    move-result-object p0

    :goto_2
    const/4 p1, 0x2

    if-ge v1, p1, :cond_5

    aget-object p1, p0, v1

    .line 288
    if-eqz p1, :cond_4

    :try_start_1
    invoke-virtual {p1}, Landroid/os/ParcelFileDescriptor;->close()V
    :try_end_1
    .catch Ljava/io/IOException; {:try_start_1 .. :try_end_1} :catch_1

    goto :goto_3

    :catch_1
    move-exception p1

    .line 287
    :cond_4
    :goto_3
    add-int/lit8 v1, v1, 0x1

    goto :goto_2

    .line 289
    :cond_5
    const/4 p0, 0x0

    invoke-virtual {p2, p0}, Ljava/util/concurrent/CompletableFuture;->complete(Ljava/lang/Object;)Z

    .line 294
    :cond_6
    :goto_4
    return v2
.end method

.method static synthetic lambda$requestStream$6(Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;Ljava/lang/Throwable;)V
    .locals 0

    .line 303
    if-eqz p0, :cond_0

    :try_start_0
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->close()V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    :catch_0
    move-exception p0

    .line 304
    :cond_0
    :goto_0
    return-void
.end method

.method private open(Ljava/lang/String;)Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 260
    invoke-direct {p0, p1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->requestStream(Ljava/lang/String;)Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;

    move-result-object v0

    .line 263
    if-nez v0, :cond_0

    .line 264
    const-wide/16 v0, 0x15e

    invoke-static {v0, v1}, Ljava/lang/Thread;->sleep(J)V

    .line 265
    invoke-direct {p0, p1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->requestStream(Ljava/lang/String;)Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;

    move-result-object v0

    .line 267
    :cond_0
    if-eqz v0, :cond_1

    .line 268
    return-object v0

    .line 267
    :cond_1
    new-instance p1, Ljava/io/IOException;

    const-string v0, "core unavailable"

    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

.method private static readLine(Ljava/io/InputStream;I)Ljava/lang/String;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 172
    new-instance v0, Ljava/io/ByteArrayOutputStream;

    invoke-direct {v0}, Ljava/io/ByteArrayOutputStream;-><init>()V

    .line 173
    const/4 v1, 0x0

    :goto_0
    if-ge v1, p1, :cond_2

    .line 174
    invoke-virtual {p0}, Ljava/io/InputStream;->read()I

    move-result v2

    .line 175
    if-ltz v2, :cond_1

    .line 176
    const/16 v3, 0xa

    if-ne v2, v3, :cond_0

    const-string p0, "US-ASCII"

    invoke-virtual {v0, p0}, Ljava/io/ByteArrayOutputStream;->toString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p0

    return-object p0

    .line 177
    :cond_0
    invoke-virtual {v0, v2}, Ljava/io/ByteArrayOutputStream;->write(I)V

    .line 173
    add-int/lit8 v1, v1, 0x1

    goto :goto_0

    .line 175
    :cond_1
    new-instance p0, Ljava/io/EOFException;

    invoke-direct {p0}, Ljava/io/EOFException;-><init>()V

    throw p0

    .line 179
    :cond_2
    new-instance p0, Ljava/io/IOException;

    const-string p1, "oversized proxy header"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private requestStream(Ljava/lang/String;)Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;
    .locals 8
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 272
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->bound:Ljava/util/concurrent/CountDownLatch;

    const-wide/16 v1, 0x3

    sget-object v3, Ljava/util/concurrent/TimeUnit;->SECONDS:Ljava/util/concurrent/TimeUnit;

    invoke-virtual {v0, v1, v2, v3}, Ljava/util/concurrent/CountDownLatch;->await(JLjava/util/concurrent/TimeUnit;)Z

    .line 273
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->service:Landroid/os/Messenger;

    .line 274
    if-eqz v0, :cond_4

    .line 275
    new-instance v1, Ljava/util/concurrent/CompletableFuture;

    invoke-direct {v1}, Ljava/util/concurrent/CompletableFuture;-><init>()V

    .line 278
    const-string v2, "ipv4.icanhazip.com"

    invoke-virtual {v2, p1}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result v2

    .line 279
    if-eqz v2, :cond_0

    const/4 v3, 0x2

    goto :goto_0

    :cond_0
    const/4 v3, 0x3

    :goto_0
    const/4 v4, 0x0

    invoke-static {v4, v3}, Landroid/os/Message;->obtain(Landroid/os/Handler;I)Landroid/os/Message;

    move-result-object v3

    .line 280
    if-nez v2, :cond_1

    invoke-virtual {v3}, Landroid/os/Message;->getData()Landroid/os/Bundle;

    move-result-object v4

    const-string v5, "destination"

    invoke-virtual {v4, v5, p1}, Landroid/os/Bundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    .line 281
    :cond_1
    new-instance v4, Landroid/os/Messenger;

    new-instance v5, Landroid/os/Handler;

    iget-object v6, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->main:Landroid/os/Handler;

    invoke-virtual {v6}, Landroid/os/Handler;->getLooper()Landroid/os/Looper;

    move-result-object v6

    new-instance v7, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda2;

    invoke-direct {v7, v2, p1, v1}, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda2;-><init>(ZLjava/lang/String;Ljava/util/concurrent/CompletableFuture;)V

    invoke-direct {v5, v6, v7}, Landroid/os/Handler;-><init>(Landroid/os/Looper;Landroid/os/Handler$Callback;)V

    invoke-direct {v4, v5}, Landroid/os/Messenger;-><init>(Landroid/os/Handler;)V

    iput-object v4, v3, Landroid/os/Message;->replyTo:Landroid/os/Messenger;

    .line 296
    invoke-virtual {v0, v3}, Landroid/os/Messenger;->send(Landroid/os/Message;)V

    .line 297
    const-string v0, "CageLightNet"

    if-nez v2, :cond_2

    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "submitted exact-address request to relay "

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    const-string v4, ":443"

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-static {v0, v3}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 298
    :cond_2
    :try_start_0
    sget-object v3, Ljava/util/concurrent/TimeUnit;->SECONDS:Ljava/util/concurrent/TimeUnit;

    const-wide/16 v4, 0xa

    invoke-virtual {v1, v4, v5, v3}, Ljava/util/concurrent/CompletableFuture;->get(JLjava/util/concurrent/TimeUnit;)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;
    :try_end_0
    .catch Ljava/lang/InterruptedException; {:try_start_0 .. :try_end_0} :catch_1
    .catch Ljava/util/concurrent/TimeoutException; {:try_start_0 .. :try_end_0} :catch_0

    return-object v3

    .line 299
    :catch_0
    move-exception v3

    goto :goto_1

    :catch_1
    move-exception v3

    .line 300
    :goto_1
    if-nez v2, :cond_3

    instance-of v2, v3, Ljava/util/concurrent/TimeoutException;

    if-eqz v2, :cond_3

    .line 301
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "no exact-address reply from relay for "

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 302
    :cond_3
    new-instance p1, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda3;

    invoke-direct {p1}, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda3;-><init>()V

    invoke-virtual {v1, p1}, Ljava/util/concurrent/CompletableFuture;->whenComplete(Ljava/util/function/BiConsumer;)Ljava/util/concurrent/CompletableFuture;

    .line 305
    throw v3

    .line 274
    :cond_4
    new-instance p1, Ljava/io/IOException;

    const-string v0, "proxy service disconnected"

    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

.method private static socksDestination(Ljava/io/DataInputStream;Ljava/io/OutputStream;)Ljava/lang/String;
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 183
    invoke-virtual {p0}, Ljava/io/DataInputStream;->readUnsignedByte()I

    move-result v0

    new-array v1, v0, [B

    .line 184
    invoke-virtual {p0, v1}, Ljava/io/DataInputStream;->readFully([B)V

    .line 185
    nop

    .line 186
    const/4 v2, 0x0

    move v3, v2

    move v4, v3

    :goto_0
    const/4 v5, 0x1

    if-ge v3, v0, :cond_1

    aget-byte v6, v1, v3

    if-nez v6, :cond_0

    move v4, v5

    :cond_0
    add-int/lit8 v3, v3, 0x1

    goto :goto_0

    .line 187
    :cond_1
    if-eqz v4, :cond_2

    move v0, v2

    goto :goto_1

    :cond_2
    const/16 v0, 0xff

    :goto_1
    int-to-byte v0, v0

    const/4 v1, 0x2

    new-array v1, v1, [B

    const/4 v3, 0x5

    aput-byte v3, v1, v2

    aput-byte v0, v1, v5

    invoke-virtual {p1, v1}, Ljava/io/OutputStream;->write([B)V

    .line 188
    if-eqz v4, :cond_6

    invoke-virtual {p0}, Ljava/io/DataInputStream;->readUnsignedByte()I

    move-result p1

    if-ne p1, v3, :cond_6

    invoke-virtual {p0}, Ljava/io/DataInputStream;->readUnsignedByte()I

    move-result p1

    if-ne p1, v5, :cond_6

    .line 189
    invoke-virtual {p0}, Ljava/io/DataInputStream;->readUnsignedByte()I

    move-result p1

    if-nez p1, :cond_6

    .line 190
    invoke-virtual {p0}, Ljava/io/DataInputStream;->readUnsignedByte()I

    move-result p1

    .line 192
    const/4 v0, 0x3

    if-ne p1, v0, :cond_3

    .line 193
    invoke-virtual {p0}, Ljava/io/DataInputStream;->readUnsignedByte()I

    move-result p1

    new-array p1, p1, [B

    .line 194
    invoke-virtual {p0, p1}, Ljava/io/DataInputStream;->readFully([B)V

    .line 195
    new-instance v0, Ljava/lang/String;

    sget-object v1, Ljava/nio/charset/StandardCharsets;->US_ASCII:Ljava/nio/charset/Charset;

    invoke-direct {v0, p1, v1}, Ljava/lang/String;-><init>([BLjava/nio/charset/Charset;)V

    .line 196
    goto :goto_2

    :cond_3
    if-ne p1, v5, :cond_5

    .line 197
    const/4 p1, 0x4

    new-array p1, p1, [B

    .line 198
    invoke-virtual {p0, p1}, Ljava/io/DataInputStream;->readFully([B)V

    .line 199
    invoke-static {p1}, Ljava/net/InetAddress;->getByAddress([B)Ljava/net/InetAddress;

    move-result-object p1

    invoke-virtual {p1}, Ljava/net/InetAddress;->getHostAddress()Ljava/lang/String;

    move-result-object v0

    .line 200
    nop

    .line 201
    :goto_2
    invoke-virtual {p0}, Ljava/io/DataInputStream;->readUnsignedShort()I

    move-result p0

    const/16 p1, 0x1bb

    if-ne p0, p1, :cond_4

    .line 202
    return-object v0

    .line 201
    :cond_4
    new-instance p0, Ljava/io/IOException;

    const-string p1, "unsupported port"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 200
    :cond_5
    new-instance p0, Ljava/io/IOException;

    const-string p1, "unsupported address family"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 189
    :cond_6
    new-instance p0, Ljava/io/IOException;

    const-string p1, "SOCKS CONNECT required"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method


# virtual methods
.method synthetic lambda$install$0$top-niunaijun-blackbox-network-GuestExitCheck(Landroid/net/LocalSocket;)V
    .locals 3

    .line 94
    :try_start_0
    invoke-direct {p0, p1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->forward(Landroid/net/LocalSocket;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    if-eqz p1, :cond_0

    :try_start_1
    invoke-virtual {p1}, Landroid/net/LocalSocket;->close()V
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    goto :goto_0

    .line 96
    :catchall_0
    move-exception p1

    goto :goto_4

    .line 95
    :catch_0
    move-exception p1

    goto :goto_2

    .line 96
    :cond_0
    :goto_0
    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->clients:Ljava/util/concurrent/Semaphore;

    invoke-virtual {p1}, Ljava/util/concurrent/Semaphore;->release()V

    goto :goto_3

    .line 94
    :catchall_1
    move-exception v0

    if-eqz p1, :cond_1

    :try_start_2
    invoke-virtual {p1}, Landroid/net/LocalSocket;->close()V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_2

    goto :goto_1

    :catchall_2
    move-exception p1

    :try_start_3
    invoke-virtual {v0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_1
    :goto_1
    throw v0
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_0
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 95
    :goto_2
    :try_start_4
    const-string v0, "CageLightNet"

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "connection closed "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_0

    goto :goto_0

    .line 97
    :goto_3
    return-void

    .line 96
    :goto_4
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->clients:Ljava/util/concurrent/Semaphore;

    invoke-virtual {v0}, Ljava/util/concurrent/Semaphore;->release()V

    throw p1
.end method

.method synthetic lambda$install$1$top-niunaijun-blackbox-network-GuestExitCheck(Landroid/net/LocalServerSocket;ILandroid/net/LocalSocket;Ljava/io/File;)V
    .locals 4

    .line 87
    const-string v0, "CageLightNet"

    :goto_0
    :try_start_0
    invoke-virtual {p1}, Landroid/net/LocalServerSocket;->accept()Landroid/net/LocalSocket;

    move-result-object v1

    .line 88
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "private connection from pid="

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v1}, Landroid/net/LocalSocket;->getPeerCredentials()Landroid/net/Credentials;

    move-result-object v3

    invoke-virtual {v3}, Landroid/net/Credentials;->getPid()I

    move-result v3

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-static {v0, v2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 89
    invoke-virtual {v1}, Landroid/net/LocalSocket;->getPeerCredentials()Landroid/net/Credentials;

    move-result-object v2

    invoke-virtual {v2}, Landroid/net/Credentials;->getUid()I

    move-result v2

    if-ne v2, p2, :cond_1

    iget-object v2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->clients:Ljava/util/concurrent/Semaphore;

    invoke-virtual {v2}, Ljava/util/concurrent/Semaphore;->tryAcquire()Z

    move-result v2

    if-nez v2, :cond_0

    goto :goto_1

    .line 93
    :cond_0
    new-instance v2, Ljava/lang/Thread;

    new-instance v3, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda6;

    invoke-direct {v3, p0, v1}, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda6;-><init>(Ltop/niunaijun/blackbox/network/GuestExitCheck;Landroid/net/LocalSocket;)V

    const-string v1, "Cage-local-client"

    invoke-direct {v2, v3, v1}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 97
    invoke-virtual {v2}, Ljava/lang/Thread;->start()V

    .line 98
    goto :goto_0

    .line 90
    :cond_1
    :goto_1
    invoke-virtual {v1}, Landroid/net/LocalSocket;->close()V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 91
    goto :goto_0

    .line 101
    :catchall_0
    move-exception p1

    goto :goto_3

    .line 99
    :catch_0
    move-exception p1

    :try_start_1
    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "listener closed "

    invoke-virtual {p2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 101
    :try_start_2
    invoke-virtual {p3}, Landroid/net/LocalSocket;->close()V
    :try_end_2
    .catch Ljava/io/IOException; {:try_start_2 .. :try_end_2} :catch_1

    goto :goto_2

    :catch_1
    move-exception p1

    .line 102
    :goto_2
    invoke-virtual {p4}, Ljava/io/File;->delete()Z

    .line 103
    nop

    .line 104
    return-void

    .line 101
    :goto_3
    :try_start_3
    invoke-virtual {p3}, Landroid/net/LocalSocket;->close()V
    :try_end_3
    .catch Ljava/io/IOException; {:try_start_3 .. :try_end_3} :catch_2

    goto :goto_4

    :catch_2
    move-exception p2

    .line 102
    :goto_4
    invoke-virtual {p4}, Ljava/io/File;->delete()Z

    .line 103
    throw p1
.end method

.method synthetic lambda$install$2$top-niunaijun-blackbox-network-GuestExitCheck(Ljava/io/File;)Ljava/net/SocketImpl;
    .locals 2

    .line 105
    new-instance v0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;

    invoke-virtual {p1}, Ljava/io/File;->toString()Ljava/lang/String;

    move-result-object p1

    iget-boolean v1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->spaceApp:Z

    invoke-direct {v0, p1, v1}, Ltop/niunaijun/blackbox/network/LocalGuestSocket;-><init>(Ljava/lang/String;Z)V

    return-object v0
.end method

.method public onServiceConnected(Landroid/content/ComponentName;Landroid/os/IBinder;)V
    .locals 0

    .line 155
    new-instance p1, Landroid/os/Messenger;

    invoke-direct {p1, p2}, Landroid/os/Messenger;-><init>(Landroid/os/IBinder;)V

    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->service:Landroid/os/Messenger;

    .line 156
    const-string p1, "CageLightNet"

    const-string p2, "bound to separate relay"

    invoke-static {p1, p2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 157
    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->bound:Ljava/util/concurrent/CountDownLatch;

    invoke-virtual {p1}, Ljava/util/concurrent/CountDownLatch;->countDown()V

    .line 158
    iget-boolean p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->stableProbe:Z

    if-eqz p1, :cond_0

    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->service:Landroid/os/Messenger;

    iget-object p2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->main:Landroid/os/Handler;

    invoke-virtual {p2}, Landroid/os/Handler;->getLooper()Landroid/os/Looper;

    move-result-object p2

    invoke-static {p1, p2}, Ltop/niunaijun/blackbox/network/DefaultCurlControl;->check(Landroid/os/Messenger;Landroid/os/Looper;)V

    .line 159
    :cond_0
    return-void
.end method

.method public onServiceDisconnected(Landroid/content/ComponentName;)V
    .locals 0

    .line 160
    const/4 p1, 0x0

    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->service:Landroid/os/Messenger;

    return-void
.end method
