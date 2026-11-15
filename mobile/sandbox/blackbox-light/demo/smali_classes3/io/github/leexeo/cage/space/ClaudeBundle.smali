.class public final Lio/github/leexeo/cage/space/ClaudeBundle;
.super Ljava/lang/Object;
.source "ClaudeBundle.java"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lio/github/leexeo/cage/space/ClaudeBundle$Selection;,
        Lio/github/leexeo/cage/space/ClaudeBundle$State;,
        Lio/github/leexeo/cage/space/ClaudeBundle$Apk;,
        Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;,
        Lio/github/leexeo/cage/space/ClaudeBundle$Record;,
        Lio/github/leexeo/cage/space/ClaudeBundle$CountingInputStream;
    }
.end annotation


# static fields
.field private static final ABI:Ljava/lang/String; = "arm64-v8a"

.field private static final ABI_SPLIT:Ljava/lang/String; = "config.arm64_v8a"

.field private static final DENSITIES:Ljava/util/Set;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/Set<",
            "Ljava/lang/String;",
            ">;"
        }
    .end annotation
.end field

.field static final HOST:Ljava/lang/String; = "top.niunaijun.microdem"

.field static final MAX_APK:J = 0xa000000L

.field static final MAX_APKS:I = 0x40

.field static final MAX_ARCHIVE:J = 0x10000000L

.field private static final MAX_EXPANDED:J = 0x20000000L

.field static final MAX_LIBRARY:J = 0x4000000L

.field private static final NS:Ljava/lang/String; = "http://schemas.android.com/apk/res/android"

.field private static final OTHER_ABI_SPLIT:Ljava/lang/String; = "config.armeabi_v7a"

.field static final PACKAGE:Ljava/lang/String; = "com.anthropic.claude"

.field private static final SIGNERS:Ljava/util/Set;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/Set<",
            "Ljava/lang/String;",
            ">;"
        }
    .end annotation
.end field


