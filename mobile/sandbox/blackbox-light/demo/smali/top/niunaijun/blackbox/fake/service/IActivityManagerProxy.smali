.class public Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy;
.super Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$updateConfiguration;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$unregisterUidObserver;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$registerUidObserver;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$setRequestedOrientation;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$SetTaskDescription;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$checkUriPermission;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$checkPermission;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$getCurrentUser;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$getHistoricalProcessExitReasons;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$setServiceForeground;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GrantUriPermission;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$RegisterReceiver;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$RegisterReceiverWithFeature;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$SendIntentSender;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$PeekService;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$PublishService;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$finishReceiver;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$unregisterReceiver;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$BroadcastIntent;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$BroadcastIntentWithFeature;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetIntentSenderWithFeature;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetIntentSenderWithSourceToken;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$getUidForIntentSender;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$getPackageForIntentSender;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetIntentSender;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetServices;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetRunningAppProcesses;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$UnbindService;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$BindIsolatedService;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$bindServiceInstance;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$BindService;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$SetActivityLocusContext;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$StopServiceToken;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$StopService;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$StartService;,
        Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetContentProvider;
    }
.end annotation

.annotation runtime Ltop/niunaijun/blackbox/fake/hook/ScanClass;
    value = {
        Ltop/niunaijun/blackbox/fake/service/ActivityManagerCommonProxy;
    }
.end annotation


# static fields
.field public static final TAG:Ljava/lang/String; = "ActivityManagerStub"


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

