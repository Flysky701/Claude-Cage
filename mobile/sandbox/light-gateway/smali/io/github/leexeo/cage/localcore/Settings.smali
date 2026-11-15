.class final Lio/github/leexeo/cage/localcore/Settings;
.super Ljava/lang/Object;
.source "Settings.java"


# direct methods
.method constructor <init>()V
    .locals 0

    .line 9
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method static configured(Landroid/content/Context;)Z
    .locals 1

    .line 13
    invoke-static {p0}, Lio/github/leexeo/cage/localcore/Settings;->file(Landroid/content/Context;)Ljava/io/File;

    move-result-object v0

    invoke-virtual {v0}, Ljava/io/File;->isFile()Z

    move-result v0

    if-nez v0, :cond_1

    invoke-static {p0}, Lio/github/leexeo/cage/localcore/Settings;->vlessFile(Landroid/content/Context;)Ljava/io/File;

    move-result-object p0

    invoke-virtual {p0}, Ljava/io/File;->isFile()Z

    move-result p0

    if-eqz p0, :cond_0

    goto :goto_0

    :cond_0
    const/4 p0, 0x0

    goto :goto_1

    :cond_1
    :goto_0
    const/4 p0, 0x1

    :goto_1
    return p0
.end method

.method static file(Landroid/content/Context;)Ljava/io/File;
    .locals 2

    .line 10
    new-instance v0, Ljava/io/File;

    invoke-virtual {p0}, Landroid/content/Context;->getFilesDir()Ljava/io/File;

    move-result-object p0

    const-string v1, "upstream.json"

    invoke-direct {v0, p0, v1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    return-object v0
.end method

.method static load(Landroid/content/Context;)Lio/github/leexeo/cage/localcore/Upstream;
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 27
    new-instance v0, Landroid/util/AtomicFile;

    invoke-static {p0}, Lio/github/leexeo/cage/localcore/Settings;->file(Landroid/content/Context;)Ljava/io/File;

    move-result-object p0

    invoke-direct {v0, p0}, Landroid/util/AtomicFile;-><init>(Ljava/io/File;)V

    .line 29
    invoke-virtual {v0}, Landroid/util/AtomicFile;->openRead()Ljava/io/FileInputStream;

    move-result-object p0

    :try_start_0
    new-instance v0, Ljava/io/ByteArrayOutputStream;

    invoke-direct {v0}, Ljava/io/ByteArrayOutputStream;-><init>()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    .line 30
    const/16 v1, 0x400

    :try_start_1
    new-array v1, v1, [B

    .line 31
    :goto_0
    invoke-virtual {p0, v1}, Ljava/io/InputStream;->read([B)I

    move-result v2

    const/4 v3, -0x1

    if-eq v2, v3, :cond_1

    .line 32
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->size()I

    move-result v3

    add-int/2addr v3, v2

    const/16 v4, 0x2000

    if-gt v3, v4, :cond_0

    .line 33
    const/4 v3, 0x0

    invoke-virtual {v0, v1, v3, v2}, Ljava/io/ByteArrayOutputStream;->write([BII)V

    goto :goto_0

    .line 32
    :cond_0
    new-instance v1, Ljava/io/IOException;

    const-string v2, "oversized config"

    invoke-direct {v1, v2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v1

    .line 35
    :cond_1
    new-instance v1, Lorg/json/JSONObject;

    new-instance v2, Ljava/lang/String;

    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->toByteArray()[B

    move-result-object v3

    sget-object v4, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-direct {v2, v3, v4}, Ljava/lang/String;-><init>([BLjava/nio/charset/Charset;)V

    invoke-direct {v1, v2}, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V

    .line 36
    const-string v2, "username"

    invoke-static {v1, v2}, Lio/github/leexeo/cage/localcore/Settings;->optionalString(Lorg/json/JSONObject;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v2

    .line 37
    const-string v3, "password"

    invoke-static {v1, v3}, Lio/github/leexeo/cage/localcore/Settings;->optionalString(Lorg/json/JSONObject;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    .line 38
    const-string v4, "port"

    invoke-virtual {v1, v4}, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v4

    .line 39
    instance-of v5, v4, Ljava/lang/Integer;

    if-eqz v5, :cond_4

    .line 40
    const-string v5, "host"

    invoke-virtual {v1, v5}, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v1

    .line 41
    instance-of v5, v1, Ljava/lang/String;

    if-eqz v5, :cond_3

    .line 42
    new-instance v5, Lio/github/leexeo/cage/localcore/Upstream;

    check-cast v1, Ljava/lang/String;

    check-cast v4, Ljava/lang/Integer;

    invoke-virtual {v4}, Ljava/lang/Integer;->intValue()I

    move-result v4

    invoke-direct {v5, v1, v4, v2, v3}, Lio/github/leexeo/cage/localcore/Upstream;-><init>(Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 43
    :try_start_2
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->close()V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_2

    if-eqz p0, :cond_2

    invoke-virtual {p0}, Ljava/io/InputStream;->close()V

    .line 42
    :cond_2
    return-object v5

    .line 41
    :cond_3
    :try_start_3
    new-instance v1, Ljava/io/IOException;

    const-string v2, "string host required"

    invoke-direct {v1, v2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v1

    .line 39
    :cond_4
    new-instance v1, Ljava/io/IOException;

    const-string v2, "integer port required"

    invoke-direct {v1, v2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v1
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 29
    :catchall_0
    move-exception v1

    :try_start_4
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->close()V
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_1

    goto :goto_1

    :catchall_1
    move-exception v0

    :try_start_5
    invoke-virtual {v1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_1
    throw v1
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_2

    :catchall_2
    move-exception v0

    if-eqz p0, :cond_5

    :try_start_6
    invoke-virtual {p0}, Ljava/io/InputStream;->close()V
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_3

    goto :goto_2

    :catchall_3
    move-exception p0

    invoke-virtual {v0, p0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_5
    :goto_2
    throw v0
.end method

.method static loadVless(Landroid/content/Context;)Ljava/lang/String;
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 16
    new-instance v0, Ljava/io/FileInputStream;

    invoke-static {p0}, Lio/github/leexeo/cage/localcore/Settings;->vlessFile(Landroid/content/Context;)Ljava/io/File;

    move-result-object p0

    invoke-direct {v0, p0}, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V

    :try_start_0
    new-instance p0, Ljava/io/ByteArrayOutputStream;

    invoke-direct {p0}, Ljava/io/ByteArrayOutputStream;-><init>()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    .line 17
    const/16 v1, 0x1000

    :try_start_1
    new-array v1, v1, [B

    .line 18
    :goto_0
    invoke-virtual {v0, v1}, Ljava/io/InputStream;->read([B)I

    move-result v2

    const/4 v3, -0x1

    if-eq v2, v3, :cond_1

    .line 19
    invoke-virtual {p0}, Ljava/io/ByteArrayOutputStream;->size()I

    move-result v3

    add-int/2addr v3, v2

    const/high16 v4, 0x40000

    if-gt v3, v4, :cond_0

    .line 20
    const/4 v3, 0x0

    invoke-virtual {p0, v1, v3, v2}, Ljava/io/ByteArrayOutputStream;->write([BII)V

    goto :goto_0

    .line 19
    :cond_0
    new-instance v1, Ljava/io/IOException;

    const-string v2, "oversized config"

    invoke-direct {v1, v2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v1

    .line 22
    :cond_1
    new-instance v1, Ljava/lang/String;

    invoke-virtual {p0}, Ljava/io/ByteArrayOutputStream;->toByteArray()[B

    move-result-object v2

    sget-object v3, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-direct {v1, v2, v3}, Ljava/lang/String;-><init>([BLjava/nio/charset/Charset;)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 23
    :try_start_2
    invoke-virtual {p0}, Ljava/io/ByteArrayOutputStream;->close()V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_2

    invoke-virtual {v0}, Ljava/io/InputStream;->close()V

    .line 22
    return-object v1

    .line 16
    :catchall_0
    move-exception v1

    :try_start_3
    invoke-virtual {p0}, Ljava/io/ByteArrayOutputStream;->close()V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    goto :goto_1

    :catchall_1
    move-exception p0

    :try_start_4
    invoke-virtual {v1, p0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_1
    throw v1
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_2

    :catchall_2
    move-exception p0

    :try_start_5
    invoke-virtual {v0}, Ljava/io/InputStream;->close()V
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_3

    goto :goto_2

    :catchall_3
    move-exception v0

    invoke-virtual {p0, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_2
    throw p0
.end method

.method private static optionalString(Lorg/json/JSONObject;Ljava/lang/String;)Ljava/lang/String;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 47
    invoke-virtual {p0, p1}, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_2

    invoke-virtual {p0, p1}, Lorg/json/JSONObject;->isNull(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_0

    goto :goto_0

    .line 48
    :cond_0
    invoke-virtual {p0, p1}, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object p0

    .line 49
    instance-of p1, p0, Ljava/lang/String;

    if-eqz p1, :cond_1

    .line 50
    check-cast p0, Ljava/lang/String;

    return-object p0

    .line 49
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string p1, "string credential required"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 47
    :cond_2
    :goto_0
    const/4 p0, 0x0

    return-object p0
.end method

.method static save(Landroid/content/Context;Lio/github/leexeo/cage/localcore/Upstream;)V
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 54
    new-instance v0, Lorg/json/JSONObject;

    invoke-direct {v0}, Lorg/json/JSONObject;-><init>()V

    .line 55
    const-string v1, "host"

    iget-object v2, p1, Lio/github/leexeo/cage/localcore/Upstream;->host:Ljava/lang/String;

    invoke-virtual {v0, v1, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    .line 56
    const-string v1, "port"

    iget v2, p1, Lio/github/leexeo/cage/localcore/Upstream;->port:I

    invoke-virtual {v0, v1, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

    .line 57
    iget-object v1, p1, Lio/github/leexeo/cage/localcore/Upstream;->username:[B

    if-eqz v1, :cond_0

    .line 58
    const-string v1, "username"

    invoke-virtual {p1}, Lio/github/leexeo/cage/localcore/Upstream;->user()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v0, v1, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    .line 59
    const-string v1, "password"

    invoke-virtual {p1}, Lio/github/leexeo/cage/localcore/Upstream;->secret()Ljava/lang/String;

    move-result-object p1

    invoke-virtual {v0, v1, p1}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    .line 61
    :cond_0
    new-instance p1, Landroid/util/AtomicFile;

    invoke-static {p0}, Lio/github/leexeo/cage/localcore/Settings;->file(Landroid/content/Context;)Ljava/io/File;

    move-result-object p0

    invoke-direct {p1, p0}, Landroid/util/AtomicFile;-><init>(Ljava/io/File;)V

    .line 62
    invoke-virtual {p1}, Landroid/util/AtomicFile;->startWrite()Ljava/io/FileOutputStream;

    move-result-object p0

    .line 64
    :try_start_0
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v0}, Lorg/json/JSONObject;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, "\n"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-virtual {v0, v1}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object v0

    invoke-virtual {p0, v0}, Ljava/io/FileOutputStream;->write([B)V

    .line 65
    invoke-virtual {p1, p0}, Landroid/util/AtomicFile;->finishWrite(Ljava/io/FileOutputStream;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 66
    nop

    .line 67
    return-void

    .line 66
    :catch_0
    move-exception v0

    invoke-virtual {p1, p0}, Landroid/util/AtomicFile;->failWrite(Ljava/io/FileOutputStream;)V

    throw v0
.end method

.method static vlessFile(Landroid/content/Context;)Ljava/io/File;
    .locals 2

    .line 11
    new-instance v0, Ljava/io/File;

    invoke-virtual {p0}, Landroid/content/Context;->getFilesDir()Ljava/io/File;

    move-result-object p0

    const-string v1, "upstream-vless.yaml"

    invoke-direct {v0, p0, v1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    return-object v0
.end method
