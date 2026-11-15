.class public final Ltop/niunaijun/blackbox/region/GuestRegion;
.super Ljava/lang/Object;
.source "GuestRegion.java"


# static fields
.field private static bound:Ltop/niunaijun/blackbox/region/GuestRegion;


# instance fields
.field public final language:Ljava/lang/String;

.field public final zone:Ljava/lang/String;


# direct methods
.method public constructor <init>(Ljava/lang/String;Ljava/lang/String;)V
    .locals 2

    .line 16
    const-string v0, "\u8bf7\u8f93\u5165\u6709\u6548\u7684\u8bed\u8a00\u6807\u7b7e"

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 19
    :try_start_0
    new-instance v1, Ljava/util/Locale$Builder;

    invoke-direct {v1}, Ljava/util/Locale$Builder;-><init>()V

    invoke-virtual {p1}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p1

    invoke-virtual {v1, p1}, Ljava/util/Locale$Builder;->setLanguageTag(Ljava/lang/String;)Ljava/util/Locale$Builder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/util/Locale$Builder;->build()Ljava/util/Locale;

    move-result-object p1
    :try_end_0
    .catch Ljava/util/IllformedLocaleException; {:try_start_0 .. :try_end_0} :catch_0

    .line 22
    nop

    .line 23
    invoke-virtual {p1}, Ljava/util/Locale;->getLanguage()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/String;->isEmpty()Z

    move-result v1

    if-nez v1, :cond_1

    .line 24
    invoke-virtual {p1}, Ljava/util/Locale;->toLanguageTag()Ljava/lang/String;

    move-result-object p1

    iput-object p1, p0, Ltop/niunaijun/blackbox/region/GuestRegion;->language:Ljava/lang/String;

    .line 25
    invoke-virtual {p2}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p1

    iput-object p1, p0, Ltop/niunaijun/blackbox/region/GuestRegion;->zone:Ljava/lang/String;

    .line 26
    invoke-static {}, Ljava/util/TimeZone;->getAvailableIDs()[Ljava/lang/String;

    move-result-object p1

    invoke-static {p1}, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;

    move-result-object p1

    iget-object p2, p0, Ltop/niunaijun/blackbox/region/GuestRegion;->zone:Ljava/lang/String;

    invoke-interface {p1, p2}, Ljava/util/List;->contains(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_0

    .line 29
    return-void

    .line 27
    :cond_0
    new-instance p1, Ljava/lang/IllegalArgumentException;

    const-string p2, "\u8bf7\u8f93\u5165\u6709\u6548\u7684\u65f6\u533a\u540d\u79f0"

    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 23
    :cond_1
    new-instance p1, Ljava/lang/IllegalArgumentException;

    invoke-direct {p1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 20
    :catch_0
    move-exception p1

    .line 21
    new-instance p2, Ljava/lang/IllegalArgumentException;

    invoke-direct {p2, v0, p1}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw p2
.end method

.method public static apply(Landroid/content/Context;)V
    .locals 3

    .line 71
    sget-object v0, Ltop/niunaijun/blackbox/region/GuestRegion;->bound:Ltop/niunaijun/blackbox/region/GuestRegion;

    if-eqz v0, :cond_2

    if-nez p0, :cond_0

    goto :goto_0

    .line 72
    :cond_0
    sget-object v0, Ltop/niunaijun/blackbox/region/GuestRegion;->bound:Ltop/niunaijun/blackbox/region/GuestRegion;

    iget-object v0, v0, Ltop/niunaijun/blackbox/region/GuestRegion;->language:Ljava/lang/String;

    invoke-static {v0}, Landroid/os/LocaleList;->forLanguageTags(Ljava/lang/String;)Landroid/os/LocaleList;

    move-result-object v0

    .line 73
    invoke-virtual {p0}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;

    move-result-object p0

    .line 74
    new-instance v1, Landroid/content/res/Configuration;

    invoke-virtual {p0}, Landroid/content/res/Resources;->getConfiguration()Landroid/content/res/Configuration;

    move-result-object v2

    invoke-direct {v1, v2}, Landroid/content/res/Configuration;-><init>(Landroid/content/res/Configuration;)V

    .line 75
    invoke-virtual {v1}, Landroid/content/res/Configuration;->getLocales()Landroid/os/LocaleList;

    move-result-object v2

    invoke-virtual {v0, v2}, Landroid/os/LocaleList;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_1

    .line 76
    invoke-virtual {v1, v0}, Landroid/content/res/Configuration;->setLocales(Landroid/os/LocaleList;)V

    .line 77
    invoke-virtual {p0}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;

    move-result-object v2

    invoke-virtual {p0, v1, v2}, Landroid/content/res/Resources;->updateConfiguration(Landroid/content/res/Configuration;Landroid/util/DisplayMetrics;)V

    .line 79
    :cond_1
    invoke-static {v0}, Landroid/os/LocaleList;->setDefault(Landroid/os/LocaleList;)V

    .line 80
    sget-object p0, Ltop/niunaijun/blackbox/region/GuestRegion;->bound:Ltop/niunaijun/blackbox/region/GuestRegion;

    iget-object p0, p0, Ltop/niunaijun/blackbox/region/GuestRegion;->zone:Ljava/lang/String;

    invoke-static {p0}, Ljava/util/TimeZone;->getTimeZone(Ljava/lang/String;)Ljava/util/TimeZone;

    move-result-object p0

    invoke-static {p0}, Ljava/util/TimeZone;->setDefault(Ljava/util/TimeZone;)V

    .line 81
    return-void

    .line 71
    :cond_2
    :goto_0
    return-void
.end method

.method public static bind(Landroid/content/Context;ILandroid/content/Context;)V
    .locals 1

    .line 63
    :try_start_0
    invoke-static {p0, p1}, Ltop/niunaijun/blackbox/region/GuestRegion;->read(Landroid/content/Context;I)Ltop/niunaijun/blackbox/region/GuestRegion;

    move-result-object p0

    sput-object p0, Ltop/niunaijun/blackbox/region/GuestRegion;->bound:Ltop/niunaijun/blackbox/region/GuestRegion;
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_1
    .catch Ljava/lang/IllegalArgumentException; {:try_start_0 .. :try_end_0} :catch_0

    .line 67
    goto :goto_1

    .line 64
    :catch_0
    move-exception p0

    goto :goto_0

    :catch_1
    move-exception p0

    .line 65
    :goto_0
    const/4 p1, 0x0

    sput-object p1, Ltop/niunaijun/blackbox/region/GuestRegion;->bound:Ltop/niunaijun/blackbox/region/GuestRegion;

    .line 66
    const-string p1, "BlackBox"

    const-string v0, "Cannot load guest region"

    invoke-static {p1, v0, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 68
    :goto_1
    invoke-static {p2}, Ltop/niunaijun/blackbox/region/GuestRegion;->apply(Landroid/content/Context;)V

    .line 69
    return-void
.end method

.method private static file(Landroid/content/Context;I)Landroid/util/AtomicFile;
    .locals 4

    .line 31
    new-instance v0, Landroid/util/AtomicFile;

    new-instance v1, Ljava/io/File;

    invoke-virtual {p0}, Landroid/content/Context;->getNoBackupFilesDir()Ljava/io/File;

    move-result-object p0

    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "guest-region-"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, p1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {v1, p0, p1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-direct {v0, v1}, Landroid/util/AtomicFile;-><init>(Ljava/io/File;)V

    return-object v0
.end method

.method public static read(Landroid/content/Context;I)Ltop/niunaijun/blackbox/region/GuestRegion;
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 34
    invoke-static {p0, p1}, Ltop/niunaijun/blackbox/region/GuestRegion;->file(Landroid/content/Context;I)Landroid/util/AtomicFile;

    move-result-object p0

    .line 35
    :try_start_0
    new-instance p1, Ljava/io/DataInputStream;

    invoke-virtual {p0}, Landroid/util/AtomicFile;->openRead()Ljava/io/FileInputStream;

    move-result-object v0

    invoke-direct {p1, v0}, Ljava/io/DataInputStream;-><init>(Ljava/io/InputStream;)V
    :try_end_0
    .catch Ljava/io/FileNotFoundException; {:try_start_0 .. :try_end_0} :catch_0

    .line 36
    :try_start_1
    new-instance v0, Ltop/niunaijun/blackbox/region/GuestRegion;

    invoke-virtual {p1}, Ljava/io/DataInputStream;->readUTF()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {p1}, Ljava/io/DataInputStream;->readUTF()Ljava/lang/String;

    move-result-object v2

    invoke-direct {v0, v1, v2}, Ltop/niunaijun/blackbox/region/GuestRegion;-><init>(Ljava/lang/String;Ljava/lang/String;)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 37
    :try_start_2
    invoke-virtual {p1}, Ljava/io/DataInputStream;->close()V
    :try_end_2
    .catch Ljava/io/FileNotFoundException; {:try_start_2 .. :try_end_2} :catch_0

    .line 36
    return-object v0

    .line 35
    :catchall_0
    move-exception v0

    :try_start_3
    invoke-virtual {p1}, Ljava/io/DataInputStream;->close()V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    goto :goto_0

    :catchall_1
    move-exception p1

    :try_start_4
    invoke-virtual {v0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_0
    throw v0
    :try_end_4
    .catch Ljava/io/FileNotFoundException; {:try_start_4 .. :try_end_4} :catch_0

    .line 37
    :catch_0
    move-exception p1

    .line 38
    invoke-virtual {p0}, Landroid/util/AtomicFile;->getBaseFile()Ljava/io/File;

    move-result-object p0

    invoke-virtual {p0}, Ljava/io/File;->exists()Z

    move-result p0

    if-nez p0, :cond_0

    .line 39
    const/4 p0, 0x0

    return-object p0

    .line 38
    :cond_0
    throw p1
.end method

.method public static save(Landroid/content/Context;ILtop/niunaijun/blackbox/region/GuestRegion;)V
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 43
    invoke-static {p0, p1}, Ltop/niunaijun/blackbox/region/GuestRegion;->file(Landroid/content/Context;I)Landroid/util/AtomicFile;

    move-result-object p0

    .line 44
    if-nez p2, :cond_1

    .line 45
    invoke-virtual {p0}, Landroid/util/AtomicFile;->delete()V

    .line 46
    invoke-virtual {p0}, Landroid/util/AtomicFile;->getBaseFile()Ljava/io/File;

    move-result-object p0

    invoke-virtual {p0}, Ljava/io/File;->exists()Z

    move-result p0

    if-nez p0, :cond_0

    .line 47
    return-void

    .line 46
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u65e0\u6cd5\u6e05\u9664\u6765\u5bbe\u8bbe\u7f6e"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 49
    :cond_1
    invoke-virtual {p0}, Landroid/util/AtomicFile;->startWrite()Ljava/io/FileOutputStream;

    move-result-object p1

    .line 51
    :try_start_0
    new-instance v0, Ljava/io/DataOutputStream;

    invoke-direct {v0, p1}, Ljava/io/DataOutputStream;-><init>(Ljava/io/OutputStream;)V

    .line 52
    iget-object v1, p2, Ltop/niunaijun/blackbox/region/GuestRegion;->language:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/io/DataOutputStream;->writeUTF(Ljava/lang/String;)V

    .line 53
    iget-object p2, p2, Ltop/niunaijun/blackbox/region/GuestRegion;->zone:Ljava/lang/String;

    invoke-virtual {v0, p2}, Ljava/io/DataOutputStream;->writeUTF(Ljava/lang/String;)V

    .line 54
    invoke-virtual {v0}, Ljava/io/DataOutputStream;->flush()V

    .line 55
    invoke-virtual {p0, p1}, Landroid/util/AtomicFile;->finishWrite(Ljava/io/FileOutputStream;)V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    .line 59
    nop

    .line 60
    return-void

    .line 56
    :catch_0
    move-exception p2

    .line 57
    invoke-virtual {p0, p1}, Landroid/util/AtomicFile;->failWrite(Ljava/io/FileOutputStream;)V

    .line 58
    throw p2
.end method