.method public static BindServiceCommon(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;I)Ljava/lang/Object;
    .locals 11

    .line 1
    const-string v0, "ActivityManagerStub"

    .line 2
    .line 3
    const/4 v1, 0x2

    .line 4
    :try_start_0
    aget-object v2, p2, v1

    .line 5
    .line 6
    check-cast v2, Landroid/content/Intent;

    .line 7
    .line 8
    const/4 v3, 0x3

    .line 9
    aget-object v3, p2, v3

    .line 10
    .line 11
    check-cast v3, Ljava/lang/String;

    .line 12
    .line 13
    const/4 v4, 0x4

    .line 14
    aget-object v5, p2, v4

    .line 15
    .line 16
    check-cast v5, Landroid/app/IServiceConnection;

    .line 17
    .line 18
    if-eqz v2, :cond_2

    .line 19
    .line 20
    invoke-virtual {v2}, Landroid/content/Intent;->getComponent()Landroid/content/ComponentName;

    .line 21
    .line 22
    .line 23
    move-result-object v6

    .line 24
    invoke-virtual {v2}, Landroid/content/Intent;->getAction()Ljava/lang/String;

    .line 25
    .line 26
    .line 27
    move-result-object v7
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 28
    const-string v8, "IntegrityService"

    .line 29
    .line 30
    if-eqz v6, :cond_0

    .line 31
    .line 32
    :try_start_1
    const-string v9, "com.google.android.finsky.expressintegrityservice.ExpressIntegrityService"

    .line 33
    .line 34
    invoke-virtual {v6}, Landroid/content/ComponentName;->getClassName()Ljava/lang/String;

    .line 35
    .line 36
    .line 37
    move-result-object v10

    .line 38
    invoke-virtual {v9, v10}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 39
    .line 40
    .line 41
    move-result v9

    .line 42
    if-nez v9, :cond_1

    .line 43
    .line 44
    invoke-virtual {v6}, Landroid/content/ComponentName;->getClassName()Ljava/lang/String;

    .line 45
    .line 46
    .line 47
    move-result-object v9

    .line 48
    invoke-virtual {v9, v8}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 49
    .line 50
    .line 51
    move-result v9

    .line 52
    if-nez v9, :cond_1

    .line 53
    .line 54
    invoke-virtual {v6}, Landroid/content/ComponentName;->getClassName()Ljava/lang/String;

    .line 55
    .line 56
    .line 57
    move-result-object v6

    .line 58
    const-string v9, "expressintegrity"

    .line 59
    .line 60
    invoke-virtual {v6, v9}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 61
    .line 62
    .line 63
    move-result v6

    .line 64
    if-nez v6, :cond_1

    .line 65
    .line 66
    goto :goto_0

    .line 67
    :catch_0
    move-exception p3

    .line 68
    goto/16 :goto_3

    .line 69
    .line 70
    :cond_0
    :goto_0
    if-eqz v7, :cond_2

    .line 71
    .line 72
    const-string v6, "expressintegrityservice"

    .line 73
    .line 74
    invoke-virtual {v7, v6}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 75
    .line 76
    .line 77
    move-result v6

    .line 78
    if-nez v6, :cond_1

    .line 79
    .line 80
    invoke-virtual {v7, v8}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 81
    .line 82
    .line 83
    move-result v6

    .line 84
    if-eqz v6, :cond_2

    .line 85
    .line 86
    :cond_1
    goto/16 :goto_1

    .line 87
    .line 88
    const-string v1, "Phase 2: Wrapping integrity service connection for bridge"

    .line 89
    .line 90
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 91
    .line 92
    .line 93
    invoke-static {v5, v2}, Ltop/niunaijun/blackbox/hooks/IntegrityProxy;->createConnectionProxy(Landroid/app/IServiceConnection;Landroid/content/Intent;)Landroid/app/IServiceConnection;

    .line 94
    .line 95
    .line 96
    move-result-object v1

    .line 97
    aput-object v1, p2, v4

    .line 98
    .line 99
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostPkg()Ljava/lang/String;

    .line 100
    .line 101
    .line 102
    move-result-object v1

    .line 103
    aput-object v1, p2, p3

    .line 104
    .line 105
    invoke-static {p0, p1, p2}, Lio/github/leexeo/cage/space/GuestCredentials;->invokeSystemBind(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 106
    .line 107
    .line 108
    move-result-object p0

    .line 109
    return-object p0

    .line 110
    :cond_2
    :goto_1
    if-nez v2, :cond_3

    .line 111
    .line 112
    const-string p3, "BindServiceCommon: Intent is null, proceeding with original call"

    .line 113
    .line 114
    invoke-static {v0, p3}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 115
    .line 116
    .line 117
    invoke-static {p0, p1, p2}, Lio/github/leexeo/cage/space/GuestCredentials;->invokeSystemBind(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 118
    .line 119
    .line 120
    move-result-object p0

    .line 121
    return-object p0

    .line 122
    :cond_3
    const-string v6, "_B_|_UserId"

    .line 123
    .line 124
    const/4 v7, -0x1

    .line 125
    invoke-virtual {v2, v6, v7}, Landroid/content/Intent;->getIntExtra(Ljava/lang/String;I)I

    .line 126
    .line 127
    .line 128
    move-result v6

    .line 129
    if-ne v6, v7, :cond_4

    .line 130
    .line 131
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    .line 132
    .line 133
    .line 134
    move-result v6

    .line 135
    :cond_4
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBPackageManager()Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;

    .line 136
    .line 137
    .line 138
    move-result-object v7

    .line 139
    const/4 v8, 0x0

    .line 140
    invoke-virtual {v7, v2, v8, v3, v6}, Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;->resolveService(Landroid/content/Intent;ILjava/lang/String;I)Landroid/content/pm/ResolveInfo;

    .line 141
    .line 142
    .line 143
    move-result-object v7

    .line 144
    if-nez v7, :cond_5

    .line 145
    .line 146
    invoke-virtual {v2}, Landroid/content/Intent;->getComponent()Landroid/content/ComponentName;

    .line 147
    .line 148
    .line 149
    move-result-object v9

    .line 150
    invoke-static {v9}, Ltop/niunaijun/blackbox/core/env/AppSystemEnv;->isOpenPackage(Landroid/content/ComponentName;)Z

    .line 151
    .line 152
    .line 153
    move-result v9

    .line 154
    if-eqz v9, :cond_a

    .line 155
    .line 156
    :cond_5
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBActivityManager()Ltop/niunaijun/blackbox/fake/frameworks/BActivityManager;

    .line 157
    .line 158
    .line 159
    move-result-object v9

    .line 160
    if-nez v5, :cond_6

    .line 161
    .line 162
    const/4 v10, 0x0

    .line 163
    goto :goto_2

    .line 164
    :cond_6
    invoke-interface {v5}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    .line 165
    .line 166
    .line 167
    move-result-object v10

    .line 168
    :goto_2
    invoke-virtual {v9, v2, v10, v3, v6}, Ltop/niunaijun/blackbox/fake/frameworks/BActivityManager;->bindService(Landroid/content/Intent;Landroid/os/IBinder;Ljava/lang/String;I)Landroid/content/Intent;

    .line 169
    .line 170
    .line 171
    move-result-object v3

    .line 172
    if-eqz v5, :cond_8

    .line 173
    .line 174
    invoke-virtual {v2}, Landroid/content/Intent;->getComponent()Landroid/content/ComponentName;

    .line 175
    .line 176
    .line 177
    move-result-object v6

    .line 178
    if-nez v6, :cond_7

    .line 179
    .line 180
    if-eqz v7, :cond_7

    .line 181
    .line 182
    new-instance v6, Landroid/content/ComponentName;

    .line 183
    .line 184
    iget-object v7, v7, Landroid/content/pm/ResolveInfo;->serviceInfo:Landroid/content/pm/ServiceInfo;

    .line 185
    .line 186
    iget-object v9, v7, Landroid/content/pm/ServiceInfo;->packageName:Ljava/lang/String;

    .line 187
    .line 188
    iget-object v7, v7, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 189
    .line 190
    invoke-direct {v6, v9, v7}, Landroid/content/ComponentName;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    .line 191
    .line 192
    .line 193
    invoke-virtual {v2, v6}, Landroid/content/Intent;->setComponent(Landroid/content/ComponentName;)Landroid/content/Intent;

    .line 194
    .line 195
    .line 196
    :cond_7
    invoke-static {v5, v2}, Ltop/niunaijun/blackbox/fake/delegate/ServiceConnectionDelegate;->createProxy(Landroid/app/IServiceConnection;Landroid/content/Intent;)Landroid/app/IServiceConnection;

    .line 197
    .line 198
    .line 199
    move-result-object v2

    .line 200
    aput-object v2, p2, v4

    .line 201
    .line 202
    const-class v4, Lblack/android/app/LoadedApkServiceDispatcherInnerConnectionContext;

    .line 203
    .line 204
    invoke-static {v4, v5, v8}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 205
    .line 206
    .line 207
    move-result-object v4

    .line 208
    check-cast v4, Lblack/android/app/LoadedApkServiceDispatcherInnerConnectionContext;

    .line 209
    .line 210
    invoke-interface {v4}, Lblack/android/app/LoadedApkServiceDispatcherInnerConnectionContext;->mDispatcher()Ljava/lang/ref/WeakReference;

    .line 211
    .line 212
    .line 213
    move-result-object v4

    .line 214
    if-eqz v4, :cond_8

    .line 215
    .line 216
    invoke-virtual {v4}, Ljava/lang/ref/Reference;->get()Ljava/lang/Object;

    .line 217
    .line 218
    .line 219
    move-result-object v4

    .line 220
    const-class v5, Lblack/android/app/LoadedApkServiceDispatcherContext;

    .line 221
    .line 222
    invoke-static {v5, v4, v8}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 223
    .line 224
    .line 225
    move-result-object v4

    .line 226
    check-cast v4, Lblack/android/app/LoadedApkServiceDispatcherContext;

    .line 227
    .line 228
    invoke-interface {v4, v2}, Lblack/android/app/LoadedApkServiceDispatcherContext;->_set_mConnection(Ljava/lang/Object;)V

    .line 229
    .line 230
    .line 231
    :cond_8
    if-eqz v3, :cond_9

    .line 232
    .line 233
    invoke-virtual {v3}, Landroid/content/Intent;->getComponent()Landroid/content/ComponentName;

    .line 234
    .line 235
    .line 236
    move-result-object v2

    .line 237
    if-eqz v2, :cond_9

    .line 238
    .line 239
    invoke-virtual {v3}, Landroid/content/Intent;->getComponent()Landroid/content/ComponentName;

    .line 240
    .line 241
    .line 242
    move-result-object v2

    .line 243
    invoke-virtual {v2}, Landroid/content/ComponentName;->getPackageName()Ljava/lang/String;

    .line 244
    .line 245
    .line 246
    move-result-object v2

    .line 247
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostPkg()Ljava/lang/String;

    .line 248
    .line 249
    .line 250
    move-result-object v4

    .line 251
    invoke-virtual {v2, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 252
    .line 253
    .line 254
    move-result v2

    .line 255
    if-eqz v2, :cond_9

    .line 256
    .line 257
    invoke-static {p2}, Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy;->getFlagsIndex([Ljava/lang/Object;)I

    .line 258
    .line 259
    .line 260
    move-result v2

    .line 261
    if-ltz v2, :cond_9

    .line 262
    .line 263
    aget-object v4, p2, v2

    .line 264
    .line 265
    invoke-static {v4}, Ltop/niunaijun/blackbox/utils/MethodParameterUtils;->toInt(Ljava/lang/Object;)I

    .line 266
    .line 267
    .line 268
    move-result v4

    .line 269
    const v5, 0x7fffffff

    .line 270
    .line 271
    .line 272
    and-int/2addr v4, v5

    .line 273
    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 274
    .line 275
    .line 276
    move-result-object v4

    .line 277
    aput-object v4, p2, v2

    .line 278
    .line 279
    :cond_9
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostPkg()Ljava/lang/String;

    .line 280
    .line 281
    .line 282
    move-result-object v2

    .line 283
    aput-object v2, p2, p3

    .line 284
    .line 285
    if-eqz v3, :cond_a

    .line 286
    .line 287
    aput-object v3, p2, v1

    .line 288
    .line 289
    invoke-static {p0, p1, p2}, Lio/github/leexeo/cage/space/GuestCredentials;->invokeSystemBind(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 290
    .line 291
    .line 292
    move-result-object p0

    .line 293
    return-object p0

    .line 294
    :cond_a
    invoke-static {p0, p1, p2}, Lio/github/leexeo/cage/space/GuestCredentials;->invokeSystemBind(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 295
    .line 296
    .line 297
    move-result-object p0
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 298
    return-object p0

    .line 299
    :goto_3
    const-string v1, "BindServiceCommon: Unexpected error"

    .line 300
    .line 301
    invoke-static {v0, v1, p3}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 302
    .line 303
    .line 304
    invoke-static {p0, p1, p2}, Lio/github/leexeo/cage/space/GuestCredentials;->invokeSystemBind(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 305
    .line 306
    .line 307
    move-result-object p0

    .line 308
    return-object p0
.end method

.method public static bridge synthetic a(Ljava/lang/String;)Z
    .locals 0

    .line 1
    invoke-static {p0}, Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy;->isAudioPermission(Ljava/lang/String;)Z

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
    invoke-static {p0}, Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy;->isStorageOrMediaPermission(Ljava/lang/String;)Z

    .line 2
    .line 3
    .line 4
    move-result p0

    .line 5
    return p0
.end method

.method private static getFlagsIndex([Ljava/lang/Object;)I
    .locals 3

    .line 1
    const/4 v0, 0x5

    .line 2
    :goto_0
    array-length v1, p0

    .line 3
    if-ge v0, v1, :cond_2

    .line 4
    .line 5
    aget-object v1, p0, v0

    .line 6
    .line 7
    instance-of v2, v1, Ljava/lang/Integer;

    .line 8
    .line 9
    if-nez v2, :cond_1

    .line 10
    .line 11
    instance-of v1, v1, Ljava/lang/Long;

    .line 12
    .line 13
    if-eqz v1, :cond_0

    .line 14
    .line 15
    goto :goto_1

    .line 16
    :cond_0
    add-int/lit8 v0, v0, 0x1

    .line 17
    .line 18
    goto :goto_0

    .line 19
    :cond_1
    :goto_1
    return v0

    .line 20
    :cond_2
    const/4 p0, -0x1

    .line 21
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
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isOreo()Z

    .line 2
    .line 3
    .line 4
    move-result v0

    .line 5
    const/4 v1, 0x0

    .line 6
    const/4 v2, 0x0

    .line 7
    if-eqz v0, :cond_0

    .line 8
    .line 9
    const-class v0, Lblack/android/app/ActivityManagerOreoStatic;

    .line 10
    .line 11
    invoke-static {v0, v2, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 12
    .line 13
    .line 14
    move-result-object v0

    .line 15
    check-cast v0, Lblack/android/app/ActivityManagerOreoStatic;

    .line 16
    .line 17
    invoke-interface {v0}, Lblack/android/app/ActivityManagerOreoStatic;->IActivityManagerSingleton()Ljava/lang/Object;

    .line 18
    .line 19
    .line 20
    move-result-object v2

    .line 21
    goto :goto_0

    .line 22
    :cond_0
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isL()Z

    .line 23
    .line 24
    .line 25
    move-result v0

    .line 26
    if-eqz v0, :cond_1

    .line 27
    .line 28
    invoke-static {}, Le5/a;->a()Lblack/android/app/ActivityManagerNativeStatic;

    .line 29
    .line 30
    .line 31
    move-result-object v0

    .line 32
    invoke-interface {v0}, Lblack/android/app/ActivityManagerNativeStatic;->gDefault()Ljava/lang/Object;

    .line 33
    .line 34
    .line 35
    move-result-object v2

    .line 36
    :cond_1
    :goto_0
    const-class v0, Lblack/android/util/SingletonContext;

    .line 37
    .line 38
    invoke-static {v0, v2, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 39
    .line 40
    .line 41
    move-result-object v0

    .line 42
    check-cast v0, Lblack/android/util/SingletonContext;

    .line 43
    .line 44
    invoke-interface {v0}, Lblack/android/util/SingletonContext;->get()Ljava/lang/Object;

    .line 45
    .line 46
    .line 47
    move-result-object v0

    .line 48
    return-object v0
.end method

.method public inject(Ljava/lang/Object;Ljava/lang/Object;)V
    .locals 2

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isOreo()Z

    .line 2
    .line 3
    .line 4
    move-result p1

    .line 5
    const/4 v0, 0x0

    .line 6
    const/4 v1, 0x0

    .line 7
    if-eqz p1, :cond_0

    .line 8
    .line 9
    const-class p1, Lblack/android/app/ActivityManagerOreoStatic;

    .line 10
    .line 11
    invoke-static {p1, v1, v0}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 12
    .line 13
    .line 14
    move-result-object p1

    .line 15
    check-cast p1, Lblack/android/app/ActivityManagerOreoStatic;

    .line 16
    .line 17
    invoke-interface {p1}, Lblack/android/app/ActivityManagerOreoStatic;->IActivityManagerSingleton()Ljava/lang/Object;

    .line 18
    .line 19
    .line 20
    move-result-object v1

    .line 21
    goto :goto_0

    .line 22
    :cond_0
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isL()Z

    .line 23
    .line 24
    .line 25
    move-result p1

    .line 26
    if-eqz p1, :cond_1

    .line 27
    .line 28
    invoke-static {}, Le5/a;->a()Lblack/android/app/ActivityManagerNativeStatic;

    .line 29
    .line 30
    .line 31
    move-result-object p1

    .line 32
    invoke-interface {p1}, Lblack/android/app/ActivityManagerNativeStatic;->gDefault()Ljava/lang/Object;

    .line 33
    .line 34
    .line 35
    move-result-object v1

    .line 36
    :cond_1
    :goto_0
    const-class p1, Lblack/android/util/SingletonContext;

    .line 37
    .line 38
    invoke-static {p1, v1, v0}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 39
    .line 40
    .line 41
    move-result-object p1

    .line 42
    check-cast p1, Lblack/android/util/SingletonContext;

    .line 43
    .line 44
    invoke-interface {p1, p2}, Lblack/android/util/SingletonContext;->_set_mInstance(Ljava/lang/Object;)V

    .line 45
    .line 46
    .line 47
    return-void
.end method

.method public invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 4

    invoke-virtual {p0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->getBase()Ljava/lang/Object;

    move-result-object v0

    invoke-static {v0, p2, p3}, Lio/github/leexeo/cage/space/GuestNetwork;->selfPermission(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    if-eqz v0, :cond_0

    return-object v0

    .line 1
    :cond_0
    const-string v0, "ActivityManagerStub"

    .line 2
    .line 3
    :try_start_0
    invoke-super {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 4
    .line 5
    .line 6
    move-result-object p1
    :try_end_0
    .catch Ljava/lang/SecurityException; {:try_start_0 .. :try_end_0} :catch_1
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 7
    return-object p1

    .line 8
    :catch_0
    move-exception v1

    .line 9
    new-instance v2, Ljava/lang/StringBuilder;

    .line 10
    .line 11
    const-string v3, "ActivityManager invoke: Unexpected error in "

    .line 12
    .line 13
    invoke-direct {v2, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 14
    .line 15
    .line 16
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    .line 17
    .line 18
    .line 19
    move-result-object v3

    .line 20
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 21
    .line 22
    .line 23
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 24
    .line 25
    .line 26
    move-result-object v2

    .line 27
    invoke-static {v0, v2, v1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 28
    .line 29
    .line 30
    invoke-super {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 31
    .line 32
    .line 33
    move-result-object p1

    .line 34
    return-object p1

    .line 35
    :catch_1
    move-exception p1

    .line 36
    invoke-virtual {p2}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    .line 37
    .line 38
    .line 39
    move-result-object p2

    .line 40
    new-instance p3, Ljava/lang/StringBuilder;

    .line 41
    .line 42
    const-string v1, "ActivityManager invoke: SecurityException in "

    .line 43
    .line 44
    invoke-direct {p3, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 45
    .line 46
    .line 47
    invoke-virtual {p3, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 48
    .line 49
    .line 50
    const-string v1, ", returning safe default"

    .line 51
    .line 52
    invoke-virtual {p3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 53
    .line 54
    .line 55
    invoke-virtual {p3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 56
    .line 57
    .line 58
    move-result-object p3

    .line 59
    invoke-static {v0, p3, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 60
    .line 61
    .line 62
    const-string p1, "set"

    .line 63
    .line 64
    invoke-virtual {p2, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    .line 65
    .line 66
    .line 67
    move-result p1

    .line 68
    const/4 p3, 0x0

    .line 69
    if-nez p1, :cond_7

    .line 70
    .line 71
    const-string p1, "update"

    .line 72
    .line 73
    invoke-virtual {p2, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    .line 74
    .line 75
    .line 76
    move-result p1

    .line 77
    if-eqz p1, :cond_1

    .line 78
    .line 79
    goto :goto_2

    .line 80
    :cond_1
    const-string p1, "get"

    .line 81
    .line 82
    invoke-virtual {p2, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    .line 83
    .line 84
    .line 85
    move-result p1

    .line 86
    if-nez p1, :cond_7

    .line 87
    .line 88
    const-string p1, "query"

    .line 89
    .line 90
    invoke-virtual {p2, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    .line 91
    .line 92
    .line 93
    move-result p1

    .line 94
    if-eqz p1, :cond_2

    .line 95
    .line 96
    goto :goto_2

    .line 97
    :cond_2
    const-string p1, "start"

    .line 98
    .line 99
    invoke-virtual {p2, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    .line 100
    .line 101
    .line 102
    move-result p1

    .line 103
    if-nez p1, :cond_6

    .line 104
    .line 105
    const-string p1, "bind"

    .line 106
    .line 107
    invoke-virtual {p2, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    .line 108
    .line 109
    .line 110
    move-result p1

    .line 111
    if-eqz p1, :cond_3

    .line 112
    .line 113
    goto :goto_1

    .line 114
    :cond_3
    const-string p1, "stop"

    .line 115
    .line 116
    invoke-virtual {p2, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    .line 117
    .line 118
    .line 119
    move-result p1

    .line 120
    if-nez p1, :cond_5

    .line 121
    .line 122
    const-string p1, "unbind"

    .line 123
    .line 124
    invoke-virtual {p2, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    .line 125
    .line 126
    .line 127
    move-result p1

    .line 128
    if-eqz p1, :cond_4

    .line 129
    .line 130
    goto :goto_0

    .line 131
    :cond_4
    return-object p3

    .line 132
    :cond_5
    :goto_0
    sget-object p1, Ljava/lang/Boolean;->TRUE:Ljava/lang/Boolean;

    .line 133
    .line 134
    return-object p1

    .line 135
    :cond_6
    :goto_1
    sget-object p1, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 136
    .line 137
    return-object p1

    .line 138
    :cond_7
    :goto_2
    return-object p3
.end method

.method public isBadEnv()Z
    .locals 2

    .line 1
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->getProxyInvocation()Ljava/lang/Object;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy;->getWho()Ljava/lang/Object;

    .line 6
    .line 7
    .line 8
    move-result-object v1

    .line 9
    if-eq v0, v1, :cond_0

    .line 10
    .line 11
    const/4 v0, 0x1

    .line 12
    return v0

    .line 13
    :cond_0
    const/4 v0, 0x0

    .line 14
    return v0
.end method

.method public onBindMethod()V
    .locals 2

    .line 1
    invoke-super {p0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->onBindMethod()V

    .line 2
    .line 3
    .line 4
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/base/PkgMethodProxy;

    .line 5
    .line 6
    const-string v1, "getAppStartMode"

    .line 7
    .line 8
    invoke-direct {v0, v1}, Ltop/niunaijun/blackbox/fake/service/base/PkgMethodProxy;-><init>(Ljava/lang/String;)V

    .line 9
    .line 10
    .line 11
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 12
    .line 13
    .line 14
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/base/PkgMethodProxy;

    .line 15
    .line 16
    const-string v1, "setAppLockedVerifying"

    .line 17
    .line 18
    invoke-direct {v0, v1}, Ltop/niunaijun/blackbox/fake/service/base/PkgMethodProxy;-><init>(Ljava/lang/String;)V

    .line 19
    .line 20
    .line 21
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 22
    .line 23
    .line 24
    new-instance v0, Ltop/niunaijun/blackbox/fake/service/base/PkgMethodProxy;

    .line 25
    .line 26
    const-string v1, "reportJunkFromApp"

    .line 27
    .line 28
    invoke-direct {v0, v1}, Ltop/niunaijun/blackbox/fake/service/base/PkgMethodProxy;-><init>(Ljava/lang/String;)V

    .line 29
    .line 30
    .line 31
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->addMethodHook(Ltop/niunaijun/blackbox/fake/hook/MethodHook;)V

    .line 32
    .line 33
    .line 34
    return-void
.end method
