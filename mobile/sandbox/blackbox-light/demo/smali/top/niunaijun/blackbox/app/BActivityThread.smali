.class public Ltop/niunaijun/blackbox/app/BActivityThread;
.super Ltop/niunaijun/blackbox/core/IBActivityThread$Stub;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;
    }
.end annotation


# static fields
.field static final synthetic $assertionsDisabled:Z = false

.field public static final TAG:Ljava/lang/String; = "BActivityThread"

.field private static final mConfigLock:Ljava/lang/Object;

.field private static sBActivityThread:Ltop/niunaijun/blackbox/app/BActivityThread;


# instance fields
.field private mAppConfig:Ltop/niunaijun/blackbox/entity/AppConfig;

.field private mBoundApplication:Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;

.field private final mH:Landroid/os/Handler;

.field private mInitialApplication:Landroid/app/Application;

.field private final mProviders:Ljava/util/List;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/List<",
            "Landroid/content/pm/ProviderInfo;",
            ">;"
        }
    .end annotation
.end field


# direct methods
.method static constructor <clinit>()V
    .locals 1

    .line 1
    new-instance v0, Ljava/lang/Object;

    .line 2
    .line 3
    invoke-direct {v0}, Ljava/lang/Object;-><init>()V

    .line 4
    .line 5
    .line 6
    sput-object v0, Ltop/niunaijun/blackbox/app/BActivityThread;->mConfigLock:Ljava/lang/Object;

    .line 7
    .line 8
    return-void
.end method

.method public constructor <init>()V
    .locals 1

    .line 1
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/IBActivityThread$Stub;-><init>()V

    .line 2
    .line 3
    .line 4
    new-instance v0, Ljava/util/ArrayList;

    .line 5
    .line 6
    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    .line 7
    .line 8
    .line 9
    iput-object v0, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mProviders:Ljava/util/List;

    .line 10
    .line 11
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->get()Ltop/niunaijun/blackbox/BlackBoxCore;

    .line 12
    .line 13
    .line 14
    move-result-object v0

    .line 15
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHandler()Landroid/os/Handler;

    .line 16
    .line 17
    .line 18
    move-result-object v0

    .line 19
    iput-object v0, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mH:Landroid/os/Handler;

    .line 20
    .line 21
    return-void
.end method

.method public static synthetic a(Ltop/niunaijun/blackbox/app/BActivityThread;Ltop/niunaijun/blackbox/entity/am/ReceiverData;)V
    .locals 0

    .line 1
    invoke-direct {p0, p1}, Ltop/niunaijun/blackbox/app/BActivityThread;->lambda$scheduleReceiver$3(Ltop/niunaijun/blackbox/entity/am/ReceiverData;)V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method private static applyGuestRegion(Landroid/content/Context;)V
    .locals 2

    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    move-result-object v0

    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    move-result v1

    invoke-static {v0, v1, p0}, Ltop/niunaijun/blackbox/region/GuestRegion;->bind(Landroid/content/Context;ILandroid/content/Context;)V

    invoke-static {v0, p0}, Lio/github/leexeo/cage/space/GuestNetwork;->bind(Landroid/content/Context;Landroid/content/Context;)V

    return-void
.end method