# direct methods
.method static constructor <clinit>()V
    .locals 8

    .line 47
    new-instance v0, Ljava/util/HashSet;

    const-string v1, "305a1e8a432e5ec0c612b2465359c3b88e3c95d6253599ac6088562b818b64a0"

    const-string v2, "ed0b07c55cc0a9a0085e2c7779e6abf85a4c5f1e6b236c940a77fe7b2b1c20cb"

    filled-new-array {v1, v2}, [Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;

    move-result-object v1

    invoke-direct {v0, v1}, Ljava/util/HashSet;-><init>(Ljava/util/Collection;)V

    sput-object v0, Lio/github/leexeo/cage/space/ClaudeBundle;->SIGNERS:Ljava/util/Set;

    .line 50
    new-instance v0, Ljava/util/HashSet;

    const-string v6, "config.xxhdpi"

    const-string v7, "config.xxxhdpi"

    const-string v1, "config.ldpi"

    const-string v2, "config.mdpi"

    const-string v3, "config.tvdpi"

    const-string v4, "config.hdpi"

    const-string v5, "config.xhdpi"

    filled-new-array/range {v1 .. v7}, [Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;

    move-result-object v1

    invoke-direct {v0, v1}, Ljava/util/HashSet;-><init>(Ljava/util/Collection;)V

    sput-object v0, Lio/github/leexeo/cage/space/ClaudeBundle;->DENSITIES:Ljava/util/Set;

    return-void
.end method

.method private constructor <init>()V
    .locals 0

    .line 59
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method static active(Ljava/io/File;)Landroid/util/AtomicFile;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 620
    new-instance v0, Landroid/util/AtomicFile;

    const-string v1, "active.json"

    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    invoke-direct {v0, p0}, Landroid/util/AtomicFile;-><init>(Ljava/io/File;)V

    return-object v0
.end method

.method private static bytes(Ljava/io/InputStream;I)[B
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 710
    new-instance v0, Ljava/io/ByteArrayOutputStream;

    invoke-direct {v0}, Ljava/io/ByteArrayOutputStream;-><init>()V

    .line 711
    const/16 v1, 0x2000

    new-array v1, v1, [B

    .line 712
    :goto_0
    invoke-virtual {p0, v1}, Ljava/io/InputStream;->read([B)I

    move-result v2

    const/4 v3, -0x1

    if-eq v2, v3, :cond_1

    .line 713
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->size()I

    move-result v3

    add-int/2addr v3, v2

    if-gt v3, p1, :cond_0

    .line 714
    const/4 v3, 0x0

    invoke-virtual {v0, v1, v3, v2}, Ljava/io/ByteArrayOutputStream;->write([BII)V

    goto :goto_0

    .line 713
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u5b89\u88c5\u8bb0\u5f55\u8fc7\u5927\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 716
    :cond_1
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->toByteArray()[B

    move-result-object p0

    return-object p0
.end method

.method static child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 622
    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->simple(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_0

    .line 623
    new-instance v0, Ljava/io/File;

    invoke-direct {v0, p0, p1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    move-result-object p0

    return-object p0

    .line 622
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u4e0d\u5b89\u5168\u7684\u79c1\u6709\u6587\u4ef6\u540d\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static copyNew(Ljava/io/InputStream;Ljava/io/File;JJ)V
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 664
    invoke-virtual {p1}, Ljava/io/File;->createNewFile()Z

    move-result v0

    if-eqz v0, :cond_3

    .line 665
    nop

    .line 666
    const/high16 v0, 0x10000

    new-array v0, v0, [B

    .line 667
    new-instance v1, Ljava/io/FileOutputStream;

    invoke-direct {v1, p1}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V

    const-wide/16 v2, 0x0

    .line 668
    :goto_0
    :try_start_0
    invoke-virtual {p0, v0}, Ljava/io/InputStream;->read([B)I

    move-result p1

    const/4 v4, -0x1

    if-eq p1, v4, :cond_1

    .line 669
    int-to-long v4, p1

    add-long/2addr v2, v4

    .line 670
    cmp-long v4, v2, p4

    if-gtz v4, :cond_0

    cmp-long v4, v2, p2

    if-gtz v4, :cond_0

    .line 671
    const/4 v4, 0x0

    invoke-virtual {v1, v0, v4, p1}, Ljava/io/FileOutputStream;->write([BII)V

    goto :goto_0

    .line 670
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u89e3\u538b\u6570\u636e\u8d85\u8fc7\u58f0\u660e\u5927\u5c0f\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 673
    :cond_1
    cmp-long p0, v2, p2

    if-nez p0, :cond_2

    .line 674
    invoke-virtual {v1}, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;

    move-result-object p0

    invoke-virtual {p0}, Ljava/io/FileDescriptor;->sync()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 675
    invoke-virtual {v1}, Ljava/io/FileOutputStream;->close()V

    .line 676
    return-void

    .line 673
    :cond_2
    :try_start_1
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u5b89\u88c5\u6587\u4ef6\u6570\u636e\u4e0d\u5b8c\u6574\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 667
    :catchall_0
    move-exception p0

    :try_start_2
    invoke-virtual {v1}, Ljava/io/FileOutputStream;->close()V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    goto :goto_1

    :catchall_1
    move-exception p1

    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_1
    throw p0

    .line 664
    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u62d2\u7edd\u8986\u76d6\u73b0\u6709\u5b89\u88c5\u6587\u4ef6\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static data(Landroid/content/Context;)Ljava/io/File;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 600
    if-eqz p0, :cond_1

    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v0

    const-string v1, "top.niunaijun.microdem"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_1

    .line 601
    invoke-virtual {p0}, Landroid/content/Context;->getDataDir()Ljava/io/File;

    move-result-object p0

    invoke-virtual {p0}, Ljava/io/File;->getCanonicalFile()Ljava/io/File;

    move-result-object p0

    .line 602
    invoke-virtual {p0}, Ljava/io/File;->getName()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_0

    invoke-virtual {p0}, Ljava/io/File;->isDirectory()Z

    move-result v0

    if-eqz v0, :cond_0

    .line 603
    return-object p0

    .line 602
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u65e0\u6cd5\u786e\u8ba4\u7a7a\u95f4\u79c1\u6709\u76ee\u5f55\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 600
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5bfc\u5165\u53ea\u9002\u7528\u4e8e\u6b64 DEMO \u7a7a\u95f4\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static decodeState(Landroid/content/Context;Lorg/json/JSONObject;ZLjava/io/File;)Lio/github/leexeo/cage/space/ClaudeBundle$State;
    .locals 0
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 462
    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->parseState(Landroid/content/Context;Lorg/json/JSONObject;)Lio/github/leexeo/cage/space/ClaudeBundle$State;

    move-result-object p0

    .line 463
    invoke-static {p0, p2, p3}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 464
    return-object p0
.end method

.method private static digest(Ljava/io/InputStream;J[B)Ljava/lang/String;
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 698
    const-string v0, "SHA-256"

    invoke-static {v0}, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;

    move-result-object v0

    .line 699
    if-eqz p3, :cond_0

    invoke-virtual {v0, p3}, Ljava/security/MessageDigest;->update([B)V

    .line 700
    :cond_0
    nop

    .line 701
    const/high16 p3, 0x10000

    new-array p3, p3, [B

    const-wide/16 v1, 0x0

    .line 702
    :goto_0
    invoke-virtual {p0, p3}, Ljava/io/InputStream;->read([B)I

    move-result v3

    const/4 v4, -0x1

    if-eq v3, v4, :cond_2

    .line 703
    int-to-long v4, v3

    add-long/2addr v1, v4

    .line 704
    cmp-long v4, v1, p1

    if-gtz v4, :cond_1

    .line 705
    const/4 v4, 0x0

    invoke-virtual {v0, p3, v4, v3}, Ljava/security/MessageDigest;->update([BII)V

    goto :goto_0

    .line 704
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u6587\u4ef6\u8d85\u51fa\u6821\u9a8c\u5927\u5c0f\u9650\u5236\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 707
    :cond_2
    invoke-virtual {v0}, Ljava/security/MessageDigest;->digest()[B

    move-result-object p0

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->hex([B)Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method private static digestNative(Ljava/io/InputStream;JZ)Ljava/lang/String;
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 681
    const/16 v0, 0x40

    new-array v1, v0, [B

    .line 682
    const/4 v2, 0x0

    move v3, v2

    .line 683
    :goto_0
    if-ge v3, v0, :cond_1

    .line 684
    rsub-int/lit8 v4, v3, 0x40

    invoke-virtual {p0, v1, v3, v4}, Ljava/io/InputStream;->read([BII)I

    move-result v4

    .line 685
    if-ltz v4, :cond_0

    .line 686
    add-int/2addr v3, v4

    .line 687
    goto :goto_0

    .line 685
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u539f\u751f\u5e93 ELF \u6587\u4ef6\u5934\u4e0d\u5b8c\u6574\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 688
    :cond_1
    aget-byte v2, v1, v2

    const/16 v3, 0x7f

    if-ne v2, v3, :cond_5

    const/4 v2, 0x1

    aget-byte v3, v1, v2

    const/16 v4, 0x45

    if-ne v3, v4, :cond_5

    const/4 v3, 0x2

    aget-byte v4, v1, v3

    const/16 v5, 0x4c

    if-ne v4, v5, :cond_5

    const/4 v4, 0x3

    aget-byte v5, v1, v4

    const/16 v6, 0x46

    if-ne v5, v6, :cond_5

    const/4 v5, 0x4

    aget-byte v5, v1, v5

    .line 689
    if-eqz p3, :cond_2

    move v3, v2

    :cond_2
    if-ne v5, v3, :cond_5

    const/4 v3, 0x5

    aget-byte v3, v1, v3

    if-ne v3, v2, :cond_5

    const/4 v3, 0x6

    aget-byte v3, v1, v3

    if-ne v3, v2, :cond_5

    const/16 v2, 0x10

    aget-byte v2, v1, v2

    if-ne v2, v4, :cond_5

    const/16 v2, 0x11

    aget-byte v2, v1, v2

    if-nez v2, :cond_5

    const/16 v2, 0x12

    aget-byte v2, v1, v2

    and-int/lit16 v2, v2, 0xff

    .line 690
    if-eqz p3, :cond_3

    const/16 p3, 0x28

    goto :goto_1

    :cond_3
    const/16 p3, 0xb7

    :goto_1
    if-ne v2, p3, :cond_5

    const/16 p3, 0x13

    aget-byte p3, v1, p3

    if-nez p3, :cond_5

    .line 692
    new-instance p3, Lio/github/leexeo/cage/space/ClaudeBundle$CountingInputStream;

    invoke-direct {p3, p0}, Lio/github/leexeo/cage/space/ClaudeBundle$CountingInputStream;-><init>(Ljava/io/InputStream;)V

    .line 693
    int-to-long v2, v0

    const-wide/32 v4, 0x4000000

    sub-long/2addr v4, v2

    invoke-static {p3, v4, v5, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->digest(Ljava/io/InputStream;J[B)Ljava/lang/String;

    move-result-object p0

    .line 694
    iget-wide v0, p3, Lio/github/leexeo/cage/space/ClaudeBundle$CountingInputStream;->count:J

    add-long/2addr v0, v2

    cmp-long p1, v0, p1

    if-nez p1, :cond_4

    .line 695
    return-object p0

    .line 694
    :cond_4
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u539f\u751f\u5e93\u6570\u636e\u957f\u5ea6\u4e0d\u4e00\u81f4\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 691
    :cond_5
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u539f\u751f\u5e93 ELF \u67b6\u6784\u6216\u7c7b\u578b\u4e0d\u5339\u914d\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static emptyTree(Ljava/io/File;[I)Z
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 635
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    .line 636
    invoke-virtual {p0}, Ljava/io/File;->exists()Z

    move-result v0

    const/4 v1, 0x1

    if-nez v0, :cond_0

    return v1

    .line 637
    :cond_0
    const/4 v0, 0x0

    aget v2, p1, v0

    add-int/2addr v2, v1

    aput v2, p1, v0

    const/16 v3, 0x80

    if-gt v2, v3, :cond_5

    invoke-virtual {p0}, Ljava/io/File;->isDirectory()Z

    move-result v2

    if-nez v2, :cond_1

    goto :goto_1

    .line 638
    :cond_1
    invoke-virtual {p0}, Ljava/io/File;->listFiles()[Ljava/io/File;

    move-result-object p0

    .line 639
    if-nez p0, :cond_2

    return v0

    .line 640
    :cond_2
    array-length v2, p0

    move v3, v0

    :goto_0
    if-ge v3, v2, :cond_4

    aget-object v4, p0, v3

    invoke-static {v4, p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->emptyTree(Ljava/io/File;[I)Z

    move-result v4

    if-nez v4, :cond_3

    return v0

    :cond_3
    add-int/lit8 v3, v3, 0x1

    goto :goto_0

    .line 641
    :cond_4
    return v1

    .line 637
    :cond_5
    :goto_1
    return v0
.end method

.method static encodeState(Lio/github/leexeo/cage/space/ClaudeBundle$State;)Lorg/json/JSONObject;
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 569
    new-instance v0, Lorg/json/JSONObject;

    invoke-direct {v0}, Lorg/json/JSONObject;-><init>()V

    .line 570
    const-string v1, "schema"

    const/4 v2, 0x1

    invoke-virtual {v0, v1, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

    move-result-object v1

    const-string v3, "package"

    const-string v4, "com.anthropic.claude"

    invoke-virtual {v1, v3, v4}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v1

    const-string v3, "version"

    iget-wide v4, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    invoke-virtual {v1, v3, v4, v5}, Lorg/json/JSONObject;->put(Ljava/lang/String;J)Lorg/json/JSONObject;

    move-result-object v1

    iget-object v3, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->versionName:Ljava/lang/String;

    .line 571
    const-string v4, "versionName"

    invoke-virtual {v1, v4, v3}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v1

    const-string v3, "signer"

    iget-object v4, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    invoke-virtual {v1, v3, v4}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v1

    const-string v3, "directory"

    iget-object v4, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directory:Ljava/lang/String;

    invoke-virtual {v1, v3, v4}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v1

    iget-object v3, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    .line 572
    invoke-static {v3, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->records(Ljava/util/List;Z)Lorg/json/JSONArray;

    move-result-object v2

    const-string v3, "apks"

    invoke-virtual {v1, v3, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v1

    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->libraries:Ljava/util/List;

    const/4 v2, 0x0

    invoke-static {p0, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->records(Ljava/util/List;Z)Lorg/json/JSONArray;

    move-result-object p0

    const-string v2, "libraries"

    invoke-virtual {v1, v2, p0}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    .line 573
    return-object v0
.end method

.method static exact(Ljava/io/File;)Ljava/io/File;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 626
    invoke-virtual {p0}, Ljava/io/File;->getAbsoluteFile()Ljava/io/File;

    move-result-object v0

    .line 627
    invoke-virtual {p0}, Ljava/io/File;->getCanonicalFile()Ljava/io/File;

    move-result-object p0

    invoke-virtual {v0, p0}, Ljava/io/File;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    .line 628
    return-object v0

    .line 627
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u79c1\u6709\u5b89\u88c5\u8def\u5f84\u5305\u542b\u94fe\u63a5\u6216\u8def\u5f84\u8df3\u8f6c\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static field(Ljava/lang/Class;Ljava/lang/String;)Ljava/lang/reflect/Field;
    .locals 2
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/lang/Class<",
            "*>;",
            "Ljava/lang/String;",
            ")",
            "Ljava/lang/reflect/Field;"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/NoSuchFieldException;
        }
    .end annotation

    .line 725
    nop

    :goto_0
    if-eqz p0, :cond_0

    .line 726
    :try_start_0
    invoke-virtual {p0, p1}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v0

    const/4 v1, 0x1

    invoke-virtual {v0, v1}, Ljava/lang/reflect/Field;->setAccessible(Z)V
    :try_end_0
    .catch Ljava/lang/NoSuchFieldException; {:try_start_0 .. :try_end_0} :catch_0

    return-object v0

    .line 727
    :catch_0
    move-exception v0

    .line 725
    invoke-virtual {p0}, Ljava/lang/Class;->getSuperclass()Ljava/lang/Class;

    move-result-object p0

    goto :goto_0

    .line 729
    :cond_0
    new-instance p0, Ljava/lang/NoSuchFieldException;

    invoke-direct {p0, p1}, Ljava/lang/NoSuchFieldException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static hex([B)Ljava/lang/String;
    .locals 6

    .line 719
    new-instance v0, Ljava/lang/StringBuilder;

    array-length v1, p0

    mul-int/lit8 v1, v1, 0x2

    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(I)V

    .line 720
    array-length v1, p0

    const/4 v2, 0x0

    :goto_0
    if-ge v2, v1, :cond_0

    aget-byte v3, p0, v2

    shr-int/lit8 v4, v3, 0x4

    and-int/lit8 v4, v4, 0xf

    const/16 v5, 0x10

    invoke-static {v4, v5}, Ljava/lang/Character;->forDigit(II)C

    move-result v4

    invoke-virtual {v0, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    move-result-object v4

    and-int/lit8 v3, v3, 0xf

    invoke-static {v3, v5}, Ljava/lang/Character;->forDigit(II)C

    move-result v3

    invoke-virtual {v4, v3}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    add-int/lit8 v2, v2, 0x1

    goto :goto_0

    .line 721
    :cond_0
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method private static inspect(Ljava/io/File;)Lio/github/leexeo/cage/space/ClaudeBundle$Apk;
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 190
    new-instance v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;

    const/4 v1, 0x0

    invoke-direct {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;-><init>(Lio/github/leexeo/cage/space/ClaudeBundle$1;)V

    .line 191
    iput-object p0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->file:Ljava/io/File;

    .line 192
    invoke-virtual {p0}, Ljava/io/File;->length()J

    move-result-wide v1

    iput-wide v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->size:J

    .line 193
    iget-wide v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->size:J

    const-wide/16 v3, 0x0

    cmp-long v1, v1, v3

    if-lez v1, :cond_1

    iget-wide v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->size:J

    const-wide/32 v5, 0xa000000

    cmp-long v1, v1, v5

    if-gtz v1, :cond_1

    .line 194
    invoke-static {p0, v5, v6}, Lio/github/leexeo/cage/space/ClaudeBundle;->sha(Ljava/io/File;J)Ljava/lang/String;

    move-result-object v1

    iput-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->sha256:Ljava/lang/String;

    .line 195
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->verifiedSigner(Ljava/io/File;)Ljava/lang/String;

    move-result-object v1

    iput-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->signer:Ljava/lang/String;

    .line 196
    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->readManifest(Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeBundle$Apk;)V

    .line 197
    const-string p0, "com.anthropic.claude"

    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->pkg:Ljava/lang/String;

    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    iget-wide v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->version:J

    cmp-long p0, v1, v3

    if-lez p0, :cond_0

    iget p0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->minSdk:I

    sget v1, Landroid/os/Build$VERSION;->SDK_INT:I

    if-gt p0, v1, :cond_0

    .line 199
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->inspectContents(Lio/github/leexeo/cage/space/ClaudeBundle$Apk;)Ljava/util/List;

    move-result-object p0

    iput-object p0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->nativeFiles:Ljava/util/List;

    .line 200
    return-object v0

    .line 198
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u8bf7\u9009\u62e9\u9002\u5408\u6b64\u624b\u673a\u7684\u539f\u7248 Claude \u5b89\u88c5\u5305\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 193
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u65e0\u6548 APK \u5927\u5c0f\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static inspectContents(Lio/github/leexeo/cage/space/ClaudeBundle$Apk;)Ljava/util/List;
    .locals 22
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Lio/github/leexeo/cage/space/ClaudeBundle$Apk;",
            ")",
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;",
            ">;"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 311
    move-object/from16 v0, p0

    new-instance v1, Ljava/util/ArrayList;

    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V

    .line 312
    new-instance v2, Ljava/util/HashSet;

    invoke-direct {v2}, Ljava/util/HashSet;-><init>()V

    .line 313
    nop

    .line 314
    nop

    .line 315
    nop

    .line 316
    new-instance v3, Ljava/util/zip/ZipFile;

    iget-object v4, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->file:Ljava/io/File;

    invoke-direct {v3, v4}, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File;)V

    .line 317
    :try_start_0
    invoke-virtual {v3}, Ljava/util/zip/ZipFile;->entries()Ljava/util/Enumeration;

    move-result-object v4

    const-wide/16 v5, 0x0

    const/4 v7, 0x0

    move-wide v9, v5

    move v8, v7

    .line 318
    :goto_0
    invoke-interface {v4}, Ljava/util/Enumeration;->hasMoreElements()Z

    move-result v11

    if-eqz v11, :cond_b

    .line 319
    invoke-interface {v4}, Ljava/util/Enumeration;->nextElement()Ljava/lang/Object;

    move-result-object v11

    check-cast v11, Ljava/util/zip/ZipEntry;

    .line 320
    invoke-virtual {v11}, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;

    move-result-object v12

    .line 321
    const/4 v13, 0x1

    add-int/2addr v8, v13

    const/16 v14, 0x7530

    if-gt v8, v14, :cond_a

    invoke-static {v12}, Lio/github/leexeo/cage/space/ClaudeBundle;->safeZipPath(Ljava/lang/String;)Z

    move-result v14

    if-eqz v14, :cond_a

    invoke-interface {v2, v12}, Ljava/util/Set;->add(Ljava/lang/Object;)Z

    move-result v14

    if-eqz v14, :cond_a

    .line 322
    invoke-virtual {v11}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v14

    cmp-long v14, v14, v5

    if-ltz v14, :cond_a

    invoke-virtual {v11}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v14

    const-wide/32 v16, 0x20000000

    cmp-long v14, v14, v16

    if-gtz v14, :cond_a

    .line 324
    invoke-virtual {v11}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v14

    add-long/2addr v9, v14

    .line 325
    cmp-long v14, v9, v16

    if-gtz v14, :cond_9

    .line 326
    invoke-virtual {v11}, Ljava/util/zip/ZipEntry;->isDirectory()Z

    move-result v14

    if-eqz v14, :cond_0

    goto :goto_0

    .line 327
    :cond_0
    const-string v14, ".dex"

    invoke-virtual {v12, v14}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v14

    if-eqz v14, :cond_1

    move v7, v13

    .line 328
    :cond_1
    const-string v14, "lib/"

    invoke-virtual {v12, v14}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v14

    if-nez v14, :cond_2

    move-wide/from16 v16, v5

    goto/16 :goto_2

    .line 329
    :cond_2
    const-string v14, "/"

    const/4 v15, -0x1

    invoke-virtual {v12, v14, v15}, Ljava/lang/String;->split(Ljava/lang/String;I)[Ljava/lang/String;

    move-result-object v14

    .line 330
    const-string v15, "config.armeabi_v7a"

    move-wide/from16 v16, v5

    iget-object v5, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v15, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    .line 331
    array-length v6, v14

    const/4 v15, 0x3

    if-ne v6, v15, :cond_8

    if-eqz v5, :cond_3

    const-string v6, "armeabi-v7a"

    goto :goto_1

    :cond_3
    const-string v6, "arm64-v8a"

    :goto_1
    aget-object v13, v14, v13

    invoke-virtual {v6, v13}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_8

    const/4 v6, 0x2

    aget-object v13, v14, v6

    .line 332
    invoke-static {v13}, Lio/github/leexeo/cage/space/ClaudeBundle;->libraryName(Ljava/lang/String;)Z

    move-result v13

    if-eqz v13, :cond_8

    invoke-virtual {v11}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v18

    cmp-long v13, v18, v16

    if-lez v13, :cond_8

    invoke-virtual {v11}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v18

    const-wide/32 v20, 0x4000000

    cmp-long v13, v18, v20

    if-gtz v13, :cond_8

    if-nez v5, :cond_4

    const-string v13, "config.arm64_v8a"

    iget-object v15, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    .line 333
    invoke-virtual {v13, v15}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v13

    if-eqz v13, :cond_8

    .line 335
    :cond_4
    invoke-interface {v1}, Ljava/util/List;->size()I

    move-result v13

    const/16 v15, 0x80

    if-ge v13, v15, :cond_7

    .line 336
    new-instance v13, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;

    const/4 v15, 0x0

    invoke-direct {v13, v15}, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;-><init>(Lio/github/leexeo/cage/space/ClaudeBundle$1;)V

    .line 337
    aget-object v6, v14, v6

    iput-object v6, v13, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->name:Ljava/lang/String;

    .line 338
    iput-object v12, v13, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->entry:Ljava/lang/String;

    .line 339
    iget-object v6, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->file:Ljava/io/File;

    iput-object v6, v13, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->owner:Ljava/io/File;

    .line 340
    invoke-virtual {v11}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v14

    iput-wide v14, v13, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->size:J

    .line 341
    invoke-virtual {v3, v11}, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;

    move-result-object v6
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    .line 342
    :try_start_1
    iget-wide v11, v13, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->size:J

    invoke-static {v6, v11, v12, v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->digestNative(Ljava/io/InputStream;JZ)Ljava/lang/String;

    move-result-object v5

    iput-object v5, v13, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->sha256:Ljava/lang/String;
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 343
    if-eqz v6, :cond_5

    :try_start_2
    invoke-virtual {v6}, Ljava/io/InputStream;->close()V

    .line 344
    :cond_5
    invoke-interface {v1, v13}, Ljava/util/List;->add(Ljava/lang/Object;)Z
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_2

    .line 345
    nop

    .line 318
    :goto_2
    move-wide/from16 v5, v16

    goto/16 :goto_0

    .line 341
    :catchall_0
    move-exception v0

    move-object v1, v0

    if-eqz v6, :cond_6

    :try_start_3
    invoke-virtual {v6}, Ljava/io/InputStream;->close()V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    goto :goto_3

    :catchall_1
    move-exception v0

    :try_start_4
    invoke-virtual {v1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_6
    :goto_3
    throw v1

    .line 335
    :cond_7
    new-instance v0, Ljava/io/IOException;

    const-string v1, "APK \u539f\u751f\u5e93\u6570\u91cf\u8fc7\u591a\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 334
    :cond_8
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u5b89\u88c5\u5305\u5305\u542b\u4e0d\u652f\u6301\u7684\u539f\u751f\u5e93\u4f4d\u7f6e\u6216\u67b6\u6784\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 325
    :cond_9
    new-instance v0, Ljava/io/IOException;

    const-string v1, "APK \u5c55\u5f00\u540e\u8fc7\u5927\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 323
    :cond_a
    new-instance v0, Ljava/io/IOException;

    const-string v1, "APK \u6587\u4ef6\u7ed3\u6784\u4e0d\u5b89\u5168\u6216\u8d85\u51fa\u9650\u5236\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_2

    .line 346
    :cond_b
    invoke-virtual {v3}, Ljava/util/zip/ZipFile;->close()V

    .line 347
    iget-object v2, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v2}, Ljava/lang/String;->isEmpty()Z

    move-result v2

    if-nez v2, :cond_d

    if-nez v7, :cond_c

    goto :goto_4

    :cond_c
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u914d\u7f6e\u5206\u62c6\u4e2d\u5305\u542b DEX \u4ee3\u7801\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 348
    :cond_d
    :goto_4
    iget-object v2, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v2}, Ljava/lang/String;->isEmpty()Z

    move-result v2

    if-eqz v2, :cond_f

    if-eqz v7, :cond_e

    iget-boolean v0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->hasCode:Z

    if-eqz v0, :cond_e

    goto :goto_5

    :cond_e
    new-instance v0, Ljava/io/IOException;

    const-string v1, "Claude \u57fa\u7840 APK \u7f3a\u5c11\u5e94\u7528\u4ee3\u7801\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 349
    :cond_f
    :goto_5
    return-object v1

    .line 316
    :catchall_2
    move-exception v0

    move-object v1, v0

    :try_start_5
    invoke-virtual {v3}, Ljava/util/zip/ZipFile;->close()V
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_3

    goto :goto_6

    :catchall_3
    move-exception v0

    invoke-virtual {v1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_6
    throw v1
.end method

.method public static declared-synchronized install(Landroid/content/Context;Ljava/io/File;)Ljava/lang/String;
    .locals 20
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    move-object/from16 v0, p0

    move-object/from16 v1, p1

    const-class v2, Lio/github/leexeo/cage/space/ClaudeBundle;

    monitor-enter v2

    .line 63
    const/4 v3, 0x1

    :try_start_0
    invoke-static {v0, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object v4

    .line 64
    invoke-static {}, Lio/github/leexeo/cage/space/ClaudeBundle;->requireArm64()V

    .line 65
    const-string v5, "install.lock"

    invoke-static {v4, v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v5

    .line 66
    new-instance v6, Ljava/io/FileOutputStream;

    invoke-direct {v6, v5, v3}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;Z)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_9

    .line 67
    :try_start_1
    invoke-virtual {v6}, Ljava/io/FileOutputStream;->getChannel()Ljava/nio/channels/FileChannel;

    move-result-object v5

    invoke-virtual {v5}, Ljava/nio/channels/FileChannel;->tryLock()Ljava/nio/channels/FileLock;

    move-result-object v5
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_7

    .line 68
    if-eqz v5, :cond_1f

    .line 69
    :try_start_2
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->recoverIfNeeded(Landroid/content/Context;)Ljava/lang/String;

    move-result-object v7
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_4

    .line 70
    if-eqz v7, :cond_1

    .line 143
    if-eqz v5, :cond_0

    :try_start_3
    invoke-virtual {v5}, Ljava/nio/channels/FileLock;->close()V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_7

    :cond_0
    :try_start_4
    invoke-virtual {v6}, Ljava/io/FileOutputStream;->close()V
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_9

    .line 70
    monitor-exit v2

    return-object v7

    .line 71
    :cond_1
    if-eqz v1, :cond_1e

    :try_start_5
    invoke-virtual {v1}, Ljava/io/File;->isFile()Z

    move-result v7

    if-eqz v7, :cond_1e

    invoke-virtual {v1}, Ljava/io/File;->length()J

    move-result-wide v7

    const-wide/16 v9, 0x0

    cmp-long v7, v7, v9

    if-lez v7, :cond_1e

    invoke-virtual {v1}, Ljava/io/File;->length()J

    move-result-wide v7

    const-wide/32 v9, 0x10000000

    cmp-long v7, v7, v9

    if-gtz v7, :cond_1e

    .line 73
    new-instance v7, Ljava/lang/StringBuilder;

    invoke-direct {v7}, Ljava/lang/StringBuilder;-><init>()V

    const-string v8, ".staging-"

    invoke-virtual {v7, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v7

    invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;

    move-result-object v8

    invoke-virtual {v7, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v7

    invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v7

    invoke-static {v4, v7}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v7

    .line 74
    invoke-virtual {v7}, Ljava/io/File;->mkdir()Z

    move-result v8
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_4

    if-eqz v8, :cond_1d

    .line 76
    :try_start_6
    const-string v8, "input"

    invoke-static {v7, v8}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v8

    .line 77
    invoke-virtual {v8}, Ljava/io/File;->mkdir()Z

    move-result v9

    if-eqz v9, :cond_1c

    .line 78
    invoke-static {v1, v8}, Lio/github/leexeo/cage/space/ClaudeBundle;->unpack(Ljava/io/File;Ljava/io/File;)Ljava/util/List;

    move-result-object v1

    invoke-static {v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->select(Ljava/util/List;)Lio/github/leexeo/cage/space/ClaudeBundle$Selection;

    move-result-object v1

    .line 79
    new-instance v8, Lio/github/leexeo/cage/space/SpacePackages;

    invoke-direct {v8, v0}, Lio/github/leexeo/cage/space/SpacePackages;-><init>(Landroid/content/Context;)V

    .line 80
    const-string v9, "com.anthropic.claude"

    invoke-virtual {v8, v9}, Lio/github/leexeo/cage/space/SpacePackages;->installed(Ljava/lang/String;)Landroid/content/pm/PackageInfo;

    move-result-object v9

    .line 81
    invoke-static {v4}, Lio/github/leexeo/cage/space/ClaudeBundle;->active(Ljava/io/File;)Landroid/util/AtomicFile;

    move-result-object v10

    .line 82
    nop

    .line 83
    invoke-virtual {v10}, Landroid/util/AtomicFile;->getBaseFile()Ljava/io/File;

    move-result-object v11

    invoke-virtual {v11}, Ljava/io/File;->exists()Z

    move-result v11

    if-nez v11, :cond_3

    new-instance v11, Ljava/io/File;

    new-instance v13, Ljava/lang/StringBuilder;

    invoke-direct {v13}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v10}, Landroid/util/AtomicFile;->getBaseFile()Ljava/io/File;

    move-result-object v14

    invoke-virtual {v13, v14}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v13

    const-string v14, ".bak"

    invoke-virtual {v13, v14}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v13

    invoke-virtual {v13}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v13

    invoke-direct {v11, v13}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v11}, Ljava/io/File;->exists()Z

    move-result v11

    if-eqz v11, :cond_2

    goto :goto_0

    :cond_2
    const/4 v11, 0x0

    goto :goto_1

    .line 84
    :cond_3
    :goto_0
    invoke-static {v0, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->readState(Landroid/content/Context;Z)Lio/github/leexeo/cage/space/ClaudeBundle$State;

    move-result-object v11

    .line 85
    if-eqz v9, :cond_1b

    invoke-virtual {v8, v9}, Lio/github/leexeo/cage/space/SpacePackages;->privateCopy(Landroid/content/pm/PackageInfo;)Z

    move-result v13

    if-eqz v13, :cond_1b

    .line 86
    invoke-static {v9}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v13

    move-wide v15, v13

    iget-wide v12, v11, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    cmp-long v12, v15, v12

    if-nez v12, :cond_1a

    .line 88
    invoke-static {v11, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->same(Lio/github/leexeo/cage/space/ClaudeBundle$State;Lio/github/leexeo/cage/space/ClaudeBundle$Selection;)Z

    move-result v12

    if-eqz v12, :cond_5

    .line 89
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "Claude "

    invoke-virtual {v0, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget-object v1, v1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->versionName:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, " \u5df2\u5b8c\u6574\u5b89\u88c5\u5728\u7a7a\u95f4\u5185\u3002"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_3

    .line 141
    :try_start_7
    invoke-static {v7, v7}, Lio/github/leexeo/cage/space/ClaudeBundle;->removeOwned(Ljava/io/File;Ljava/io/File;)V
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_0

    .line 143
    if-eqz v5, :cond_4

    :try_start_8
    invoke-virtual {v5}, Ljava/nio/channels/FileLock;->close()V
    :try_end_8
    .catchall {:try_start_8 .. :try_end_8} :catchall_7

    :cond_4
    :try_start_9
    invoke-virtual {v6}, Ljava/io/FileOutputStream;->close()V
    :try_end_9
    .catchall {:try_start_9 .. :try_end_9} :catchall_9

    .line 89
    monitor-exit v2

    return-object v0

    .line 66
    :catchall_0
    move-exception v0

    move-object v1, v0

    move-object v3, v5

    goto/16 :goto_b

    .line 90
    :cond_5
    :try_start_a
    iget-wide v12, v1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->version:J

    iget-wide v14, v11, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    cmp-long v12, v12, v14

    if-lez v12, :cond_19

    iget-object v12, v11, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    iget-object v13, v1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->signer:Ljava/lang/String;

    invoke-virtual {v12, v13}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v12

    if-eqz v12, :cond_19

    .line 93
    :goto_1
    const/4 v12, 0x0

    if-nez v11, :cond_f

    if-nez v9, :cond_7

    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v13

    invoke-virtual {v13}, Ljava/io/File;->getParentFile()Ljava/io/File;

    move-result-object v13

    invoke-virtual {v13}, Ljava/io/File;->exists()Z

    move-result v13

    if-nez v13, :cond_7

    new-instance v13, Ljava/io/File;

    .line 94
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->data(Landroid/content/Context;)Ljava/io/File;

    move-result-object v14

    const-string v15, "blackbox/data/user/0/com.anthropic.claude"

    invoke-direct {v13, v14, v15}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-virtual {v13}, Ljava/io/File;->exists()Z

    move-result v13

    if-nez v13, :cond_7

    new-instance v13, Ljava/io/File;

    .line 95
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->data(Landroid/content/Context;)Ljava/io/File;

    move-result-object v14

    const-string v15, "blackbox/data/user_de/0/com.anthropic.claude"

    invoke-direct {v13, v14, v15}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-virtual {v13}, Ljava/io/File;->exists()Z

    move-result v13

    if-eqz v13, :cond_6

    goto :goto_2

    :cond_6
    move-object v3, v5

    move/from16 v17, v12

    goto/16 :goto_6

    .line 96
    :cond_7
    :goto_2
    iget-object v13, v1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->apks:Ljava/util/List;

    invoke-interface {v13, v12}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v13

    check-cast v13, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;

    .line 97
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v14

    .line 98
    new-instance v15, Ljava/lang/StringBuilder;

    invoke-direct {v15}, Ljava/lang/StringBuilder;-><init>()V

    move-object/from16 v17, v4

    iget-wide v3, v1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->version:J

    invoke-virtual {v15, v3, v4}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;

    move-result-object v3

    const-string v4, "-"

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    iget-object v4, v13, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->sha256:Ljava/lang/String;

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    move-object/from16 v4, v17

    invoke-static {v4, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v3

    .line 99
    if-nez v9, :cond_9

    invoke-virtual {v14}, Ljava/io/File;->exists()Z

    move-result v15

    if-nez v15, :cond_9

    .line 100
    invoke-virtual {v14}, Ljava/io/File;->getParentFile()Ljava/io/File;

    move-result-object v15

    move/from16 v17, v12

    filled-new-array/range {v17 .. v17}, [I

    move-result-object v12

    invoke-static {v15, v12}, Lio/github/leexeo/cage/space/ClaudeBundle;->emptyTree(Ljava/io/File;[I)Z

    move-result v12

    if-eqz v12, :cond_8

    new-instance v12, Ljava/io/File;

    .line 101
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->data(Landroid/content/Context;)Ljava/io/File;

    move-result-object v15

    move-object/from16 v18, v3

    const-string v3, "blackbox/data/user/0/com.anthropic.claude"

    invoke-direct {v12, v15, v3}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    filled-new-array/range {v17 .. v17}, [I

    move-result-object v3

    invoke-static {v12, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->emptyTree(Ljava/io/File;[I)Z

    move-result v3

    if-eqz v3, :cond_a

    new-instance v3, Ljava/io/File;

    .line 102
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->data(Landroid/content/Context;)Ljava/io/File;

    move-result-object v12

    const-string v15, "blackbox/data/user_de/0/com.anthropic.claude"

    invoke-direct {v3, v12, v15}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    filled-new-array/range {v17 .. v17}, [I

    move-result-object v12

    invoke-static {v3, v12}, Lio/github/leexeo/cage/space/ClaudeBundle;->emptyTree(Ljava/io/File;[I)Z

    move-result v3

    if-eqz v3, :cond_a

    const/4 v3, 0x1

    goto :goto_4

    .line 100
    :cond_8
    move-object/from16 v18, v3

    goto :goto_3

    .line 99
    :cond_9
    move-object/from16 v18, v3

    move/from16 v17, v12

    .line 102
    :cond_a
    :goto_3
    move/from16 v3, v17

    .line 105
    :goto_4
    invoke-virtual/range {v18 .. v18}, Ljava/io/File;->isDirectory()Z

    move-result v12

    if-eqz v12, :cond_d

    if-nez v3, :cond_c

    invoke-virtual {v14}, Ljava/io/File;->isFile()Z

    move-result v3

    if-eqz v3, :cond_d

    .line 106
    invoke-virtual {v14}, Ljava/io/File;->length()J

    move-result-wide v18
    :try_end_a
    .catchall {:try_start_a .. :try_end_a} :catchall_3

    move-object v3, v5

    move-object v12, v6

    :try_start_b
    iget-wide v5, v13, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->size:J

    cmp-long v5, v18, v5

    if-nez v5, :cond_b

    iget-object v5, v13, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->sha256:Ljava/lang/String;
    :try_end_b
    .catchall {:try_start_b .. :try_end_b} :catchall_1

    .line 107
    move-object v6, v12

    const-wide/32 v12, 0xa000000

    :try_start_c
    invoke-static {v14, v12, v13}, Lio/github/leexeo/cage/space/ClaudeBundle;->sha(Ljava/io/File;J)Ljava/lang/String;

    move-result-object v12

    invoke-virtual {v5, v12}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_e

    if-eqz v9, :cond_10

    .line 108
    invoke-static {v9}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v12

    iget-wide v14, v1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->version:J

    cmp-long v5, v12, v14

    if-nez v5, :cond_e

    goto :goto_6

    .line 106
    :cond_b
    move-object v6, v12

    goto :goto_5

    .line 141
    :catchall_1
    move-exception v0

    move-object v6, v12

    goto/16 :goto_9

    .line 105
    :cond_c
    move-object v3, v5

    goto :goto_6

    :cond_d
    move-object v3, v5

    .line 109
    :cond_e
    :goto_5
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u68c0\u6d4b\u5230\u4e0d\u540c\u6216\u65e0\u6cd5\u6838\u5b9e\u7684 Claude \u5b89\u88c5\uff0c\u5df2\u505c\u6b62\u8986\u76d6\u5e76\u4fdd\u7559\u6570\u636e\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 93
    :cond_f
    move-object v3, v5

    move/from16 v17, v12

    .line 112
    :cond_10
    :goto_6
    const-string v5, "payload"

    invoke-static {v7, v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v5

    .line 113
    invoke-virtual {v5}, Ljava/io/File;->mkdir()Z

    move-result v12

    if-eqz v12, :cond_18

    .line 114
    invoke-static {v1, v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->materialize(Lio/github/leexeo/cage/space/ClaudeBundle$Selection;Ljava/io/File;)Lio/github/leexeo/cage/space/ClaudeBundle$State;

    move-result-object v12

    .line 115
    iget-object v13, v12, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directory:Ljava/lang/String;

    invoke-static {v4, v13}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v4

    .line 116
    invoke-virtual {v4}, Ljava/io/File;->exists()Z

    move-result v13

    if-eqz v13, :cond_11

    .line 118
    iput-object v4, v12, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directoryFile:Ljava/io/File;

    .line 119
    const/4 v5, 0x0

    const/4 v13, 0x1

    invoke-static {v12, v13, v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    goto :goto_7

    .line 121
    :cond_11
    invoke-virtual {v5, v4}, Ljava/io/File;->renameTo(Ljava/io/File;)Z

    move-result v5

    if-eqz v5, :cond_17

    .line 122
    iput-object v4, v12, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directoryFile:Ljava/io/File;

    .line 125
    :goto_7
    if-eqz v11, :cond_13

    iget-object v1, v9, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget v1, v1, Landroid/content/pm/ApplicationInfo;->uid:I

    invoke-static {v0, v11, v12, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->install(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;Lio/github/leexeo/cage/space/ClaudeBundle$State;I)Ljava/lang/String;

    move-result-object v0
    :try_end_c
    .catchall {:try_start_c .. :try_end_c} :catchall_2

    .line 141
    :try_start_d
    invoke-static {v7, v7}, Lio/github/leexeo/cage/space/ClaudeBundle;->removeOwned(Ljava/io/File;Ljava/io/File;)V
    :try_end_d
    .catchall {:try_start_d .. :try_end_d} :catchall_5

    .line 143
    if-eqz v3, :cond_12

    :try_start_e
    invoke-virtual {v3}, Ljava/nio/channels/FileLock;->close()V
    :try_end_e
    .catchall {:try_start_e .. :try_end_e} :catchall_7

    :cond_12
    :try_start_f
    invoke-virtual {v6}, Ljava/io/FileOutputStream;->close()V
    :try_end_f
    .catchall {:try_start_f .. :try_end_f} :catchall_9

    .line 125
    monitor-exit v2

    return-object v0

    .line 127
    :cond_13
    :try_start_10
    const-string v5, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v5}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v5

    const-string v9, "get"

    move/from16 v11, v17

    new-array v13, v11, [Ljava/lang/Class;

    invoke-virtual {v5, v9, v13}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v5

    new-array v9, v11, [Ljava/lang/Object;

    const/4 v11, 0x0

    invoke-virtual {v5, v11, v9}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v5

    .line 128
    invoke-virtual {v5}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v9

    const-string v11, "installPackageAsUser"

    const-class v13, Landroid/net/Uri;

    sget-object v14, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v13, v14}, [Ljava/lang/Class;

    move-result-object v13

    invoke-virtual {v9, v11, v13}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v9

    const-string v11, "base.apk"

    .line 129
    invoke-static {v4, v11}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v4

    invoke-static {v4}, Landroid/net/Uri;->fromFile(Ljava/io/File;)Landroid/net/Uri;

    move-result-object v4

    const/16 v17, 0x0

    invoke-static/range {v17 .. v17}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v11

    filled-new-array {v4, v11}, [Ljava/lang/Object;

    move-result-object v4

    invoke-virtual {v9, v5, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v4

    .line 130
    if-eqz v4, :cond_16

    invoke-virtual {v4}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v5

    const-string v9, "success"

    invoke-virtual {v5, v9}, Ljava/lang/Class;->getField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v5

    invoke-virtual {v5, v4}, Ljava/lang/reflect/Field;->getBoolean(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_16

    .line 132
    const-string v4, "com.anthropic.claude"

    invoke-virtual {v8, v4}, Lio/github/leexeo/cage/space/SpacePackages;->installed(Ljava/lang/String;)Landroid/content/pm/PackageInfo;

    move-result-object v4

    .line 133
    if-eqz v4, :cond_15

    const-string v5, "com.anthropic.claude"

    iget-object v8, v4, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v5, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_15

    .line 134
    invoke-static {v4}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v4

    iget-wide v8, v12, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    cmp-long v4, v4, v8

    if-nez v4, :cond_15

    .line 136
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v0

    const/4 v13, 0x1

    invoke-static {v12, v13, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 137
    invoke-static {v10, v12}, Lio/github/leexeo/cage/space/ClaudeBundle;->publish(Landroid/util/AtomicFile;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V

    .line 138
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "Claude "

    invoke-virtual {v0, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget-object v1, v1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->versionName:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, " \u5df2\u5b89\u88c5\u5728\u7a7a\u95f4\u5185\uff08\u4fdd\u7559\u539f\u7248\u7b7e\u540d\uff09\u3002"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0
    :try_end_10
    .catchall {:try_start_10 .. :try_end_10} :catchall_2

    .line 141
    :try_start_11
    invoke-static {v7, v7}, Lio/github/leexeo/cage/space/ClaudeBundle;->removeOwned(Ljava/io/File;Ljava/io/File;)V
    :try_end_11
    .catchall {:try_start_11 .. :try_end_11} :catchall_5

    .line 143
    if-eqz v3, :cond_14

    :try_start_12
    invoke-virtual {v3}, Ljava/nio/channels/FileLock;->close()V
    :try_end_12
    .catchall {:try_start_12 .. :try_end_12} :catchall_7

    :cond_14
    :try_start_13
    invoke-virtual {v6}, Ljava/io/FileOutputStream;->close()V
    :try_end_13
    .catchall {:try_start_13 .. :try_end_13} :catchall_9

    .line 138
    monitor-exit v2

    return-object v0

    .line 135
    :cond_15
    :try_start_14
    new-instance v0, Ljava/io/IOException;

    const-string v1, "Claude \u79c1\u6709\u5b89\u88c5\u8bb0\u5f55\u672a\u5b8c\u6210\uff1b\u5df2\u4fdd\u7559\u6570\u636e\uff0c\u672a\u5f00\u653e\u542f\u52a8\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 131
    :cond_16
    new-instance v0, Ljava/io/IOException;

    const-string v1, "Claude \u79c1\u6709\u5b89\u88c5\u672a\u5b8c\u6210\uff1b\u5df2\u4fdd\u7559\u6587\u4ef6\u548c\u6570\u636e\uff0c\u672a\u5f00\u653e\u542f\u52a8\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 121
    :cond_17
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u65e0\u6cd5\u63d0\u4ea4\u5df2\u6821\u9a8c\u7684 Claude \u6587\u4ef6\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 113
    :cond_18
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u65e0\u6cd5\u521b\u5efa\u5b89\u88c5\u5305\u76ee\u5f55\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 90
    :cond_19
    move-object v3, v5

    .line 91
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u5347\u7ea7\u5fc5\u987b\u4f7f\u7528\u66f4\u9ad8\u7248\u672c\u4e14\u5f53\u524d\u5b98\u65b9\u7b7e\u540d\u5b8c\u5168\u76f8\u540c\u7684 Claude \u5b8c\u6574\u5206\u5305\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 86
    :cond_1a
    move-object v3, v5

    goto :goto_8

    .line 85
    :cond_1b
    move-object v3, v5

    .line 87
    :goto_8
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u73b0\u6709 Claude \u5b89\u88c5\u8bb0\u5f55\u4e0d\u5b8c\u6574\uff0c\u5df2\u505c\u6b62\u5347\u7ea7\u5e76\u4fdd\u7559\u6570\u636e\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 77
    :cond_1c
    move-object v3, v5

    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u65e0\u6cd5\u521b\u5efa\u6821\u9a8c\u76ee\u5f55\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0
    :try_end_14
    .catchall {:try_start_14 .. :try_end_14} :catchall_2

    .line 141
    :catchall_2
    move-exception v0

    goto :goto_9

    :catchall_3
    move-exception v0

    move-object v3, v5

    :goto_9
    :try_start_15
    invoke-static {v7, v7}, Lio/github/leexeo/cage/space/ClaudeBundle;->removeOwned(Ljava/io/File;Ljava/io/File;)V

    .line 142
    throw v0

    .line 74
    :cond_1d
    move-object v3, v5

    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u65e0\u6cd5\u521b\u5efa\u72ec\u7acb\u5bfc\u5165\u76ee\u5f55\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 71
    :cond_1e
    move-object v3, v5

    .line 72
    new-instance v0, Ljava/io/IOException;

    const-string v1, "Claude \u5b89\u88c5\u5305\u4e3a\u7a7a\u6216\u8d85\u8fc7 256 MB\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 66
    :catchall_4
    move-exception v0

    move-object v3, v5

    :goto_a
    move-object v1, v0

    goto :goto_b

    .line 68
    :cond_1f
    move-object v3, v5

    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u53e6\u4e00\u6b21 Claude \u5bfc\u5165\u4ecd\u5728\u8fdb\u884c\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0
    :try_end_15
    .catchall {:try_start_15 .. :try_end_15} :catchall_5

    .line 66
    :catchall_5
    move-exception v0

    goto :goto_a

    :goto_b
    if-eqz v3, :cond_20

    :try_start_16
    invoke-virtual {v3}, Ljava/nio/channels/FileLock;->close()V
    :try_end_16
    .catchall {:try_start_16 .. :try_end_16} :catchall_6

    goto :goto_c

    :catchall_6
    move-exception v0

    :try_start_17
    invoke-virtual {v1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_20
    :goto_c
    throw v1
    :try_end_17
    .catchall {:try_start_17 .. :try_end_17} :catchall_7

    :catchall_7
    move-exception v0

    move-object v1, v0

    :try_start_18
    invoke-virtual {v6}, Ljava/io/FileOutputStream;->close()V
    :try_end_18
    .catchall {:try_start_18 .. :try_end_18} :catchall_8

    goto :goto_d

    :catchall_8
    move-exception v0

    :try_start_19
    invoke-virtual {v1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_d
    throw v1

    .line 62
    :catchall_9
    move-exception v0

    monitor-exit v2
    :try_end_19
    .catchall {:try_start_19 .. :try_end_19} :catchall_9

    throw v0
.end method

.method static synthetic lambda$select$0(Lio/github/leexeo/cage/space/ClaudeBundle$Apk;)Ljava/lang/String;
    .locals 0

    .line 395
    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    return-object p0
.end method

.method static synthetic lambda$select$1(Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;)Ljava/lang/String;
    .locals 0

    .line 401
    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->name:Ljava/lang/String;

    return-object p0
.end method

.method private static libraryName(Ljava/lang/String;)Z
    .locals 1

    .line 643
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->simple(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_0

    const-string v0, "lib"

    invoke-virtual {p0, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_0

    const-string v0, ".so"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_0

    const/4 p0, 0x1

    goto :goto_0

    :cond_0
    const/4 p0, 0x0

    :goto_0
    return p0
.end method

.method private static materialize(Lio/github/leexeo/cage/space/ClaudeBundle$Selection;Ljava/io/File;)Lio/github/leexeo/cage/space/ClaudeBundle$State;
    .locals 11
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 406
    new-instance v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-direct {v0}, Lio/github/leexeo/cage/space/ClaudeBundle$State;-><init>()V

    .line 407
    iget-wide v1, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->version:J

    iput-wide v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    .line 408
    iget-object v1, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->versionName:Ljava/lang/String;

    iput-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->versionName:Ljava/lang/String;

    .line 409
    iget-object v1, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->signer:Ljava/lang/String;

    iput-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    .line 410
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    iget-wide v2, v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    invoke-virtual {v1, v2, v3}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, "-"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    iget-object v2, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->apks:Ljava/util/List;

    const/4 v3, 0x0

    invoke-interface {v2, v3}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;

    iget-object v2, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->sha256:Ljava/lang/String;

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    iput-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directory:Ljava/lang/String;

    .line 411
    iput-object p1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directoryFile:Ljava/io/File;

    .line 412
    iget-object v1, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->apks:Ljava/util/List;

    invoke-interface {v1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v1

    :goto_0
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :cond_1

    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;

    .line 413
    new-instance v3, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    invoke-direct {v3}, Lio/github/leexeo/cage/space/ClaudeBundle$Record;-><init>()V

    .line 414
    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v4}, Ljava/lang/String;->isEmpty()Z

    move-result v4

    if-eqz v4, :cond_0

    const-string v4, "base.apk"

    goto :goto_1

    :cond_0
    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    iget-object v5, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    const-string v5, ".apk"

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v4

    :goto_1
    iput-object v4, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    .line 415
    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    iput-object v4, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->split:Ljava/lang/String;

    .line 416
    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->sha256:Ljava/lang/String;

    iput-object v4, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    .line 417
    iget-wide v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->size:J

    iput-wide v4, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    .line 418
    iget-object v4, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    invoke-static {p1, v4}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v6

    .line 419
    new-instance v5, Ljava/io/FileInputStream;

    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->file:Ljava/io/File;

    invoke-direct {v5, v4}, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V

    .line 420
    :try_start_0
    iget-wide v7, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->size:J

    const-wide/32 v9, 0xa000000

    invoke-static/range {v5 .. v10}, Lio/github/leexeo/cage/space/ClaudeBundle;->copyNew(Ljava/io/InputStream;Ljava/io/File;JJ)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 421
    invoke-virtual {v5}, Ljava/io/InputStream;->close()V

    .line 422
    invoke-static {v6}, Lio/github/leexeo/cage/space/ClaudeBundle;->readOnly(Ljava/io/File;)V

    .line 423
    iget-object v2, v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    invoke-interface {v2, v3}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 424
    goto :goto_0

    .line 419
    :catchall_0
    move-exception v0

    move-object p0, v0

    :try_start_1
    invoke-virtual {v5}, Ljava/io/InputStream;->close()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    goto :goto_2

    :catchall_1
    move-exception v0

    move-object p1, v0

    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_2
    throw p0

    .line 425
    :cond_1
    const-string v1, "lib"

    invoke-static {p1, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 426
    const-string v1, "arm64-v8a"

    invoke-static {p1, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v1

    .line 427
    invoke-virtual {p1}, Ljava/io/File;->mkdir()Z

    move-result p1

    if-eqz p1, :cond_6

    invoke-virtual {v1}, Ljava/io/File;->mkdir()Z

    move-result p1

    if-eqz p1, :cond_6

    .line 428
    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->libraries:Ljava/util/List;

    invoke-interface {p0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object p0

    :goto_3
    invoke-interface {p0}, Ljava/util/Iterator;->hasNext()Z

    move-result p1

    if-eqz p1, :cond_5

    invoke-interface {p0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;

    .line 429
    new-instance v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    invoke-direct {v2}, Lio/github/leexeo/cage/space/ClaudeBundle$Record;-><init>()V

    .line 430
    iget-object v3, p1, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->name:Ljava/lang/String;

    iput-object v3, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    .line 431
    iget-wide v3, p1, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->size:J

    iput-wide v3, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    .line 432
    iget-object v3, p1, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->sha256:Ljava/lang/String;

    iput-object v3, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    .line 433
    iget-object v3, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    invoke-static {v1, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v5

    .line 434
    new-instance v3, Ljava/util/zip/ZipFile;

    iget-object v4, p1, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->owner:Ljava/io/File;

    invoke-direct {v3, v4}, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File;)V

    .line 435
    :try_start_2
    iget-object v4, p1, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->entry:Ljava/lang/String;

    invoke-virtual {v3, v4}, Ljava/util/zip/ZipFile;->getEntry(Ljava/lang/String;)Ljava/util/zip/ZipEntry;

    move-result-object v4

    invoke-virtual {v3, v4}, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;

    move-result-object v4
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_4

    .line 436
    :try_start_3
    iget-wide v6, p1, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->size:J

    const-wide/32 v8, 0x4000000

    invoke-static/range {v4 .. v9}, Lio/github/leexeo/cage/space/ClaudeBundle;->copyNew(Ljava/io/InputStream;Ljava/io/File;JJ)V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_2

    .line 437
    if-eqz v4, :cond_2

    :try_start_4
    invoke-virtual {v4}, Ljava/io/InputStream;->close()V
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_4

    :cond_2
    invoke-virtual {v3}, Ljava/util/zip/ZipFile;->close()V

    .line 438
    iget-object p1, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    const-wide/32 v3, 0x4000000

    invoke-static {v5, v3, v4}, Lio/github/leexeo/cage/space/ClaudeBundle;->sha(Ljava/io/File;J)Ljava/lang/String;

    move-result-object v3

    invoke-virtual {p1, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_3

    .line 439
    invoke-static {v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->readOnly(Ljava/io/File;)V

    .line 440
    iget-object p1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->libraries:Ljava/util/List;

    invoke-interface {p1, v2}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 441
    goto :goto_3

    .line 438
    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u539f\u751f\u5e93\u590d\u5236\u6821\u9a8c\u5931\u8d25\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 434
    :catchall_2
    move-exception v0

    move-object p0, v0

    if-eqz v4, :cond_4

    :try_start_5
    invoke-virtual {v4}, Ljava/io/InputStream;->close()V
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_3

    goto :goto_4

    :catchall_3
    move-exception v0

    move-object p1, v0

    :try_start_6
    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_4
    :goto_4
    throw p0
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_4

    :catchall_4
    move-exception v0

    move-object p0, v0

    :try_start_7
    invoke-virtual {v3}, Ljava/util/zip/ZipFile;->close()V
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_5

    goto :goto_5

    :catchall_5
    move-exception v0

    move-object p1, v0

    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_5
    throw p0

    .line 442
    :cond_5
    const/4 p0, 0x1

    const/4 p1, 0x0

    invoke-static {v0, p0, p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 443
    return-object v0

    .line 427
    :cond_6
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u65e0\u6cd5\u521b\u5efa\u539f\u751f\u5e93\u76ee\u5f55\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static nativeDir(Lio/github/leexeo/cage/space/ClaudeBundle$State;)Ljava/io/File;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 619
    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directoryFile:Ljava/io/File;

    const-string v0, "lib"

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    const-string v0, "arm64-v8a"

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    return-object p0
.end method

.method static parseState(Landroid/content/Context;Lorg/json/JSONObject;)Lio/github/leexeo/cage/space/ClaudeBundle$State;
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 468
    const/4 v0, 0x0

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object p0

    .line 469
    const-string v1, "schema"

    invoke-virtual {p1, v1}, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I

    move-result v1

    const/4 v2, 0x1

    if-ne v1, v2, :cond_2

    const-string v1, "package"

    invoke-virtual {p1, v1}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v1

    const-string v3, "com.anthropic.claude"

    invoke-virtual {v3, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_2

    .line 471
    new-instance v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-direct {v1}, Lio/github/leexeo/cage/space/ClaudeBundle$State;-><init>()V

    .line 472
    const-string v3, "version"

    invoke-virtual {p1, v3}, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J

    move-result-wide v3

    iput-wide v3, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    .line 473
    const-string v3, "versionName"

    invoke-virtual {p1, v3}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    iput-object v3, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->versionName:Ljava/lang/String;

    .line 474
    const-string v3, "signer"

    invoke-virtual {p1, v3}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    iput-object v3, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    .line 475
    const-string v3, "directory"

    invoke-virtual {p1, v3}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    iput-object v3, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directory:Ljava/lang/String;

    .line 476
    iget-wide v3, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    const-wide/16 v5, 0x0

    cmp-long v3, v3, v5

    if-lez v3, :cond_1

    sget-object v3, Lio/github/leexeo/cage/space/ClaudeBundle;->SIGNERS:Ljava/util/Set;

    iget-object v4, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    invoke-interface {v3, v4}, Ljava/util/Set;->contains(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_1

    iget-object v3, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->versionName:Ljava/lang/String;

    invoke-virtual {v3}, Ljava/lang/String;->length()I

    move-result v3

    const/16 v4, 0x80

    if-gt v3, v4, :cond_1

    iget-object v3, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directory:Ljava/lang/String;

    .line 477
    const-string v4, "[0-9]+-[0-9a-f]{64}"

    invoke-virtual {v3, v4}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_1

    .line 479
    iget-object v3, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directory:Ljava/lang/String;

    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    iput-object p0, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directoryFile:Ljava/io/File;

    .line 480
    const-string p0, "apks"

    invoke-virtual {p1, p0}, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;

    move-result-object p0

    iget-object v3, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    invoke-static {p0, v3, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->readRecords(Lorg/json/JSONArray;Ljava/util/List;Z)V

    .line 481
    const-string p0, "libraries"

    invoke-virtual {p1, p0}, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;

    move-result-object p0

    iget-object p1, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->libraries:Ljava/util/List;

    invoke-static {p0, p1, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->readRecords(Lorg/json/JSONArray;Ljava/util/List;Z)V

    .line 482
    iget-object p0, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    invoke-interface {p0}, Ljava/util/List;->size()I

    move-result p0

    const/4 p1, 0x3

    if-lt p0, p1, :cond_0

    iget-object p0, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    invoke-interface {p0, v0}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->split:Ljava/lang/String;

    invoke-virtual {p0}, Ljava/lang/String;->isEmpty()Z

    move-result p0

    if-eqz p0, :cond_0

    iget-object p0, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directory:Ljava/lang/String;

    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    iget-wide v2, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    invoke-virtual {p1, v2, v3}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v2, "-"

    invoke-virtual {p1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    iget-object v2, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    .line 483
    invoke-interface {v2, v0}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    iget-object v0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    .line 485
    return-object v1

    .line 484
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u57fa\u7840\u5305\u5b89\u88c5\u8bb0\u5f55\u7f3a\u5931\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 478
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u5b89\u88c5\u8bb0\u5f55\u4e0d\u7b26\u5408\u9884\u671f\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 470
    :cond_2
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u5b89\u88c5\u8bb0\u5f55\u65e0\u6548\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static privateBase(Landroid/content/Context;)Ljava/io/File;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 615
    new-instance v0, Ljava/io/File;

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->data(Landroid/content/Context;)Ljava/io/File;

    move-result-object p0

    const-string v1, "blackbox/data/app/com.anthropic.claude"

    invoke-direct {v0, p0, v1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    .line 616
    new-instance p0, Ljava/io/File;

    const-string v1, "base.apk"

    invoke-direct {p0, v0, v1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    move-result-object p0

    return-object p0
.end method

.method static publish(Landroid/util/AtomicFile;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 577
    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->encodeState(Lio/github/leexeo/cage/space/ClaudeBundle$State;)Lorg/json/JSONObject;

    move-result-object p1

    .line 578
    nop

    .line 580
    :try_start_0
    invoke-virtual {p0}, Landroid/util/AtomicFile;->startWrite()Ljava/io/FileOutputStream;

    move-result-object v0
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_1

    .line 581
    :try_start_1
    invoke-virtual {p1}, Lorg/json/JSONObject;->toString()Ljava/lang/String;

    move-result-object p1

    sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-virtual {p1, v1}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object p1

    invoke-virtual {v0, p1}, Ljava/io/FileOutputStream;->write([B)V

    .line 582
    invoke-virtual {p0, v0}, Landroid/util/AtomicFile;->finishWrite(Ljava/io/FileOutputStream;)V
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 586
    nop

    .line 587
    return-void

    .line 583
    :catch_0
    move-exception p1

    goto :goto_0

    :catch_1
    move-exception p1

    const/4 v0, 0x0

    .line 584
    :goto_0
    if-eqz v0, :cond_0

    invoke-virtual {p0, v0}, Landroid/util/AtomicFile;->failWrite(Ljava/io/FileOutputStream;)V

    .line 585
    :cond_0
    throw p1
.end method

.method private static readManifest(Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeBundle$Apk;)V
    .locals 19
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 246
    move-object/from16 v0, p1

    const-string v1, "configForSplit"

    const-class v2, Landroid/content/res/AssetManager;

    const/4 v3, 0x0

    new-array v4, v3, [Ljava/lang/Class;

    invoke-virtual {v2, v4}, Ljava/lang/Class;->getDeclaredConstructor([Ljava/lang/Class;)Ljava/lang/reflect/Constructor;

    move-result-object v2

    new-array v4, v3, [Ljava/lang/Object;

    invoke-virtual {v2, v4}, Ljava/lang/reflect/Constructor;->newInstance([Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Landroid/content/res/AssetManager;

    .line 248
    :try_start_0
    const-class v4, Landroid/content/res/AssetManager;

    const-string v5, "addAssetPath"

    const-class v6, Ljava/lang/String;

    filled-new-array {v6}, [Ljava/lang/Class;

    move-result-object v6

    invoke-virtual {v4, v5, v6}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v4

    .line 249
    const/4 v5, 0x1

    invoke-virtual {v4, v5}, Ljava/lang/reflect/Method;->setAccessible(Z)V

    .line 250
    invoke-virtual/range {p0 .. p0}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v6

    filled-new-array {v6}, [Ljava/lang/Object;

    move-result-object v6

    invoke-virtual {v4, v2, v6}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Ljava/lang/Integer;

    invoke-virtual {v4}, Ljava/lang/Integer;->intValue()I

    move-result v4

    .line 251
    if-eqz v4, :cond_15

    .line 252
    const-string v6, "AndroidManifest.xml"

    invoke-virtual {v2, v4, v6}, Landroid/content/res/AssetManager;->openXmlResourceParser(ILjava/lang/String;)Landroid/content/res/XmlResourceParser;

    move-result-object v4
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    .line 253
    nop

    .line 254
    move v6, v3

    move v7, v6

    move v8, v7

    .line 255
    :goto_0
    :try_start_1
    invoke-interface {v4}, Landroid/content/res/XmlResourceParser;->next()I

    move-result v9

    if-eq v9, v5, :cond_10

    .line 256
    const/4 v10, 0x2

    if-eq v9, v10, :cond_0

    goto :goto_0

    .line 257
    :cond_0
    add-int/lit8 v8, v8, 0x1

    const/16 v9, 0x2710

    if-gt v8, v9, :cond_f

    .line 258
    invoke-interface {v4}, Landroid/content/res/XmlResourceParser;->getName()Ljava/lang/String;

    move-result-object v9

    .line 259
    invoke-interface {v4}, Landroid/content/res/XmlResourceParser;->getDepth()I

    move-result v11
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 260
    const-string v12, "http://schemas.android.com/apk/res/android"

    if-ne v11, v5, :cond_5

    .line 261
    if-nez v6, :cond_4

    :try_start_2
    const-string v6, "manifest"

    invoke-virtual {v6, v9}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_4

    .line 262
    nop

    .line 263
    const-string v6, "package"

    const/4 v13, 0x0

    invoke-interface {v4, v13, v6}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v6

    iput-object v6, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->pkg:Ljava/lang/String;

    .line 264
    const-string v6, "split"

    invoke-interface {v4, v13, v6}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v6

    invoke-static {v6}, Lio/github/leexeo/cage/space/ClaudeBundle;->value(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v6

    iput-object v6, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    .line 265
    const-string v6, "sharedUserId"

    invoke-interface {v4, v12, v6}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v6

    invoke-static {v6}, Lio/github/leexeo/cage/space/ClaudeBundle;->value(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v6

    invoke-virtual {v6}, Ljava/lang/String;->isEmpty()Z

    move-result v6

    if-eqz v6, :cond_3

    .line 267
    const-string v6, "versionCode"

    invoke-interface {v4, v12, v6, v3}, Landroid/content/res/XmlResourceParser;->getAttributeIntValue(Ljava/lang/String;Ljava/lang/String;I)I

    move-result v6

    .line 268
    const-string v14, "versionCodeMajor"

    invoke-interface {v4, v12, v14, v3}, Landroid/content/res/XmlResourceParser;->getAttributeIntValue(Ljava/lang/String;Ljava/lang/String;I)I

    move-result v14

    .line 269
    if-ltz v14, :cond_2

    .line 270
    int-to-long v14, v14

    const/16 v16, 0x20

    shl-long v14, v14, v16

    int-to-long v5, v6

    const-wide v17, 0xffffffffL

    and-long v5, v5, v17

    or-long/2addr v5, v14

    iput-wide v5, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->version:J

    .line 271
    const-string v5, "versionName"

    invoke-interface {v4, v12, v5}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    invoke-static {v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->value(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    iput-object v5, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->versionName:Ljava/lang/String;

    .line 272
    const-string v5, "requiredSplitTypes"

    invoke-interface {v4, v12, v5}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    invoke-static {v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->types(Ljava/lang/String;)Ljava/util/Set;

    move-result-object v5

    iput-object v5, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->required:Ljava/util/Set;

    .line 273
    const-string v5, "splitTypes"

    invoke-interface {v4, v12, v5}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    invoke-static {v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->types(Ljava/lang/String;)Ljava/util/Set;

    move-result-object v5

    iput-object v5, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->types:Ljava/util/Set;

    .line 274
    const-string v5, "isFeatureSplit"

    invoke-interface {v4, v12, v5, v3}, Landroid/content/res/XmlResourceParser;->getAttributeBooleanValue(Ljava/lang/String;Ljava/lang/String;Z)Z

    move-result v5

    if-nez v5, :cond_1

    const-string v5, "isolatedSplits"

    .line 275
    invoke-interface {v4, v12, v5, v3}, Landroid/content/res/XmlResourceParser;->getAttributeBooleanValue(Ljava/lang/String;Ljava/lang/String;Z)Z

    move-result v5

    if-nez v5, :cond_1

    .line 276
    invoke-interface {v4, v13, v1}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    invoke-static {v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->value(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/String;->isEmpty()Z

    move-result v5

    if-eqz v5, :cond_1

    .line 277
    invoke-interface {v4, v12, v1}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    invoke-static {v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->value(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/String;->isEmpty()Z

    move-result v5

    if-eqz v5, :cond_1

    const/4 v6, 0x1

    goto :goto_1

    .line 278
    :cond_1
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u6b64 DEMO \u4e0d\u652f\u6301\u529f\u80fd\u5206\u62c6\u6216\u72ec\u7acb\u5206\u62c6\u52a0\u8f7d\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 269
    :cond_2
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u4e0d\u652f\u6301\u6b64 APK \u7248\u672c\u7f16\u7801\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 266
    :cond_3
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u6b64\u5bfc\u5165\u5668\u4e0d\u652f\u6301\u5171\u4eab\u8eab\u4efd\u7684 Claude \u5305\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 261
    :cond_4
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u65e0\u6548 APK \u6e05\u5355\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 280
    :cond_5
    :goto_1
    const-string v5, "uses-split"

    invoke-virtual {v5, v9}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    if-nez v5, :cond_e

    .line 281
    const-string v5, "uses-sdk"

    if-ne v11, v10, :cond_6

    :try_start_3
    invoke-virtual {v5, v9}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v13

    if-eqz v13, :cond_6

    .line 282
    const-string v13, "minSdkVersion"

    const/4 v14, 0x1

    invoke-interface {v4, v12, v13, v14}, Landroid/content/res/XmlResourceParser;->getAttributeIntValue(Ljava/lang/String;Ljava/lang/String;I)I

    move-result v13

    iput v13, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->minSdk:I
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 283
    :cond_6
    const-string v13, "application"

    if-ne v11, v10, :cond_a

    :try_start_4
    invoke-virtual {v13, v9}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v14

    if-eqz v14, :cond_a

    .line 284
    if-nez v7, :cond_9

    .line 285
    nop

    .line 286
    const-string v7, "hasCode"

    const/4 v14, 0x1

    invoke-interface {v4, v12, v7, v14}, Landroid/content/res/XmlResourceParser;->getAttributeBooleanValue(Ljava/lang/String;Ljava/lang/String;Z)Z

    move-result v7

    iput-boolean v7, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->hasCode:Z

    .line 287
    iget-object v7, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v7}, Ljava/lang/String;->isEmpty()Z

    move-result v7

    if-nez v7, :cond_8

    const-string v7, "classLoader"

    invoke-interface {v4, v12, v7}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v7

    if-nez v7, :cond_7

    goto :goto_2

    .line 288
    :cond_7
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u4e0d\u652f\u6301\u5206\u62c6\u81ea\u5b9a\u4e49\u7c7b\u52a0\u8f7d\u5668\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 290
    :cond_8
    :goto_2
    move v7, v14

    goto :goto_3

    .line 284
    :cond_9
    new-instance v0, Ljava/io/IOException;

    const-string v1, "APK \u5305\u542b\u91cd\u590d application \u6e05\u5355\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 283
    :cond_a
    const/4 v14, 0x1

    .line 290
    :goto_3
    iget-object v12, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v12}, Ljava/lang/String;->isEmpty()Z

    move-result v12

    if-nez v12, :cond_d

    if-ne v11, v10, :cond_b

    invoke-virtual {v13, v9}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v10

    if-nez v10, :cond_b

    invoke-virtual {v5, v9}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_c

    :cond_b
    const/4 v5, 0x3

    if-lt v11, v5, :cond_d

    if-ne v11, v5, :cond_c

    const-string v5, "meta-data"

    .line 291
    invoke-virtual {v5, v9}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_c

    goto :goto_4

    .line 292
    :cond_c
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u6b64 DEMO \u53ea\u63a5\u53d7\u8d44\u6e90\u6216\u539f\u751f\u5e93\u914d\u7f6e\u5206\u62c6\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 293
    :cond_d
    :goto_4
    move v5, v14

    goto/16 :goto_0

    .line 280
    :cond_e
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u6b64 DEMO \u4e0d\u652f\u6301\u5206\u62c6\u4f9d\u8d56\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 257
    :cond_f
    new-instance v0, Ljava/io/IOException;

    const-string v1, "APK \u6e05\u5355\u8fc7\u5927\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 294
    :cond_10
    if-eqz v6, :cond_13

    if-eqz v7, :cond_13

    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v1}, Ljava/lang/String;->isEmpty()Z

    move-result v1

    if-nez v1, :cond_11

    iget-boolean v0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->hasCode:Z
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_0

    if-nez v0, :cond_13

    .line 296
    :cond_11
    if-eqz v4, :cond_12

    :try_start_5
    invoke-interface {v4}, Landroid/content/res/XmlResourceParser;->close()V
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_2

    .line 297
    :cond_12
    invoke-virtual {v2}, Landroid/content/res/AssetManager;->close()V

    .line 298
    return-void

    .line 295
    :cond_13
    :try_start_6
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u914d\u7f6e\u5206\u62c6\u7f3a\u5c11\u6709\u6548\u6e05\u5355\uff0c\u6216\u5305\u542b\u53ef\u6267\u884c\u4ee3\u7801\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_0

    .line 252
    :catchall_0
    move-exception v0

    move-object v1, v0

    if-eqz v4, :cond_14

    :try_start_7
    invoke-interface {v4}, Landroid/content/res/XmlResourceParser;->close()V
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_1

    goto :goto_5

    :catchall_1
    move-exception v0

    :try_start_8
    invoke-virtual {v1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_14
    :goto_5
    throw v1

    .line 251
    :cond_15
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u65e0\u6cd5\u8bfb\u53d6 Claude APK \u6e05\u5355\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0
    :try_end_8
    .catchall {:try_start_8 .. :try_end_8} :catchall_2

    .line 297
    :catchall_2
    move-exception v0

    invoke-virtual {v2}, Landroid/content/res/AssetManager;->close()V

    throw v0
.end method

.method private static readOnly(Ljava/io/File;)V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 661
    invoke-virtual {p0}, Ljava/io/File;->setReadOnly()Z

    move-result p0

    if-eqz p0, :cond_0

    .line 662
    return-void

    .line 661
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u65e0\u6cd5\u5c06\u5df2\u6821\u9a8c\u7684\u5b89\u88c5\u6587\u4ef6\u8bbe\u4e3a\u53ea\u8bfb\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static readRecords(Lorg/json/JSONArray;Ljava/util/List;Z)V
    .locals 10
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Lorg/json/JSONArray;",
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeBundle$Record;",
            ">;Z)V"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 489
    invoke-virtual {p0}, Lorg/json/JSONArray;->length()I

    move-result v0

    const/4 v1, 0x1

    if-lt v0, v1, :cond_a

    invoke-virtual {p0}, Lorg/json/JSONArray;->length()I

    move-result v0

    if-eqz p2, :cond_0

    const/16 v1, 0x40

    goto :goto_0

    :cond_0
    const/16 v1, 0x80

    :goto_0
    if-gt v0, v1, :cond_a

    .line 490
    new-instance v0, Ljava/util/HashSet;

    invoke-direct {v0}, Ljava/util/HashSet;-><init>()V

    .line 491
    nop

    .line 492
    const-string v1, ""

    const/4 v2, 0x0

    move-object v3, v1

    :goto_1
    invoke-virtual {p0}, Lorg/json/JSONArray;->length()I

    move-result v4

    if-ge v2, v4, :cond_9

    .line 493
    invoke-virtual {p0, v2}, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;

    move-result-object v4

    .line 494
    new-instance v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    invoke-direct {v5}, Lio/github/leexeo/cage/space/ClaudeBundle$Record;-><init>()V

    .line 495
    const-string v6, "file"

    invoke-virtual {v4, v6}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v6

    iput-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    .line 496
    const-string v6, "size"

    invoke-virtual {v4, v6}, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J

    move-result-wide v6

    iput-wide v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    .line 497
    const-string v6, "sha256"

    invoke-virtual {v4, v6}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v6

    iput-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    .line 498
    if-eqz p2, :cond_1

    const-string v6, "split"

    invoke-virtual {v4, v6}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v4

    goto :goto_2

    :cond_1
    move-object v4, v1

    :goto_2
    iput-object v4, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->split:Ljava/lang/String;

    .line 499
    if-eqz p2, :cond_2

    iget-object v4, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->split:Ljava/lang/String;

    goto :goto_3

    :cond_2
    iget-object v4, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    .line 500
    :goto_3
    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    invoke-static {v6}, Lio/github/leexeo/cage/space/ClaudeBundle;->simple(Ljava/lang/String;)Z

    move-result v6

    if-eqz v6, :cond_8

    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    invoke-interface {v0, v6}, Ljava/util/Set;->add(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_8

    iget-wide v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    const-wide/16 v8, 0x0

    cmp-long v6, v6, v8

    if-lez v6, :cond_8

    iget-wide v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    .line 501
    if-eqz p2, :cond_3

    const-wide/32 v8, 0xa000000

    goto :goto_4

    :cond_3
    const-wide/32 v8, 0x4000000

    :goto_4
    cmp-long v6, v6, v8

    if-gtz v6, :cond_8

    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    const-string v7, "[0-9a-f]{64}"

    invoke-virtual {v6, v7}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v6

    if-eqz v6, :cond_8

    if-lez v2, :cond_4

    .line 502
    invoke-virtual {v3, v4}, Ljava/lang/String;->compareTo(Ljava/lang/String;)I

    move-result v3

    if-gez v3, :cond_8

    :cond_4
    if-eqz p2, :cond_6

    .line 503
    iget-object v3, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->split:Ljava/lang/String;

    invoke-virtual {v3}, Ljava/lang/String;->isEmpty()Z

    move-result v3

    if-eqz v3, :cond_5

    const-string v3, "base.apk"

    goto :goto_5

    :cond_5
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->split:Ljava/lang/String;

    invoke-virtual {v3, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    const-string v6, ".apk"

    invoke-virtual {v3, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    :goto_5
    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    invoke-virtual {v3, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_8

    :cond_6
    if-nez p2, :cond_7

    iget-object v3, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    .line 504
    invoke-static {v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->libraryName(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_8

    .line 505
    :cond_7
    nop

    .line 506
    invoke-interface {p1, v5}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 492
    add-int/lit8 v2, v2, 0x1

    move-object v3, v4

    goto/16 :goto_1

    .line 504
    :cond_8
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u5b89\u88c5\u8bb0\u5f55\u5305\u542b\u975e\u6cd5\u6587\u4ef6\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 508
    :cond_9
    return-void

    .line 489
    :cond_a
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u5b89\u88c5\u8bb0\u5f55\u6587\u4ef6\u6570\u65e0\u6548\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static readState(Landroid/content/Context;Z)Lio/github/leexeo/cage/space/ClaudeBundle$State;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 447
    invoke-static {}, Lio/github/leexeo/cage/space/ClaudeBundle;->requireArm64()V

    .line 448
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->requireIdle(Landroid/content/Context;)V

    .line 449
    const/4 v0, 0x0

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object v0

    .line 450
    const-string v1, "active.json"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    .line 451
    const-string v1, "active.json.bak"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    .line 452
    const-string v1, "active.json.new"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    .line 454
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->active(Ljava/io/File;)Landroid/util/AtomicFile;

    move-result-object v0

    invoke-virtual {v0}, Landroid/util/AtomicFile;->openRead()Ljava/io/FileInputStream;

    move-result-object v0

    const/high16 v1, 0x20000

    :try_start_0
    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->bytes(Ljava/io/InputStream;I)[B

    move-result-object v1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    if-eqz v0, :cond_0

    invoke-virtual {v0}, Ljava/io/InputStream;->close()V

    .line 455
    :cond_0
    new-instance v0, Lorg/json/JSONObject;

    new-instance v2, Ljava/lang/String;

    sget-object v3, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-direct {v2, v1, v3}, Ljava/lang/String;-><init>([BLjava/nio/charset/Charset;)V

    invoke-direct {v0, v2}, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v1

    invoke-static {p0, v0, p1, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->decodeState(Landroid/content/Context;Lorg/json/JSONObject;ZLjava/io/File;)Lio/github/leexeo/cage/space/ClaudeBundle$State;

    move-result-object p1

    .line 456
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->requireIdle(Landroid/content/Context;)V

    .line 457
    return-object p1

    .line 454
    :catchall_0
    move-exception p0

    if-eqz v0, :cond_1

    :try_start_1
    invoke-virtual {v0}, Ljava/io/InputStream;->close()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    goto :goto_0

    :catchall_1
    move-exception p1

    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_1
    :goto_0
    throw p0
.end method

.method private static records(Ljava/util/List;Z)Lorg/json/JSONArray;
    .locals 6
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeBundle$Record;",
            ">;Z)",
            "Lorg/json/JSONArray;"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 590
    new-instance v0, Lorg/json/JSONArray;

    invoke-direct {v0}, Lorg/json/JSONArray;-><init>()V

    .line 591
    invoke-interface {p0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object p0

    :goto_0
    invoke-interface {p0}, Ljava/util/Iterator;->hasNext()Z

    move-result v1

    if-eqz v1, :cond_1

    invoke-interface {p0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    .line 592
    new-instance v2, Lorg/json/JSONObject;

    invoke-direct {v2}, Lorg/json/JSONObject;-><init>()V

    const-string v3, "file"

    iget-object v4, v1, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    invoke-virtual {v2, v3, v4}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v2

    const-string v3, "size"

    iget-wide v4, v1, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    invoke-virtual {v2, v3, v4, v5}, Lorg/json/JSONObject;->put(Ljava/lang/String;J)Lorg/json/JSONObject;

    move-result-object v2

    const-string v3, "sha256"

    iget-object v4, v1, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    invoke-virtual {v2, v3, v4}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v2

    .line 593
    if-eqz p1, :cond_0

    const-string v3, "split"

    iget-object v1, v1, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->split:Ljava/lang/String;

    invoke-virtual {v2, v3, v1}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    .line 594
    :cond_0
    invoke-virtual {v0, v2}, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;

    .line 595
    goto :goto_0

    .line 596
    :cond_1
    return-object v0
.end method

.method public static declared-synchronized recoverUpgrade(Landroid/content/Context;)Ljava/lang/String;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    const-class v0, Lio/github/leexeo/cage/space/ClaudeBundle;

    monitor-enter v0

    .line 148
    const/4 v1, 0x0

    :try_start_0
    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object v1

    .line 149
    new-instance v2, Ljava/io/FileOutputStream;

    const-string v3, "install.lock"

    invoke-static {v1, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v1

    const/4 v3, 0x1

    invoke-direct {v2, v1, v3}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;Z)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_4

    .line 150
    :try_start_1
    invoke-virtual {v2}, Ljava/io/FileOutputStream;->getChannel()Ljava/nio/channels/FileChannel;

    move-result-object v1

    invoke-virtual {v1}, Ljava/nio/channels/FileChannel;->tryLock()Ljava/nio/channels/FileLock;

    move-result-object v1
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_2

    .line 151
    if-eqz v1, :cond_2

    .line 152
    :try_start_2
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->recoverIfNeeded(Landroid/content/Context;)Ljava/lang/String;

    move-result-object p0

    .line 153
    if-nez p0, :cond_0

    const-string p0, "\u6ca1\u6709\u5f85\u6062\u590d\u7684 Claude \u5347\u7ea7\u3002"
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    .line 154
    :cond_0
    if-eqz v1, :cond_1

    :try_start_3
    invoke-virtual {v1}, Ljava/nio/channels/FileLock;->close()V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_2

    :cond_1
    :try_start_4
    invoke-virtual {v2}, Ljava/io/FileOutputStream;->close()V
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_4

    .line 153
    monitor-exit v0

    return-object p0

    .line 149
    :catchall_0
    move-exception p0

    goto :goto_0

    .line 151
    :cond_2
    :try_start_5
    new-instance p0, Ljava/io/IOException;

    const-string v3, "\u53e6\u4e00\u6b21 Claude \u5bfc\u5165\u4ecd\u5728\u8fdb\u884c\u3002"

    invoke-direct {p0, v3}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_0

    .line 149
    :goto_0
    if-eqz v1, :cond_3

    :try_start_6
    invoke-virtual {v1}, Ljava/nio/channels/FileLock;->close()V
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_1

    goto :goto_1

    :catchall_1
    move-exception v1

    :try_start_7
    invoke-virtual {p0, v1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_3
    :goto_1
    throw p0
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_2

    :catchall_2
    move-exception p0

    :try_start_8
    invoke-virtual {v2}, Ljava/io/FileOutputStream;->close()V
    :try_end_8
    .catchall {:try_start_8 .. :try_end_8} :catchall_3

    goto :goto_2

    :catchall_3
    move-exception v1

    :try_start_9
    invoke-virtual {p0, v1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_2
    throw p0

    .line 147
    :catchall_4
    move-exception p0

    monitor-exit v0
    :try_end_9
    .catchall {:try_start_9 .. :try_end_9} :catchall_4

    throw p0
.end method

.method private static removeOwned(Ljava/io/File;Ljava/io/File;)V
    .locals 4

    .line 733
    :try_start_0
    invoke-virtual {p0}, Ljava/io/File;->getCanonicalFile()Ljava/io/File;

    move-result-object v0

    invoke-virtual {p1}, Ljava/io/File;->getCanonicalFile()Ljava/io/File;

    move-result-object v1

    .line 734
    invoke-virtual {p0}, Ljava/io/File;->getAbsoluteFile()Ljava/io/File;

    move-result-object v2

    invoke-virtual {v0, v2}, Ljava/io/File;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_2

    invoke-virtual {v0, v1}, Ljava/io/File;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_0

    .line 735
    invoke-virtual {v0}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v0

    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v1}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    sget-object v2, Ljava/io/File;->separator:Ljava/lang/String;

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_0

    goto :goto_1

    .line 736
    :cond_0
    invoke-virtual {p0}, Ljava/io/File;->isDirectory()Z

    move-result v0

    if-eqz v0, :cond_1

    .line 737
    invoke-virtual {p0}, Ljava/io/File;->listFiles()[Ljava/io/File;

    move-result-object v0

    .line 738
    if-eqz v0, :cond_1

    array-length v1, v0

    const/4 v2, 0x0

    :goto_0
    if-ge v2, v1, :cond_1

    aget-object v3, v0, v2

    invoke-static {v3, p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->removeOwned(Ljava/io/File;Ljava/io/File;)V

    add-int/lit8 v2, v2, 0x1

    goto :goto_0

    .line 740
    :cond_1
    invoke-virtual {p0}, Ljava/io/File;->delete()Z
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_2

    .line 735
    :cond_2
    :goto_1
    return-void

    .line 741
    :catch_0
    move-exception p0

    :goto_2
    nop

    .line 742
    return-void
.end method

.method private static requireArm64()V
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 653
    invoke-static {}, Landroid/os/Process;->is64Bit()Z

    move-result v0

    if-eqz v0, :cond_0

    sget-object v0, Landroid/os/Build;->SUPPORTED_ABIS:[Ljava/lang/String;

    invoke-static {v0}, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;

    move-result-object v0

    const-string v1, "arm64-v8a"

    invoke-interface {v0, v1}, Ljava/util/List;->contains(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_0

    .line 655
    return-void

    .line 654
    :cond_0
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u6b64 DEMO \u7684 Claude \u5bfc\u5165\u76ee\u524d\u4ec5\u652f\u6301 arm64 \u7a7a\u95f4\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0
.end method

.method private static requireFile(Ljava/io/File;J)V
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 657
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    .line 658
    invoke-virtual {p0}, Ljava/io/File;->isFile()Z

    move-result v0

    if-eqz v0, :cond_0

    invoke-virtual {p0}, Ljava/io/File;->length()J

    move-result-wide v0

    cmp-long p0, v0, p1

    if-nez p0, :cond_0

    .line 659
    return-void

    .line 658
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u5b89\u88c5\u6587\u4ef6\u7f3a\u5931\u6216\u5927\u5c0f\u6539\u53d8\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static root(Landroid/content/Context;Z)Ljava/io/File;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 607
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->data(Landroid/content/Context;)Ljava/io/File;

    move-result-object p0

    const-string v0, "files"

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    .line 608
    if-eqz p1, :cond_1

    invoke-virtual {p0}, Ljava/io/File;->isDirectory()Z

    move-result v0

    if-nez v0, :cond_1

    invoke-virtual {p0}, Ljava/io/File;->mkdir()Z

    move-result v0

    if-eqz v0, :cond_0

    goto :goto_0

    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u65e0\u6cd5\u521b\u5efa\u7a7a\u95f4\u6587\u4ef6\u76ee\u5f55\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 609
    :cond_1
    :goto_0
    const-string v0, "claude-bundles"

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    .line 610
    if-eqz p1, :cond_3

    invoke-virtual {p0}, Ljava/io/File;->isDirectory()Z

    move-result p1

    if-nez p1, :cond_3

    invoke-virtual {p0}, Ljava/io/File;->mkdir()Z

    move-result p1

    if-eqz p1, :cond_2

    goto :goto_1

    :cond_2
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u65e0\u6cd5\u521b\u5efa\u5b89\u88c5\u5305\u5b58\u50a8\u76ee\u5f55\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 611
    :cond_3
    :goto_1
    return-object p0
.end method

.method private static safeZipPath(Ljava/lang/String;)Z
    .locals 6

    .line 645
    invoke-virtual {p0}, Ljava/lang/String;->isEmpty()Z

    move-result v0

    const/4 v1, 0x0

    if-nez v0, :cond_5

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    const/16 v2, 0x400

    if-gt v0, v2, :cond_5

    const-string v0, "/"

    invoke-virtual {p0, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-nez v2, :cond_5

    const/16 v2, 0x5c

    invoke-virtual {p0, v2}, Ljava/lang/String;->indexOf(I)I

    move-result v2

    if-gez v2, :cond_5

    invoke-virtual {p0, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v2

    if-ltz v2, :cond_0

    goto :goto_2

    .line 646
    :cond_0
    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v2

    const/4 v3, 0x1

    if-eqz v2, :cond_1

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v2

    sub-int/2addr v2, v3

    invoke-virtual {p0, v1, v2}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    .line 649
    :cond_1
    const/4 v2, -0x1

    invoke-virtual {p0, v0, v2}, Ljava/lang/String;->split(Ljava/lang/String;I)[Ljava/lang/String;

    move-result-object p0

    array-length v0, p0

    move v2, v1

    :goto_0
    if-ge v2, v0, :cond_4

    aget-object v4, p0, v2

    invoke-virtual {v4}, Ljava/lang/String;->isEmpty()Z

    move-result v5

    if-nez v5, :cond_3

    const-string v5, "."

    invoke-virtual {v5, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-nez v5, :cond_3

    const-string v5, ".."

    invoke-virtual {v5, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_2

    goto :goto_1

    :cond_2
    add-int/lit8 v2, v2, 0x1

    goto :goto_0

    :cond_3
    :goto_1
    return v1

    .line 650
    :cond_4
    return v3

    .line 645
    :cond_5
    :goto_2
    return v1
.end method

.method private static same(Lio/github/leexeo/cage/space/ClaudeBundle$State;Lio/github/leexeo/cage/space/ClaudeBundle$Selection;)Z
    .locals 6

    .line 553
    iget-wide v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    iget-wide v2, p1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->version:J

    cmp-long v0, v0, v2

    const/4 v1, 0x0

    if-nez v0, :cond_7

    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    iget-object v2, p1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->signer:Ljava/lang/String;

    invoke-virtual {v0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_7

    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    .line 554
    invoke-interface {v0}, Ljava/util/List;->size()I

    move-result v0

    iget-object v2, p1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->apks:Ljava/util/List;

    invoke-interface {v2}, Ljava/util/List;->size()I

    move-result v2

    if-ne v0, v2, :cond_7

    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->libraries:Ljava/util/List;

    invoke-interface {v0}, Ljava/util/List;->size()I

    move-result v0

    iget-object v2, p1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->libraries:Ljava/util/List;

    invoke-interface {v2}, Ljava/util/List;->size()I

    move-result v2

    if-eq v0, v2, :cond_0

    goto/16 :goto_4

    .line 555
    :cond_0
    move v0, v1

    :goto_0
    iget-object v2, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    invoke-interface {v2}, Ljava/util/List;->size()I

    move-result v2

    if-ge v0, v2, :cond_3

    .line 556
    iget-object v2, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    invoke-interface {v2, v0}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    .line 557
    iget-object v3, p1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->apks:Ljava/util/List;

    invoke-interface {v3, v0}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;

    .line 558
    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->split:Ljava/lang/String;

    iget-object v5, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v4, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_2

    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    iget-object v5, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->sha256:Ljava/lang/String;

    invoke-virtual {v4, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_2

    iget-wide v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    iget-wide v2, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->size:J

    cmp-long v2, v4, v2

    if-eqz v2, :cond_1

    goto :goto_1

    .line 555
    :cond_1
    add-int/lit8 v0, v0, 0x1

    goto :goto_0

    .line 558
    :cond_2
    :goto_1
    return v1

    .line 560
    :cond_3
    move v0, v1

    :goto_2
    iget-object v2, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->libraries:Ljava/util/List;

    invoke-interface {v2}, Ljava/util/List;->size()I

    move-result v2

    if-ge v0, v2, :cond_6

    .line 561
    iget-object v2, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->libraries:Ljava/util/List;

    invoke-interface {v2, v0}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    .line 562
    iget-object v3, p1, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->libraries:Ljava/util/List;

    invoke-interface {v3, v0}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;

    .line 563
    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    iget-object v5, v3, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->name:Ljava/lang/String;

    invoke-virtual {v4, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_5

    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    iget-object v5, v3, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->sha256:Ljava/lang/String;

    invoke-virtual {v4, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_5

    iget-wide v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    iget-wide v2, v3, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->size:J

    cmp-long v2, v4, v2

    if-eqz v2, :cond_4

    goto :goto_3

    .line 560
    :cond_4
    add-int/lit8 v0, v0, 0x1

    goto :goto_2

    .line 563
    :cond_5
    :goto_3
    return v1

    .line 565
    :cond_6
    const/4 p0, 0x1

    return p0

    .line 554
    :cond_7
    :goto_4
    return v1
.end method

.method private static select(Ljava/util/List;)Lio/github/leexeo/cage/space/ClaudeBundle$Selection;
    .locals 10
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeBundle$Apk;",
            ">;)",
            "Lio/github/leexeo/cage/space/ClaudeBundle$Selection;"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 353
    invoke-interface {p0}, Ljava/util/List;->size()I

    move-result v0

    const/4 v1, 0x3

    if-lt v0, v1, :cond_14

    invoke-interface {p0}, Ljava/util/List;->size()I

    move-result v0

    const/16 v1, 0x40

    if-gt v0, v1, :cond_14

    .line 354
    nop

    .line 355
    new-instance v0, Ljava/util/HashSet;

    invoke-direct {v0}, Ljava/util/HashSet;-><init>()V

    .line 356
    invoke-interface {p0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v1

    const/4 v2, 0x0

    move-object v3, v2

    :goto_0
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    move-result v4

    if-eqz v4, :cond_2

    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;

    .line 357
    iget-object v5, v4, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-interface {v0, v5}, Ljava/util/Set;->add(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_1

    .line 358
    iget-object v5, v4, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v5}, Ljava/lang/String;->isEmpty()Z

    move-result v5

    if-eqz v5, :cond_0

    move-object v3, v4

    .line 359
    :cond_0
    goto :goto_0

    .line 357
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u5b89\u88c5\u5305\u5305\u542b\u91cd\u590d\u5206\u62c6\u540d\u79f0\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 360
    :cond_2
    if-eqz v3, :cond_13

    iget-object v0, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->types:Ljava/util/Set;

    invoke-interface {v0}, Ljava/util/Set;->isEmpty()Z

    move-result v0

    if-eqz v0, :cond_13

    .line 361
    new-instance v0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;

    invoke-direct {v0, v2}, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;-><init>(Lio/github/leexeo/cage/space/ClaudeBundle$1;)V

    .line 362
    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->apks:Ljava/util/List;

    invoke-interface {v1, v3}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 363
    iget-wide v1, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->version:J

    iput-wide v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->version:J

    .line 364
    iget-object v1, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->versionName:Ljava/lang/String;

    invoke-virtual {v1}, Ljava/lang/String;->isEmpty()Z

    move-result v1

    if-eqz v1, :cond_3

    iget-wide v1, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->version:J

    invoke-static {v1, v2}, Ljava/lang/Long;->toString(J)Ljava/lang/String;

    move-result-object v1

    goto :goto_1

    :cond_3
    iget-object v1, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->versionName:Ljava/lang/String;

    :goto_1
    iput-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->versionName:Ljava/lang/String;

    .line 365
    iget-object v1, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->signer:Ljava/lang/String;

    iput-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->signer:Ljava/lang/String;

    .line 366
    new-instance v1, Ljava/util/HashSet;

    invoke-direct {v1}, Ljava/util/HashSet;-><init>()V

    .line 367
    nop

    .line 368
    invoke-interface {p0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object p0

    const/4 v2, 0x0

    move v4, v2

    :goto_2
    invoke-interface {p0}, Ljava/util/Iterator;->hasNext()Z

    move-result v5

    if-eqz v5, :cond_e

    invoke-interface {p0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v5

    check-cast v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;

    .line 369
    const-string v6, "com.anthropic.claude"

    iget-object v7, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->pkg:Ljava/lang/String;

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_d

    iget-wide v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->version:J

    iget-wide v8, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->version:J

    cmp-long v6, v6, v8

    if-nez v6, :cond_d

    iget-object v6, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->signer:Ljava/lang/String;

    iget-object v7, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->signer:Ljava/lang/String;

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_d

    .line 371
    if-ne v5, v3, :cond_4

    goto :goto_2

    .line 372
    :cond_4
    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->required:Ljava/util/Set;

    invoke-interface {v6}, Ljava/util/Set;->isEmpty()Z

    move-result v6

    if-eqz v6, :cond_c

    .line 373
    const-string v6, "config.armeabi_v7a"

    iget-object v7, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    const-string v7, "base__abi"

    if-eqz v6, :cond_6

    .line 374
    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->types:Ljava/util/Set;

    invoke-static {v7}, Ljava/util/Collections;->singleton(Ljava/lang/Object;)Ljava/util/Set;

    move-result-object v7

    invoke-interface {v6, v7}, Ljava/util/Set;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_5

    iget-object v5, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->nativeFiles:Ljava/util/List;

    invoke-interface {v5}, Ljava/util/List;->isEmpty()Z

    move-result v5

    if-nez v5, :cond_5

    goto :goto_2

    .line 375
    :cond_5
    new-instance p0, Ljava/io/IOException;

    const-string v0, "32 \u4f4d\u914d\u7f6e\u5206\u62c6\u7ed3\u6784\u65e0\u6548\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 378
    :cond_6
    const-string v6, "config.arm64_v8a"

    iget-object v8, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v6, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_8

    .line 379
    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->types:Ljava/util/Set;

    invoke-static {v7}, Ljava/util/Collections;->singleton(Ljava/lang/Object;)Ljava/util/Set;

    move-result-object v7

    invoke-interface {v6, v7}, Ljava/util/Set;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_7

    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->nativeFiles:Ljava/util/List;

    invoke-interface {v6}, Ljava/util/List;->isEmpty()Z

    move-result v6

    if-nez v6, :cond_7

    .line 381
    add-int/lit8 v2, v2, 0x1

    goto :goto_3

    .line 380
    :cond_7
    new-instance p0, Ljava/io/IOException;

    const-string v0, "64 \u4f4d\u539f\u751f\u5e93\u914d\u7f6e\u4e0d\u5b8c\u6574\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 382
    :cond_8
    sget-object v6, Lio/github/leexeo/cage/space/ClaudeBundle;->DENSITIES:Ljava/util/Set;

    iget-object v7, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-interface {v6, v7}, Ljava/util/Set;->contains(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_a

    .line 383
    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->types:Ljava/util/Set;

    const-string v7, "base__density"

    invoke-static {v7}, Ljava/util/Collections;->singleton(Ljava/lang/Object;)Ljava/util/Set;

    move-result-object v7

    invoke-interface {v6, v7}, Ljava/util/Set;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_9

    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->nativeFiles:Ljava/util/List;

    invoke-interface {v6}, Ljava/util/List;->isEmpty()Z

    move-result v6

    if-eqz v6, :cond_9

    .line 385
    add-int/lit8 v4, v4, 0x1

    goto :goto_3

    .line 384
    :cond_9
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u5c4f\u5e55\u5bc6\u5ea6\u914d\u7f6e\u65e0\u6548\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 386
    :cond_a
    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    const-string v7, "config\\.[a-z]{2,3}(_r[A-Z]{2})?"

    invoke-virtual {v6, v7}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v6

    if-eqz v6, :cond_b

    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->types:Ljava/util/Set;

    .line 387
    invoke-interface {v6}, Ljava/util/Set;->isEmpty()Z

    move-result v6

    if-eqz v6, :cond_b

    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->nativeFiles:Ljava/util/List;

    invoke-interface {v6}, Ljava/util/List;->isEmpty()Z

    move-result v6

    if-eqz v6, :cond_b

    .line 390
    :goto_3
    iget-object v6, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->apks:Ljava/util/List;

    invoke-interface {v6, v5}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 391
    iget-object v5, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->types:Ljava/util/Set;

    invoke-interface {v1, v5}, Ljava/util/Set;->addAll(Ljava/util/Collection;)Z

    .line 392
    goto/16 :goto_2

    .line 388
    :cond_b
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u6b64 DEMO \u4e0d\u652f\u6301\u6240\u9009\u914d\u7f6e\u5206\u62c6\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 372
    :cond_c
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u914d\u7f6e\u5206\u62c6\u4e0d\u53ef\u518d\u8981\u6c42\u5176\u4ed6\u5206\u62c6\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 370
    :cond_d
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u6240\u6709 Claude \u5206\u62c6\u5fc5\u987b\u5177\u6709\u76f8\u540c\u5305\u540d\u3001\u7248\u672c\u548c\u5f53\u524d\u5b98\u65b9\u7b7e\u540d\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 393
    :cond_e
    const/4 p0, 0x1

    if-ne v2, p0, :cond_12

    if-ne v4, p0, :cond_12

    iget-object p0, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->required:Ljava/util/Set;

    invoke-interface {v1, p0}, Ljava/util/Set;->containsAll(Ljava/util/Collection;)Z

    move-result p0

    if-eqz p0, :cond_12

    .line 395
    iget-object p0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->apks:Ljava/util/List;

    new-instance v1, Lio/github/leexeo/cage/space/ClaudeBundle$$ExternalSyntheticLambda0;

    invoke-direct {v1}, Lio/github/leexeo/cage/space/ClaudeBundle$$ExternalSyntheticLambda0;-><init>()V

    invoke-static {v1}, Ljava/util/Comparator;->comparing(Ljava/util/function/Function;)Ljava/util/Comparator;

    move-result-object v1

    invoke-static {p0, v1}, Ljava/util/Collections;->sort(Ljava/util/List;Ljava/util/Comparator;)V

    .line 396
    new-instance p0, Ljava/util/HashSet;

    invoke-direct {p0}, Ljava/util/HashSet;-><init>()V

    .line 397
    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->apks:Ljava/util/List;

    invoke-interface {v1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v1

    :cond_f
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :cond_11

    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;

    iget-object v2, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->nativeFiles:Ljava/util/List;

    invoke-interface {v2}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v2

    :goto_4
    invoke-interface {v2}, Ljava/util/Iterator;->hasNext()Z

    move-result v3

    if-eqz v3, :cond_f

    invoke-interface {v2}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;

    .line 398
    iget-object v4, v3, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;->name:Ljava/lang/String;

    invoke-interface {p0, v4}, Ljava/util/Set;->add(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_10

    .line 399
    iget-object v4, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->libraries:Ljava/util/List;

    invoke-interface {v4, v3}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 400
    goto :goto_4

    .line 398
    :cond_10
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u914d\u7f6e\u5206\u62c6\u5305\u542b\u91cd\u590d\u539f\u751f\u5e93\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 401
    :cond_11
    iget-object p0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->libraries:Ljava/util/List;

    new-instance v1, Lio/github/leexeo/cage/space/ClaudeBundle$$ExternalSyntheticLambda1;

    invoke-direct {v1}, Lio/github/leexeo/cage/space/ClaudeBundle$$ExternalSyntheticLambda1;-><init>()V

    invoke-static {v1}, Ljava/util/Comparator;->comparing(Ljava/util/function/Function;)Ljava/util/Comparator;

    move-result-object v1

    invoke-static {p0, v1}, Ljava/util/Collections;->sort(Ljava/util/List;Ljava/util/Comparator;)V

    .line 402
    return-object v0

    .line 394
    :cond_12
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u7f3a\u5c11\u552f\u4e00\u7684 arm64 \u67b6\u6784\u6216\u5c4f\u5e55\u5bc6\u5ea6\u5206\u62c6\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 360
    :cond_13
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u7f3a\u5c11\u552f\u4e00\u7684 Claude \u57fa\u7840 APK\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 353
    :cond_14
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u8bf7\u9009\u62e9\u5305\u542b\u57fa\u7840\u5305\u3001\u67b6\u6784\u548c\u5bc6\u5ea6\u5206\u62c6\u7684\u5b8c\u6574 Claude \u5305\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static sha(Ljava/io/File;J)Ljava/lang/String;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 678
    new-instance v0, Ljava/io/FileInputStream;

    invoke-direct {v0, p0}, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V

    const/4 p0, 0x0

    :try_start_0
    invoke-static {v0, p1, p2, p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->digest(Ljava/io/InputStream;J[B)Ljava/lang/String;

    move-result-object p0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    invoke-virtual {v0}, Ljava/io/InputStream;->close()V

    return-object p0

    :catchall_0
    move-exception p0

    :try_start_1
    invoke-virtual {v0}, Ljava/io/InputStream;->close()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    goto :goto_0

    :catchall_1
    move-exception p1

    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_0
    throw p0
.end method

.method private static simple(Ljava/lang/String;)Z
    .locals 2

    .line 631
    if-eqz p0, :cond_0

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    const/16 v1, 0xa0

    if-gt v0, v1, :cond_0

    const-string v0, "."

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_0

    const-string v0, ".."

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_0

    .line 632
    const-string v0, "[A-Za-z0-9._+-]+"

    invoke-virtual {p0, v0}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_0

    const/4 p0, 0x1

    goto :goto_0

    :cond_0
    const/4 p0, 0x0

    .line 631
    :goto_0
    return p0
.end method

.method private static types(Ljava/lang/String;)Ljava/util/Set;
    .locals 5
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/lang/String;",
            ")",
            "Ljava/util/Set<",
            "Ljava/lang/String;",
            ">;"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 301
    new-instance v0, Ljava/util/HashSet;

    invoke-direct {v0}, Ljava/util/HashSet;-><init>()V

    .line 302
    if-eqz p0, :cond_4

    invoke-virtual {p0}, Ljava/lang/String;->isEmpty()Z

    move-result v1

    if-eqz v1, :cond_0

    goto :goto_1

    .line 303
    :cond_0
    const-string v1, ","

    const/4 v2, -0x1

    invoke-virtual {p0, v1, v2}, Ljava/lang/String;->split(Ljava/lang/String;I)[Ljava/lang/String;

    move-result-object p0

    array-length v1, p0

    const/4 v2, 0x0

    :goto_0
    if-ge v2, v1, :cond_3

    aget-object v3, p0, v2

    .line 304
    const-string v4, "base__abi"

    invoke-virtual {v4, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-nez v4, :cond_1

    const-string v4, "base__density"

    invoke-virtual {v4, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_2

    :cond_1
    invoke-interface {v0, v3}, Ljava/util/Set;->add(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_2

    .line 303
    add-int/lit8 v2, v2, 0x1

    goto :goto_0

    .line 305
    :cond_2
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u5b89\u88c5\u5305\u5305\u542b\u5f53\u524d DEMO \u4e0d\u652f\u6301\u7684\u5206\u62c6\u7c7b\u578b\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 307
    :cond_3
    return-object v0

    .line 302
    :cond_4
    :goto_1
    return-object v0
.end method

.method private static unpack(Ljava/io/File;Ljava/io/File;)Ljava/util/List;
    .locals 18
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/io/File;",
            "Ljava/io/File;",
            ")",
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeBundle$Apk;",
            ">;"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 158
    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    .line 159
    new-instance v1, Ljava/util/HashSet;

    invoke-direct {v1}, Ljava/util/HashSet;-><init>()V

    .line 160
    nop

    .line 161
    nop

    .line 162
    new-instance v2, Ljava/util/zip/ZipFile;

    move-object/from16 v3, p0

    invoke-direct {v2, v3}, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File;)V

    .line 163
    :try_start_0
    invoke-virtual {v2}, Ljava/util/zip/ZipFile;->entries()Ljava/util/Enumeration;

    move-result-object v3

    const-wide/16 v4, 0x0

    const/4 v6, 0x0

    move-wide v7, v4

    .line 164
    :goto_0
    invoke-interface {v3}, Ljava/util/Enumeration;->hasMoreElements()Z

    move-result v9

    if-eqz v9, :cond_7

    .line 165
    invoke-interface {v3}, Ljava/util/Enumeration;->nextElement()Ljava/lang/Object;

    move-result-object v9

    check-cast v9, Ljava/util/zip/ZipEntry;

    .line 166
    invoke-virtual {v9}, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;

    move-result-object v10

    .line 167
    add-int/lit8 v6, v6, 0x1

    const/16 v11, 0x60

    if-gt v6, v11, :cond_6

    invoke-static {v10}, Lio/github/leexeo/cage/space/ClaudeBundle;->simple(Ljava/lang/String;)Z

    move-result v11

    if-eqz v11, :cond_6

    sget-object v11, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {v10, v11}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object v11

    invoke-interface {v1, v11}, Ljava/util/Set;->add(Ljava/lang/Object;)Z

    move-result v11

    if-eqz v11, :cond_6

    .line 168
    invoke-virtual {v9}, Ljava/util/zip/ZipEntry;->isDirectory()Z

    move-result v11

    if-nez v11, :cond_6

    invoke-virtual {v9}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v11

    cmp-long v11, v11, v4

    if-ltz v11, :cond_6

    .line 170
    invoke-virtual {v9}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v11

    add-long/2addr v7, v11

    .line 171
    const-wide/32 v11, 0x20000000

    cmp-long v11, v7, v11

    if-gtz v11, :cond_5

    .line 172
    const-string v11, ".apk"

    invoke-virtual {v10, v11}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v11

    if-nez v11, :cond_1

    .line 173
    invoke-virtual {v9}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v9

    const-wide/32 v11, 0x100000

    cmp-long v9, v9, v11

    if-gtz v9, :cond_0

    move-object/from16 v11, p1

    goto :goto_0

    :cond_0
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u5b89\u88c5\u5305\u9644\u52a0\u6587\u4ef6\u8fc7\u5927\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 176
    :cond_1
    invoke-interface {v0}, Ljava/util/List;->size()I

    move-result v11

    const/16 v12, 0x40

    if-ge v11, v12, :cond_4

    invoke-virtual {v9}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v11

    cmp-long v11, v11, v4

    if-lez v11, :cond_4

    invoke-virtual {v9}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v11

    const-wide/32 v13, 0xa000000

    cmp-long v11, v11, v13

    if-gtz v11, :cond_4

    .line 178
    move-object/from16 v11, p1

    invoke-static {v11, v10}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v13

    .line 179
    invoke-virtual {v2, v9}, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;

    move-result-object v12
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    .line 180
    :try_start_1
    invoke-virtual {v9}, Ljava/util/zip/ZipEntry;->getSize()J

    move-result-wide v14

    const-wide/32 v16, 0xa000000

    invoke-static/range {v12 .. v17}, Lio/github/leexeo/cage/space/ClaudeBundle;->copyNew(Ljava/io/InputStream;Ljava/io/File;JJ)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 181
    if-eqz v12, :cond_2

    :try_start_2
    invoke-virtual {v12}, Ljava/io/InputStream;->close()V

    .line 182
    :cond_2
    invoke-static {v13}, Lio/github/leexeo/cage/space/ClaudeBundle;->readOnly(Ljava/io/File;)V

    .line 183
    invoke-static {v13}, Lio/github/leexeo/cage/space/ClaudeBundle;->inspect(Ljava/io/File;)Lio/github/leexeo/cage/space/ClaudeBundle$Apk;

    move-result-object v9

    invoke-interface {v0, v9}, Ljava/util/List;->add(Ljava/lang/Object;)Z
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_2

    .line 184
    goto/16 :goto_0

    .line 179
    :catchall_0
    move-exception v0

    move-object v1, v0

    if-eqz v12, :cond_3

    :try_start_3
    invoke-virtual {v12}, Ljava/io/InputStream;->close()V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    goto :goto_1

    :catchall_1
    move-exception v0

    :try_start_4
    invoke-virtual {v1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_3
    :goto_1
    throw v1

    .line 177
    :cond_4
    new-instance v0, Ljava/io/IOException;

    const-string v1, "Claude APK \u6570\u91cf\u6216\u5927\u5c0f\u8d85\u51fa\u9650\u5236\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 171
    :cond_5
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u5b89\u88c5\u5305\u89e3\u538b\u540e\u8fc7\u5927\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 169
    :cond_6
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u5b89\u88c5\u5305\u5305\u542b\u91cd\u590d\u3001\u8fc7\u591a\u6216\u4e0d\u5b89\u5168\u7684\u6587\u4ef6\u8def\u5f84\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_2

    .line 185
    :cond_7
    invoke-virtual {v2}, Ljava/util/zip/ZipFile;->close()V

    .line 186
    return-object v0

    .line 162
    :catchall_2
    move-exception v0

    move-object v1, v0

    :try_start_5
    invoke-virtual {v2}, Ljava/util/zip/ZipFile;->close()V
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_3

    goto :goto_2

    :catchall_3
    move-exception v0

    invoke-virtual {v1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_2
    throw v1
.end method

.method static validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V
    .locals 9
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 511
    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directoryFile:Ljava/io/File;

    invoke-virtual {v0}, Ljava/io/File;->isDirectory()Z

    move-result v0

    if-eqz v0, :cond_10

    .line 512
    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    .line 513
    iget-object v1, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    invoke-interface {v1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v1

    :goto_0
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :cond_2

    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    .line 514
    iget-object v3, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directoryFile:Ljava/io/File;

    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    invoke-static {v3, v4}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v3

    .line 515
    iget-wide v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    invoke-static {v3, v4, v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->requireFile(Ljava/io/File;J)V

    .line 516
    if-eqz p1, :cond_1

    .line 517
    invoke-static {v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->inspect(Ljava/io/File;)Lio/github/leexeo/cage/space/ClaudeBundle$Apk;

    move-result-object v3

    .line 518
    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    iget-object v5, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->sha256:Ljava/lang/String;

    invoke-virtual {v4, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_0

    iget-object v2, v2, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->split:Ljava/lang/String;

    iget-object v4, v3, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v2, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_0

    .line 520
    invoke-interface {v0, v3}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    goto :goto_1

    .line 519
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u539f\u7248 APK \u5df2\u6539\u53d8\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 522
    :cond_1
    :goto_1
    goto :goto_0

    .line 523
    :cond_2
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->nativeDir(Lio/github/leexeo/cage/space/ClaudeBundle$State;)Ljava/io/File;

    move-result-object v1

    .line 524
    invoke-virtual {v1}, Ljava/io/File;->isDirectory()Z

    move-result v2

    if-eqz v2, :cond_f

    .line 525
    invoke-virtual {v1}, Ljava/io/File;->list()[Ljava/lang/String;

    move-result-object v2

    .line 526
    if-eqz v2, :cond_e

    array-length v3, v2

    iget-object v4, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->libraries:Ljava/util/List;

    invoke-interface {v4}, Ljava/util/List;->size()I

    move-result v4

    if-ne v3, v4, :cond_e

    .line 527
    new-instance v3, Ljava/util/HashSet;

    invoke-direct {v3}, Ljava/util/HashSet;-><init>()V

    .line 528
    iget-object v4, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->libraries:Ljava/util/List;

    invoke-interface {v4}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v4

    :goto_2
    invoke-interface {v4}, Ljava/util/Iterator;->hasNext()Z

    move-result v5

    if-eqz v5, :cond_5

    invoke-interface {v4}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v5

    check-cast v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    .line 529
    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    invoke-interface {v3, v6}, Ljava/util/Set;->add(Ljava/lang/Object;)Z

    .line 530
    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->name:Ljava/lang/String;

    invoke-static {v1, v6}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v6

    .line 531
    iget-wide v7, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    invoke-static {v6, v7, v8}, Lio/github/leexeo/cage/space/ClaudeBundle;->requireFile(Ljava/io/File;J)V

    .line 532
    if-eqz p1, :cond_4

    iget-object v5, v5, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    const-wide/32 v7, 0x4000000

    invoke-static {v6, v7, v8}, Lio/github/leexeo/cage/space/ClaudeBundle;->sha(Ljava/io/File;J)Ljava/lang/String;

    move-result-object v6

    invoke-virtual {v5, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_3

    goto :goto_3

    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u539f\u751f\u5e93\u5df2\u6539\u53d8\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 533
    :cond_4
    :goto_3
    goto :goto_2

    .line 534
    :cond_5
    array-length v1, v2

    const/4 v4, 0x0

    move v5, v4

    :goto_4
    if-ge v5, v1, :cond_7

    aget-object v6, v2, v5

    invoke-interface {v3, v6}, Ljava/util/Set;->contains(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_6

    add-int/lit8 v5, v5, 0x1

    goto :goto_4

    :cond_6
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u539f\u751f\u5e93\u76ee\u5f55\u5305\u542b\u672a\u77e5\u6587\u4ef6\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 535
    :cond_7
    if-eqz p1, :cond_9

    .line 536
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->select(Ljava/util/List;)Lio/github/leexeo/cage/space/ClaudeBundle$Selection;

    move-result-object v0

    .line 537
    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->same(Lio/github/leexeo/cage/space/ClaudeBundle$State;Lio/github/leexeo/cage/space/ClaudeBundle$Selection;)Z

    move-result v0

    if-eqz v0, :cond_8

    goto :goto_5

    :cond_8
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u914d\u7f6e\u5206\u62c6\u4e0e\u5b89\u88c5\u8bb0\u5f55\u4e0d\u4e00\u81f4\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 539
    :cond_9
    :goto_5
    if-eqz p2, :cond_d

    .line 540
    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    invoke-interface {v0, v4}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    .line 541
    iget-wide v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    invoke-static {p2, v1, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->requireFile(Ljava/io/File;J)V

    .line 542
    iget-object v0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    const-wide/32 v1, 0xa000000

    invoke-static {p2, v1, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->sha(Ljava/io/File;J)Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_c

    .line 543
    new-instance v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;

    const/4 v1, 0x0

    invoke-direct {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;-><init>(Lio/github/leexeo/cage/space/ClaudeBundle$1;)V

    .line 544
    invoke-static {p2, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->readManifest(Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeBundle$Apk;)V

    .line 545
    const-string v1, "com.anthropic.claude"

    iget-object v2, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->pkg:Ljava/lang/String;

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_b

    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    invoke-virtual {v1}, Ljava/lang/String;->isEmpty()Z

    move-result v1

    if-eqz v1, :cond_b

    iget-wide v0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->version:J

    iget-wide v2, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    cmp-long v0, v0, v2

    if-nez v0, :cond_b

    .line 547
    if-eqz p1, :cond_d

    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    invoke-static {p2}, Lio/github/leexeo/cage/space/ClaudeBundle;->verifiedSigner(Ljava/io/File;)Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_a

    goto :goto_6

    .line 548
    :cond_a
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u79c1\u6709\u57fa\u7840 APK \u7b7e\u540d\u4e0d\u4e00\u81f4\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 546
    :cond_b
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u79c1\u6709\u57fa\u7840 APK \u7248\u672c\u4e0d\u4e00\u81f4\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 542
    :cond_c
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u79c1\u6709\u57fa\u7840 APK \u5df2\u6539\u53d8\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 550
    :cond_d
    :goto_6
    return-void

    .line 526
    :cond_e
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u539f\u751f\u5e93\u96c6\u5408\u5df2\u6539\u53d8\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 524
    :cond_f
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u539f\u751f\u5e93\u76ee\u5f55\u7f3a\u5931\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 511
    :cond_10
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u914d\u7f6e\u5206\u62c6\u76ee\u5f55\u4e0d\u5b58\u5728\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static value(Ljava/lang/String;)Ljava/lang/String;
    .locals 0

    .line 723
    if-nez p0, :cond_0

    const-string p0, ""

    :cond_0
    return-object p0
.end method

.method static verifiedSigner(Ljava/io/File;)Ljava/lang/String;
    .locals 10
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 205
    const-string v0, "verify"

    const-string v1, "android.util.apk.ApkSignatureVerifier"

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    .line 207
    nop

    .line 208
    nop

    .line 210
    const/4 v2, 0x0

    :try_start_0
    const-string v3, "android.content.pm.parsing.result.ParseInput"

    invoke-static {v3}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v3

    .line 211
    const-class v4, Ljava/lang/String;

    sget-object v5, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v3, v4, v5}, [Ljava/lang/Class;

    move-result-object v3

    invoke-virtual {v1, v0, v3}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v3
    :try_end_0
    .catch Ljava/lang/ClassNotFoundException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljava/lang/NoSuchMethodException; {:try_start_0 .. :try_end_0} :catch_0

    .line 212
    goto :goto_0

    :catch_0
    move-exception v3

    move-object v3, v2

    .line 214
    :goto_0
    const/4 v4, 0x2

    const-string v5, "Claude APK \u5b8c\u6574\u7b7e\u540d\u6821\u9a8c\u672a\u901a\u8fc7\u3002"

    const/4 v6, 0x1

    const/4 v7, 0x0

    if-eqz v3, :cond_1

    .line 215
    :try_start_1
    const-string v0, "android.content.pm.parsing.result.ParseTypeImpl"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    .line 216
    const-string v1, "forDefaultParsing"

    new-array v8, v7, [Ljava/lang/Class;

    invoke-virtual {v0, v1, v8}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v8, v7, [Ljava/lang/Object;

    invoke-virtual {v1, v2, v8}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    .line 217
    const-string v8, "reset"

    new-array v9, v7, [Ljava/lang/Class;

    invoke-virtual {v0, v8, v9}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    new-array v8, v7, [Ljava/lang/Object;

    invoke-virtual {v0, v1, v8}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    .line 218
    invoke-virtual {v3, v6}, Ljava/lang/reflect/Method;->setAccessible(Z)V

    .line 219
    invoke-virtual {p0}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object p0

    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    filled-new-array {v0, p0, v1}, [Ljava/lang/Object;

    move-result-object p0

    invoke-virtual {v3, v2, p0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    .line 220
    const-string v0, "android.content.pm.parsing.result.ParseResult"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    .line 221
    if-eqz p0, :cond_0

    const-string v1, "isError"

    new-array v2, v7, [Ljava/lang/Class;

    invoke-virtual {v0, v1, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v2, v7, [Ljava/lang/Object;

    invoke-virtual {v1, p0, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Ljava/lang/Boolean;

    invoke-virtual {v1}, Ljava/lang/Boolean;->booleanValue()Z

    move-result v1

    if-nez v1, :cond_0

    .line 223
    const-string v1, "getResult"

    new-array v2, v7, [Ljava/lang/Class;

    invoke-virtual {v0, v1, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    new-array v1, v7, [Ljava/lang/Object;

    invoke-virtual {v0, p0, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    .line 224
    goto :goto_1

    .line 222
    :cond_0
    new-instance p0, Ljava/io/IOException;

    invoke-direct {p0, v5}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 229
    :catch_1
    move-exception p0

    goto/16 :goto_3

    .line 225
    :cond_1
    const-class v3, Ljava/lang/String;

    sget-object v8, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v3, v8}, [Ljava/lang/Class;

    move-result-object v3

    invoke-virtual {v1, v0, v3}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    .line 226
    invoke-virtual {v0, v6}, Ljava/lang/reflect/Method;->setAccessible(Z)V

    .line 227
    invoke-virtual {p0}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object p0

    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    filled-new-array {p0, v1}, [Ljava/lang/Object;

    move-result-object p0

    invoke-virtual {v0, v2, p0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0
    :try_end_1
    .catch Ljava/lang/reflect/InvocationTargetException; {:try_start_1 .. :try_end_1} :catch_1

    .line 231
    :goto_1
    nop

    .line 232
    if-eqz p0, :cond_4

    .line 234
    :try_start_2
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v0

    const-string v1, "getSignatures"

    new-array v2, v7, [Ljava/lang/Class;

    invoke-virtual {v0, v1, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    new-array v1, v7, [Ljava/lang/Object;

    invoke-virtual {v0, p0, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, [Landroid/content/pm/Signature;
    :try_end_2
    .catch Ljava/lang/NoSuchMethodException; {:try_start_2 .. :try_end_2} :catch_2

    .line 237
    goto :goto_2

    .line 235
    :catch_2
    move-exception v0

    .line 236
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v0

    const-string v1, "signatures"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->field(Ljava/lang/Class;Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v0

    invoke-virtual {v0, p0}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    move-object v0, p0

    check-cast v0, [Landroid/content/pm/Signature;

    .line 238
    :goto_2
    if-eqz v0, :cond_3

    array-length p0, v0

    if-ne p0, v6, :cond_3

    .line 240
    const-string p0, "SHA-256"

    invoke-static {p0}, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;

    move-result-object p0

    aget-object v0, v0, v7

    invoke-virtual {v0}, Landroid/content/pm/Signature;->toByteArray()[B

    move-result-object v0

    invoke-virtual {p0, v0}, Ljava/security/MessageDigest;->digest([B)[B

    move-result-object p0

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->hex([B)Ljava/lang/String;

    move-result-object p0

    .line 241
    sget-object v0, Lio/github/leexeo/cage/space/ClaudeBundle;->SIGNERS:Ljava/util/Set;

    invoke-interface {v0, p0}, Ljava/util/Set;->contains(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_2

    .line 242
    return-object p0

    .line 241
    :cond_2
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude APK \u4e0d\u662f\u5df2\u77e5 Anthropic \u5b98\u65b9\u7b7e\u540d\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 239
    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude APK \u5fc5\u987b\u53ea\u6709\u4e00\u4e2a\u5df2\u9a8c\u8bc1\u7684\u5f53\u524d\u7b7e\u540d\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 232
    :cond_4
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Android \u672a\u8fd4\u56de\u5df2\u9a8c\u8bc1\u7684\u7b7e\u540d\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 230
    :goto_3
    new-instance v0, Ljava/io/IOException;

    invoke-virtual {p0}, Ljava/lang/reflect/InvocationTargetException;->getCause()Ljava/lang/Throwable;

    move-result-object p0

    invoke-direct {v0, v5, p0}, Ljava/io/IOException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw v0
.end method
