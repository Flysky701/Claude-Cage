.class final Lio/github/leexeo/cage/localcore/EmbeddedProxy;
.super Ljava/lang/Object;
.source "EmbeddedProxy.java"

# interfaces
.implements Ljava/io/Closeable;


# instance fields
.field private volatile handshake:Ljava/net/Socket;

.field private volatile process:Ljava/lang/Process;

.field private volatile stopped:Z


# direct methods
.method constructor <init>()V
    .locals 0

    .line 11
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method cancel()V
    .locals 1

    .line 59
    const/4 v0, 0x1

    iput-boolean v0, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->stopped:Z

    .line 60
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->handshake:Ljava/net/Socket;

    .line 61
    if-eqz v0, :cond_0

    :try_start_0
    invoke-virtual {v0}, Ljava/net/Socket;->close()V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    :catch_0
    move-exception v0

    .line 62
    :cond_0
    :goto_0
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->process:Ljava/lang/Process;

    .line 63
    if-eqz v0, :cond_1

    invoke-virtual {v0}, Ljava/lang/Process;->destroy()V

    .line 64
    :cond_1
    return-void
.end method

.method public close()V
    .locals 4

    .line 67
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->cancel()V

    .line 68
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->process:Ljava/lang/Process;

    .line 69
    if-nez v0, :cond_0

    return-void

    .line 71
    :cond_0
    :try_start_0
    sget-object v1, Ljava/util/concurrent/TimeUnit;->SECONDS:Ljava/util/concurrent/TimeUnit;

    const-wide/16 v2, 0x1

    invoke-virtual {v0, v2, v3, v1}, Ljava/lang/Process;->waitFor(JLjava/util/concurrent/TimeUnit;)Z

    move-result v1

    if-nez v1, :cond_1

    .line 72
    invoke-virtual {v0}, Ljava/lang/Process;->destroyForcibly()Ljava/lang/Process;

    sget-object v1, Ljava/util/concurrent/TimeUnit;->SECONDS:Ljava/util/concurrent/TimeUnit;

    const-wide/16 v2, 0x2

    invoke-virtual {v0, v2, v3, v1}, Ljava/lang/Process;->waitFor(JLjava/util/concurrent/TimeUnit;)Z
    :try_end_0
    .catch Ljava/lang/InterruptedException; {:try_start_0 .. :try_end_0} :catch_0

    .line 74
    :cond_1
    goto :goto_0

    :catch_0
    move-exception v1

    invoke-virtual {v0}, Ljava/lang/Process;->destroyForcibly()Ljava/lang/Process;

    invoke-static {}, Ljava/lang/Thread;->currentThread()Ljava/lang/Thread;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/Thread;->interrupt()V

    .line 75
    :goto_0
    return-void
.end method

.method isAlive()Z
    .locals 2

    .line 55
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->process:Ljava/lang/Process;

    iget-boolean v1, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->stopped:Z

    if-nez v1, :cond_0

    if-eqz v0, :cond_0

    invoke-virtual {v0}, Ljava/lang/Process;->isAlive()Z

    move-result v0

    if-eqz v0, :cond_0

    const/4 v0, 0x1

    goto :goto_0

    :cond_0
    const/4 v0, 0x0

    :goto_0
    return v0
.end method

