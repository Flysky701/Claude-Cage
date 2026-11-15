.class public final Lio/github/leexeo/cage/space/DemoNetworkCheck;
.super Ljava/lang/Object;
.source "DemoNetworkCheck.java"


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 13
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method private static check(Ljava/lang/String;Ljava/lang/String;)Z
    .locals 3

    .line 59
    nop

    .line 60
    nop

    .line 62
    const/4 v0, 0x0

    const/4 v1, 0x0

    :try_start_0
    new-instance v2, Ljava/net/URL;

    invoke-direct {v2, p1}, Ljava/net/URL;-><init>(Ljava/lang/String;)V

    invoke-virtual {v2}, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;

    move-result-object p1

    check-cast p1, Ljava/net/HttpURLConnection;
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_1
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    .line 63
    const/16 v0, 0x1388

    :try_start_1
    invoke-virtual {p1, v0}, Ljava/net/HttpURLConnection;->setConnectTimeout(I)V

    invoke-virtual {p1, v0}, Ljava/net/HttpURLConnection;->setReadTimeout(I)V

    .line 64
    invoke-virtual {p1, v1}, Ljava/net/HttpURLConnection;->setUseCaches(Z)V

    invoke-virtual {p1, v1}, Ljava/net/HttpURLConnection;->setInstanceFollowRedirects(Z)V

    .line 65
    const-string v0, "HEAD"

    invoke-virtual {p1, v0}, Ljava/net/HttpURLConnection;->setRequestMethod(Ljava/lang/String;)V

    const-string v0, "Connection"

    const-string v2, "close"

    invoke-virtual {p1, v0, v2}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    .line 66
    invoke-virtual {p1}, Ljava/net/HttpURLConnection;->getResponseCode()I

    move-result v0
    :try_end_1
    .catch Ljava/io/IOException; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 67
    const/16 v2, 0xc8

    if-lt v0, v2, :cond_0

    const/16 v2, 0x190

    if-ge v0, v2, :cond_0

    const/4 v0, 0x1

    move v1, v0

    .line 69
    :cond_0
    if-eqz p1, :cond_2

    invoke-virtual {p1}, Ljava/net/HttpURLConnection;->disconnect()V

    goto :goto_2

    :catchall_0
    move-exception p0

    move-object v0, p1

    goto :goto_0

    .line 68
    :catch_0
    move-exception v0

    move-object v0, p1

    goto :goto_1

    .line 69
    :catchall_1
    move-exception p0

    :goto_0
    if-eqz v0, :cond_1

    invoke-virtual {v0}, Ljava/net/HttpURLConnection;->disconnect()V

    :cond_1
    throw p0

    .line 68
    :catch_1
    move-exception p1

    .line 69
    :goto_1
    if-eqz v0, :cond_2

    invoke-virtual {v0}, Ljava/net/HttpURLConnection;->disconnect()V

    .line 70
    :cond_2
    :goto_2
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "network_check "

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string p1, "="

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0, v1}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    const-string p1, "CageDemo"

    invoke-static {p1, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 71
    return v1
.end method

.method private static exitDigest()Ljava/lang/String;
    .locals 11

    .line 35
    nop

    .line 37
    const/4 v0, 0x0

    :try_start_0
    new-instance v1, Ljava/net/URL;

    const-string v2, "https://ipv4.icanhazip.com"

    invoke-direct {v1, v2}, Ljava/net/URL;-><init>(Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;

    move-result-object v1

    check-cast v1, Ljava/net/HttpURLConnection;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_1
    .catchall {:try_start_0 .. :try_end_0} :catchall_3

    .line 38
    const/16 v2, 0x1388

    :try_start_1
    invoke-virtual {v1, v2}, Ljava/net/HttpURLConnection;->setConnectTimeout(I)V

    invoke-virtual {v1, v2}, Ljava/net/HttpURLConnection;->setReadTimeout(I)V

    .line 39
    const/4 v2, 0x0

    invoke-virtual {v1, v2}, Ljava/net/HttpURLConnection;->setUseCaches(Z)V

    invoke-virtual {v1, v2}, Ljava/net/HttpURLConnection;->setInstanceFollowRedirects(Z)V

    .line 40
    const-string v3, "Connection"

    const-string v4, "close"

    invoke-virtual {v1, v3, v4}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    .line 41
    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->getResponseCode()I

    move-result v3
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_2

    const/16 v4, 0xc8

    if-eq v3, v4, :cond_1

    .line 55
    if-eqz v1, :cond_0

    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->disconnect()V

    .line 41
    :cond_0
    return-object v0

    .line 42
    :cond_1
    const/16 v3, 0x40

    :try_start_2
    new-array v4, v3, [B

    .line 43
    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->getInputStream()Ljava/io/InputStream;

    move-result-object v5
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_0
    .catchall {:try_start_2 .. :try_end_2} :catchall_2

    move v6, v2

    .line 44
    :goto_0
    if-ge v6, v3, :cond_3

    rsub-int/lit8 v7, v6, 0x40

    :try_start_3
    invoke-virtual {v5, v4, v6, v7}, Ljava/io/InputStream;->read([BII)I

    move-result v7
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    const/4 v8, -0x1

    if-eq v7, v8, :cond_3

    add-int/2addr v6, v7

    goto :goto_0

    .line 43
    :catchall_0
    move-exception v2

    if-eqz v5, :cond_2

    :try_start_4
    invoke-virtual {v5}, Ljava/io/InputStream;->close()V
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_1

    goto :goto_1

    :catchall_1
    move-exception v3

    :try_start_5
    invoke-virtual {v2, v3}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_2
    :goto_1
    throw v2

    .line 45
    :cond_3
    if-eqz v5, :cond_4

    invoke-virtual {v5}, Ljava/io/InputStream;->close()V
    :try_end_5
    .catch Ljava/lang/Exception; {:try_start_5 .. :try_end_5} :catch_0
    .catchall {:try_start_5 .. :try_end_5} :catchall_2

    .line 46
    :cond_4
    if-ne v6, v3, :cond_6

    .line 55
    if-eqz v1, :cond_5

    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->disconnect()V

    .line 46
    :cond_5
    return-object v0

    .line 47
    :cond_6
    :try_start_6
    new-instance v5, Ljava/lang/String;

    sget-object v7, Ljava/nio/charset/StandardCharsets;->US_ASCII:Ljava/nio/charset/Charset;

    invoke-direct {v5, v4, v2, v6, v7}, Ljava/lang/String;-><init>([BIILjava/nio/charset/Charset;)V

    invoke-virtual {v5}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v4

    .line 48
    const-string v5, "(?:[0-9]{1,3}\\.){3}[0-9]{1,3}"

    invoke-virtual {v4, v5}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v5
    :try_end_6
    .catch Ljava/lang/Exception; {:try_start_6 .. :try_end_6} :catch_0
    .catchall {:try_start_6 .. :try_end_6} :catchall_2

    if-nez v5, :cond_8

    .line 55
    if-eqz v1, :cond_7

    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->disconnect()V

    .line 48
    :cond_7
    return-object v0

    .line 49
    :cond_8
    :try_start_7
    const-string v5, "\\."

    invoke-virtual {v4, v5}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object v5

    array-length v6, v5

    move v7, v2

    :goto_2
    const/16 v8, 0xff

    if-ge v7, v6, :cond_b

    aget-object v9, v5, v7

    invoke-static {v9}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result v9
    :try_end_7
    .catch Ljava/lang/Exception; {:try_start_7 .. :try_end_7} :catch_0
    .catchall {:try_start_7 .. :try_end_7} :catchall_2

    if-le v9, v8, :cond_a

    .line 55
    if-eqz v1, :cond_9

    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->disconnect()V

    .line 49
    :cond_9
    return-object v0

    :cond_a
    add-int/lit8 v7, v7, 0x1

    goto :goto_2

    .line 50
    :cond_b
    :try_start_8
    const-string v5, "SHA-256"

    invoke-static {v5}, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;

    move-result-object v5

    sget-object v6, Ljava/nio/charset/StandardCharsets;->US_ASCII:Ljava/nio/charset/Charset;

    invoke-virtual {v4, v6}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object v4

    invoke-virtual {v5, v4}, Ljava/security/MessageDigest;->digest([B)[B

    move-result-object v4

    .line 51
    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5, v3}, Ljava/lang/StringBuilder;-><init>(I)V

    .line 52
    array-length v3, v4

    :goto_3
    if-ge v2, v3, :cond_c

    aget-byte v6, v4, v2

    sget-object v7, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    const-string v9, "%02x"

    and-int/2addr v6, v8

    invoke-static {v6}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v6

    filled-new-array {v6}, [Ljava/lang/Object;

    move-result-object v6

    invoke-static {v7, v9, v6}, Ljava/lang/String;->format(Ljava/util/Locale;Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/String;

    move-result-object v6

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    add-int/lit8 v2, v2, 0x1

    goto :goto_3

    .line 53
    :cond_c
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0
    :try_end_8
    .catch Ljava/lang/Exception; {:try_start_8 .. :try_end_8} :catch_0
    .catchall {:try_start_8 .. :try_end_8} :catchall_2

    .line 55
    if-eqz v1, :cond_d

    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->disconnect()V

    .line 53
    :cond_d
    return-object v0

    .line 55
    :catchall_2
    move-exception v0

    goto :goto_4

    .line 54
    :catch_0
    move-exception v2

    goto :goto_5

    .line 55
    :catchall_3
    move-exception v1

    move-object v10, v1

    move-object v1, v0

    move-object v0, v10

    :goto_4
    if-eqz v1, :cond_e

    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->disconnect()V

    :cond_e
    throw v0

    .line 54
    :catch_1
    move-exception v1

    move-object v1, v0

    .line 55
    :goto_5
    if-eqz v1, :cond_f

    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->disconnect()V

    .line 54
    :cond_f
    return-object v0
.end method

.method static synthetic lambda$start$0(Landroid/app/Activity;Landroid/widget/TextView;ZZLjava/lang/Boolean;Ljava/lang/Runnable;)V
    .locals 2

    .line 25
    invoke-virtual {p0}, Landroid/app/Activity;->isDestroyed()Z

    move-result p0

    if-nez p0, :cond_4

    new-instance p0, Ljava/lang/StringBuilder;

    invoke-direct {p0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "\u57df\u540d\u8fde\u63a5\uff1a"

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, "\u6210\u529f"

    const-string v1, "\u672a\u8fde\u63a5"

    if-eqz p2, :cond_0

    move-object p2, v0

    goto :goto_0

    :cond_0
    move-object p2, v1

    :goto_0
    invoke-virtual {p0, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string p2, "\n\u6570\u5b57 IPv4 \u8fde\u63a5\uff1a"

    invoke-virtual {p0, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    .line 26
    if-eqz p3, :cond_1

    goto :goto_1

    :cond_1
    move-object v0, v1

    :goto_1
    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    .line 27
    if-nez p4, :cond_2

    const-string p2, ""

    goto :goto_3

    :cond_2
    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string p3, "\n\u9884\u671f\u51fa\u53e3\uff1a"

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p4}, Ljava/lang/Boolean;->booleanValue()Z

    move-result p3

    if-eqz p3, :cond_3

    const-string p3, "\u5339\u914d"

    goto :goto_2

    :cond_3
    const-string p3, "\u672a\u5339\u914d"

    :goto_2
    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    :goto_3
    invoke-virtual {p0, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string p2, "\n\u6b64\u7ed3\u679c\u53ea\u4ee3\u8868\u672c\u6b21\u8fde\u63a5\u3002\u7f51\u5173\u505c\u6b62\u540e\uff0c\u4e24\u9879\u90fd\u5e94\u672a\u8fde\u63a5\uff1b\u91cd\u65b0\u542f\u52a8\u540e\u5e94\u6062\u590d\u3002"

    invoke-virtual {p0, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    .line 25
    invoke-virtual {p1, p0}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 29
    :cond_4
    invoke-interface {p5}, Ljava/lang/Runnable;->run()V

    .line 30
    return-void
.end method

.method static synthetic lambda$start$1(Landroid/app/Activity;Landroid/widget/TextView;Ljava/lang/Runnable;)V
    .locals 11

    .line 16
    invoke-virtual {p0}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;

    move-result-object v0

    const-string v1, "expected_exit_sha256"

    invoke-virtual {v0, v1}, Landroid/content/Intent;->getStringExtra(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    .line 17
    const/4 v1, 0x0

    if-eqz v0, :cond_0

    const-string v2, "[0-9a-f]{64}"

    invoke-virtual {v0, v2}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v2

    if-nez v2, :cond_0

    move-object v0, v1

    .line 18
    :cond_0
    invoke-static {}, Lio/github/leexeo/cage/space/DemoNetworkCheck;->exitDigest()Ljava/lang/String;

    move-result-object v2

    .line 19
    if-eqz v2, :cond_1

    const/4 v3, 0x1

    goto :goto_0

    :cond_1
    const/4 v3, 0x0

    :goto_0
    move v7, v3

    .line 20
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "network_check domain="

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3, v7}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    const-string v4, "CageDemo"

    invoke-static {v4, v3}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 21
    if-nez v0, :cond_2

    goto :goto_1

    :cond_2
    invoke-virtual {v0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    invoke-static {v0}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object v1

    :goto_1
    move-object v9, v1

    .line 22
    if-eqz v9, :cond_3

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "network_check expected_exit_match="

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, v9}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-static {v4, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 23
    :cond_3
    const-string v0, "numeric_ipv4"

    const-string v1, "https://1.1.1.1/cdn-cgi/trace"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/DemoNetworkCheck;->check(Ljava/lang/String;Ljava/lang/String;)Z

    move-result v8

    .line 24
    new-instance v4, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;

    move-object v5, p0

    move-object v6, p1

    move-object v10, p2

    invoke-direct/range {v4 .. v10}, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;-><init>(Landroid/app/Activity;Landroid/widget/TextView;ZZLjava/lang/Boolean;Ljava/lang/Runnable;)V

    invoke-virtual {v5, v4}, Landroid/app/Activity;->runOnUiThread(Ljava/lang/Runnable;)V

    .line 31
    return-void
.end method

.method public static start(Landroid/app/Activity;Landroid/widget/TextView;Ljava/lang/Runnable;)V
    .locals 2

    .line 15
    new-instance v0, Ljava/lang/Thread;

    new-instance v1, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda0;

    invoke-direct {v1, p0, p1, p2}, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda0;-><init>(Landroid/app/Activity;Landroid/widget/TextView;Ljava/lang/Runnable;)V

    const-string p0, "Cage-network-check"

    invoke-direct {v0, v1, p0}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 31
    invoke-virtual {v0}, Ljava/lang/Thread;->start()V

    .line 32
    return-void
.end method
