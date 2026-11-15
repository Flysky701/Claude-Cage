.class final Ltop/niunaijun/blackbox/network/DefaultCurlControl;
.super Ljava/lang/Object;
.source "DefaultCurlControl.java"


# static fields
.field private static final TAG:Ljava/lang/String; = "CageLightControl"


# direct methods
.method constructor <init>()V
    .locals 0

    .line 14
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method static check(Landroid/os/Messenger;Landroid/os/Looper;)V
    .locals 4

    .line 17
    const/4 v0, 0x0

    const/4 v1, 0x4

    invoke-static {v0, v1}, Landroid/os/Message;->obtain(Landroid/os/Handler;I)Landroid/os/Message;

    move-result-object v0

    .line 18
    new-instance v1, Landroid/os/Messenger;

    new-instance v2, Landroid/os/Handler;

    new-instance v3, Ltop/niunaijun/blackbox/network/DefaultCurlControl$$ExternalSyntheticLambda1;

    invoke-direct {v3}, Ltop/niunaijun/blackbox/network/DefaultCurlControl$$ExternalSyntheticLambda1;-><init>()V

    invoke-direct {v2, p1, v3}, Landroid/os/Handler;-><init>(Landroid/os/Looper;Landroid/os/Handler$Callback;)V

    invoke-direct {v1, v2}, Landroid/os/Messenger;-><init>(Landroid/os/Handler;)V

    iput-object v1, v0, Landroid/os/Message;->replyTo:Landroid/os/Messenger;

    .line 24
    :try_start_0
    invoke-virtual {p0, v0}, Landroid/os/Messenger;->send(Landroid/os/Message;)V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    :catch_0
    move-exception p0

    const-string p0, "CageLightControl"

    const-string p1, "relay disconnected"

    invoke-static {p0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 25
    :goto_0
    return-void
.end method

.method static synthetic lambda$check$0()V
    .locals 3

    .line 20
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/network/DefaultCurlControl;->run()V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    :catch_0
    move-exception v0

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "control failed "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    const-string v1, "CageLightControl"

    invoke-static {v1, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 21
    :goto_0
    return-void
.end method

.method static synthetic lambda$check$1(Landroid/os/Message;)Z
    .locals 3

    .line 19
    iget v0, p0, Landroid/os/Message;->what:I

    const/4 v1, 0x4

    const/4 v2, 0x1

    if-ne v0, v1, :cond_0

    iget p0, p0, Landroid/os/Message;->arg1:I

    if-ne p0, v2, :cond_0

    new-instance p0, Ljava/lang/Thread;

    new-instance v0, Ltop/niunaijun/blackbox/network/DefaultCurlControl$$ExternalSyntheticLambda0;

    invoke-direct {v0}, Ltop/niunaijun/blackbox/network/DefaultCurlControl$$ExternalSyntheticLambda0;-><init>()V

    const-string v1, "Cage-default-curl-control"

    invoke-direct {p0, v0, v1}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 21
    invoke-virtual {p0}, Ljava/lang/Thread;->start()V

    .line 22
    :cond_0
    return v2
.end method

.method private static run()V
    .locals 11
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 27
    new-instance v0, Ljava/util/ArrayList;

    const-string v6, "--rate"

    const-string v7, "1/10s"

    const-string v1, "/system/bin/sh"

    const-string v2, "-c"

    const-string v3, "echo pid=$$; exec /system/bin/curl \"$@\""

    const-string v4, "curl-control"

    const-string v5, "-q"

    filled-new-array/range {v1 .. v7}, [Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;

    move-result-object v1

    invoke-direct {v0, v1}, Ljava/util/ArrayList;-><init>(Ljava/util/Collection;)V

    .line 29
    const/4 v1, 0x0

    :goto_0
    const/4 v2, 0x5

    const/4 v3, 0x1

    if-ge v1, v2, :cond_2

    .line 30
    if-lez v1, :cond_0

    const-string v2, "--next"

    invoke-interface {v0, v2}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 31
    :cond_0
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "\nresult-"

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v4, "=%{exitcode}\n"

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v10

    const-string v4, "-fsS"

    const-string v5, "--max-time"

    const-string v6, "7"

    const-string v7, "-H"

    const-string v8, "Connection: close"

    const-string v9, "-w"

    filled-new-array/range {v4 .. v10}, [Ljava/lang/String;

    move-result-object v2

    invoke-static {v0, v2}, Ljava/util/Collections;->addAll(Ljava/util/Collection;[Ljava/lang/Object;)Z

    .line 33
    rem-int/lit8 v2, v1, 0x2

    if-ne v2, v3, :cond_1

    .line 34
    const-string v2, "--connect-to"

    const-string v3, "ipv4.icanhazip.com:443:104.16.185.241:443"

    filled-new-array {v2, v3}, [Ljava/lang/String;

    move-result-object v2

    invoke-static {v0, v2}, Ljava/util/Collections;->addAll(Ljava/util/Collection;[Ljava/lang/Object;)Z

    .line 35
    :cond_1
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "https://ipv4.icanhazip.com/?cage="

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-interface {v0, v2}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 29
    add-int/lit8 v1, v1, 0x1

    goto :goto_0

    .line 37
    :cond_2
    new-instance v1, Ljava/lang/ProcessBuilder;

    invoke-direct {v1, v0}, Ljava/lang/ProcessBuilder;-><init>(Ljava/util/List;)V

    invoke-virtual {v1, v3}, Ljava/lang/ProcessBuilder;->redirectErrorStream(Z)Ljava/lang/ProcessBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/ProcessBuilder;->start()Ljava/lang/Process;

    move-result-object v0

    .line 38
    :try_start_0
    new-instance v1, Ljava/io/BufferedReader;

    new-instance v2, Ljava/io/InputStreamReader;

    invoke-virtual {v0}, Ljava/lang/Process;->getInputStream()Ljava/io/InputStream;

    move-result-object v3

    sget-object v4, Ljava/nio/charset/StandardCharsets;->US_ASCII:Ljava/nio/charset/Charset;

    invoke-direct {v2, v3, v4}, Ljava/io/InputStreamReader;-><init>(Ljava/io/InputStream;Ljava/nio/charset/Charset;)V

    invoke-direct {v1, v2}, Ljava/io/BufferedReader;-><init>(Ljava/io/Reader;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    .line 40
    :cond_3
    :goto_1
    :try_start_1
    invoke-virtual {v1}, Ljava/io/BufferedReader;->readLine()Ljava/lang/String;

    move-result-object v2
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    const-string v3, "CageLightControl"

    if-eqz v2, :cond_5

    .line 41
    :try_start_2
    const-string v4, "pid=[0-9]+|result-[0-4]=[0-9]+"

    invoke-virtual {v2, v4}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v4

    if-nez v4, :cond_4

    sget-object v4, Landroid/util/Patterns;->IP_ADDRESS:Ljava/util/regex/Pattern;

    .line 42
    invoke-virtual {v2}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v4, v5}, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;

    move-result-object v4

    invoke-virtual {v4}, Ljava/util/regex/Matcher;->matches()Z

    move-result v4

    if-eqz v4, :cond_3

    :cond_4
    invoke-static {v3, v2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    goto :goto_1

    .line 43
    :cond_5
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "complete rc="

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v0}, Ljava/lang/Process;->waitFor()I

    move-result v4

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-static {v3, v2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    .line 44
    :try_start_3
    invoke-virtual {v1}, Ljava/io/BufferedReader;->close()V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_2

    invoke-virtual {v0}, Ljava/lang/Process;->destroy()V

    .line 45
    return-void

    .line 38
    :catchall_0
    move-exception v2

    :try_start_4
    invoke-virtual {v1}, Ljava/io/BufferedReader;->close()V
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_1

    goto :goto_2

    :catchall_1
    move-exception v1

    :try_start_5
    invoke-virtual {v2, v1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_2
    throw v2
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_2

    .line 44
    :catchall_2
    move-exception v1

    invoke-virtual {v0}, Ljava/lang/Process;->destroy()V

    throw v1
.end method