.method declared-synchronized start(Ljava/io/File;Ljava/io/File;Ljava/lang/String;)Lio/github/leexeo/cage/localcore/Upstream;
    .locals 8
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    monitor-enter p0

    .line 17
    :try_start_0
    iget-boolean v0, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->stopped:Z

    if-nez v0, :cond_6

    invoke-virtual {p1}, Ljava/io/File;->isFile()Z

    move-result v0

    if-eqz v0, :cond_6

    invoke-virtual {p1}, Ljava/io/File;->canExecute()Z

    move-result v0

    if-eqz v0, :cond_6

    .line 18
    invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;

    move-result-object v0

    invoke-virtual {v0}, Ljava/util/UUID;->toString()Ljava/lang/String;

    move-result-object v0

    .line 21
    new-instance v1, Ljava/net/ServerSocket;

    const-string v2, "127.0.0.1"

    invoke-static {v2}, Ljava/net/InetAddress;->getByName(Ljava/lang/String;)Ljava/net/InetAddress;

    move-result-object v2

    const/4 v3, 0x0

    const/4 v4, 0x1

    invoke-direct {v1, v3, v4, v2}, Ljava/net/ServerSocket;-><init>(IILjava/net/InetAddress;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_5

    .line 22
    :try_start_1
    invoke-virtual {v1}, Ljava/net/ServerSocket;->getLocalPort()I

    move-result v2
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_3

    .line 23
    :try_start_2
    invoke-virtual {v1}, Ljava/net/ServerSocket;->close()V

    .line 24
    new-instance v1, Ljava/io/File;

    const-string v5, "proxy-runtime.yaml"

    invoke-direct {v1, p2, v5}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    .line 25
    invoke-virtual {v1}, Ljava/io/File;->toPath()Ljava/nio/file/Path;

    move-result-object v5

    invoke-static {p3, v2, v0}, Lio/github/leexeo/cage/localcore/VlessConfig;->render(Ljava/lang/String;ILjava/lang/String;)Ljava/lang/String;

    move-result-object p3

    sget-object v6, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-virtual {p3, v6}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object p3

    new-array v3, v3, [Ljava/nio/file/OpenOption;

    invoke-static {v5, p3, v3}, Ljava/nio/file/Files;->write(Ljava/nio/file/Path;[B[Ljava/nio/file/OpenOption;)Ljava/nio/file/Path;

    .line 26
    iget-boolean p3, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->stopped:Z

    if-nez p3, :cond_5

    .line 27
    new-instance p3, Ljava/lang/ProcessBuilder;

    invoke-virtual {p1}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    move-result-object p1

    const-string v3, "-d"

    invoke-virtual {p2}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    move-result-object p2

    const-string v5, "-f"

    invoke-virtual {v1}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    move-result-object v1

    filled-new-array {p1, v3, p2, v5, v1}, [Ljava/lang/String;

    move-result-object p1

    invoke-direct {p3, p1}, Ljava/lang/ProcessBuilder;-><init>([Ljava/lang/String;)V

    .line 28
    invoke-virtual {p3, v4}, Ljava/lang/ProcessBuilder;->redirectErrorStream(Z)Ljava/lang/ProcessBuilder;

    move-result-object p1

    new-instance p2, Ljava/io/File;

    const-string p3, "/dev/null"

    invoke-direct {p2, p3}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {p1, p2}, Ljava/lang/ProcessBuilder;->redirectOutput(Ljava/io/File;)Ljava/lang/ProcessBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/ProcessBuilder;->start()Ljava/lang/Process;

    move-result-object p1

    iput-object p1, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->process:Ljava/lang/Process;

    .line 29
    new-instance p1, Lio/github/leexeo/cage/localcore/Upstream;

    const-string p2, "127.0.0.1"

    const-string p3, "cage"

    invoke-direct {p1, p2, v2, p3, v0}, Lio/github/leexeo/cage/localcore/Upstream;-><init>(Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;)V

    .line 30
    invoke-static {}, Ljava/lang/System;->nanoTime()J

    move-result-wide p2

    sget-object v0, Ljava/util/concurrent/TimeUnit;->SECONDS:Ljava/util/concurrent/TimeUnit;

    const-wide/16 v5, 0xa

    invoke-virtual {v0, v5, v6}, Ljava/util/concurrent/TimeUnit;->toNanos(J)J

    move-result-wide v0

    add-long/2addr p2, v0

    .line 31
    :goto_0
    iget-boolean v0, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->stopped:Z

    if-nez v0, :cond_4

    iget-object v0, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->process:Ljava/lang/Process;

    invoke-virtual {v0}, Ljava/lang/Process;->isAlive()Z

    move-result v0

    if-eqz v0, :cond_4

    invoke-static {}, Ljava/lang/System;->nanoTime()J

    move-result-wide v0
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_5

    cmp-long v0, v0, p2

    if-gez v0, :cond_4

    .line 32
    const/4 v0, 0x0

    :try_start_3
    new-instance v1, Ljava/net/Socket;

    sget-object v3, Ljava/net/Proxy;->NO_PROXY:Ljava/net/Proxy;

    invoke-direct {v1, v3}, Ljava/net/Socket;-><init>(Ljava/net/Proxy;)V
    :try_end_3
    .catch Ljava/io/IOException; {:try_start_3 .. :try_end_3} :catch_0
    .catchall {:try_start_3 .. :try_end_3} :catchall_2

    .line 33
    :try_start_4
    iput-object v1, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->handshake:Ljava/net/Socket;

    .line 34
    iget-boolean v3, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->stopped:Z

    if-nez v3, :cond_3

    .line 35
    new-instance v3, Ljava/net/InetSocketAddress;

    const-string v5, "127.0.0.1"

    invoke-direct {v3, v5, v2}, Ljava/net/InetSocketAddress;-><init>(Ljava/lang/String;I)V

    const/16 v5, 0xc8

    invoke-virtual {v1, v3, v5}, Ljava/net/Socket;->connect(Ljava/net/SocketAddress;I)V

    .line 36
    const/16 v3, 0x12c

    invoke-virtual {v1, v3}, Ljava/net/Socket;->setSoTimeout(I)V

    .line 37
    new-instance v3, Ljava/io/DataInputStream;

    invoke-virtual {v1}, Ljava/net/Socket;->getInputStream()Ljava/io/InputStream;

    move-result-object v5

    invoke-direct {v3, v5}, Ljava/io/DataInputStream;-><init>(Ljava/io/InputStream;)V

    .line 38
    invoke-virtual {v1}, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;

    move-result-object v5

    .line 39
    const/4 v6, 0x3

    new-array v6, v6, [B

    fill-array-data v6, :array_0

    invoke-virtual {v5, v6}, Ljava/io/OutputStream;->write([B)V

    invoke-virtual {v5}, Ljava/io/OutputStream;->flush()V

    .line 40
    invoke-virtual {v3}, Ljava/io/DataInputStream;->readUnsignedByte()I

    move-result v6

    const/4 v7, 0x5

    if-ne v6, v7, :cond_2

    invoke-virtual {v3}, Ljava/io/DataInputStream;->readUnsignedByte()I

    move-result v6

    const/4 v7, 0x2

    if-ne v6, v7, :cond_2

    .line 42
    invoke-virtual {v5, v4}, Ljava/io/OutputStream;->write(I)V

    iget-object v6, p1, Lio/github/leexeo/cage/localcore/Upstream;->username:[B

    array-length v6, v6

    invoke-virtual {v5, v6}, Ljava/io/OutputStream;->write(I)V

    iget-object v6, p1, Lio/github/leexeo/cage/localcore/Upstream;->username:[B

    invoke-virtual {v5, v6}, Ljava/io/OutputStream;->write([B)V

    .line 43
    iget-object v6, p1, Lio/github/leexeo/cage/localcore/Upstream;->password:[B

    array-length v6, v6

    invoke-virtual {v5, v6}, Ljava/io/OutputStream;->write(I)V

    iget-object v6, p1, Lio/github/leexeo/cage/localcore/Upstream;->password:[B

    invoke-virtual {v5, v6}, Ljava/io/OutputStream;->write([B)V

    invoke-virtual {v5}, Ljava/io/OutputStream;->flush()V

    .line 44
    invoke-virtual {v3}, Ljava/io/DataInputStream;->readUnsignedByte()I

    move-result v5

    if-ne v5, v4, :cond_1

    invoke-virtual {v3}, Ljava/io/DataInputStream;->readUnsignedByte()I

    move-result v3

    if-nez v3, :cond_1

    .line 46
    iget-boolean v3, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->stopped:Z

    if-nez v3, :cond_0

    iget-object v3, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->process:Ljava/lang/Process;

    invoke-virtual {v3}, Ljava/lang/Process;->isAlive()Z

    move-result v3
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_0

    if-eqz v3, :cond_0

    .line 47
    :try_start_5
    invoke-virtual {v1}, Ljava/net/Socket;->close()V
    :try_end_5
    .catch Ljava/io/IOException; {:try_start_5 .. :try_end_5} :catch_0
    .catchall {:try_start_5 .. :try_end_5} :catchall_2

    .line 49
    :try_start_6
    iput-object v0, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->handshake:Ljava/net/Socket;
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_5

    .line 46
    monitor-exit p0

    return-object p1

    .line 47
    :cond_0
    :try_start_7
    invoke-virtual {v1}, Ljava/net/Socket;->close()V
    :try_end_7
    .catch Ljava/io/IOException; {:try_start_7 .. :try_end_7} :catch_0
    .catchall {:try_start_7 .. :try_end_7} :catchall_2

    goto :goto_2

    .line 45
    :cond_1
    :try_start_8
    new-instance v3, Ljava/io/IOException;

    const-string v5, "loopback authentication failed"

    invoke-direct {v3, v5}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v3

    .line 41
    :cond_2
    new-instance v3, Ljava/io/IOException;

    const-string v5, "authenticated SOCKS required"

    invoke-direct {v3, v5}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v3

    .line 34
    :cond_3
    new-instance v3, Ljava/io/IOException;

    const-string v5, "stopped"

    invoke-direct {v3, v5}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v3
    :try_end_8
    .catchall {:try_start_8 .. :try_end_8} :catchall_0

    .line 32
    :catchall_0
    move-exception v3

    :try_start_9
    invoke-virtual {v1}, Ljava/net/Socket;->close()V
    :try_end_9
    .catchall {:try_start_9 .. :try_end_9} :catchall_1

    goto :goto_1

    :catchall_1
    move-exception v1

    :try_start_a
    invoke-virtual {v3, v1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_1
    throw v3
    :try_end_a
    .catch Ljava/io/IOException; {:try_start_a .. :try_end_a} :catch_0
    .catchall {:try_start_a .. :try_end_a} :catchall_2

    .line 49
    :catchall_2
    move-exception p1

    :try_start_b
    iput-object v0, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->handshake:Ljava/net/Socket;

    throw p1

    .line 47
    :catch_0
    move-exception v1

    .line 49
    :goto_2
    iput-object v0, p0, Lio/github/leexeo/cage/localcore/EmbeddedProxy;->handshake:Ljava/net/Socket;

    .line 50
    const-wide/16 v0, 0x4b

    invoke-static {v0, v1}, Ljava/lang/Thread;->sleep(J)V

    goto/16 :goto_0

    .line 52
    :cond_4
    new-instance p1, Ljava/io/IOException;

    const-string p2, "optional core startup failed"

    invoke-direct {p1, p2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 26
    :cond_5
    new-instance p1, Ljava/io/IOException;

    const-string p2, "stopped"

    invoke-direct {p1, p2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
    :try_end_b
    .catchall {:try_start_b .. :try_end_b} :catchall_5

    .line 21
    :catchall_3
    move-exception p1

    :try_start_c
    invoke-virtual {v1}, Ljava/net/ServerSocket;->close()V
    :try_end_c
    .catchall {:try_start_c .. :try_end_c} :catchall_4

    goto :goto_3

    :catchall_4
    move-exception p2

    :try_start_d
    invoke-virtual {p1, p2}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_3
    throw p1

    .line 17
    :cond_6
    new-instance p1, Ljava/io/IOException;

    const-string p2, "optional core unavailable"

    invoke-direct {p1, p2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 16
    :catchall_5
    move-exception p1

    monitor-exit p0
    :try_end_d
    .catchall {:try_start_d .. :try_end_d} :catchall_5

    throw p1

    nop

    :array_0
    .array-data 1
        0x5t
        0x1t
        0x2t
    .end array-data
.end method
