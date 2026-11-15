.class public Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;
.super Ljava/lang/Object;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# annotations
.annotation build Landroid/annotation/SuppressLint;
    value = {
        "SdCardPath",
        "NewApi"
    }
.end annotation


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method private static checkUseInstalledOrHidden(ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;Landroid/content/pm/ApplicationInfo;)Z
    .locals 0

    .line 1
    iget-object p0, p2, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 2
    .line 3
    invoke-static {p0}, Ltop/niunaijun/blackbox/core/env/AppSystemEnv;->isBlackPackage(Ljava/lang/String;)Z

    .line 4
    .line 5
    .line 6
    move-result p0

    .line 7
    const/4 p2, 0x0

    .line 8
    if-eqz p0, :cond_0

    .line 9
    .line 10
    return p2

    .line 11
    :cond_0
    iget-boolean p0, p1, Ltop/niunaijun/blackbox/core/system/pm/BPackageUserState;->installed:Z

    .line 12
    .line 13
    if-eqz p0, :cond_2

    .line 14
    .line 15
    iget-boolean p0, p1, Ltop/niunaijun/blackbox/core/system/pm/BPackageUserState;->hidden:Z

    .line 16
    .line 17
    if-eqz p0, :cond_1

    .line 18
    .line 19
    goto :goto_0

    .line 20
    :cond_1
    const/4 p0, 0x1

    .line 21
    return p0

    .line 22
    :cond_2
    :goto_0
    return p2
.end method

