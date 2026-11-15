.class public final Lio/github/leexeo/cage/space/SpaceActivity;
.super Landroid/app/Activity;
.source "SpaceActivity.java"


# static fields
.field private static final ACTION:Ljava/lang/String; = "io.github.leexeo.cage.space."

.field private static final GATEWAY:Ljava/lang/String; = "io.github.leexeo.cage.microdemo"

.field private static final NETWORK:I = 0x2

.field private static final PICK:I = 0x1

.field private static final PICK_CLAUDE:I = 0x3

.field private static final tasks:Ljava/util/concurrent/ExecutorService;


# instance fields
.field private busy:Z

.field private content:Landroid/widget/LinearLayout;

.field private demo:Z

.field private launchRequested:Z

.field private microG:Z

.field private notice:Ljava/lang/String;

.field private pendingListing:Z

.field private pendingPackage:Ljava/lang/String;

.field private refreshGeneration:I

.field private resumed:Z

.field private status:Landroid/widget/TextView;


# direct methods
.method public static synthetic $r8$lambda$OzvqypzKu9IHmq7Hs33VfMiEsc8(Lio/github/leexeo/cage/space/SpaceActivity;)V
    .locals 0

    invoke-direct {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->checkNetwork()V

    return-void
.end method

.method public static synthetic $r8$lambda$T7w387uDduEbwIMFAHQ7Vg5kG2U(Lio/github/leexeo/cage/space/SpaceActivity;)V
    .locals 0

    invoke-direct {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->pickClaude()V

    return-void
.end method

.method public static synthetic $r8$lambda$TAPT9vxlXVbnJdEVWt_YHg-MaRI(Lio/github/leexeo/cage/space/SpaceActivity;)V
    .locals 0

    invoke-direct {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->openRelay()V

    return-void
.end method

.method public static synthetic $r8$lambda$wGdG8L9hvsRaxDacA7RySQOVNb0(Lio/github/leexeo/cage/space/SpaceActivity;)V
    .locals 0

    invoke-direct {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->pick()V

    return-void
.end method

.method static constructor <clinit>()V
    .locals 1

    .line 26
    invoke-static {}, Ljava/util/concurrent/Executors;->newSingleThreadExecutor()Ljava/util/concurrent/ExecutorService;

    move-result-object v0

    sput-object v0, Lio/github/leexeo/cage/space/SpaceActivity;->tasks:Ljava/util/concurrent/ExecutorService;

    return-void
.end method

.method public constructor <init>()V
    .locals 1

    .line 19
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V

    .line 35
    const-string v0, ""

    iput-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    return-void
.end method

.method private action(Ljava/lang/String;Ljava/lang/Runnable;)V
    .locals 2

    .line 90
    new-instance v0, Landroid/widget/Button;

    invoke-direct {v0, p0}, Landroid/widget/Button;-><init>(Landroid/content/Context;)V

    .line 91
    const/4 v1, 0x0

    invoke-virtual {v0, v1}, Landroid/widget/Button;->setAllCaps(Z)V

    .line 92
    invoke-virtual {v0, p1}, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V

    .line 93
    iget-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->content:Landroid/widget/LinearLayout;

    invoke-virtual {p1, v0}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    .line 94
    new-instance p1, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda1;

    invoke-direct {p1, p0, p2}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda1;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;Ljava/lang/Runnable;)V

    invoke-virtual {v0, p1}, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    .line 95
    return-void
.end method

.method private bundleApk(Ljava/lang/String;)Z
    .locals 2

    .line 413
    const/16 v0, 0x2f

    invoke-virtual {p1, v0}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v0

    const/4 v1, 0x1

    add-int/2addr v0, v1

    invoke-virtual {p1, v0}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p1

    sget-object v0, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p1, v0}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p1

    .line 414
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz v0, :cond_0

    const-string v0, "com\\.google\\.android\\.gms-[0-9]+\\.apk"

    invoke-virtual {p1, v0}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_0

    return v1

    .line 415
    :cond_0
    const-string v0, "googleservicesframework.apk"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_2

    const-string v0, "gmscore.apk"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_2

    const-string v0, "phonesky.apk"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_2

    .line 416
    const-string v0, "prebuiltgmscore.apk"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_2

    const-string v0, "com.google.android.gms.apk"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_2

    .line 417
    const-string v0, "com.google.android.gsf.apk"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_2

    const-string v0, "com.android.vending.apk"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_1

    goto :goto_0

    :cond_1
    const/4 v1, 0x0

    goto :goto_1

    :cond_2
    :goto_0
    nop

    .line 415
    :goto_1
    return v1
.end method

.method private checkNetwork()V
    .locals 5

    .line 105
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    if-nez v0, :cond_0

    return-void

    .line 106
    :cond_0
    const/4 v0, 0x1

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    .line 108
    :try_start_0
    const-string v0, "io.github.leexeo.cage.space.DemoNetworkCheck"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    const-string v1, "start"

    const-class v2, Landroid/app/Activity;

    const-class v3, Landroid/widget/TextView;

    const-class v4, Ljava/lang/Runnable;

    filled-new-array {v2, v3, v4}, [Ljava/lang/Class;

    move-result-object v2

    .line 109
    invoke-virtual {v0, v1, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    iget-object v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->status:Landroid/widget/TextView;

    new-instance v2, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda2;

    invoke-direct {v2, p0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda2;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;)V

    filled-new-array {p0, v1, v2}, [Ljava/lang/Object;

    move-result-object v1

    .line 110
    const/4 v2, 0x0

    invoke-virtual {v0, v2, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_0

    .line 114
    goto :goto_0

    .line 111
    :catch_0
    move-exception v0

    .line 112
    const/4 v0, 0x0

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    .line 113
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->status:Landroid/widget/TextView;

    const-string v1, "\u8fde\u63a5\u68c0\u67e5\u6682\u4e0d\u53ef\u7528\u3002"

    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 115
    :goto_0
    return-void
.end method

.method private static copy(Ljava/io/InputStream;Ljava/io/File;J)V
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 428
    if-eqz p0, :cond_2

    .line 429
    new-instance v0, Ljava/io/FileOutputStream;

    invoke-direct {v0, p1}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V

    .line 430
    const/high16 p1, 0x10000

    :try_start_0
    new-array p1, p1, [B

    .line 431
    const-wide/16 v1, 0x0

    .line 432
    :goto_0
    invoke-virtual {p0, p1}, Ljava/io/InputStream;->read([B)I

    move-result v3

    const/4 v4, -0x1

    if-eq v3, v4, :cond_1

    .line 433
    int-to-long v4, v3

    add-long/2addr v1, v4

    .line 434
    cmp-long v4, v1, p2

    if-gtz v4, :cond_0

    .line 435
    const/4 v4, 0x0

    invoke-virtual {v0, p1, v4, v3}, Ljava/io/OutputStream;->write([BII)V

    goto :goto_0

    .line 434
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u5b89\u88c5\u5305\u8d85\u8fc7\u7a7a\u95f4\u652f\u6301\u7684\u5927\u5c0f\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 437
    :cond_1
    invoke-virtual {v0}, Ljava/io/OutputStream;->close()V

    .line 438
    return-void

    .line 429
    :catchall_0
    move-exception p0

    :try_start_1
    invoke-virtual {v0}, Ljava/io/OutputStream;->close()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    goto :goto_1

    :catchall_1
    move-exception p1

    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_1
    throw p0

    .line 428
    :cond_2
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u6587\u4ef6\u63d0\u4f9b\u65b9\u672a\u8fd4\u56de\u5b89\u88c5\u5305\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private failed(Ljava/lang/String;I)V
    .locals 1

    .line 269
    new-instance v0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda5;

    invoke-direct {v0, p0, p2, p1}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda5;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;ILjava/lang/String;)V

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->runOnUiThread(Ljava/lang/Runnable;)V

    .line 278
    return-void
.end method

.method private header(Ljava/lang/String;)V
    .locals 3

    .line 98
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->content:Landroid/widget/LinearLayout;

    invoke-virtual {v0}, Landroid/widget/LinearLayout;->removeAllViews()V

    .line 99
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    if-eqz v0, :cond_0

    const-string v0, "Cage \u00b7 \u8f7b\u91cf DEMO"

    goto :goto_0

    :cond_0
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz v0, :cond_1

    const-string v0, "Cage \u00b7 microG \u7a7a\u95f4"

    goto :goto_0

    :cond_1
    const-string v0, "Google \u5957\u4ef6"

    :goto_0
    const/16 v1, 0x1a

    invoke-direct {p0, v0, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->line(Ljava/lang/String;I)Landroid/widget/TextView;

    move-result-object v0

    sget-object v1, Landroid/graphics/Typeface;->DEFAULT:Landroid/graphics/Typeface;

    const/4 v2, 0x1

    invoke-virtual {v0, v1, v2}, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;I)V

    .line 100
    const/16 v0, 0x10

    invoke-direct {p0, p1, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->line(Ljava/lang/String;I)Landroid/widget/TextView;

    move-result-object p1

    iput-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->status:Landroid/widget/TextView;

    .line 101
    iget-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->status:Landroid/widget/TextView;

    invoke-virtual {p1, v2}, Landroid/widget/TextView;->setAccessibilityLiveRegion(I)V

    .line 102
    return-void
.end method

.method private importClaude(Landroid/net/Uri;)V
    .locals 2

    .line 295
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    if-eqz v0, :cond_1

    if-eqz p1, :cond_1

    const-string v0, "content"

    invoke-virtual {p1}, Landroid/net/Uri;->getScheme()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_0

    goto :goto_0

    .line 296
    :cond_0
    iget v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->refreshGeneration:I

    const/4 v1, 0x1

    add-int/2addr v0, v1

    iput v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->refreshGeneration:I

    .line 297
    iput-boolean v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    .line 298
    const-string v0, "\u6b63\u5728\u9a8c\u8bc1 Claude \u539f\u7248\u5206\u5305\u5e76\u5bfc\u5165\u7a7a\u95f4\u2026"

    invoke-direct {p0, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->header(Ljava/lang/String;)V

    .line 299
    sget-object v0, Lio/github/leexeo/cage/space/SpaceActivity;->tasks:Ljava/util/concurrent/ExecutorService;

    new-instance v1, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda20;

    invoke-direct {v1, p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda20;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;Landroid/net/Uri;)V

    invoke-interface {v0, v1}, Ljava/util/concurrent/ExecutorService;->execute(Ljava/lang/Runnable;)V

    .line 322
    return-void

    .line 295
    :cond_1
    :goto_0
    return-void
.end method

.method private importFiles(Ljava/util/Set;)Ljava/lang/String;
    .locals 13
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/util/Set<",
            "Landroid/net/Uri;",
            ">;)",
            "Ljava/lang/String;"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 372
    const-string v0, ".apk"

    invoke-interface {p1}, Ljava/util/Set;->size()I

    move-result v1

    iget-boolean v2, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz v2, :cond_0

    const/4 v2, 0x2

    goto :goto_0

    :cond_0
    const/4 v2, 0x3

    :goto_0
    if-le v1, v2, :cond_2

    new-instance p1, Ljava/io/IOException;

    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz v0, :cond_1

    .line 373
    const-string v0, "\u8bf7\u9009\u62e9\u5957\u4ef6 ZIP \u6216\u6700\u591a\u4e24\u4e2a\u5b8c\u6574 APK\u3002"

    goto :goto_1

    :cond_1
    const-string v0, "\u8bf7\u9009\u62e9\u4e00\u4e2a\u5957\u4ef6 ZIP \u6216\u6700\u591a\u4e09\u4e2a\u5b8c\u6574 APK\u3002"

    :goto_1
    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 374
    :cond_2
    new-instance v1, Lio/github/leexeo/cage/space/SpacePackages;

    invoke-direct {v1, p0}, Lio/github/leexeo/cage/space/SpacePackages;-><init>(Landroid/content/Context;)V

    .line 375
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->getCacheDir()Ljava/io/File;

    move-result-object v2

    invoke-virtual {v2}, Ljava/io/File;->toPath()Ljava/nio/file/Path;

    move-result-object v2

    const-string v3, "google-import-"

    const/4 v4, 0x0

    new-array v5, v4, [Ljava/nio/file/attribute/FileAttribute;

    invoke-static {v2, v3, v5}, Ljava/nio/file/Files;->createTempDirectory(Ljava/nio/file/Path;Ljava/lang/String;[Ljava/nio/file/attribute/FileAttribute;)Ljava/nio/file/Path;

    move-result-object v2

    invoke-interface {v2}, Ljava/nio/file/Path;->toFile()Ljava/io/File;

    move-result-object v2

    .line 376
    new-instance v3, Ljava/util/HashMap;

    invoke-direct {v3}, Ljava/util/HashMap;-><init>()V

    .line 377
    new-instance v5, Ljava/util/HashMap;

    invoke-direct {v5}, Ljava/util/HashMap;-><init>()V

    .line 379
    :try_start_0
    invoke-interface {p1}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    move-result-object p1

    :goto_2
    invoke-interface {p1}, Ljava/util/Iterator;->hasNext()Z

    move-result v6

    if-eqz v6, :cond_d

    invoke-interface {p1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v6

    check-cast v6, Landroid/net/Uri;

    .line 380
    if-eqz v6, :cond_c

    const-string v7, "content"

    invoke-virtual {v6}, Landroid/net/Uri;->getScheme()Ljava/lang/String;

    move-result-object v8

    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v7

    if-eqz v7, :cond_c

    .line 381
    const-string v7, "selection-"

    invoke-static {v7, v0, v2}, Ljava/io/File;->createTempFile(Ljava/lang/String;Ljava/lang/String;Ljava/io/File;)Ljava/io/File;

    move-result-object v7

    .line 382
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->getContentResolver()Landroid/content/ContentResolver;

    move-result-object v8

    invoke-virtual {v8, v6}, Landroid/content/ContentResolver;->openInputStream(Landroid/net/Uri;)Ljava/io/InputStream;

    move-result-object v6
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_6

    const-wide/32 v8, 0x40000000

    :try_start_1
    invoke-static {v6, v7, v8, v9}, Lio/github/leexeo/cage/space/SpaceActivity;->copy(Ljava/io/InputStream;Ljava/io/File;J)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_4

    if-eqz v6, :cond_3

    :try_start_2
    invoke-virtual {v6}, Ljava/io/InputStream;->close()V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_6

    .line 383
    :cond_3
    :try_start_3
    new-instance v6, Ljava/util/zip/ZipFile;

    invoke-direct {v6, v7}, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File;)V
    :try_end_3
    .catch Ljava/util/zip/ZipException; {:try_start_3 .. :try_end_3} :catch_0
    .catchall {:try_start_3 .. :try_end_3} :catchall_6

    .line 384
    :try_start_4
    const-string v8, "AndroidManifest.xml"

    invoke-virtual {v6, v8}, Ljava/util/zip/ZipFile;->getEntry(Ljava/lang/String;)Ljava/util/zip/ZipEntry;

    move-result-object v8

    if-eqz v8, :cond_4

    .line 385
    invoke-direct {p0, v7, v3, v5}, Lio/github/leexeo/cage/space/SpaceActivity;->stage(Ljava/io/File;Ljava/util/Map;Ljava/util/Map;)V
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_2

    .line 398
    :try_start_5
    invoke-virtual {v6}, Ljava/util/zip/ZipFile;->close()V
    :try_end_5
    .catch Ljava/util/zip/ZipException; {:try_start_5 .. :try_end_5} :catch_0
    .catchall {:try_start_5 .. :try_end_5} :catchall_6

    .line 386
    goto :goto_2

    .line 388
    :cond_4
    :try_start_6
    invoke-interface {v3}, Ljava/util/Map;->size()I

    move-result v7

    .line 389
    invoke-virtual {v6}, Ljava/util/zip/ZipFile;->entries()Ljava/util/Enumeration;

    move-result-object v8

    .line 390
    :cond_5
    :goto_3
    invoke-interface {v8}, Ljava/util/Enumeration;->hasMoreElements()Z

    move-result v9

    if-eqz v9, :cond_9

    .line 391
    invoke-interface {v8}, Ljava/util/Enumeration;->nextElement()Ljava/lang/Object;

    move-result-object v9

    check-cast v9, Ljava/util/zip/ZipEntry;

    .line 392
    invoke-virtual {v9}, Ljava/util/zip/ZipEntry;->isDirectory()Z

    move-result v10

    if-nez v10, :cond_5

    invoke-virtual {v9}, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;

    move-result-object v10

    invoke-direct {p0, v10}, Lio/github/leexeo/cage/space/SpaceActivity;->bundleApk(Ljava/lang/String;)Z

    move-result v10

    if-nez v10, :cond_6

    goto :goto_3

    .line 393
    :cond_6
    const-string v10, "component-"

    invoke-static {v10, v0, v2}, Ljava/io/File;->createTempFile(Ljava/lang/String;Ljava/lang/String;Ljava/io/File;)Ljava/io/File;

    move-result-object v10

    .line 394
    invoke-virtual {v6, v9}, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;

    move-result-object v9
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_2

    const-wide/32 v11, 0x20000000

    :try_start_7
    invoke-static {v9, v10, v11, v12}, Lio/github/leexeo/cage/space/SpaceActivity;->copy(Ljava/io/InputStream;Ljava/io/File;J)V
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_0

    if-eqz v9, :cond_7

    :try_start_8
    invoke-virtual {v9}, Ljava/io/InputStream;->close()V

    .line 395
    :cond_7
    invoke-direct {p0, v10, v3, v5}, Lio/github/leexeo/cage/space/SpaceActivity;->stage(Ljava/io/File;Ljava/util/Map;Ljava/util/Map;)V
    :try_end_8
    .catchall {:try_start_8 .. :try_end_8} :catchall_2

    .line 396
    goto :goto_3

    .line 394
    :catchall_0
    move-exception p1

    if-eqz v9, :cond_8

    :try_start_9
    invoke-virtual {v9}, Ljava/io/InputStream;->close()V
    :try_end_9
    .catchall {:try_start_9 .. :try_end_9} :catchall_1

    goto :goto_4

    :catchall_1
    move-exception v0

    :try_start_a
    invoke-virtual {p1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_8
    :goto_4
    throw p1

    .line 397
    :cond_9
    invoke-interface {v3}, Ljava/util/Map;->size()I

    move-result v8
    :try_end_a
    .catchall {:try_start_a .. :try_end_a} :catchall_2

    if-eq v8, v7, :cond_a

    .line 398
    :try_start_b
    invoke-virtual {v6}, Ljava/util/zip/ZipFile;->close()V
    :try_end_b
    .catch Ljava/util/zip/ZipException; {:try_start_b .. :try_end_b} :catch_0
    .catchall {:try_start_b .. :try_end_b} :catchall_6

    .line 399
    goto/16 :goto_2

    .line 397
    :cond_a
    :try_start_c
    new-instance p1, Ljava/io/IOException;

    const-string v0, "ZIP \u4e2d\u6ca1\u6709\u627e\u5230\u652f\u6301\u7684 Google \u7ec4\u4ef6 APK\u3002"

    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
    :try_end_c
    .catchall {:try_start_c .. :try_end_c} :catchall_2

    .line 383
    :catchall_2
    move-exception p1

    :try_start_d
    invoke-virtual {v6}, Ljava/util/zip/ZipFile;->close()V
    :try_end_d
    .catchall {:try_start_d .. :try_end_d} :catchall_3

    goto :goto_5

    :catchall_3
    move-exception v0

    :try_start_e
    invoke-virtual {p1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_5
    throw p1
    :try_end_e
    .catch Ljava/util/zip/ZipException; {:try_start_e .. :try_end_e} :catch_0
    .catchall {:try_start_e .. :try_end_e} :catchall_6

    .line 398
    :catch_0
    move-exception p1

    :try_start_f
    new-instance p1, Ljava/io/IOException;

    const-string v0, "\u8bf7\u9009\u62e9\u5b8c\u6574\u7684 APK \u6216\u5957\u4ef6 ZIP\u3002"

    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
    :try_end_f
    .catchall {:try_start_f .. :try_end_f} :catchall_6

    .line 382
    :catchall_4
    move-exception p1

    if-eqz v6, :cond_b

    :try_start_10
    invoke-virtual {v6}, Ljava/io/InputStream;->close()V
    :try_end_10
    .catchall {:try_start_10 .. :try_end_10} :catchall_5

    goto :goto_6

    :catchall_5
    move-exception v0

    :try_start_11
    invoke-virtual {p1, v0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_b
    :goto_6
    throw p1

    .line 380
    :cond_c
    new-instance p1, Ljava/io/IOException;

    const-string v0, "\u65e0\u6cd5\u8bfb\u53d6\u6240\u9009\u6587\u4ef6\u3002"

    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 401
    :cond_d
    iget-boolean p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz p1, :cond_e

    sget-object p1, Lio/github/leexeo/cage/space/SpacePackages;->MICROG:[Ljava/lang/String;

    goto :goto_7

    :cond_e
    sget-object p1, Lio/github/leexeo/cage/space/SpacePackages;->GOOGLE:[Ljava/lang/String;

    :goto_7
    array-length v0, p1

    move v6, v4

    :goto_8
    if-ge v6, v0, :cond_10

    aget-object v7, p1, v6

    .line 402
    invoke-interface {v3, v7}, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z

    move-result v8

    if-eqz v8, :cond_f

    invoke-interface {v3, v7}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v8

    check-cast v8, Ljava/io/File;

    invoke-interface {v5, v7}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v7

    check-cast v7, Landroid/content/pm/PackageInfo;

    invoke-virtual {v1, v8, v7}, Lio/github/leexeo/cage/space/SpacePackages;->install(Ljava/io/File;Landroid/content/pm/PackageInfo;)V

    .line 401
    :cond_f
    add-int/lit8 v6, v6, 0x1

    goto :goto_8

    .line 404
    :cond_10
    const-string p1, "\u5df2\u5bfc\u5165\u6240\u9009\u7ec4\u4ef6\u3002"
    :try_end_11
    .catchall {:try_start_11 .. :try_end_11} :catchall_6

    .line 406
    invoke-virtual {v2}, Ljava/io/File;->listFiles()[Ljava/io/File;

    move-result-object v0

    .line 407
    if-eqz v0, :cond_11

    array-length v1, v0

    :goto_9
    if-ge v4, v1, :cond_11

    aget-object v3, v0, v4

    invoke-virtual {v3}, Ljava/io/File;->delete()Z

    add-int/lit8 v4, v4, 0x1

    goto :goto_9

    .line 408
    :cond_11
    invoke-virtual {v2}, Ljava/io/File;->delete()Z

    .line 404
    return-object p1

    .line 406
    :catchall_6
    move-exception p1

    invoke-virtual {v2}, Ljava/io/File;->listFiles()[Ljava/io/File;

    move-result-object v0

    .line 407
    if-eqz v0, :cond_12

    array-length v1, v0

    :goto_a
    if-ge v4, v1, :cond_12

    aget-object v3, v0, v4

    invoke-virtual {v3}, Ljava/io/File;->delete()Z

    add-int/lit8 v4, v4, 0x1

    goto :goto_a

    .line 408
    :cond_12
    invoke-virtual {v2}, Ljava/io/File;->delete()Z

    .line 409
    throw p1
.end method

.method private label(Ljava/lang/String;)Ljava/lang/String;
    .locals 1

    .line 213
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz v0, :cond_0

    const-string v0, "com.google.android.gms"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_0

    const-string p1, "microG Services"

    goto :goto_0

    :cond_0
    invoke-static {p1}, Lio/github/leexeo/cage/space/SpacePackages;->label(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    :goto_0
    return-object p1
.end method

.method private line(Ljava/lang/String;I)Landroid/widget/TextView;
    .locals 1

    .line 81
    new-instance v0, Landroid/widget/TextView;

    invoke-direct {v0, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V

    .line 82
    invoke-virtual {v0, p1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 83
    int-to-float p1, p2

    invoke-virtual {v0, p1}, Landroid/widget/TextView;->setTextSize(F)V

    .line 84
    const/4 p1, 0x0

    const/16 p2, 0xc

    invoke-virtual {v0, p1, p2, p1, p2}, Landroid/widget/TextView;->setPadding(IIII)V

    .line 85
    iget-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->content:Landroid/widget/LinearLayout;

    invoke-virtual {p1, v0}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    .line 86
    return-object v0
.end method

.method private open(Ljava/lang/String;Z)V
    .locals 3

    invoke-static {p0}, Lio/github/leexeo/cage/space/SharedGateway;->ready(Landroid/content/Context;)Z

    move-result v0

    if-eqz v0, :recovery_gateway_missing

    invoke-direct {p0, p1, p2}, Lio/github/leexeo/cage/space/SpaceActivity;->openReady(Ljava/lang/String;Z)V

    return-void

    :recovery_gateway_missing
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->status:Landroid/widget/TextView;

    const-string v1, "\u8bf7\u5148\u4fdd\u6301\u5df2\u9a8c\u8bc1\u7684\u7f51\u5173\u8fde\u63a5\uff0c\u5e76\u5f00\u542f\u59cb\u7ec8\u5f00\u542f VPN \u548c\u65ad\u7f51\u4fdd\u62a4\u3002"

    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    return-void

.end method

.method private openReady(Ljava/lang/String;Z)V
    .locals 3

    .line 248
    const/4 v0, 0x1

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    .line 249
    const/4 v0, 0x0

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->launchRequested:Z

    .line 250
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->status:Landroid/widget/TextView;

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "\u6b63\u5728\u6253\u5f00"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-direct {p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->label(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, "\u2026"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 251
    sget-object v0, Lio/github/leexeo/cage/space/SpaceActivity;->tasks:Ljava/util/concurrent/ExecutorService;

    new-instance v1, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda8;

    invoke-direct {v1, p0, p1, p2}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda8;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;Ljava/lang/String;Z)V

    invoke-interface {v0, v1}, Ljava/util/concurrent/ExecutorService;->execute(Ljava/lang/Runnable;)V

    .line 266
    return-void
.end method

.method private openRelay()V
    .locals 3

    .line 218
    :try_start_0
    new-instance v0, Landroid/content/Intent;

    invoke-direct {v0}, Landroid/content/Intent;-><init>()V

    iget-boolean v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    if-eqz v1, :cond_0

    const-string v1, "io.github.leexeo.cage.microdemo"

    goto :goto_0

    :cond_0
    const-string v1, "io.github.leexeo.cage.microcore"

    :goto_0
    const-string v2, "io.github.leexeo.cage.localcore.CoreActivity"

    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->setClassName(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;

    move-result-object v0

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->startActivity(Landroid/content/Intent;)V
    :try_end_0
    .catch Landroid/content/ActivityNotFoundException; {:try_start_0 .. :try_end_0} :catch_0

    .line 222
    goto :goto_1

    .line 220
    :catch_0
    move-exception v0

    .line 221
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->status:Landroid/widget/TextView;

    const-string v1, "\u8bf7\u5148\u5b89\u88c5\u914d\u5957\u7684 microG \u7a7a\u95f4\u4ee3\u7406\u52a9\u624b\u3002"

    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 223
    :goto_1
    return-void
.end method

.method private pick()V
    .locals 3

    .line 281
    new-instance v0, Landroid/content/Intent;

    const-string v1, "android.intent.action.OPEN_DOCUMENT"

    invoke-direct {v0, v1}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V

    const-string v1, "android.intent.category.OPENABLE"

    invoke-virtual {v0, v1}, Landroid/content/Intent;->addCategory(Ljava/lang/String;)Landroid/content/Intent;

    move-result-object v0

    .line 282
    const-string v1, "*/*"

    invoke-virtual {v0, v1}, Landroid/content/Intent;->setType(Ljava/lang/String;)Landroid/content/Intent;

    move-result-object v0

    const-string v1, "android.intent.extra.ALLOW_MULTIPLE"

    const/4 v2, 0x1

    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Z)Landroid/content/Intent;

    move-result-object v0

    .line 283
    :try_start_0
    invoke-virtual {p0, v0, v2}, Lio/github/leexeo/cage/space/SpaceActivity;->startActivityForResult(Landroid/content/Intent;I)V
    :try_end_0
    .catch Landroid/content/ActivityNotFoundException; {:try_start_0 .. :try_end_0} :catch_0

    .line 284
    goto :goto_0

    :catch_0
    move-exception v0

    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->status:Landroid/widget/TextView;

    const-string v1, "\u624b\u673a\u4e0a\u6ca1\u6709\u53ef\u7528\u7684\u6587\u4ef6\u9009\u62e9\u5668\u3002"

    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 285
    :goto_0
    return-void
.end method

.method private pickClaude()V
    .locals 2

    .line 288
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    if-nez v0, :cond_0

    return-void

    .line 289
    :cond_0
    new-instance v0, Landroid/content/Intent;

    const-string v1, "android.intent.action.OPEN_DOCUMENT"

    invoke-direct {v0, v1}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V

    const-string v1, "android.intent.category.OPENABLE"

    invoke-virtual {v0, v1}, Landroid/content/Intent;->addCategory(Ljava/lang/String;)Landroid/content/Intent;

    move-result-object v0

    const-string v1, "*/*"

    invoke-virtual {v0, v1}, Landroid/content/Intent;->setType(Ljava/lang/String;)Landroid/content/Intent;

    move-result-object v0

    .line 290
    const/4 v1, 0x3

    :try_start_0
    invoke-virtual {p0, v0, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->startActivityForResult(Landroid/content/Intent;I)V
    :try_end_0
    .catch Landroid/content/ActivityNotFoundException; {:try_start_0 .. :try_end_0} :catch_0

    .line 291
    goto :goto_0

    :catch_0
    move-exception v0

    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->status:Landroid/widget/TextView;

    const-string v1, "\u624b\u673a\u4e0a\u6ca1\u6709\u53ef\u7528\u7684\u6587\u4ef6\u9009\u62e9\u5668\u3002"

    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 292
    :goto_0
    return-void
.end method

.method private prepare(Ljava/lang/String;)V
    .locals 3

    .line 203
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz v0, :cond_1

    .line 204
    const-string v0, "OPEN_CLAUDE"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    .line 205
    if-eqz v0, :cond_0

    const-string v0, "com.anthropic.claude"

    goto :goto_0

    :cond_0
    const-string v0, "com.android.vending"

    :goto_0
    const-string v1, "INSTALL_CLAUDE"

    invoke-virtual {v1, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    invoke-direct {p0, v0, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->open(Ljava/lang/String;Z)V

    .line 206
    return-void

    .line 208
    :cond_1
    new-instance v0, Landroid/content/Intent;

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "io.github.leexeo.cage.space."

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {v0, p1}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V

    const/4 p1, -0x1

    invoke-virtual {p0, p1, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->setResult(ILandroid/content/Intent;)V

    .line 209
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->finish()V

    .line 210
    return-void
.end method

.method private refresh()V
    .locals 3

    .line 118
    iget v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->refreshGeneration:I

    const/4 v1, 0x1

    add-int/2addr v0, v1

    iput v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->refreshGeneration:I

    .line 119
    iput-boolean v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    .line 120
    const-string v1, "\u6b63\u5728\u8bfb\u53d6\u7a7a\u95f4\u91cc\u7684\u5e94\u7528\u2026"

    invoke-direct {p0, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->header(Ljava/lang/String;)V

    .line 121
    sget-object v1, Lio/github/leexeo/cage/space/SpaceActivity;->tasks:Ljava/util/concurrent/ExecutorService;

    new-instance v2, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda3;

    invoke-direct {v2, p0, v0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda3;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;I)V

    invoke-interface {v1, v2}, Ljava/util/concurrent/ExecutorService;->execute(Ljava/lang/Runnable;)V

    .line 198
    return-void
.end method

.method private stage(Ljava/io/File;Ljava/util/Map;Ljava/util/Map;)V
    .locals 2
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/io/File;",
            "Ljava/util/Map<",
            "Ljava/lang/String;",
            "Ljava/io/File;",
            ">;",
            "Ljava/util/Map<",
            "Ljava/lang/String;",
            "Landroid/content/pm/PackageInfo;",
            ">;)V"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 422
    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/SpacePackages;->inspect(Landroid/content/Context;Ljava/io/File;)Landroid/content/pm/PackageInfo;

    move-result-object v0

    .line 423
    iget-object v1, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-interface {p2, v1, p1}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    if-nez p1, :cond_0

    .line 424
    iget-object p1, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-interface {p3, p1, v0}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 425
    return-void

    .line 423
    :cond_0
    new-instance p1, Ljava/io/IOException;

    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string p3, "\u9009\u62e9\u4e2d\u6709\u4e24\u4efd"

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    iget-object p3, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-static {p3}, Lio/github/leexeo/cage/space/SpacePackages;->label(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p3

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    const-string p3, "\u3002"

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    invoke-direct {p1, p2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
.end method


# virtual methods
.method synthetic lambda$action$0$io-github-leexeo-cage-space-SpaceActivity(Ljava/lang/Runnable;Landroid/view/View;)V
    .locals 0

    .line 94
    iget-boolean p2, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    if-nez p2, :cond_0

    invoke-interface {p1}, Ljava/lang/Runnable;->run()V

    :cond_0
    return-void
.end method

.method synthetic lambda$checkNetwork$1$io-github-leexeo-cage-space-SpaceActivity()V
    .locals 1

    .line 110
    const/4 v0, 0x0

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    return-void
.end method

.method synthetic lambda$failed$11$io-github-leexeo-cage-space-SpaceActivity()V
    .locals 1

    .line 275
    const-string v0, ""

    iput-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    invoke-direct {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->refresh()V

    return-void
.end method

.method synthetic lambda$failed$12$io-github-leexeo-cage-space-SpaceActivity(ILjava/lang/String;)V
    .locals 1

    .line 270
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->isDestroyed()Z

    move-result v0

    if-nez v0, :cond_1

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->isFinishing()Z

    move-result v0

    if-nez v0, :cond_1

    if-ltz p1, :cond_0

    iget v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->refreshGeneration:I

    if-eq p1, v0, :cond_0

    goto :goto_0

    .line 271
    :cond_0
    const/4 p1, 0x0

    iput-boolean p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    .line 272
    iput-boolean p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->launchRequested:Z

    .line 273
    iput-object p2, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    .line 274
    invoke-direct {p0, p2}, Lio/github/leexeo/cage/space/SpaceActivity;->header(Ljava/lang/String;)V

    .line 275
    new-instance p1, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda18;

    invoke-direct {p1, p0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda18;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;)V

    const-string p2, "\u91cd\u65b0\u8bfb\u53d6\u7a7a\u95f4"

    invoke-direct {p0, p2, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->action(Ljava/lang/String;Ljava/lang/Runnable;)V

    .line 276
    new-instance p1, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda19;

    invoke-direct {p1, p0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda19;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;)V

    const-string p2, "\u8fd4\u56de"

    invoke-direct {p0, p2, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->action(Ljava/lang/String;Ljava/lang/Runnable;)V

    .line 277
    return-void

    .line 270
    :cond_1
    :goto_0
    return-void
.end method

.method synthetic lambda$importClaude$13$io-github-leexeo-cage-space-SpaceActivity(Ljava/lang/String;)V
    .locals 1

    .line 315
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->isDestroyed()Z

    move-result v0

    if-nez v0, :cond_1

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->isFinishing()Z

    move-result v0

    if-eqz v0, :cond_0

    goto :goto_0

    .line 316
    :cond_0
    const/4 v0, 0x0

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    .line 317
    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->launchRequested:Z

    .line 318
    iput-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    .line 319
    invoke-direct {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->refresh()V

    .line 320
    return-void

    .line 315
    :cond_1
    :goto_0
    return-void
.end method

.method synthetic lambda$importClaude$14$io-github-leexeo-cage-space-SpaceActivity(Landroid/net/Uri;)V
    .locals 5

    .line 301
    nop

    .line 303
    const/4 v0, 0x0

    :try_start_0
    const-string v1, "claude-selection-"

    const-string v2, ".xapk"

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->getCacheDir()Ljava/io/File;

    move-result-object v3

    invoke-static {v1, v2, v3}, Ljava/io/File;->createTempFile(Ljava/lang/String;Ljava/lang/String;Ljava/io/File;)Ljava/io/File;

    move-result-object v1
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_1
    .catchall {:try_start_0 .. :try_end_0} :catchall_3

    .line 304
    :try_start_1
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->getContentResolver()Landroid/content/ContentResolver;

    move-result-object v2

    invoke-virtual {v2, p1}, Landroid/content/ContentResolver;->openInputStream(Landroid/net/Uri;)Ljava/io/InputStream;

    move-result-object p1
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_2

    const-wide/32 v2, 0x10000000

    :try_start_2
    invoke-static {p1, v1, v2, v3}, Lio/github/leexeo/cage/space/SpaceActivity;->copy(Ljava/io/InputStream;Ljava/io/File;J)V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    if-eqz p1, :cond_0

    :try_start_3
    invoke-virtual {p1}, Ljava/io/InputStream;->close()V

    .line 305
    :cond_0
    const-string p1, "io.github.leexeo.cage.space.ClaudeBundle"

    invoke-static {p1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p1

    const-string v2, "install"

    const-class v3, Landroid/content/Context;

    const-class v4, Ljava/io/File;

    filled-new-array {v3, v4}, [Ljava/lang/Class;

    move-result-object v3

    .line 306
    invoke-virtual {p1, v2, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p1

    filled-new-array {p0, v1}, [Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {p1, v0, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Ljava/lang/String;
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_0
    .catchall {:try_start_3 .. :try_end_3} :catchall_2

    .line 312
    if-eqz v1, :cond_4

    invoke-virtual {v1}, Ljava/io/File;->delete()Z

    goto :goto_4

    .line 304
    :catchall_0
    move-exception v0

    if-eqz p1, :cond_1

    :try_start_4
    invoke-virtual {p1}, Ljava/io/InputStream;->close()V
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_1

    goto :goto_0

    :catchall_1
    move-exception p1

    :try_start_5
    invoke-virtual {v0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_1
    :goto_0
    throw v0
    :try_end_5
    .catch Ljava/lang/Exception; {:try_start_5 .. :try_end_5} :catch_0
    .catchall {:try_start_5 .. :try_end_5} :catchall_2

    .line 312
    :catchall_2
    move-exception p1

    move-object v0, v1

    goto :goto_5

    .line 307
    :catch_0
    move-exception p1

    move-object v0, v1

    goto :goto_1

    .line 312
    :catchall_3
    move-exception p1

    goto :goto_5

    .line 307
    :catch_1
    move-exception p1

    .line 308
    :goto_1
    :try_start_6
    invoke-virtual {p1}, Ljava/lang/Exception;->getCause()Ljava/lang/Throwable;

    move-result-object v1

    if-nez v1, :cond_2

    goto :goto_2

    :cond_2
    invoke-virtual {p1}, Ljava/lang/Exception;->getCause()Ljava/lang/Throwable;

    move-result-object p1

    .line 309
    :goto_2
    const-string v1, "CageDemo"

    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "Claude bundle import failed: "

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-static {v1, v2}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 310
    instance-of v1, p1, Ljava/io/IOException;

    if-eqz v1, :cond_3

    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    move-result-object v1

    if-eqz v1, :cond_3

    .line 311
    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    move-result-object p1

    goto :goto_3

    :cond_3
    const-string p1, "Claude \u5206\u5305\u5bfc\u5165\u5931\u8d25\uff0c\u539f\u6709\u8d26\u53f7\u548c\u6570\u636e\u5df2\u4fdd\u7559\u3002"
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_3

    .line 312
    :goto_3
    if-eqz v0, :cond_4

    invoke-virtual {v0}, Ljava/io/File;->delete()Z

    .line 313
    :cond_4
    :goto_4
    nop

    .line 314
    new-instance v0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda21;

    invoke-direct {v0, p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda21;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;Ljava/lang/String;)V

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->runOnUiThread(Ljava/lang/Runnable;)V

    .line 321
    return-void

    .line 312
    :goto_5
    if-eqz v0, :cond_5

    invoke-virtual {v0}, Ljava/io/File;->delete()Z

    :cond_5
    throw p1
.end method

.method synthetic lambda$onActivityResult$15$io-github-leexeo-cage-space-SpaceActivity(ZLjava/lang/String;)V
    .locals 2

    .line 362
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->isDestroyed()Z

    move-result v0

    if-nez v0, :cond_3

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->isFinishing()Z

    move-result v0

    if-eqz v0, :cond_0

    goto :goto_0

    .line 363
    :cond_0
    const/4 v0, 0x0

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    .line 364
    if-eqz p1, :cond_1

    iget-boolean v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->launchRequested:Z

    if-eqz v1, :cond_1

    const-string p2, ""

    :cond_1
    iput-object p2, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    .line 365
    if-nez p1, :cond_2

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->launchRequested:Z

    .line 366
    :cond_2
    invoke-direct {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->refresh()V

    .line 367
    return-void

    .line 362
    :cond_3
    :goto_0
    return-void
.end method

.method synthetic lambda$onActivityResult$16$io-github-leexeo-cage-space-SpaceActivity(Ljava/util/LinkedHashSet;)V
    .locals 2

    .line 352
    nop

    .line 354
    const/4 v0, 0x0

    :try_start_0
    invoke-direct {p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->importFiles(Ljava/util/Set;)Ljava/lang/String;

    move-result-object p1
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_1
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 355
    nop

    .line 358
    const/4 v0, 0x1

    goto :goto_1

    :catch_0
    move-exception p1

    const-string p1, "\u5bfc\u5165\u4e2d\u65ad\uff0c\u8bf7\u91cd\u65b0\u8bfb\u53d6\u7a7a\u95f4\u540e\u91cd\u8bd5\u3002"

    goto :goto_1

    .line 357
    :catch_1
    move-exception p1

    invoke-virtual {p1}, Ljava/io/IOException;->getMessage()Ljava/lang/String;

    move-result-object v1

    if-nez v1, :cond_0

    const-string p1, "\u65e0\u6cd5\u8bfb\u53d6\u5b89\u88c5\u5305\uff0c\u8bf7\u91cd\u65b0\u9009\u62e9\u6587\u4ef6\u3002"

    goto :goto_0

    :cond_0
    invoke-virtual {p1}, Ljava/io/IOException;->getMessage()Ljava/lang/String;

    move-result-object p1

    .line 358
    :goto_0
    nop

    .line 359
    :goto_1
    nop

    .line 360
    nop

    .line 361
    new-instance v1, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda0;

    invoke-direct {v1, p0, v0, p1}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda0;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;ZLjava/lang/String;)V

    invoke-virtual {p0, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->runOnUiThread(Ljava/lang/Runnable;)V

    .line 368
    return-void
.end method

.method synthetic lambda$openReady$10$io-github-leexeo-cage-space-SpaceActivity(Ljava/lang/String;Z)V
    .locals 2

    .line 253
    :try_start_0
    new-instance v0, Lio/github/leexeo/cage/space/SpacePackages;

    invoke-direct {v0, p0}, Lio/github/leexeo/cage/space/SpacePackages;-><init>(Landroid/content/Context;)V

    .line 254
    invoke-virtual {v0, p1, p2}, Lio/github/leexeo/cage/space/SpacePackages;->open(Ljava/lang/String;Z)Z

    move-result p2

    if-eqz p2, :cond_0

    .line 255
    new-instance p2, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda4;

    invoke-direct {p2, p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda4;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;Ljava/lang/String;)V

    invoke-virtual {p0, p2}, Lio/github/leexeo/cage/space/SpaceActivity;->runOnUiThread(Ljava/lang/Runnable;)V

    .line 264
    goto :goto_0

    .line 254
    :cond_0
    new-instance p2, Ljava/io/IOException;

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u7a7a\u95f4\u5185\u6ca1\u6709\u53ef\u6253\u5f00\u7684"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-direct {p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->label(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, "\u3002"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-direct {p2, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p2
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 260
    :catch_0
    move-exception p2

    .line 261
    invoke-virtual {p2}, Ljava/lang/Exception;->getCause()Ljava/lang/Throwable;

    move-result-object v0

    if-eqz v0, :cond_1

    invoke-virtual {p2}, Ljava/lang/Exception;->getCause()Ljava/lang/Throwable;

    move-result-object p2

    .line 262
    :cond_1
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "Guest launch failed for "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, ": "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {p2}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object p2

    invoke-virtual {v0, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    const-string v0, "CageSpace"

    invoke-static {v0, p2}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 263
    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "\u7a7a\u95f4\u91cc\u7684"

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-direct {p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->label(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string p2, "\u672a\u80fd\u6253\u5f00\u3002"

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const/4 p2, -0x1

    invoke-direct {p0, p1, p2}, Lio/github/leexeo/cage/space/SpaceActivity;->failed(Ljava/lang/String;I)V

    .line 265
    :goto_0
    return-void
.end method

.method synthetic lambda$openReady$9$io-github-leexeo-cage-space-SpaceActivity(Ljava/lang/String;)V
    .locals 1

    .line 256
    const/4 v0, 0x0

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    .line 257
    const-string v0, ""

    iput-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    .line 258
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->isDestroyed()Z

    move-result v0

    if-nez v0, :cond_0

    const-string v0, "com.anthropic.claude"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_0

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->finish()V

    .line 259
    :cond_0
    return-void
.end method

.method synthetic lambda$refresh$2$io-github-leexeo-cage-space-SpaceActivity()V
    .locals 3

    .line 162
    :try_start_0
    new-instance v0, Landroid/content/Intent;

    invoke-direct {v0}, Landroid/content/Intent;-><init>()V

    const-string v1, "io.github.leexeo.cage.fullguest"

    const-string v2, "io.github.leexeo.cage.fullguest.GuestActivity"

    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->setClassName(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;

    move-result-object v0

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->startActivity(Landroid/content/Intent;)V
    :try_end_0
    .catch Landroid/content/ActivityNotFoundException; {:try_start_0 .. :try_end_0} :catch_0

    .line 166
    goto :goto_0

    .line 164
    :catch_0
    move-exception v0

    .line 165
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->status:Landroid/widget/TextView;

    const-string v1, "\u72ec\u7acb\u7f51\u5361\u7a7a\u95f4\u6682\u65f6\u65e0\u6cd5\u6253\u5f00\u3002"

    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 167
    :goto_0
    return-void
.end method

.method synthetic lambda$refresh$3$io-github-leexeo-cage-space-SpaceActivity()V
    .locals 3

    .line 168
    new-instance v0, Landroid/content/Intent;

    invoke-direct {v0}, Landroid/content/Intent;-><init>()V

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->getPackageName()Ljava/lang/String;

    move-result-object v1

    const-string v2, "top.niunaijun.blackboxa.view.main.WelcomeActivity"

    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->setClassName(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;

    move-result-object v0

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->startActivity(Landroid/content/Intent;)V

    return-void
.end method

.method synthetic lambda$refresh$4$io-github-leexeo-cage-space-SpaceActivity()V
    .locals 2

    .line 171
    const-string v0, "com.google.android.gms"

    const/4 v1, 0x0

    invoke-direct {p0, v0, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->open(Ljava/lang/String;Z)V

    return-void
.end method

.method synthetic lambda$refresh$5$io-github-leexeo-cage-space-SpaceActivity(Z)V
    .locals 0

    .line 184
    if-eqz p1, :cond_0

    const-string p1, "OPEN_CLAUDE"

    goto :goto_0

    :cond_0
    const-string p1, "INSTALL_CLAUDE"

    :goto_0
    invoke-direct {p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->prepare(Ljava/lang/String;)V

    return-void
.end method

.method synthetic lambda$refresh$6$io-github-leexeo-cage-space-SpaceActivity()V
    .locals 1

    .line 185
    const-string v0, "OPEN_STORE"

    invoke-direct {p0, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->prepare(Ljava/lang/String;)V

    return-void
.end method

.method synthetic lambda$refresh$7$io-github-leexeo-cage-space-SpaceActivity(IZLjava/util/List;ZZZZ)V
    .locals 2

    .line 151
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->isDestroyed()Z

    move-result v0

    if-nez v0, :cond_18

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->isFinishing()Z

    move-result v0

    if-nez v0, :cond_18

    iget v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->refreshGeneration:I

    if-eq p1, v0, :cond_0

    goto/16 :goto_a

    .line 152
    :cond_0
    const/4 p1, 0x0

    iput-boolean p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    .line 153
    if-eqz p2, :cond_2

    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz v0, :cond_1

    const-string v0, "microG \u548c Play \u5546\u5e97\u5df2\u5bfc\u5165\u3002"

    goto :goto_0

    :cond_1
    const-string v0, "\u4e09\u4e2a\u7ec4\u4ef6\u5df2\u5bfc\u5165\u672c\u673a\u7a7a\u95f4\u3002"

    goto :goto_0

    .line 154
    :cond_2
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz v0, :cond_3

    const-string v0, "\u8bf7\u5bfc\u5165 microG Services \u548c\u539f\u7248 Play \u5546\u5e97\u3002"

    goto :goto_0

    :cond_3
    const-string v0, "\u8bf7\u5bfc\u5165\u9002\u5408\u8fd9\u53f0\u624b\u673a\u7684 Google \u5957\u4ef6\u3002"

    .line 155
    :goto_0
    iget-object v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    invoke-virtual {v1}, Ljava/lang/String;->isEmpty()Z

    move-result v1

    if-eqz v1, :cond_4

    goto :goto_1

    :cond_4
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    :goto_1
    invoke-direct {p0, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->header(Ljava/lang/String;)V

    .line 156
    invoke-interface {p3}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object p3

    :goto_2
    invoke-interface {p3}, Ljava/util/Iterator;->hasNext()Z

    move-result v0

    const/16 v1, 0xf

    if-eqz v0, :cond_5

    invoke-interface {p3}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/lang/String;

    invoke-direct {p0, v0, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->line(Ljava/lang/String;I)Landroid/widget/TextView;

    goto :goto_2

    .line 157
    :cond_5
    if-eqz p2, :cond_6

    const-string p3, "\u66f4\u65b0 Google \u5957\u4ef6"

    goto :goto_3

    :cond_6
    const-string p3, "\u5bfc\u5165 Google \u5957\u4ef6"

    :goto_3
    new-instance v0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda9;

    invoke-direct {v0, p0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda9;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;)V

    invoke-direct {p0, p3, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->action(Ljava/lang/String;Ljava/lang/Runnable;)V

    .line 158
    iget-boolean p3, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz p3, :cond_8

    .line 159
    new-instance p3, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda10;

    invoke-direct {p3, p0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda10;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;)V

    const-string v0, "\u914d\u7f6e\u7a7a\u95f4\u4ee3\u7406"

    invoke-direct {p0, v0, p3}, Lio/github/leexeo/cage/space/SpaceActivity;->action(Ljava/lang/String;Ljava/lang/Runnable;)V

    .line 160
    if-eqz p4, :cond_7

    new-instance p3, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda11;

    invoke-direct {p3, p0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda11;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;)V

    const-string p4, "\u6253\u5f00\u72ec\u7acb\u7f51\u5361\u7a7a\u95f4"

    invoke-direct {p0, p4, p3}, Lio/github/leexeo/cage/space/SpaceActivity;->action(Ljava/lang/String;Ljava/lang/Runnable;)V

    .line 168
    :cond_7
    new-instance p3, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda12;

    invoke-direct {p3, p0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda12;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;)V

    const-string p4, "\u7a7a\u95f4\u8bbe\u7f6e"

    invoke-direct {p0, p4, p3}, Lio/github/leexeo/cage/space/SpaceActivity;->action(Ljava/lang/String;Ljava/lang/Runnable;)V

    .line 171
    :cond_8
    if-eqz p5, :cond_9

    new-instance p3, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda13;

    invoke-direct {p3, p0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda13;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;)V

    const-string p4, "\u6253\u5f00 microG \u8bbe\u7f6e"

    invoke-direct {p0, p4, p3}, Lio/github/leexeo/cage/space/SpaceActivity;->action(Ljava/lang/String;Ljava/lang/Runnable;)V

    .line 172
    :cond_9
    if-eqz p2, :cond_11

    .line 173
    if-eqz p6, :cond_a

    const-string p3, "Google \u767b\u5f55\u53d7\u9650\uff1a\u5728 Android 16 \u4e0a\uff0c\u6b64\u7a7a\u95f4\u6682\u65f6\u65e0\u6cd5\u6dfb\u52a0 Google \u8d26\u53f7\u3002"

    invoke-direct {p0, p3, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->line(Ljava/lang/String;I)Landroid/widget/TextView;

    .line 174
    :cond_a
    iget-boolean p3, p0, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    if-eqz p3, :cond_d

    .line 175
    const-string p3, "\u6253\u5f00\u5e94\u7528\u524d\u4f1a\u68c0\u67e5\u7f51\u5173\u548c\u7cfb\u7edf\u65ad\u7f51\u4fdd\u62a4\u3002\u6b64\u7f51\u5173\u4f1a\u63a5\u7ba1\u5168\u624b\u673a\u6d41\u91cf\u3002"

    invoke-direct {p0, p3, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->line(Ljava/lang/String;I)Landroid/widget/TextView;

    .line 176
    new-instance p3, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda14;

    invoke-direct {p3, p0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda14;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;)V

    const-string p4, "\u68c0\u67e5\u8fde\u63a5"

    invoke-direct {p0, p4, p3}, Lio/github/leexeo/cage/space/SpaceActivity;->action(Ljava/lang/String;Ljava/lang/Runnable;)V

    .line 177
    if-nez p7, :cond_b

    .line 178
    const-string p3, "\u652f\u6301\u901a\u8fc7 Play \u5546\u5e97\u5b89\u88c5 Claude\uff0c\u4e5f\u53ef\u5bfc\u5165\u539f\u7248\u5206\u5305\u3002"

    invoke-direct {p0, p3, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->line(Ljava/lang/String;I)Landroid/widget/TextView;

    .line 180
    :cond_b
    if-eqz p7, :cond_c

    const-string p3, "\u66f4\u65b0 Claude \u539f\u7248\u5206\u5305"

    goto :goto_4

    :cond_c
    const-string p3, "\u5bfc\u5165 Claude \u539f\u7248\u5206\u5305"

    :goto_4
    new-instance p4, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda15;

    invoke-direct {p4, p0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda15;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;)V

    invoke-direct {p0, p3, p4}, Lio/github/leexeo/cage/space/SpaceActivity;->action(Ljava/lang/String;Ljava/lang/Runnable;)V

    goto :goto_5

    .line 182
    :cond_d
    iget-boolean p3, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz p3, :cond_e

    const-string p3, "\u5f53\u524d\u7248\u672c\u7684\u767b\u5f55\u7f51\u9875\u65e0\u6cd5\u7ecf\u7a7a\u95f4\u4ee3\u7406\u8054\u7f51\uff0c\u6dfb\u52a0 Google \u8d26\u53f7\u4f1a\u505c\u5728\u8fde\u63a5\u9875\u3002"

    invoke-direct {p0, p3, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->line(Ljava/lang/String;I)Landroid/widget/TextView;

    .line 183
    :cond_e
    :goto_5
    if-eqz p7, :cond_f

    const-string p3, "\u6253\u5f00 Claude"

    goto :goto_6

    :cond_f
    iget-boolean p3, p0, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    if-eqz p3, :cond_10

    const-string p3, "\u67e5\u770b Claude \u5546\u5e97\u9875"

    goto :goto_6

    :cond_10
    const-string p3, "\u5728 Play \u5546\u5e97\u5b89\u88c5 Claude"

    :goto_6
    new-instance p4, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda16;

    invoke-direct {p4, p0, p7}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda16;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;Z)V

    invoke-direct {p0, p3, p4}, Lio/github/leexeo/cage/space/SpaceActivity;->action(Ljava/lang/String;Ljava/lang/Runnable;)V

    .line 185
    new-instance p3, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda17;

    invoke-direct {p3, p0}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda17;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;)V

    const-string p4, "\u6253\u5f00\u7a7a\u95f4\u91cc\u7684 Play \u5546\u5e97"

    invoke-direct {p0, p4, p3}, Lio/github/leexeo/cage/space/SpaceActivity;->action(Ljava/lang/String;Ljava/lang/Runnable;)V

    goto :goto_7

    .line 186
    :cond_11
    iget-boolean p3, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-nez p3, :cond_12

    const-string p3, "\u9009\u62e9\u4e09\u4e2a\u5b8c\u6574 APK\uff0c\u4e5f\u53ef\u4ee5\u9009\u62e9\u5305\u542b\u8fd9\u4e09\u4e2a\u7ec4\u4ef6\u7684\u5957\u4ef6 ZIP\u3002"

    const/16 p4, 0xe

    invoke-direct {p0, p3, p4}, Lio/github/leexeo/cage/space/SpaceActivity;->line(Ljava/lang/String;I)Landroid/widget/TextView;

    .line 187
    :cond_12
    :goto_7
    iget-object p3, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    invoke-virtual {p3}, Ljava/lang/String;->isEmpty()Z

    move-result p3

    if-eqz p3, :cond_17

    iget-boolean p3, p0, Lio/github/leexeo/cage/space/SpaceActivity;->launchRequested:Z

    if-eqz p3, :cond_17

    if-eqz p2, :cond_17

    iget-boolean p2, p0, Lio/github/leexeo/cage/space/SpaceActivity;->resumed:Z

    if-eqz p2, :cond_17

    .line 188
    iput-boolean p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->launchRequested:Z

    .line 189
    const/4 p2, 0x1

    const-string p3, "io.github.leexeo.cage.space.OPEN_CLAUDE"

    if-eqz p7, :cond_13

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->getIntent()Landroid/content/Intent;

    move-result-object p4

    invoke-virtual {p4}, Landroid/content/Intent;->getAction()Ljava/lang/String;

    move-result-object p4

    invoke-virtual {p3, p4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p4

    if-eqz p4, :cond_13

    move p4, p2

    goto :goto_8

    :cond_13
    move p4, p1

    .line 190
    :goto_8
    if-nez p4, :cond_14

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->getIntent()Landroid/content/Intent;

    move-result-object p5

    invoke-virtual {p5}, Landroid/content/Intent;->getAction()Ljava/lang/String;

    move-result-object p5

    const-string p7, "io.github.leexeo.cage.space.OPEN_STORE"

    invoke-virtual {p7, p5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p5

    if-nez p5, :cond_14

    move p1, p2

    .line 191
    :cond_14
    if-nez p4, :cond_15

    if-eqz p6, :cond_15

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->getIntent()Landroid/content/Intent;

    move-result-object p2

    invoke-virtual {p2}, Landroid/content/Intent;->getAction()Ljava/lang/String;

    move-result-object p2

    invoke-virtual {p3, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2

    if-nez p2, :cond_17

    .line 192
    :cond_15
    if-eqz p4, :cond_16

    const-string p2, "com.anthropic.claude"

    goto :goto_9

    :cond_16
    const-string p2, "com.android.vending"

    :goto_9
    invoke-direct {p0, p2, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->open(Ljava/lang/String;Z)V

    .line 195
    :cond_17
    return-void

    .line 151
    :cond_18
    :goto_a
    return-void
.end method

.method synthetic lambda$refresh$8$io-github-leexeo-cage-space-SpaceActivity(I)V
    .locals 16

    .line 123
    move-object/from16 v1, p0

    :try_start_0
    new-instance v0, Lio/github/leexeo/cage/space/SpacePackages;

    invoke-direct {v0, v1}, Lio/github/leexeo/cage/space/SpacePackages;-><init>(Landroid/content/Context;)V

    .line 124
    new-instance v4, Ljava/util/ArrayList;

    invoke-direct {v4}, Ljava/util/ArrayList;-><init>()V

    .line 125
    nop

    .line 126
    nop

    .line 127
    iget-boolean v2, v1, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz v2, :cond_0

    sget-object v2, Lio/github/leexeo/cage/space/SpacePackages;->MICROG:[Ljava/lang/String;

    goto :goto_0

    :cond_0
    sget-object v2, Lio/github/leexeo/cage/space/SpacePackages;->GOOGLE:[Ljava/lang/String;

    :goto_0
    array-length v3, v2
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    const/4 v6, 0x1

    move v8, v6

    const/4 v7, 0x0

    const/4 v9, 0x0

    :goto_1
    const-string v10, " \u00b7 "

    const-string v11, ""

    const-string v12, "\u5df2\u5bfc\u5165"

    if-ge v7, v3, :cond_5

    :try_start_1
    aget-object v13, v2, v7

    .line 128
    invoke-virtual {v0, v13}, Lio/github/leexeo/cage/space/SpacePackages;->installed(Ljava/lang/String;)Landroid/content/pm/PackageInfo;

    move-result-object v14

    .line 129
    invoke-virtual {v0, v14}, Lio/github/leexeo/cage/space/SpacePackages;->privateCopy(Landroid/content/pm/PackageInfo;)Z

    move-result v15

    .line 130
    const-string v5, "com.google.android.gms"

    invoke-virtual {v5, v13}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_1

    move v9, v15

    .line 131
    :cond_1
    and-int/2addr v8, v15

    .line 132
    if-eqz v15, :cond_3

    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v5, v12}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    iget-object v12, v14, Landroid/content/pm/PackageInfo;->versionName:Ljava/lang/String;

    if-nez v12, :cond_2

    :goto_2
    goto :goto_3

    :cond_2
    new-instance v11, Ljava/lang/StringBuilder;

    invoke-direct {v11}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v11, v10}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v10

    iget-object v11, v14, Landroid/content/pm/PackageInfo;->versionName:Ljava/lang/String;

    invoke-virtual {v10, v11}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v10

    invoke-virtual {v10}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v11

    goto :goto_2

    :goto_3
    invoke-virtual {v5, v11}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v5

    goto :goto_4

    .line 133
    :cond_3
    if-nez v14, :cond_4

    const-string v5, "\u5f85\u5bfc\u5165"

    goto :goto_4

    :cond_4
    const-string v5, "\u9700\u5bfc\u5165\u72ec\u7acb\u526f\u672c"

    .line 134
    :goto_4
    new-instance v10, Ljava/lang/StringBuilder;

    invoke-direct {v10}, Ljava/lang/StringBuilder;-><init>()V

    invoke-direct {v1, v13}, Lio/github/leexeo/cage/space/SpaceActivity;->label(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v11

    invoke-virtual {v10, v11}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v10

    const-string v11, "\u3000"

    invoke-virtual {v10, v11}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v10

    invoke-virtual {v10, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v5

    invoke-interface {v4, v5}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 127
    add-int/lit8 v7, v7, 0x1

    goto :goto_1

    .line 136
    :cond_5
    const-string v2, "com.anthropic.claude"

    invoke-virtual {v0, v2}, Lio/github/leexeo/cage/space/SpacePackages;->installed(Ljava/lang/String;)Landroid/content/pm/PackageInfo;

    move-result-object v0

    .line 137
    if-eqz v0, :cond_7

    iget-boolean v2, v1, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    if-eqz v2, :cond_6

    const-string v2, "io.github.leexeo.cage.space.GuestSplits"

    .line 138
    invoke-static {v2}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v2

    const-string v3, "ready"

    const-class v5, Landroid/content/Context;

    filled-new-array {v5}, [Ljava/lang/Class;

    move-result-object v5

    .line 139
    invoke-virtual {v2, v3, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    filled-new-array {v1}, [Ljava/lang/Object;

    move-result-object v3

    const/4 v5, 0x0

    invoke-virtual {v2, v5, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Ljava/lang/Boolean;

    .line 138
    invoke-virtual {v2}, Ljava/lang/Boolean;->booleanValue()Z

    move-result v2

    if-eqz v2, :cond_7

    :cond_6
    move v3, v8

    move v8, v6

    goto :goto_5

    :cond_7
    move v3, v8

    const/4 v8, 0x0

    .line 140
    :goto_5
    iget-boolean v2, v1, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    if-eqz v2, :cond_a

    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v5, "Claude\u3000"

    invoke-virtual {v2, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    if-eqz v8, :cond_9

    .line 141
    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v5, v12}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    iget-object v7, v0, Landroid/content/pm/PackageInfo;->versionName:Ljava/lang/String;

    if-nez v7, :cond_8

    :goto_6
    goto :goto_7

    :cond_8
    new-instance v7, Ljava/lang/StringBuilder;

    invoke-direct {v7}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v7, v10}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v7

    iget-object v0, v0, Landroid/content/pm/PackageInfo;->versionName:Ljava/lang/String;

    invoke-virtual {v7, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v11

    goto :goto_6

    :goto_7
    invoke-virtual {v5, v11}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    goto :goto_8

    .line 142
    :cond_9
    const-string v0, "\u5f85\u5bfc\u5165\u6216\u6062\u590d"

    :goto_8
    invoke-virtual {v2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    .line 140
    invoke-interface {v4, v0}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 143
    :cond_a
    nop

    .line 144
    iget-boolean v0, v1, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz v0, :cond_b

    if-eqz v9, :cond_b

    move v0, v6

    goto :goto_9

    :cond_b
    move v0, v6

    const/4 v6, 0x0

    .line 145
    :goto_9
    iget-boolean v2, v1, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-eqz v2, :cond_c

    iget-boolean v2, v1, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    if-nez v2, :cond_c

    invoke-virtual {v1}, Lio/github/leexeo/cage/space/SpaceActivity;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object v2

    invoke-virtual {v1}, Lio/github/leexeo/cage/space/SpaceActivity;->getPackageName()Ljava/lang/String;

    move-result-object v5

    const-string v7, "io.github.leexeo.cage.fullguest"

    invoke-virtual {v2, v5, v7}, Landroid/content/pm/PackageManager;->checkSignatures(Ljava/lang/String;Ljava/lang/String;)I

    move-result v2

    if-nez v2, :cond_c

    move v5, v0

    goto :goto_a

    :cond_c
    const/4 v5, 0x0

    .line 149
    :goto_a
    iget-boolean v2, v1, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    if-nez v2, :cond_d

    const-string v2, "com.google"

    invoke-static {v1, v2}, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes;->cannotAddAccount(Landroid/content/Context;Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_d

    move v7, v0

    goto :goto_b

    :cond_d
    const/4 v7, 0x0

    .line 150
    :goto_b
    new-instance v0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda6;

    move/from16 v2, p1

    invoke-direct/range {v0 .. v8}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda6;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;IZLjava/util/List;ZZZZ)V

    invoke-virtual {v1, v0}, Lio/github/leexeo/cage/space/SpaceActivity;->runOnUiThread(Ljava/lang/Runnable;)V
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 196
    goto :goto_c

    :catch_0
    move-exception v0

    const-string v0, "\u7a7a\u95f4\u670d\u52a1\u6682\u65f6\u65e0\u6cd5\u8bfb\u53d6\uff0c\u8bf7\u91cd\u8bd5\u3002"

    move/from16 v2, p1

    invoke-direct {v1, v0, v2}, Lio/github/leexeo/cage/space/SpaceActivity;->failed(Ljava/lang/String;I)V

    .line 197
    :goto_c
    return-void
.end method

.method protected onActivityResult(IILandroid/content/Intent;)V
    .locals 3

    .line 325
    invoke-super {p0, p1, p2, p3}, Landroid/app/Activity;->onActivityResult(IILandroid/content/Intent;)V

    .line 326
    const/4 v0, 0x3

    const/4 v1, -0x1

    if-ne p1, v0, :cond_1

    .line 327
    if-ne p2, v1, :cond_0

    if-eqz p3, :cond_0

    invoke-virtual {p3}, Landroid/content/Intent;->getData()Landroid/net/Uri;

    move-result-object p1

    invoke-direct {p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->importClaude(Landroid/net/Uri;)V

    .line 328
    :cond_0
    return-void

    .line 330
    :cond_1
    const/4 v0, 0x2

    const/4 v2, 0x0

    if-ne p1, v0, :cond_3

    .line 331
    iget-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->pendingPackage:Ljava/lang/String;

    .line 332
    const/4 v0, 0x0

    iput-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->pendingPackage:Ljava/lang/String;

    .line 333
    if-ne p2, v1, :cond_2

    if-eqz p3, :cond_2

    const-string p2, "protectionReady"

    invoke-virtual {p3, p2, v2}, Landroid/content/Intent;->getBooleanExtra(Ljava/lang/String;Z)Z

    move-result p2

    if-eqz p2, :cond_2

    if-eqz p1, :cond_2

    .line 334
    iget-boolean p2, p0, Lio/github/leexeo/cage/space/SpaceActivity;->pendingListing:Z

    invoke-direct {p0, p1, p2}, Lio/github/leexeo/cage/space/SpaceActivity;->openReady(Ljava/lang/String;Z)V

    goto :goto_0

    .line 336
    :cond_2
    const-string p1, "\u5c1a\u672a\u542f\u7528\u7f51\u5173\u548c\u7cfb\u7edf\u65ad\u7f51\u4fdd\u62a4\uff0c\u5e94\u7528\u672a\u542f\u52a8\u3002"

    iput-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    .line 337
    invoke-direct {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->refresh()V

    .line 339
    :goto_0
    return-void

    .line 341
    :cond_3
    const/4 v0, 0x1

    if-ne p1, v0, :cond_8

    if-ne p2, v1, :cond_8

    if-nez p3, :cond_4

    goto :goto_2

    .line 342
    :cond_4
    new-instance p1, Ljava/util/LinkedHashSet;

    invoke-direct {p1}, Ljava/util/LinkedHashSet;-><init>()V

    .line 343
    invoke-virtual {p3}, Landroid/content/Intent;->getData()Landroid/net/Uri;

    move-result-object p2

    if-eqz p2, :cond_5

    invoke-virtual {p3}, Landroid/content/Intent;->getData()Landroid/net/Uri;

    move-result-object p2

    invoke-virtual {p1, p2}, Ljava/util/LinkedHashSet;->add(Ljava/lang/Object;)Z

    .line 344
    :cond_5
    invoke-virtual {p3}, Landroid/content/Intent;->getClipData()Landroid/content/ClipData;

    move-result-object p2

    .line 345
    if-eqz p2, :cond_6

    :goto_1
    invoke-virtual {p2}, Landroid/content/ClipData;->getItemCount()I

    move-result p3

    if-ge v2, p3, :cond_6

    invoke-virtual {p2, v2}, Landroid/content/ClipData;->getItemAt(I)Landroid/content/ClipData$Item;

    move-result-object p3

    invoke-virtual {p3}, Landroid/content/ClipData$Item;->getUri()Landroid/net/Uri;

    move-result-object p3

    invoke-virtual {p1, p3}, Ljava/util/LinkedHashSet;->add(Ljava/lang/Object;)Z

    add-int/lit8 v2, v2, 0x1

    goto :goto_1

    .line 346
    :cond_6
    invoke-virtual {p1}, Ljava/util/LinkedHashSet;->isEmpty()Z

    move-result p2

    if-eqz p2, :cond_7

    return-void

    .line 347
    :cond_7
    iget p2, p0, Lio/github/leexeo/cage/space/SpaceActivity;->refreshGeneration:I

    add-int/2addr p2, v0

    iput p2, p0, Lio/github/leexeo/cage/space/SpaceActivity;->refreshGeneration:I

    .line 348
    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    .line 349
    const-string p2, "\u6b63\u5728\u68c0\u67e5\u5b89\u88c5\u5305\u5e76\u5bfc\u5165\u672c\u673a\u7a7a\u95f4\u2026"

    invoke-direct {p0, p2}, Lio/github/leexeo/cage/space/SpaceActivity;->header(Ljava/lang/String;)V

    .line 350
    sget-object p2, Lio/github/leexeo/cage/space/SpaceActivity;->tasks:Ljava/util/concurrent/ExecutorService;

    new-instance p3, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda7;

    invoke-direct {p3, p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda7;-><init>(Lio/github/leexeo/cage/space/SpaceActivity;Ljava/util/LinkedHashSet;)V

    invoke-interface {p2, p3}, Ljava/util/concurrent/ExecutorService;->execute(Ljava/lang/Runnable;)V

    .line 369
    return-void

    .line 341
    :cond_8
    :goto_2
    return-void
.end method

.method public onCreate(Landroid/os/Bundle;)V
    .locals 4

    .line 40
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

    .line 41
    invoke-static {p0}, Lio/github/leexeo/cage/space/SpacePackages;->microG(Landroid/content/Context;)Z

    move-result v0

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->microG:Z

    .line 42
    const-string v0, "top.niunaijun.microdem"

    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->getPackageName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    .line 43
    if-eqz p1, :cond_0

    .line 44
    const-string v0, "pendingPackage"

    invoke-virtual {p1, v0}, Landroid/os/Bundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    iput-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->pendingPackage:Ljava/lang/String;

    .line 45
    const-string v0, "pendingListing"

    invoke-virtual {p1, v0}, Landroid/os/Bundle;->getBoolean(Ljava/lang/String;)Z

    move-result v0

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->pendingListing:Z

    .line 47
    :cond_0
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->getIntent()Landroid/content/Intent;

    move-result-object v0

    invoke-virtual {v0}, Landroid/content/Intent;->getAction()Ljava/lang/String;

    move-result-object v0

    .line 48
    const-string v1, "io.github.leexeo.cage.space.OPEN_CLAUDE"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    const/4 v2, 0x1

    if-nez v1, :cond_2

    const-string v1, "io.github.leexeo.cage.space.OPEN_STORE"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_2

    .line 49
    const-string v1, "io.github.leexeo.cage.space.INSTALL_CLAUDE"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_1

    goto :goto_0

    :cond_1
    const/4 v1, 0x0

    goto :goto_1

    :cond_2
    :goto_0
    move v1, v2

    :goto_1
    iput-boolean v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->launchRequested:Z

    .line 50
    if-eqz p1, :cond_3

    const-string v1, "launch"

    invoke-virtual {p1, v1}, Landroid/os/Bundle;->getBoolean(Ljava/lang/String;)Z

    move-result v1

    iput-boolean v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->launchRequested:Z

    .line 51
    :cond_3
    if-eqz p1, :cond_4

    const-string v1, "notice"

    const-string v3, ""

    invoke-virtual {p1, v1, v3}, Landroid/os/Bundle;->getString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    iput-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    .line 52
    :cond_4
    new-instance p1, Landroid/widget/ScrollView;

    invoke-direct {p1, p0}, Landroid/widget/ScrollView;-><init>(Landroid/content/Context;)V

    .line 53
    invoke-virtual {p1, v2}, Landroid/widget/ScrollView;->setFitsSystemWindows(Z)V

    .line 54
    new-instance v1, Landroid/widget/LinearLayout;

    invoke-direct {v1, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V

    iput-object v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->content:Landroid/widget/LinearLayout;

    .line 55
    iget-object v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->content:Landroid/widget/LinearLayout;

    invoke-virtual {v1, v2}, Landroid/widget/LinearLayout;->setOrientation(I)V

    .line 56
    invoke-virtual {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->getResources()Landroid/content/res/Resources;

    move-result-object v1

    invoke-virtual {v1}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;

    move-result-object v1

    iget v1, v1, Landroid/util/DisplayMetrics;->density:F

    const/high16 v2, 0x41a00000    # 20.0f

    mul-float/2addr v1, v2

    invoke-static {v1}, Ljava/lang/Math;->round(F)I

    move-result v1

    .line 57
    iget-object v2, p0, Lio/github/leexeo/cage/space/SpaceActivity;->content:Landroid/widget/LinearLayout;

    invoke-virtual {v2, v1, v1, v1, v1}, Landroid/widget/LinearLayout;->setPadding(IIII)V

    .line 58
    iget-object v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->content:Landroid/widget/LinearLayout;

    invoke-virtual {p1, v1}, Landroid/widget/ScrollView;->addView(Landroid/view/View;)V

    .line 59
    invoke-virtual {p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->setContentView(Landroid/view/View;)V

    .line 60
    iget-boolean p1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->demo:Z

    if-eqz p1, :cond_5

    const-string p1, "io.github.leexeo.cage.space.CHECK_NETWORK"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_5

    .line 61
    const-string p1, "\u6b63\u5728\u68c0\u67e5\u65b0\u5efa HTTPS \u8fde\u63a5\u2026"

    invoke-direct {p0, p1}, Lio/github/leexeo/cage/space/SpaceActivity;->header(Ljava/lang/String;)V

    .line 62
    invoke-direct {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->checkNetwork()V

    .line 64
    :cond_5
    return-void
.end method

.method protected onPause()V
    .locals 1

    .line 200
    const/4 v0, 0x0

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->resumed:Z

    invoke-super {p0}, Landroid/app/Activity;->onPause()V

    return-void
.end method

.method protected onResume()V
    .locals 1

    .line 67
    invoke-super {p0}, Landroid/app/Activity;->onResume()V

    .line 68
    const/4 v0, 0x1

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->resumed:Z

    .line 69
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/SpaceActivity;->busy:Z

    if-nez v0, :cond_0

    invoke-direct {p0}, Lio/github/leexeo/cage/space/SpaceActivity;->refresh()V

    .line 70
    :cond_0
    return-void
.end method

.method protected onSaveInstanceState(Landroid/os/Bundle;)V
    .locals 2

    .line 73
    invoke-super {p0, p1}, Landroid/app/Activity;->onSaveInstanceState(Landroid/os/Bundle;)V

    .line 74
    const-string v0, "launch"

    iget-boolean v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->launchRequested:Z

    invoke-virtual {p1, v0, v1}, Landroid/os/Bundle;->putBoolean(Ljava/lang/String;Z)V

    .line 75
    const-string v0, "notice"

    iget-object v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->notice:Ljava/lang/String;

    invoke-virtual {p1, v0, v1}, Landroid/os/Bundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    .line 76
    const-string v0, "pendingPackage"

    iget-object v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->pendingPackage:Ljava/lang/String;

    invoke-virtual {p1, v0, v1}, Landroid/os/Bundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    .line 77
    const-string v0, "pendingListing"

    iget-boolean v1, p0, Lio/github/leexeo/cage/space/SpaceActivity;->pendingListing:Z

    invoke-virtual {p1, v0, v1}, Landroid/os/Bundle;->putBoolean(Ljava/lang/String;Z)V

    .line 78
    return-void
.end method
