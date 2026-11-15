.class final Ltop/niunaijun/blackbox/network/GuestStreamHttps;
.super Ljava/lang/Object;
.source "GuestStreamHttps.java"


# static fields
.field private static final HOST:Ljava/lang/String; = "ipv4.icanhazip.com"


# instance fields
.field private final empty:Ljava/nio/ByteBuffer;

.field private final engine:Ljavax/net/ssl/SSLEngine;

.field private final input:Ljava/io/DataInputStream;

.field private final network:Ljava/nio/ByteBuffer;

.field private final output:Ljava/io/OutputStream;

.field private final plain:Ljava/nio/ByteBuffer;


# direct methods
.method private constructor <init>(Ljava/io/InputStream;Ljava/io/OutputStream;)V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 17
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 16
    const/4 v0, 0x0

    invoke-static {v0}, Ljava/nio/ByteBuffer;->allocate(I)Ljava/nio/ByteBuffer;

    move-result-object v0

    iput-object v0, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->empty:Ljava/nio/ByteBuffer;

    .line 18
    new-instance v0, Ljava/io/DataInputStream;

    invoke-direct {v0, p1}, Ljava/io/DataInputStream;-><init>(Ljava/io/InputStream;)V

    iput-object v0, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->input:Ljava/io/DataInputStream;

    .line 19
    iput-object p2, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->output:Ljava/io/OutputStream;

    .line 20
    invoke-static {}, Ljavax/net/ssl/SSLContext;->getDefault()Ljavax/net/ssl/SSLContext;

    move-result-object p1

    const/16 p2, 0x1bb

    const-string v0, "ipv4.icanhazip.com"

    invoke-virtual {p1, v0, p2}, Ljavax/net/ssl/SSLContext;->createSSLEngine(Ljava/lang/String;I)Ljavax/net/ssl/SSLEngine;

    move-result-object p1

    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    .line 21
    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    const/4 p2, 0x1

    invoke-virtual {p1, p2}, Ljavax/net/ssl/SSLEngine;->setUseClientMode(Z)V

    .line 22
    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    const-string p2, "TLSv1.2"

    filled-new-array {p2}, [Ljava/lang/String;

    move-result-object p2

    invoke-virtual {p1, p2}, Ljavax/net/ssl/SSLEngine;->setEnabledProtocols([Ljava/lang/String;)V

    .line 23
    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    invoke-virtual {p1}, Ljavax/net/ssl/SSLEngine;->getSSLParameters()Ljavax/net/ssl/SSLParameters;

    move-result-object p1

    .line 24
    const-string p2, "HTTPS"

    invoke-virtual {p1, p2}, Ljavax/net/ssl/SSLParameters;->setEndpointIdentificationAlgorithm(Ljava/lang/String;)V

    .line 25
    new-instance p2, Ljavax/net/ssl/SNIHostName;

    invoke-direct {p2, v0}, Ljavax/net/ssl/SNIHostName;-><init>(Ljava/lang/String;)V

    invoke-static {p2}, Ljava/util/Collections;->singletonList(Ljava/lang/Object;)Ljava/util/List;

    move-result-object p2

    invoke-virtual {p1, p2}, Ljavax/net/ssl/SSLParameters;->setServerNames(Ljava/util/List;)V

    .line 26
    iget-object p2, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    invoke-virtual {p2, p1}, Ljavax/net/ssl/SSLEngine;->setSSLParameters(Ljavax/net/ssl/SSLParameters;)V

    .line 27
    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    invoke-virtual {p1}, Ljavax/net/ssl/SSLEngine;->getSession()Ljavax/net/ssl/SSLSession;

    move-result-object p1

    invoke-interface {p1}, Ljavax/net/ssl/SSLSession;->getApplicationBufferSize()I

    move-result p1

    const p2, 0x8000

    invoke-static {p2, p1}, Ljava/lang/Math;->max(II)I

    move-result p1

    invoke-static {p1}, Ljava/nio/ByteBuffer;->allocate(I)Ljava/nio/ByteBuffer;

    move-result-object p1

    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->plain:Ljava/nio/ByteBuffer;

    .line 28
    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    invoke-virtual {p1}, Ljavax/net/ssl/SSLEngine;->getSession()Ljavax/net/ssl/SSLSession;

    move-result-object p1

    invoke-interface {p1}, Ljavax/net/ssl/SSLSession;->getPacketBufferSize()I

    move-result p1

    invoke-static {p2, p1}, Ljava/lang/Math;->max(II)I

    move-result p1

    invoke-static {p1}, Ljava/nio/ByteBuffer;->allocate(I)Ljava/nio/ByteBuffer;

    move-result-object p1

    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->network:Ljava/nio/ByteBuffer;

    .line 29
    return-void
.end method

.method static fetch(Ljava/io/InputStream;Ljava/io/OutputStream;)Ljava/lang/String;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 81
    new-instance v0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;

    invoke-direct {v0, p0, p1}, Ltop/niunaijun/blackbox/network/GuestStreamHttps;-><init>(Ljava/io/InputStream;Ljava/io/OutputStream;)V

    invoke-direct {v0}, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->run()Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method private read(Ljava/io/ByteArrayOutputStream;)Z
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 38
    const/4 v0, 0x5

    new-array v1, v0, [B

    .line 39
    const/4 v2, 0x0

    :try_start_0
    iget-object v3, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->input:Ljava/io/DataInputStream;

    invoke-virtual {v3, v1}, Ljava/io/DataInputStream;->readFully([B)V
    :try_end_0
    .catch Ljava/io/EOFException; {:try_start_0 .. :try_end_0} :catch_0

    .line 40
    const/4 v3, 0x3

    aget-byte v3, v1, v3

    and-int/lit16 v3, v3, 0xff

    shl-int/lit8 v3, v3, 0x8

    const/4 v4, 0x4

    aget-byte v4, v1, v4

    and-int/lit16 v4, v4, 0xff

    or-int/2addr v3, v4

    .line 41
    const/16 v4, 0x4800

    if-gt v3, v4, :cond_5

    .line 42
    add-int/lit8 v4, v3, 0x5

    new-array v4, v4, [B

    .line 43
    invoke-static {v1, v2, v4, v2, v0}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 44
    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->input:Ljava/io/DataInputStream;

    invoke-virtual {v1, v4, v0, v3}, Ljava/io/DataInputStream;->readFully([BII)V

    .line 45
    invoke-static {v4}, Ljava/nio/ByteBuffer;->wrap([B)Ljava/nio/ByteBuffer;

    move-result-object v0

    .line 46
    :goto_0
    invoke-virtual {v0}, Ljava/nio/ByteBuffer;->hasRemaining()Z

    move-result v1

    if-eqz v1, :cond_4

    .line 47
    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->plain:Ljava/nio/ByteBuffer;

    invoke-virtual {v1}, Ljava/nio/ByteBuffer;->clear()Ljava/nio/Buffer;

    .line 48
    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    iget-object v3, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->plain:Ljava/nio/ByteBuffer;

    invoke-virtual {v1, v0, v3}, Ljavax/net/ssl/SSLEngine;->unwrap(Ljava/nio/ByteBuffer;Ljava/nio/ByteBuffer;)Ljavax/net/ssl/SSLEngineResult;

    move-result-object v1

    .line 49
    invoke-virtual {v1}, Ljavax/net/ssl/SSLEngineResult;->getStatus()Ljavax/net/ssl/SSLEngineResult$Status;

    move-result-object v3

    sget-object v4, Ljavax/net/ssl/SSLEngineResult$Status;->CLOSED:Ljavax/net/ssl/SSLEngineResult$Status;

    if-ne v3, v4, :cond_0

    return v2

    .line 50
    :cond_0
    invoke-virtual {v1}, Ljavax/net/ssl/SSLEngineResult;->getStatus()Ljavax/net/ssl/SSLEngineResult$Status;

    move-result-object v3

    sget-object v4, Ljavax/net/ssl/SSLEngineResult$Status;->OK:Ljavax/net/ssl/SSLEngineResult$Status;

    if-ne v3, v4, :cond_3

    invoke-virtual {v1}, Ljavax/net/ssl/SSLEngineResult;->bytesConsumed()I

    move-result v1

    if-eqz v1, :cond_3

    .line 51
    if-eqz p1, :cond_1

    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->plain:Ljava/nio/ByteBuffer;

    invoke-virtual {v1}, Ljava/nio/ByteBuffer;->array()[B

    move-result-object v1

    iget-object v3, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->plain:Ljava/nio/ByteBuffer;

    invoke-virtual {v3}, Ljava/nio/ByteBuffer;->position()I

    move-result v3

    invoke-virtual {p1, v1, v2, v3}, Ljava/io/ByteArrayOutputStream;->write([BII)V

    .line 53
    :cond_1
    :goto_1
    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    invoke-virtual {v1}, Ljavax/net/ssl/SSLEngine;->getDelegatedTask()Ljava/lang/Runnable;

    move-result-object v1

    if-eqz v1, :cond_2

    invoke-interface {v1}, Ljava/lang/Runnable;->run()V

    goto :goto_1

    .line 54
    :cond_2
    goto :goto_0

    .line 50
    :cond_3
    new-instance p1, Ljavax/net/ssl/SSLException;

    const-string v0, "unwrap"

    invoke-direct {p1, v0}, Ljavax/net/ssl/SSLException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 55
    :cond_4
    const/4 p1, 0x1

    return p1

    .line 41
    :cond_5
    new-instance p1, Ljavax/net/ssl/SSLException;

    const-string v0, "invalid record"

    invoke-direct {p1, v0}, Ljavax/net/ssl/SSLException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 39
    :catch_0
    move-exception p1

    return v2
.end method

.method private run()Ljava/lang/String;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 58
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    invoke-virtual {v0}, Ljavax/net/ssl/SSLEngine;->beginHandshake()V

    .line 59
    const/4 v0, 0x0

    move v1, v0

    :goto_0
    const/16 v2, 0x80

    if-ge v1, v2, :cond_2

    .line 60
    sget-object v2, Ltop/niunaijun/blackbox/network/GuestStreamHttps$1;->$SwitchMap$javax$net$ssl$SSLEngineResult$HandshakeStatus:[I

    iget-object v3, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    invoke-virtual {v3}, Ljavax/net/ssl/SSLEngine;->getHandshakeStatus()Ljavax/net/ssl/SSLEngineResult$HandshakeStatus;

    move-result-object v3

    invoke-virtual {v3}, Ljavax/net/ssl/SSLEngineResult$HandshakeStatus;->ordinal()I

    move-result v3

    aget v2, v2, v3

    packed-switch v2, :pswitch_data_0

    .line 65
    goto :goto_3

    .line 64
    :goto_1
    :pswitch_0
    iget-object v2, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    invoke-virtual {v2}, Ljavax/net/ssl/SSLEngine;->getDelegatedTask()Ljava/lang/Runnable;

    move-result-object v2

    if-eqz v2, :cond_1

    invoke-interface {v2}, Ljava/lang/Runnable;->run()V

    goto :goto_1

    .line 62
    :pswitch_1
    const/4 v2, 0x0

    invoke-direct {p0, v2}, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->read(Ljava/io/ByteArrayOutputStream;)Z

    move-result v2

    if-eqz v2, :cond_0

    goto :goto_2

    :cond_0
    new-instance v0, Ljava/io/EOFException;

    invoke-direct {v0}, Ljava/io/EOFException;-><init>()V

    throw v0

    .line 61
    :pswitch_2
    iget-object v2, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->empty:Ljava/nio/ByteBuffer;

    invoke-direct {p0, v2}, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->write(Ljava/nio/ByteBuffer;)V

    .line 59
    :cond_1
    :goto_2
    add-int/lit8 v1, v1, 0x1

    goto :goto_0

    .line 69
    :cond_2
    :goto_3
    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    invoke-virtual {v1}, Ljavax/net/ssl/SSLEngine;->getHandshakeStatus()Ljavax/net/ssl/SSLEngineResult$HandshakeStatus;

    move-result-object v1

    sget-object v2, Ljavax/net/ssl/SSLEngineResult$HandshakeStatus;->NOT_HANDSHAKING:Ljavax/net/ssl/SSLEngineResult$HandshakeStatus;

    if-ne v1, v2, :cond_7

    .line 70
    const-string v1, "GET / HTTP/1.0\r\nHost: ipv4.icanhazip.com\r\nConnection: close\r\n\r\n"

    sget-object v2, Ljava/nio/charset/StandardCharsets;->US_ASCII:Ljava/nio/charset/Charset;

    invoke-virtual {v1, v2}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object v1

    invoke-static {v1}, Ljava/nio/ByteBuffer;->wrap([B)Ljava/nio/ByteBuffer;

    move-result-object v1

    .line 71
    :goto_4
    invoke-virtual {v1}, Ljava/nio/ByteBuffer;->hasRemaining()Z

    move-result v2

    if-eqz v2, :cond_3

    invoke-direct {p0, v1}, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->write(Ljava/nio/ByteBuffer;)V

    goto :goto_4

    .line 72
    :cond_3
    new-instance v1, Ljava/io/ByteArrayOutputStream;

    invoke-direct {v1}, Ljava/io/ByteArrayOutputStream;-><init>()V

    .line 73
    :goto_5
    invoke-virtual {v1}, Ljava/io/ByteArrayOutputStream;->size()I

    move-result v2

    const/16 v3, 0x2000

    if-ge v2, v3, :cond_4

    invoke-direct {p0, v1}, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->read(Ljava/io/ByteArrayOutputStream;)Z

    move-result v2

    if-eqz v2, :cond_4

    goto :goto_5

    .line 74
    :cond_4
    const-string v2, "US-ASCII"

    invoke-virtual {v1, v2}, Ljava/io/ByteArrayOutputStream;->toString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v1

    .line 75
    const-string v2, "\r\n\r\n"

    invoke-virtual {v1, v2}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result v2

    .line 76
    if-ltz v2, :cond_6

    const-string v3, "\r\n"

    invoke-virtual {v1, v3}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result v3

    invoke-virtual {v1, v0, v3}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v0

    const-string v3, "HTTP/1\\.[01] 200.*"

    invoke-virtual {v0, v3}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_6

    .line 77
    add-int/lit8 v2, v2, 0x4

    invoke-virtual {v1, v2}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v0

    .line 78
    sget-object v1, Landroid/util/Patterns;->IP_ADDRESS:Ljava/util/regex/Pattern;

    invoke-virtual {v1, v0}, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;

    move-result-object v1

    invoke-virtual {v1}, Ljava/util/regex/Matcher;->matches()Z

    move-result v1

    if-eqz v1, :cond_5

    .line 79
    return-object v0

    .line 78
    :cond_5
    new-instance v0, Ljava/io/IOException;

    const-string v1, "invalid address"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 76
    :cond_6
    new-instance v0, Ljava/io/IOException;

    const-string v1, "bad HTTP response"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 69
    :cond_7
    new-instance v0, Ljavax/net/ssl/SSLException;

    const-string v1, "handshake incomplete"

    invoke-direct {v0, v1}, Ljavax/net/ssl/SSLException;-><init>(Ljava/lang/String;)V

    throw v0

    :pswitch_data_0
    .packed-switch 0x1
        :pswitch_2
        :pswitch_1
        :pswitch_0
    .end packed-switch
.end method

.method private write(Ljava/nio/ByteBuffer;)V
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 31
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->network:Ljava/nio/ByteBuffer;

    invoke-virtual {v0}, Ljava/nio/ByteBuffer;->clear()Ljava/nio/Buffer;

    .line 32
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->engine:Ljavax/net/ssl/SSLEngine;

    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->network:Ljava/nio/ByteBuffer;

    invoke-virtual {v0, p1, v1}, Ljavax/net/ssl/SSLEngine;->wrap(Ljava/nio/ByteBuffer;Ljava/nio/ByteBuffer;)Ljavax/net/ssl/SSLEngineResult;

    move-result-object p1

    .line 33
    invoke-virtual {p1}, Ljavax/net/ssl/SSLEngineResult;->getStatus()Ljavax/net/ssl/SSLEngineResult$Status;

    move-result-object v0

    sget-object v1, Ljavax/net/ssl/SSLEngineResult$Status;->OK:Ljavax/net/ssl/SSLEngineResult$Status;

    if-ne v0, v1, :cond_0

    .line 34
    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->output:Ljava/io/OutputStream;

    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->network:Ljava/nio/ByteBuffer;

    invoke-virtual {v0}, Ljava/nio/ByteBuffer;->array()[B

    move-result-object v0

    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->network:Ljava/nio/ByteBuffer;

    invoke-virtual {v1}, Ljava/nio/ByteBuffer;->position()I

    move-result v1

    const/4 v2, 0x0

    invoke-virtual {p1, v0, v2, v1}, Ljava/io/OutputStream;->write([BII)V

    .line 35
    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestStreamHttps;->output:Ljava/io/OutputStream;

    invoke-virtual {p1}, Ljava/io/OutputStream;->flush()V

    .line 36
    return-void

    .line 33
    :cond_0
    new-instance v0, Ljavax/net/ssl/SSLException;

    invoke-virtual {p1}, Ljavax/net/ssl/SSLEngineResult;->getStatus()Ljavax/net/ssl/SSLEngineResult$Status;

    move-result-object p1

    invoke-virtual {p1}, Ljavax/net/ssl/SSLEngineResult$Status;->name()Ljava/lang/String;

    move-result-object p1

    invoke-direct {v0, p1}, Ljavax/net/ssl/SSLException;-><init>(Ljava/lang/String;)V

    throw v0
.end method
