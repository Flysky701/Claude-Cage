.class public Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetContentProvider;
.super Ltop/niunaijun/blackbox/fake/hook/MethodHook;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x9
    name = "GetContentProvider"
.end annotation

.annotation runtime Ltop/niunaijun/blackbox/fake/hook/ProxyMethod;
    value = "getContentProvider"
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


# virtual methods
.method public getAuthIndex()I
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isQ()Z

    .line 2
    .line 3
    .line 4
    move-result v0

    .line 5
    if-eqz v0, :cond_0

    .line 6
    .line 7
    const/4 v0, 0x2

    .line 8
    return v0

    .line 9
    :cond_0
    const/4 v0, 0x1

    .line 10
    return v0
.end method

.method public getUserIndex()I
    .locals 1

    .line 1
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetContentProvider;->getAuthIndex()I

    .line 2
    .line 3
    .line 4
    move-result v0

    .line 5
    add-int/lit8 v0, v0, 0x1

    .line 6
    .line 7
    return v0
.end method

.method public hook(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 7

    .line 1
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetContentProvider;->getAuthIndex()I

    .line 2
    .line 3
    .line 4
    move-result v0

    .line 5
    aget-object v1, p3, v0

    .line 6
    .line 7
    instance-of v2, v1, Ljava/lang/String;

    .line 8
    .line 9
    if-eqz v2, :cond_8

    .line 10
    .line 11
    move-object v2, v1

    .line 12
    check-cast v2, Ljava/lang/String;

    .line 13
    .line 14
    invoke-static {v2}, Ltop/niunaijun/blackbox/proxy/ProxyManifest;->isProxy(Ljava/lang/String;)Z

    .line 15
    .line 16
    .line 17
    move-result v3

    .line 18
    if-eqz v3, :cond_0

    .line 19
    .line 20
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 21
    .line 22
    .line 23
    move-result-object p1

    .line 24
    return-object p1

    .line 25
    :cond_0
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isQ()Z

    .line 26
    .line 27
    .line 28
    move-result v3

    .line 29
    if-eqz v3, :cond_1

    .line 30
    .line 31
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostPkg()Ljava/lang/String;

    .line 32
    .line 33
    .line 34
    move-result-object v3

    .line 35
    const/4 v4, 0x1

    .line 36
    aput-object v3, p3, v4

    .line 37
    .line 38
    :cond_1
    const-string v3, "io.github.leexeo.cage.microdemo.status"

    invoke-virtual {v1, v3}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-nez v3, :cond_7

    const-string v3, "settings"

    .line 39
    .line 40
    invoke-virtual {v1, v3}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    .line 41
    .line 42
    .line 43
    move-result v3

    .line 44
    if-nez v3, :cond_7

    .line 45
    .line 46
    const-string v3, "media"

    .line 47
    .line 48
    invoke-virtual {v1, v3}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    .line 49
    .line 50
    .line 51
    move-result v3

    .line 52
    if-nez v3, :cond_7

    .line 53
    .line 54
    const-string v3, "telephony"

    .line 55
    .line 56
    invoke-virtual {v1, v3}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    .line 57
    .line 58
    .line 59
    move-result v3

    .line 60
    if-nez v3, :cond_7

    .line 61
    .line 62
    const-string v3, "com.huawei.android.launcher.settings"

    .line 95
    .line 96
    invoke-virtual {v1, v3}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    .line 97
    .line 98
    .line 99
    move-result v3

    .line 100
    if-nez v3, :cond_7

    .line 101
    .line 102
    const-string v3, "com.hihonor.android.launcher.settings"

    .line 103
    .line 104
    invoke-virtual {v1, v3}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    .line 105
    .line 106
    .line 107
    move-result v1

    .line 108
    if-eqz v1, :cond_2

    .line 109
    .line 110
    goto/16 :goto_2

    .line 111
    .line 112
    :cond_2
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBPackageManager()Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;

    .line 113
    .line 114
    .line 115
    move-result-object v1

    .line 116
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    .line 117
    .line 118
    .line 119
    move-result v3

    .line 120
    const/16 v4, 0x80

    .line 121
    .line 122
    invoke-virtual {v1, v2, v4, v3}, Ltop/niunaijun/blackbox/fake/frameworks/BPackageManager;->resolveContentProvider(Ljava/lang/String;II)Landroid/content/pm/ProviderInfo;

    .line 123
    .line 124
    .line 125
    move-result-object v1

    .line 126
    const/4 v2, 0x0

    .line 127
    if-nez v1, :cond_3

    .line 128
    .line 129
    return-object v2

    .line 130
    :cond_3
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppPid()I

    .line 131
    .line 132
    .line 133
    move-result v3

    .line 134
    const/4 v4, -0x1

    .line 135
    if-eq v3, v4, :cond_5

    .line 136
    .line 137
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBActivityManager()Ltop/niunaijun/blackbox/fake/frameworks/BActivityManager;

    .line 138
    .line 139
    .line 140
    move-result-object v3

    .line 141
    iget-object v4, v1, Landroid/content/pm/ProviderInfo;->packageName:Ljava/lang/String;

    .line 142
    .line 143
    iget-object v5, v1, Landroid/content/pm/ProviderInfo;->processName:Ljava/lang/String;

    .line 144
    .line 145
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getUserId()I

    .line 146
    .line 147
    .line 148
    move-result v6

    .line 149
    invoke-virtual {v3, v4, v5, v6}, Ltop/niunaijun/blackbox/fake/frameworks/BActivityManager;->initProcess(Ljava/lang/String;Ljava/lang/String;I)Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 150
    .line 151
    .line 152
    move-result-object v3

    .line 153
    iget v4, v3, Ltop/niunaijun/blackbox/entity/AppConfig;->bpid:I

    .line 154
    .line 155
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppPid()I

    .line 156
    .line 157
    .line 158
    move-result v5

    .line 159
    if-eq v4, v5, :cond_4

    .line 160
    .line 161
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBActivityManager()Ltop/niunaijun/blackbox/fake/frameworks/BActivityManager;

    .line 162
    .line 163
    .line 164
    move-result-object v4

    .line 165
    invoke-virtual {v4, v1}, Ltop/niunaijun/blackbox/fake/frameworks/BActivityManager;->acquireContentProviderClient(Landroid/content/pm/ProviderInfo;)Landroid/os/IBinder;

    .line 166
    .line 167
    .line 168
    move-result-object v4

    .line 169
    goto :goto_0

    .line 170
    :cond_4
    move-object v4, v2

    .line 171
    :goto_0
    iget v3, v3, Ltop/niunaijun/blackbox/entity/AppConfig;->bpid:I

    .line 172
    .line 173
    invoke-static {v3}, Ltop/niunaijun/blackbox/proxy/ProxyManifest;->getProxyAuthorities(I)Ljava/lang/String;

    .line 174
    .line 175
    .line 176
    move-result-object v3

    .line 177
    aput-object v3, p3, v0

    .line 178
    .line 179
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/fake/service/IActivityManagerProxy$GetContentProvider;->getUserIndex()I

    .line 180
    .line 181
    .line 182
    move-result v0

    .line 183
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostUserId()I

    .line 184
    .line 185
    .line 186
    move-result v3

    .line 187
    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 188
    .line 189
    .line 190
    move-result-object v3

    .line 191
    aput-object v3, p3, v0

    .line 192
    .line 193
    goto :goto_1

    .line 194
    :cond_5
    move-object v4, v2

    .line 195
    :goto_1
    if-nez v4, :cond_6

    .line 196
    .line 197
    return-object v2

    .line 198
    :cond_6
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 199
    .line 200
    .line 201
    move-result-object p1

    .line 202
    invoke-static {p1}, Ltop/niunaijun/blackbox/utils/Reflector;->with(Ljava/lang/Object;)Ltop/niunaijun/blackbox/utils/Reflector;

    .line 203
    .line 204
    .line 205
    move-result-object p2

    .line 206
    const-string p3, "info"

    .line 207
    .line 208
    invoke-virtual {p2, p3}, Ltop/niunaijun/blackbox/utils/Reflector;->field(Ljava/lang/String;)Ltop/niunaijun/blackbox/utils/Reflector;

    .line 209
    .line 210
    .line 211
    move-result-object p2

    .line 212
    invoke-virtual {p2, v1}, Ltop/niunaijun/blackbox/utils/Reflector;->set(Ljava/lang/Object;)Ltop/niunaijun/blackbox/utils/Reflector;

    .line 213
    .line 214
    .line 215
    invoke-static {p1}, Ltop/niunaijun/blackbox/utils/Reflector;->with(Ljava/lang/Object;)Ltop/niunaijun/blackbox/utils/Reflector;

    .line 216
    .line 217
    .line 218
    move-result-object p2

    .line 219
    const-string p3, "provider"

    .line 220
    .line 221
    invoke-virtual {p2, p3}, Ltop/niunaijun/blackbox/utils/Reflector;->field(Ljava/lang/String;)Ltop/niunaijun/blackbox/utils/Reflector;

    .line 222
    .line 223
    .line 224
    move-result-object p2

    .line 225
    new-instance p3, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;

    .line 226
    .line 227
    invoke-direct {p3}, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;-><init>()V

    .line 228
    .line 229
    .line 230
    const-class v0, Lblack/android/content/ContentProviderNativeStatic;

    .line 231
    .line 232
    const/4 v3, 0x0

    .line 233
    invoke-static {v0, v2, v3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 234
    .line 235
    .line 236
    move-result-object v0

    .line 237
    check-cast v0, Lblack/android/content/ContentProviderNativeStatic;

    .line 238
    .line 239
    invoke-interface {v0, v4}, Lblack/android/content/ContentProviderNativeStatic;->asInterface(Landroid/os/IBinder;)Landroid/os/IInterface;

    .line 240
    .line 241
    .line 242
    move-result-object v0

    .line 243
    iget-object v1, v1, Landroid/content/pm/ProviderInfo;->packageName:Ljava/lang/String;

    .line 244
    .line 245
    invoke-virtual {p3, v0, v1}, Ltop/niunaijun/blackbox/fake/service/context/providers/ContentProviderStub;->wrapper(Landroid/os/IInterface;Ljava/lang/String;)Landroid/os/IInterface;

    .line 246
    .line 247
    .line 248
    move-result-object p3

    .line 249
    invoke-virtual {p2, p3}, Ltop/niunaijun/blackbox/utils/Reflector;->set(Ljava/lang/Object;)Ltop/niunaijun/blackbox/utils/Reflector;

    .line 250
    .line 251
    .line 252
    return-object p1

    .line 253
    :cond_7
    :goto_2
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 254
    .line 255
    .line 256
    move-result-object p1

    .line 257
    invoke-static {p1, v2}, Ltop/niunaijun/blackbox/fake/delegate/ContentProviderDelegate;->update(Ljava/lang/Object;Ljava/lang/String;)V

    .line 258
    .line 259
    .line 260
    return-object p1

    .line 261
    :cond_8
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 262
    .line 263
    .line 264
    move-result-object p1

    .line 265
    return-object p1
.end method
