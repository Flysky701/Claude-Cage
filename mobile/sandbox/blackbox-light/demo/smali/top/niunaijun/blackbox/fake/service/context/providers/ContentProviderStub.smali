.class public Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;
.super Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"

# interfaces
.implements Ltop/niunaijun/blackbox/fake/service/context/providers/BContentProvider;


# static fields
.field public static final TAG:Ljava/lang/String; = "ContentProviderStub"


# instance fields
.field private mAppPkg:Ljava/lang/String;

.field private mBase:Landroid/os/IInterface;


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 1
    invoke-direct {p0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;-><init>()V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method private fixAttributionSourceUid(Ljava/lang/Object;)V
    .locals 6

    .line 1
    const-string v0, "ContentProviderStub"

    .line 2
    .line 3
    const-string v1, "Could not fix AttributionSource UID: "

    .line 4
    .line 5
    if-nez p1, :cond_0

    .line 6
    .line 7
    goto/16 :goto_2

    .line 8
    .line 9
    :cond_0
    :try_start_0
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 10
    .line 11
    .line 12
    move-result-object v2
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 13
    const/4 v3, 0x1

    .line 14
    :try_start_1
    const-string v4, "mUid"

    .line 15
    .line 16
    invoke-virtual {v2, v4}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    .line 17
    .line 18
    .line 19
    move-result-object v4

    .line 20
    invoke-virtual {v4, v3}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 21
    .line 22
    .line 23
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostUid()I

    .line 24
    .line 25
    .line 26
    move-result v5

    .line 27
    invoke-static {v5}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 28
    .line 29
    .line 30
    move-result-object v5

    .line 31
    invoke-virtual {v4, p1, v5}, Ljava/lang/reflect/Field;->set(Ljava/lang/Object;Ljava/lang/Object;)V

    .line 32
    .line 33
    .line 34
    const-string v4, "Fixed AttributionSource UID via field access"

    .line 35
    .line 36
    invoke-static {v0, v4}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catch Ljava/lang/NoSuchFieldException; {:try_start_1 .. :try_end_1} :catch_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 37
    .line 38
    .line 39
    goto :goto_0

    .line 40
    :catch_0
    move-exception p1

    .line 41
    goto :goto_1

    .line 42
    :catch_1
    :try_start_2
    const-string v4, "uid"

    .line 43
    .line 44
    invoke-virtual {v2, v4}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    .line 45
    .line 46
    .line 47
    move-result-object v4

    .line 48
    invoke-virtual {v4, v3}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 49
    .line 50
    .line 51
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostUid()I

    .line 52
    .line 53
    .line 54
    move-result v5

    .line 55
    invoke-static {v5}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 56
    .line 57
    .line 58
    move-result-object v5

    .line 59
    invoke-virtual {v4, p1, v5}, Ljava/lang/reflect/Field;->set(Ljava/lang/Object;Ljava/lang/Object;)V

    .line 60
    .line 61
    .line 62
    const-string v4, "Fixed AttributionSource UID via alternative field"

    .line 63
    .line 64
    invoke-static {v0, v4}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/NoSuchFieldException; {:try_start_2 .. :try_end_2} :catch_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_0

    .line 65
    .line 66
    .line 67
    goto :goto_0

    .line 68
    :catch_2
    :try_start_3
    const-string v4, "setUid"

    .line 69
    .line 70
    sget-object v5, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    .line 71
    .line 72
    filled-new-array {v5}, [Ljava/lang/Class;

    .line 73
    .line 74
    .line 75
    move-result-object v5

    .line 76
    invoke-virtual {v2, v4, v5}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    .line 77
    .line 78
    .line 79
    move-result-object v4

    .line 80
    invoke-virtual {v4, v3}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 81
    .line 82
    .line 83
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostUid()I

    .line 84
    .line 85
    .line 86
    move-result v5

    .line 87
    invoke-static {v5}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 88
    .line 89
    .line 90
    move-result-object v5

    .line 91
    filled-new-array {v5}, [Ljava/lang/Object;

    .line 92
    .line 93
    .line 94
    move-result-object v5

    .line 95
    invoke-virtual {v4, p1, v5}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 96
    .line 97
    .line 98
    const-string v4, "Fixed AttributionSource UID via setter method"

    .line 99
    .line 100
    invoke-static {v0, v4}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_3

    .line 101
    .line 102
    .line 103
    goto :goto_0

    .line 104
    :catch_3
    move-exception v4

    .line 105
    :try_start_4
    new-instance v5, Ljava/lang/StringBuilder;

    .line 106
    .line 107
    invoke-direct {v5, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 108
    .line 109
    .line 110
    invoke-virtual {v4}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 111
    .line 112
    .line 113
    move-result-object v1

    .line 114
    invoke-virtual {v5, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 115
    .line 116
    .line 117
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 118
    .line 119
    .line 120
    move-result-object v1

    .line 121
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_4
    .catch Ljava/lang/Exception; {:try_start_4 .. :try_end_4} :catch_0

    .line 122
    .line 123
    .line 124
    :goto_0
    :try_start_5
    const-string v1, "mPackageName"

    .line 125
    .line 126
    invoke-virtual {v2, v1}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    .line 127
    .line 128
    .line 129
    move-result-object v1

    .line 130
    invoke-virtual {v1, v3}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 131
    .line 132
    .line 133
    iget-object v2, p0, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->mAppPkg:Ljava/lang/String;

    .line 134
    .line 135
    invoke-virtual {v1, p1, v2}, Ljava/lang/reflect/Field;->set(Ljava/lang/Object;Ljava/lang/Object;)V

    .line 136
    .line 137
    .line 138
    const-string p1, "Fixed AttributionSource package name"

    .line 139
    .line 140
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_5
    .catch Ljava/lang/Exception; {:try_start_5 .. :try_end_5} :catch_4

    .line 141
    .line 142
    .line 143
    goto :goto_2

    .line 144
    :goto_1
    const-string v1, "Error fixing AttributionSource UID: "

    .line 145
    .line 146
    invoke-static {v1, p1, v0}, Landroidx/fragment/app/x0;->n(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 147
    .line 148
    .line 149
    :catch_4
    :goto_2
    return-void
.end method

.method private getSafeDefaultValue(Ljava/lang/String;)Ljava/lang/Object;
    .locals 4

    const/4 v0, 0x0

    .line 1
    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    .line 2
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    invoke-virtual {p1}, Ljava/lang/String;->hashCode()I

    move-result v2

    const/4 v3, -0x1

    sparse-switch v2, :sswitch_data_0

    :goto_0
    move v0, v3

    goto :goto_1

    :sswitch_0
    const-string v0, "call"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-nez p1, :cond_0

    goto :goto_0

    :cond_0
    const/4 v0, 0x3

    goto :goto_1

    :sswitch_1
    const-string v0, "update"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-nez p1, :cond_1

    goto :goto_0

    :cond_1
    const/4 v0, 0x2

    goto :goto_1

    :sswitch_2
    const-string v0, "bulkInsert"

    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-nez p1, :cond_2

    goto :goto_0

    :cond_2
    const/4 v0, 0x1

    goto :goto_1

    :sswitch_3
    const-string v2, "delete"

    invoke-virtual {p1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-nez p1, :cond_3

    goto :goto_0

    :cond_3
    :goto_1
    packed-switch v0, :pswitch_data_0

    const/4 p1, 0x0

    return-object p1

    .line 3
    :pswitch_0
    new-instance p1, Landroid/os/Bundle;

    invoke-direct {p1}, Landroid/os/Bundle;-><init>()V

    return-object p1

    :pswitch_1
    return-object v1

    :sswitch_data_0
    .sparse-switch
        -0x4f997a55 -> :sswitch_3
        -0x468c9595 -> :sswitch_2
        -0x31ffc737 -> :sswitch_1
        0x2e7a5e -> :sswitch_0
    .end sparse-switch

    :pswitch_data_0
    .packed-switch 0x0
        :pswitch_1
        :pswitch_1
        :pswitch_1
        :pswitch_0
    .end packed-switch
.end method

.method private getSafeDefaultValue(Ljava/lang/String;Ljava/lang/Class;)Ljava/lang/Object;
    .locals 1
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/lang/String;",
            "Ljava/lang/Class<",
            "*>;)",
            "Ljava/lang/Object;"
        }
    .end annotation

    if-nez p2, :cond_0

    .line 4
    invoke-direct {p0, p1}, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->getSafeDefaultValue(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object p1

    return-object p1

    .line 5
    :cond_0
    const-class v0, Ljava/lang/String;

    if-ne p2, v0, :cond_1

    .line 6
    const-string p1, "true"

    return-object p1

    .line 7
    :cond_1
    sget-object v0, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    if-eq p2, v0, :cond_a

    const-class v0, Ljava/lang/Integer;

    if-ne p2, v0, :cond_2

    goto :goto_3

    .line 8
    :cond_2
    sget-object v0, Ljava/lang/Long;->TYPE:Ljava/lang/Class;

    if-eq p2, v0, :cond_9

    const-class v0, Ljava/lang/Long;

    if-ne p2, v0, :cond_3

    goto :goto_2

    .line 9
    :cond_3
    sget-object v0, Ljava/lang/Float;->TYPE:Ljava/lang/Class;

    if-eq p2, v0, :cond_8

    const-class v0, Ljava/lang/Float;

    if-ne p2, v0, :cond_4

    goto :goto_1

    .line 10
    :cond_4
    sget-object v0, Ljava/lang/Boolean;->TYPE:Ljava/lang/Class;

    if-eq p2, v0, :cond_7

    const-class v0, Ljava/lang/Boolean;

    if-ne p2, v0, :cond_5

    goto :goto_0

    .line 11
    :cond_5
    const-class v0, Landroid/os/Bundle;

    if-ne p2, v0, :cond_6

    .line 12
    new-instance p1, Landroid/os/Bundle;

    invoke-direct {p1}, Landroid/os/Bundle;-><init>()V

    return-object p1

    .line 13
    :cond_6
    invoke-direct {p0, p1}, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->getSafeDefaultValue(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object p1

    return-object p1

    .line 14
    :cond_7
    :goto_0
    sget-object p1, Ljava/lang/Boolean;->TRUE:Ljava/lang/Boolean;

    return-object p1

    :cond_8
    :goto_1
    const/high16 p1, 0x3f800000    # 1.0f

    .line 15
    invoke-static {p1}, Ljava/lang/Float;->valueOf(F)Ljava/lang/Float;

    move-result-object p1

    return-object p1

    :cond_9
    :goto_2
    const-wide/16 p1, 0x1

    .line 16
    invoke-static {p1, p2}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;

    move-result-object p1

    return-object p1

    :cond_a
    :goto_3
    const/4 p1, 0x1

    .line 17
    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p1

    return-object p1
.end method

.method private isSystemProviderAuthority(Ljava/lang/String;)Z
    .locals 2

    .line 1
    const/4 v0, 0x0

    .line 2
    if-nez p1, :cond_0

    .line 3
    .line 4
    return v0

    .line 5
    :cond_0
    const-string v1, "settings"

    .line 6
    .line 7
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 8
    .line 9
    .line 10
    move-result v1

    .line 11
    if-nez v1, :cond_2

    .line 12
    .line 13
    const-string v1, "settings_global"

    .line 14
    .line 15
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 16
    .line 17
    .line 18
    move-result v1

    .line 19
    if-nez v1, :cond_2

    .line 20
    .line 21
    const-string v1, "settings_system"

    .line 22
    .line 23
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 24
    .line 25
    .line 26
    move-result v1

    .line 27
    if-nez v1, :cond_2

    .line 28
    .line 29
    const-string v1, "settings_secure"

    .line 30
    .line 31
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 32
    .line 33
    .line 34
    move-result v1

    .line 35
    if-nez v1, :cond_2

    .line 36
    .line 37
    const-string v1, "media"

    .line 38
    .line 39
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 40
    .line 41
    .line 42
    move-result v1

    .line 43
    if-nez v1, :cond_2

    .line 44
    .line 45
    const-string v1, "telephony"

    .line 46
    .line 47
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 48
    .line 49
    .line 50
    move-result v1

    .line 51
    if-nez v1, :cond_2

    .line 52
    .line 53
    const-string v1, "android.provider.Settings"

    .line 54
    .line 55
    invoke-virtual {p1, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    .line 56
    .line 57
    .line 58
    move-result p1

    .line 59
    if-eqz p1, :cond_1

    .line 60
    .line 61
    goto :goto_0

    .line 62
    :cond_1
    return v0

    .line 63
    :cond_2
    :goto_0
    const/4 p1, 0x1

    .line 64
    return p1
.end method

.method private isUidMismatchError(Ljava/lang/Throwable;)Z
    .locals 2

    .line 1
    const/4 v0, 0x0

    .line 2
    if-nez p1, :cond_0

    .line 3
    .line 4
    return v0

    .line 5
    :cond_0
    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 6
    .line 7
    .line 8
    move-result-object p1

    .line 9
    if-nez p1, :cond_1

    .line 10
    .line 11
    return v0

    .line 12
    :cond_1
    const-string v1, "Calling uid"

    .line 13
    .line 14
    invoke-virtual {p1, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 15
    .line 16
    .line 17
    move-result v1

    .line 18
    if-eqz v1, :cond_2

    .line 19
    .line 20
    const-string v1, "doesn\'t match source uid"

    .line 21
    .line 22
    invoke-virtual {p1, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 23
    .line 24
    .line 25
    move-result v1

    .line 26
    if-nez v1, :cond_5

    .line 27
    .line 28
    :cond_2
    const-string v1, "uid"

    .line 29
    .line 30
    invoke-virtual {p1, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 31
    .line 32
    .line 33
    move-result v1

    .line 34
    if-eqz v1, :cond_3

    .line 35
    .line 36
    const-string v1, "permission"

    .line 37
    .line 38
    invoke-virtual {p1, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 39
    .line 40
    .line 41
    move-result v1

    .line 42
    if-nez v1, :cond_5

    .line 43
    .line 44
    :cond_3
    const-string v1, "SecurityException"

    .line 45
    .line 46
    invoke-virtual {p1, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 47
    .line 48
    .line 49
    move-result v1

    .line 50
    if-nez v1, :cond_5

    .line 51
    .line 52
    const-string v1, "UID mismatch"

    .line 53
    .line 54
    invoke-virtual {p1, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 55
    .line 56
    .line 57
    move-result p1

    .line 58
    if-eqz p1, :cond_4

    .line 59
    .line 60
    goto :goto_0

    .line 61
    :cond_4
    return v0

    .line 62
    :cond_5
    :goto_0
    const/4 p1, 0x1

    .line 63
    return p1
.end method


# virtual methods
.method public getWho()Ljava/lang/Object;
    .locals 1

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->mBase:Landroid/os/IInterface;

    .line 2
    .line 3
    return-object v0
.end method

.method public inject(Ljava/lang/Object;Ljava/lang/Object;)V
    .locals 0

    .line 1
    return-void
.end method

.method public invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 4

    iget-object v0, p0, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->mAppPkg:Ljava/lang/String;

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestProviders;->internal(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_0

    iget-object v0, p0, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->mBase:Landroid/os/IInterface;

    invoke-static {v0, p2, p3}, Lio/github/leexeo/cage/space/GuestProviders;->invoke(Landroid/os/IInterface;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    return-object v0

    .line 1
    :cond_0
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    .line 2
    .line 3
    .line 4
    move-result-object p1

    .line 5
    const-string v0, "asBinder"

    .line 6
    .line 7
    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 8
    .line 9
    .line 10
    move-result p1

    .line 11
    if-eqz p1, :cond_1

    .line 12
    .line 13
    iget-object p1, p0, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->mBase:Landroid/os/IInterface;

    .line 14
    .line 15
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 16
    .line 17
    .line 18
    move-result-object p1

    .line 19
    return-object p1

    .line 20
    :cond_1
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    .line 21
    .line 22
    .line 23
    move-result-object p1

    .line 24
    const-string v0, "call"

    .line 25
    .line 26
    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 27
    .line 28
    .line 29
    move-result p1

    .line 30
    if-eqz p1, :cond_2

    .line 31
    .line 32
    invoke-static {p3}, Ltop/niunaijun/blackbox/utils/AttributionSourceUtils;->fixAttributionSourceInArgs([Ljava/lang/Object;)V

    .line 33
    .line 34
    .line 35
    goto :goto_1

    .line 36
    :cond_2
    if-eqz p3, :cond_5

    .line 37
    .line 38
    array-length p1, p3

    .line 39
    if-lez p1, :cond_5

    .line 40
    .line 41
    const/4 p1, 0x0

    .line 42
    :goto_0
    array-length v1, p3

    .line 43
    if-ge p1, v1, :cond_4

    .line 44
    .line 45
    aget-object v1, p3, p1

    .line 46
    .line 47
    instance-of v2, v1, Ljava/lang/String;

    .line 48
    .line 49
    if-eqz v2, :cond_3

    .line 50
    .line 51
    check-cast v1, Ljava/lang/String;

    .line 52
    .line 53
    invoke-direct {p0, v1}, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->isSystemProviderAuthority(Ljava/lang/String;)Z

    .line 54
    .line 55
    .line 56
    move-result v1

    .line 57
    if-nez v1, :cond_3

    .line 58
    .line 59
    iget-object v1, p0, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->mAppPkg:Ljava/lang/String;

    .line 60
    .line 61
    aput-object v1, p3, p1

    .line 62
    .line 63
    :cond_3
    add-int/lit8 p1, p1, 0x1

    .line 64
    .line 65
    goto :goto_0

    .line 66
    :cond_4
    invoke-static {p3}, Ltop/niunaijun/blackbox/utils/AttributionSourceUtils;->fixAttributionSourceInArgs([Ljava/lang/Object;)V

    .line 67
    .line 68
    .line 69
    :cond_5
    :goto_1
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    .line 70
    .line 71
    .line 72
    move-result-object p1

    .line 73
    const-string v1, "query"

    .line 74
    .line 75
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 76
    .line 77
    .line 78
    move-result v1

    .line 79
    const-string v2, "ContentProviderStub"

    .line 80
    .line 81
    if-nez v1, :cond_8

    .line 82
    .line 83
    const-string v1, "insert"

    .line 84
    .line 85
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 86
    .line 87
    .line 88
    move-result v1

    .line 89
    if-nez v1, :cond_8

    .line 90
    .line 91
    const-string v1, "update"

    .line 92
    .line 93
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 94
    .line 95
    .line 96
    move-result v1

    .line 97
    if-nez v1, :cond_8

    .line 98
    .line 99
    const-string v1, "delete"

    .line 100
    .line 101
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 102
    .line 103
    .line 104
    move-result v1

    .line 105
    if-nez v1, :cond_8

    .line 106
    .line 107
    const-string v1, "bulkInsert"

    .line 108
    .line 109
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 110
    .line 111
    .line 112
    move-result v1

    .line 113
    if-nez v1, :cond_8

    .line 114
    .line 115
    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 116
    .line 117
    .line 118
    move-result v1

    .line 119
    if-eqz v1, :cond_6

    .line 120
    .line 121
    goto :goto_2

    .line 122
    :cond_6
    :try_start_0
    iget-object v0, p0, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->mBase:Landroid/os/IInterface;

    .line 123
    .line 124
    invoke-virtual {p2, v0, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 125
    .line 126
    .line 127
    move-result-object p1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 128
    return-object p1

    .line 129
    :catchall_0
    move-exception p3

    .line 130
    invoke-virtual {p3}, Ljava/lang/Throwable;->getCause()Ljava/lang/Throwable;

    .line 131
    .line 132
    .line 133
    move-result-object v0

    .line 134
    invoke-direct {p0, v0}, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->isUidMismatchError(Ljava/lang/Throwable;)Z

    .line 135
    .line 136
    .line 137
    move-result v1

    .line 138
    if-eqz v1, :cond_7

    .line 139
    .line 140
    const-string p3, "UID mismatch in "

    .line 141
    .line 142
    const-string v1, ", returning safe default: "

    .line 143
    .line 144
    invoke-static {p3, p1, v1}, Ltop/niunaijun/blackbox/a;->a(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 145
    .line 146
    .line 147
    move-result-object p3

    .line 148
    invoke-virtual {v0}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 149
    .line 150
    .line 151
    move-result-object v0

    .line 152
    invoke-virtual {p3, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 153
    .line 154
    .line 155
    invoke-virtual {p3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 156
    .line 157
    .line 158
    move-result-object p3

    .line 159
    invoke-static {v2, p3}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 160
    .line 161
    .line 162
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getReturnType()Ljava/lang/Class;

    .line 163
    .line 164
    .line 165
    move-result-object p2

    .line 166
    invoke-direct {p0, p1, p2}, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->getSafeDefaultValue(Ljava/lang/String;Ljava/lang/Class;)Ljava/lang/Object;

    .line 167
    .line 168
    .line 169
    move-result-object p1

    .line 170
    return-object p1

    .line 171
    :cond_7
    invoke-virtual {p3}, Ljava/lang/Throwable;->getCause()Ljava/lang/Throwable;

    .line 172
    .line 173
    .line 174
    move-result-object p1

    .line 175
    throw p1

    .line 176
    :cond_8
    :goto_2
    :try_start_1
    iget-object v1, p0, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->mBase:Landroid/os/IInterface;

    .line 177
    .line 178
    invoke-virtual {p2, v1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 179
    .line 180
    .line 181
    move-result-object p1
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    .line 182
    return-object p1

    .line 183
    :catchall_1
    move-exception p3

    .line 184
    invoke-virtual {p3}, Ljava/lang/Throwable;->getCause()Ljava/lang/Throwable;

    .line 185
    .line 186
    .line 187
    move-result-object v1

    .line 188
    invoke-direct {p0, v1}, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->isUidMismatchError(Ljava/lang/Throwable;)Z

    .line 189
    .line 190
    .line 191
    move-result v3

    .line 192
    if-eqz v3, :cond_9

    .line 193
    .line 194
    new-instance p3, Ljava/lang/StringBuilder;

    .line 195
    .line 196
    const-string v0, "UID mismatch in ContentProvider call, returning safe default: "

    .line 197
    .line 198
    invoke-direct {p3, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 199
    .line 200
    .line 201
    invoke-virtual {v1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 202
    .line 203
    .line 204
    move-result-object v0

    .line 205
    invoke-virtual {p3, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 206
    .line 207
    .line 208
    invoke-virtual {p3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 209
    .line 210
    .line 211
    move-result-object p3

    .line 212
    invoke-static {v2, p3}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 213
    .line 214
    .line 215
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getReturnType()Ljava/lang/Class;

    .line 216
    .line 217
    .line 218
    move-result-object p2

    .line 219
    invoke-direct {p0, p1, p2}, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->getSafeDefaultValue(Ljava/lang/String;Ljava/lang/Class;)Ljava/lang/Object;

    .line 220
    .line 221
    .line 222
    move-result-object p1

    .line 223
    return-object p1

    .line 224
    :cond_9
    instance-of v3, v1, Ljava/lang/RuntimeException;

    .line 225
    .line 226
    if-eqz v3, :cond_b

    .line 227
    .line 228
    invoke-virtual {v1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 229
    .line 230
    .line 231
    move-result-object v1

    .line 232
    if-eqz v1, :cond_b

    .line 233
    .line 234
    const-string v3, "uid"

    .line 235
    .line 236
    invoke-virtual {v1, v3}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 237
    .line 238
    .line 239
    move-result v3

    .line 240
    if-nez v3, :cond_a

    .line 241
    .line 242
    const-string v3, "permission"

    .line 243
    .line 244
    invoke-virtual {v1, v3}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 245
    .line 246
    .line 247
    move-result v3

    .line 248
    if-eqz v3, :cond_b

    .line 249
    .line 250
    :cond_a
    const-string p3, "Permission/UID error in ContentProvider call, returning safe default: "

    .line 251
    .line 252
    invoke-virtual {p3, v1}, Ljava/lang/String;->concat(Ljava/lang/String;)Ljava/lang/String;

    .line 253
    .line 254
    .line 255
    move-result-object p3

    .line 256
    invoke-static {v2, p3}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 257
    .line 258
    .line 259
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getReturnType()Ljava/lang/Class;

    .line 260
    .line 261
    .line 262
    move-result-object p2

    .line 263
    invoke-direct {p0, p1, p2}, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->getSafeDefaultValue(Ljava/lang/String;Ljava/lang/Class;)Ljava/lang/Object;

    .line 264
    .line 265
    .line 266
    move-result-object p1

    .line 267
    return-object p1

    .line 268
    :cond_b
    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 269
    .line 270
    .line 271
    move-result v0

    .line 272
    if-eqz v0, :cond_c

    .line 273
    .line 274
    new-instance v0, Ljava/lang/StringBuilder;

    .line 275
    .line 276
    const-string v1, "Error in call method, returning safe default: "

    .line 277
    .line 278
    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 279
    .line 280
    .line 281
    invoke-virtual {p3}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 282
    .line 283
    .line 284
    move-result-object p3

    .line 285
    invoke-virtual {v0, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 286
    .line 287
    .line 288
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 289
    .line 290
    .line 291
    move-result-object p3

    .line 292
    invoke-static {v2, p3}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 293
    .line 294
    .line 295
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getReturnType()Ljava/lang/Class;

    .line 296
    .line 297
    .line 298
    move-result-object p2

    .line 299
    invoke-direct {p0, p1, p2}, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->getSafeDefaultValue(Ljava/lang/String;Ljava/lang/Class;)Ljava/lang/Object;

    .line 300
    .line 301
    .line 302
    move-result-object p1

    .line 303
    return-object p1

    .line 304
    :cond_c
    invoke-virtual {p3}, Ljava/lang/Throwable;->getCause()Ljava/lang/Throwable;

    .line 305
    .line 306
    .line 307
    move-result-object p1

    .line 308
    throw p1
.end method

.method public isBadEnv()Z
    .locals 1

    .line 1
    const/4 v0, 0x0

    .line 2
    return v0
.end method

.method public onBindMethod()V
    .locals 0

    .line 1
    return-void
.end method

.method public wrapper(Landroid/os/IInterface;Ljava/lang/String;)Landroid/os/IInterface;
    .locals 0

    .line 1
    iput-object p1, p0, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->mBase:Landroid/os/IInterface;

    .line 2
    .line 3
    iput-object p2, p0, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->mAppPkg:Ljava/lang/String;

    .line 4
    .line 5
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->injectHook()V

    .line 6
    .line 7
    .line 8
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->getProxyInvocation()Ljava/lang/Object;

    .line 9
    .line 10
    .line 11
    move-result-object p1

    .line 12
    check-cast p1, Landroid/os/IInterface;

    .line 13
    .line 14
    return-object p1
.end method
