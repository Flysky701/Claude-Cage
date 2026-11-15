.class final Lio/github/leexeo/cage/localcore/TunnelConfig;
.super Ljava/lang/Object;
.source "TunnelConfig.java"


# static fields
.field static final DNS:Ljava/lang/String; = "198.18.0.2"

.field static final IPV4:Ljava/lang/String; = "198.18.0.1"

.field static final IPV6:Ljava/lang/String; = "fc00::1"


# direct methods
.method constructor <init>()V
    .locals 0

    .line 4
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method private static quote(Ljava/lang/String;)Ljava/lang/String;
    .locals 5

    .line 23
    new-instance v0, Ljava/lang/StringBuilder;

    const-string v1, "\""

    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 24
    const/4 v1, 0x0

    :goto_0
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v2

    const/16 v3, 0x22

    if-ge v1, v2, :cond_4

    .line 25
    invoke-virtual {p0, v1}, Ljava/lang/String;->charAt(I)C

    move-result v2

    .line 26
    const/16 v4, 0x5c

    if-eq v2, v4, :cond_3

    if-ne v2, v3, :cond_0

    goto :goto_2

    .line 27
    :cond_0
    const/16 v3, 0x20

    if-lt v2, v3, :cond_2

    const/16 v3, 0x7f

    if-eq v2, v3, :cond_2

    const/16 v3, 0x85

    if-eq v2, v3, :cond_2

    const/16 v3, 0x2028

    if-eq v2, v3, :cond_2

    const/16 v3, 0x2029

    if-ne v2, v3, :cond_1

    goto :goto_1

    .line 29
    :cond_1
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    goto :goto_3

    .line 28
    :cond_2
    :goto_1
    sget-object v3, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    filled-new-array {v2}, [Ljava/lang/Object;

    move-result-object v2

    const-string v4, "\\u%04x"

    invoke-static {v3, v4, v2}, Ljava/lang/String;->format(Ljava/util/Locale;Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    goto :goto_3

    .line 26
    :cond_3
    :goto_2
    invoke-virtual {v0, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 24
    :goto_3
    add-int/lit8 v1, v1, 0x1

    goto :goto_0

    .line 31
    :cond_4
    invoke-virtual {v0, v3}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method static render(Lio/github/leexeo/cage/localcore/Upstream;Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    .line 8
    if-eqz p1, :cond_1

    const-string v0, "[0-9a-fA-F:.]+"

    invoke-virtual {p1, v0}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_1

    .line 10
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "tunnel:\n  name: cage\n  mtu: 1500\n  ipv4: 198.18.0.1\n  ipv6: \'fc00::1\'\n  icmp: \'off\'\nsocks5:\n  address: "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    .line 12
    invoke-static {p1}, Lio/github/leexeo/cage/localcore/TunnelConfig;->quote(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v0, "\n  port: "

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    iget v0, p0, Lio/github/leexeo/cage/localcore/Upstream;->port:I

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v0, "\n  udp: \'udp\'\n  pipeline: false\n"

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    .line 13
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/Upstream;->username:[B

    if-eqz v0, :cond_0

    .line 14
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v0, "  username: "

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/Upstream;->user()Ljava/lang/String;

    move-result-object v0

    invoke-static {v0}, Lio/github/leexeo/cage/localcore/TunnelConfig;->quote(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v0, "\n  password: "

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/Upstream;->secret()Ljava/lang/String;

    move-result-object p0

    invoke-static {p0}, Lio/github/leexeo/cage/localcore/TunnelConfig;->quote(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string p1, "\n"

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    .line 15
    :cond_0
    new-instance p0, Ljava/lang/StringBuilder;

    invoke-direct {p0}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string p1, "mapdns:\n  address: "

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string p1, "198.18.0.2"

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string p1, "\n  port: 53\n  network: 100.64.0.0\n  netmask: 255.192.0.0\n  cache-size: 2048\nmisc:\n  max-session-count: 128\n  connect-timeout: 10000\n  tcp-read-write-timeout: 120000\n  udp-read-write-timeout: 120000\n  task-stack-size: 86016\n  tcp-buffer-size: 8192\n  log-file: null\n  log-level: error\n"

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    return-object p0

    .line 9
    :cond_1
    new-instance p0, Ljava/lang/IllegalArgumentException;

    const-string p1, "numeric upstream required"

    invoke-direct {p0, p1}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw p0
.end method
