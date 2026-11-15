.class public Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetIntentSender;
.super Ltop/niunaijun/blackbox/fake/hook/MethodHook;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x9
    name = "GetIntentSender"
.end annotation

.annotation runtime Ltop/niunaijun/blackbox/fake/hook/ProxyMethod;
    value = "getIntentSender"
.end annotation


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 1
    invoke-direct {p0}, Ltop/niunaijun/blackbox/fake/hook/MethodHook;-><init>()V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method private getIntentsIndex([Ljava/lang/Object;)I
    .locals 2

    .line 1
    const/4 v0, 0x0

    .line 2
    :goto_0
    array-length v1, p1

    .line 3
    if-ge v0, v1, :cond_1

    .line 4
    .line 5
    aget-object v1, p1, v0

    .line 6
    .line 7
    instance-of v1, v1, [Landroid/content/Intent;

    .line 8
    .line 9
    if-eqz v1, :cond_0

    .line 10
    .line 11
    return v0

    .line 12
    :cond_0
    add-int/lit8 v0, v0, 0x1

    .line 13
    .line 14
    goto :goto_0

    .line 15
    :cond_1
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isR()Z

    .line 16
    .line 17
    .line 18
    move-result p1

    .line 19
    if-eqz p1, :cond_2

    .line 20
    .line 21
    const/4 p1, 0x6

    .line 22
    return p1

    .line 23
    :cond_2
    const/4 p1, 0x5

    .line 24
    return p1
.end method


# virtual methods
.method public hook(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 9

    .line 1
    const/4 v0, 0x0

    .line 2
    aget-object v1, p3, v0

    .line 3
    .line 4
    check-cast v1, Ljava/lang/Integer;

    .line 5
    .line 6
    invoke-virtual {v1}, Ljava/lang/Integer;->intValue()I

    .line 7
    .line 8
    .line 9
    move-result v1

    .line 10
    invoke-direct {p0, p3}, Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetIntentSender;->getIntentsIndex([Ljava/lang/Object;)I

    .line 11
    .line 12
    .line 13
    move-result v2

    .line 14
    aget-object v2, p3, v2

    .line 15
    .line 16
    check-cast v2, [Landroid/content/Intent;

    .line 17
    .line 18
    invoke-static {p3}, Ltop/niunaijun/blackbox/utils/MethodParameterUtils;->replaceFirstAppPkg([Ljava/lang/Object;)Ljava/lang/String;

    .line 19
    .line 20
    .line 21
    move v3, v0

    .line 22
    :goto_0
    array-length v4, v2

    .line 23
    if-ge v3, v4, :cond_1

    .line 24
    .line 25
    aget-object v4, v2, v3

    .line 26
    .line 27
    const/4 v5, 0x2

    .line 28
    if-eq v1, v5, :cond_0

    .line 29
    .line 30
    goto :goto_1

    .line 31
    :cond_0
    new-instance v5, Landroid/content/Intent;

    .line 32
    .line 33
    invoke-direct {v5}, Landroid/content/Intent;-><init>()V

    .line 34
    .line 35
    .line 36
    new-instance v6, Landroid/content/ComponentName;

    .line 37
    .line 38
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostPkg()Ljava/lang/String;

    .line 39
    .line 40
    .line 41
    move-result-object v7

    .line 42
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppPid()I

    .line 43
    .line 44
    .line 45
    move-result v8

    .line 46
    invoke-static {v8}, Ltop/niunaijun/blackbox/proxy/ProxyManifest;->getProxyPendingActivity(I)Ljava/lang/String;

    .line 47
    .line 48
    .line 49
    move-result-object v8

    .line 50
    invoke-direct {v6, v7, v8}, Landroid/content/ComponentName;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    .line 51
    .line 52
    .line 53
    invoke-virtual {v5, v6}, Landroid/content/Intent;->setComponent(Landroid/content/ComponentName;)Landroid/content/Intent;

    .line 54
    .line 55
    .line 56
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    .line 57
    .line 58
    .line 59
    move-result v6

    .line 60
    invoke-static {v5, v4, v6}, Ltop/niunaijun/blackbox/proxy/record/ProxyPendingRecord;->saveStub(Landroid/content/Intent;Landroid/content/Intent;I)V

    .line 61
    .line 62
    .line 63
    aput-object v5, v2, v3

    .line 64
    .line 65
    :goto_1
    add-int/lit8 v3, v3, 0x1

    .line 66
    .line 67
    goto :goto_0

    .line 68
    :cond_1
    invoke-static {p2, p3}, Lio/github/leexeo/cage/space/GuestPendingActivity;->prepare(Ljava/lang/reflect/Method;[Ljava/lang/Object;)V

    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 69
    .line 70
    .line 71
    move-result-object p1

    .line 72
    check-cast p1, Landroid/os/IInterface;

    invoke-static {p1, p2, p3}, Lio/github/leexeo/cage/space/GuestPendingActivity;->created(Landroid/os/IInterface;Ljava/lang/reflect/Method;[Ljava/lang/Object;)V

    .line 73
    .line 74
    if-eqz p1, :cond_3

    .line 75
    .line 76
    invoke-static {}, Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;->get()Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;

    .line 77
    .line 78
    .line 79
    move-result-object p2

    .line 80
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getCallingBUid()I

    .line 81
    .line 82
    .line 83
    move-result p3

    .line 84
    invoke-virtual {p2, p3}, Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;->getPackagesForUid(I)[Ljava/lang/String;

    .line 85
    .line 86
    .line 87
    move-result-object p2

    .line 88
    array-length p3, p2

    .line 89
    const/4 v1, 0x1

    .line 90
    if-ge p3, v1, :cond_2

    .line 91
    .line 92
    new-array p2, v1, [Ljava/lang/String;

    .line 93
    .line 94
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostPkg()Ljava/lang/String;

    .line 95
    .line 96
    .line 97
    move-result-object p3

    .line 98
    aput-object p3, p2, v0

    .line 99
    .line 100
    :cond_2
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBActivityManager()Ltop/niunaijun/blackbox/fake/frameworks/BActivityManager;

    .line 101
    .line 102
    .line 103
    move-result-object p3

    .line 104
    invoke-interface {p1}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    .line 105
    .line 106
    .line 107
    move-result-object v1

    .line 108
    aget-object p2, p2, v0

    .line 109
    .line 110
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getCallingBUid()I

    .line 111
    .line 112
    .line 113
    move-result v0

    .line 114
    invoke-virtual {p3, v1, p2, v0}, Ltop/niunaijun/blackbox/fake/frameworks/BActivityManager;->getIntentSender(Landroid/os/IBinder;Ljava/lang/String;I)V

    .line 115
    .line 116
    .line 117
    :cond_3
    return-object p1
.end method