.method public static synthetic b(Landroid/content/Intent;Landroid/os/IBinder;)V
    .locals 0

    .line 1
    invoke-static {p0, p1}, Ltop/niunaijun/blackbox/app/BActivityThread;->lambda$handleNewIntent$2(Landroid/content/Intent;Landroid/os/IBinder;)V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method public static synthetic c(Ltop/niunaijun/blackbox/app/BActivityThread;Ljava/lang/String;Ljava/lang/String;Landroid/os/ConditionVariable;)V
    .locals 0

    .line 1
    invoke-direct {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/app/BActivityThread;->lambda$bindApplication$0(Ljava/lang/String;Ljava/lang/String;Landroid/os/ConditionVariable;)V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method private createApplication(Landroid/content/pm/ApplicationInfo;)Landroid/app/Application;
    .locals 2

    .line 1
    :try_start_0
    invoke-direct {p0, p1}, Ltop/niunaijun/blackbox/app/BActivityThread;->getClassLoader(Landroid/content/pm/ApplicationInfo;)Ljava/lang/ClassLoader;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    iget-object v1, p1, Landroid/content/pm/ApplicationInfo;->className:Ljava/lang/String;

    .line 6
    .line 7
    invoke-virtual {v0, v1}, Ljava/lang/ClassLoader;->loadClass(Ljava/lang/String;)Ljava/lang/Class;

    .line 8
    .line 9
    .line 10
    move-result-object v0

    .line 11
    invoke-virtual {v0}, Ljava/lang/Class;->newInstance()Ljava/lang/Object;

    .line 12
    .line 13
    .line 14
    move-result-object v0

    .line 15
    check-cast v0, Landroid/app/Application;

    .line 16
    .line 17
    invoke-direct {p0, v0, p1}, Ltop/niunaijun/blackbox/app/BActivityThread;->ensureApplicationBaseContext(Landroid/app/Application;Landroid/content/pm/ApplicationInfo;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 18
    .line 19
    .line 20
    return-object v0

    .line 21
    :catch_0
    move-exception p1

    .line 22
    const-string v0, "Error creating application: "

    .line 23
    .line 24
    const-string v1, "BActivityThread"

    .line 25
    .line 26
    invoke-static {v0, p1, v1}, Landroidx/fragment/app/x0;->k(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 27
    .line 28
    .line 29
    const/4 p1, 0x0

    .line 30
    return-object p1
.end method

.method private createApplicationWithFallback(Landroid/content/pm/ApplicationInfo;)Landroid/app/Application;
    .locals 4

    .line 1
    const-string v0, "BActivityThread"

    .line 2
    .line 3
    const-string v1, "Application created successfully: "

    .line 4
    .line 5
    :try_start_0
    invoke-direct {p0, p1}, Ltop/niunaijun/blackbox/app/BActivityThread;->createApplication(Landroid/content/pm/ApplicationInfo;)Landroid/app/Application;

    .line 6
    .line 7
    .line 8
    move-result-object v2

    .line 9
    if-eqz v2, :cond_0

    .line 10
    .line 11
    new-instance v3, Ljava/lang/StringBuilder;

    .line 12
    .line 13
    invoke-direct {v3, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 14
    .line 15
    .line 16
    iget-object v1, p1, Landroid/content/pm/ApplicationInfo;->className:Ljava/lang/String;

    .line 17
    .line 18
    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 19
    .line 20
    .line 21
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 22
    .line 23
    .line 24
    move-result-object v1

    .line 25
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 26
    .line 27
    .line 28
    return-object v2

    .line 29
    :catch_0
    move-exception v1

    .line 30
    const-string v2, "Failed to create application normally: "

    .line 31
    .line 32
    invoke-static {v2, v1, v0}, Landroidx/fragment/app/x0;->n(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 33
    .line 34
    .line 35
    :cond_0
    :try_start_1
    const-string v1, "Attempting fallback application creation"

    .line 36
    .line 37
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 38
    .line 39
    .line 40
    invoke-direct {p0, p1}, Ltop/niunaijun/blackbox/app/BActivityThread;->getClassLoader(Landroid/content/pm/ApplicationInfo;)Ljava/lang/ClassLoader;

    .line 41
    .line 42
    .line 43
    move-result-object v1

    .line 44
    if-nez v1, :cond_1

    .line 45
    .line 46
    const-string v1, "ClassLoader is null, using system class loader"

    .line 47
    .line 48
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 49
    .line 50
    .line 51
    invoke-static {}, Ljava/lang/ClassLoader;->getSystemClassLoader()Ljava/lang/ClassLoader;

    .line 52
    .line 53
    .line 54
    move-result-object v1

    .line 55
    goto :goto_0

    .line 56
    :catch_1
    move-exception v1

    .line 57
    goto :goto_1

    .line 58
    :cond_1
    :goto_0
    iget-object v2, p1, Landroid/content/pm/ApplicationInfo;->className:Ljava/lang/String;

    .line 59
    .line 60
    invoke-virtual {v1, v2}, Ljava/lang/ClassLoader;->loadClass(Ljava/lang/String;)Ljava/lang/Class;

    .line 61
    .line 62
    .line 63
    move-result-object v1

    .line 64
    invoke-virtual {v1}, Ljava/lang/Class;->newInstance()Ljava/lang/Object;

    .line 65
    .line 66
    .line 67
    move-result-object v1

    .line 68
    check-cast v1, Landroid/app/Application;

    .line 69
    .line 70
    invoke-direct {p0, v1, p1}, Ltop/niunaijun/blackbox/app/BActivityThread;->ensureApplicationBaseContext(Landroid/app/Application;Landroid/content/pm/ApplicationInfo;)V

    .line 71
    .line 72
    .line 73
    const-string v2, "Fallback application creation successful"

    .line 74
    .line 75
    invoke-static {v0, v2}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

    .line 76
    .line 77
    .line 78
    return-object v1

    .line 79
    :goto_1
    const-string v2, "Fallback application creation failed: "

    .line 80
    .line 81
    invoke-static {v2, v1, v0}, Landroidx/fragment/app/x0;->k(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 82
    .line 83
    .line 84
    :try_start_2
    const-string v1, "Creating minimal application wrapper"

    .line 85
    .line 86
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 87
    .line 88
    .line 89
    new-instance v1, Ltop/niunaijun/blackbox/app/BActivityThread$4;

    .line 90
    .line 91
    invoke-direct {v1, p0}, Ltop/niunaijun/blackbox/app/BActivityThread$4;-><init>(Ltop/niunaijun/blackbox/app/BActivityThread;)V

    .line 92
    .line 93
    .line 94
    invoke-direct {p0, v1, p1}, Ltop/niunaijun/blackbox/app/BActivityThread;->ensureApplicationBaseContext(Landroid/app/Application;Landroid/content/pm/ApplicationInfo;)V
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_2

    .line 95
    .line 96
    .line 97
    return-object v1

    .line 98
    :catch_2
    move-exception p1

    .line 99
    const-string v1, "Failed to create minimal application wrapper"

    .line 100
    .line 101
    invoke-static {v0, v1, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 102
    .line 103
    .line 104
    const/4 p1, 0x0

    .line 105
    return-object p1
.end method

.method private createBindApplicationData(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/Object;
    .locals 2

    .line 1
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBPackageManager()Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;

    .line 2
    .line 3
    .line 4
    move-result-object p2

    .line 5
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    .line 6
    .line 7
    .line 8
    move-result v0

    .line 9
    const/16 v1, 0x8

    .line 10
    .line 11
    invoke-virtual {p2, p1, v1, v0}, Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;->getPackageInfo(Ljava/lang/String;II)Landroid/content/pm/PackageInfo;

    .line 12
    .line 13
    .line 14
    move-result-object p1

    .line 15
    iget-object p2, p1, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 16
    .line 17
    new-instance v0, Ltop/niunaijun/blackbox/app/BActivityThread$2;

    .line 18
    .line 19
    invoke-direct {v0, p0, p2, p1}, Ltop/niunaijun/blackbox/app/BActivityThread$2;-><init>(Ltop/niunaijun/blackbox/app/BActivityThread;Landroid/content/pm/ApplicationInfo;Landroid/content/pm/PackageInfo;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 20
    .line 21
    .line 22
    return-object v0

    .line 23
    :catch_0
    move-exception p1

    .line 24
    const-string p2, "BActivityThread"

    .line 25
    .line 26
    const-string v0, "Error creating bind application data"

    .line 27
    .line 28
    invoke-static {p2, v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 29
    .line 30
    .line 31
    new-instance p1, Ltop/niunaijun/blackbox/app/BActivityThread$3;

    .line 32
    .line 33
    invoke-direct {p1, p0}, Ltop/niunaijun/blackbox/app/BActivityThread$3;-><init>(Ltop/niunaijun/blackbox/app/BActivityThread;)V

    .line 34
    .line 35
    .line 36
    return-object p1
.end method

.method private createFallbackContext(Ljava/lang/String;)Landroid/content/Context;
    .locals 5

    .line 1
    const-string v0, "BActivityThread"

    .line 2
    .line 3
    const/4 v1, 0x0

    .line 4
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    .line 5
    .line 6
    .line 7
    move-result-object v2

    .line 8
    if-nez v2, :cond_0

    .line 9
    .line 10
    const-string v2, "BlackBoxCore.getContext() is null, cannot create fallback context"

    .line 11
    .line 12
    invoke-static {v0, v2}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 13
    .line 14
    .line 15
    return-object v1

    .line 16
    :catch_0
    move-exception v2

    .line 17
    goto :goto_0

    .line 18
    :cond_0
    new-instance v3, Ltop/niunaijun/blackbox/app/BActivityThread$5;

    .line 19
    .line 20
    invoke-direct {v3, p0, v2, p1, v2}, Ltop/niunaijun/blackbox/app/BActivityThread$5;-><init>(Ltop/niunaijun/blackbox/app/BActivityThread;Landroid/content/Context;Ljava/lang/String;Landroid/content/Context;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 21
    .line 22
    .line 23
    return-object v3

    .line 24
    :goto_0
    const-string v3, "Failed to create fallback context for "

    .line 25
    .line 26
    const-string v4, ": "

    .line 27
    .line 28
    invoke-static {v3, p1, v4}, Ltop/niunaijun/blackbox/a;->a(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 29
    .line 30
    .line 31
    move-result-object p1

    .line 32
    invoke-static {v2, p1, v0}, Ltop/niunaijun/blackbox/b;->a(Ljava/lang/Exception;Ljava/lang/StringBuilder;Ljava/lang/String;)V

    .line 33
    .line 34
    .line 35
    return-object v1
.end method

.method private createMinimalApplication(Landroid/content/Context;Ljava/lang/String;)Landroid/app/Application;
    .locals 8

    .line 1
    const-string v0, "BActivityThread"

    .line 2
    .line 3
    const-string v1, "Minimal application created successfully for "

    .line 4
    .line 5
    const-string v2, "Could not attach base context to minimal application: "

    .line 6
    .line 7
    const-string v3, "Successfully attached base context to minimal application for "

    .line 8
    .line 9
    const-string v4, "Creating minimal application for "

    .line 10
    .line 11
    :try_start_0
    new-instance v5, Ljava/lang/StringBuilder;

    .line 12
    .line 13
    invoke-direct {v5, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 14
    .line 15
    .line 16
    invoke-virtual {v5, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 17
    .line 18
    .line 19
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 20
    .line 21
    .line 22
    move-result-object v4

    .line 23
    invoke-static {v0, v4}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 24
    .line 25
    .line 26
    new-instance v4, Ltop/niunaijun/blackbox/app/BActivityThread$7;

    .line 27
    .line 28
    invoke-direct {v4, p0, p2}, Ltop/niunaijun/blackbox/app/BActivityThread$7;-><init>(Ltop/niunaijun/blackbox/app/BActivityThread;Ljava/lang/String;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_1

    .line 29
    .line 30
    .line 31
    if-eqz p1, :cond_0

    .line 32
    .line 33
    :try_start_1
    const-class v5, Landroid/app/Application;

    .line 34
    .line 35
    const-string v6, "attachBaseContext"

    .line 36
    .line 37
    const-class v7, Landroid/content/Context;

    .line 38
    .line 39
    filled-new-array {v7}, [Ljava/lang/Class;

    .line 40
    .line 41
    .line 42
    move-result-object v7

    .line 43
    invoke-virtual {v5, v6, v7}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    .line 44
    .line 45
    .line 46
    move-result-object v5

    .line 47
    const/4 v6, 0x1

    .line 48
    invoke-virtual {v5, v6}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 49
    .line 50
    .line 51
    filled-new-array {p1}, [Ljava/lang/Object;

    .line 52
    .line 53
    .line 54
    move-result-object p1

    .line 55
    invoke-virtual {v5, v4, p1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 56
    .line 57
    .line 58
    new-instance p1, Ljava/lang/StringBuilder;

    .line 59
    .line 60
    invoke-direct {p1, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 61
    .line 62
    .line 63
    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 64
    .line 65
    .line 66
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 67
    .line 68
    .line 69
    move-result-object p1

    .line 70
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 71
    .line 72
    .line 73
    goto :goto_0

    .line 74
    :catch_0
    move-exception p1

    .line 75
    :try_start_2
    new-instance v3, Ljava/lang/StringBuilder;

    .line 76
    .line 77
    invoke-direct {v3, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 78
    .line 79
    .line 80
    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 81
    .line 82
    .line 83
    move-result-object p1

    .line 84
    invoke-virtual {v3, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 85
    .line 86
    .line 87
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 88
    .line 89
    .line 90
    move-result-object p1

    .line 91
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 92
    .line 93
    .line 94
    goto :goto_0

    .line 95
    :catch_1
    move-exception p1

    .line 96
    goto :goto_1

    .line 97
    :cond_0
    const-string p1, "Package context is null, cannot attach base context to minimal application"

    .line 98
    .line 99
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 100
    .line 101
    .line 102
    :goto_0
    new-instance p1, Ljava/lang/StringBuilder;

    .line 103
    .line 104
    invoke-direct {p1, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 105
    .line 106
    .line 107
    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 108
    .line 109
    .line 110
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 111
    .line 112
    .line 113
    move-result-object p1

    .line 114
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_1

    .line 115
    .line 116
    .line 117
    return-object v4

    .line 118
    :goto_1
    new-instance v1, Ljava/lang/StringBuilder;

    .line 119
    .line 120
    const-string v2, "Error creating minimal application for "

    .line 121
    .line 122
    invoke-direct {v1, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 123
    .line 124
    .line 125
    invoke-virtual {v1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 126
    .line 127
    .line 128
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 129
    .line 130
    .line 131
    move-result-object p2

    .line 132
    invoke-static {v0, p2, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 133
    .line 134
    .line 135
    const/4 p1, 0x0

    .line 136
    return-object p1
.end method

.method private static createMinimalPackageContext(Landroid/content/pm/ApplicationInfo;)Landroid/content/Context;
    .locals 11

    .line 1
    const-string v0, ": "

    .line 2
    .line 3
    const-string v1, "BActivityThread"

    .line 4
    .line 5
    const-string v2, "Failed to create package context with include code for "

    .line 6
    .line 7
    const-string v3, "Successfully created package context with include code for "

    .line 8
    .line 9
    const-string v4, "Failed to create package context with ignore security for "

    .line 10
    .line 11
    const-string v5, "Successfully created package context with ignore security for "

    .line 12
    .line 13
    const-string v6, "Failed to create package context with minimal flags for "

    .line 14
    .line 15
    const-string v7, "Successfully created package context with minimal flags for "

    .line 16
    .line 17
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    .line 18
    .line 19
    .line 20
    move-result-object v8
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_3

    .line 21
    :try_start_1
    iget-object v9, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 22
    .line 23
    const/4 v10, 0x0

    .line 24
    invoke-virtual {v8, v9, v10}, Landroid/content/Context;->createPackageContext(Ljava/lang/String;I)Landroid/content/Context;

    .line 25
    .line 26
    .line 27
    move-result-object v9

    .line 28
    if-eqz v9, :cond_0

    .line 29
    .line 30
    new-instance v10, Ljava/lang/StringBuilder;

    .line 31
    .line 32
    invoke-direct {v10, v7}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 33
    .line 34
    .line 35
    iget-object v7, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 36
    .line 37
    invoke-virtual {v10, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 38
    .line 39
    .line 40
    invoke-virtual {v10}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 41
    .line 42
    .line 43
    move-result-object v7

    .line 44
    invoke-static {v1, v7}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 45
    .line 46
    .line 47
    return-object v9

    .line 48
    :catch_0
    move-exception v7

    .line 49
    :try_start_2
    new-instance v9, Ljava/lang/StringBuilder;

    .line 50
    .line 51
    invoke-direct {v9, v6}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 52
    .line 53
    .line 54
    iget-object v6, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 55
    .line 56
    invoke-virtual {v9, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 57
    .line 58
    .line 59
    invoke-virtual {v9, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 60
    .line 61
    .line 62
    invoke-virtual {v7}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 63
    .line 64
    .line 65
    move-result-object v6

    .line 66
    invoke-virtual {v9, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 67
    .line 68
    .line 69
    invoke-virtual {v9}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 70
    .line 71
    .line 72
    move-result-object v6

    .line 73
    invoke-static {v1, v6}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_3

    .line 74
    .line 75
    .line 76
    :cond_0
    :try_start_3
    iget-object v6, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 77
    .line 78
    const/4 v7, 0x2

    .line 79
    invoke-virtual {v8, v6, v7}, Landroid/content/Context;->createPackageContext(Ljava/lang/String;I)Landroid/content/Context;

    .line 80
    .line 81
    .line 82
    move-result-object v6

    .line 83
    if-eqz v6, :cond_1

    .line 84
    .line 85
    new-instance v7, Ljava/lang/StringBuilder;

    .line 86
    .line 87
    invoke-direct {v7, v5}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 88
    .line 89
    .line 90
    iget-object v5, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 91
    .line 92
    invoke-virtual {v7, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 93
    .line 94
    .line 95
    invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 96
    .line 97
    .line 98
    move-result-object v5

    .line 99
    invoke-static {v1, v5}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_1

    .line 100
    .line 101
    .line 102
    return-object v6

    .line 103
    :catch_1
    move-exception v5

    .line 104
    :try_start_4
    new-instance v6, Ljava/lang/StringBuilder;

    .line 105
    .line 106
    invoke-direct {v6, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 107
    .line 108
    .line 109
    iget-object v4, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 110
    .line 111
    invoke-virtual {v6, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 112
    .line 113
    .line 114
    invoke-virtual {v6, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 115
    .line 116
    .line 117
    invoke-virtual {v5}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 118
    .line 119
    .line 120
    move-result-object v4

    .line 121
    invoke-virtual {v6, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 122
    .line 123
    .line 124
    invoke-virtual {v6}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 125
    .line 126
    .line 127
    move-result-object v4

    .line 128
    invoke-static {v1, v4}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_4
    .catch Ljava/lang/Exception; {:try_start_4 .. :try_end_4} :catch_3

    .line 129
    .line 130
    .line 131
    :cond_1
    :try_start_5
    iget-object v4, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 132
    .line 133
    const/4 v5, 0x1

    .line 134
    invoke-virtual {v8, v4, v5}, Landroid/content/Context;->createPackageContext(Ljava/lang/String;I)Landroid/content/Context;

    .line 135
    .line 136
    .line 137
    move-result-object v4

    .line 138
    if-eqz v4, :cond_2

    .line 139
    .line 140
    new-instance v5, Ljava/lang/StringBuilder;

    .line 141
    .line 142
    invoke-direct {v5, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 143
    .line 144
    .line 145
    iget-object v3, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 146
    .line 147
    invoke-virtual {v5, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 148
    .line 149
    .line 150
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 151
    .line 152
    .line 153
    move-result-object v3

    .line 154
    invoke-static {v1, v3}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_5
    .catch Ljava/lang/Exception; {:try_start_5 .. :try_end_5} :catch_2

    .line 155
    .line 156
    .line 157
    return-object v4

    .line 158
    :catch_2
    move-exception v3

    .line 159
    :try_start_6
    new-instance v4, Ljava/lang/StringBuilder;

    .line 160
    .line 161
    invoke-direct {v4, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 162
    .line 163
    .line 164
    iget-object v2, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 165
    .line 166
    invoke-virtual {v4, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 167
    .line 168
    .line 169
    invoke-virtual {v4, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 170
    .line 171
    .line 172
    invoke-virtual {v3}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 173
    .line 174
    .line 175
    move-result-object v2

    .line 176
    invoke-virtual {v4, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 177
    .line 178
    .line 179
    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 180
    .line 181
    .line 182
    move-result-object v2

    .line 183
    invoke-static {v1, v2}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_6
    .catch Ljava/lang/Exception; {:try_start_6 .. :try_end_6} :catch_3

    .line 184
    .line 185
    .line 186
    goto :goto_0

    .line 187
    :catch_3
    move-exception v2

    .line 188
    new-instance v3, Ljava/lang/StringBuilder;

    .line 189
    .line 190
    const-string v4, "Failed to create minimal package context for "

    .line 191
    .line 192
    invoke-direct {v3, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 193
    .line 194
    .line 195
    iget-object v4, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 196
    .line 197
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 198
    .line 199
    .line 200
    invoke-virtual {v3, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 201
    .line 202
    .line 203
    invoke-static {v2, v3, v1}, Ltop/niunaijun/blackbox/b;->a(Ljava/lang/Exception;Ljava/lang/StringBuilder;Ljava/lang/String;)V

    .line 204
    .line 205
    .line 206
    :cond_2
    :goto_0
    new-instance v0, Ljava/lang/StringBuilder;

    .line 207
    .line 208
    const-string v2, "Using base context as fallback for "

    .line 209
    .line 210
    invoke-direct {v0, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 211
    .line 212
    .line 213
    iget-object v2, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 214
    .line 215
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 216
    .line 217
    .line 218
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 219
    .line 220
    .line 221
    move-result-object v0

    .line 222
    invoke-static {v1, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 223
    .line 224
    .line 225
    iget-object p0, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 226
    .line 227
    invoke-static {p0}, Ltop/niunaijun/blackbox/app/BActivityThread;->createWrappedBaseContext(Ljava/lang/String;)Landroid/content/Context;

    .line 228
    .line 229
    .line 230
    move-result-object p0

    .line 231
    return-object p0
.end method

.method public static createPackageContext(Landroid/content/pm/ApplicationInfo;)Landroid/content/Context;
    .locals 2

    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestSplits;->beforeContext(Landroid/content/pm/ApplicationInfo;)V

    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestCredentials;->beforeContext(Landroid/content/pm/ApplicationInfo;)V

    .line 1
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    iget-object p0, p0, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 6
    .line 7
    const/4 v1, 0x3

    .line 8
    invoke-virtual {v0, p0, v1}, Landroid/content/Context;->createPackageContext(Ljava/lang/String;I)Landroid/content/Context;

    .line 9
    .line 10
    .line 11
    move-result-object p0
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 12
    return-object p0

    .line 13
    :catch_0
    move-exception p0

    .line 14
    invoke-virtual {p0}, Ljava/lang/Throwable;->printStackTrace()V

    .line 15
    .line 16
    .line 17
    const/4 p0, 0x0

    .line 18
    return-object p0
.end method

.method private static createWrappedBaseContext(Ljava/lang/String;)Landroid/content/Context;
    .locals 3

    .line 1
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    new-instance v1, Ltop/niunaijun/blackbox/app/BActivityThread$6;

    .line 6
    .line 7
    invoke-direct {v1, v0, p0, v0}, Ltop/niunaijun/blackbox/app/BActivityThread$6;-><init>(Landroid/content/Context;Ljava/lang/String;Landroid/content/Context;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 8
    .line 9
    .line 10
    return-object v1

    .line 11
    :catch_0
    move-exception v0

    .line 12
    const-string v1, "Failed to create wrapped base context for "

    .line 13
    .line 14
    const-string v2, ": "

    .line 15
    .line 16
    invoke-static {v1, p0, v2}, Ltop/niunaijun/blackbox/a;->a(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 17
    .line 18
    .line 19
    move-result-object p0

    .line 20
    invoke-virtual {v0}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 21
    .line 22
    .line 23
    move-result-object v0

    .line 24
    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 25
    .line 26
    .line 27
    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 28
    .line 29
    .line 30
    move-result-object p0

    .line 31
    const-string v0, "BActivityThread"

    .line 32
    .line 33
    invoke-static {v0, p0}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 34
    .line 35
    .line 36
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    .line 37
    .line 38
    .line 39
    move-result-object p0

    .line 40
    return-object p0
.end method

.method public static currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;
    .locals 2

    .line 1
    sget-object v0, Ltop/niunaijun/blackbox/app/BActivityThread;->sBActivityThread:Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 2
    .line 3
    if-nez v0, :cond_1

    .line 4
    .line 5
    const-class v0, Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 6
    .line 7
    monitor-enter v0

    .line 8
    :try_start_0
    sget-object v1, Ltop/niunaijun/blackbox/app/BActivityThread;->sBActivityThread:Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 9
    .line 10
    if-nez v1, :cond_0

    .line 11
    .line 12
    new-instance v1, Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 13
    .line 14
    invoke-direct {v1}, Ltop/niunaijun/blackbox/app/BActivityThread;-><init>()V

    .line 15
    .line 16
    .line 17
    sput-object v1, Ltop/niunaijun/blackbox/app/BActivityThread;->sBActivityThread:Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 18
    .line 19
    goto :goto_0

    .line 20
    :catchall_0
    move-exception v1

    .line 21
    goto :goto_1

    .line 22
    :cond_0
    :goto_0
    monitor-exit v0

    .line 23
    goto :goto_2

    .line 24
    :goto_1
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 25
    throw v1

    .line 26
    :cond_1
    :goto_2
    sget-object v0, Ltop/niunaijun/blackbox/app/BActivityThread;->sBActivityThread:Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 27
    .line 28
    return-object v0
.end method

.method public static synthetic d(Landroid/os/IBinder;)V
    .locals 0

    .line 1
    invoke-static {p0}, Ltop/niunaijun/blackbox/app/BActivityThread;->lambda$finishActivity$1(Landroid/os/IBinder;)V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method public static bridge synthetic e(Ltop/niunaijun/blackbox/app/BActivityThread;)V
    .locals 1

    .line 1
    const/4 v0, 0x0

    .line 2
    iput-object v0, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mAppConfig:Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 3
    .line 4
    return-void
.end method

.method public static ensureActivityContext(Landroid/app/Activity;)V
    .locals 7

    .line 1
    const-string v0, "BActivityThread"

    .line 2
    .line 3
    const-string v1, "Could not attach base context to activity: "

    .line 4
    .line 5
    const-string v2, "Successfully attached package context to activity: "

    .line 6
    .line 7
    const-string v3, "Could not get application context: "

    .line 8
    .line 9
    const-string v4, "Activity has null context, ensuring valid context: "

    .line 10
    .line 11
    const-string v5, "Activity already has context: "

    .line 12
    .line 13
    if-nez p0, :cond_0

    .line 14
    .line 15
    goto/16 :goto_3

    .line 16
    .line 17
    :cond_0
    :try_start_0
    invoke-virtual {p0}, Landroid/content/ContextWrapper;->getBaseContext()Landroid/content/Context;

    .line 18
    .line 19
    .line 20
    move-result-object v6

    .line 21
    if-eqz v6, :cond_1

    .line 22
    .line 23
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 24
    .line 25
    .line 26
    move-result-object p0

    .line 27
    invoke-virtual {p0}, Ljava/lang/Class;->getName()Ljava/lang/String;

    .line 28
    .line 29
    .line 30
    move-result-object p0

    .line 31
    invoke-virtual {v5, p0}, Ljava/lang/String;->concat(Ljava/lang/String;)Ljava/lang/String;

    .line 32
    .line 33
    .line 34
    move-result-object p0

    .line 35
    invoke-static {v0, p0}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 36
    .line 37
    .line 38
    return-void

    .line 39
    :catch_0
    move-exception p0

    .line 40
    goto/16 :goto_2

    .line 41
    .line 42
    :cond_1
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 43
    .line 44
    .line 45
    move-result-object v5

    .line 46
    invoke-virtual {v5}, Ljava/lang/Class;->getName()Ljava/lang/String;

    .line 47
    .line 48
    .line 49
    move-result-object v5

    .line 50
    invoke-virtual {v4, v5}, Ljava/lang/String;->concat(Ljava/lang/String;)Ljava/lang/String;

    .line 51
    .line 52
    .line 53
    move-result-object v4

    .line 54
    invoke-static {v0, v4}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 55
    .line 56
    .line 57
    :try_start_1
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getApplication()Landroid/app/Application;

    .line 58
    .line 59
    .line 60
    move-result-object v4

    .line 61
    if-nez v4, :cond_2

    .line 62
    .line 63
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    .line 64
    .line 65
    .line 66
    move-result-object v3
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

    .line 67
    :goto_0
    move-object v4, v3

    .line 68
    goto :goto_1

    .line 69
    :catch_1
    move-exception v4

    .line 70
    :try_start_2
    new-instance v5, Ljava/lang/StringBuilder;

    .line 71
    .line 72
    invoke-direct {v5, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 73
    .line 74
    .line 75
    invoke-virtual {v4}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 76
    .line 77
    .line 78
    move-result-object v3

    .line 79
    invoke-virtual {v5, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 80
    .line 81
    .line 82
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 83
    .line 84
    .line 85
    move-result-object v3

    .line 86
    invoke-static {v0, v3}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 87
    .line 88
    .line 89
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    .line 90
    .line 91
    .line 92
    move-result-object v3
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_0

    .line 93
    goto :goto_0

    .line 94
    :cond_2
    :goto_1
    if-eqz v4, :cond_3

    .line 95
    .line 96
    :try_start_3
    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    .line 97
    .line 98
    .line 99
    move-result-object v3

    .line 100
    const/4 v5, 0x3

    .line 101
    invoke-virtual {v4, v3, v5}, Landroid/content/Context;->createPackageContext(Ljava/lang/String;I)Landroid/content/Context;

    .line 102
    .line 103
    .line 104
    move-result-object v3

    .line 105
    const-class v4, Landroid/app/Activity;

    .line 106
    .line 107
    const-string v5, "attachBaseContext"

    .line 108
    .line 109
    const-class v6, Landroid/content/Context;

    .line 110
    .line 111
    filled-new-array {v6}, [Ljava/lang/Class;

    .line 112
    .line 113
    .line 114
    move-result-object v6

    .line 115
    invoke-virtual {v4, v5, v6}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    .line 116
    .line 117
    .line 118
    move-result-object v4

    .line 119
    const/4 v5, 0x1

    .line 120
    invoke-virtual {v4, v5}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 121
    .line 122
    .line 123
    filled-new-array {v3}, [Ljava/lang/Object;

    .line 124
    .line 125
    .line 126
    move-result-object v3

    .line 127
    invoke-virtual {v4, p0, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 128
    .line 129
    .line 130
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 131
    .line 132
    .line 133
    move-result-object p0

    .line 134
    invoke-virtual {p0}, Ljava/lang/Class;->getName()Ljava/lang/String;

    .line 135
    .line 136
    .line 137
    move-result-object p0

    .line 138
    invoke-virtual {v2, p0}, Ljava/lang/String;->concat(Ljava/lang/String;)Ljava/lang/String;

    .line 139
    .line 140
    .line 141
    move-result-object p0

    .line 142
    invoke-static {v0, p0}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_2

    .line 143
    .line 144
    .line 145
    goto :goto_3

    .line 146
    :catch_2
    move-exception p0

    .line 147
    :try_start_4
    new-instance v2, Ljava/lang/StringBuilder;

    .line 148
    .line 149
    invoke-direct {v2, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 150
    .line 151
    .line 152
    invoke-virtual {p0}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 153
    .line 154
    .line 155
    move-result-object p0

    .line 156
    invoke-virtual {v2, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 157
    .line 158
    .line 159
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 160
    .line 161
    .line 162
    move-result-object p0

    .line 163
    invoke-static {v0, p0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_4
    .catch Ljava/lang/Exception; {:try_start_4 .. :try_end_4} :catch_0

    .line 164
    .line 165
    .line 166
    goto :goto_3

    .line 167
    :goto_2
    const-string v1, "Error ensuring activity context: "

    .line 168
    .line 169
    invoke-static {v1, p0, v0}, Landroidx/fragment/app/x0;->k(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 170
    .line 171
    .line 172
    :cond_3
    :goto_3
    return-void
.end method

.method private ensureApplicationBaseContext(Landroid/app/Application;Landroid/content/pm/ApplicationInfo;)V
    .locals 7

    .line 1
    const-string v0, "BActivityThread"

    .line 2
    .line 3
    const-string v1, "Could not attach base context to application: "

    .line 4
    .line 5
    const-string v2, "Successfully attached base context to application: "

    .line 6
    .line 7
    const-string v3, "Failed to create any context for application: "

    .line 8
    .line 9
    const-string v4, "Could not create package context for application: "

    .line 10
    .line 11
    const-string v5, "Application already has base context: "

    .line 12
    .line 13
    :try_start_0
    invoke-virtual {p1}, Landroid/content/ContextWrapper;->getBaseContext()Landroid/content/Context;

    .line 14
    .line 15
    .line 16
    move-result-object v6

    .line 17
    if-eqz v6, :cond_0

    .line 18
    .line 19
    new-instance p1, Ljava/lang/StringBuilder;

    .line 20
    .line 21
    invoke-direct {p1, v5}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 22
    .line 23
    .line 24
    iget-object p2, p2, Landroid/content/pm/ApplicationInfo;->className:Ljava/lang/String;

    .line 25
    .line 26
    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 27
    .line 28
    .line 29
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 30
    .line 31
    .line 32
    move-result-object p1

    .line 33
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 34
    .line 35
    .line 36
    return-void

    .line 37
    :catch_0
    move-exception p1

    .line 38
    goto :goto_0

    .line 39
    :cond_0
    invoke-static {p2}, Ltop/niunaijun/blackbox/app/BActivityThread;->createPackageContext(Landroid/content/pm/ApplicationInfo;)Landroid/content/Context;

    .line 40
    .line 41
    .line 42
    move-result-object v5

    .line 43
    if-nez v5, :cond_1

    .line 44
    .line 45
    new-instance v5, Ljava/lang/StringBuilder;

    .line 46
    .line 47
    invoke-direct {v5, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 48
    .line 49
    .line 50
    iget-object v4, p2, Landroid/content/pm/ApplicationInfo;->className:Ljava/lang/String;

    .line 51
    .line 52
    invoke-virtual {v5, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 53
    .line 54
    .line 55
    const-string v4, ", using fallback"

    .line 56
    .line 57
    invoke-virtual {v5, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 58
    .line 59
    .line 60
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 61
    .line 62
    .line 63
    move-result-object v4

    .line 64
    invoke-static {v0, v4}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 65
    .line 66
    .line 67
    iget-object v4, p2, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 68
    .line 69
    invoke-direct {p0, v4}, Ltop/niunaijun/blackbox/app/BActivityThread;->createFallbackContext(Ljava/lang/String;)Landroid/content/Context;

    .line 70
    .line 71
    .line 72
    move-result-object v5

    .line 73
    :cond_1
    if-nez v5, :cond_2

    .line 74
    .line 75
    new-instance p1, Ljava/lang/StringBuilder;

    .line 76
    .line 77
    invoke-direct {p1, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 78
    .line 79
    .line 80
    iget-object p2, p2, Landroid/content/pm/ApplicationInfo;->className:Ljava/lang/String;

    .line 81
    .line 82
    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 83
    .line 84
    .line 85
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 86
    .line 87
    .line 88
    move-result-object p1

    .line 89
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 90
    .line 91
    .line 92
    return-void

    .line 93
    :cond_2
    :try_start_1
    const-class v3, Landroid/app/Application;

    .line 94
    .line 95
    const-string v4, "attachBaseContext"

    .line 96
    .line 97
    const-class v6, Landroid/content/Context;

    .line 98
    .line 99
    filled-new-array {v6}, [Ljava/lang/Class;

    .line 100
    .line 101
    .line 102
    move-result-object v6

    .line 103
    invoke-virtual {v3, v4, v6}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    .line 104
    .line 105
    .line 106
    move-result-object v3

    .line 107
    const/4 v4, 0x1

    .line 108
    invoke-virtual {v3, v4}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 109
    .line 110
    .line 111
    filled-new-array {v5}, [Ljava/lang/Object;

    .line 112
    .line 113
    .line 114
    move-result-object v4

    .line 115
    invoke-virtual {v3, p1, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 116
    .line 117
    .line 118
    new-instance p1, Ljava/lang/StringBuilder;

    .line 119
    .line 120
    invoke-direct {p1, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 121
    .line 122
    .line 123
    iget-object p2, p2, Landroid/content/pm/ApplicationInfo;->className:Ljava/lang/String;

    .line 124
    .line 125
    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 126
    .line 127
    .line 128
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 129
    .line 130
    .line 131
    move-result-object p1

    .line 132
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

    .line 133
    .line 134
    .line 135
    goto :goto_1

    .line 136
    :catch_1
    move-exception p1

    .line 137
    :try_start_2
    new-instance p2, Ljava/lang/StringBuilder;

    .line 138
    .line 139
    invoke-direct {p2, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 140
    .line 141
    .line 142
    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 143
    .line 144
    .line 145
    move-result-object p1

    .line 146
    invoke-virtual {p2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 147
    .line 148
    .line 149
    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 150
    .line 151
    .line 152
    move-result-object p1

    .line 153
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_0

    .line 154
    .line 155
    .line 156
    goto :goto_1

    .line 157
    :goto_0
    const-string p2, "Error ensuring application base context: "

    .line 158
    .line 159
    invoke-static {p2, p1, v0}, Landroidx/fragment/app/x0;->k(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 160
    .line 161
    .line 162
    :goto_1
    return-void
.end method

.method public static bridge synthetic f()Ljava/lang/Object;
    .locals 1

    .line 1
    sget-object v0, Ltop/niunaijun/blackbox/app/BActivityThread;->mConfigLock:Ljava/lang/Object;

    .line 2
    .line 3
    return-object v0
.end method

.method public static getActivityByToken(Landroid/os/IBinder;)Landroid/app/Activity;
    .locals 3

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    const-class v1, Lblack/android/app/ActivityThreadContext;

    .line 6
    .line 7
    const/4 v2, 0x0

    .line 8
    invoke-static {v1, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 9
    .line 10
    .line 11
    move-result-object v0

    .line 12
    check-cast v0, Lblack/android/app/ActivityThreadContext;

    .line 13
    .line 14
    invoke-interface {v0}, Lblack/android/app/ActivityThreadContext;->mActivities()Ljava/util/Map;

    .line 15
    .line 16
    .line 17
    move-result-object v0

    .line 18
    invoke-interface {v0, p0}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 19
    .line 20
    .line 21
    move-result-object p0

    .line 22
    const-class v0, Lblack/android/app/ActivityThreadActivityClientRecordContext;

    .line 23
    .line 24
    invoke-static {v0, p0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 25
    .line 26
    .line 27
    move-result-object p0

    .line 28
    check-cast p0, Lblack/android/app/ActivityThreadActivityClientRecordContext;

    .line 29
    .line 30
    invoke-interface {p0}, Lblack/android/app/ActivityThreadActivityClientRecordContext;->activity()Landroid/app/Activity;

    .line 31
    .line 32
    .line 33
    move-result-object p0

    .line 34
    return-object p0
.end method

.method public static getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;
    .locals 2

    .line 1
    sget-object v0, Ltop/niunaijun/blackbox/app/BActivityThread;->mConfigLock:Ljava/lang/Object;

    .line 2
    .line 3
    monitor-enter v0

    .line 4
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 5
    .line 6
    .line 7
    move-result-object v1

    .line 8
    iget-object v1, v1, Ltop/niunaijun/blackbox/app/BActivityThread;->mAppConfig:Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 9
    .line 10
    monitor-exit v0

    .line 11
    return-object v1

    .line 12
    :catchall_0
    move-exception v1

    .line 13
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 14
    throw v1
.end method

.method public static getAppPackageName()Ljava/lang/String;
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    if-eqz v0, :cond_0

    .line 6
    .line 7
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 8
    .line 9
    .line 10
    move-result-object v0

    .line 11
    iget-object v0, v0, Ltop/niunaijun/blackbox/entity/AppConfig;->packageName:Ljava/lang/String;

    .line 12
    .line 13
    return-object v0

    .line 14
    :cond_0
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 15
    .line 16
    .line 17
    move-result-object v0

    .line 18
    iget-object v0, v0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 19
    .line 20
    if-eqz v0, :cond_1

    .line 21
    .line 22
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 23
    .line 24
    .line 25
    move-result-object v0

    .line 26
    iget-object v0, v0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 27
    .line 28
    invoke-virtual {v0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    .line 29
    .line 30
    .line 31
    move-result-object v0

    .line 32
    return-object v0

    .line 33
    :cond_1
    const/4 v0, 0x0

    .line 34
    return-object v0
.end method

.method public static getAppPid()I
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    if-nez v0, :cond_0

    .line 6
    .line 7
    const/4 v0, -0x1

    .line 8
    return v0

    .line 9
    :cond_0
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 10
    .line 11
    .line 12
    move-result-object v0

    .line 13
    iget v0, v0, Ltop/niunaijun/blackbox/entity/AppConfig;->bpid:I

    .line 14
    .line 15
    return v0
.end method

.method public static getAppProcessName()Ljava/lang/String;
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    if-eqz v0, :cond_0

    .line 6
    .line 7
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 8
    .line 9
    .line 10
    move-result-object v0

    .line 11
    iget-object v0, v0, Ltop/niunaijun/blackbox/entity/AppConfig;->processName:Ljava/lang/String;

    .line 12
    .line 13
    return-object v0

    .line 14
    :cond_0
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 15
    .line 16
    .line 17
    move-result-object v0

    .line 18
    iget-object v0, v0, Ltop/niunaijun/blackbox/app/BActivityThread;->mBoundApplication:Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;

    .line 19
    .line 20
    if-eqz v0, :cond_1

    .line 21
    .line 22
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 23
    .line 24
    .line 25
    move-result-object v0

    .line 26
    iget-object v0, v0, Ltop/niunaijun/blackbox/app/BActivityThread;->mBoundApplication:Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;

    .line 27
    .line 28
    iget-object v0, v0, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->processName:Ljava/lang/String;

    .line 29
    .line 30
    return-object v0

    .line 31
    :cond_1
    const/4 v0, 0x0

    .line 32
    return-object v0
.end method

.method public static getApplication()Landroid/app/Application;
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    iget-object v0, v0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 6
    .line 7
    return-object v0
.end method

.method private getApplicationInfo(Ljava/lang/Object;)Landroid/content/pm/ApplicationInfo;
    .locals 5

    .line 1
    const-string v0, "Error getting info from custom data object: "

    .line 2
    .line 3
    const-string v1, "BActivityThread"

    .line 4
    .line 5
    const/4 v2, 0x0

    .line 6
    if-eqz p1, :cond_0

    .line 7
    .line 8
    :try_start_0
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 9
    .line 10
    .line 11
    move-result-object v3

    .line 12
    const-string v4, "getInfo"

    .line 13
    .line 14
    invoke-virtual {v3, v4, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    .line 15
    .line 16
    .line 17
    move-result-object v3

    .line 18
    invoke-virtual {v3, p1, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 19
    .line 20
    .line 21
    move-result-object p1

    .line 22
    check-cast p1, Landroid/content/pm/ApplicationInfo;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 23
    .line 24
    if-eqz p1, :cond_0

    .line 25
    .line 26
    return-object p1

    .line 27
    :catch_0
    move-exception p1

    .line 28
    :try_start_1
    new-instance v3, Ljava/lang/StringBuilder;

    .line 29
    .line 30
    invoke-direct {v3, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 31
    .line 32
    .line 33
    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 34
    .line 35
    .line 36
    move-result-object p1

    .line 37
    invoke-virtual {v3, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 38
    .line 39
    .line 40
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 41
    .line 42
    .line 43
    move-result-object p1

    .line 44
    invoke-static {v1, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 45
    .line 46
    .line 47
    goto :goto_0

    .line 48
    :catch_1
    move-exception p1

    .line 49
    goto :goto_1

    .line 50
    :cond_0
    :goto_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getAppPackageName()Ljava/lang/String;

    .line 51
    .line 52
    .line 53
    move-result-object p1

    .line 54
    if-eqz p1, :cond_1

    .line 55
    .line 56
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBPackageManager()Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;

    .line 57
    .line 58
    .line 59
    move-result-object v0

    .line 60
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    .line 61
    .line 62
    .line 63
    move-result v3

    .line 64
    const/4 v4, 0x0

    .line 65
    invoke-virtual {v0, p1, v4, v3}, Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;->getPackageInfo(Ljava/lang/String;II)Landroid/content/pm/PackageInfo;

    .line 66
    .line 67
    .line 68
    move-result-object p1

    .line 69
    iget-object p1, p1, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

    .line 70
    .line 71
    return-object p1

    .line 72
    :cond_1
    return-object v2

    .line 73
    :goto_1
    const-string v0, "Error getting application info"

    .line 74
    .line 75
    invoke-static {v1, v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 76
    .line 77
    .line 78
    return-object v2
.end method

.method public static getBAppId()I
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getBUid()I

    .line 2
    .line 3
    .line 4
    move-result v0

    .line 5
    invoke-static {v0}, Ltop/niunaijun/blackbox/core/system/user/BUserHandle;->getAppId(I)I

    .line 6
    .line 7
    .line 8
    move-result v0

    .line 9
    return v0
.end method

.method public static getBUid()I
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    if-nez v0, :cond_0

    .line 6
    .line 7
    const/16 v0, 0x2710

    .line 8
    .line 9
    return v0

    .line 10
    :cond_0
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 11
    .line 12
    .line 13
    move-result-object v0

    .line 14
    iget v0, v0, Ltop/niunaijun/blackbox/entity/AppConfig;->buid:I

    .line 15
    .line 16
    return v0
.end method

.method public static getCallingBUid()I
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    if-nez v0, :cond_0

    .line 6
    .line 7
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostUid()I

    .line 8
    .line 9
    .line 10
    move-result v0

    .line 11
    return v0

    .line 12
    :cond_0
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 13
    .line 14
    .line 15
    move-result-object v0

    .line 16
    iget v0, v0, Ltop/niunaijun/blackbox/entity/AppConfig;->callingBUid:I

    .line 17
    .line 18
    return v0
.end method

.method private getClassLoader(Landroid/content/pm/ApplicationInfo;)Ljava/lang/ClassLoader;
    .locals 2

    .line 1
    :try_start_0
    iget-object p1, p1, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    .line 2
    .line 3
    if-eqz p1, :cond_0

    .line 4
    .line 5
    new-instance v0, Ldalvik/system/PathClassLoader;

    .line 6
    .line 7
    invoke-static {}, Ljava/lang/ClassLoader;->getSystemClassLoader()Ljava/lang/ClassLoader;

    .line 8
    .line 9
    .line 10
    move-result-object v1

    .line 11
    invoke-direct {v0, p1, v1}, Ldalvik/system/PathClassLoader;-><init>(Ljava/lang/String;Ljava/lang/ClassLoader;)V

    .line 12
    .line 13
    .line 14
    return-object v0

    .line 15
    :catch_0
    move-exception p1

    .line 16
    goto :goto_0

    .line 17
    :cond_0
    invoke-static {}, Ljava/lang/ClassLoader;->getSystemClassLoader()Ljava/lang/ClassLoader;

    .line 18
    .line 19
    .line 20
    move-result-object p1
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 21
    return-object p1

    .line 22
    :goto_0
    new-instance v0, Ljava/lang/StringBuilder;

    .line 23
    .line 24
    const-string v1, "Error getting class loader: "

    .line 25
    .line 26
    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 27
    .line 28
    .line 29
    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 30
    .line 31
    .line 32
    move-result-object p1

    .line 33
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 34
    .line 35
    .line 36
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 37
    .line 38
    .line 39
    move-result-object p1

    .line 40
    const-string v0, "BActivityThread"

    .line 41
    .line 42
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 43
    .line 44
    .line 45
    invoke-static {}, Ljava/lang/ClassLoader;->getSystemClassLoader()Ljava/lang/ClassLoader;

    .line 46
    .line 47
    .line 48
    move-result-object p1

    .line 49
    return-object p1
.end method

.method private getProviderInfoList(Ljava/lang/Object;)Ljava/util/List;
    .locals 5
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/lang/Object;",
            ")",
            "Ljava/util/List<",
            "Landroid/content/pm/ProviderInfo;",
            ">;"
        }
    .end annotation

    .line 1
    const-string v0, "Error getting providers from custom data object: "

    .line 2
    .line 3
    const-string v1, "BActivityThread"

    .line 4
    .line 5
    if-eqz p1, :cond_0

    .line 6
    .line 7
    :try_start_0
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 8
    .line 9
    .line 10
    move-result-object v2

    .line 11
    const-string v3, "getProviders"

    .line 12
    .line 13
    const/4 v4, 0x0

    .line 14
    invoke-virtual {v2, v3, v4}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    .line 15
    .line 16
    .line 17
    move-result-object v2

    .line 18
    invoke-virtual {v2, p1, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 19
    .line 20
    .line 21
    move-result-object p1

    .line 22
    check-cast p1, Ljava/util/List;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 23
    .line 24
    if-eqz p1, :cond_0

    .line 25
    .line 26
    return-object p1

    .line 27
    :catch_0
    move-exception p1

    .line 28
    :try_start_1
    new-instance v2, Ljava/lang/StringBuilder;

    .line 29
    .line 30
    invoke-direct {v2, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 31
    .line 32
    .line 33
    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 34
    .line 35
    .line 36
    move-result-object p1

    .line 37
    invoke-virtual {v2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 38
    .line 39
    .line 40
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 41
    .line 42
    .line 43
    move-result-object p1

    .line 44
    invoke-static {v1, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 45
    .line 46
    .line 47
    goto :goto_0

    .line 48
    :catch_1
    move-exception p1

    .line 49
    goto :goto_1

    .line 50
    :cond_0
    :goto_0
    new-instance p1, Ljava/util/ArrayList;

    .line 51
    .line 52
    invoke-direct {p1}, Ljava/util/ArrayList;-><init>()V
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

    .line 53
    .line 54
    .line 55
    return-object p1

    .line 56
    :goto_1
    const-string v0, "Error getting provider info list"

    .line 57
    .line 58
    invoke-static {v1, v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 59
    .line 60
    .line 61
    new-instance p1, Ljava/util/ArrayList;

    .line 62
    .line 63
    invoke-direct {p1}, Ljava/util/ArrayList;-><init>()V

    .line 64
    .line 65
    .line 66
    return-object p1
.end method

.method public static getProviders()Ljava/util/List;
    .locals 1
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "()",
            "Ljava/util/List<",
            "Landroid/content/pm/ProviderInfo;",
            ">;"
        }
    .end annotation

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    iget-object v0, v0, Ltop/niunaijun/blackbox/app/BActivityThread;->mProviders:Ljava/util/List;

    .line 6
    .line 7
    return-object v0
.end method

.method public static getUid()I
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    if-nez v0, :cond_0

    .line 6
    .line 7
    const/4 v0, -0x1

    .line 8
    return v0

    .line 9
    :cond_0
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 10
    .line 11
    .line 12
    move-result-object v0

    .line 13
    iget v0, v0, Ltop/niunaijun/blackbox/entity/AppConfig;->uid:I

    .line 14
    .line 15
    return v0
.end method

.method public static getUserId()I
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    if-nez v0, :cond_0

    .line 6
    .line 7
    const/4 v0, 0x0

    .line 8
    return v0

    .line 9
    :cond_0
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 10
    .line 11
    .line 12
    move-result-object v0

    .line 13
    iget v0, v0, Ltop/niunaijun/blackbox/entity/AppConfig;->userId:I

    .line 14
    .line 15
    return v0
.end method

.method private handleSecurityException(Ljava/lang/SecurityException;Ljava/lang/String;Ljava/lang/String;Landroid/content/Context;)V
    .locals 1

    .line 1
    new-instance p3, Ljava/lang/StringBuilder;

    .line 2
    .line 3
    const-string v0, "Handling SecurityException for "

    .line 4
    .line 5
    invoke-direct {p3, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 6
    .line 7
    .line 8
    invoke-virtual {p3, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 9
    .line 10
    .line 11
    invoke-virtual {p3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 12
    .line 13
    .line 14
    move-result-object p3

    .line 15
    const-string v0, "BActivityThread"

    .line 16
    .line 17
    invoke-static {v0, p3}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 18
    .line 19
    .line 20
    :try_start_0
    invoke-direct {p0, p4, p2}, Ltop/niunaijun/blackbox/app/BActivityThread;->createMinimalApplication(Landroid/content/Context;Ljava/lang/String;)Landroid/app/Application;

    .line 21
    .line 22
    .line 23
    move-result-object p2

    .line 24
    if-eqz p2, :cond_0

    .line 25
    .line 26
    iput-object p2, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 27
    .line 28
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 29
    .line 30
    .line 31
    move-result-object p2

    .line 32
    const-class p3, Lblack/android/app/ActivityThreadContext;

    .line 33
    .line 34
    const/4 p4, 0x0

    .line 35
    invoke-static {p3, p2, p4}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 36
    .line 37
    .line 38
    move-result-object p2

    .line 39
    check-cast p2, Lblack/android/app/ActivityThreadContext;

    .line 40
    .line 41
    iget-object p3, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 42
    .line 43
    invoke-interface {p2, p3}, Lblack/android/app/ActivityThreadContext;->_set_mInitialApplication(Ljava/lang/Object;)V

    .line 44
    .line 45
    .line 46
    iget-object p2, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 47
    .line 48
    invoke-static {p2}, Ltop/niunaijun/blackbox/utils/compat/ContextCompat;->fix(Landroid/content/Context;)V

    .line 49
    .line 50
    .line 51
    const-string p2, "Created basic application, skipping problematic operations"

    .line 52
    .line 53
    invoke-static {v0, p2}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 54
    .line 55
    .line 56
    return-void

    .line 57
    :catch_0
    move-exception p2

    .line 58
    const-string p3, "Failed to create basic application after SecurityException: "

    .line 59
    .line 60
    invoke-static {p3, p2, v0}, Landroidx/fragment/app/x0;->k(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 61
    .line 62
    .line 63
    :cond_0
    new-instance p2, Ljava/lang/RuntimeException;

    .line 64
    .line 65
    const-string p3, "Unable to handle SecurityException"

    .line 66
    .line 67
    invoke-direct {p2, p3, p1}, Ljava/lang/RuntimeException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    .line 68
    .line 69
    .line 70
    throw p2
.end method

.method public static hookActivityThread()V
    .locals 5

    .line 1
    const-string v0, "BActivityThread"

    .line 2
    .line 3
    const-string v1, "Could not replace ActivityThread instrumentation: "

    .line 4
    .line 5
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 6
    .line 7
    .line 8
    move-result-object v2

    .line 9
    if-eqz v2, :cond_2

    .line 10
    .line 11
    const-class v3, Lblack/android/app/ActivityThreadContext;

    .line 12
    .line 13
    const/4 v4, 0x0

    .line 14
    invoke-static {v3, v2, v4}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 15
    .line 16
    .line 17
    move-result-object v2

    .line 18
    check-cast v2, Lblack/android/app/ActivityThreadContext;

    .line 19
    .line 20
    invoke-interface {v2}, Lblack/android/app/ActivityThreadContext;->mInstrumentation()Landroid/app/Instrumentation;

    .line 21
    .line 22
    .line 23
    move-result-object v2

    .line 24
    if-eqz v2, :cond_1

    .line 25
    .line 26
    const-string v3, "Found ActivityThread instrumentation, ensuring it\'s our AppInstrumentation"

    .line 27
    .line 28
    invoke-static {v0, v3}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 29
    .line 30
    .line 31
    instance-of v2, v2, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;

    .line 32
    .line 33
    if-nez v2, :cond_0

    .line 34
    .line 35
    const-string v2, "ActivityThread instrumentation is not our AppInstrumentation, attempting to replace"

    .line 36
    .line 37
    invoke-static {v0, v2}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_1

    .line 38
    .line 39
    .line 40
    :try_start_1
    invoke-static {}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->get()Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;

    .line 41
    .line 42
    .line 43
    move-result-object v2

    .line 44
    invoke-virtual {v2}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->injectHook()V

    .line 45
    .line 46
    .line 47
    const-string v2, "Successfully replaced ActivityThread instrumentation with AppInstrumentation"

    .line 48
    .line 49
    invoke-static {v0, v2}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 50
    .line 51
    .line 52
    goto :goto_1

    .line 53
    :catch_0
    move-exception v2

    .line 54
    :try_start_2
    new-instance v3, Ljava/lang/StringBuilder;

    .line 55
    .line 56
    invoke-direct {v3, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 57
    .line 58
    .line 59
    invoke-virtual {v2}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 60
    .line 61
    .line 62
    move-result-object v1

    .line 63
    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 64
    .line 65
    .line 66
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 67
    .line 68
    .line 69
    move-result-object v1

    .line 70
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 71
    .line 72
    .line 73
    goto :goto_1

    .line 74
    :catch_1
    move-exception v1

    .line 75
    goto :goto_0

    .line 76
    :cond_0
    const-string v1, "ActivityThread instrumentation is already our AppInstrumentation"

    .line 77
    .line 78
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 79
    .line 80
    .line 81
    goto :goto_1

    .line 82
    :cond_1
    const-string v1, "ActivityThread instrumentation is null"

    .line 83
    .line 84
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 85
    .line 86
    .line 87
    goto :goto_1

    .line 88
    :cond_2
    const-string v1, "ActivityThread is null"

    .line 89
    .line 90
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_1

    .line 91
    .line 92
    .line 93
    goto :goto_1

    .line 94
    :goto_0
    const-string v2, "Error hooking ActivityThread: "

    .line 95
    .line 96
    invoke-static {v2, v1, v0}, Landroidx/fragment/app/x0;->k(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 97
    .line 98
    .line 99
    :goto_1
    return-void
.end method

.method private initializeJarEnvironment()V
    .locals 5

    .line 1
    const-string v0, "BActivityThread"

    .line 2
    .line 3
    const-string v1, "Empty JAR verified: "

    .line 4
    .line 5
    :try_start_0
    const-string v2, "Initializing JAR environment for DEX loading"

    .line 6
    .line 7
    invoke-static {v0, v2}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 8
    .line 9
    .line 10
    invoke-static {}, Ltop/niunaijun/blackbox/core/system/JarManager;->getInstance()Ltop/niunaijun/blackbox/core/system/JarManager;

    .line 11
    .line 12
    .line 13
    move-result-object v2

    .line 14
    invoke-virtual {v2}, Ltop/niunaijun/blackbox/core/system/JarManager;->isReady()Z

    .line 15
    .line 16
    .line 17
    move-result v3

    .line 18
    if-nez v3, :cond_0

    .line 19
    .line 20
    const-string v3, "JarManager not ready, initializing synchronously"

    .line 21
    .line 22
    invoke-static {v0, v3}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 23
    .line 24
    .line 25
    invoke-virtual {v2}, Ltop/niunaijun/blackbox/core/system/JarManager;->initializeSync()V

    .line 26
    .line 27
    .line 28
    goto :goto_0

    .line 29
    :catch_0
    move-exception v1

    .line 30
    goto :goto_1

    .line 31
    :cond_0
    :goto_0
    invoke-virtual {v2}, Ltop/niunaijun/blackbox/core/system/JarManager;->getEmptyJar()Ljava/io/File;

    .line 32
    .line 33
    .line 34
    move-result-object v3

    .line 35
    if-eqz v3, :cond_1

    .line 36
    .line 37
    invoke-virtual {v3}, Ljava/io/File;->exists()Z

    .line 38
    .line 39
    .line 40
    move-result v4

    .line 41
    if-nez v4, :cond_2

    .line 42
    .line 43
    :cond_1
    const-string v3, "Empty JAR not available, attempting to recreate"

    .line 44
    .line 45
    invoke-static {v0, v3}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 46
    .line 47
    .line 48
    invoke-virtual {v2}, Ltop/niunaijun/blackbox/core/system/JarManager;->clearCache()V

    .line 49
    .line 50
    .line 51
    invoke-virtual {v2}, Ltop/niunaijun/blackbox/core/system/JarManager;->initializeSync()V

    .line 52
    .line 53
    .line 54
    invoke-virtual {v2}, Ltop/niunaijun/blackbox/core/system/JarManager;->getEmptyJar()Ljava/io/File;

    .line 55
    .line 56
    .line 57
    move-result-object v3

    .line 58
    :cond_2
    if-eqz v3, :cond_3

    .line 59
    .line 60
    invoke-virtual {v3}, Ljava/io/File;->exists()Z

    .line 61
    .line 62
    .line 63
    move-result v2

    .line 64
    if-eqz v2, :cond_3

    .line 65
    .line 66
    new-instance v2, Ljava/lang/StringBuilder;

    .line 67
    .line 68
    invoke-direct {v2, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 69
    .line 70
    .line 71
    invoke-virtual {v3}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    .line 72
    .line 73
    .line 74
    move-result-object v1

    .line 75
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 76
    .line 77
    .line 78
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 79
    .line 80
    .line 81
    move-result-object v1

    .line 82
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 83
    .line 84
    .line 85
    return-void

    .line 86
    :cond_3
    const-string v1, "Empty JAR still not available after retry"

    .line 87
    .line 88
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 89
    .line 90
    .line 91
    return-void

    .line 92
    :goto_1
    const-string v2, "Error initializing JAR environment"

    .line 93
    .line 94
    invoke-static {v0, v2, v1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 95
    .line 96
    .line 97
    return-void
.end method

.method private installContentProvider(Landroid/app/Application;Landroid/content/pm/ProviderInfo;)V
    .locals 5

    .line 1
    const-string v0, "Content provider installed: "

    .line 2
    .line 3
    const-string v1, "Application class loader is null, using system class loader for: "

    .line 4
    .line 5
    const-string v2, "Skipping anti-detect ContentProvider: "

    .line 6
    .line 7
    const-string v3, "Application is null, cannot install content provider: "

    .line 8
    .line 9
    const-string v4, "BActivityThread"

    .line 10
    .line 11
    if-nez p1, :cond_0

    .line 12
    .line 13
    :try_start_0
    new-instance p1, Ljava/lang/StringBuilder;

    .line 14
    .line 15
    invoke-direct {p1, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 16
    .line 17
    .line 18
    iget-object v0, p2, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 19
    .line 20
    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 21
    .line 22
    .line 23
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 24
    .line 25
    .line 26
    move-result-object p1

    .line 27
    invoke-static {v4, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 28
    .line 29
    .line 30
    return-void

    .line 31
    :catch_0
    move-exception p1

    .line 32
    goto :goto_0

    .line 33
    :cond_0
    iget-object v3, p2, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 34
    .line 35
    if-eqz v3, :cond_1

    .line 36
    .line 37
    invoke-static {v3}, Ltop/niunaijun/blackbox/app/BActivityThread;->isAntiDetectProvider(Ljava/lang/String;)Z

    .line 38
    .line 39
    .line 40
    move-result v3

    .line 41
    if-eqz v3, :cond_1

    .line 42
    .line 43
    new-instance p1, Ljava/lang/StringBuilder;

    .line 44
    .line 45
    invoke-direct {p1, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 46
    .line 47
    .line 48
    iget-object v0, p2, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 49
    .line 50
    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 51
    .line 52
    .line 53
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 54
    .line 55
    .line 56
    move-result-object p1

    .line 57
    invoke-static {v4, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 58
    .line 59
    .line 60
    return-void

    .line 61
    :cond_1
    invoke-virtual {p1}, Landroid/content/Context;->getClassLoader()Ljava/lang/ClassLoader;

    .line 62
    .line 63
    .line 64
    move-result-object v2

    .line 65
    if-nez v2, :cond_2

    .line 66
    .line 67
    new-instance v2, Ljava/lang/StringBuilder;

    .line 68
    .line 69
    invoke-direct {v2, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 70
    .line 71
    .line 72
    iget-object v1, p2, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 73
    .line 74
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 75
    .line 76
    .line 77
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 78
    .line 79
    .line 80
    move-result-object v1

    .line 81
    invoke-static {v4, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 82
    .line 83
    .line 84
    invoke-static {}, Ljava/lang/ClassLoader;->getSystemClassLoader()Ljava/lang/ClassLoader;

    .line 85
    .line 86
    .line 87
    move-result-object v2

    .line 88
    :cond_2
    iget-object v1, p2, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 89
    .line 90
    invoke-virtual {v2, v1}, Ljava/lang/ClassLoader;->loadClass(Ljava/lang/String;)Ljava/lang/Class;

    .line 91
    .line 92
    .line 93
    move-result-object v1

    .line 94
    invoke-virtual {v1}, Ljava/lang/Class;->newInstance()Ljava/lang/Object;

    .line 95
    .line 96
    .line 97
    move-result-object v1

    .line 98
    check-cast v1, Landroid/content/ContentProvider;

    .line 99
    .line 100
    invoke-virtual {v1, p1, p2}, Landroid/content/ContentProvider;->attachInfo(Landroid/content/Context;Landroid/content/pm/ProviderInfo;)V

    .line 101
    .line 102
    .line 103
    new-instance p1, Ljava/lang/StringBuilder;

    .line 104
    .line 105
    invoke-direct {p1, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 106
    .line 107
    .line 108
    iget-object v0, p2, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 109
    .line 110
    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 111
    .line 112
    .line 113
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 114
    .line 115
    .line 116
    move-result-object p1

    .line 117
    invoke-static {v4, p1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 118
    .line 119
    .line 120
    return-void

    .line 121
    :goto_0
    new-instance v0, Ljava/lang/StringBuilder;

    .line 122
    .line 123
    const-string v1, "Error installing content provider "

    .line 124
    .line 125
    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 126
    .line 127
    .line 128
    iget-object p2, p2, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 129
    .line 130
    invoke-virtual {v0, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 131
    .line 132
    .line 133
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 134
    .line 135
    .line 136
    move-result-object p2

    .line 137
    invoke-static {v4, p2, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 138
    .line 139
    .line 140
    return-void
.end method

.method private installContentProvidersWithFallback(Landroid/app/Application;Ljava/lang/Object;)V
    .locals 5

    .line 1
    const-string v0, "BActivityThread"

    .line 2
    .line 3
    const-string v1, "Installing "

    .line 4
    .line 5
    :try_start_0
    invoke-direct {p0, p2}, Ltop/niunaijun/blackbox/app/BActivityThread;->getProviderInfoList(Ljava/lang/Object;)Ljava/util/List;

    .line 6
    .line 7
    .line 8
    move-result-object p2

    .line 9
    if-eqz p2, :cond_1

    .line 10
    .line 11
    invoke-interface {p2}, Ljava/util/List;->isEmpty()Z

    .line 12
    .line 13
    .line 14
    move-result v2

    .line 15
    if-eqz v2, :cond_0

    .line 16
    .line 17
    goto :goto_1

    .line 18
    :cond_0
    new-instance v2, Ljava/lang/StringBuilder;

    .line 19
    .line 20
    invoke-direct {v2, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 21
    .line 22
    .line 23
    invoke-interface {p2}, Ljava/util/List;->size()I

    .line 24
    .line 25
    .line 26
    move-result v1

    .line 27
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 28
    .line 29
    .line 30
    const-string v1, " content providers"

    .line 31
    .line 32
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 33
    .line 34
    .line 35
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 36
    .line 37
    .line 38
    move-result-object v1

    .line 39
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 40
    .line 41
    .line 42
    invoke-interface {p2}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    .line 43
    .line 44
    .line 45
    move-result-object p2

    .line 46
    :goto_0
    invoke-interface {p2}, Ljava/util/Iterator;->hasNext()Z

    .line 47
    .line 48
    .line 49
    move-result v1

    .line 50
    if-eqz v1, :cond_2

    .line 51
    .line 52
    invoke-interface {p2}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 53
    .line 54
    .line 55
    move-result-object v1

    .line 56
    check-cast v1, Landroid/content/pm/ProviderInfo;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_1

    .line 57
    .line 58
    :try_start_1
    invoke-direct {p0, p1, v1}, Ltop/niunaijun/blackbox/app/BActivityThread;->installContentProvider(Landroid/app/Application;Landroid/content/pm/ProviderInfo;)V

    .line 59
    .line 60
    .line 61
    new-instance v2, Ljava/lang/StringBuilder;

    .line 62
    .line 63
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    .line 64
    .line 65
    .line 66
    const-string v3, "Successfully installed provider: "

    .line 67
    .line 68
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 69
    .line 70
    .line 71
    iget-object v3, v1, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 72
    .line 73
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 74
    .line 75
    .line 76
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 77
    .line 78
    .line 79
    move-result-object v2

    .line 80
    invoke-static {v0, v2}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 81
    .line 82
    .line 83
    goto :goto_0

    .line 84
    :catch_0
    move-exception v2

    .line 85
    :try_start_2
    new-instance v3, Ljava/lang/StringBuilder;

    .line 86
    .line 87
    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    .line 88
    .line 89
    .line 90
    const-string v4, "Failed to install provider "

    .line 91
    .line 92
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 93
    .line 94
    .line 95
    iget-object v1, v1, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 96
    .line 97
    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 98
    .line 99
    .line 100
    const-string v1, ": "

    .line 101
    .line 102
    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 103
    .line 104
    .line 105
    invoke-virtual {v2}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 106
    .line 107
    .line 108
    move-result-object v1

    .line 109
    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 110
    .line 111
    .line 112
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 113
    .line 114
    .line 115
    move-result-object v1

    .line 116
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 117
    .line 118
    .line 119
    goto :goto_0

    .line 120
    :catch_1
    move-exception p1

    .line 121
    goto :goto_2

    .line 122
    :cond_1
    :goto_1
    const-string p1, "No content providers to install"

    .line 123
    .line 124
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_1

    .line 125
    .line 126
    .line 127
    return-void

    .line 128
    :goto_2
    const-string p2, "Error installing content providers"

    .line 129
    .line 130
    invoke-static {v0, p2, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 131
    .line 132
    .line 133
    :cond_2
    return-void
.end method

.method public static installProvider(Ljava/lang/Object;Landroid/content/Context;Landroid/content/pm/ProviderInfo;Ljava/lang/Object;)V
    .locals 8

    .line 1
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    const-string v1, "installProvider"

    .line 6
    .line 7
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Reflector;->findMethodByFirstName(Ljava/lang/Class;Ljava/lang/String;)Ljava/lang/reflect/Method;

    .line 8
    .line 9
    .line 10
    move-result-object v0

    .line 11
    if-eqz v0, :cond_0

    .line 12
    .line 13
    const/4 v1, 0x1

    .line 14
    invoke-virtual {v0, v1}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 15
    .line 16
    .line 17
    sget-object v5, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 18
    .line 19
    sget-object v6, Ljava/lang/Boolean;->TRUE:Ljava/lang/Boolean;

    .line 20
    .line 21
    move-object v7, v6

    .line 22
    move-object v2, p1

    .line 23
    move-object v4, p2

    .line 24
    move-object v3, p3

    .line 25
    filled-new-array/range {v2 .. v7}, [Ljava/lang/Object;

    .line 26
    .line 27
    .line 28
    move-result-object p1

    .line 29
    invoke-virtual {v0, p0, p1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 30
    .line 31
    .line 32
    :cond_0
    return-void
.end method

.method private installProviders(Landroid/content/Context;Ljava/lang/String;Ljava/util/List;)V
    .locals 6
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Landroid/content/Context;",
            "Ljava/lang/String;",
            "Ljava/util/List<",
            "Landroid/content/pm/ProviderInfo;",
            ">;)V"
        }
    .end annotation

    .line 1
    invoke-static {}, Landroid/os/Binder;->clearCallingIdentity()J

    .line 2
    .line 3
    .line 4
    move-result-wide v0

    .line 5
    :try_start_0
    invoke-interface {p3}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    .line 6
    .line 7
    .line 8
    move-result-object p3

    .line 9
    :catchall_0
    :cond_0
    :goto_0
    invoke-interface {p3}, Ljava/util/Iterator;->hasNext()Z

    .line 10
    .line 11
    .line 12
    move-result v2

    .line 13
    if-eqz v2, :cond_3

    .line 14
    .line 15
    invoke-interface {p3}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 16
    .line 17
    .line 18
    move-result-object v2

    .line 19
    check-cast v2, Landroid/content/pm/ProviderInfo;
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    .line 20
    .line 21
    :try_start_1
    iget-object v3, v2, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 22
    .line 23
    if-eqz v3, :cond_1

    .line 24
    .line 25
    invoke-static {v3}, Ltop/niunaijun/blackbox/app/BActivityThread;->isAntiDetectProvider(Ljava/lang/String;)Z

    .line 26
    .line 27
    .line 28
    move-result v3

    .line 29
    if-eqz v3, :cond_1

    .line 30
    .line 31
    const-string v3, "BActivityThread"

    .line 32
    .line 33
    new-instance v4, Ljava/lang/StringBuilder;

    .line 34
    .line 35
    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    .line 36
    .line 37
    .line 38
    const-string v5, "Skipping anti-detect ContentProvider: "

    .line 39
    .line 40
    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 41
    .line 42
    .line 43
    iget-object v2, v2, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 44
    .line 45
    invoke-virtual {v4, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 46
    .line 47
    .line 48
    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 49
    .line 50
    .line 51
    move-result-object v2

    .line 52
    invoke-static {v3, v2}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 53
    .line 54
    .line 55
    goto :goto_0

    .line 56
    :cond_1
    iget-object v3, v2, Landroid/content/pm/ProviderInfo;->processName:Ljava/lang/String;

    .line 57
    .line 58
    invoke-virtual {p2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 59
    .line 60
    .line 61
    move-result v3

    .line 62
    if-nez v3, :cond_2

    .line 63
    .line 64
    iget-object v3, v2, Landroid/content/pm/ProviderInfo;->processName:Ljava/lang/String;

    .line 65
    .line 66
    invoke-virtual {p1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    .line 67
    .line 68
    .line 69
    move-result-object v4

    .line 70
    invoke-virtual {v3, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 71
    .line 72
    .line 73
    move-result v3

    .line 74
    if-nez v3, :cond_2

    .line 75
    .line 76
    iget-boolean v3, v2, Landroid/content/pm/ProviderInfo;->multiprocess:Z

    .line 77
    .line 78
    if-eqz v3, :cond_0

    .line 79
    .line 80
    :cond_2
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 81
    .line 82
    .line 83
    move-result-object v3

    .line 84
    const/4 v4, 0x0

    .line 85
    invoke-static {v3, p1, v2, v4}, Ltop/niunaijun/blackbox/app/BActivityThread;->installProvider(Ljava/lang/Object;Landroid/content/Context;Landroid/content/pm/ProviderInfo;Ljava/lang/Object;)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 86
    .line 87
    .line 88
    goto :goto_0

    .line 89
    :catchall_1
    move-exception p1

    .line 90
    goto :goto_1

    .line 91
    :cond_3
    invoke-static {v0, v1}, Landroid/os/Binder;->restoreCallingIdentity(J)V

    .line 92
    .line 93
    .line 94
    invoke-static {}, Ltop/niunaijun/blackbox/fake/delegate/ContentProviderDelegate;->init()V

    .line 95
    .line 96
    .line 97
    return-void

    .line 98
    :goto_1
    invoke-static {v0, v1}, Landroid/os/Binder;->restoreCallingIdentity(J)V

    .line 99
    .line 100
    .line 101
    invoke-static {}, Ltop/niunaijun/blackbox/fake/delegate/ContentProviderDelegate;->init()V

    .line 102
    .line 103
    .line 104
    throw p1
.end method

.method private installProvidersWithErrorHandling(Landroid/content/Context;Ljava/lang/String;Ljava/util/List;)V
    .locals 9
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Landroid/content/Context;",
            "Ljava/lang/String;",
            "Ljava/util/List<",
            "Landroid/content/pm/ProviderInfo;",
            ">;)V"
        }
    .end annotation

    .line 1
    const-string v0, "Error initializing ContentProviderDelegate: "

    .line 2
    .line 3
    const-string v1, ": "

    .line 4
    .line 5
    const-string v2, "BActivityThread"

    .line 6
    .line 7
    invoke-static {}, Landroid/os/Binder;->clearCallingIdentity()J

    .line 8
    .line 9
    .line 10
    move-result-wide v3

    .line 11
    :try_start_0
    invoke-interface {p3}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    .line 12
    .line 13
    .line 14
    move-result-object p3

    .line 15
    :cond_0
    :goto_0
    invoke-interface {p3}, Ljava/util/Iterator;->hasNext()Z

    .line 16
    .line 17
    .line 18
    move-result v5

    .line 19
    if-eqz v5, :cond_2

    .line 20
    .line 21
    invoke-interface {p3}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 22
    .line 23
    .line 24
    move-result-object v5

    .line 25
    check-cast v5, Landroid/content/pm/ProviderInfo;
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    .line 26
    .line 27
    :try_start_1
    iget-object v6, v5, Landroid/content/pm/ProviderInfo;->processName:Ljava/lang/String;

    .line 28
    .line 29
    invoke-virtual {p2, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 30
    .line 31
    .line 32
    move-result v6

    .line 33
    if-nez v6, :cond_1

    .line 34
    .line 35
    iget-object v6, v5, Landroid/content/pm/ProviderInfo;->processName:Ljava/lang/String;

    .line 36
    .line 37
    invoke-virtual {p1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    .line 38
    .line 39
    .line 40
    move-result-object v7

    .line 41
    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 42
    .line 43
    .line 44
    move-result v6

    .line 45
    if-nez v6, :cond_1

    .line 46
    .line 47
    iget-boolean v6, v5, Landroid/content/pm/ProviderInfo;->multiprocess:Z

    .line 48
    .line 49
    if-eqz v6, :cond_0

    .line 50
    .line 51
    goto :goto_1

    .line 52
    :catchall_0
    move-exception v6

    .line 53
    goto :goto_2

    .line 54
    :catch_0
    move-exception v6

    .line 55
    goto :goto_3

    .line 56
    :cond_1
    :goto_1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 57
    .line 58
    .line 59
    move-result-object v6

    .line 60
    const/4 v7, 0x0

    .line 61
    invoke-static {v6, p1, v5, v7}, Ltop/niunaijun/blackbox/app/BActivityThread;->installProvider(Ljava/lang/Object;Landroid/content/Context;Landroid/content/pm/ProviderInfo;Ljava/lang/Object;)V
    :try_end_1
    .catch Ljava/lang/SecurityException; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 62
    .line 63
    .line 64
    goto :goto_0

    .line 65
    :goto_2
    :try_start_2
    new-instance v7, Ljava/lang/StringBuilder;

    .line 66
    .line 67
    invoke-direct {v7}, Ljava/lang/StringBuilder;-><init>()V

    .line 68
    .line 69
    .line 70
    const-string v8, "Error installing provider "

    .line 71
    .line 72
    invoke-virtual {v7, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 73
    .line 74
    .line 75
    iget-object v5, v5, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 76
    .line 77
    invoke-virtual {v7, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 78
    .line 79
    .line 80
    invoke-virtual {v7, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 81
    .line 82
    .line 83
    invoke-virtual {v6}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 84
    .line 85
    .line 86
    move-result-object v5

    .line 87
    invoke-virtual {v7, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 88
    .line 89
    .line 90
    invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 91
    .line 92
    .line 93
    move-result-object v5

    .line 94
    invoke-static {v2, v5}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 95
    .line 96
    .line 97
    goto :goto_0

    .line 98
    :catchall_1
    move-exception p1

    .line 99
    goto :goto_5

    .line 100
    :goto_3
    new-instance v7, Ljava/lang/StringBuilder;

    .line 101
    .line 102
    invoke-direct {v7}, Ljava/lang/StringBuilder;-><init>()V

    .line 103
    .line 104
    .line 105
    const-string v8, "SecurityException installing provider "

    .line 106
    .line 107
    invoke-virtual {v7, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 108
    .line 109
    .line 110
    iget-object v5, v5, Landroid/content/pm/ProviderInfo;->name:Ljava/lang/String;

    .line 111
    .line 112
    invoke-virtual {v7, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 113
    .line 114
    .line 115
    invoke-virtual {v7, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 116
    .line 117
    .line 118
    invoke-virtual {v6}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 119
    .line 120
    .line 121
    move-result-object v5

    .line 122
    invoke-virtual {v7, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 123
    .line 124
    .line 125
    invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 126
    .line 127
    .line 128
    move-result-object v5

    .line 129
    invoke-static {v2, v5}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    .line 130
    .line 131
    .line 132
    goto :goto_0

    .line 133
    :cond_2
    invoke-static {v3, v4}, Landroid/os/Binder;->restoreCallingIdentity(J)V

    .line 134
    .line 135
    .line 136
    :try_start_3
    invoke-static {}, Ltop/niunaijun/blackbox/fake/delegate/ContentProviderDelegate;->init()V
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_1

    .line 137
    .line 138
    .line 139
    goto :goto_4

    .line 140
    :catch_1
    move-exception p1

    .line 141
    invoke-static {v0, p1, v2}, Landroidx/fragment/app/x0;->n(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 142
    .line 143
    .line 144
    :goto_4
    return-void

    .line 145
    :goto_5
    invoke-static {v3, v4}, Landroid/os/Binder;->restoreCallingIdentity(J)V

    .line 146
    .line 147
    .line 148
    :try_start_4
    invoke-static {}, Ltop/niunaijun/blackbox/fake/delegate/ContentProviderDelegate;->init()V
    :try_end_4
    .catch Ljava/lang/Exception; {:try_start_4 .. :try_end_4} :catch_2

    .line 149
    .line 150
    .line 151
    goto :goto_6

    .line 152
    :catch_2
    move-exception p2

    .line 153
    invoke-static {v0, p2, v2}, Landroidx/fragment/app/x0;->n(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 154
    .line 155
    .line 156
    :goto_6
    throw p1
.end method

.method private static isAntiDetectProvider(Ljava/lang/String;)Z
    .locals 1

    .line 1
    invoke-virtual {p0}, Ljava/lang/String;->toLowerCase()Ljava/lang/String;

    .line 2
    .line 3
    .line 4
    move-result-object p0

    .line 5
    const-string v0, "hades"

    .line 6
    .line 7
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 8
    .line 9
    .line 10
    move-result v0

    .line 11
    if-nez v0, :cond_1

    .line 12
    .line 13
    const-string v0, "ztuni"

    .line 14
    .line 15
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 16
    .line 17
    .line 18
    move-result v0

    .line 19
    if-nez v0, :cond_1

    .line 20
    .line 21
    const-string v0, "securityguard"

    .line 22
    .line 23
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 24
    .line 25
    .line 26
    move-result v0

    .line 27
    if-nez v0, :cond_1

    .line 28
    .line 29
    const-string v0, "avdetector"

    .line 30
    .line 31
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 32
    .line 33
    .line 34
    move-result v0

    .line 35
    if-nez v0, :cond_1

    .line 36
    .line 37
    const-string v0, "virtualdetect"

    .line 38
    .line 39
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 40
    .line 41
    .line 42
    move-result v0

    .line 43
    if-nez v0, :cond_1

    .line 44
    .line 45
    const-string v0, "sandboxdetect"

    .line 46
    .line 47
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 48
    .line 49
    .line 50
    move-result v0

    .line 51
    if-nez v0, :cond_1

    .line 52
    .line 53
    const-string v0, "emulatordetect"

    .line 54
    .line 55
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 56
    .line 57
    .line 58
    move-result v0

    .line 59
    if-nez v0, :cond_1

    .line 60
    .line 61
    const-string v0, "fridadetect"

    .line 62
    .line 63
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 64
    .line 65
    .line 66
    move-result v0

    .line 67
    if-nez v0, :cond_1

    .line 68
    .line 69
    const-string v0, "hookdetect"

    .line 70
    .line 71
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 72
    .line 73
    .line 74
    move-result v0

    .line 75
    if-nez v0, :cond_1

    .line 76
    .line 77
    const-string v0, "xposeddetect"

    .line 78
    .line 79
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 80
    .line 81
    .line 82
    move-result v0

    .line 83
    if-nez v0, :cond_1

    .line 84
    .line 85
    const-string v0, "magiskdetect"

    .line 86
    .line 87
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 88
    .line 89
    .line 90
    move-result p0

    .line 91
    if-eqz p0, :cond_0

    .line 92
    .line 93
    goto :goto_0

    .line 94
    :cond_0
    const/4 p0, 0x0

    .line 95
    return p0

    .line 96
    :cond_1
    :goto_0
    const/4 p0, 0x1

    .line 97
    return p0
.end method

.method public static isThreadInit()Z
    .locals 1

    .line 1
    sget-object v0, Ltop/niunaijun/blackbox/app/BActivityThread;->sBActivityThread:Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 2
    .line 3
    if-eqz v0, :cond_0

    .line 4
    .line 5
    const/4 v0, 0x1

    .line 6
    return v0

    .line 7
    :cond_0
    const/4 v0, 0x0

    .line 8
    return v0
.end method

.method private synthetic lambda$bindApplication$0(Ljava/lang/String;Ljava/lang/String;Landroid/os/ConditionVariable;)V
    .locals 0

    .line 1
    invoke-direct {p0, p1, p2}, Ltop/niunaijun/blackbox/app/BActivityThread;->createBindApplicationData(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/Object;

    .line 2
    .line 3
    .line 4
    invoke-virtual {p0, p1, p2}, Ltop/niunaijun/blackbox/app/BActivityThread;->handleBindApplication(Ljava/lang/String;Ljava/lang/String;)V

    .line 5
    .line 6
    .line 7
    invoke-virtual {p3}, Landroid/os/ConditionVariable;->open()V

    .line 8
    .line 9
    .line 10
    return-void
.end method

.method private static lambda$finishActivity$1(Landroid/os/IBinder;)V
    .locals 5

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    const-class v1, Lblack/android/app/ActivityThreadContext;

    .line 6
    .line 7
    const/4 v2, 0x0

    .line 8
    invoke-static {v1, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 9
    .line 10
    .line 11
    move-result-object v0

    .line 12
    check-cast v0, Lblack/android/app/ActivityThreadContext;

    .line 13
    .line 14
    invoke-interface {v0}, Lblack/android/app/ActivityThreadContext;->mActivities()Ljava/util/Map;

    .line 15
    .line 16
    .line 17
    move-result-object v0

    .line 18
    invoke-interface {v0}, Ljava/util/Map;->isEmpty()Z

    .line 19
    .line 20
    .line 21
    move-result v1

    .line 22
    if-eqz v1, :cond_0

    .line 23
    .line 24
    goto :goto_0

    .line 25
    :cond_0
    invoke-interface {v0, p0}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 26
    .line 27
    .line 28
    move-result-object v0

    .line 29
    if-nez v0, :cond_1

    .line 30
    .line 31
    :goto_0
    return-void

    .line 32
    :cond_1
    invoke-static {p0}, Ltop/niunaijun/blackbox/app/BActivityThread;->getActivityByToken(Landroid/os/IBinder;)Landroid/app/Activity;

    .line 33
    .line 34
    .line 35
    move-result-object v0

    .line 36
    :goto_1
    invoke-virtual {v0}, Landroid/app/Activity;->getParent()Landroid/app/Activity;

    .line 37
    .line 38
    .line 39
    move-result-object v1

    .line 40
    if-eqz v1, :cond_2

    .line 41
    .line 42
    invoke-virtual {v0}, Landroid/app/Activity;->getParent()Landroid/app/Activity;

    .line 43
    .line 44
    .line 45
    move-result-object v0

    .line 46
    goto :goto_1

    .line 47
    :cond_2
    const-class v1, Lblack/android/app/ActivityContext;

    .line 48
    .line 49
    invoke-static {v1, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 50
    .line 51
    .line 52
    move-result-object v3

    .line 53
    check-cast v3, Lblack/android/app/ActivityContext;

    .line 54
    .line 55
    invoke-interface {v3}, Lblack/android/app/ActivityContext;->mResultCode()Ljava/lang/Integer;

    .line 56
    .line 57
    .line 58
    move-result-object v3

    .line 59
    invoke-virtual {v3}, Ljava/lang/Integer;->intValue()I

    .line 60
    .line 61
    .line 62
    move-result v3

    .line 63
    invoke-static {v1, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 64
    .line 65
    .line 66
    move-result-object v4

    .line 67
    check-cast v4, Lblack/android/app/ActivityContext;

    .line 68
    .line 69
    invoke-interface {v4}, Lblack/android/app/ActivityContext;->mResultData()Landroid/content/Intent;

    .line 70
    .line 71
    .line 72
    move-result-object v4

    .line 73
    invoke-static {p0, v3, v4}, Ltop/niunaijun/blackbox/utils/compat/ActivityManagerCompat;->finishActivity(Landroid/os/IBinder;ILandroid/content/Intent;)Z

    .line 74
    .line 75
    .line 76
    invoke-static {v1, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 77
    .line 78
    .line 79
    move-result-object p0

    .line 80
    check-cast p0, Lblack/android/app/ActivityContext;

    .line 81
    .line 82
    sget-object v0, Ljava/lang/Boolean;->TRUE:Ljava/lang/Boolean;

    .line 83
    .line 84
    invoke-interface {p0, v0}, Lblack/android/app/ActivityContext;->_set_mFinished(Ljava/lang/Object;)V

    .line 85
    .line 86
    .line 87
    return-void
.end method

.method private static lambda$handleNewIntent$2(Landroid/content/Intent;Landroid/os/IBinder;)V
    .locals 5

    .line 1
    const-class v0, Lblack/com/android/internal/content/ReferrerIntentStatic;

    .line 2
    .line 3
    const/4 v1, 0x0

    .line 4
    const/4 v2, 0x0

    .line 5
    invoke-static {v0, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 6
    .line 7
    .line 8
    move-result-object v0

    .line 9
    check-cast v0, Lblack/com/android/internal/content/ReferrerIntentStatic;

    .line 10
    .line 11
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostPkg()Ljava/lang/String;

    .line 12
    .line 13
    .line 14
    move-result-object v3

    .line 15
    invoke-interface {v0, p0, v3}, Lblack/com/android/internal/content/ReferrerIntentStatic;->_new(Landroid/content/Intent;Ljava/lang/String;)Landroid/content/Intent;

    .line 16
    .line 17
    .line 18
    move-result-object p0

    .line 19
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 20
    .line 21
    .line 22
    move-result-object v0

    .line 23
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 24
    .line 25
    .line 26
    move-result-object v3

    .line 27
    const-class v4, Lblack/android/app/ActivityThreadContext;

    .line 28
    .line 29
    invoke-static {v4, v3, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 30
    .line 31
    .line 32
    move-result-object v3

    .line 33
    check-cast v3, Lblack/android/app/ActivityThreadContext;

    .line 34
    .line 35
    invoke-interface {v3, v1, v1}, Lblack/android/app/ActivityThreadContext;->_check_performNewIntents(Landroid/os/IBinder;Ljava/util/List;)Ljava/lang/reflect/Method;

    .line 36
    .line 37
    .line 38
    move-result-object v3

    .line 39
    if-eqz v3, :cond_0

    .line 40
    .line 41
    invoke-static {v4, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 42
    .line 43
    .line 44
    move-result-object v0

    .line 45
    check-cast v0, Lblack/android/app/ActivityThreadContext;

    .line 46
    .line 47
    invoke-static {p0}, Ljava/util/Collections;->singletonList(Ljava/lang/Object;)Ljava/util/List;

    .line 48
    .line 49
    .line 50
    move-result-object p0

    .line 51
    invoke-interface {v0, p1, p0}, Lblack/android/app/ActivityThreadContext;->performNewIntents(Landroid/os/IBinder;Ljava/util/List;)Ljava/lang/Void;

    .line 52
    .line 53
    .line 54
    return-void

    .line 55
    :cond_0
    const-class v3, Lblack/android/app/ActivityThreadNMR1Context;

    .line 56
    .line 57
    invoke-static {v3, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 58
    .line 59
    .line 60
    move-result-object v4

    .line 61
    check-cast v4, Lblack/android/app/ActivityThreadNMR1Context;

    .line 62
    .line 63
    invoke-interface {v4, v1, v1, v2}, Lblack/android/app/ActivityThreadNMR1Context;->_check_performNewIntents(Landroid/os/IBinder;Ljava/util/List;Z)Ljava/lang/reflect/Method;

    .line 64
    .line 65
    .line 66
    move-result-object v4

    .line 67
    if-eqz v4, :cond_1

    .line 68
    .line 69
    invoke-static {v3, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 70
    .line 71
    .line 72
    move-result-object v0

    .line 73
    check-cast v0, Lblack/android/app/ActivityThreadNMR1Context;

    .line 74
    .line 75
    invoke-static {p0}, Ljava/util/Collections;->singletonList(Ljava/lang/Object;)Ljava/util/List;

    .line 76
    .line 77
    .line 78
    move-result-object p0

    .line 79
    const/4 v1, 0x1

    .line 80
    invoke-interface {v0, p1, p0, v1}, Lblack/android/app/ActivityThreadNMR1Context;->performNewIntents(Landroid/os/IBinder;Ljava/util/List;Z)Ljava/lang/Void;

    .line 81
    .line 82
    .line 83
    return-void

    .line 84
    :cond_1
    const-class v3, Lblack/android/app/ActivityThreadQContext;

    .line 85
    .line 86
    invoke-static {v3, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 87
    .line 88
    .line 89
    move-result-object v4

    .line 90
    check-cast v4, Lblack/android/app/ActivityThreadQContext;

    .line 91
    .line 92
    invoke-interface {v4, v1, v1}, Lblack/android/app/ActivityThreadQContext;->_check_handleNewIntent(Landroid/os/IBinder;Ljava/util/List;)Ljava/lang/reflect/Method;

    .line 93
    .line 94
    .line 95
    move-result-object v1

    .line 96
    if-eqz v1, :cond_2

    .line 97
    .line 98
    invoke-static {v3, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 99
    .line 100
    .line 101
    move-result-object v0

    .line 102
    check-cast v0, Lblack/android/app/ActivityThreadQContext;

    .line 103
    .line 104
    invoke-static {p0}, Ljava/util/Collections;->singletonList(Ljava/lang/Object;)Ljava/util/List;

    .line 105
    .line 106
    .line 107
    move-result-object p0

    .line 108
    invoke-interface {v0, p1, p0}, Lblack/android/app/ActivityThreadQContext;->handleNewIntent(Landroid/os/IBinder;Ljava/util/List;)Ljava/lang/Void;

    .line 109
    .line 110
    .line 111
    :cond_2
    return-void
.end method

.method private lambda$scheduleReceiver$3(Ltop/niunaijun/blackbox/entity/am/ReceiverData;)V
    .locals 7

    .line 1
    const-class v0, Lblack/android/content/BroadcastReceiverContext;

    .line 2
    .line 3
    iget-object v1, p1, Ltop/niunaijun/blackbox/entity/am/ReceiverData;->intent:Landroid/content/Intent;

    .line 4
    .line 5
    iget-object v2, p1, Ltop/niunaijun/blackbox/entity/am/ReceiverData;->activityInfo:Landroid/content/pm/ActivityInfo;

    .line 6
    .line 7
    iget-object v3, p1, Ltop/niunaijun/blackbox/entity/am/ReceiverData;->data:Ltop/niunaijun/blackbox/entity/am/PendingResultData;

    .line 8
    .line 9
    invoke-virtual {v3}, Ltop/niunaijun/blackbox/entity/am/PendingResultData;->build()Landroid/content/BroadcastReceiver$PendingResult;

    .line 10
    .line 11
    .line 12
    move-result-object v3

    .line 13
    const/4 v4, 0x0

    .line 14
    :try_start_0
    iget-object v5, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 15
    .line 16
    invoke-virtual {v5}, Landroid/content/ContextWrapper;->getBaseContext()Landroid/content/Context;

    .line 17
    .line 18
    .line 19
    move-result-object v5

    .line 20
    invoke-virtual {v5}, Landroid/content/Context;->getClassLoader()Ljava/lang/ClassLoader;

    .line 21
    .line 22
    .line 23
    move-result-object v6

    .line 24
    invoke-virtual {v1, v6}, Landroid/content/Intent;->setExtrasClassLoader(Ljava/lang/ClassLoader;)V

    .line 25
    .line 26
    .line 27
    iget-object v2, v2, Landroid/content/pm/ActivityInfo;->name:Ljava/lang/String;

    .line 28
    .line 29
    invoke-virtual {v6, v2}, Ljava/lang/ClassLoader;->loadClass(Ljava/lang/String;)Ljava/lang/Class;

    .line 30
    .line 31
    .line 32
    move-result-object v2

    .line 33
    invoke-virtual {v2}, Ljava/lang/Class;->newInstance()Ljava/lang/Object;

    .line 34
    .line 35
    .line 36
    move-result-object v2

    .line 37
    check-cast v2, Landroid/content/BroadcastReceiver;
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    .line 38
    .line 39
    const/4 v4, 0x0

    .line 40
    :try_start_1
    invoke-static {v0, v2, v4}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 41
    .line 42
    .line 43
    move-result-object v6

    .line 44
    check-cast v6, Lblack/android/content/BroadcastReceiverContext;

    .line 45
    .line 46
    invoke-interface {v6, v3}, Lblack/android/content/BroadcastReceiverContext;->setPendingResult(Ljava/lang/Object;)Ljava/lang/Void;

    .line 47
    .line 48
    .line 49
    invoke-virtual {v2, v5, v1}, Landroid/content/BroadcastReceiver;->onReceive(Landroid/content/Context;Landroid/content/Intent;)V

    .line 50
    .line 51
    .line 52
    invoke-static {v0, v2, v4}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 53
    .line 54
    .line 55
    move-result-object v0

    .line 56
    check-cast v0, Lblack/android/content/BroadcastReceiverContext;

    .line 57
    .line 58
    invoke-interface {v0}, Lblack/android/content/BroadcastReceiverContext;->getPendingResult()Landroid/content/BroadcastReceiver$PendingResult;

    .line 59
    .line 60
    .line 61
    move-result-object v0

    .line 62
    if-eqz v0, :cond_0

    .line 63
    .line 64
    invoke-virtual {v0}, Landroid/content/BroadcastReceiver$PendingResult;->finish()V

    .line 65
    .line 66
    .line 67
    goto :goto_0

    .line 68
    :catchall_0
    move-exception p1

    .line 69
    move-object v4, v2

    .line 70
    goto :goto_1

    .line 71
    :cond_0
    :goto_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBActivityManager()Ltop/niunaijun/blackbox/fake/frameworks/BActivityManager;

    .line 72
    .line 73
    .line 74
    move-result-object v0

    .line 75
    iget-object p1, p1, Ltop/niunaijun/blackbox/entity/am/ReceiverData;->data:Ltop/niunaijun/blackbox/entity/am/PendingResultData;

    .line 76
    .line 77
    invoke-virtual {v0, p1}, Ltop/niunaijun/blackbox/fake/frameworks/BActivityManager;->finishBroadcast(Ltop/niunaijun/blackbox/entity/am/PendingResultData;)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 78
    .line 79
    .line 80
    return-void

    .line 81
    :catchall_1
    move-exception p1

    .line 82
    :goto_1
    invoke-virtual {p1}, Ljava/lang/Throwable;->printStackTrace()V

    .line 83
    .line 84
    .line 85
    new-instance p1, Ljava/lang/StringBuilder;

    .line 86
    .line 87
    const-string v0, "Error receiving broadcast "

    .line 88
    .line 89
    invoke-direct {p1, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 90
    .line 91
    .line 92
    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 93
    .line 94
    .line 95
    const-string v0, " in "

    .line 96
    .line 97
    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 98
    .line 99
    .line 100
    invoke-virtual {p1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 101
    .line 102
    .line 103
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 104
    .line 105
    .line 106
    move-result-object p1

    .line 107
    const-string v0, "BActivityThread"

    .line 108
    .line 109
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 110
    .line 111
    .line 112
    return-void
.end method

.method private onAfterApplicationOnCreate(Ljava/lang/String;Ljava/lang/String;Landroid/app/Application;)V
    .locals 3

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->get()Ltop/niunaijun/blackbox/BlackBoxCore;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/BlackBoxCore;->getAppLifecycleCallbacks()Ljava/util/List;

    .line 6
    .line 7
    .line 8
    move-result-object v0

    .line 9
    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    .line 10
    .line 11
    .line 12
    move-result-object v0

    .line 13
    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    .line 14
    .line 15
    .line 16
    move-result v1

    .line 17
    if-eqz v1, :cond_0

    .line 18
    .line 19
    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 20
    .line 21
    .line 22
    move-result-object v1

    .line 23
    check-cast v1, Ltop/niunaijun/blackbox/app/configuration/AppLifecycleCallback;

    .line 24
    .line 25
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    .line 26
    .line 27
    .line 28
    move-result v2

    .line 29
    invoke-virtual {v1, p1, p2, p3, v2}, Ltop/niunaijun/blackbox/app/configuration/AppLifecycleCallback;->afterApplicationOnCreate(Ljava/lang/String;Ljava/lang/String;Landroid/app/Application;I)V

    .line 30
    .line 31
    .line 32
    goto :goto_0

    .line 33
    :cond_0
    return-void
.end method

.method private onBeforeApplicationOnCreate(Ljava/lang/String;Ljava/lang/String;Landroid/app/Application;)V
    .locals 3

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->get()Ltop/niunaijun/blackbox/BlackBoxCore;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/BlackBoxCore;->getAppLifecycleCallbacks()Ljava/util/List;

    .line 6
    .line 7
    .line 8
    move-result-object v0

    .line 9
    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    .line 10
    .line 11
    .line 12
    move-result-object v0

    .line 13
    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    .line 14
    .line 15
    .line 16
    move-result v1

    .line 17
    if-eqz v1, :cond_0

    .line 18
    .line 19
    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 20
    .line 21
    .line 22
    move-result-object v1

    .line 23
    check-cast v1, Ltop/niunaijun/blackbox/app/configuration/AppLifecycleCallback;

    .line 24
    .line 25
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    .line 26
    .line 27
    .line 28
    move-result v2

    .line 29
    invoke-virtual {v1, p1, p2, p3, v2}, Ltop/niunaijun/blackbox/app/configuration/AppLifecycleCallback;->beforeApplicationOnCreate(Ljava/lang/String;Ljava/lang/String;Landroid/app/Application;I)V

    .line 30
    .line 31
    .line 32
    goto :goto_0

    .line 33
    :cond_0
    return-void
.end method

.method private onBeforeCreateApplication(Ljava/lang/String;Ljava/lang/String;Landroid/content/Context;)V
    .locals 3

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->get()Ltop/niunaijun/blackbox/BlackBoxCore;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/BlackBoxCore;->getAppLifecycleCallbacks()Ljava/util/List;

    .line 6
    .line 7
    .line 8
    move-result-object v0

    .line 9
    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    .line 10
    .line 11
    .line 12
    move-result-object v0

    .line 13
    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    .line 14
    .line 15
    .line 16
    move-result v1

    .line 17
    if-eqz v1, :cond_0

    .line 18
    .line 19
    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 20
    .line 21
    .line 22
    move-result-object v1

    .line 23
    check-cast v1, Ltop/niunaijun/blackbox/app/configuration/AppLifecycleCallback;

    .line 24
    .line 25
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    .line 26
    .line 27
    .line 28
    move-result v2

    .line 29
    invoke-virtual {v1, p1, p2, p3, v2}, Ltop/niunaijun/blackbox/app/configuration/AppLifecycleCallback;->beforeCreateApplication(Ljava/lang/String;Ljava/lang/String;Landroid/content/Context;I)V

    .line 30
    .line 31
    .line 32
    goto :goto_0

    .line 33
    :cond_0
    return-void
.end method

.method private setApplication(Landroid/app/Application;)V
    .locals 4

    .line 1
    const-string v0, "BActivityThread"

    .line 2
    .line 3
    :try_start_0
    iput-object p1, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 4
    .line 5
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 6
    .line 7
    .line 8
    move-result-object v1

    .line 9
    const-class v2, Lblack/android/app/ActivityThreadContext;

    .line 10
    .line 11
    const/4 v3, 0x0

    .line 12
    invoke-static {v2, v1, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 13
    .line 14
    .line 15
    move-result-object v1

    .line 16
    check-cast v1, Lblack/android/app/ActivityThreadContext;

    .line 17
    .line 18
    invoke-interface {v1, p1}, Lblack/android/app/ActivityThreadContext;->_set_mInitialApplication(Ljava/lang/Object;)V

    .line 19
    .line 20
    .line 21
    const-string p1, "Application set in ActivityThread successfully"

    .line 22
    .line 23
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 24
    .line 25
    .line 26
    return-void

    .line 27
    :catch_0
    move-exception p1

    .line 28
    const-string v1, "Error setting application in ActivityThread"

    .line 29
    .line 30
    invoke-static {v0, v1, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 31
    .line 32
    .line 33
    return-void
.end method


# virtual methods
.method public acquireContentProviderClient(Landroid/content/pm/ProviderInfo;)Landroid/os/IBinder;
    .locals 5

    .line 1
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/app/BActivityThread;->isInit()Z

    .line 2
    .line 3
    .line 4
    move-result v0

    .line 5
    if-nez v0, :cond_0

    .line 6
    .line 7
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 8
    .line 9
    .line 10
    move-result-object v0

    .line 11
    iget-object v0, v0, Ltop/niunaijun/blackbox/entity/AppConfig;->packageName:Ljava/lang/String;

    .line 12
    .line 13
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 14
    .line 15
    .line 16
    move-result-object v1

    .line 17
    iget-object v1, v1, Ltop/niunaijun/blackbox/entity/AppConfig;->processName:Ljava/lang/String;

    .line 18
    .line 19
    invoke-virtual {p0, v0, v1}, Ltop/niunaijun/blackbox/app/BActivityThread;->bindApplication(Ljava/lang/String;Ljava/lang/String;)V

    .line 20
    .line 21
    .line 22
    :cond_0
    iget-object p1, p1, Landroid/content/pm/ProviderInfo;->authority:Ljava/lang/String;

    .line 23
    .line 24
    const-string v0, ";"

    .line 25
    .line 26
    invoke-virtual {p1, v0}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    .line 27
    .line 28
    .line 29
    move-result-object p1

    .line 30
    array-length v0, p1

    .line 31
    const/4 v1, 0x0

    .line 32
    move v2, v1

    .line 33
    :goto_0
    if-ge v2, v0, :cond_2

    .line 34
    .line 35
    aget-object v3, p1, v2

    .line 36
    .line 37
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    .line 38
    .line 39
    .line 40
    move-result-object v4

    .line 41
    invoke-virtual {v4}, Landroid/content/Context;->getContentResolver()Landroid/content/ContentResolver;

    .line 42
    .line 43
    .line 44
    move-result-object v4

    .line 45
    invoke-virtual {v4, v3}, Landroid/content/ContentResolver;->acquireContentProviderClient(Ljava/lang/String;)Landroid/content/ContentProviderClient;

    .line 46
    .line 47
    .line 48
    move-result-object v3

    .line 49
    const-class v4, Lblack/android/content/ContentProviderClientContext;

    .line 50
    .line 51
    invoke-static {v4, v3, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 52
    .line 53
    .line 54
    move-result-object v3

    .line 55
    check-cast v3, Lblack/android/content/ContentProviderClientContext;

    .line 56
    .line 57
    invoke-interface {v3}, Lblack/android/content/ContentProviderClientContext;->mContentProvider()Landroid/os/IInterface;

    .line 58
    .line 59
    .line 60
    move-result-object v3

    .line 61
    if-nez v3, :cond_1

    .line 62
    .line 63
    add-int/lit8 v2, v2, 0x1

    .line 64
    .line 65
    goto :goto_0

    .line 66
    :cond_1
    invoke-interface {v3}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    .line 67
    .line 68
    .line 69
    move-result-object p1

    .line 70
    return-object p1

    .line 71
    :cond_2
    const/4 p1, 0x0

    .line 72
    return-object p1
.end method

.method public bindApplication()V
    .locals 2

    .line 7
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/app/BActivityThread;->isInit()Z

    move-result v0

    if-nez v0, :cond_0

    .line 8
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppPackageName()Ljava/lang/String;

    move-result-object v0

    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppProcessName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {p0, v0, v1}, Ltop/niunaijun/blackbox/app/BActivityThread;->bindApplication(Ljava/lang/String;Ljava/lang/String;)V

    :cond_0
    return-void
.end method

.method public bindApplication(Ljava/lang/String;Ljava/lang/String;)V
    .locals 8

    .line 1
    invoke-static {}, Landroid/os/Looper;->myLooper()Landroid/os/Looper;

    move-result-object v0

    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;

    move-result-object v1

    if-eq v0, v1, :cond_0

    .line 2
    new-instance v6, Landroid/os/ConditionVariable;

    invoke-direct {v6}, Landroid/os/ConditionVariable;-><init>()V

    .line 3
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->get()Ltop/niunaijun/blackbox/BlackBoxCore;

    move-result-object v0

    invoke-virtual {v0}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHandler()Landroid/os/Handler;

    move-result-object v0

    new-instance v2, Ltop/niunaijun/blackbox/d;

    const/4 v7, 0x1

    move-object v3, p0

    move-object v4, p1

    move-object v5, p2

    invoke-direct/range {v2 .. v7}, Ltop/niunaijun/blackbox/d;-><init>(Ljava/lang/Object;Ljava/lang/String;Ljava/lang/String;Ljava/lang/Object;I)V

    invoke-virtual {v0, v2}, Landroid/os/Handler;->post(Ljava/lang/Runnable;)Z

    .line 4
    invoke-virtual {v6}, Landroid/os/ConditionVariable;->block()V

    return-void

    :cond_0
    move-object v4, p1

    move-object v5, p2

    .line 5
    invoke-direct {p0, v4, v5}, Ltop/niunaijun/blackbox/app/BActivityThread;->createBindApplicationData(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/Object;

    .line 6
    invoke-virtual {p0, v4, v5}, Ltop/niunaijun/blackbox/app/BActivityThread;->handleBindApplication(Ljava/lang/String;Ljava/lang/String;)V

    return-void
.end method

.method public createJobService(Landroid/content/pm/ServiceInfo;)Landroid/app/job/JobService;
    .locals 18

    .line 1
    move-object/from16 v1, p0

    .line 2
    .line 3
    move-object/from16 v2, p1

    .line 4
    .line 5
    const-string v3, ": "

    .line 6
    .line 7
    const-string v4, "Unable to create JobService "

    .line 8
    .line 9
    const-string v5, "google.android.location"

    .line 10
    .line 11
    const-string v6, "google.android.gms"

    .line 12
    .line 13
    const-string v7, "BActivityThread"

    .line 14
    .line 15
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 16
    .line 17
    .line 18
    move-result-object v0

    .line 19
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/app/BActivityThread;->isInit()Z

    .line 20
    .line 21
    .line 22
    move-result v0

    .line 23
    if-nez v0, :cond_0

    .line 24
    .line 25
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 26
    .line 27
    .line 28
    move-result-object v0

    .line 29
    iget-object v8, v2, Landroid/content/pm/ServiceInfo;->packageName:Ljava/lang/String;

    .line 30
    .line 31
    iget-object v9, v2, Landroid/content/pm/ServiceInfo;->processName:Ljava/lang/String;

    .line 32
    .line 33
    invoke-virtual {v0, v8, v9}, Ltop/niunaijun/blackbox/app/BActivityThread;->bindApplication(Ljava/lang/String;Ljava/lang/String;)V

    .line 34
    .line 35
    .line 36
    :cond_0
    iget-object v0, v1, Ltop/niunaijun/blackbox/app/BActivityThread;->mBoundApplication:Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;

    .line 37
    .line 38
    iget-object v0, v0, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->info:Ljava/lang/Object;

    .line 39
    .line 40
    const-class v8, Lblack/android/app/LoadedApkContext;

    .line 41
    .line 42
    const/4 v9, 0x0

    .line 43
    invoke-static {v8, v0, v9}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 44
    .line 45
    .line 46
    move-result-object v0

    .line 47
    check-cast v0, Lblack/android/app/LoadedApkContext;

    .line 48
    .line 49
    invoke-interface {v0}, Lblack/android/app/LoadedApkContext;->getClassLoader()Ljava/lang/ClassLoader;

    .line 50
    .line 51
    .line 52
    move-result-object v0

    .line 53
    const/4 v8, 0x0

    .line 54
    :try_start_0
    iget-object v10, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 55
    .line 56
    invoke-virtual {v0, v10}, Ljava/lang/ClassLoader;->loadClass(Ljava/lang/String;)Ljava/lang/Class;

    .line 57
    .line 58
    .line 59
    move-result-object v0

    .line 60
    invoke-virtual {v0}, Ljava/lang/Class;->newInstance()Ljava/lang/Object;

    .line 61
    .line 62
    .line 63
    move-result-object v0

    .line 64
    check-cast v0, Landroid/app/job/JobService;
    :try_end_0
    .catch Ljava/lang/ClassNotFoundException; {:try_start_0 .. :try_end_0} :catch_2
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_1

    .line 65
    .line 66
    :try_start_1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    .line 67
    .line 68
    .line 69
    move-result-object v3

    .line 70
    iget-object v4, v2, Landroid/content/pm/ServiceInfo;->packageName:Ljava/lang/String;

    .line 71
    .line 72
    const/4 v10, 0x3

    .line 73
    invoke-virtual {v3, v4, v10}, Landroid/content/Context;->createPackageContext(Ljava/lang/String;I)Landroid/content/Context;

    .line 74
    .line 75
    .line 76
    move-result-object v12

    .line 77
    const-class v3, Lblack/android/app/ContextImplContext;

    .line 78
    .line 79
    invoke-static {v3, v12, v9}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 80
    .line 81
    .line 82
    move-result-object v3

    .line 83
    check-cast v3, Lblack/android/app/ContextImplContext;

    .line 84
    .line 85
    invoke-interface {v3, v0}, Lblack/android/app/ContextImplContext;->setOuterContext(Landroid/content/Context;)Ljava/lang/Void;

    .line 86
    .line 87
    .line 88
    const-class v3, Lblack/android/app/ServiceContext;

    .line 89
    .line 90
    invoke-static {v3, v0, v9}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 91
    .line 92
    .line 93
    move-result-object v3

    .line 94
    move-object v11, v3

    .line 95
    check-cast v11, Lblack/android/app/ServiceContext;

    .line 96
    .line 97
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 98
    .line 99
    .line 100
    move-result-object v13

    .line 101
    iget-object v14, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 102
    .line 103
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 104
    .line 105
    .line 106
    move-result-object v3

    .line 107
    invoke-virtual {v3}, Ltop/niunaijun/blackbox/app/BActivityThread;->getActivityThread()Landroid/os/IBinder;

    .line 108
    .line 109
    .line 110
    move-result-object v15

    .line 111
    iget-object v3, v1, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 112
    .line 113
    invoke-static {}, Le5/a;->a()Lblack/android/app/ActivityManagerNativeStatic;

    .line 114
    .line 115
    .line 116
    move-result-object v4

    .line 117
    invoke-interface {v4}, Lblack/android/app/ActivityManagerNativeStatic;->getDefault()Landroid/os/IInterface;

    .line 118
    .line 119
    .line 120
    move-result-object v17

    .line 121
    move-object/from16 v16, v3

    .line 122
    .line 123
    invoke-interface/range {v11 .. v17}, Lblack/android/app/ServiceContext;->attach(Landroid/content/Context;Ljava/lang/Object;Ljava/lang/String;Landroid/os/IBinder;Landroid/app/Application;Ljava/lang/Object;)Ljava/lang/Void;

    .line 124
    .line 125
    .line 126
    invoke-static {v12}, Ltop/niunaijun/blackbox/utils/compat/ContextCompat;->fix(Landroid/content/Context;)V

    .line 127
    .line 128
    .line 129
    invoke-virtual {v0}, Landroid/app/Service;->onCreate()V

    .line 130
    .line 131
    .line 132
    invoke-virtual {v0, v8}, Landroid/app/job/JobService;->onBind(Landroid/content/Intent;)Landroid/os/IBinder;
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 133
    .line 134
    .line 135
    return-object v0

    .line 136
    :catch_0
    move-exception v0

    .line 137
    iget-object v3, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 138
    .line 139
    invoke-virtual {v3, v6}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 140
    .line 141
    .line 142
    move-result v3

    .line 143
    if-nez v3, :cond_2

    .line 144
    .line 145
    iget-object v3, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 146
    .line 147
    invoke-virtual {v3, v5}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 148
    .line 149
    .line 150
    move-result v3

    .line 151
    if-eqz v3, :cond_1

    .line 152
    .line 153
    goto :goto_0

    .line 154
    :cond_1
    new-instance v3, Ljava/lang/StringBuilder;

    .line 155
    .line 156
    const-string v4, "JobService creation failed, but continuing: "

    .line 157
    .line 158
    invoke-direct {v3, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 159
    .line 160
    .line 161
    iget-object v2, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 162
    .line 163
    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 164
    .line 165
    .line 166
    const-string v2, " - "

    .line 167
    .line 168
    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 169
    .line 170
    .line 171
    invoke-static {v0, v3, v7}, Ltop/niunaijun/blackbox/c;->a(Ljava/lang/Exception;Ljava/lang/StringBuilder;Ljava/lang/String;)V

    .line 172
    .line 173
    .line 174
    return-object v8

    .line 175
    :cond_2
    :goto_0
    new-instance v0, Ljava/lang/StringBuilder;

    .line 176
    .line 177
    const-string v3, "Google Play Services JobService creation failed, skipping: "

    .line 178
    .line 179
    invoke-direct {v0, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 180
    .line 181
    .line 182
    iget-object v2, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 183
    .line 184
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 185
    .line 186
    .line 187
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 188
    .line 189
    .line 190
    move-result-object v0

    .line 191
    invoke-static {v7, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 192
    .line 193
    .line 194
    return-object v8

    .line 195
    :catch_1
    move-exception v0

    .line 196
    goto :goto_1

    .line 197
    :catch_2
    move-exception v0

    .line 198
    goto :goto_2

    .line 199
    :goto_1
    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V

    .line 200
    .line 201
    .line 202
    new-instance v5, Ljava/lang/StringBuilder;

    .line 203
    .line 204
    invoke-direct {v5, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 205
    .line 206
    .line 207
    iget-object v2, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 208
    .line 209
    invoke-virtual {v5, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 210
    .line 211
    .line 212
    invoke-virtual {v5, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 213
    .line 214
    .line 215
    invoke-virtual {v0}, Ljava/lang/Object;->toString()Ljava/lang/String;

    .line 216
    .line 217
    .line 218
    move-result-object v0

    .line 219
    invoke-virtual {v5, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 220
    .line 221
    .line 222
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 223
    .line 224
    .line 225
    move-result-object v0

    .line 226
    invoke-static {v7, v0}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 227
    .line 228
    .line 229
    return-object v8

    .line 230
    :goto_2
    iget-object v9, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 231
    .line 232
    invoke-virtual {v9, v6}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 233
    .line 234
    .line 235
    move-result v6

    .line 236
    if-nez v6, :cond_4

    .line 237
    .line 238
    iget-object v6, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 239
    .line 240
    invoke-virtual {v6, v5}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 241
    .line 242
    .line 243
    move-result v5

    .line 244
    if-eqz v5, :cond_3

    .line 245
    .line 246
    goto :goto_3

    .line 247
    :cond_3
    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V

    .line 248
    .line 249
    .line 250
    new-instance v5, Ljava/lang/StringBuilder;

    .line 251
    .line 252
    invoke-direct {v5, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 253
    .line 254
    .line 255
    iget-object v2, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 256
    .line 257
    invoke-virtual {v5, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 258
    .line 259
    .line 260
    invoke-virtual {v5, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 261
    .line 262
    .line 263
    invoke-virtual {v0}, Ljava/lang/Object;->toString()Ljava/lang/String;

    .line 264
    .line 265
    .line 266
    move-result-object v0

    .line 267
    invoke-virtual {v5, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 268
    .line 269
    .line 270
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 271
    .line 272
    .line 273
    move-result-object v0

    .line 274
    invoke-static {v7, v0}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 275
    .line 276
    .line 277
    return-object v8

    .line 278
    :cond_4
    :goto_3
    new-instance v0, Ljava/lang/StringBuilder;

    .line 279
    .line 280
    const-string v3, "Google Play Services JobService class not found, skipping: "

    .line 281
    .line 282
    invoke-direct {v0, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 283
    .line 284
    .line 285
    iget-object v2, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 286
    .line 287
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 288
    .line 289
    .line 290
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 291
    .line 292
    .line 293
    move-result-object v0

    .line 294
    invoke-static {v7, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 295
    .line 296
    .line 297
    return-object v8
.end method

.method public createService(Landroid/content/pm/ServiceInfo;Landroid/os/IBinder;)Landroid/app/Service;
    .locals 18

    .line 1
    move-object/from16 v1, p0

    .line 2
    .line 3
    move-object/from16 v2, p1

    .line 4
    .line 5
    const-string v3, ": "

    .line 6
    .line 7
    const-string v4, "Unable to instantiate service "

    .line 8
    .line 9
    const-string v5, "google.android.location"

    .line 10
    .line 11
    const-string v6, "google.android.gms"

    .line 12
    .line 13
    const-string v7, "BActivityThread"

    .line 14
    .line 15
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 16
    .line 17
    .line 18
    move-result-object v0

    .line 19
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/app/BActivityThread;->isInit()Z

    .line 20
    .line 21
    .line 22
    move-result v0

    .line 23
    if-nez v0, :cond_0

    .line 24
    .line 25
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->currentActivityThread()Ltop/niunaijun/blackbox/app/BActivityThread;

    .line 26
    .line 27
    .line 28
    move-result-object v0

    .line 29
    iget-object v8, v2, Landroid/content/pm/ServiceInfo;->packageName:Ljava/lang/String;

    .line 30
    .line 31
    iget-object v9, v2, Landroid/content/pm/ServiceInfo;->processName:Ljava/lang/String;

    .line 32
    .line 33
    invoke-virtual {v0, v8, v9}, Ltop/niunaijun/blackbox/app/BActivityThread;->bindApplication(Ljava/lang/String;Ljava/lang/String;)V

    .line 34
    .line 35
    .line 36
    :cond_0
    iget-object v0, v1, Ltop/niunaijun/blackbox/app/BActivityThread;->mBoundApplication:Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;

    .line 37
    .line 38
    iget-object v0, v0, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->info:Ljava/lang/Object;

    .line 39
    .line 40
    const-class v8, Lblack/android/app/LoadedApkContext;

    .line 41
    .line 42
    const/4 v9, 0x0

    .line 43
    invoke-static {v8, v0, v9}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 44
    .line 45
    .line 46
    move-result-object v0

    .line 47
    check-cast v0, Lblack/android/app/LoadedApkContext;

    .line 48
    .line 49
    invoke-interface {v0}, Lblack/android/app/LoadedApkContext;->getClassLoader()Ljava/lang/ClassLoader;

    .line 50
    .line 51
    .line 52
    move-result-object v0

    .line 53
    const/4 v8, 0x0

    .line 54
    :try_start_0
    iget-object v10, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 55
    .line 56
    invoke-virtual {v0, v10}, Ljava/lang/ClassLoader;->loadClass(Ljava/lang/String;)Ljava/lang/Class;

    .line 57
    .line 58
    .line 59
    move-result-object v0

    .line 60
    invoke-virtual {v0}, Ljava/lang/Class;->newInstance()Ljava/lang/Object;

    .line 61
    .line 62
    .line 63
    move-result-object v0

    .line 64
    check-cast v0, Landroid/app/Service;
    :try_end_0
    .catch Ljava/lang/ClassNotFoundException; {:try_start_0 .. :try_end_0} :catch_2
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_1

    .line 65
    .line 66
    :try_start_1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    .line 67
    .line 68
    .line 69
    move-result-object v3

    .line 70
    iget-object v4, v2, Landroid/content/pm/ServiceInfo;->packageName:Ljava/lang/String;

    .line 71
    .line 72
    const/4 v10, 0x3

    .line 73
    invoke-virtual {v3, v4, v10}, Landroid/content/Context;->createPackageContext(Ljava/lang/String;I)Landroid/content/Context;

    .line 74
    .line 75
    .line 76
    move-result-object v12

    .line 77
    const-class v3, Lblack/android/app/ContextImplContext;

    .line 78
    .line 79
    invoke-static {v3, v12, v9}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 80
    .line 81
    .line 82
    move-result-object v3

    .line 83
    check-cast v3, Lblack/android/app/ContextImplContext;

    .line 84
    .line 85
    invoke-interface {v3, v0}, Lblack/android/app/ContextImplContext;->setOuterContext(Landroid/content/Context;)Ljava/lang/Void;

    .line 86
    .line 87
    .line 88
    const-class v3, Lblack/android/app/ServiceContext;

    .line 89
    .line 90
    invoke-static {v3, v0, v9}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 91
    .line 92
    .line 93
    move-result-object v3

    .line 94
    move-object v11, v3

    .line 95
    check-cast v11, Lblack/android/app/ServiceContext;

    .line 96
    .line 97
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 98
    .line 99
    .line 100
    move-result-object v13

    .line 101
    iget-object v14, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 102
    .line 103
    iget-object v3, v1, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 104
    .line 105
    invoke-static {}, Le5/a;->a()Lblack/android/app/ActivityManagerNativeStatic;

    .line 106
    .line 107
    .line 108
    move-result-object v4

    .line 109
    invoke-interface {v4}, Lblack/android/app/ActivityManagerNativeStatic;->getDefault()Landroid/os/IInterface;

    .line 110
    .line 111
    .line 112
    move-result-object v17

    .line 113
    move-object/from16 v15, p2

    .line 114
    .line 115
    move-object/from16 v16, v3

    .line 116
    .line 117
    invoke-interface/range {v11 .. v17}, Lblack/android/app/ServiceContext;->attach(Landroid/content/Context;Ljava/lang/Object;Ljava/lang/String;Landroid/os/IBinder;Landroid/app/Application;Ljava/lang/Object;)Ljava/lang/Void;

    .line 118
    .line 119
    .line 120
    invoke-static {v12}, Ltop/niunaijun/blackbox/utils/compat/ContextCompat;->fix(Landroid/content/Context;)V

    .line 121
    .line 122
    .line 123
    invoke-virtual {v0}, Landroid/app/Service;->onCreate()V

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->serviceCreated(Landroid/app/Service;)V
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 124
    .line 125
    .line 126
    return-object v0

    .line 127
    :catch_0
    move-exception v0

    .line 128
    iget-object v3, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 129
    .line 130
    invoke-virtual {v3, v6}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 131
    .line 132
    .line 133
    move-result v3

    .line 134
    if-nez v3, :cond_2

    .line 135
    .line 136
    iget-object v3, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 137
    .line 138
    invoke-virtual {v3, v5}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 139
    .line 140
    .line 141
    move-result v3

    .line 142
    if-eqz v3, :cond_1

    .line 143
    .line 144
    goto :goto_0

    .line 145
    :cond_1
    new-instance v3, Ljava/lang/StringBuilder;

    .line 146
    .line 147
    const-string v4, "Service creation failed, but continuing: "

    .line 148
    .line 149
    invoke-direct {v3, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 150
    .line 151
    .line 152
    iget-object v2, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 153
    .line 154
    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 155
    .line 156
    .line 157
    const-string v2, " - "

    .line 158
    .line 159
    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 160
    .line 161
    .line 162
    invoke-static {v0, v3, v7}, Ltop/niunaijun/blackbox/c;->a(Ljava/lang/Exception;Ljava/lang/StringBuilder;Ljava/lang/String;)V

    .line 163
    .line 164
    .line 165
    return-object v8

    .line 166
    :cond_2
    :goto_0
    new-instance v0, Ljava/lang/StringBuilder;

    .line 167
    .line 168
    const-string v3, "Google Play Services service creation failed, skipping: "

    .line 169
    .line 170
    invoke-direct {v0, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 171
    .line 172
    .line 173
    iget-object v2, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 174
    .line 175
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 176
    .line 177
    .line 178
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 179
    .line 180
    .line 181
    move-result-object v0

    .line 182
    invoke-static {v7, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 183
    .line 184
    .line 185
    return-object v8

    .line 186
    :catch_1
    move-exception v0

    .line 187
    goto :goto_1

    .line 188
    :catch_2
    move-exception v0

    .line 189
    goto :goto_2

    .line 190
    :goto_1
    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V

    .line 191
    .line 192
    .line 193
    new-instance v5, Ljava/lang/StringBuilder;

    .line 194
    .line 195
    invoke-direct {v5, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 196
    .line 197
    .line 198
    iget-object v2, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 199
    .line 200
    invoke-virtual {v5, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 201
    .line 202
    .line 203
    invoke-virtual {v5, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 204
    .line 205
    .line 206
    invoke-virtual {v0}, Ljava/lang/Object;->toString()Ljava/lang/String;

    .line 207
    .line 208
    .line 209
    move-result-object v0

    .line 210
    invoke-virtual {v5, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 211
    .line 212
    .line 213
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 214
    .line 215
    .line 216
    move-result-object v0

    .line 217
    invoke-static {v7, v0}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 218
    .line 219
    .line 220
    return-object v8

    .line 221
    :goto_2
    iget-object v9, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 222
    .line 223
    invoke-virtual {v9, v6}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 224
    .line 225
    .line 226
    move-result v6

    .line 227
    if-nez v6, :cond_4

    .line 228
    .line 229
    iget-object v6, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 230
    .line 231
    invoke-virtual {v6, v5}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 232
    .line 233
    .line 234
    move-result v5

    .line 235
    if-eqz v5, :cond_3

    .line 236
    .line 237
    goto :goto_3

    .line 238
    :cond_3
    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V

    .line 239
    .line 240
    .line 241
    new-instance v5, Ljava/lang/StringBuilder;

    .line 242
    .line 243
    invoke-direct {v5, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 244
    .line 245
    .line 246
    iget-object v2, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 247
    .line 248
    invoke-virtual {v5, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 249
    .line 250
    .line 251
    invoke-virtual {v5, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 252
    .line 253
    .line 254
    invoke-virtual {v0}, Ljava/lang/Object;->toString()Ljava/lang/String;

    .line 255
    .line 256
    .line 257
    move-result-object v0

    .line 258
    invoke-virtual {v5, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 259
    .line 260
    .line 261
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 262
    .line 263
    .line 264
    move-result-object v0

    .line 265
    invoke-static {v7, v0}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 266
    .line 267
    .line 268
    return-object v8

    .line 269
    :cond_4
    :goto_3
    new-instance v0, Ljava/lang/StringBuilder;

    .line 270
    .line 271
    const-string v3, "Google Play Services class not found, skipping: "

    .line 272
    .line 273
    invoke-direct {v0, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 274
    .line 275
    .line 276
    iget-object v2, v2, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 277
    .line 278
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 279
    .line 280
    .line 281
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 282
    .line 283
    .line 284
    move-result-object v0

    .line 285
    invoke-static {v7, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 286
    .line 287
    .line 288
    return-object v8
.end method

.method public finishActivity(Landroid/os/IBinder;)V
    .locals 3

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mH:Landroid/os/Handler;

    .line 2
    .line 3
    new-instance v1, La0/a;

    .line 4
    .line 5
    const/16 v2, 0xe

    .line 6
    .line 7
    invoke-direct {v1, v2, p1}, La0/a;-><init>(ILjava/lang/Object;)V

    .line 8
    .line 9
    .line 10
    invoke-virtual {v0, v1}, Landroid/os/Handler;->post(Ljava/lang/Runnable;)Z

    .line 11
    .line 12
    .line 13
    return-void
.end method

.method public getActivityThread()Landroid/os/IBinder;
    .locals 3

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    const-class v1, Lblack/android/app/ActivityThreadContext;

    .line 6
    .line 7
    const/4 v2, 0x0

    .line 8
    invoke-static {v1, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 9
    .line 10
    .line 11
    move-result-object v0

    .line 12
    check-cast v0, Lblack/android/app/ActivityThreadContext;

    .line 13
    .line 14
    invoke-interface {v0}, Lblack/android/app/ActivityThreadContext;->getApplicationThread()Landroid/os/IBinder;

    .line 15
    .line 16
    .line 17
    move-result-object v0

    .line 18
    return-object v0
.end method

.method public getPackageInfo()Ljava/lang/Object;
    .locals 1

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mBoundApplication:Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;

    .line 2
    .line 3
    iget-object v0, v0, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->info:Ljava/lang/Object;

    .line 4
    .line 5
    return-object v0
.end method

.method public declared-synchronized handleBindApplication(Ljava/lang/String;Ljava/lang/String;)V
    .locals 9

    .line 1
    monitor-enter p0

    .line 2
    :try_start_0
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/app/BActivityThread;->isInit()Z

    .line 3
    .line 4
    .line 5
    move-result v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    .line 6
    if-eqz v0, :cond_0

    .line 7
    .line 8
    goto/16 :goto_4

    .line 9
    .line 10
    :cond_0
    :try_start_1
    invoke-static {}, Ltop/niunaijun/blackbox/core/CrashHandler;->create()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 11
    .line 12
    .line 13
    :catchall_0
    :try_start_2
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBPackageManager()Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;

    .line 14
    .line 15
    .line 16
    move-result-object v0

    .line 17
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    .line 18
    .line 19
    .line 20
    move-result v1

    .line 21
    const/16 v2, 0x8

    .line 22
    .line 23
    invoke-virtual {v0, p1, v2, v1}, Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;->getPackageInfo(Ljava/lang/String;II)Landroid/content/pm/PackageInfo;

    .line 24
    .line 25
    .line 26
    move-result-object v0

    .line 27
    iget-object v1, v0, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 28
    .line 29
    iget-object v2, v0, Landroid/content/pm/PackageInfo;->providers:[Landroid/content/pm/ProviderInfo;

    .line 30
    .line 31
    const/4 v3, 0x0

    .line 32
    if-nez v2, :cond_1

    .line 33
    .line 34
    new-array v2, v3, [Landroid/content/pm/ProviderInfo;

    .line 35
    .line 36
    iput-object v2, v0, Landroid/content/pm/PackageInfo;->providers:[Landroid/content/pm/ProviderInfo;

    .line 37
    .line 38
    goto :goto_0

    .line 39
    :catchall_1
    move-exception p1

    .line 40
    goto/16 :goto_6

    .line 41
    .line 42
    :cond_1
    :goto_0
    iget-object v2, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mProviders:Ljava/util/List;

    .line 43
    .line 44
    iget-object v0, v0, Landroid/content/pm/PackageInfo;->providers:[Landroid/content/pm/ProviderInfo;

    .line 45
    .line 46
    invoke-static {v0}, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;

    .line 47
    .line 48
    .line 49
    move-result-object v0

    .line 50
    invoke-interface {v2, v0}, Ljava/util/List;->addAll(Ljava/util/Collection;)Z

    .line 51
    .line 52
    .line 53
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 54
    .line 55
    .line 56
    move-result-object v0

    .line 57
    const-class v2, Lblack/android/app/ActivityThreadContext;

    .line 58
    .line 59
    invoke-static {v2, v0, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 60
    .line 61
    .line 62
    move-result-object v0

    .line 63
    check-cast v0, Lblack/android/app/ActivityThreadContext;

    .line 64
    .line 65
    invoke-interface {v0}, Lblack/android/app/ActivityThreadContext;->mBoundApplication()Ljava/lang/Object;

    .line 66
    .line 67
    .line 68
    move-result-object v0

    .line 69
    invoke-static {v1}, Ltop/niunaijun/blackbox/app/BActivityThread;->createPackageContext(Landroid/content/pm/ApplicationInfo;)Landroid/content/Context;

    .line 70
    .line 71
    .line 72
    move-result-object v2

    invoke-static {v2}, Ltop/niunaijun/blackbox/app/BActivityThread;->applyGuestRegion(Landroid/content/Context;)V

    .line 73
    const-class v4, Lblack/android/app/ContextImplContext;

    .line 74
    .line 75
    invoke-static {v4, v2, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 76
    .line 77
    .line 78
    move-result-object v4

    .line 79
    check-cast v4, Lblack/android/app/ContextImplContext;

    .line 80
    .line 81
    invoke-interface {v4}, Lblack/android/app/ContextImplContext;->mPackageInfo()Ljava/lang/Object;

    .line 82
    .line 83
    .line 84
    move-result-object v4

    .line 85
    const-class v5, Lblack/android/app/LoadedApkContext;

    .line 86
    .line 87
    invoke-static {v5, v4, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 88
    .line 89
    .line 90
    move-result-object v5

    .line 91
    check-cast v5, Lblack/android/app/LoadedApkContext;

    .line 92
    .line 93
    sget-object v6, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 94
    .line 95
    invoke-interface {v5, v6}, Lblack/android/app/LoadedApkContext;->_set_mSecurityViolation(Ljava/lang/Object;)V

    .line 96
    .line 97
    .line 98
    const-class v5, Lblack/android/app/LoadedApkContext;

    .line 99
    .line 100
    invoke-static {v5, v4, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 101
    .line 102
    .line 103
    move-result-object v5

    .line 104
    check-cast v5, Lblack/android/app/LoadedApkContext;

    .line 105
    .line 106
    invoke-interface {v5, v1}, Lblack/android/app/LoadedApkContext;->_set_mApplicationInfo(Ljava/lang/Object;)V

    .line 107
    .line 108
    .line 109
    iget v5, v1, Landroid/content/pm/ApplicationInfo;->targetSdkVersion:I

    .line 110
    .line 111
    const/16 v6, 0x9

    .line 112
    .line 113
    if-ge v5, v6, :cond_2

    .line 114
    .line 115
    new-instance v6, Landroid/os/StrictMode$ThreadPolicy$Builder;

    .line 116
    .line 117
    invoke-static {}, Landroid/os/StrictMode;->getThreadPolicy()Landroid/os/StrictMode$ThreadPolicy;

    .line 118
    .line 119
    .line 120
    move-result-object v7

    .line 121
    invoke-direct {v6, v7}, Landroid/os/StrictMode$ThreadPolicy$Builder;-><init>(Landroid/os/StrictMode$ThreadPolicy;)V

    .line 122
    .line 123
    .line 124
    invoke-virtual {v6}, Landroid/os/StrictMode$ThreadPolicy$Builder;->permitNetwork()Landroid/os/StrictMode$ThreadPolicy$Builder;

    .line 125
    .line 126
    .line 127
    move-result-object v6

    .line 128
    invoke-virtual {v6}, Landroid/os/StrictMode$ThreadPolicy$Builder;->build()Landroid/os/StrictMode$ThreadPolicy;

    .line 129
    .line 130
    .line 131
    move-result-object v6

    .line 132
    invoke-static {v6}, Landroid/os/StrictMode;->setThreadPolicy(Landroid/os/StrictMode$ThreadPolicy;)V

    .line 133
    .line 134
    .line 135
    :cond_2
    sget v6, Landroid/os/Build$VERSION;->SDK_INT:I

    .line 136
    .line 137
    const/16 v7, 0x18

    .line 138
    .line 139
    if-ge v5, v7, :cond_3

    .line 140
    .line 141
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/StrictModeCompat;->disableDeathOnFileUriExposure()Z

    .line 142
    .line 143
    .line 144
    :cond_3
    const/16 v5, 0x1c

    .line 145
    .line 146
    if-lt v6, v5, :cond_4

    .line 147
    .line 148
    new-instance v5, Ljava/lang/StringBuilder;

    .line 149
    .line 150
    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    .line 151
    .line 152
    .line 153
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    .line 154
    .line 155
    .line 156
    move-result v7

    .line 157
    invoke-virtual {v5, v7}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 158
    .line 159
    .line 160
    const-string v7, ":"

    .line 161
    .line 162
    invoke-virtual {v5, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 163
    .line 164
    .line 165
    invoke-virtual {v5, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 166
    .line 167
    .line 168
    const-string v7, ":"

    .line 169
    .line 170
    invoke-virtual {v5, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 171
    .line 172
    .line 173
    invoke-virtual {v5, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 174
    .line 175
    .line 176
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 177
    .line 178
    .line 179
    move-result-object v5

    .line 180
    invoke-static {v5}, La1/q;->x(Ljava/lang/String;)V

    .line 181
    .line 182
    .line 183
    :cond_4
    invoke-static {p2, v1}, Ltop/niunaijun/blackbox/core/env/VirtualRuntime;->setupRuntime(Ljava/lang/String;Landroid/content/pm/ApplicationInfo;)V

    .line 184
    .line 185
    .line 186
    const-class v5, Lblack/dalvik/system/VMRuntimeStatic;

    .line 187
    .line 188
    const/4 v7, 0x0

    .line 189
    invoke-static {v5, v7, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 190
    .line 191
    .line 192
    move-result-object v5

    .line 193
    check-cast v5, Lblack/dalvik/system/VMRuntimeStatic;

    .line 194
    .line 195
    invoke-interface {v5}, Lblack/dalvik/system/VMRuntimeStatic;->getRuntime()Ljava/lang/Object;

    .line 196
    .line 197
    .line 198
    move-result-object v5

    .line 199
    const-class v8, Lblack/dalvik/system/VMRuntimeContext;

    .line 200
    .line 201
    invoke-static {v8, v5, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 202
    .line 203
    .line 204
    move-result-object v5

    .line 205
    check-cast v5, Lblack/dalvik/system/VMRuntimeContext;

    .line 206
    .line 207
    iget v8, v1, Landroid/content/pm/ApplicationInfo;->targetSdkVersion:I

    .line 208
    .line 209
    invoke-interface {v5, v8}, Lblack/dalvik/system/VMRuntimeContext;->setTargetSdkVersion(I)Ljava/lang/Void;

    .line 210
    .line 211
    .line 212
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isS()Z

    .line 213
    .line 214
    .line 215
    move-result v5

    .line 216
    if-eqz v5, :cond_5

    .line 217
    .line 218
    const-class v5, Lblack/android/graphics/CompatibilityStatic;

    .line 219
    .line 220
    invoke-static {v5, v7, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 221
    .line 222
    .line 223
    move-result-object v5

    .line 224
    check-cast v5, Lblack/android/graphics/CompatibilityStatic;

    .line 225
    .line 226
    iget v8, v1, Landroid/content/pm/ApplicationInfo;->targetSdkVersion:I

    .line 227
    .line 228
    invoke-interface {v5, v8}, Lblack/android/graphics/CompatibilityStatic;->setTargetSdkVersion(I)Ljava/lang/Void;

    .line 229
    .line 230
    .line 231
    :cond_5
    invoke-static {v6}, Ltop/niunaijun/blackbox/core/NativeCore;->init(I)V

    .line 232
    .line 233
    .line 234
    invoke-static {}, Ltop/niunaijun/blackbox/core/IOCore;->get()Ltop/niunaijun/blackbox/core/IOCore;

    .line 235
    .line 236
    .line 237
    move-result-object v5

    .line 238
    invoke-virtual {v5, v2}, Ltop/niunaijun/blackbox/core/IOCore;->enableRedirect(Landroid/content/Context;)V

    .line 239
    .line 240
    .line 241
    new-instance v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;

    .line 242
    .line 243
    invoke-direct {v5}, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;-><init>()V

    .line 244
    .line 245
    .line 246
    iput-object v1, v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->appInfo:Landroid/content/pm/ApplicationInfo;

    .line 247
    .line 248
    iput-object p2, v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->processName:Ljava/lang/String;

    .line 249
    .line 250
    iput-object v4, v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->info:Ljava/lang/Object;

    .line 251
    .line 252
    iget-object v1, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mProviders:Ljava/util/List;

    .line 253
    .line 254
    iput-object v1, v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->providers:Ljava/util/List;

    .line 255
    .line 256
    const-class v1, Lblack/android/app/ActivityThreadAppBindDataContext;

    .line 257
    .line 258
    invoke-static {v1, v0, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 259
    .line 260
    .line 261
    move-result-object v0

    .line 262
    check-cast v0, Lblack/android/app/ActivityThreadAppBindDataContext;

    .line 263
    .line 264
    new-instance v1, Landroid/content/ComponentName;

    .line 265
    .line 266
    iget-object v6, v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->appInfo:Landroid/content/pm/ApplicationInfo;

    .line 267
    .line 268
    iget-object v6, v6, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 269
    .line 270
    const-class v8, Landroid/app/Instrumentation;

    .line 271
    .line 272
    invoke-virtual {v8}, Ljava/lang/Class;->getName()Ljava/lang/String;

    .line 273
    .line 274
    .line 275
    move-result-object v8

    .line 276
    invoke-direct {v1, v6, v8}, Landroid/content/ComponentName;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    .line 277
    .line 278
    .line 279
    invoke-interface {v0, v1}, Lblack/android/app/ActivityThreadAppBindDataContext;->_set_instrumentationName(Ljava/lang/Object;)V

    .line 280
    .line 281
    .line 282
    iget-object v1, v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->appInfo:Landroid/content/pm/ApplicationInfo;

    .line 283
    .line 284
    invoke-interface {v0, v1}, Lblack/android/app/ActivityThreadAppBindDataContext;->_set_appInfo(Ljava/lang/Object;)V

    .line 285
    .line 286
    .line 287
    iget-object v1, v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->info:Ljava/lang/Object;

    .line 288
    .line 289
    invoke-interface {v0, v1}, Lblack/android/app/ActivityThreadAppBindDataContext;->_set_info(Ljava/lang/Object;)V

    .line 290
    .line 291
    .line 292
    iget-object v1, v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->processName:Ljava/lang/String;

    .line 293
    .line 294
    invoke-interface {v0, v1}, Lblack/android/app/ActivityThreadAppBindDataContext;->_set_processName(Ljava/lang/Object;)V

    .line 295
    .line 296
    .line 297
    iget-object v1, v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->providers:Ljava/util/List;

    .line 298
    .line 299
    invoke-interface {v0, v1}, Lblack/android/app/ActivityThreadAppBindDataContext;->_set_providers(Ljava/lang/Object;)V

    .line 300
    .line 301
    .line 302
    iput-object v5, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mBoundApplication:Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;

    .line 303
    .line 304
    const-class v0, Lblack/android/security/net/config/NetworkSecurityConfigProviderContext;

    .line 305
    .line 306
    invoke-static {v0}, Ltop/niunaijun/blackreflection/utils/ClassUtil;->classReady(Ljava/lang/Class;)Ljava/lang/Class;

    .line 307
    .line 308
    .line 309
    move-result-object v0

    .line 310
    if-eqz v0, :cond_6

    .line 311
    .line 312
    const-string v0, "AndroidNSSP"

    .line 313
    .line 314
    invoke-static {v0}, Ljava/security/Security;->removeProvider(Ljava/lang/String;)V

    .line 315
    .line 316
    .line 317
    const-class v0, Lblack/android/security/net/config/NetworkSecurityConfigProviderStatic;

    .line 318
    .line 319
    invoke-static {v0, v7, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 320
    .line 321
    .line 322
    move-result-object v0

    .line 323
    check-cast v0, Lblack/android/security/net/config/NetworkSecurityConfigProviderStatic;

    .line 324
    .line 325
    invoke-interface {v0, v2}, Lblack/android/security/net/config/NetworkSecurityConfigProviderStatic;->install(Landroid/content/Context;)Ljava/lang/Void;
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    .line 326
    .line 327
    .line 328
    :cond_6
    :try_start_3
    invoke-direct {p0, p1, p2, v2}, Ltop/niunaijun/blackbox/app/BActivityThread;->onBeforeCreateApplication(Ljava/lang/String;Ljava/lang/String;Landroid/content/Context;)V
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    .line 329
    .line 330
    .line 331
    :try_start_4
    const-class v0, Lblack/android/app/LoadedApkContext;

    .line 332
    .line 333
    invoke-static {v0, v4, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 334
    .line 335
    .line 336
    move-result-object v0

    .line 337
    check-cast v0, Lblack/android/app/LoadedApkContext;

    .line 338
    .line 339
    invoke-interface {v0, v3, v7}, Lblack/android/app/LoadedApkContext;->makeApplication(ZLandroid/app/Instrumentation;)Landroid/app/Application;

    .line 340
    .line 341
    .line 342
    move-result-object v0
    :try_end_4
    .catch Ljava/lang/Exception; {:try_start_4 .. :try_end_4} :catch_0
    .catchall {:try_start_4 .. :try_end_4} :catchall_1

    .line 343
    goto :goto_1

    .line 344
    :catch_0
    move-exception v0

    .line 345
    :try_start_5
    const-string v1, "BActivityThread"

    .line 346
    .line 347
    const-string v6, "Failed to makeApplication, trying fallback approach"

    .line 348
    .line 349
    invoke-static {v1, v6, v0}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 350
    .line 351
    .line 352
    move-object v0, v7

    .line 353
    :goto_1
    if-nez v0, :cond_8

    .line 354
    .line 355
    const-string v1, "BActivityThread"

    .line 356
    .line 357
    const-string v6, "makeApplication returned null, attempting fallback creation"

    .line 358
    .line 359
    invoke-static {v1, v6}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_5
    .catch Ljava/lang/Exception; {:try_start_5 .. :try_end_5} :catch_3
    .catchall {:try_start_5 .. :try_end_5} :catchall_1

    .line 360
    .line 361
    .line 362
    :try_start_6
    const-class v1, Lblack/android/app/LoadedApkContext;

    .line 363
    .line 364
    invoke-static {v1, v4, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 365
    .line 366
    .line 367
    move-result-object v1

    .line 368
    check-cast v1, Lblack/android/app/LoadedApkContext;

    .line 369
    .line 370
    const/4 v4, 0x1

    .line 371
    invoke-interface {v1, v4, v7}, Lblack/android/app/LoadedApkContext;->makeApplication(ZLandroid/app/Instrumentation;)Landroid/app/Application;

    .line 372
    .line 373
    .line 374
    move-result-object v0
    :try_end_6
    .catch Ljava/lang/Exception; {:try_start_6 .. :try_end_6} :catch_1
    .catchall {:try_start_6 .. :try_end_6} :catchall_1

    .line 375
    goto :goto_2

    .line 376
    :catch_1
    move-exception v1

    .line 377
    :try_start_7
    const-string v4, "BActivityThread"

    .line 378
    .line 379
    const-string v6, "Fallback makeApplication also failed"

    .line 380
    .line 381
    invoke-static {v4, v6, v1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 382
    .line 383
    .line 384
    :goto_2
    if-nez v0, :cond_8

    .line 385
    .line 386
    const-string v0, "BActivityThread"

    .line 387
    .line 388
    const-string v1, "Creating minimal application context as fallback"

    .line 389
    .line 390
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_7
    .catch Ljava/lang/Exception; {:try_start_7 .. :try_end_7} :catch_3
    .catchall {:try_start_7 .. :try_end_7} :catchall_1

    .line 391
    .line 392
    .line 393
    :try_start_8
    move-object v0, v2

    .line 394
    check-cast v0, Landroid/app/Application;

    .line 395
    .line 396
    if-eqz v0, :cond_7

    .line 397
    .line 398
    goto :goto_3

    .line 399
    :cond_7
    const-string p1, "BActivityThread"

    .line 400
    .line 401
    const-string p2, "Even package context is null, this is critical"

    .line 402
    .line 403
    invoke-static {p1, p2}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 404
    .line 405
    .line 406
    new-instance p1, Ljava/lang/RuntimeException;

    .line 407
    .line 408
    const-string p2, "Unable to create application context"

    .line 409
    .line 410
    invoke-direct {p1, p2}, Ljava/lang/RuntimeException;-><init>(Ljava/lang/String;)V

    .line 411
    .line 412
    .line 413
    throw p1
    :try_end_8
    .catch Ljava/lang/Exception; {:try_start_8 .. :try_end_8} :catch_2
    .catchall {:try_start_8 .. :try_end_8} :catchall_1

    .line 414
    :catch_2
    move-exception p1

    .line 415
    :try_start_9
    const-string p2, "BActivityThread"

    .line 416
    .line 417
    const-string v0, "Failed to create fallback application context"

    .line 418
    .line 419
    invoke-static {p2, v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 420
    .line 421
    .line 422
    new-instance p2, Ljava/lang/RuntimeException;

    .line 423
    .line 424
    const-string v0, "Unable to makeApplication - all fallback attempts failed"

    .line 425
    .line 426
    invoke-direct {p2, v0, p1}, Ljava/lang/RuntimeException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    .line 427
    .line 428
    .line 429
    throw p2

    .line 430
    :catch_3
    move-exception p1

    .line 431
    goto :goto_5

    .line 432
    :cond_8
    :goto_3
    iput-object v0, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 433
    .line 434
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 435
    .line 436
    .line 437
    move-result-object v1

    .line 438
    const-class v2, Lblack/android/app/ActivityThreadContext;

    .line 439
    .line 440
    invoke-static {v2, v1, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 441
    .line 442
    .line 443
    move-result-object v1

    .line 444
    check-cast v1, Lblack/android/app/ActivityThreadContext;

    .line 445
    .line 446
    iget-object v2, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 447
    .line 448
    invoke-interface {v1, v2}, Lblack/android/app/ActivityThreadContext;->_set_mInitialApplication(Ljava/lang/Object;)V

    .line 449
    .line 450
    .line 451
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 452
    .line 453
    .line 454
    move-result-object v1

    .line 455
    const-class v2, Lblack/android/app/ActivityThreadContext;

    .line 456
    .line 457
    invoke-static {v2, v1, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 458
    .line 459
    .line 460
    move-result-object v1

    .line 461
    check-cast v1, Lblack/android/app/ActivityThreadContext;

    .line 462
    .line 463
    invoke-interface {v1}, Lblack/android/app/ActivityThreadContext;->getSystemContext()Ljava/lang/Object;

    .line 464
    .line 465
    .line 466
    move-result-object v1

    .line 467
    check-cast v1, Landroid/content/Context;

    .line 468
    .line 469
    invoke-static {v1}, Ltop/niunaijun/blackbox/utils/compat/ContextCompat;->fix(Landroid/content/Context;)V

    .line 470
    .line 471
    .line 472
    iget-object v1, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 473
    .line 474
    invoke-static {v1}, Ltop/niunaijun/blackbox/utils/compat/ContextCompat;->fix(Landroid/content/Context;)V

    .line 475
    .line 476
    .line 477
    iget-object v1, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mInitialApplication:Landroid/app/Application;

    .line 478
    .line 479
    iget-object v2, v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->processName:Ljava/lang/String;

    .line 480
    .line 481
    iget-object v3, v5, Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;->providers:Ljava/util/List;

    .line 482
    .line 483
    invoke-direct {p0, v1, v2, v3}, Ltop/niunaijun/blackbox/app/BActivityThread;->installProviders(Landroid/content/Context;Ljava/lang/String;Ljava/util/List;)V

    .line 484
    .line 485
    .line 486
    invoke-direct {p0, p1, p2, v0}, Ltop/niunaijun/blackbox/app/BActivityThread;->onBeforeApplicationOnCreate(Ljava/lang/String;Ljava/lang/String;Landroid/app/Application;)V

    .line 487
    .line 488
    .line 489
    invoke-static {}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->get()Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;

    .line 490
    .line 491
    .line 492
    move-result-object v1

    .line 493
    invoke-virtual {v1, v0}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->callApplicationOnCreate(Landroid/app/Application;)V

    .line 494
    .line 495
    .line 496
    invoke-direct {p0, p1, p2, v0}, Ltop/niunaijun/blackbox/app/BActivityThread;->onAfterApplicationOnCreate(Ljava/lang/String;Ljava/lang/String;Landroid/app/Application;)V

    .line 497
    .line 498
    .line 499
    invoke-static {}, Ltop/niunaijun/blackbox/fake/hook/HookManager;->get()Ltop/niunaijun/blackbox/fake/hook/HookManager;

    .line 500
    .line 501
    .line 502
    move-result-object p1

    .line 503
    const-class p2, Ltop/niunaijun/blackbox/fake/service/HCallbackProxy;

    .line 504
    .line 505
    invoke-virtual {p1, p2}, Ltop/niunaijun/blackbox/fake/hook/HookManager;->checkEnv(Ljava/lang/Class;)V
    :try_end_9
    .catch Ljava/lang/Exception; {:try_start_9 .. :try_end_9} :catch_3
    .catchall {:try_start_9 .. :try_end_9} :catchall_1

    .line 506
    .line 507
    .line 508
    :goto_4
    monitor-exit p0

    .line 509
    return-void

    .line 510
    :goto_5
    :try_start_a
    const-string p2, "BActivityThread"

    .line 511
    .line 512
    const-string v0, "Critical error in handleBindApplication"

    .line 513
    .line 514
    invoke-static {p2, v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 515
    .line 516
    .line 517
    new-instance p2, Ljava/lang/RuntimeException;

    .line 518
    .line 519
    const-string v0, "Unable to makeApplication"

    .line 520
    .line 521
    invoke-direct {p2, v0, p1}, Ljava/lang/RuntimeException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    .line 522
    .line 523
    .line 524
    throw p2

    .line 525
    :goto_6
    monitor-exit p0
    :try_end_a
    .catchall {:try_start_a .. :try_end_a} :catchall_1

    .line 526
    throw p1
.end method

.method public handleNewIntent(Landroid/os/IBinder;Landroid/content/Intent;)V
    .locals 3

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mH:Landroid/os/Handler;

    .line 2
    .line 3
    new-instance v1, Ld0/k;

    .line 4
    .line 5
    const/4 v2, 0x5

    .line 6
    invoke-direct {v1, p2, v2, p1}, Ld0/k;-><init>(Ljava/lang/Object;ILjava/lang/Object;)V

    .line 7
    .line 8
    .line 9
    invoke-virtual {v0, v1}, Landroid/os/Handler;->post(Ljava/lang/Runnable;)Z

    .line 10
    .line 11
    .line 12
    return-void
.end method

.method public initProcess(Ltop/niunaijun/blackbox/entity/AppConfig;)V
    .locals 4

    .line 1
    const-string v0, "reject init process: "

    .line 2
    .line 3
    sget-object v1, Ltop/niunaijun/blackbox/app/BActivityThread;->mConfigLock:Ljava/lang/Object;

    .line 4
    .line 5
    monitor-enter v1

    .line 6
    :try_start_0
    iget-object v2, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mAppConfig:Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 7
    .line 8
    if-eqz v2, :cond_1

    .line 9
    .line 10
    iget-object v2, v2, Ltop/niunaijun/blackbox/entity/AppConfig;->packageName:Ljava/lang/String;

    .line 11
    .line 12
    iget-object v3, p1, Ltop/niunaijun/blackbox/entity/AppConfig;->packageName:Ljava/lang/String;

    .line 13
    .line 14
    invoke-virtual {v2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 15
    .line 16
    .line 17
    move-result v2

    .line 18
    if-eqz v2, :cond_0

    .line 19
    .line 20
    goto :goto_0

    .line 21
    :cond_0
    new-instance v2, Ljava/lang/RuntimeException;

    .line 22
    .line 23
    new-instance v3, Ljava/lang/StringBuilder;

    .line 24
    .line 25
    invoke-direct {v3, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 26
    .line 27
    .line 28
    iget-object p1, p1, Ltop/niunaijun/blackbox/entity/AppConfig;->processName:Ljava/lang/String;

    .line 29
    .line 30
    invoke-virtual {v3, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 31
    .line 32
    .line 33
    const-string p1, ", this process is : "

    .line 34
    .line 35
    invoke-virtual {v3, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 36
    .line 37
    .line 38
    iget-object p1, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mAppConfig:Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 39
    .line 40
    iget-object p1, p1, Ltop/niunaijun/blackbox/entity/AppConfig;->processName:Ljava/lang/String;

    .line 41
    .line 42
    invoke-virtual {v3, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 43
    .line 44
    .line 45
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 46
    .line 47
    .line 48
    move-result-object p1

    .line 49
    invoke-direct {v2, p1}, Ljava/lang/RuntimeException;-><init>(Ljava/lang/String;)V

    .line 50
    .line 51
    .line 52
    throw v2

    .line 53
    :catchall_0
    move-exception p1

    .line 54
    goto :goto_2

    .line 55
    :cond_1
    :goto_0
    iput-object p1, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mAppConfig:Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 56
    .line 57
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/core/IBActivityThread$Stub;->asBinder()Landroid/os/IBinder;

    .line 58
    .line 59
    .line 60
    move-result-object p1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 61
    :try_start_1
    new-instance v0, Ltop/niunaijun/blackbox/app/BActivityThread$1;

    .line 62
    .line 63
    invoke-direct {v0, p0, p1}, Ltop/niunaijun/blackbox/app/BActivityThread$1;-><init>(Ltop/niunaijun/blackbox/app/BActivityThread;Landroid/os/IBinder;)V

    .line 64
    .line 65
    .line 66
    const/4 v2, 0x0

    .line 67
    invoke-interface {p1, v0, v2}, Landroid/os/IBinder;->linkToDeath(Landroid/os/IBinder$DeathRecipient;I)V
    :try_end_1
    .catch Landroid/os/RemoteException; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 68
    .line 69
    .line 70
    goto :goto_1

    .line 71
    :catch_0
    move-exception p1

    .line 72
    :try_start_2
    invoke-virtual {p1}, Ljava/lang/Throwable;->printStackTrace()V

    .line 73
    .line 74
    .line 75
    :goto_1
    monitor-exit v1

    .line 76
    return-void

    .line 77
    :goto_2
    monitor-exit v1
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    .line 78
    throw p1
.end method

.method public isInit()Z
    .locals 1

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mBoundApplication:Ltop/niunaijun/blackbox/app/BActivityThread$AppBindData;

    .line 2
    .line 3
    if-eqz v0, :cond_0

    .line 4
    .line 5
    const/4 v0, 0x1

    .line 6
    return v0

    .line 7
    :cond_0
    const/4 v0, 0x0

    .line 8
    return v0
.end method

.method public peekService(Landroid/content/Intent;)Landroid/os/IBinder;
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/dispatcher/AppServiceDispatcher;->get()Ltop/niunaijun/blackbox/app/dispatcher/AppServiceDispatcher;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    invoke-virtual {v0, p1}, Ltop/niunaijun/blackbox/app/dispatcher/AppServiceDispatcher;->peekService(Landroid/content/Intent;)Landroid/os/IBinder;

    .line 6
    .line 7
    .line 8
    move-result-object p1

    .line 9
    return-object p1
.end method

.method public restartJobService(Ljava/lang/String;)V
    .locals 0

    .line 1
    return-void
.end method

.method public scheduleReceiver(Ltop/niunaijun/blackbox/entity/am/ReceiverData;)V
    .locals 3

    .line 1
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/app/BActivityThread;->isInit()Z

    .line 2
    .line 3
    .line 4
    move-result v0

    .line 5
    if-nez v0, :cond_0

    .line 6
    .line 7
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/app/BActivityThread;->bindApplication()V

    .line 8
    .line 9
    .line 10
    :cond_0
    iget-object v0, p0, Ltop/niunaijun/blackbox/app/BActivityThread;->mH:Landroid/os/Handler;

    .line 11
    .line 12
    new-instance v1, Ld0/k;

    .line 13
    .line 14
    const/4 v2, 0x4

    .line 15
    invoke-direct {v1, p0, v2, p1}, Ld0/k;-><init>(Ljava/lang/Object;ILjava/lang/Object;)V

    .line 16
    .line 17
    .line 18
    invoke-virtual {v0, v1}, Landroid/os/Handler;->post(Ljava/lang/Runnable;)Z

    .line 19
    .line 20
    .line 21
    return-void
.end method

.method public stopService(Landroid/content/Intent;)V
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/app/dispatcher/AppServiceDispatcher;->get()Ltop/niunaijun/blackbox/app/dispatcher/AppServiceDispatcher;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    invoke-virtual {v0, p1}, Ltop/niunaijun/blackbox/app/dispatcher/AppServiceDispatcher;->stopService(Landroid/content/Intent;)V

    .line 6
    .line 7
    .line 8
    return-void
.end method