.method private static fixJar(Landroid/content/pm/ApplicationInfo;)V
    .locals 4

    .line 1
    new-instance v0, Ljava/util/HashSet;

    .line 2
    .line 3
    invoke-direct {v0}, Ljava/util/HashSet;-><init>()V

    .line 4
    .line 5
    .line 6
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isQ()Z

    .line 7
    .line 8
    .line 9
    move-result v1

    .line 10
    const-string v2, "/system/framework/org.apache.http.legacy.boot.jar"

    .line 11
    .line 12
    if-eqz v1, :cond_1

    .line 13
    .line 14
    const-string v1, "/system/framework/org.apache.http.legacy.jar"

    .line 15
    .line 16
    invoke-static {v1}, Ltop/niunaijun/blackbox/utils/FileUtils;->isExist(Ljava/lang/String;)Z

    .line 17
    .line 18
    .line 19
    move-result v3

    .line 20
    if-nez v3, :cond_0

    .line 21
    .line 22
    invoke-virtual {v0, v2}, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z

    .line 23
    .line 24
    .line 25
    goto :goto_0

    .line 26
    :cond_0
    invoke-virtual {v0, v1}, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z

    .line 27
    .line 28
    .line 29
    goto :goto_0

    .line 30
    :cond_1
    invoke-virtual {v0, v2}, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z

    .line 31
    .line 32
    .line 33
    :goto_0
    const/4 v1, 0x0

    .line 34
    new-array v1, v1, [Ljava/lang/String;

    .line 35
    .line 36
    invoke-virtual {v0, v1}, Ljava/util/HashSet;->toArray([Ljava/lang/Object;)[Ljava/lang/Object;

    .line 37
    .line 38
    .line 39
    move-result-object v0

    .line 40
    check-cast v0, [Ljava/lang/String;

    .line 41
    .line 42
    iput-object v0, p0, Landroid/content/pm/ApplicationInfo;->sharedLibraryFiles:[Ljava/lang/String;

    .line 43
    .line 44
    return-void
.end method

.method public static generateActivityInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage$Activity;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ActivityInfo;
    .locals 3

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Activity;->info:Landroid/content/pm/ActivityInfo;

    .line 2
    .line 3
    iget-object v0, v0, Landroid/content/pm/ActivityInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 4
    .line 5
    invoke-static {p1, p2, v0}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->checkUseInstalledOrHidden(ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;Landroid/content/pm/ApplicationInfo;)Z

    .line 6
    .line 7
    .line 8
    move-result v0

    .line 9
    if-nez v0, :cond_0

    .line 10
    .line 11
    const/4 p0, 0x0

    .line 12
    return-object p0

    .line 13
    :cond_0
    new-instance v0, Landroid/content/pm/ActivityInfo;

    .line 14
    .line 15
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Activity;->info:Landroid/content/pm/ActivityInfo;

    .line 16
    .line 17
    invoke-direct {v0, v1}, Landroid/content/pm/ActivityInfo;-><init>(Landroid/content/pm/ActivityInfo;)V

    .line 18
    .line 19
    .line 20
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Component;->metaData:Landroid/os/Bundle;

    .line 21
    .line 22
    iput-object v1, v0, Landroid/content/pm/ActivityInfo;->metaData:Landroid/os/Bundle;

    .line 23
    .line 24
    iget-object v1, v0, Landroid/content/pm/ActivityInfo;->packageName:Ljava/lang/String;

    .line 25
    .line 26
    iget-object v2, v0, Landroid/content/pm/ActivityInfo;->processName:Ljava/lang/String;

    .line 27
    .line 28
    invoke-static {v1, v2}, Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;->fixProcessName(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    .line 29
    .line 30
    .line 31
    move-result-object v1

    .line 32
    iput-object v1, v0, Landroid/content/pm/ActivityInfo;->processName:Ljava/lang/String;

    .line 33
    .line 34
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Component;->owner:Ltop/niunaijun/blackbox/core/system/pm/BPackage;

    .line 35
    .line 36
    invoke-static {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->generateApplicationInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ApplicationInfo;

    .line 37
    .line 38
    .line 39
    move-result-object p0

    .line 40
    iput-object p0, v0, Landroid/content/pm/ActivityInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 41
    .line 42
    return-object v0
.end method

.method public static generateApplicationInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ApplicationInfo;
    .locals 4

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 2
    .line 3
    invoke-static {p1, p2, v0}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->checkUseInstalledOrHidden(ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;Landroid/content/pm/ApplicationInfo;)Z

    .line 4
    .line 5
    .line 6
    move-result p2

    .line 7
    const/4 v0, 0x0

    .line 8
    if-nez p2, :cond_0

    .line 9
    .line 10
    return-object v0

    .line 11
    :cond_0
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getPackageManager()Landroid/content/pm/PackageManager;

    .line 12
    .line 13
    .line 14
    move-result-object p2

    .line 15
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getHostPkg()Ljava/lang/String;

    .line 16
    .line 17
    .line 18
    move-result-object v1

    .line 19
    invoke-virtual {p2, v1, p1}, Landroid/content/pm/PackageManager;->getApplicationInfo(Ljava/lang/String;I)Landroid/content/pm/ApplicationInfo;

    .line 20
    .line 21
    .line 22
    move-result-object p2
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 23
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->baseCodePath:Ljava/lang/String;

    .line 24
    .line 25
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 26
    .line 27
    const/4 v2, 0x0

    .line 28
    if-nez v1, :cond_1

    .line 29
    .line 30
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getPackageManager()Landroid/content/pm/PackageManager;

    .line 31
    .line 32
    .line 33
    move-result-object v1

    .line 34
    invoke-virtual {v1, v0, v2}, Landroid/content/pm/PackageManager;->getPackageArchiveInfo(Ljava/lang/String;I)Landroid/content/pm/PackageInfo;

    .line 35
    .line 36
    .line 37
    move-result-object v1

    .line 38
    iget-object v1, v1, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 39
    .line 40
    iput-object v1, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 41
    .line 42
    :cond_1
    new-instance v1, Landroid/content/pm/ApplicationInfo;

    .line 43
    .line 44
    iget-object v3, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 45
    .line 46
    invoke-direct {v1, v3}, Landroid/content/pm/ApplicationInfo;-><init>(Landroid/content/pm/ApplicationInfo;)V

    .line 47
    .line 48
    .line 49
    and-int/lit16 p1, p1, 0x80

    .line 50
    .line 51
    if-eqz p1, :cond_2

    .line 52
    .line 53
    iget-object p1, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->mAppMetaData:Landroid/os/Bundle;

    .line 54
    .line 55
    iput-object p1, v1, Landroid/content/pm/ApplicationInfo;->metaData:Landroid/os/Bundle;

    .line 56
    .line 57
    :cond_2
    iget-object p1, v1, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 58
    .line 59
    invoke-static {p1, p3}, Ltop/niunaijun/blackbox/core/env/BEnvironment;->getDataDir(Ljava/lang/String;I)Ljava/io/File;

    .line 60
    .line 61
    .line 62
    move-result-object p1

    .line 63
    invoke-virtual {p1}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    .line 64
    .line 65
    .line 66
    move-result-object p1

    .line 67
    iput-object p1, v1, Landroid/content/pm/ApplicationInfo;->dataDir:Ljava/lang/String;

    .line 68
    .line 69
    iget-object p1, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->installOption:Ltop/niunaijun/blackbox/entity/pm/InstallOption;

    .line 70
    .line 71
    const/4 v3, 0x1

    .line 72
    invoke-virtual {p1, v3}, Ltop/niunaijun/blackbox/entity/pm/InstallOption;->isFlag(I)Z

    .line 73
    .line 74
    .line 75
    move-result p1

    .line 76
    if-nez p1, :cond_3

    .line 77
    .line 78
    iget-object p1, v1, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 79
    .line 80
    invoke-static {p1}, Ltop/niunaijun/blackbox/core/env/BEnvironment;->getAppLibDir(Ljava/lang/String;)Ljava/io/File;

    .line 81
    .line 82
    .line 83
    move-result-object p1

    .line 84
    invoke-virtual {p1}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    .line 85
    .line 86
    .line 87
    move-result-object p1

    .line 88
    iput-object p1, v1, Landroid/content/pm/ApplicationInfo;->nativeLibraryDir:Ljava/lang/String;

    .line 89
    .line 90
    :cond_3
    iget-object p1, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->packageName:Ljava/lang/String;

    .line 91
    .line 92
    iget-object v3, v1, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 93
    .line 94
    invoke-static {p1, v3}, Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;->fixProcessName(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    .line 95
    .line 96
    .line 97
    move-result-object p1

    .line 98
    iput-object p1, v1, Landroid/content/pm/ApplicationInfo;->processName:Ljava/lang/String;

    .line 99
    .line 100
    iput-object v0, v1, Landroid/content/pm/ApplicationInfo;->publicSourceDir:Ljava/lang/String;

    .line 101
    .line 102
    iput-object v0, v1, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    .line 103
    .line 104
    iget-object p1, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->mExtras:Ltop/niunaijun/blackbox/core/system/pm/BPackageSettings;

    .line 105
    .line 106
    iget p1, p1, Ltop/niunaijun/blackbox/core/system/pm/BPackageSettings;->appId:I

    .line 107
    .line 108
    iput p1, v1, Landroid/content/pm/ApplicationInfo;->uid:I

    .line 109
    .line 110
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isL()Z

    .line 111
    .line 112
    .line 113
    move-result p1

    .line 114
    if-eqz p1, :cond_4

    .line 115
    .line 116
    const-class p1, Lblack/android/content/pm/ApplicationInfoLContext;

    .line 117
    .line 118
    invoke-static {p1, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 119
    .line 120
    .line 121
    move-result-object v0

    .line 122
    check-cast v0, Lblack/android/content/pm/ApplicationInfoLContext;

    .line 123
    .line 124
    sget-object v3, Landroid/os/Build;->CPU_ABI:Ljava/lang/String;

    .line 125
    .line 126
    invoke-interface {v0, v3}, Lblack/android/content/pm/ApplicationInfoLContext;->_set_primaryCpuAbi(Ljava/lang/Object;)V

    .line 127
    .line 128
    .line 129
    invoke-static {p1, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 130
    .line 131
    .line 132
    move-result-object v0

    .line 133
    check-cast v0, Lblack/android/content/pm/ApplicationInfoLContext;

    .line 134
    .line 135
    invoke-static {p1, p2, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 136
    .line 137
    .line 138
    move-result-object v3

    .line 139
    check-cast v3, Lblack/android/content/pm/ApplicationInfoLContext;

    .line 140
    .line 141
    invoke-interface {v3}, Lblack/android/content/pm/ApplicationInfoLContext;->scanPublicSourceDir()Ljava/lang/String;

    .line 142
    .line 143
    .line 144
    move-result-object v3

    .line 145
    invoke-interface {v0, v3}, Lblack/android/content/pm/ApplicationInfoLContext;->_set_scanPublicSourceDir(Ljava/lang/Object;)V

    .line 146
    .line 147
    .line 148
    invoke-static {p1, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 149
    .line 150
    .line 151
    move-result-object v0

    .line 152
    check-cast v0, Lblack/android/content/pm/ApplicationInfoLContext;

    .line 153
    .line 154
    invoke-static {p1, p2, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 155
    .line 156
    .line 157
    move-result-object p1

    .line 158
    check-cast p1, Lblack/android/content/pm/ApplicationInfoLContext;

    .line 159
    .line 160
    invoke-interface {p1}, Lblack/android/content/pm/ApplicationInfoLContext;->scanSourceDir()Ljava/lang/String;

    .line 161
    .line 162
    .line 163
    move-result-object p1

    .line 164
    invoke-interface {v0, p1}, Lblack/android/content/pm/ApplicationInfoLContext;->_set_scanSourceDir(Ljava/lang/Object;)V

    .line 165
    .line 166
    .line 167
    :cond_4
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isN()Z

    .line 168
    .line 169
    .line 170
    move-result p1

    .line 171
    if-eqz p1, :cond_8

    .line 172
    .line 173
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->packageName:Ljava/lang/String;

    .line 174
    .line 175
    invoke-static {p0, p3}, Ltop/niunaijun/blackbox/core/env/BEnvironment;->getDeDataDir(Ljava/lang/String;I)Ljava/io/File;

    .line 176
    .line 177
    .line 178
    move-result-object p0

    .line 179
    invoke-virtual {p0}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    .line 180
    .line 181
    .line 182
    move-result-object p0

    .line 183
    iput-object p0, v1, Landroid/content/pm/ApplicationInfo;->deviceProtectedDataDir:Ljava/lang/String;

    .line 184
    .line 185
    const-class p0, Lblack/android/content/pm/ApplicationInfoNContext;

    .line 186
    .line 187
    invoke-static {p0, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 188
    .line 189
    .line 190
    move-result-object p1

    .line 191
    check-cast p1, Lblack/android/content/pm/ApplicationInfoNContext;

    .line 192
    .line 193
    invoke-interface {p1}, Lblack/android/content/pm/ApplicationInfoNContext;->_check_deviceEncryptedDataDir()Ljava/lang/reflect/Field;

    .line 194
    .line 195
    .line 196
    move-result-object p1

    .line 197
    if-eqz p1, :cond_5

    .line 198
    .line 199
    invoke-static {p0, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 200
    .line 201
    .line 202
    move-result-object p1

    .line 203
    check-cast p1, Lblack/android/content/pm/ApplicationInfoNContext;

    .line 204
    .line 205
    iget-object p2, v1, Landroid/content/pm/ApplicationInfo;->deviceProtectedDataDir:Ljava/lang/String;

    .line 206
    .line 207
    invoke-interface {p1, p2}, Lblack/android/content/pm/ApplicationInfoNContext;->_set_deviceEncryptedDataDir(Ljava/lang/Object;)V

    .line 208
    .line 209
    .line 210
    :cond_5
    invoke-static {p0, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 211
    .line 212
    .line 213
    move-result-object p1

    .line 214
    check-cast p1, Lblack/android/content/pm/ApplicationInfoNContext;

    .line 215
    .line 216
    invoke-interface {p1}, Lblack/android/content/pm/ApplicationInfoNContext;->_check_credentialEncryptedDataDir()Ljava/lang/reflect/Field;

    .line 217
    .line 218
    .line 219
    move-result-object p1

    .line 220
    if-eqz p1, :cond_6

    .line 221
    .line 222
    invoke-static {p0, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 223
    .line 224
    .line 225
    move-result-object p1

    .line 226
    check-cast p1, Lblack/android/content/pm/ApplicationInfoNContext;

    .line 227
    .line 228
    iget-object p2, v1, Landroid/content/pm/ApplicationInfo;->dataDir:Ljava/lang/String;

    .line 229
    .line 230
    invoke-interface {p1, p2}, Lblack/android/content/pm/ApplicationInfoNContext;->_set_credentialEncryptedDataDir(Ljava/lang/Object;)V

    .line 231
    .line 232
    .line 233
    :cond_6
    invoke-static {p0, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 234
    .line 235
    .line 236
    move-result-object p1

    .line 237
    check-cast p1, Lblack/android/content/pm/ApplicationInfoNContext;

    .line 238
    .line 239
    invoke-interface {p1}, Lblack/android/content/pm/ApplicationInfoNContext;->_check_deviceProtectedDataDir()Ljava/lang/reflect/Field;

    .line 240
    .line 241
    .line 242
    move-result-object p1

    .line 243
    if-eqz p1, :cond_7

    .line 244
    .line 245
    invoke-static {p0, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 246
    .line 247
    .line 248
    move-result-object p1

    .line 249
    check-cast p1, Lblack/android/content/pm/ApplicationInfoNContext;

    .line 250
    .line 251
    iget-object p2, v1, Landroid/content/pm/ApplicationInfo;->deviceProtectedDataDir:Ljava/lang/String;

    .line 252
    .line 253
    invoke-interface {p1, p2}, Lblack/android/content/pm/ApplicationInfoNContext;->_set_deviceProtectedDataDir(Ljava/lang/Object;)V

    .line 254
    .line 255
    .line 256
    :cond_7
    invoke-static {p0, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 257
    .line 258
    .line 259
    move-result-object p1

    .line 260
    check-cast p1, Lblack/android/content/pm/ApplicationInfoNContext;

    .line 261
    .line 262
    invoke-interface {p1}, Lblack/android/content/pm/ApplicationInfoNContext;->_check_credentialProtectedDataDir()Ljava/lang/reflect/Field;

    .line 263
    .line 264
    .line 265
    move-result-object p1

    .line 266
    if-eqz p1, :cond_8

    .line 267
    .line 268
    invoke-static {p0, v1, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 269
    .line 270
    .line 271
    move-result-object p0

    .line 272
    check-cast p0, Lblack/android/content/pm/ApplicationInfoNContext;

    .line 273
    .line 274
    iget-object p1, v1, Landroid/content/pm/ApplicationInfo;->dataDir:Ljava/lang/String;

    .line 275
    .line 276
    invoke-interface {p0, p1}, Lblack/android/content/pm/ApplicationInfoNContext;->_set_credentialProtectedDataDir(Ljava/lang/Object;)V

    .line 277
    .line 278
    .line 279
    :cond_8
    invoke-static {v1}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->fixJar(Landroid/content/pm/ApplicationInfo;)V

    .line 280
    .line 281
    .line 282
    invoke-static {v1, p3}, Lio/github/leexeo/cage/space/GuestSplits;->apply(Landroid/content/pm/ApplicationInfo;I)Landroid/content/pm/ApplicationInfo;

    move-result-object v1

    return-object v1

    .line 283
    :catch_0
    return-object v0
.end method

.method public static generateInstrumentationInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage$Instrumentation;I)Landroid/content/pm/InstrumentationInfo;
    .locals 1

    .line 1
    if-nez p0, :cond_0

    .line 2
    .line 3
    const/4 p0, 0x0

    .line 4
    return-object p0

    .line 5
    :cond_0
    and-int/lit16 p1, p1, 0x80

    .line 6
    .line 7
    if-nez p1, :cond_1

    .line 8
    .line 9
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Instrumentation;->info:Landroid/content/pm/InstrumentationInfo;

    .line 10
    .line 11
    return-object p0

    .line 12
    :cond_1
    new-instance p1, Landroid/content/pm/InstrumentationInfo;

    .line 13
    .line 14
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Instrumentation;->info:Landroid/content/pm/InstrumentationInfo;

    .line 15
    .line 16
    invoke-direct {p1, v0}, Landroid/content/pm/InstrumentationInfo;-><init>(Landroid/content/pm/InstrumentationInfo;)V

    .line 17
    .line 18
    .line 19
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Component;->metaData:Landroid/os/Bundle;

    .line 20
    .line 21
    iput-object p0, p1, Landroid/content/pm/InstrumentationInfo;->metaData:Landroid/os/Bundle;

    .line 22
    .line 23
    return-object p1
.end method

.method public static generatePackageInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage;IJJLtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/PackageInfo;
    .locals 6

    move v5, p1

    .line 3
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    invoke-static {p1, p6, v0}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->checkUseInstalledOrHidden(ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;Landroid/content/pm/ApplicationInfo;)Z

    move-result v0

    const/4 v1, 0x0

    if-nez v0, :cond_0

    return-object v1

    .line 4
    :cond_0
    new-instance v0, Landroid/content/pm/PackageInfo;

    invoke-direct {v0}, Landroid/content/pm/PackageInfo;-><init>()V

    .line 5
    iget-object v2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->packageName:Ljava/lang/String;

    iput-object v2, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    .line 6
    iget v2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->mVersionCode:I

    iput v2, v0, Landroid/content/pm/PackageInfo;->versionCode:I

    .line 7
    iget-object v2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->mVersionName:Ljava/lang/String;

    iput-object v2, v0, Landroid/content/pm/PackageInfo;->versionName:Ljava/lang/String;

    .line 8
    iget-object v2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->mSharedUserId:Ljava/lang/String;

    iput-object v2, v0, Landroid/content/pm/PackageInfo;->sharedUserId:Ljava/lang/String;

    .line 9
    iget v2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->mSharedUserLabel:I

    iput v2, v0, Landroid/content/pm/PackageInfo;->sharedUserLabel:I

    .line 10
    invoke-static {p0, p1, p6, p7}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->generateApplicationInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ApplicationInfo;

    move-result-object v2

    iput-object v2, v0, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 11
    iput-wide p2, v0, Landroid/content/pm/PackageInfo;->firstInstallTime:J

    .line 12
    iput-wide p4, v0, Landroid/content/pm/PackageInfo;->lastUpdateTime:J

    .line 13
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->requestedPermissions:Ljava/util/ArrayList;

    invoke-virtual {p2}, Ljava/util/ArrayList;->isEmpty()Z

    move-result p2

    if-nez p2, :cond_1

    .line 14
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->requestedPermissions:Ljava/util/ArrayList;

    invoke-virtual {p2}, Ljava/util/ArrayList;->size()I

    move-result p2

    new-array p2, p2, [Ljava/lang/String;

    .line 15
    iget-object p3, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->requestedPermissions:Ljava/util/ArrayList;

    invoke-virtual {p3, p2}, Ljava/util/ArrayList;->toArray([Ljava/lang/Object;)[Ljava/lang/Object;

    .line 16
    iput-object p2, v0, Landroid/content/pm/PackageInfo;->requestedPermissions:[Ljava/lang/String;

    :cond_1
    and-int/lit16 p2, p1, 0x100

    const/4 p3, 0x0

    if-eqz p2, :cond_2

    .line 17
    new-array p2, p3, [I

    iput-object p2, v0, Landroid/content/pm/PackageInfo;->gids:[I

    :cond_2
    and-int/lit16 p2, p1, 0x4000

    if-eqz p2, :cond_6

    .line 18
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->configPreferences:Ljava/util/ArrayList;

    if-eqz p2, :cond_3

    invoke-virtual {p2}, Ljava/util/ArrayList;->size()I

    move-result p2

    goto :goto_0

    :cond_3
    move p2, p3

    :goto_0
    if-lez p2, :cond_4

    .line 19
    new-array p2, p2, [Landroid/content/pm/ConfigurationInfo;

    iput-object p2, v0, Landroid/content/pm/PackageInfo;->configPreferences:[Landroid/content/pm/ConfigurationInfo;

    .line 20
    iget-object p4, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->configPreferences:Ljava/util/ArrayList;

    invoke-virtual {p4, p2}, Ljava/util/ArrayList;->toArray([Ljava/lang/Object;)[Ljava/lang/Object;

    .line 21
    :cond_4
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->reqFeatures:Ljava/util/ArrayList;

    if-eqz p2, :cond_5

    invoke-virtual {p2}, Ljava/util/ArrayList;->size()I

    move-result p2

    goto :goto_1

    :cond_5
    move p2, p3

    :goto_1
    if-lez p2, :cond_6

    .line 22
    new-array p2, p2, [Landroid/content/pm/FeatureInfo;

    iput-object p2, v0, Landroid/content/pm/PackageInfo;->reqFeatures:[Landroid/content/pm/FeatureInfo;

    .line 23
    iget-object p4, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->reqFeatures:Ljava/util/ArrayList;

    invoke-virtual {p4, p2}, Ljava/util/ArrayList;->toArray([Ljava/lang/Object;)[Ljava/lang/Object;

    :cond_6
    and-int/lit8 p2, p1, 0x1

    if-eqz p2, :cond_8

    .line 24
    iput-object v1, v0, Landroid/content/pm/PackageInfo;->activities:[Landroid/content/pm/ActivityInfo;

    .line 25
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->activities:Ljava/util/ArrayList;

    invoke-virtual {p2}, Ljava/util/ArrayList;->size()I

    move-result p2

    if-lez p2, :cond_8

    .line 26
    new-array p4, p2, [Landroid/content/pm/ActivityInfo;

    move p5, p3

    move v2, p5

    :goto_2
    if-ge p5, p2, :cond_7

    .line 27
    iget-object v3, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->activities:Ljava/util/ArrayList;

    invoke-virtual {v3, p5}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Activity;

    add-int/lit8 v4, v2, 0x1

    .line 28
    invoke-static {v3, p1, p6, p7}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->generateActivityInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage$Activity;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ActivityInfo;

    move-result-object v3

    aput-object v3, p4, v2

    add-int/lit8 p5, p5, 0x1

    move v2, v4

    goto :goto_2

    .line 29
    :cond_7
    invoke-static {p4, v2}, Ltop/niunaijun/blackbox/utils/ArrayUtils;->trimToSize([Ljava/lang/Object;I)[Ljava/lang/Object;

    move-result-object p2

    check-cast p2, [Landroid/content/pm/ActivityInfo;

    iput-object p2, v0, Landroid/content/pm/PackageInfo;->activities:[Landroid/content/pm/ActivityInfo;

    :cond_8
    and-int/lit8 p2, p1, 0x2

    if-eqz p2, :cond_a

    .line 30
    iput-object v1, v0, Landroid/content/pm/PackageInfo;->receivers:[Landroid/content/pm/ActivityInfo;

    .line 31
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->receivers:Ljava/util/ArrayList;

    invoke-virtual {p2}, Ljava/util/ArrayList;->size()I

    move-result p2

    if-lez p2, :cond_a

    .line 32
    new-array p4, p2, [Landroid/content/pm/ActivityInfo;

    move p5, p3

    move v2, p5

    :goto_3
    if-ge p5, p2, :cond_9

    .line 33
    iget-object v3, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->receivers:Ljava/util/ArrayList;

    invoke-virtual {v3, p5}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Activity;

    add-int/lit8 v4, v2, 0x1

    .line 34
    invoke-static {v3, p1, p6, p7}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->generateActivityInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage$Activity;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ActivityInfo;

    move-result-object v3

    aput-object v3, p4, v2

    add-int/lit8 p5, p5, 0x1

    move v2, v4

    goto :goto_3

    .line 35
    :cond_9
    invoke-static {p4, v2}, Ltop/niunaijun/blackbox/utils/ArrayUtils;->trimToSize([Ljava/lang/Object;I)[Ljava/lang/Object;

    move-result-object p2

    check-cast p2, [Landroid/content/pm/ActivityInfo;

    iput-object p2, v0, Landroid/content/pm/PackageInfo;->receivers:[Landroid/content/pm/ActivityInfo;

    :cond_a
    and-int/lit8 p2, p1, 0x4

    if-eqz p2, :cond_f

    .line 36
    iput-object v1, v0, Landroid/content/pm/PackageInfo;->services:[Landroid/content/pm/ServiceInfo;

    .line 37
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->services:Ljava/util/ArrayList;

    invoke-virtual {p2}, Ljava/util/ArrayList;->size()I

    move-result p2

    if-lez p2, :cond_f

    .line 38
    new-array p4, p2, [Landroid/content/pm/ServiceInfo;

    move p5, p3

    move v2, p5

    :goto_4
    if-ge p5, p2, :cond_e

    .line 39
    iget-object v3, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->services:Ljava/util/ArrayList;

    invoke-virtual {v3, p5}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Service;

    .line 40
    invoke-static {v3, p1, p6, p7}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->generateServiceInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage$Service;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ServiceInfo;

    move-result-object v3

    if-nez v3, :cond_b

    goto :goto_6

    :cond_b
    and-int/lit16 v4, p1, 0x80

    if-eqz v4, :cond_c

    .line 41
    iget-object v4, v3, Landroid/content/pm/ServiceInfo;->metaData:Landroid/os/Bundle;

    if-eqz v4, :cond_d

    add-int/lit8 v4, v2, 0x1

    .line 42
    aput-object v3, p4, v2

    :goto_5
    move v2, v4

    goto :goto_6

    :cond_c
    add-int/lit8 v4, v2, 0x1

    .line 43
    aput-object v3, p4, v2

    goto :goto_5

    :cond_d
    :goto_6
    add-int/lit8 p5, p5, 0x1

    goto :goto_4

    .line 44
    :cond_e
    invoke-static {p4, v2}, Ltop/niunaijun/blackbox/utils/ArrayUtils;->trimToSize([Ljava/lang/Object;I)[Ljava/lang/Object;

    move-result-object p2

    check-cast p2, [Landroid/content/pm/ServiceInfo;

    iput-object p2, v0, Landroid/content/pm/PackageInfo;->services:[Landroid/content/pm/ServiceInfo;

    :cond_f
    and-int/lit8 p2, p1, 0x8

    if-eqz p2, :cond_12

    .line 45
    iput-object v1, v0, Landroid/content/pm/PackageInfo;->providers:[Landroid/content/pm/ProviderInfo;

    .line 46
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->providers:Ljava/util/ArrayList;

    invoke-virtual {p2}, Ljava/util/ArrayList;->size()I

    move-result p2

    if-lez p2, :cond_12

    .line 47
    new-array p4, p2, [Landroid/content/pm/ProviderInfo;

    move p5, p3

    move v2, p5

    :goto_7
    if-ge p5, p2, :cond_11

    .line 48
    iget-object v3, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->providers:Ljava/util/ArrayList;

    invoke-virtual {v3, p5}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Provider;

    .line 49
    invoke-static {v3, p1, p6, p7}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->generateProviderInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage$Provider;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ProviderInfo;

    move-result-object v3

    if-eqz v3, :cond_10

    add-int/lit8 v4, v2, 0x1

    .line 50
    aput-object v3, p4, v2

    move v2, v4

    :cond_10
    add-int/lit8 p5, p5, 0x1

    goto :goto_7

    .line 51
    :cond_11
    invoke-static {p4, v2}, Ltop/niunaijun/blackbox/utils/ArrayUtils;->trimToSize([Ljava/lang/Object;I)[Ljava/lang/Object;

    move-result-object p2

    check-cast p2, [Landroid/content/pm/ProviderInfo;

    iput-object p2, v0, Landroid/content/pm/PackageInfo;->providers:[Landroid/content/pm/ProviderInfo;

    :cond_12
    and-int/lit8 p2, p1, 0x10

    if-eqz p2, :cond_13

    .line 52
    iput-object v1, v0, Landroid/content/pm/PackageInfo;->instrumentation:[Landroid/content/pm/InstrumentationInfo;

    .line 53
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->instrumentation:Ljava/util/ArrayList;

    invoke-virtual {p2}, Ljava/util/ArrayList;->size()I

    move-result p2

    if-lez p2, :cond_13

    .line 54
    new-array p4, p2, [Landroid/content/pm/InstrumentationInfo;

    iput-object p4, v0, Landroid/content/pm/PackageInfo;->instrumentation:[Landroid/content/pm/InstrumentationInfo;

    move p4, p3

    :goto_8
    if-ge p4, p2, :cond_13

    .line 55
    iget-object p5, v0, Landroid/content/pm/PackageInfo;->instrumentation:[Landroid/content/pm/InstrumentationInfo;

    iget-object p6, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->instrumentation:Ljava/util/ArrayList;

    .line 56
    invoke-virtual {p6, p4}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object p6

    check-cast p6, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Instrumentation;

    .line 57
    invoke-static {p6, p1}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->generateInstrumentationInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage$Instrumentation;I)Landroid/content/pm/InstrumentationInfo;

    move-result-object p6

    aput-object p6, p5, p4

    add-int/lit8 p4, p4, 0x1

    goto :goto_8

    :cond_13
    and-int/lit16 p2, p1, 0x1000

    if-eqz p2, :cond_15

    .line 58
    iput-object v1, v0, Landroid/content/pm/PackageInfo;->permissions:[Landroid/content/pm/PermissionInfo;

    .line 59
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->permissions:Ljava/util/ArrayList;

    invoke-virtual {p2}, Ljava/util/ArrayList;->size()I

    move-result p2

    if-lez p2, :cond_14

    .line 60
    new-array p4, p2, [Landroid/content/pm/PermissionInfo;

    iput-object p4, v0, Landroid/content/pm/PackageInfo;->permissions:[Landroid/content/pm/PermissionInfo;

    move p4, p3

    :goto_9
    if-ge p4, p2, :cond_14

    .line 61
    iget-object p5, v0, Landroid/content/pm/PackageInfo;->permissions:[Landroid/content/pm/PermissionInfo;

    iget-object p6, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->permissions:Ljava/util/ArrayList;

    invoke-virtual {p6, p4}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object p6

    check-cast p6, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Permission;

    invoke-static {p6, p1}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->generatePermissionInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage$Permission;I)Landroid/content/pm/PermissionInfo;

    move-result-object p6

    aput-object p6, p5, p4

    add-int/lit8 p4, p4, 0x1

    goto :goto_9

    .line 62
    :cond_14
    iput-object v1, v0, Landroid/content/pm/PackageInfo;->requestedPermissions:[Ljava/lang/String;

    .line 63
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->requestedPermissions:Ljava/util/ArrayList;

    invoke-virtual {p2}, Ljava/util/ArrayList;->size()I

    move-result p2

    if-lez p2, :cond_15

    .line 64
    new-array p4, p2, [Ljava/lang/String;

    iput-object p4, v0, Landroid/content/pm/PackageInfo;->requestedPermissions:[Ljava/lang/String;

    .line 65
    new-array p4, p2, [I

    iput-object p4, v0, Landroid/content/pm/PackageInfo;->requestedPermissionsFlags:[I

    move p4, p3

    :goto_a
    if-ge p4, p2, :cond_15

    .line 66
    iget-object p5, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->requestedPermissions:Ljava/util/ArrayList;

    invoke-virtual {p5, p4}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object p5

    check-cast p5, Ljava/lang/String;

    .line 67
    iget-object p6, v0, Landroid/content/pm/PackageInfo;->requestedPermissions:[Ljava/lang/String;

    aput-object p5, p6, p4

    add-int/lit8 p4, p4, 0x1

    goto :goto_a

    .line 68
    :cond_15
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    move-result-object p2

    invoke-virtual {p2}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object p2

    iget-object p4, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->packageName:Ljava/lang/String;

    invoke-virtual {p2, p4, p1}, Landroid/content/pm/PackageManager;->getPackageInfo(Ljava/lang/String;I)Landroid/content/pm/PackageInfo;

    move-result-object p2
    :try_end_0
    .catch Landroid/content/pm/PackageManager$NameNotFoundException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_b

    :catch_0
    move-object p2, v1

    :goto_b
    and-int/lit8 p4, p1, 0x40

    if-eqz p4, :cond_17

    if-nez p2, :cond_16

    .line 69
    iget-object p4, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->mSignatures:[Landroid/content/pm/Signature;

    iput-object p4, v0, Landroid/content/pm/PackageInfo;->signatures:[Landroid/content/pm/Signature;

    goto :goto_c

    .line 70
    :cond_16
    iget-object p4, p2, Landroid/content/pm/PackageInfo;->signatures:[Landroid/content/pm/Signature;

    iput-object p4, v0, Landroid/content/pm/PackageInfo;->signatures:[Landroid/content/pm/Signature;

    .line 71
    :cond_17
    :goto_c
    invoke-static {}, Ltop/niunaijun/blackbox/utils/compat/BuildCompat;->isPie()Z

    move-result p4

    if-eqz p4, :cond_19

    const/high16 p4, 0x8000000

    and-int/2addr p1, p4

    if-eqz p1, :cond_19

    if-nez p2, :cond_18

    .line 72
    sget-object p1, Landroid/content/pm/PackageParser$SigningDetails;->UNKNOWN:Landroid/content/pm/PackageParser$SigningDetails;

    .line 73
    const-class p2, Lblack/android/content/pm/PackageParserSigningDetailsContext;

    invoke-static {p2, p1, p3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    move-result-object p2

    check-cast p2, Lblack/android/content/pm/PackageParserSigningDetailsContext;

    .line 74
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->mSigningDetails:Ltop/niunaijun/blackbox/core/system/pm/BPackage$SigningDetails;

    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$SigningDetails;->signatures:[Landroid/content/pm/Signature;

    invoke-interface {p2, p0}, Lblack/android/content/pm/PackageParserSigningDetailsContext;->_set_signatures(Ljava/lang/Object;)V

    .line 75
    const-class p0, Lblack/android/content/pm/SigningInfoStatic;

    invoke-static {p0, v1, p3}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Lblack/android/content/pm/SigningInfoStatic;

    .line 76
    invoke-interface {p0, p1}, Lblack/android/content/pm/SigningInfoStatic;->_new(Landroid/content/pm/PackageParser$SigningDetails;)Landroid/content/pm/SigningInfo;

    move-result-object p0

    invoke-static {v0, p0}, La1/q;->s(Landroid/content/pm/PackageInfo;Landroid/content/pm/SigningInfo;)V

    goto :goto_d

    .line 77
    :cond_18
    invoke-static {p2}, La1/q;->e(Landroid/content/pm/PackageInfo;)Landroid/content/pm/SigningInfo;

    move-result-object p0

    invoke-static {v0, p0}, La1/q;->s(Landroid/content/pm/PackageInfo;Landroid/content/pm/SigningInfo;)V

    :cond_19
    :goto_d
    invoke-static {v0, v5}, Lio/github/leexeo/cage/space/GuestSplits;->packageInfo(Landroid/content/pm/PackageInfo;I)Landroid/content/pm/PackageInfo;

    move-result-object v0

    return-object v0
.end method

.method public static generatePackageInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackageSettings;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/PackageInfo;
    .locals 9

    const/4 v0, 0x0

    if-nez p0, :cond_0

    return-object v0

    .line 1
    :cond_0
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackageSettings;->pkg:Ltop/niunaijun/blackbox/core/system/pm/BPackage;

    if-eqz v1, :cond_1

    const-wide/16 v3, 0x0

    const-wide/16 v5, 0x0

    move v2, p1

    move-object v7, p2

    move v8, p3

    .line 2
    :try_start_0
    invoke-static/range {v1 .. v8}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->generatePackageInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage;IJJLtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/PackageInfo;

    move-result-object p0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    return-object p0

    :catchall_0
    :cond_1
    return-object v0
.end method

.method public static generatePermissionInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage$Permission;I)Landroid/content/pm/PermissionInfo;
    .locals 1

    .line 1
    if-nez p0, :cond_0

    .line 2
    .line 3
    const/4 p0, 0x0

    .line 4
    return-object p0

    .line 5
    :cond_0
    and-int/lit16 p1, p1, 0x80

    .line 6
    .line 7
    if-nez p1, :cond_1

    .line 8
    .line 9
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Permission;->info:Landroid/content/pm/PermissionInfo;

    .line 10
    .line 11
    return-object p0

    .line 12
    :cond_1
    new-instance p1, Landroid/content/pm/PermissionInfo;

    .line 13
    .line 14
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Permission;->info:Landroid/content/pm/PermissionInfo;

    .line 15
    .line 16
    invoke-direct {p1, v0}, Landroid/content/pm/PermissionInfo;-><init>(Landroid/content/pm/PermissionInfo;)V

    .line 17
    .line 18
    .line 19
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Component;->metaData:Landroid/os/Bundle;

    .line 20
    .line 21
    iput-object p0, p1, Landroid/content/pm/PermissionInfo;->metaData:Landroid/os/Bundle;

    .line 22
    .line 23
    return-object p1
.end method

.method public static generateProviderInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage$Provider;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ProviderInfo;
    .locals 4

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Provider;->info:Landroid/content/pm/ProviderInfo;

    .line 2
    .line 3
    iget-object v0, v0, Landroid/content/pm/ProviderInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 4
    .line 5
    invoke-static {p1, p2, v0}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->checkUseInstalledOrHidden(ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;Landroid/content/pm/ApplicationInfo;)Z

    .line 6
    .line 7
    .line 8
    move-result v0

    .line 9
    const/4 v1, 0x0

    .line 10
    if-nez v0, :cond_0

    .line 11
    .line 12
    return-object v1

    .line 13
    :cond_0
    new-instance v0, Landroid/content/pm/ProviderInfo;

    .line 14
    .line 15
    iget-object v2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Provider;->info:Landroid/content/pm/ProviderInfo;

    .line 16
    .line 17
    invoke-direct {v0, v2}, Landroid/content/pm/ProviderInfo;-><init>(Landroid/content/pm/ProviderInfo;)V

    .line 18
    .line 19
    .line 20
    iget-object v2, v0, Landroid/content/pm/ProviderInfo;->authority:Ljava/lang/String;

    .line 21
    .line 22
    if-nez v2, :cond_1

    .line 23
    .line 24
    return-object v1

    .line 25
    :cond_1
    iget-object v2, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Component;->metaData:Landroid/os/Bundle;

    .line 26
    .line 27
    iput-object v2, v0, Landroid/content/pm/ProviderInfo;->metaData:Landroid/os/Bundle;

    .line 28
    .line 29
    iget-object v2, v0, Landroid/content/pm/ProviderInfo;->packageName:Ljava/lang/String;

    .line 30
    .line 31
    iget-object v3, v0, Landroid/content/pm/ProviderInfo;->processName:Ljava/lang/String;

    .line 32
    .line 33
    invoke-static {v2, v3}, Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;->fixProcessName(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    .line 34
    .line 35
    .line 36
    move-result-object v2

    .line 37
    iput-object v2, v0, Landroid/content/pm/ProviderInfo;->processName:Ljava/lang/String;

    .line 38
    .line 39
    and-int/lit16 v2, p1, 0x800

    .line 40
    .line 41
    if-nez v2, :cond_2

    .line 42
    .line 43
    iput-object v1, v0, Landroid/content/pm/ProviderInfo;->uriPermissionPatterns:[Landroid/os/PatternMatcher;

    .line 44
    .line 45
    :cond_2
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Component;->owner:Ltop/niunaijun/blackbox/core/system/pm/BPackage;

    .line 46
    .line 47
    invoke-static {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->generateApplicationInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ApplicationInfo;

    .line 48
    .line 49
    .line 50
    move-result-object p0

    .line 51
    iput-object p0, v0, Landroid/content/pm/ProviderInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 52
    .line 53
    return-object v0
.end method

.method public static generateServiceInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage$Service;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ServiceInfo;
    .locals 3

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Service;->info:Landroid/content/pm/ServiceInfo;

    .line 2
    .line 3
    iget-object v0, v0, Landroid/content/pm/ServiceInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 4
    .line 5
    invoke-static {p1, p2, v0}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->checkUseInstalledOrHidden(ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;Landroid/content/pm/ApplicationInfo;)Z

    .line 6
    .line 7
    .line 8
    move-result v0

    .line 9
    if-nez v0, :cond_0

    .line 10
    .line 11
    const/4 p0, 0x0

    .line 12
    return-object p0

    .line 13
    :cond_0
    new-instance v0, Landroid/content/pm/ServiceInfo;

    .line 14
    .line 15
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Service;->info:Landroid/content/pm/ServiceInfo;

    .line 16
    .line 17
    invoke-direct {v0, v1}, Landroid/content/pm/ServiceInfo;-><init>(Landroid/content/pm/ServiceInfo;)V

    .line 18
    .line 19
    .line 20
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Component;->metaData:Landroid/os/Bundle;

    .line 21
    .line 22
    iput-object v1, v0, Landroid/content/pm/ServiceInfo;->metaData:Landroid/os/Bundle;

    .line 23
    .line 24
    iget-object v1, v0, Landroid/content/pm/ServiceInfo;->packageName:Ljava/lang/String;

    .line 25
    .line 26
    iget-object v2, v0, Landroid/content/pm/ServiceInfo;->processName:Ljava/lang/String;

    .line 27
    .line 28
    invoke-static {v1, v2}, Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;->fixProcessName(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    .line 29
    .line 30
    .line 31
    move-result-object v1

    .line 32
    iput-object v1, v0, Landroid/content/pm/ServiceInfo;->processName:Ljava/lang/String;

    .line 33
    .line 34
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/pm/BPackage$Component;->owner:Ltop/niunaijun/blackbox/core/system/pm/BPackage;

    .line 35
    .line 36
    invoke-static {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/core/system/pm/PackageManagerCompat;->generateApplicationInfo(Ltop/niunaijun/blackbox/core/system/pm/BPackage;ILtop/niunaijun/blackbox/core/system/pm/BPackageUserState;I)Landroid/content/pm/ApplicationInfo;

    .line 37
    .line 38
    .line 39
    move-result-object p0

    .line 40
    iput-object p0, v0, Landroid/content/pm/ServiceInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 41
    .line 42
    return-object v0
.end method

.method public static getResources(Landroid/content/Context;Landroid/content/pm/ApplicationInfo;)Landroid/content/res/Resources;
    .locals 3

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;->get()Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    iget-object p1, p1, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 6
    .line 7
    invoke-virtual {v0, p1}, Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;->getBPackageSetting(Ljava/lang/String;)Ltop/niunaijun/blackbox/core/system/pm/BPackageSettings;

    .line 8
    .line 9
    .line 10
    move-result-object p1

    .line 11
    const/4 v0, 0x0

    .line 12
    if-eqz p1, :cond_0

    .line 13
    .line 14
    const-class v1, Lblack/android/content/res/AssetManagerStatic;

    .line 15
    .line 16
    const/4 v2, 0x0

    .line 17
    invoke-static {v1, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 18
    .line 19
    .line 20
    move-result-object v0

    .line 21
    check-cast v0, Lblack/android/content/res/AssetManagerStatic;

    .line 22
    .line 23
    invoke-interface {v0}, Lblack/android/content/res/AssetManagerStatic;->_new()Landroid/content/res/AssetManager;

    .line 24
    .line 25
    .line 26
    move-result-object v0

    .line 27
    const-class v1, Lblack/android/content/res/AssetManagerContext;

    .line 28
    .line 29
    invoke-static {v1, v0, v2}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 30
    .line 31
    .line 32
    move-result-object v1

    .line 33
    check-cast v1, Lblack/android/content/res/AssetManagerContext;

    .line 34
    .line 35
    iget-object p1, p1, Ltop/niunaijun/blackbox/core/system/pm/BPackageSettings;->pkg:Ltop/niunaijun/blackbox/core/system/pm/BPackage;

    .line 36
    .line 37
    iget-object p1, p1, Ltop/niunaijun/blackbox/core/system/pm/BPackage;->baseCodePath:Ljava/lang/String;

    .line 38
    .line 39
    invoke-interface {v1, p1}, Lblack/android/content/res/AssetManagerContext;->addAssetPath(Ljava/lang/String;)Ljava/lang/Integer;

    .line 40
    .line 41
    .line 42
    invoke-virtual {p0}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;

    .line 43
    .line 44
    .line 45
    move-result-object p0

    .line 46
    new-instance p1, Landroid/content/res/Resources;

    .line 47
    .line 48
    invoke-virtual {p0}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;

    .line 49
    .line 50
    .line 51
    move-result-object v1

    .line 52
    invoke-virtual {p0}, Landroid/content/res/Resources;->getConfiguration()Landroid/content/res/Configuration;

    .line 53
    .line 54
    .line 55
    move-result-object p0

    .line 56
    invoke-direct {p1, v0, v1, p0}, Landroid/content/res/Resources;-><init>(Landroid/content/res/AssetManager;Landroid/util/DisplayMetrics;Landroid/content/res/Configuration;)V

    .line 57
    .line 58
    .line 59
    return-object p1

    .line 60
    :cond_0
    return-object v0
.end method
