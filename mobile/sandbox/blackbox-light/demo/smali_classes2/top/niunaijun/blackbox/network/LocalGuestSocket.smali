.class final Ltop/niunaijun/blackbox/network/LocalGuestSocket;
.super Ljava/net/SocketImpl;
.source "LocalGuestSocket.java"


# instance fields
.field private final options:Ljava/util/Map;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/Map<",
            "Ljava/lang/Integer;",
            "Ljava/lang/Object;",
            ">;"
        }
    .end annotation
.end field

.field private final path:Ljava/lang/String;

.field private final spaceApp:Z

.field private final transport:Landroid/net/LocalSocket;


# direct methods
.method constructor <init>(Ljava/lang/String;Z)V
    .locals 1

    .line 19
    invoke-direct {p0}, Ljava/net/SocketImpl;-><init>()V

    .line 16
    new-instance v0, Ljava/util/HashMap;

    invoke-direct {v0}, Ljava/util/HashMap;-><init>()V

    iput-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->options:Ljava/util/Map;

    .line 17
    new-instance v0, Landroid/net/LocalSocket;

    invoke-direct {v0}, Landroid/net/LocalSocket;-><init>()V

    iput-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    .line 19
    iput-object p1, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->path:Ljava/lang/String;

    iput-boolean p2, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->spaceApp:Z

    return-void
.end method

.method private static outgoingOnly()Ljava/net/SocketException;
    .locals 2

    .line 72
    new-instance v0, Ljava/net/SocketException;

    const-string v1, "outgoing TLS streams only"

    invoke-direct {v0, v1}, Ljava/net/SocketException;-><init>(Ljava/lang/String;)V

    return-object v0
.end method


# virtual methods
.method protected accept(Ljava/net/SocketImpl;)V
    .locals 0
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 70
    invoke-static {}, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->outgoingOnly()Ljava/net/SocketException;

    move-result-object p1

    throw p1
.end method

.method protected available()I
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 64
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->getInputStream()Ljava/io/InputStream;

    move-result-object v0

    invoke-virtual {v0}, Ljava/io/InputStream;->available()I

    move-result v0

    return v0
.end method

.method protected bind(Ljava/net/InetAddress;I)V
    .locals 0
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 68
    invoke-static {}, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->outgoingOnly()Ljava/net/SocketException;

    move-result-object p1

    throw p1
.end method

.method protected close()V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 67
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    invoke-virtual {v0}, Landroid/net/LocalSocket;->close()V

    return-void
.end method

.method protected connect(Ljava/lang/String;I)V
    .locals 0
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 25
    invoke-static {p1, p2}, Ljava/net/InetSocketAddress;->createUnresolved(Ljava/lang/String;I)Ljava/net/InetSocketAddress;

    move-result-object p1

    const/4 p2, 0x0

    invoke-virtual {p0, p1, p2}, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->connect(Ljava/net/SocketAddress;I)V

    .line 26
    return-void
.end method

.method protected connect(Ljava/net/InetAddress;I)V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 28
    new-instance v0, Ljava/net/InetSocketAddress;

    invoke-direct {v0, p1, p2}, Ljava/net/InetSocketAddress;-><init>(Ljava/net/InetAddress;I)V

    const/4 p1, 0x0

    invoke-virtual {p0, v0, p1}, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->connect(Ljava/net/SocketAddress;I)V

    .line 29
    return-void
.end method

