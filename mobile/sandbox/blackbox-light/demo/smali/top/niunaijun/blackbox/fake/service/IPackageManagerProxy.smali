.class public Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy;
.super Ltop/niunaijun/blackbox/fake/hook/BinderInvocationStub;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$SimpleAudioPermissionHook;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$CheckSelfPermission;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$ShouldShowRequestPermissionRationale;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$RequestPermissions;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$DisableIconLoading;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$SetSplashScreenTheme;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$XiaomiSecurityBypass;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$getComponentEnabledSetting;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetSharedLibraries;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetInstallerPackageName;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetPackagesForUid;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$CanRequestPackageInstalls;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$ResolveContentProvider;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$QueryBroadcastReceivers;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$QueryContentProviders;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetApplicationInfo;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetInstalledPackages;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetInstalledApplications;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetServiceInfo;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetActivityInfo;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetReceiverInfo;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetProviderInfo;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetPackageUid;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$GetPackageInfo;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$SetComponentEnabledSetting;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$ResolveService;,
        Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$ResolveIntent;
    }
.end annotation


# static fields
.field public static final TAG:Ljava/lang/String; = "PackageManagerStub"


# direct methods
.method public constructor <init>()V
    .locals 3

    .line 1
    const/4 v0, 0x0

    .line 2
    const/4 v1, 0x0

    .line 3
    const-class v2, Lblack/android/app/ActivityThreadStatic;

    .line 4
    .line 5
    invoke-static {v2, v0, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 6
    .line 7
    .line 8
    move-result-object v0

    .line 9
    check-cast v0, Lblack/android/app/ActivityThreadStatic;

    .line 10
    .line 11
    invoke-interface {v0}, Lblack/android/app/ActivityThreadStatic;->sPackageManager()Landroid/os/IInterface;

    .line 12
    .line 13
    .line 14
    move-result-object v0

    .line 15
    invoke-interface {v0}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    .line 16
    .line 17
    .line 18
    move-result-object v0

    .line 19
    invoke-direct {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/BinderInvocationStub;-><init>(Landroid/os/IBinder;)V

    .line 20
    .line 21
    .line 22
    return-void
.end method

.method public static bridge synthetic a(Ljava/lang/String;)Z
    .locals 0

    .line 1
    invoke-static {p0}, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy;->isAudioPermission(Ljava/lang/String;)Z

    .line 2
    .line 3
    .line 4
    move-result p0

    .line 5
    return p0
.end method

.method public static bridge synthetic b(Ljava/lang/String;)Z
    .locals 0

    .line 1
    invoke-static {p0}, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy;->isNotificationOrXiaomiPermission(Ljava/lang/String;)Z

    .line 2
    .line 3
    .line 4
    move-result p0

    .line 5
    return p0
.end method

.method public static bridge synthetic c(Ljava/lang/String;)Z
    .locals 0

    .line 1
    invoke-static {p0}, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy;->isStorageOrMediaPermission(Ljava/lang/String;)Z

    .line 2
    .line 3
    .line 4
    move-result p0

    .line 5
    return p0
.end method

.method private static isAudioPermission(Ljava/lang/String;)Z
    .locals 2

    .line 1
    const/4 v0, 0x0

    .line 2
    if-nez p0, :cond_0

    .line 3
    .line 4
    return v0

    .line 5
    :cond_0
    const-string v1, "android.permission.RECORD_AUDIO"

    .line 6
    .line 7
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 8
    .line 9
    .line 10
    move-result v1

    .line 11
    if-nez v1, :cond_2

    .line 12
    .line 13
    const-string v1, "android.permission.CAPTURE_AUDIO_OUTPUT"

    .line 14
    .line 15
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 16
    .line 17
    .line 18
    move-result v1

    .line 19
    if-nez v1, :cond_2

    .line 20
    .line 21
    const-string v1, "android.permission.MODIFY_AUDIO_SETTINGS"

    .line 22
    .line 23
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 24
    .line 25
    .line 26
    move-result v1

    .line 27
    if-nez v1, :cond_2

    .line 28
    .line 29
    const-string v1, "android.permission.FOREGROUND_SERVICE_MICROPHONE"

    .line 30
    .line 31
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 32
    .line 33
    .line 34
    move-result v1

    .line 35
    if-nez v1, :cond_2

    .line 36
    .line 37
    const-string v1, "android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION"

    .line 38
    .line 39
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 40
    .line 41
    .line 42
    move-result v1

    .line 43
    if-nez v1, :cond_2

    .line 44
    .line 45
    const-string v1, "android.permission.FOREGROUND_SERVICE_CAMERA"

    .line 46
    .line 47
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 48
    .line 49
    .line 50
    move-result v1

    .line 51
    if-nez v1, :cond_2

    .line 52
    .line 53
    const-string v1, "android.permission.FOREGROUND_SERVICE_LOCATION"

    .line 54
    .line 55
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 56
    .line 57
    .line 58
    move-result v1

    .line 59
    if-nez v1, :cond_2

    .line 60
    .line 61
    const-string v1, "android.permission.FOREGROUND_SERVICE_HEALTH"

    .line 62
    .line 63
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 64
    .line 65
    .line 66
    move-result v1

    .line 67
    if-nez v1, :cond_2

    .line 68
    .line 69
    const-string v1, "android.permission.FOREGROUND_SERVICE_DATA_SYNC"

    .line 70
    .line 71
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 72
    .line 73
    .line 74
    move-result v1

    .line 75
    if-nez v1, :cond_2

    .line 76
    .line 77
    const-string v1, "android.permission.FOREGROUND_SERVICE_SPECIAL_USE"

    .line 78
    .line 79
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 80
    .line 81
    .line 82
    move-result v1

    .line 83
    if-nez v1, :cond_2

    .line 84
    .line 85
    const-string v1, "android.permission.FOREGROUND_SERVICE_SYSTEM_EXEMPTED"

    .line 86
    .line 87
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 88
    .line 89
    .line 90
    move-result v1

    .line 91
    if-nez v1, :cond_2

    .line 92
    .line 93
    const-string v1, "android.permission.FOREGROUND_SERVICE_PHONE_CALL"

    .line 94
    .line 95
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 96
    .line 97
    .line 98
    move-result v1

    .line 99
    if-nez v1, :cond_2

    .line 100
    .line 101
    const-string v1, "android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"

    .line 102
    .line 103
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 104
    .line 105
    .line 106
    move-result p0

    .line 107
    if-eqz p0, :cond_1

    .line 108
    .line 109
    goto :goto_0

    .line 110
    :cond_1
    return v0

    .line 111
    :cond_2
    :goto_0
    const/4 p0, 0x1

    .line 112
    return p0
.end method

.method private static isNotificationOrXiaomiPermission(Ljava/lang/String;)Z
    .locals 3

    .line 1
    const/4 v0, 0x0

    .line 2
    if-nez p0, :cond_0

    .line 3
    .line 4
    return v0

    .line 5
    :cond_0
    const-string v1, "android.permission.POST_NOTIFICATIONS"

    .line 6
    .line 7
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 8
    .line 9
    .line 10
    move-result v1

    .line 11
    const/4 v2, 0x1

    .line 12
    if-eqz v1, :cond_1

    .line 13
    .line 14
    return v2

    .line 15
    :cond_1
    const-string v1, "miui.permission.USE_INTERNAL_GENERAL_API"

    .line 16
    .line 17
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 18
    .line 19
    .line 20
    move-result v1

    .line 21
    if-nez v1, :cond_3

    .line 22
    .line 23
    const-string v1, "miui.permission.OPTIMIZE_POWER"

    .line 24
    .line 25
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 26
    .line 27
    .line 28
    move-result v1

    .line 29
    if-nez v1, :cond_3

    .line 30
    .line 31
    const-string v1, "miui.permission.RUN_IN_BACKGROUND"

    .line 32
    .line 33
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 34
    .line 35
    .line 36
    move-result v1

    .line 37
    if-nez v1, :cond_3

    .line 38
    .line 39
    const-string v1, "miui.permission.POST_NOTIFICATIONS"

    .line 40
    .line 41
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 42
    .line 43
    .line 44
    move-result v1

    .line 45
    if-nez v1, :cond_3

    .line 46
    .line 47
    const-string v1, "miui.permission.AUTO_START"

    .line 48
    .line 49
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 50
    .line 51
    .line 52
    move-result v1

    .line 53
    if-nez v1, :cond_3

    .line 54
    .line 55
    const-string v1, "miui.permission.BACKGROUND_POPUP_WINDOW"

    .line 56
    .line 57
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 58
    .line 59
    .line 60
    move-result v1

    .line 61
    if-nez v1, :cond_3

    .line 62
    .line 63
    const-string v1, "miui.permission.SHOW_WHEN_LOCKED"

    .line 64
    .line 65
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 66
    .line 67
    .line 68
    move-result v1

    .line 69
    if-nez v1, :cond_3

    .line 70
    .line 71
    const-string v1, "miui.permission.TURN_SCREEN_ON"

    .line 72
    .line 73
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 74
    .line 75
    .line 76
    move-result p0

    .line 77
    if-eqz p0, :cond_2

    .line 78
    .line 79
    goto :goto_0

    .line 80
    :cond_2
    return v0

    .line 81
    :cond_3
    :goto_0
    return v2
.end method

.method private static isStorageOrMediaPermission(Ljava/lang/String;)Z
    .locals 3

    .line 1
    const/4 v0, 0x0

    .line 2
    if-nez p0, :cond_0

    .line 3
    .line 4
    return v0

    .line 5
    :cond_0
    const-string v1, "android.permission.READ_EXTERNAL_STORAGE"

    .line 6
    .line 7
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 8
    .line 9
    .line 10
    move-result v1

    .line 11
    const/4 v2, 0x1

    .line 12
    if-nez v1, :cond_4

    .line 13
    .line 14
    const-string v1, "android.permission.WRITE_EXTERNAL_STORAGE"

    .line 15
    .line 16
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 17
    .line 18
    .line 19
    move-result v1

    .line 20
    if-eqz v1, :cond_1

    .line 21
    .line 22
    goto :goto_0

    .line 23
    :cond_1
    const-string v1, "android.permission.READ_MEDIA_AUDIO"

    .line 24
    .line 25
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 26
    .line 27
    .line 28
    move-result v1

    .line 29
    if-nez v1, :cond_4

    .line 30
    .line 31
    const-string v1, "android.permission.READ_MEDIA_VIDEO"

    .line 32
    .line 33
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 34
    .line 35
    .line 36
    move-result v1

    .line 37
    if-nez v1, :cond_4

    .line 38
    .line 39
    const-string v1, "android.permission.READ_MEDIA_IMAGES"

    .line 40
    .line 41
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 42
    .line 43
    .line 44
    move-result v1

    .line 45
    if-nez v1, :cond_4

    .line 46
    .line 47
    const-string v1, "android.permission.READ_MEDIA_VISUAL"

    .line 48
    .line 49
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 50
    .line 51
    .line 52
    move-result v1

    .line 53
    if-nez v1, :cond_4

    .line 54
    .line 55
    const-string v1, "android.permission.READ_MEDIA_AURAL"

    .line 56
    .line 57
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 58
    .line 59
    .line 60
    move-result v1

    .line 61
    if-nez v1, :cond_4

    .line 62
    .line 63
    const-string v1, "android.permission.ACCESS_MEDIA_LOCATION"

    .line 64
    .line 65
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 66
    .line 67
    .line 68
    move-result v1

    .line 69
    if-eqz v1, :cond_2

    .line 70
    .line 71
    goto :goto_0

    .line 72
    :cond_2
    const-string v1, "android.permission.READ_MEDIA_AUDIO_USER_SELECTED"

    .line 73
    .line 74
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 75
    .line 76
    .line 77
    move-result v1

    .line 78
    if-nez v1, :cond_4

    .line 79
    .line 80
    const-string v1, "android.permission.READ_MEDIA_VIDEO_USER_SELECTED"

    .line 81
    .line 82
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 83
    .line 84
    .line 85
    move-result v1

    .line 86
    if-nez v1, :cond_4

    .line 87
    .line 88
    const-string v1, "android.permission.READ_MEDIA_IMAGES_USER_SELECTED"

    .line 89
    .line 90
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 91
    .line 92
    .line 93
    move-result v1

    .line 94
    if-nez v1, :cond_4

    .line 95
    .line 96
    const-string v1, "android.permission.READ_MEDIA_VISUAL_USER_SELECTED"

    .line 97
    .line 98
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 99
    .line 100
    .line 101
    move-result v1

    .line 102
    if-nez v1, :cond_4

    .line 103
    .line 104
    const-string v1, "android.permission.READ_MEDIA_AURAL_USER_SELECTED"

    .line 105
    .line 106
    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 107
    .line 108
    .line 109
    move-result p0

    .line 110
    if-eqz p0, :cond_3

    .line 111
    .line 112
    goto :goto_0

    .line 113
    :cond_3
    return v0

    .line 114
    :cond_4
    :goto_0
    return v2
.end method


# virtual methods
.method public getWho()Ljava/lang/Object;
    .locals 3

    .line 1
    const/4 v0, 0x0

    .line 2
    const/4 v1, 0x0

    .line 3
    const-class v2, Lblack/android/app/ActivityThreadStatic;

    .line 4
    .line 5
    invoke-static {v2, v0, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 6
    .line 7
    .line 8
    move-result-object v0

    .line 9
    check-cast v0, Lblack/android/app/ActivityThreadStatic;

    .line 10
    .line 11
    invoke-interface {v0}, Lblack/android/app/ActivityThreadStatic;->sPackageManager()Landroid/os/IInterface;

    .line 12
    .line 13
    .line 14
    move-result-object v0

    .line 15
    return-object v0
.end method

.method public inject(Ljava/lang/Object;Ljava/lang/Object;)V
    .locals 4

    .line 1
    const-class p1, Lblack/android/app/ActivityThreadStatic;

    .line 2
    .line 3
    const/4 v0, 0x0

    .line 4
    const/4 v1, 0x0

    .line 5
    invoke-static {p1, v0, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 6
    .line 7
    .line 8
    move-result-object p1

    .line 9
    check-cast p1, Lblack/android/app/ActivityThreadStatic;

    .line 10
    .line 11
    invoke-interface {p1, p2}, Lblack/android/app/ActivityThreadStatic;->_set_sPackageManager(Ljava/lang/Object;)V

    .line 12
    .line 13
    .line 14
    const-string p1, "package"

    .line 15
    .line 16
    invoke-virtual {p0, p1}, Ltop/niunaijun/blackbox/fake/hook/BinderInvocationStub;->replaceSystemService(Ljava/lang/String;)V

    .line 17
    .line 18
    .line 19
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->mainThread()Ljava/lang/Object;

    .line 20
    .line 21
    .line 22
    move-result-object p1

    .line 23
    const-class v2, Lblack/android/app/ActivityThreadContext;

    .line 24
    .line 25
    invoke-static {v2, p1, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 26
    .line 27
    .line 28
    move-result-object p1

    .line 29
    check-cast p1, Lblack/android/app/ActivityThreadContext;

    .line 30
    .line 31
    invoke-interface {p1}, Lblack/android/app/ActivityThreadContext;->getSystemContext()Ljava/lang/Object;

    .line 32
    .line 33
    .line 34
    move-result-object p1

    .line 35
    const-class v2, Lblack/android/app/ContextImplContext;

    .line 36
    .line 37
    invoke-static {v2, p1, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 38
    .line 39
    .line 40
    move-result-object v3

    .line 41
    check-cast v3, Lblack/android/app/ContextImplContext;

    .line 42
    .line 43
    invoke-interface {v3}, Lblack/android/app/ContextImplContext;->getPackageManager()Landroid/content/pm/PackageManager;

    .line 44
    .line 45
    .line 46
    invoke-static {v2, p1, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 47
    .line 48
    .line 49
    move-result-object p1

    .line 50
    check-cast p1, Lblack/android/app/ContextImplContext;

    .line 51
    .line 52
    invoke-interface {p1}, Lblack/android/app/ContextImplContext;->mPackageManager()Landroid/content/pm/PackageManager;

    .line 53
    .line 54
    .line 55
    move-result-object p1

    .line 56
    if-eqz p1, :cond_0

    .line 57
    .line 58
    const-class v2, Lblack/android/content/pm/PackageManagerStatic;

    .line 59
    .line 60
    invoke-static {v2, v0, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 61
    .line 62
    .line 63
    move-result-object v0

    .line 64
    check-cast v0, Lblack/android/content/pm/PackageManagerStatic;

    .line 65
    .line 66
    invoke-interface {v0}, Lblack/android/content/pm/PackageManagerStatic;->disableApplicationInfoCache()Ljava/lang/Void;

    .line 67
    .line 68
    .line 69
    :try_start_0
    const-string v0, "android.app.ApplicationPackageManager"

    .line 70
    .line 71
    invoke-static {v0}, Ltop/niunaijun/blackbox/utils/Reflector;->on(Ljava/lang/String;)Ltop/niunaijun/blackbox/utils/Reflector;

    .line 72
    .line 73
    .line 74
    move-result-object v0

    .line 75
    const-string v1, "mPM"

    .line 76
    .line 77
    invoke-virtual {v0, v1}, Ltop/niunaijun/blackbox/utils/Reflector;->field(Ljava/lang/String;)Ltop/niunaijun/blackbox/utils/Reflector;

    .line 78
    .line 79
    .line 80
    move-result-object v0

    .line 81
    invoke-virtual {v0, p1, p2}, Ltop/niunaijun/blackbox/utils/Reflector;->set(Ljava/lang/Object;Ljava/lang/Object;)Ltop/niunaijun/blackbox/utils/Reflector;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 82
    .line 83
    .line 84
    return-void

    .line 85
    :catch_0
    move-exception p1

    .line 86
    invoke-virtual {p1}, Ljava/lang/Throwable;->printStackTrace()V

    .line 87
    .line 88
    .line 89
    :cond_0
    return-void
.end method

.method public invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 2

    invoke-static {p2, p3}, Lio/github/leexeo/cage/space/GuestInstaller;->querySource(Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    if-eqz v0, :recovery_import_identity

    return-object v0

    :recovery_import_identity
    invoke-static {p2, p3}, Lio/github/leexeo/cage/space/GuestPackageIdentity;->query(Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    if-eqz v0, :cond_0

    return-object v0

    :cond_0
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v0

    const-string v1, "getPackageInstaller"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_1

    invoke-static {}, Lio/github/leexeo/cage/space/GuestInstaller;->get()Ljava/lang/Object;

    move-result-object v0

    return-object v0

    :cond_1
    invoke-super {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/fake/hook/BinderInvocationStub;->invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    return-object v0
.end method

.method public isBadEnv()Z
    .locals 1

    .line 1
    const/4 v0, 0x0

    .line 2
    return v0
.end method

.method public onBindMethod()V
    .locals 3

    .line 1
    invoke-super {p0}, Ltop/niunaijun/blackbox/fake/hook/BinderInvocationStub;->onBindMethod()V

    .line 2
    .line 3
    .line 4
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/base/ValueMethodProxy;

    .line 5
    .line 6
    const/4 v1, 0x0

    .line 7
    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 8
    .line 9
    .line 10
    move-result-object v1

    .line 11
    const-string v2, "addOnPermissionsChangeListener"

    .line 12
    .line 13
    invoke-direct {v0, v2, v1}, Ltop/niunaijun/blackbox/fake/service/base/ValueMethodProxy;-><init>(Ljava/lang/String;Ljava/lang/Object;)V

    .line 14
    .line 15
    .line 16
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 17
    .line 18
    .line 19
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/base/ValueMethodProxy;

    .line 20
    .line 21
    const-string v2, "removeOnPermissionsChangeListener"

    .line 22
    .line 23
    invoke-direct {v0, v2, v1}, Ltop/niunaijun/blackbox/fake/service/base/ValueMethodProxy;-><init>(Ljava/lang/String;Ljava/lang/Object;)V

    .line 24
    .line 25
    .line 26
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 27
    .line 28
    .line 29
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$SimpleAudioPermissionHook;

    .line 30
    .line 31
    invoke-direct {v0}, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$SimpleAudioPermissionHook;-><init>()V

    .line 32
    .line 33
    .line 34
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 35
    .line 36
    .line 37
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$CheckSelfPermission;

    .line 38
    .line 39
    invoke-direct {v0}, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$CheckSelfPermission;-><init>()V

    .line 40
    .line 41
    .line 42
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 43
    .line 44
    .line 45
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$ShouldShowRequestPermissionRationale;

    .line 46
    .line 47
    invoke-direct {v0}, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$ShouldShowRequestPermissionRationale;-><init>()V

    .line 48
    .line 49
    .line 50
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 51
    .line 52
    .line 53
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$RequestPermissions;

    .line 54
    .line 55
    invoke-direct {v0}, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$RequestPermissions;-><init>()V

    .line 56
    .line 57
    .line 58
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 59
    .line 60
    .line 61
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$DisableIconLoading;

    .line 62
    .line 63
    invoke-direct {v0}, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$DisableIconLoading;-><init>()V

    .line 64
    .line 65
    .line 66
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 67
    .line 68
    .line 69
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$SetSplashScreenTheme;

    .line 70
    .line 71
    invoke-direct {v0}, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$SetSplashScreenTheme;-><init>()V

    .line 72
    .line 73
    .line 74
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 75
    .line 76
    .line 77
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$XiaomiSecurityBypass;

    .line 78
    .line 79
    invoke-direct {v0}, Ltop/niunaijun/blackbox/fake/service/IPackageManagerProxy$XiaomiSecurityBypass;-><init>()V

    .line 80
    .line 81
    .line 82
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 83
    .line 84
    .line 85
    return-void
.end method
