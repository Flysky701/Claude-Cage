.class public Ltop/niunaijun/blackbox/core/NativeCore;
.super Ljava/lang/Object;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# static fields
.field public static final TAG:Ljava/lang/String; = "NativeCore"

.field private static volatile sCachedRealUid:I = -0x1

.field private static volatile sCachedRealUidPkg:Ljava/lang/String;

.field private static final sReentrantGuard:Ljava/lang/ThreadLocal;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/lang/ThreadLocal<",
            "Ljava/lang/Boolean;",
            ">;"
        }
    .end annotation
.end field


# direct methods
.method static constructor <clinit>()V
    .locals 1

    .line 1
    new-instance v0, Ljava/lang/ThreadLocal;

    .line 2
    .line 3
    invoke-direct {v0}, Ljava/lang/ThreadLocal;-><init>()V

    .line 4
    .line 5
    .line 6
    sput-object v0, Ltop/niunaijun/blackbox/core/NativeCore;->sReentrantGuard:Ljava/lang/ThreadLocal;

    .line 7
    .line 8
    const-string v0, "blackbox"

    .line 9
    .line 10
    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    .line 11
    .line 12
    .line 13
    return-void
.end method

.method public constructor <init>()V
    .locals 0

    .line 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method public static native addIORule(Ljava/lang/String;Ljava/lang/String;)V
.end method

