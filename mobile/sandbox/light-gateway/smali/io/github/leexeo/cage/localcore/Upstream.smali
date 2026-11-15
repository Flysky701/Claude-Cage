.class final Lio/github/leexeo/cage/localcore/Upstream;
.super Ljava/lang/Object;
.source "Upstream.java"


# instance fields
.field final host:Ljava/lang/String;

.field final password:[B

.field private final passwordText:Ljava/lang/String;

.field final port:I

.field private final userText:Ljava/lang/String;

.field final username:[B


# direct methods
.method constructor <init>(Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;)V
    .locals 4

    .line 15
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 16
    if-eqz p1, :cond_9

    invoke-virtual {p1}, Ljava/lang/String;->length()I

    move-result v0

    if-eqz v0, :cond_9

    invoke-virtual {p1}, Ljava/lang/String;->length()I

    move-result v0

    const/16 v1, 0xfd

    if-gt v0, v1, :cond_9

    const/4 v0, 0x1

    if-lt p2, v0, :cond_9

    const v1, 0xffff

    if-gt p2, v1, :cond_9

    .line 17
    const-string v1, "[A-Za-z0-9.:_-]+"

    invoke-virtual {p1, v1}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_9

    const-string v1, "%"

    invoke-virtual {p1, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result v1

    if-nez v1, :cond_9

    .line 19
    const/4 v1, 0x0

    if-nez p3, :cond_0

    move v2, v0

    goto :goto_0

    :cond_0
    move v2, v1

    :goto_0
    if-nez p4, :cond_1

    move v3, v0

    goto :goto_1

    :cond_1
    move v3, v1

    :goto_1
    if-ne v2, v3, :cond_8

    .line 20
    if-eqz p3, :cond_3

    invoke-virtual {p3, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v2

    if-gez v2, :cond_2

    invoke-virtual {p4, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    if-gez v1, :cond_2

    goto :goto_2

    .line 21
    :cond_2
    new-instance p1, Ljava/lang/IllegalArgumentException;

    const-string p2, "NUL is not supported by native credentials"

    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 22
    :cond_3
    :goto_2
    iput-object p1, p0, Lio/github/leexeo/cage/localcore/Upstream;->host:Ljava/lang/String;

    .line 23
    iput p2, p0, Lio/github/leexeo/cage/localcore/Upstream;->port:I

    .line 24
    iput-object p3, p0, Lio/github/leexeo/cage/localcore/Upstream;->userText:Ljava/lang/String;

    .line 25
    iput-object p4, p0, Lio/github/leexeo/cage/localcore/Upstream;->passwordText:Ljava/lang/String;

    .line 26
    const/4 p1, 0x0

    if-nez p3, :cond_4

    move-object p2, p1

    goto :goto_3

    :cond_4
    sget-object p2, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-virtual {p3, p2}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object p2

    :goto_3
    iput-object p2, p0, Lio/github/leexeo/cage/localcore/Upstream;->username:[B

    .line 27
    if-nez p4, :cond_5

    goto :goto_4

    :cond_5
    sget-object p1, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-virtual {p4, p1}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object p1

    :goto_4
    iput-object p1, p0, Lio/github/leexeo/cage/localcore/Upstream;->password:[B

    .line 28
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/Upstream;->username:[B

    if-eqz p1, :cond_7

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/Upstream;->username:[B

    array-length p1, p1

    if-lt p1, v0, :cond_6

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/Upstream;->username:[B

    array-length p1, p1

    const/16 p2, 0xff

    if-gt p1, p2, :cond_6

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/Upstream;->password:[B

    array-length p1, p1

    if-lt p1, v0, :cond_6

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/Upstream;->password:[B

    array-length p1, p1

    if-gt p1, p2, :cond_6

    goto :goto_5

    .line 30
    :cond_6
    new-instance p1, Ljava/lang/IllegalArgumentException;

    const-string p2, "invalid credential length"

    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 31
    :cond_7
    :goto_5
    return-void

    .line 19
    :cond_8
    new-instance p1, Ljava/lang/IllegalArgumentException;

    const-string p2, "incomplete credentials"

    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 18
    :cond_9
    new-instance p1, Ljava/lang/IllegalArgumentException;

    const-string p2, "invalid upstream"

    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

.method private static decode(Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    .line 53
    :try_start_0
    const-string v0, "+"

    const-string v1, "%2B"

    invoke-virtual {p0, v0, v1}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object p0

    const-string v0, "UTF-8"

    invoke-static {p0, v0}, Ljava/net/URLDecoder;->decode(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0
    :try_end_0
    .catch Ljava/io/UnsupportedEncodingException; {:try_start_0 .. :try_end_0} :catch_0

    return-object p0

    .line 54
    :catch_0
    move-exception p0

    new-instance v0, Ljava/lang/AssertionError;

    invoke-direct {v0, p0}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V

    throw v0
.end method

.method static parse(Ljava/lang/String;)Lio/github/leexeo/cage/localcore/Upstream;
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/net/URISyntaxException;
        }
    .end annotation

    .line 34
    new-instance v0, Ljava/net/URI;

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p0

    invoke-direct {v0, p0}, Ljava/net/URI;-><init>(Ljava/lang/String;)V

    .line 35
    const-string p0, "socks5"

    invoke-virtual {v0}, Ljava/net/URI;->getScheme()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {p0, v1}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_4

    invoke-virtual {v0}, Ljava/net/URI;->getHost()Ljava/lang/String;

    move-result-object p0

    if-eqz p0, :cond_4

    .line 36
    invoke-virtual {v0}, Ljava/net/URI;->getRawPath()Ljava/lang/String;

    move-result-object p0

    if-eqz p0, :cond_0

    invoke-virtual {v0}, Ljava/net/URI;->getRawPath()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/String;->isEmpty()Z

    move-result p0

    if-eqz p0, :cond_4

    .line 37
    :cond_0
    invoke-virtual {v0}, Ljava/net/URI;->getRawQuery()Ljava/lang/String;

    move-result-object p0

    if-nez p0, :cond_4

    invoke-virtual {v0}, Ljava/net/URI;->getRawFragment()Ljava/lang/String;

    move-result-object p0

    if-nez p0, :cond_4

    .line 39
    invoke-virtual {v0}, Ljava/net/URI;->getHost()Ljava/lang/String;

    move-result-object p0

    .line 40
    const-string v1, "["

    invoke-virtual {p0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    const/4 v2, 0x1

    if-eqz v1, :cond_1

    const-string v1, "]"

    invoke-virtual {p0, v1}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_1

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v1

    sub-int/2addr v1, v2

    invoke-virtual {p0, v2, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    .line 41
    :cond_1
    nop

    .line 42
    invoke-virtual {v0}, Ljava/net/URI;->getRawUserInfo()Ljava/lang/String;

    move-result-object v1

    .line 43
    if-eqz v1, :cond_3

    .line 44
    const/16 v3, 0x3a

    invoke-virtual {v1, v3}, Ljava/lang/String;->indexOf(I)I

    move-result v3

    .line 45
    if-ltz v3, :cond_2

    .line 46
    const/4 v4, 0x0

    invoke-virtual {v1, v4, v3}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v4

    invoke-static {v4}, Lio/github/leexeo/cage/localcore/Upstream;->decode(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v4

    .line 47
    add-int/2addr v3, v2

    invoke-virtual {v1, v3}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Lio/github/leexeo/cage/localcore/Upstream;->decode(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v1

    goto :goto_0

    .line 45
    :cond_2
    new-instance p0, Ljava/lang/IllegalArgumentException;

    const-string v0, "both credentials required"

    invoke-direct {p0, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 43
    :cond_3
    const/4 v4, 0x0

    move-object v1, v4

    .line 49
    :goto_0
    new-instance v2, Lio/github/leexeo/cage/localcore/Upstream;

    invoke-virtual {v0}, Ljava/net/URI;->getPort()I

    move-result v0

    invoke-direct {v2, p0, v0, v4, v1}, Lio/github/leexeo/cage/localcore/Upstream;-><init>(Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;)V

    return-object v2

    .line 38
    :cond_4
    new-instance p0, Ljava/lang/IllegalArgumentException;

    const-string v0, "SOCKS5 URI required"

    invoke-direct {p0, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw p0
.end method


# virtual methods
.method secret()Ljava/lang/String;
    .locals 1

    .line 58
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/Upstream;->passwordText:Ljava/lang/String;

    return-object v0
.end method

.method user()Ljava/lang/String;
    .locals 1

    .line 57
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/Upstream;->userText:Ljava/lang/String;

    return-object v0
.end method
