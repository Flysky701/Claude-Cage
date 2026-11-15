.class public final Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;
.super Ltop/niunaijun/blackbox/fake/delegate/BaseInstrumentationDelegate;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"

# interfaces
.implements Ltop/niunaijun/blackbox/fake/hook/IInjectHook;


# static fields
.field static final synthetic $assertionsDisabled:Z = false

.field private static final TAG:Ljava/lang/String; = "AppInstrumentation"

.field private static sAppInstrumentation:Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 1
    invoke-direct {p0}, Ltop/niunaijun/blackbox/fake/delegate/BaseInstrumentationDelegate;-><init>()V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method private checkActivity(Landroid/app/Activity;)V
    .locals 4

    .line 1
    sget-object v0, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->TAG:Ljava/lang/String;

    .line 2
    .line 3
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 4
    .line 5
    .line 6
    move-result-object v1

    .line 7
    invoke-virtual {v1}, Ljava/lang/Class;->getName()Ljava/lang/String;

    .line 8
    .line 9
    .line 10
    move-result-object v1

    .line 11
    const-string v2, "callActivityOnCreate: "

    .line 12
    .line 13
    invoke-virtual {v2, v1}, Ljava/lang/String;->concat(Ljava/lang/String;)Ljava/lang/String;

    .line 14
    .line 15
    .line 16
    move-result-object v1

    .line 17
    invoke-static {v0, v1}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 18
    .line 19
    .line 20
    invoke-virtual {p1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    .line 21
    .line 22
    .line 23
    move-result-object v0

    .line 24
    invoke-virtual {p1}, Landroid/content/Context;->getClassLoader()Ljava/lang/ClassLoader;

    .line 25
    .line 26
    .line 27
    move-result-object v1

    .line 28
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/HackAppUtils;->enableQQLogOutput(Ljava/lang/String;Ljava/lang/ClassLoader;)V

    .line 29
    .line 30
    .line 31
    invoke-direct {p0}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->checkHCallback()V

    .line 32
    .line 33
    .line 34
    invoke-static {}, Ltop/niunaijun/blackbox/fake/hook/HookManager;->get()Ltop/niunaijun/blackbox/fake/hook/HookManager;

    .line 35
    .line 36
    .line 37
    move-result-object v0

    .line 38
    const-class v1, Ltop/niunaijun/blackbox/fake/service/IActivityClientProxy;

    .line 39
    .line 40
    invoke-virtual {v0, v1}, Ltop/niunaijun/blackbox/fake/hook/HookManager;->checkEnv(Ljava/lang/Class;)V

    .line 41
    .line 42
    .line 43
    const-class v0, Lblack/android/app/ActivityContext;

    .line 44
    .line 45
    const/4 v1, 0x0

    .line 46
    invoke-static {v0, p1, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 47
    .line 48
    .line 49
    move-result-object v0

    .line 50
    check-cast v0, Lblack/android/app/ActivityContext;

    .line 51
    .line 52
    invoke-interface {v0}, Lblack/android/app/ActivityContext;->mActivityInfo()Landroid/content/pm/ActivityInfo;

    .line 53
    .line 54
    .line 55
    move-result-object v0

    .line 56
    invoke-static {p1}, Ltop/niunaijun/blackbox/utils/compat/ContextCompat;->fix(Landroid/content/Context;)V

    .line 57
    .line 58
    .line 59
    invoke-static {p1}, Ltop/niunaijun/blackbox/utils/compat/ActivityCompat;->fix(Landroid/app/Activity;)V

    .line 60
    .line 61
    .line 62
    iget v1, v0, Landroid/content/pm/ActivityInfo;->theme:I

    .line 63
    .line 64
    if-eqz v1, :cond_0

    .line 65
    .line 66
    invoke-virtual {p1}, Landroid/content/Context;->getTheme()Landroid/content/res/Resources$Theme;

    .line 67
    .line 68
    .line 69
    move-result-object v1

    .line 70
    iget v2, v0, Landroid/content/pm/ActivityInfo;->theme:I

    .line 71
    .line 72
    const/4 v3, 0x1

    .line 73
    invoke-virtual {v1, v2, v3}, Landroid/content/res/Resources$Theme;->applyStyle(IZ)V

    .line 74
    .line 75
    .line 76
    :cond_0
    iget v0, v0, Landroid/content/pm/ActivityInfo;->screenOrientation:I

    .line 77
    .line 78
    invoke-static {p1, v0}, Ltop/niunaijun/blackbox/utils/compat/ActivityManagerCompat;->setActivityOrientation(Landroid/app/Activity;I)V

    .line 79
    .line 80
    .line 81
    return-void
.end method

.method private checkHCallback()V
    .locals 2

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/fake/hook/HookManager;->get()Ltop/niunaijun/blackbox/fake/hook/HookManager;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    const-class v1, Ltop/niunaijun/blackbox/fake/service/HCallbackProxy;

    .line 6
    .line 7
    invoke-virtual {v0, v1}, Ltop/niunaijun/blackbox/fake/hook/HookManager;->checkEnv(Ljava/lang/Class;)V

    .line 8
    .line 9
    .line 10
    return-void
.end method

.method private checkInstrumentation(Landroid/app/Instrumentation;)Z
    .locals 9

    .line 1
    instance-of v0, p1, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;

    .line 2
    .line 3
    const/4 v1, 0x1

    .line 4
    if-eqz v0, :cond_0

    .line 5
    .line 6
    return v1

    .line 7
    :cond_0
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 8
    .line 9
    .line 10
    move-result-object v0

    .line 11
    const-class v2, Landroid/app/Instrumentation;

    .line 12
    .line 13
    invoke-virtual {v2, v0}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    .line 14
    .line 15
    .line 16
    move-result v3

    .line 17
    const/4 v4, 0x0

    .line 18
    if-eqz v3, :cond_1

    .line 19
    .line 20
    return v4

    .line 21
    :cond_1
    invoke-virtual {v0}, Ljava/lang/Class;->getDeclaredFields()[Ljava/lang/reflect/Field;

    .line 22
    .line 23
    .line 24
    move-result-object v3

    .line 25
    array-length v5, v3

    .line 26
    move v6, v4

    .line 27
    :goto_0
    if-ge v6, v5, :cond_3

    .line 28
    .line 29
    aget-object v7, v3, v6

    .line 30
    .line 31
    invoke-virtual {v7}, Ljava/lang/reflect/Field;->getType()Ljava/lang/Class;

    .line 32
    .line 33
    .line 34
    move-result-object v8

    .line 35
    invoke-virtual {v2, v8}, Ljava/lang/Class;->isAssignableFrom(Ljava/lang/Class;)Z

    .line 36
    .line 37
    .line 38
    move-result v8

    .line 39
    if-eqz v8, :cond_2

    .line 40
    .line 41
    invoke-virtual {v7, v1}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 42
    .line 43
    .line 44
    :try_start_0
    invoke-virtual {v7, p1}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 45
    .line 46
    .line 47
    move-result-object v7

    .line 48
    instance-of v7, v7, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 49
    .line 50
    if-eqz v7, :cond_2

    .line 51
    .line 52
    return v1

    .line 53
    :catch_0
    return v4

    .line 54
    :cond_2
    add-int/lit8 v6, v6, 0x1

    .line 55
    .line 56
    goto :goto_0

    .line 57
    :cond_3
    invoke-virtual {v0}, Ljava/lang/Class;->getSuperclass()Ljava/lang/Class;

    .line 58
    .line 59
    .line 60
    move-result-object v0

    .line 61
    invoke-virtual {v2, v0}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    .line 62
    .line 63
    .line 64
    move-result v3

    .line 65
    if-eqz v3, :cond_1

    .line 66
    .line 67
    return v4
.end method

.method public static get()Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;
    .locals 2

    .line 1
    sget-object v0, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->sAppInstrumentation:Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;

    .line 2
    .line 3
    if-nez v0, :cond_1

    .line 4
    .line 5
    const-class v0, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;

    .line 6
    .line 7
    monitor-enter v0

    .line 8
    :try_start_0
    sget-object v1, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->sAppInstrumentation:Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;

    .line 9
    .line 10
    if-nez v1, :cond_0

    .line 11
    .line 12
    new-instance v1, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;

    .line 13
    .line 14
    invoke-direct {v1}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;-><init>()V

    .line 15
    .line 16
    .line 17
    sput-object v1, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->sAppInstrumentation:Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;

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
    sget-object v0, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->sAppInstrumentation:Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;

    .line 27
    .line 28
    return-object v0
.end method

.method private getCurrInstrumentation()Landroid/app/Instrumentation;
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
    invoke-interface {v0}, Lblack/android/app/ActivityThreadContext;->mInstrumentation()Landroid/app/Instrumentation;

    .line 15
    .line 16
    .line 17
    move-result-object v0

    .line 18
    return-object v0
.end method


# virtual methods
.method public callActivityOnCreate(Landroid/app/Activity;Landroid/os/Bundle;)V
    .locals 0

    .line 3
    invoke-direct {p0, p1}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->checkActivity(Landroid/app/Activity;)V

    .line 4
    invoke-static {p1}, Ltop/niunaijun/blackbox/region/GuestRegion;->apply(Landroid/content/Context;)V

    invoke-super {p0, p1, p2}, Ltop/niunaijun/blackbox/fake/delegate/BaseInstrumentationDelegate;->callActivityOnCreate(Landroid/app/Activity;Landroid/os/Bundle;)V

    return-void
.end method

.method public callActivityOnCreate(Landroid/app/Activity;Landroid/os/Bundle;Landroid/os/PersistableBundle;)V
    .locals 0

    .line 1
    invoke-direct {p0, p1}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->checkActivity(Landroid/app/Activity;)V

    .line 2
    invoke-static {p1}, Ltop/niunaijun/blackbox/region/GuestRegion;->apply(Landroid/content/Context;)V

    invoke-super {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/fake/delegate/BaseInstrumentationDelegate;->callActivityOnCreate(Landroid/app/Activity;Landroid/os/Bundle;Landroid/os/PersistableBundle;)V

    return-void
.end method

.method public callActivityOnResume(Landroid/app/Activity;)V
    .locals 0

    invoke-super {p0, p1}, Ltop/niunaijun/blackbox/fake/delegate/BaseInstrumentationDelegate;->callActivityOnResume(Landroid/app/Activity;)V

    invoke-static {p1}, Lio/github/leexeo/cage/space/LoginViewCompat;->resume(Landroid/app/Activity;)V

    return-void
.end method

.method public callApplicationOnCreate(Landroid/app/Application;)V
    .locals 0

    .line 1
    invoke-direct {p0}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->checkHCallback()V

    .line 2
    .line 3
    .line 4
    invoke-static {p1}, Ltop/niunaijun/blackbox/region/GuestRegion;->apply(Landroid/content/Context;)V

    invoke-super {p0, p1}, Ltop/niunaijun/blackbox/fake/delegate/BaseInstrumentationDelegate;->callApplicationOnCreate(Landroid/app/Application;)V

    .line 5
    .line 6
    .line 7
    return-void
.end method

.method public injectHook()V
    .locals 3

    .line 1
    :try_start_0
    invoke-direct {p0}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->getCurrInstrumentation()Landroid/app/Instrumentation;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    if-eq v0, p0, :cond_1

    .line 6
    .line 7
    invoke-direct {p0, v0}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->checkInstrumentation(Landroid/app/Instrumentation;)Z

    .line 8
    .line 9
    .line 10
    move-result v1

    .line 11
    if-eqz v1, :cond_0

    .line 12
    .line 13
    goto :goto_0

    .line 14
    :cond_0
    iput-object v0, p0, Ltop/niunaijun/blackbox/fake/delegate/BaseInstrumentationDelegate;->mBaseInstrumentation:Landroid/app/Instrumentation;

    .line 15
    .line 16
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 17
    .line 18
    .line 19
    move-result-object v0

    .line 20
    const-class v1, Lblack/android/app/ActivityThreadContext;

    .line 21
    .line 22
    const/4 v2, 0x0

    .line 23
    invoke-static {v1, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 24
    .line 25
    .line 26
    move-result-object v0

    .line 27
    check-cast v0, Lblack/android/app/ActivityThreadContext;

    .line 28
    .line 29
    invoke-interface {v0, p0}, Lblack/android/app/ActivityThreadContext;->_set_mInstrumentation(Ljava/lang/Object;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 30
    .line 31
    .line 32
    return-void

    .line 33
    :catch_0
    move-exception v0

    .line 34
    goto :goto_1

    .line 35
    :cond_1
    :goto_0
    return-void

    .line 36
    :goto_1
    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V

    .line 37
    .line 38
    .line 39
    return-void
.end method

.method public isBadEnv()Z
    .locals 1

    .line 1
    invoke-direct {p0}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->getCurrInstrumentation()Landroid/app/Instrumentation;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    invoke-direct {p0, v0}, Ltop/niunaijun/blackbox/fake/delegate/AppInstrumentation;->checkInstrumentation(Landroid/app/Instrumentation;)Z

    .line 6
    .line 7
    .line 8
    move-result v0

    .line 9
    xor-int/lit8 v0, v0, 0x1

    .line 10
    .line 11
    return v0
.end method

.method public newActivity(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Intent;)Landroid/app/Activity;
    .locals 1

    .line 1
    :try_start_0
    invoke-super {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/fake/delegate/BaseInstrumentationDelegate;->newActivity(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Intent;)Landroid/app/Activity;

    .line 2
    .line 3
    .line 4
    move-result-object p1
    :try_end_0
    .catch Ljava/lang/ClassNotFoundException; {:try_start_0 .. :try_end_0} :catch_0

    .line 5
    return-object p1

    .line 6
    :catch_0
    iget-object v0, p0, Ltop/niunaijun/blackbox/fake/delegate/BaseInstrumentationDelegate;->mBaseInstrumentation:Landroid/app/Instrumentation;

    .line 7
    .line 8
    invoke-virtual {v0, p1, p2, p3}, Landroid/app/Instrumentation;->newActivity(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Intent;)Landroid/app/Activity;

    .line 9
    .line 10
    .line 11
    move-result-object p1

    .line 12
    return-object p1
.end method

.method public newApplication(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Context;)Landroid/app/Application;
    .locals 0

    .line 1
    invoke-static {p3}, Ltop/niunaijun/blackbox/utils/compat/ContextCompat;->fix(Landroid/content/Context;)V

    .line 2
    .line 3
    .line 4
    invoke-super {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/fake/delegate/BaseInstrumentationDelegate;->newApplication(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Context;)Landroid/app/Application;

    .line 5
    .line 6
    .line 7
    move-result-object p1

    .line 8
    return-object p1
.end method