.method public static cacheRealUid(Ljava/lang/String;)V
    .locals 11

    .line 1
    const-string v0, ": "

    .line 2
    .line 3
    const-string v1, "="

    .line 4
    .line 5
    const-string v2, "NativeCore"

    .line 6
    .line 7
    const-string v3, "cacheRealUid: PM uid="

    .line 8
    .line 9
    const-string v4, "cacheRealUid: "

    .line 10
    .line 11
    const-string v5, "grep \'^"

    .line 12
    .line 13
    const/16 v6, 0x4e1f

    .line 14
    .line 15
    const/16 v7, 0x2710

    .line 16
    .line 17
    :try_start_0
    invoke-static {}, Ljava/lang/Runtime;->getRuntime()Ljava/lang/Runtime;

    .line 18
    .line 19
    .line 20
    move-result-object v8

    .line 21
    new-instance v9, Ljava/lang/StringBuilder;

    .line 22
    .line 23
    invoke-direct {v9, v5}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 24
    .line 25
    .line 26
    invoke-virtual {v9, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 27
    .line 28
    .line 29
    const-string v5, " \' /data/system/packages.list"

    .line 30
    .line 31
    invoke-virtual {v9, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 32
    .line 33
    .line 34
    invoke-virtual {v9}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 35
    .line 36
    .line 37
    move-result-object v5

    .line 38
    const-string v9, "su"

    .line 39
    .line 40
    const-string v10, "-c"

    .line 41
    .line 42
    filled-new-array {v9, v10, v5}, [Ljava/lang/String;

    .line 43
    .line 44
    .line 45
    move-result-object v5

    .line 46
    invoke-virtual {v8, v5}, Ljava/lang/Runtime;->exec([Ljava/lang/String;)Ljava/lang/Process;

    .line 47
    .line 48
    .line 49
    move-result-object v5

    .line 50
    new-instance v8, Ljava/io/BufferedReader;

    .line 51
    .line 52
    new-instance v9, Ljava/io/InputStreamReader;

    .line 53
    .line 54
    invoke-virtual {v5}, Ljava/lang/Process;->getInputStream()Ljava/io/InputStream;

    .line 55
    .line 56
    .line 57
    move-result-object v10

    .line 58
    invoke-direct {v9, v10}, Ljava/io/InputStreamReader;-><init>(Ljava/io/InputStream;)V

    .line 59
    .line 60
    .line 61
    invoke-direct {v8, v9}, Ljava/io/BufferedReader;-><init>(Ljava/io/Reader;)V

    .line 62
    .line 63
    .line 64
    invoke-virtual {v8}, Ljava/io/BufferedReader;->readLine()Ljava/lang/String;

    .line 65
    .line 66
    .line 67
    move-result-object v9

    .line 68
    invoke-virtual {v8}, Ljava/io/BufferedReader;->close()V

    .line 69
    .line 70
    .line 71
    invoke-virtual {v5}, Ljava/lang/Process;->waitFor()I

    .line 72
    .line 73
    .line 74
    if-eqz v9, :cond_0

    .line 75
    .line 76
    invoke-virtual {v9}, Ljava/lang/String;->isEmpty()Z

    .line 77
    .line 78
    .line 79
    move-result v5

    .line 80
    if-nez v5, :cond_0

    .line 81
    .line 82
    invoke-virtual {v9}, Ljava/lang/String;->trim()Ljava/lang/String;

    .line 83
    .line 84
    .line 85
    move-result-object v5

    .line 86
    const-string v8, "\\s+"

    .line 87
    .line 88
    invoke-virtual {v5, v8}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    .line 89
    .line 90
    .line 91
    move-result-object v5

    .line 92
    array-length v8, v5

    .line 93
    const/4 v9, 0x2

    .line 94
    if-lt v8, v9, :cond_0

    .line 95
    .line 96
    const/4 v8, 0x1

    .line 97
    aget-object v5, v5, v8

    .line 98
    .line 99
    invoke-static {v5}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    .line 100
    .line 101
    .line 102
    move-result v5

    .line 103
    if-lt v5, v7, :cond_0

    .line 104
    .line 105
    if-gt v5, v6, :cond_0

    .line 106
    .line 107
    sput v5, Ltop/niunaijun/blackbox/core/NativeCore;->sCachedRealUid:I

    .line 108
    .line 109
    sput-object p0, Ltop/niunaijun/blackbox/core/NativeCore;->sCachedRealUidPkg:Ljava/lang/String;

    .line 110
    .line 111
    new-instance v8, Ljava/lang/StringBuilder;

    .line 112
    .line 113
    invoke-direct {v8, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 114
    .line 115
    .line 116
    invoke-virtual {v8, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 117
    .line 118
    .line 119
    invoke-virtual {v8, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 120
    .line 121
    .line 122
    invoke-virtual {v8, v5}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 123
    .line 124
    .line 125
    const-string v5, " (su)"

    .line 126
    .line 127
    invoke-virtual {v8, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 128
    .line 129
    .line 130
    invoke-virtual {v8}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 131
    .line 132
    .line 133
    move-result-object v5

    .line 134
    invoke-static {v2, v5}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 135
    .line 136
    .line 137
    return-void

    .line 138
    :catch_0
    move-exception v5

    .line 139
    const-string v8, "cacheRealUid su failed for "

    .line 140
    .line 141
    invoke-static {v8, p0, v0}, Ltop/niunaijun/blackbox/a;->a(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 142
    .line 143
    .line 144
    move-result-object v8

    .line 145
    invoke-virtual {v5}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 146
    .line 147
    .line 148
    move-result-object v5

    .line 149
    invoke-virtual {v8, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 150
    .line 151
    .line 152
    invoke-virtual {v8}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 153
    .line 154
    .line 155
    move-result-object v5

    .line 156
    invoke-static {v2, v5}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 157
    .line 158
    .line 159
    :cond_0
    :try_start_1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getPackageManager()Landroid/content/pm/PackageManager;

    .line 160
    .line 161
    .line 162
    move-result-object v5

    .line 163
    const/4 v8, 0x0

    .line 164
    invoke-virtual {v5, p0, v8}, Landroid/content/pm/PackageManager;->getApplicationInfo(Ljava/lang/String;I)Landroid/content/pm/ApplicationInfo;

    .line 165
    .line 166
    .line 167
    move-result-object v5

    .line 168
    iget v5, v5, Landroid/content/pm/ApplicationInfo;->uid:I

    .line 169
    .line 170
    if-lt v5, v7, :cond_1

    .line 171
    .line 172
    if-gt v5, v6, :cond_1

    .line 173
    .line 174
    sput v5, Ltop/niunaijun/blackbox/core/NativeCore;->sCachedRealUid:I

    .line 175
    .line 176
    sput-object p0, Ltop/niunaijun/blackbox/core/NativeCore;->sCachedRealUidPkg:Ljava/lang/String;

    .line 177
    .line 178
    new-instance v3, Ljava/lang/StringBuilder;

    .line 179
    .line 180
    invoke-direct {v3, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 181
    .line 182
    .line 183
    invoke-virtual {v3, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 184
    .line 185
    .line 186
    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 187
    .line 188
    .line 189
    invoke-virtual {v3, v5}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 190
    .line 191
    .line 192
    const-string v1, " (PM)"

    .line 193
    .line 194
    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 195
    .line 196
    .line 197
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 198
    .line 199
    .line 200
    move-result-object v1

    .line 201
    invoke-static {v2, v1}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 202
    .line 203
    .line 204
    goto :goto_1

    .line 205
    :catch_1
    move-exception v1

    .line 206
    goto :goto_0

    .line 207
    :cond_1
    new-instance v1, Ljava/lang/StringBuilder;

    .line 208
    .line 209
    invoke-direct {v1, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 210
    .line 211
    .line 212
    invoke-virtual {v1, v5}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 213
    .line 214
    .line 215
    const-string v3, " out of range for "

    .line 216
    .line 217
    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 218
    .line 219
    .line 220
    invoke-virtual {v1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 221
    .line 222
    .line 223
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 224
    .line 225
    .line 226
    move-result-object v1

    .line 227
    invoke-static {v2, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

    .line 228
    .line 229
    .line 230
    goto :goto_1

    .line 231
    :goto_0
    const-string v3, "cacheRealUid PM failed for "

    .line 232
    .line 233
    invoke-static {v3, p0, v0}, Ltop/niunaijun/blackbox/a;->a(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 234
    .line 235
    .line 236
    move-result-object p0

    .line 237
    invoke-virtual {v1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 238
    .line 239
    .line 240
    move-result-object v0

    .line 241
    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 242
    .line 243
    .line 244
    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 245
    .line 246
    .line 247
    move-result-object p0

    .line 248
    invoke-static {v2, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 249
    .line 250
    .line 251
    :goto_1
    return-void
.end method

.method private static createFallbackEmptyDex()[J
    .locals 7

    .line 1
    const-string v0, "NativeCore"

    .line 2
    .line 3
    const/4 v1, 0x0

    .line 4
    :try_start_0
    const-string v2, "Creating fallback empty DEX"

    .line 5
    .line 6
    invoke-static {v0, v2}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 7
    .line 8
    .line 9
    invoke-static {}, Ltop/niunaijun/blackbox/core/NativeCore;->createMinimalDexBytes()[B

    .line 10
    .line 11
    .line 12
    move-result-object v2

    .line 13
    const-string v3, "fallback_empty"

    .line 14
    .line 15
    const-string v4, ".dex"

    .line 16
    .line 17
    invoke-static {v3, v4}, Ljava/io/File;->createTempFile(Ljava/lang/String;Ljava/lang/String;)Ljava/io/File;

    .line 18
    .line 19
    .line 20
    move-result-object v3

    .line 21
    invoke-virtual {v3}, Ljava/io/File;->deleteOnExit()V

    .line 22
    .line 23
    .line 24
    new-instance v4, Ljava/io/FileOutputStream;

    .line 25
    .line 26
    invoke-direct {v4, v3}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V

    .line 27
    .line 28
    .line 29
    invoke-virtual {v4, v2}, Ljava/io/FileOutputStream;->write([B)V

    .line 30
    .line 31
    .line 32
    invoke-virtual {v4}, Ljava/io/FileOutputStream;->close()V

    .line 33
    .line 34
    .line 35
    new-instance v2, Ldalvik/system/DexFile;

    .line 36
    .line 37
    invoke-direct {v2, v3}, Ldalvik/system/DexFile;-><init>(Ljava/io/File;)V

    .line 38
    .line 39
    .line 40
    invoke-static {v2}, Ltop/niunaijun/blackbox/utils/compat/DexFileCompat;->getCookies(Ldalvik/system/DexFile;)Ljava/util/List;

    .line 41
    .line 42
    .line 43
    move-result-object v2

    .line 44
    if-eqz v2, :cond_1

    .line 45
    .line 46
    invoke-interface {v2}, Ljava/util/List;->isEmpty()Z

    .line 47
    .line 48
    .line 49
    move-result v3

    .line 50
    if-nez v3, :cond_1

    .line 51
    .line 52
    invoke-interface {v2}, Ljava/util/List;->size()I

    .line 53
    .line 54
    .line 55
    move-result v3

    .line 56
    new-array v3, v3, [J

    .line 57
    .line 58
    move v4, v1

    .line 59
    :goto_0
    invoke-interface {v2}, Ljava/util/List;->size()I

    .line 60
    .line 61
    .line 62
    move-result v5

    .line 63
    if-ge v4, v5, :cond_0

    .line 64
    .line 65
    invoke-interface {v2, v4}, Ljava/util/List;->get(I)Ljava/lang/Object;

    .line 66
    .line 67
    .line 68
    move-result-object v5

    .line 69
    check-cast v5, Ljava/lang/Long;

    .line 70
    .line 71
    invoke-virtual {v5}, Ljava/lang/Long;->longValue()J

    .line 72
    .line 73
    .line 74
    move-result-wide v5

    .line 75
    aput-wide v5, v3, v4

    .line 76
    .line 77
    add-int/lit8 v4, v4, 0x1

    .line 78
    .line 79
    goto :goto_0

    .line 80
    :catch_0
    move-exception v2

    .line 81
    goto :goto_1

    .line 82
    :cond_0
    new-instance v4, Ljava/lang/StringBuilder;

    .line 83
    .line 84
    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    .line 85
    .line 86
    .line 87
    const-string v5, "Successfully created fallback empty DEX with "

    .line 88
    .line 89
    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 90
    .line 91
    .line 92
    invoke-interface {v2}, Ljava/util/List;->size()I

    .line 93
    .line 94
    .line 95
    move-result v2

    .line 96
    invoke-virtual {v4, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 97
    .line 98
    .line 99
    const-string v2, " cookies"

    .line 100
    .line 101
    invoke-virtual {v4, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 102
    .line 103
    .line 104
    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 105
    .line 106
    .line 107
    move-result-object v2

    .line 108
    invoke-static {v0, v2}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 109
    .line 110
    .line 111
    return-object v3

    .line 112
    :goto_1
    const-string v3, "Error creating fallback empty DEX: "

    .line 113
    .line 114
    invoke-static {v3, v2, v0}, Landroidx/fragment/app/x0;->k(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 115
    .line 116
    .line 117
    :cond_1
    const-string v2, "Returning empty DEX array as last resort"

    .line 118
    .line 119
    invoke-static {v0, v2}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 120
    .line 121
    .line 122
    new-array v0, v1, [J

    .line 123
    .line 124
    return-object v0
.end method

.method private static createMinimalDexBytes()[B
    .locals 1

    .line 1
    const/16 v0, 0x70

    .line 2
    .line 3
    new-array v0, v0, [B

    .line 4
    .line 5
    fill-array-data v0, :array_0

    .line 6
    .line 7
    .line 8
    return-object v0

    .line 9
    :array_0
    .array-data 1
        0x64t
        0x65t
        0x78t
        0xat
        0x30t
        0x33t
        0x35t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x70t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
        0x0t
    .end array-data
.end method

.method public static native disableHiddenApi()Z
.end method

.method public static native disableResourceLoading()Z
.end method

.method public static native enableIO()V
.end method

.method public static native getArtMethodPtr(Ljava/lang/reflect/Method;)J
.end method

.method public static getCallingUid(I)I
    .locals 7
    .annotation build Ld/a;
    .end annotation

    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestCallingUid;->incoming(I)Ljava/lang/Integer;

    move-result-object v0

    if-eqz v0, :cond_0

    invoke-virtual {v0}, Ljava/lang/Integer;->intValue()I

    move-result v0

    return v0

    .line 1
    :cond_0
    const-string v0, "NativeCore"

    .line 2
    .line 3
    const-string v1, "Error in getCallingUid: "

    .line 4
    .line 5
    const-string v2, "getCallingUid: cached uid="

    .line 6
    .line 7
    sget-object v3, Ljava/lang/Boolean;->TRUE:Ljava/lang/Boolean;

    .line 8
    .line 9
    sget-object v4, Ltop/niunaijun/blackbox/core/NativeCore;->sReentrantGuard:Ljava/lang/ThreadLocal;

    .line 10
    .line 11
    invoke-virtual {v4}, Ljava/lang/ThreadLocal;->get()Ljava/lang/Object;

    .line 12
    .line 13
    .line 14
    move-result-object v5

    .line 15
    invoke-virtual {v3, v5}, Ljava/lang/Boolean;->equals(Ljava/lang/Object;)Z

    .line 16
    .line 17
    .line 18
    move-result v5

    .line 19
    if-eqz v5, :cond_1

    .line 20
    .line 21
    return p0

    .line 22
    :cond_1
    invoke-virtual {v4, v3}, Ljava/lang/ThreadLocal;->set(Ljava/lang/Object;)V

    .line 23
    .line 24
    .line 25
    if-lez p0, :cond_2

    .line 26
    .line 27
    const/16 v3, 0x2710

    .line 28
    .line 29
    if-ge p0, v3, :cond_2

    .line 30
    .line 31
    sget-object v0, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 32
    .line 33
    invoke-virtual {v4, v0}, Ljava/lang/ThreadLocal;->set(Ljava/lang/Object;)V

    .line 34
    .line 35
    .line 36
    return p0

    .line 37
    :cond_2
    const/16 v3, 0x4e1f

    .line 38
    .line 39
    if-le p0, v3, :cond_3

    .line 40
    .line 41
    sget-object v0, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 42
    .line 43
    invoke-virtual {v4, v0}, Ljava/lang/ThreadLocal;->set(Ljava/lang/Object;)V

    .line 44
    .line 45
    .line 46
    return p0

    .line 47
    :cond_3
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostUid()I

    .line 48
    .line 49
    .line 50
    move-result v5

    .line 51
    if-ne p0, v5, :cond_8

    .line 52
    .line 53
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getAppPackageName()Ljava/lang/String;

    .line 54
    .line 55
    .line 56
    move-result-object v5

    .line 57
    if-eqz v5, :cond_7

    .line 58
    .line 59
    const-string v6, "com.google.android.gms"

    .line 60
    .line 61
    invoke-virtual {v5, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 62
    .line 63
    .line 64
    move-result v6

    .line 65
    if-nez v6, :cond_6

    .line 66
    .line 67
    const-string v6, "com.google.android.webview"

    .line 68
    .line 69
    invoke-virtual {v5, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 70
    .line 71
    .line 72
    move-result v6

    .line 73
    if-eqz v6, :cond_4

    .line 74
    .line 75
    goto :goto_0

    .line 76
    :cond_4
    sget v6, Ltop/niunaijun/blackbox/core/NativeCore;->sCachedRealUid:I

    .line 77
    .line 78
    if-lez v6, :cond_5

    .line 79
    .line 80
    sget-object v6, Ltop/niunaijun/blackbox/core/NativeCore;->sCachedRealUidPkg:Ljava/lang/String;

    .line 81
    .line 82
    if-eqz v6, :cond_5

    .line 83
    .line 84
    sget-object v6, Ltop/niunaijun/blackbox/core/NativeCore;->sCachedRealUidPkg:Ljava/lang/String;

    .line 85
    .line 86
    invoke-virtual {v6, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 87
    .line 88
    .line 89
    move-result v6

    .line 90
    if-eqz v6, :cond_5

    .line 91
    .line 92
    new-instance v3, Ljava/lang/StringBuilder;

    .line 93
    .line 94
    invoke-direct {v3, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 95
    .line 96
    .line 97
    sget v2, Ltop/niunaijun/blackbox/core/NativeCore;->sCachedRealUid:I

    .line 98
    .line 99
    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 100
    .line 101
    .line 102
    const-string v2, " spoofing "

    .line 103
    .line 104
    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 105
    .line 106
    .line 107
    invoke-virtual {v3, p0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 108
    .line 109
    .line 110
    const-string p0, " for "

    .line 111
    .line 112
    invoke-virtual {v3, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 113
    .line 114
    .line 115
    invoke-virtual {v3, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 116
    .line 117
    .line 118
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 119
    .line 120
    .line 121
    move-result-object p0

    .line 122
    invoke-static {v0, p0}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 123
    .line 124
    .line 125
    sget p0, Ltop/niunaijun/blackbox/core/NativeCore;->sCachedRealUid:I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 126
    .line 127
    sget-object v0, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 128
    .line 129
    invoke-virtual {v4, v0}, Ljava/lang/ThreadLocal;->set(Ljava/lang/Object;)V

    .line 130
    .line 131
    .line 132
    return p0

    .line 133
    :catch_0
    move-exception p0

    .line 134
    goto :goto_1

    .line 135
    :cond_5
    :try_start_1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getCallingBUid()I

    .line 136
    .line 137
    .line 138
    move-result p0
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 139
    if-lez p0, :cond_7

    .line 140
    .line 141
    if-ge p0, v3, :cond_7

    .line 142
    .line 143
    sget-object v0, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 144
    .line 145
    invoke-virtual {v4, v0}, Ljava/lang/ThreadLocal;->set(Ljava/lang/Object;)V

    .line 146
    .line 147
    .line 148
    return p0

    .line 149
    :cond_6
    :goto_0
    :try_start_2
    invoke-static {}, Landroid/os/Process;->myUid()I

    .line 150
    .line 151
    .line 152
    move-result p0
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_0
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    .line 153
    sget-object v0, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 154
    .line 155
    invoke-virtual {v4, v0}, Ljava/lang/ThreadLocal;->set(Ljava/lang/Object;)V

    .line 156
    .line 157
    .line 158
    return p0

    .line 159
    :catch_1
    :cond_7
    :try_start_3
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostUid()I

    .line 160
    .line 161
    .line 162
    move-result p0
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_0
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 163
    sget-object v0, Ltop/niunaijun/blackbox/core/NativeCore;->sReentrantGuard:Ljava/lang/ThreadLocal;

    .line 164
    .line 165
    sget-object v1, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 166
    .line 167
    invoke-virtual {v0, v1}, Ljava/lang/ThreadLocal;->set(Ljava/lang/Object;)V

    .line 168
    .line 169
    .line 170
    return p0

    .line 171
    :cond_8
    sget-object v0, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 172
    .line 173
    invoke-virtual {v4, v0}, Ljava/lang/ThreadLocal;->set(Ljava/lang/Object;)V

    .line 174
    .line 175
    .line 176
    return p0

    .line 177
    :goto_1
    :try_start_4
    new-instance v2, Ljava/lang/StringBuilder;

    .line 178
    .line 179
    invoke-direct {v2, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 180
    .line 181
    .line 182
    invoke-virtual {p0}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 183
    .line 184
    .line 185
    move-result-object p0

    .line 186
    invoke-virtual {v2, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 187
    .line 188
    .line 189
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 190
    .line 191
    .line 192
    move-result-object p0

    .line 193
    invoke-static {v0, p0}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 194
    .line 195
    .line 196
    invoke-static {}, Landroid/os/Process;->myUid()I

    .line 197
    .line 198
    .line 199
    move-result p0
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_0

    .line 200
    sget-object v0, Ltop/niunaijun/blackbox/core/NativeCore;->sReentrantGuard:Ljava/lang/ThreadLocal;

    .line 201
    .line 202
    sget-object v1, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 203
    .line 204
    invoke-virtual {v0, v1}, Ljava/lang/ThreadLocal;->set(Ljava/lang/Object;)V

    .line 205
    .line 206
    .line 207
    return p0

    .line 208
    :catchall_0
    move-exception p0

    .line 209
    sget-object v0, Ltop/niunaijun/blackbox/core/NativeCore;->sReentrantGuard:Ljava/lang/ThreadLocal;

    .line 210
    .line 211
    sget-object v1, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 212
    .line 213
    invoke-virtual {v0, v1}, Ljava/lang/ThreadLocal;->set(Ljava/lang/Object;)V

    .line 214
    .line 215
    .line 216
    throw p0
.end method

.method public static native hideXposed()V
.end method

.method public static native init(I)V
.end method

.method public static loadEmptyDex()[J
    .locals 7
    .annotation build Ld/a;
    .end annotation

    .line 1
    const-string v0, "NativeCore"

    .line 2
    .line 3
    const/4 v1, 0x0

    .line 4
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/core/system/JarManager;->getInstance()Ltop/niunaijun/blackbox/core/system/JarManager;

    .line 5
    .line 6
    .line 7
    move-result-object v2

    .line 8
    invoke-virtual {v2}, Ltop/niunaijun/blackbox/core/system/JarManager;->getEmptyJar()Ljava/io/File;

    .line 9
    .line 10
    .line 11
    move-result-object v2

    .line 12
    if-nez v2, :cond_0

    .line 13
    .line 14
    const-string v2, "Empty JAR not available, attempting sync initialization"

    .line 15
    .line 16
    invoke-static {v0, v2}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 17
    .line 18
    .line 19
    invoke-static {}, Ltop/niunaijun/blackbox/core/system/JarManager;->getInstance()Ltop/niunaijun/blackbox/core/system/JarManager;

    .line 20
    .line 21
    .line 22
    move-result-object v2

    .line 23
    invoke-virtual {v2}, Ltop/niunaijun/blackbox/core/system/JarManager;->initializeSync()V

    .line 24
    .line 25
    .line 26
    invoke-static {}, Ltop/niunaijun/blackbox/core/system/JarManager;->getInstance()Ltop/niunaijun/blackbox/core/system/JarManager;

    .line 27
    .line 28
    .line 29
    move-result-object v2

    .line 30
    invoke-virtual {v2}, Ltop/niunaijun/blackbox/core/system/JarManager;->getEmptyJar()Ljava/io/File;

    .line 31
    .line 32
    .line 33
    move-result-object v2

    .line 34
    goto :goto_0

    .line 35
    :catch_0
    move-exception v2

    .line 36
    goto :goto_3

    .line 37
    :cond_0
    :goto_0
    if-eqz v2, :cond_3

    .line 38
    .line 39
    invoke-virtual {v2}, Ljava/io/File;->exists()Z

    .line 40
    .line 41
    .line 42
    move-result v3

    .line 43
    if-nez v3, :cond_1

    .line 44
    .line 45
    goto :goto_2

    .line 46
    :cond_1
    new-instance v3, Ldalvik/system/DexFile;

    .line 47
    .line 48
    invoke-direct {v3, v2}, Ldalvik/system/DexFile;-><init>(Ljava/io/File;)V

    .line 49
    .line 50
    .line 51
    invoke-static {v3}, Ltop/niunaijun/blackbox/utils/compat/DexFileCompat;->getCookies(Ldalvik/system/DexFile;)Ljava/util/List;

    .line 52
    .line 53
    .line 54
    move-result-object v2

    .line 55
    invoke-interface {v2}, Ljava/util/List;->size()I

    .line 56
    .line 57
    .line 58
    move-result v3

    .line 59
    new-array v3, v3, [J

    .line 60
    .line 61
    move v4, v1

    .line 62
    :goto_1
    invoke-interface {v2}, Ljava/util/List;->size()I

    .line 63
    .line 64
    .line 65
    move-result v5

    .line 66
    if-ge v4, v5, :cond_2

    .line 67
    .line 68
    invoke-interface {v2, v4}, Ljava/util/List;->get(I)Ljava/lang/Object;

    .line 69
    .line 70
    .line 71
    move-result-object v5

    .line 72
    check-cast v5, Ljava/lang/Long;

    .line 73
    .line 74
    invoke-virtual {v5}, Ljava/lang/Long;->longValue()J

    .line 75
    .line 76
    .line 77
    move-result-wide v5

    .line 78
    aput-wide v5, v3, v4

    .line 79
    .line 80
    add-int/lit8 v4, v4, 0x1

    .line 81
    .line 82
    goto :goto_1

    .line 83
    :cond_2
    new-instance v4, Ljava/lang/StringBuilder;

    .line 84
    .line 85
    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    .line 86
    .line 87
    .line 88
    const-string v5, "Successfully loaded empty DEX with "

    .line 89
    .line 90
    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 91
    .line 92
    .line 93
    invoke-interface {v2}, Ljava/util/List;->size()I

    .line 94
    .line 95
    .line 96
    move-result v2

    .line 97
    invoke-virtual {v4, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 98
    .line 99
    .line 100
    const-string v2, " cookies"

    .line 101
    .line 102
    invoke-virtual {v4, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 103
    .line 104
    .line 105
    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 106
    .line 107
    .line 108
    move-result-object v2

    .line 109
    invoke-static {v0, v2}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 110
    .line 111
    .line 112
    return-object v3

    .line 113
    :cond_3
    :goto_2
    const-string v2, "Empty JAR file not found or invalid"

    .line 114
    .line 115
    invoke-static {v0, v2}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 116
    .line 117
    .line 118
    new-array v0, v1, [J
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 119
    .line 120
    return-object v0

    .line 121
    :goto_3
    const-string v3, "Failed to load empty DEX"

    .line 122
    .line 123
    invoke-static {v0, v3, v2}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 124
    .line 125
    .line 126
    new-array v0, v1, [J

    .line 127
    .line 128
    return-object v0
.end method

.method public static native readNativeInt(J)I
.end method

.method public static redirectPath(Ljava/io/File;)Ljava/io/File;
    .locals 1
    .annotation build Ld/a;
    .end annotation

    .line 2
    invoke-static {}, Ltop/niunaijun/blackbox/core/IOCore;->get()Ltop/niunaijun/blackbox/core/IOCore;

    move-result-object v0

    invoke-virtual {v0, p0}, Ltop/niunaijun/blackbox/core/IOCore;->redirectPath(Ljava/io/File;)Ljava/io/File;

    move-result-object p0

    return-object p0
.end method

.method public static redirectPath(Ljava/lang/String;)Ljava/lang/String;
    .locals 1
    .annotation build Ld/a;
    .end annotation

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/core/IOCore;->get()Ltop/niunaijun/blackbox/core/IOCore;

    move-result-object v0

    invoke-virtual {v0, p0}, Ltop/niunaijun/blackbox/core/IOCore;->redirectPath(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method