.method protected connect(Ljava/net/SocketAddress;I)V
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 31
    instance-of v0, p1, Ljava/net/InetSocketAddress;

    if-eqz v0, :cond_a

    .line 32
    check-cast p1, Ljava/net/InetSocketAddress;

    .line 33
    sget-object v0, Ltop/niunaijun/blackbox/network/GuestExitCheck;->JAVA_PROXY:Ljava/net/InetSocketAddress;

    invoke-virtual {v0, p1}, Ljava/net/InetSocketAddress;->equals(Ljava/lang/Object;)Z

    move-result v0

    .line 34
    invoke-virtual {p1}, Ljava/net/InetSocketAddress;->getHostString()Ljava/lang/String;

    move-result-object v1

    .line 35
    if-nez v0, :cond_1

    iget-boolean v2, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->spaceApp:Z

    if-eqz v2, :cond_1

    invoke-static {v1}, Lio/github/leexeo/cage/space/SpaceSites;->allows(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_0

    goto :goto_0

    :cond_0
    new-instance p1, Ljava/net/ConnectException;

    const-string p2, "outside space route"

    invoke-direct {p1, p2}, Ljava/net/ConnectException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 36
    :cond_1
    :goto_0
    if-nez v0, :cond_4

    iget-boolean v2, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->spaceApp:Z

    if-nez v2, :cond_4

    const-string v2, "ipv4.icanhazip.com"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result v2

    if-nez v2, :cond_4

    .line 37
    invoke-virtual {p1}, Ljava/net/InetSocketAddress;->getAddress()Ljava/net/InetAddress;

    move-result-object v2

    if-eqz v2, :cond_2

    invoke-virtual {p1}, Ljava/net/InetSocketAddress;->getAddress()Ljava/net/InetAddress;

    move-result-object v1

    invoke-virtual {v1}, Ljava/net/InetAddress;->getHostAddress()Ljava/lang/String;

    move-result-object v1

    .line 38
    :cond_2
    const-string v2, "104.16.185.241"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_3

    goto :goto_1

    :cond_3
    new-instance p1, Ljava/net/ConnectException;

    const-string p2, "outside test site"

    invoke-direct {p1, p2}, Ljava/net/ConnectException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 40
    :cond_4
    :goto_1
    if-nez v0, :cond_6

    invoke-virtual {p1}, Ljava/net/InetSocketAddress;->getPort()I

    move-result v2

    const/16 v3, 0x1bb

    if-ne v2, v3, :cond_5

    goto :goto_2

    :cond_5
    new-instance p1, Ljava/net/ConnectException;

    const-string p2, "unsupported port"

    invoke-direct {p1, p2}, Ljava/net/ConnectException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 42
    :cond_6
    :goto_2
    :try_start_0
    iget-object v2, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    new-instance v3, Landroid/net/LocalSocketAddress;

    iget-object v4, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->path:Ljava/lang/String;

    sget-object v5, Landroid/net/LocalSocketAddress$Namespace;->FILESYSTEM:Landroid/net/LocalSocketAddress$Namespace;

    invoke-direct {v3, v4, v5}, Landroid/net/LocalSocketAddress;-><init>(Ljava/lang/String;Landroid/net/LocalSocketAddress$Namespace;)V

    invoke-virtual {v2, v3}, Landroid/net/LocalSocket;->connect(Landroid/net/LocalSocketAddress;)V

    .line 43
    iget-object v2, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    invoke-virtual {v2}, Landroid/net/LocalSocket;->getFileDescriptor()Ljava/io/FileDescriptor;

    move-result-object v2

    iput-object v2, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->fd:Ljava/io/FileDescriptor;

    .line 44
    if-nez v0, :cond_9

    .line 45
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    if-lez p2, :cond_7

    goto :goto_3

    :cond_7
    const/16 p2, 0x2710

    :goto_3
    invoke-virtual {v0, p2}, Landroid/net/LocalSocket;->setSoTimeout(I)V

    .line 46
    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "CONNECT "

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    const-string v0, ":443 HTTP/1.1\r\nHost: "

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    const-string v0, ":443\r\n\r\n"

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    .line 47
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    invoke-virtual {v0}, Landroid/net/LocalSocket;->getOutputStream()Ljava/io/OutputStream;

    move-result-object v0

    sget-object v1, Ljava/nio/charset/StandardCharsets;->US_ASCII:Ljava/nio/charset/Charset;

    invoke-virtual {p2, v1}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object p2

    invoke-virtual {v0, p2}, Ljava/io/OutputStream;->write([B)V

    .line 49
    const-string p2, "HTTP/1.1 200 Connection Established\r\n\r\n"

    sget-object v0, Ljava/nio/charset/StandardCharsets;->US_ASCII:Ljava/nio/charset/Charset;

    invoke-virtual {p2, v0}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object p2

    .line 50
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    invoke-virtual {v0}, Landroid/net/LocalSocket;->getInputStream()Ljava/io/InputStream;

    move-result-object v0

    .line 51
    array-length v1, p2

    const/4 v2, 0x0

    :goto_4
    if-ge v2, v1, :cond_9

    aget-byte v3, p2, v2

    invoke-virtual {v0}, Ljava/io/InputStream;->read()I

    move-result v4

    if-ne v4, v3, :cond_8

    add-int/lit8 v2, v2, 0x1

    goto :goto_4

    .line 52
    :cond_8
    new-instance p1, Ljava/net/ConnectException;

    const-string p2, "proxy unavailable"

    invoke-direct {p1, p2}, Ljava/net/ConnectException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 54
    :cond_9
    iget-object p2, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    const/16 v0, 0x1006

    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->getOption(I)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/lang/Integer;

    invoke-virtual {v0}, Ljava/lang/Integer;->intValue()I

    move-result v0

    invoke-virtual {p2, v0}, Landroid/net/LocalSocket;->setSoTimeout(I)V

    .line 55
    invoke-virtual {p1}, Ljava/net/InetSocketAddress;->getAddress()Ljava/net/InetAddress;

    move-result-object p2

    iput-object p2, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->address:Ljava/net/InetAddress;

    .line 56
    invoke-virtual {p1}, Ljava/net/InetSocketAddress;->getPort()I

    move-result p1

    iput p1, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->port:I
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    .line 60
    nop

    .line 61
    return-void

    .line 57
    :catch_0
    move-exception p1

    .line 58
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->close()V

    .line 59
    throw p1

    .line 31
    :cond_a
    new-instance p1, Ljava/net/SocketException;

    const-string p2, "unsupported address"

    invoke-direct {p1, p2}, Ljava/net/SocketException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

.method protected create(Z)V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 22
    if-eqz p1, :cond_0

    .line 23
    return-void

    .line 22
    :cond_0
    new-instance p1, Ljava/net/SocketException;

    const-string v0, "datagrams are unavailable"

    invoke-direct {p1, v0}, Ljava/net/SocketException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

.method protected getInputStream()Ljava/io/InputStream;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 62
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    invoke-virtual {v0}, Landroid/net/LocalSocket;->getInputStream()Ljava/io/InputStream;

    move-result-object v0

    return-object v0
.end method

.method public getOption(I)Ljava/lang/Object;
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/net/SocketException;
        }
    .end annotation

    .line 82
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->options:Ljava/util/Map;

    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    invoke-interface {v0, v1}, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_0

    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->options:Ljava/util/Map;

    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p1

    invoke-interface {v0, p1}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    return-object p1

    .line 83
    :cond_0
    const/4 v0, 0x0

    sparse-switch p1, :sswitch_data_0

    .line 89
    new-instance v0, Ljava/net/SocketException;

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "unsupported socket option "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {v0, p1}, Ljava/net/SocketException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 86
    :sswitch_0
    const/16 p1, 0x2000

    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p1

    return-object p1

    .line 84
    :sswitch_1
    invoke-static {}, Ljava/net/InetAddress;->getLoopbackAddress()Ljava/net/InetAddress;

    move-result-object p1

    return-object p1

    .line 85
    :sswitch_2
    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p1

    return-object p1

    .line 88
    :sswitch_3
    invoke-static {v0}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object p1

    return-object p1

    :sswitch_data_0
    .sparse-switch
        0x1 -> :sswitch_3
        0x3 -> :sswitch_2
        0x4 -> :sswitch_3
        0x8 -> :sswitch_3
        0xf -> :sswitch_1
        0x80 -> :sswitch_3
        0x1001 -> :sswitch_0
        0x1002 -> :sswitch_0
        0x1003 -> :sswitch_3
        0x1006 -> :sswitch_2
    .end sparse-switch
.end method

.method protected getOutputStream()Ljava/io/OutputStream;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 63
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    invoke-virtual {v0}, Landroid/net/LocalSocket;->getOutputStream()Ljava/io/OutputStream;

    move-result-object v0

    return-object v0
.end method

.method protected listen(I)V
    .locals 0
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 69
    invoke-static {}, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->outgoingOnly()Ljava/net/SocketException;

    move-result-object p1

    throw p1
.end method

.method protected sendUrgentData(I)V
    .locals 0
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 71
    invoke-static {}, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->outgoingOnly()Ljava/net/SocketException;

    move-result-object p1

    throw p1
.end method

.method public setOption(ILjava/lang/Object;)V
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/net/SocketException;
        }
    .end annotation

    .line 75
    const/16 v0, 0x1006

    if-ne p1, v0, :cond_0

    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->fd:Ljava/io/FileDescriptor;

    if-eqz v0, :cond_0

    .line 76
    :try_start_0
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    move-object v1, p2

    check-cast v1, Ljava/lang/Integer;

    invoke-virtual {v1}, Ljava/lang/Integer;->intValue()I

    move-result v1

    invoke-virtual {v0, v1}, Landroid/net/LocalSocket;->setSoTimeout(I)V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    .line 77
    goto :goto_0

    :catch_0
    move-exception p1

    new-instance p2, Ljava/net/SocketException;

    invoke-virtual {p1}, Ljava/io/IOException;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {p2, p1}, Ljava/net/SocketException;-><init>(Ljava/lang/String;)V

    throw p2

    .line 79
    :cond_0
    :goto_0
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->options:Ljava/util/Map;

    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p1

    invoke-interface {v0, p1, p2}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 80
    return-void
.end method

.method protected shutdownInput()V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 65
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    invoke-virtual {v0}, Landroid/net/LocalSocket;->shutdownInput()V

    return-void
.end method

.method protected shutdownOutput()V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 66
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/LocalGuestSocket;->transport:Landroid/net/LocalSocket;

    invoke-virtual {v0}, Landroid/net/LocalSocket;->shutdownOutput()V

    return-void
.end method
