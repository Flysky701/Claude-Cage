.class public final Lio/github/leexeo/cage/space/GuestNetwork;
.super Ljava/lang/Object;
.source "GuestNetwork.java"


# static fields
.field private static final DIAGNOSTICS:Z = false

.field private static final HOST:Ljava/lang/String; = "top.niunaijun.microdem"

.field private static final callbacks:Landroid/os/HandlerThread;

.field private static final relays:Ljava/util/concurrent/ConcurrentHashMap;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/concurrent/ConcurrentHashMap<",
            "Landroid/os/IBinder;",
            "Landroid/os/Messenger;",
            ">;"
        }
    .end annotation
.end field


# direct methods
.method static constructor <clinit>()V
    .locals 2

    .line 14
    new-instance v0, Landroid/os/HandlerThread;

    const-string v1, "Cage-network-events"

    invoke-direct {v0, v1}, Landroid/os/HandlerThread;-><init>(Ljava/lang/String;)V

    sput-object v0, Lio/github/leexeo/cage/space/GuestNetwork;->callbacks:Landroid/os/HandlerThread;

    .line 15
    new-instance v0, Ljava/util/concurrent/ConcurrentHashMap;

    invoke-direct {v0}, Ljava/util/concurrent/ConcurrentHashMap;-><init>()V

    sput-object v0, Lio/github/leexeo/cage/space/GuestNetwork;->relays:Ljava/util/concurrent/ConcurrentHashMap;

    .line 16
    sget-object v0, Lio/github/leexeo/cage/space/GuestNetwork;->callbacks:Landroid/os/HandlerThread;

    invoke-virtual {v0}, Landroid/os/HandlerThread;->start()V

    return-void
.end method

.method public constructor <init>()V
    .locals 0

    .line 11
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static bind(Landroid/content/Context;Landroid/content/Context;)V
    .locals 9

    .line 114
    const-string v0, "org.apache.http.ProtocolVersion"

    const-string v1, "CageDemo"

    invoke-virtual {p1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v2

    .line 115
    const-string v3, "com.google.android.gms"

    invoke-virtual {v3, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    const-string v4, "com.android.vending"

    const-string v5, "com.anthropic.claude"

    if-nez v3, :cond_1

    invoke-virtual {v4, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-nez v3, :cond_1

    .line 116
    invoke-virtual {v5, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_0

    goto :goto_0

    .line 117
    :cond_0
    new-instance p0, Ljava/lang/SecurityException;

    const-string p1, "This DEMO only runs its Google and Claude apps"

    invoke-direct {p0, p1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 118
    :cond_1
    :goto_0
    invoke-virtual {v5, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_2

    .line 119
    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestSplits;->verify(Landroid/content/Context;)V

    goto :goto_1

    .line 122
    :cond_2
    :try_start_0
    new-instance v3, Lio/github/leexeo/cage/space/SpacePackages;

    invoke-direct {v3, p0}, Lio/github/leexeo/cage/space/SpacePackages;-><init>(Landroid/content/Context;)V

    .line 123
    invoke-virtual {v3, v2}, Lio/github/leexeo/cage/space/SpacePackages;->installed(Ljava/lang/String;)Landroid/content/pm/PackageInfo;

    move-result-object v2

    .line 124
    invoke-virtual {v3, v2}, Lio/github/leexeo/cage/space/SpacePackages;->privateCopy(Landroid/content/pm/PackageInfo;)Z

    move-result v3

    if-eqz v3, :cond_c

    .line 125
    new-instance v3, Ljava/io/File;

    iget-object v2, v2, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget-object v2, v2, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    invoke-direct {v3, v2}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/SpacePackages;->inspect(Landroid/content/Context;Ljava/io/File;)Landroid/content/pm/PackageInfo;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_4

    .line 126
    nop

    .line 128
    :goto_1
    nop

    .line 130
    const/4 v2, 0x1

    const/4 v3, 0x0

    :try_start_1
    invoke-static {p0}, Lio/github/leexeo/cage/space/SharedGateway;->status(Landroid/content/Context;)Landroid/os/Bundle;

    move-result-object v5

    .line 132
    if-eqz v5, :cond_3

    const-string v6, "protectionReady"

    invoke-virtual {v5, v6, v3}, Landroid/os/Bundle;->getBoolean(Ljava/lang/String;Z)Z

    move-result v5
    :try_end_1
    .catch Ljava/lang/RuntimeException; {:try_start_1 .. :try_end_1} :catch_0

    if-eqz v5, :cond_3

    move v5, v2

    goto :goto_2

    :cond_3
    move v5, v3

    .line 135
    :goto_2
    goto :goto_3

    .line 133
    :catch_0
    move-exception v5

    .line 134
    new-instance v6, Ljava/lang/StringBuilder;

    invoke-direct {v6}, Ljava/lang/StringBuilder;-><init>()V

    const-string v7, "Gateway state unavailable: "

    invoke-virtual {v6, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v6

    invoke-virtual {v5}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v6, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v5

    invoke-static {v1, v5}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    move v5, v3

    .line 136
    :goto_3
    if-eqz v5, :cond_b

    .line 142
    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    const-string v6, "System-network guest: "

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {p1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v6

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v5

    invoke-static {v1, v5}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 143
    invoke-static {p1}, Lio/github/leexeo/cage/space/GuestPackageIdentity;->prepare(Landroid/content/Context;)V

    .line 144
    invoke-static {p1}, Lio/github/leexeo/cage/space/GuestProfiles;->prepare(Landroid/content/Context;)V

    .line 145
    invoke-static {p1}, Lio/github/leexeo/cage/space/GuestIntegrityTrace;->identitySnapshot(Landroid/content/Context;)V

    .line 146
    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/GuestAccounts;->bind(Landroid/content/Context;Landroid/content/Context;)V

    .line 147
    invoke-virtual {p1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {v4, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_5

    .line 148
    invoke-virtual {p1}, Landroid/content/Context;->getClassLoader()Ljava/lang/ClassLoader;

    move-result-object p0

    .line 149
    :try_start_2
    invoke-static {v0, v3, p0}, Ljava/lang/Class;->forName(Ljava/lang/String;ZLjava/lang/ClassLoader;)Ljava/lang/Class;
    :try_end_2
    .catch Ljava/lang/ClassNotFoundException; {:try_start_2 .. :try_end_2} :catch_1

    .line 161
    goto :goto_4

    .line 150
    :catch_1
    move-exception v4

    .line 152
    :try_start_3
    const-string v4, "/system/framework/org.apache.http.legacy.jar"

    .line 153
    new-instance v5, Ljava/io/File;

    invoke-direct {v5, v4}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v5}, Ljava/io/File;->isFile()Z

    move-result v5

    if-eqz v5, :cond_4

    .line 154
    const-string v5, "dalvik.system.BaseDexClassLoader"

    invoke-static {v5}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v5

    const-string v6, "addDexPath"

    const-class v7, Ljava/lang/String;

    filled-new-array {v7}, [Ljava/lang/Class;

    move-result-object v7

    invoke-virtual {v5, v6, v7}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v5

    filled-new-array {v4}, [Ljava/lang/Object;

    move-result-object v4

    .line 155
    invoke-virtual {v5, p0, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 156
    invoke-static {v0, v3, p0}, Ljava/lang/Class;->forName(Ljava/lang/String;ZLjava/lang/ClassLoader;)Ljava/lang/Class;

    .line 157
    const-string p0, "Play system HTTP library loaded"

    invoke-static {v1, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 160
    goto :goto_4

    .line 153
    :cond_4
    new-instance p0, Ljava/lang/IllegalStateException;

    const-string p1, "System HTTP library missing"

    invoke-direct {p0, p1}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;)V

    throw p0
    :try_end_3
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_3 .. :try_end_3} :catch_2

    .line 158
    :catch_2
    move-exception p0

    .line 159
    new-instance p1, Ljava/lang/IllegalStateException;

    const-string v0, "Play system HTTP library unavailable"

    invoke-direct {p1, v0, p0}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw p1

    .line 187
    :cond_5
    :goto_4
    :try_start_4
    const-string p0, "connectivity"

    invoke-virtual {p1, p0}, Landroid/content/Context;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Landroid/net/ConnectivityManager;

    .line 188
    invoke-virtual {p0}, Landroid/net/ConnectivityManager;->getActiveNetwork()Landroid/net/Network;

    move-result-object v0

    .line 189
    invoke-virtual {p0, v0}, Landroid/net/ConnectivityManager;->getNetworkCapabilities(Landroid/net/Network;)Landroid/net/NetworkCapabilities;

    move-result-object v4

    .line 190
    invoke-virtual {p0}, Landroid/net/ConnectivityManager;->getActiveNetworkInfo()Landroid/net/NetworkInfo;

    move-result-object v5

    .line 191
    invoke-virtual {p0, v0}, Landroid/net/ConnectivityManager;->getLinkProperties(Landroid/net/Network;)Landroid/net/LinkProperties;

    move-result-object p0

    .line 192
    new-instance v6, Ljava/lang/StringBuilder;

    invoke-direct {v6}, Ljava/lang/StringBuilder;-><init>()V

    const-string v7, "guest_network active="

    invoke-virtual {v6, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v6

    if-eqz v0, :cond_6

    move v0, v2

    goto :goto_5

    :cond_6
    move v0, v3

    :goto_5
    invoke-virtual {v6, v0}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v6, " vpn="

    invoke-virtual {v0, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    if-eqz v4, :cond_7

    .line 193
    const/4 v6, 0x4

    invoke-virtual {v4, v6}, Landroid/net/NetworkCapabilities;->hasTransport(I)Z

    move-result v6

    if-eqz v6, :cond_7

    move v6, v2

    goto :goto_6

    :cond_7
    move v6, v3

    :goto_6
    invoke-virtual {v0, v6}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v6, " not_vpn="

    invoke-virtual {v0, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    if-eqz v4, :cond_8

    .line 194
    const/16 v6, 0xf

    invoke-virtual {v4, v6}, Landroid/net/NetworkCapabilities;->hasCapability(I)Z

    move-result v4

    if-eqz v4, :cond_8

    goto :goto_7

    :cond_8
    move v2, v3

    :goto_7
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v2, " legacy_type="

    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    .line 195
    const/4 v2, -0x1

    if-nez v5, :cond_9

    move v3, v2

    goto :goto_8

    :cond_9
    invoke-virtual {v5}, Landroid/net/NetworkInfo;->getType()I

    move-result v3

    :goto_8
    invoke-virtual {v0, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v3, " dns_count="

    invoke-virtual {v0, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    .line 196
    if-nez p0, :cond_a

    :goto_9
    goto :goto_a

    :cond_a
    invoke-virtual {p0}, Landroid/net/LinkProperties;->getDnsServers()Ljava/util/List;

    move-result-object p0

    invoke-interface {p0}, Ljava/util/List;->size()I

    move-result v2

    goto :goto_9

    :goto_a
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, " internet_permission="

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, "android.permission.INTERNET"

    .line 197
    invoke-virtual {p1, v0}, Landroid/content/Context;->checkSelfPermission(Ljava/lang/String;)I

    move-result v0

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, " network_state_permission="

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, "android.permission.ACCESS_NETWORK_STATE"

    .line 198
    invoke-virtual {p1, v0}, Landroid/content/Context;->checkSelfPermission(Ljava/lang/String;)I

    move-result p1

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    .line 192
    invoke-static {v1, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_4
    .catch Ljava/lang/RuntimeException; {:try_start_4 .. :try_end_4} :catch_3

    .line 199
    goto :goto_b

    :catch_3
    move-exception p0

    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "Network metadata check: "

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    invoke-static {v1, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 200
    :goto_b
    return-void

    .line 137
    :cond_b
    const-string p0, "Guest launch blocked: system network protection is not ready"

    invoke-static {v1, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 138
    invoke-static {}, Landroid/os/Process;->myPid()I

    move-result p0

    invoke-static {p0}, Landroid/os/Process;->killProcess(I)V

    .line 139
    new-instance p0, Ljava/lang/IllegalStateException;

    const-string p1, "Network protection is not ready"

    invoke-direct {p0, p1}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 124
    :cond_c
    :try_start_5
    new-instance p0, Ljava/lang/IllegalStateException;

    const-string p1, "Private guest package missing"

    invoke-direct {p0, p1}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;)V

    throw p0
    :try_end_5
    .catch Ljava/lang/Exception; {:try_start_5 .. :try_end_5} :catch_4

    .line 126
    :catch_4
    move-exception p0

    new-instance p1, Ljava/lang/SecurityException;

    const-string v0, "Guest signature unavailable"

    invoke-direct {p1, v0, p0}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw p1
.end method

.method public static invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Throwable;
        }
    .end annotation

    .line 35
    if-nez p2, :cond_0

    const/4 p2, 0x0

    goto :goto_0

    :cond_0
    invoke-virtual {p2}, [Ljava/lang/Object;->clone()Ljava/lang/Object;

    move-result-object p2

    check-cast p2, [Ljava/lang/Object;

    .line 36
    :goto_0
    if-eqz p2, :cond_4

    const/4 v0, 0x0

    :goto_1
    array-length v1, p2

    if-ge v0, v1, :cond_4

    .line 37
    aget-object v1, p2, v0

    .line 39
    instance-of v2, v1, Ljava/lang/String;

    if-eqz v2, :cond_2

    const-string v2, "com.google.android.gms"

    invoke-virtual {v1, v2}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_1

    const-string v2, "com.android.vending"

    invoke-virtual {v1, v2}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_1

    .line 40
    const-string v2, "com.anthropic.claude"

    invoke-virtual {v1, v2}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_1

    const-string v2, "io.github.leexeo.cage.stablenet"

    invoke-virtual {v1, v2}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_2

    :cond_1
    const-string v2, "top.niunaijun.microdem"

    aput-object v2, p2, v0

    .line 41
    :cond_2
    instance-of v2, v1, Landroid/os/Messenger;

    if-eqz v2, :cond_3

    check-cast v1, Landroid/os/Messenger;

    invoke-static {v1}, Lio/github/leexeo/cage/space/GuestNetwork;->relay(Landroid/os/Messenger;)Landroid/os/Messenger;

    move-result-object v1

    aput-object v1, p2, v0

    .line 36
    :cond_3
    add-int/lit8 v0, v0, 0x1

    goto :goto_1

    .line 43
    :cond_4
    :try_start_0
    invoke-virtual {p1, p0, p2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestNetwork;->sanitize(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0
    :try_end_0
    .catch Ljava/lang/reflect/InvocationTargetException; {:try_start_0 .. :try_end_0} :catch_0

    return-object p0

    .line 44
    :catch_0
    move-exception p0

    invoke-virtual {p0}, Ljava/lang/reflect/InvocationTargetException;->getCause()Ljava/lang/Throwable;

    move-result-object p0

    throw p0
.end method

.method private static synthetic lambda$bind$3()V
    .locals 6

    .line 165
    const-wide/16 v0, 0x3a98

    :try_start_0
    invoke-static {v0, v1}, Ljava/lang/Thread;->sleep(J)V
    :try_end_0
    .catch Ljava/lang/InterruptedException; {:try_start_0 .. :try_end_0} :catch_0

    .line 166
    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;

    move-result-object v0

    invoke-virtual {v0}, Landroid/os/Looper;->getThread()Ljava/lang/Thread;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/Thread;->getStackTrace()[Ljava/lang/StackTraceElement;

    move-result-object v0

    array-length v1, v0

    const/4 v2, 0x0

    :goto_0
    if-ge v2, v1, :cond_0

    aget-object v3, v0, v2

    .line 167
    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    const-string v5, "store_main: "

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    const-string v4, "CageDemo"

    invoke-static {v4, v3}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 166
    add-int/lit8 v2, v2, 0x1

    goto :goto_0

    .line 168
    :cond_0
    return-void

    .line 165
    :catch_0
    move-exception v0

    return-void
.end method

.method private static synthetic lambda$bind$4()V
    .locals 6

    .line 173
    const-string v0, "CageDemo"

    .line 175
    const/4 v1, 0x0

    :try_start_0
    new-instance v2, Ljava/net/URL;

    const-string v3, "https://accounts.google.com/"

    invoke-direct {v2, v3}, Ljava/net/URL;-><init>(Ljava/lang/String;)V

    invoke-virtual {v2}, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;

    move-result-object v2

    check-cast v2, Ljava/net/HttpURLConnection;
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_1
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 176
    const/16 v1, 0x1f40

    :try_start_1
    invoke-virtual {v2, v1}, Ljava/net/HttpURLConnection;->setConnectTimeout(I)V

    invoke-virtual {v2, v1}, Ljava/net/HttpURLConnection;->setReadTimeout(I)V

    .line 177
    const/4 v1, 0x0

    invoke-virtual {v2, v1}, Ljava/net/HttpURLConnection;->setUseCaches(Z)V

    invoke-virtual {v2, v1}, Ljava/net/HttpURLConnection;->setInstanceFollowRedirects(Z)V

    .line 178
    const-string v1, "HEAD"

    invoke-virtual {v2, v1}, Ljava/net/HttpURLConnection;->setRequestMethod(Ljava/lang/String;)V

    .line 179
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "guest_https_status="

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v2}, Ljava/net/HttpURLConnection;->getResponseCode()I

    move-result v3

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catch Ljava/io/IOException; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    .line 183
    if-eqz v2, :cond_1

    goto :goto_2

    .line 180
    :catch_0
    move-exception v1

    goto :goto_0

    .line 183
    :catchall_0
    move-exception v0

    goto :goto_3

    .line 180
    :catch_1
    move-exception v2

    move-object v5, v2

    move-object v2, v1

    move-object v1, v5

    .line 181
    :goto_0
    :try_start_2
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "guest_https_failure="

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v4

    invoke-virtual {v4}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object v4

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    const-string v4, "/"

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    .line 182
    invoke-virtual {v1}, Ljava/io/IOException;->getCause()Ljava/lang/Throwable;

    move-result-object v4

    if-nez v4, :cond_0

    const-string v1, "none"

    goto :goto_1

    :cond_0
    invoke-virtual {v1}, Ljava/io/IOException;->getCause()Ljava/lang/Throwable;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object v1

    :goto_1
    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    .line 181
    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    .line 183
    if-eqz v2, :cond_1

    :goto_2
    invoke-virtual {v2}, Ljava/net/HttpURLConnection;->disconnect()V

    .line 184
    :cond_1
    return-void

    .line 183
    :catchall_1
    move-exception v0

    move-object v1, v2

    :goto_3
    if-eqz v1, :cond_2

    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->disconnect()V

    :cond_2
    throw v0
.end method

.method static synthetic lambda$relay$0(Landroid/os/Messenger;Landroid/os/IBinder;Landroid/os/Message;)Z
    .locals 5

    .line 50
    invoke-static {p2}, Landroid/os/Message;->obtain(Landroid/os/Message;)Landroid/os/Message;

    move-result-object v0

    .line 51
    new-instance v1, Landroid/os/Bundle;

    invoke-virtual {p2}, Landroid/os/Message;->getData()Landroid/os/Bundle;

    move-result-object p2

    invoke-direct {v1, p2}, Landroid/os/Bundle;-><init>(Landroid/os/Bundle;)V

    .line 52
    const-class p2, Landroid/net/NetworkCapabilities;

    invoke-virtual {p2}, Ljava/lang/Class;->getClassLoader()Ljava/lang/ClassLoader;

    move-result-object p2

    invoke-virtual {v1, p2}, Landroid/os/Bundle;->setClassLoader(Ljava/lang/ClassLoader;)V

    .line 53
    invoke-virtual {v1}, Landroid/os/Bundle;->keySet()Ljava/util/Set;

    move-result-object p2

    invoke-interface {p2}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    move-result-object p2

    :goto_0
    invoke-interface {p2}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :cond_1

    invoke-interface {p2}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Ljava/lang/String;

    .line 54
    invoke-virtual {v1, v2}, Landroid/os/Bundle;->get(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v3

    invoke-static {v3}, Lio/github/leexeo/cage/space/GuestNetwork;->sanitize(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v4

    .line 55
    if-eq v4, v3, :cond_0

    instance-of v3, v4, Landroid/os/Parcelable;

    if-eqz v3, :cond_0

    check-cast v4, Landroid/os/Parcelable;

    invoke-virtual {v1, v2, v4}, Landroid/os/Bundle;->putParcelable(Ljava/lang/String;Landroid/os/Parcelable;)V

    .line 56
    :cond_0
    goto :goto_0

    .line 57
    :cond_1
    invoke-virtual {v0, v1}, Landroid/os/Message;->setData(Landroid/os/Bundle;)V

    .line 58
    :try_start_0
    invoke-virtual {p0, v0}, Landroid/os/Messenger;->send(Landroid/os/Message;)V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_1

    :catch_0
    move-exception p0

    sget-object p0, Lio/github/leexeo/cage/space/GuestNetwork;->relays:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {p0, p1}, Ljava/util/concurrent/ConcurrentHashMap;->remove(Ljava/lang/Object;)Ljava/lang/Object;

    .line 59
    :goto_1
    const/4 p0, 0x1

    return p0
.end method

.method static synthetic lambda$relay$1(Landroid/os/IBinder;)V
    .locals 1

    .line 61
    sget-object v0, Lio/github/leexeo/cage/space/GuestNetwork;->relays:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {v0, p0}, Ljava/util/concurrent/ConcurrentHashMap;->remove(Ljava/lang/Object;)Ljava/lang/Object;

    return-void
.end method

.method static synthetic lambda$relay$2(Landroid/os/Messenger;Landroid/os/IBinder;)Landroid/os/Messenger;
    .locals 4

    .line 49
    new-instance v0, Landroid/os/Messenger;

    new-instance v1, Landroid/os/Handler;

    sget-object v2, Lio/github/leexeo/cage/space/GuestNetwork;->callbacks:Landroid/os/HandlerThread;

    invoke-virtual {v2}, Landroid/os/HandlerThread;->getLooper()Landroid/os/Looper;

    move-result-object v2

    new-instance v3, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda0;

    invoke-direct {v3, p0, p1}, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda0;-><init>(Landroid/os/Messenger;Landroid/os/IBinder;)V

    invoke-direct {v1, v2, v3}, Landroid/os/Handler;-><init>(Landroid/os/Looper;Landroid/os/Handler$Callback;)V

    invoke-direct {v0, v1}, Landroid/os/Messenger;-><init>(Landroid/os/Handler;)V

    .line 61
    :try_start_0
    new-instance p0, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda1;

    invoke-direct {p0, p1}, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda1;-><init>(Landroid/os/IBinder;)V

    const/4 v1, 0x0

    invoke-interface {p1, p0, v1}, Landroid/os/IBinder;->linkToDeath(Landroid/os/IBinder$DeathRecipient;I)V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    :catch_0
    move-exception p0

    .line 62
    :goto_0
    return-object v0
.end method

.method private static relay(Landroid/os/Messenger;)Landroid/os/Messenger;
    .locals 3

    .line 48
    sget-object v0, Lio/github/leexeo/cage/space/GuestNetwork;->relays:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {p0}, Landroid/os/Messenger;->getBinder()Landroid/os/IBinder;

    move-result-object v1

    new-instance v2, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda2;

    invoke-direct {v2, p0}, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda2;-><init>(Landroid/os/Messenger;)V

    invoke-virtual {v0, v1, v2}, Ljava/util/concurrent/ConcurrentHashMap;->computeIfAbsent(Ljava/lang/Object;Ljava/util/function/Function;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Landroid/os/Messenger;

    return-object p0
.end method

.method private static sanitize(Ljava/lang/Object;)Ljava/lang/Object;
    .locals 7

    .line 67
    instance-of v0, p0, Landroid/net/NetworkCapabilities;

    const/4 v1, 0x0

    const/4 v2, 0x1

    const/4 v3, 0x0

    if-eqz v0, :cond_2

    .line 68
    new-instance v0, Landroid/net/NetworkCapabilities;

    check-cast p0, Landroid/net/NetworkCapabilities;

    invoke-direct {v0, p0}, Landroid/net/NetworkCapabilities;-><init>(Landroid/net/NetworkCapabilities;)V

    .line 69
    const/4 p0, 0x4

    invoke-virtual {v0, p0}, Landroid/net/NetworkCapabilities;->hasTransport(I)Z

    move-result v4

    if-eqz v4, :cond_1

    .line 71
    :try_start_0
    const-class v4, Landroid/net/NetworkCapabilities;

    const-string v5, "removeTransportType"

    sget-object v6, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v6}, [Ljava/lang/Class;

    move-result-object v6

    invoke-virtual {v4, v5, v6}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v4

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0

    filled-new-array {p0}, [Ljava/lang/Object;

    move-result-object p0

    invoke-virtual {v4, v0, p0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 72
    invoke-virtual {v0, v2}, Landroid/net/NetworkCapabilities;->hasTransport(I)Z

    move-result p0

    if-nez p0, :cond_0

    .line 73
    invoke-virtual {v0, v3}, Landroid/net/NetworkCapabilities;->hasTransport(I)Z

    move-result p0

    if-nez p0, :cond_0

    .line 74
    const-class p0, Landroid/net/NetworkCapabilities;

    const-string v3, "addTransportType"

    sget-object v4, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v4}, [Ljava/lang/Class;

    move-result-object v4

    invoke-virtual {p0, v3, v4}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    filled-new-array {v2}, [Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {p0, v0, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 75
    :cond_0
    const-class p0, Landroid/net/NetworkCapabilities;

    const-string v2, "addCapability"

    sget-object v3, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v3}, [Ljava/lang/Class;

    move-result-object v3

    invoke-virtual {p0, v2, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    const/16 v2, 0xf

    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    filled-new-array {v2}, [Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {p0, v0, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 76
    const-class p0, Landroid/net/NetworkCapabilities;

    const-string v2, "setTransportInfo"

    const-string v3, "android.net.TransportInfo"

    invoke-static {v3}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v3

    filled-new-array {v3}, [Ljava/lang/Class;

    move-result-object v3

    invoke-virtual {p0, v2, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    filled-new-array {v1}, [Ljava/lang/Object;

    move-result-object v1

    invoke-virtual {p0, v0, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_0

    .line 79
    goto :goto_0

    .line 77
    :catch_0
    move-exception p0

    .line 78
    new-instance v0, Ljava/lang/IllegalStateException;

    const-string v1, "Guest network metadata unavailable"

    invoke-direct {v0, v1, p0}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw v0

    .line 81
    :cond_1
    :goto_0
    return-object v0

    .line 83
    :cond_2
    instance-of v0, p0, Landroid/net/NetworkInfo;

    if-eqz v0, :cond_3

    .line 84
    move-object v0, p0

    check-cast v0, Landroid/net/NetworkInfo;

    .line 85
    invoke-virtual {v0}, Landroid/net/NetworkInfo;->getType()I

    move-result v4

    const/16 v5, 0x11

    if-ne v4, v5, :cond_3

    .line 86
    new-instance p0, Landroid/net/NetworkInfo;

    const-string v4, "WIFI"

    const-string v5, ""

    invoke-direct {p0, v2, v3, v4, v5}, Landroid/net/NetworkInfo;-><init>(IILjava/lang/String;Ljava/lang/String;)V

    .line 87
    invoke-virtual {v0}, Landroid/net/NetworkInfo;->getDetailedState()Landroid/net/NetworkInfo$DetailedState;

    move-result-object v2

    invoke-virtual {v0}, Landroid/net/NetworkInfo;->getReason()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {p0, v2, v3, v1}, Landroid/net/NetworkInfo;->setDetailedState(Landroid/net/NetworkInfo$DetailedState;Ljava/lang/String;Ljava/lang/String;)V

    .line 88
    :try_start_1
    const-class v1, Landroid/net/NetworkInfo;

    const-string v2, "setIsAvailable"

    sget-object v3, Ljava/lang/Boolean;->TYPE:Ljava/lang/Class;

    filled-new-array {v3}, [Ljava/lang/Class;

    move-result-object v3

    invoke-virtual {v1, v2, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    invoke-virtual {v0}, Landroid/net/NetworkInfo;->isAvailable()Z

    move-result v0

    invoke-static {v0}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object v0

    filled-new-array {v0}, [Ljava/lang/Object;

    move-result-object v0

    invoke-virtual {v1, p0, v0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    :try_end_1
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_1 .. :try_end_1} :catch_1

    .line 89
    nop

    .line 90
    return-object p0

    .line 89
    :catch_1
    move-exception p0

    new-instance v0, Ljava/lang/IllegalStateException;

    invoke-direct {v0, p0}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/Throwable;)V

    throw v0

    .line 93
    :cond_3
    instance-of v0, p0, [Landroid/net/NetworkInfo;

    if-eqz v0, :cond_5

    .line 94
    check-cast p0, [Landroid/net/NetworkInfo;

    invoke-virtual {p0}, [Landroid/net/NetworkInfo;->clone()Ljava/lang/Object;

    move-result-object p0

    check-cast p0, [Landroid/net/NetworkInfo;

    .line 95
    nop

    :goto_1
    array-length v0, p0

    if-ge v3, v0, :cond_4

    aget-object v0, p0, v3

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestNetwork;->sanitize(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/net/NetworkInfo;

    aput-object v0, p0, v3

    add-int/lit8 v3, v3, 0x1

    goto :goto_1

    .line 96
    :cond_4
    return-object p0

    .line 98
    :cond_5
    instance-of v0, p0, Landroid/net/LinkProperties;

    if-eqz v0, :cond_8

    .line 99
    invoke-static {}, Landroid/os/Parcel;->obtain()Landroid/os/Parcel;

    move-result-object v0

    .line 102
    :try_start_2
    check-cast p0, Landroid/net/LinkProperties;

    invoke-virtual {p0, v0, v3}, Landroid/net/LinkProperties;->writeToParcel(Landroid/os/Parcel;I)V

    .line 103
    invoke-virtual {v0, v3}, Landroid/os/Parcel;->setDataPosition(I)V

    .line 104
    sget-object p0, Landroid/net/LinkProperties;->CREATOR:Landroid/os/Parcelable$Creator;

    invoke-interface {p0, v0}, Landroid/os/Parcelable$Creator;->createFromParcel(Landroid/os/Parcel;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Landroid/net/LinkProperties;
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    .line 105
    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    .line 106
    invoke-virtual {p0}, Landroid/net/LinkProperties;->getInterfaceName()Ljava/lang/String;

    move-result-object v0

    .line 107
    if-eqz v0, :cond_7

    const-string v1, "tun"

    invoke-virtual {v0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    if-nez v1, :cond_6

    const-string v1, "ppp"

    invoke-virtual {v0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_7

    :cond_6
    const-string v0, "cage0"

    invoke-virtual {p0, v0}, Landroid/net/LinkProperties;->setInterfaceName(Ljava/lang/String;)V

    .line 108
    :cond_7
    return-object p0

    .line 105
    :catchall_0
    move-exception p0

    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    throw p0

    .line 110
    :cond_8
    return-object p0
.end method

.method public static selfPermission(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Throwable;
        }
    .end annotation

    .line 19
    const-string v0, "checkPermissionForDevice"

    invoke-virtual {p1}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    const/4 v1, 0x0

    if-eqz v0, :cond_3

    if-eqz p2, :cond_3

    array-length v0, p2

    const/4 v2, 0x4

    if-ne v0, v2, :cond_3

    const/4 v0, 0x1

    aget-object v2, p2, v0

    instance-of v2, v2, Ljava/lang/Integer;

    if-eqz v2, :cond_3

    const/4 v2, 0x2

    aget-object v3, p2, v2

    instance-of v3, v3, Ljava/lang/Integer;

    if-eqz v3, :cond_3

    aget-object v0, p2, v0

    check-cast v0, Ljava/lang/Integer;

    .line 21
    invoke-virtual {v0}, Ljava/lang/Integer;->intValue()I

    move-result v0

    invoke-static {}, Landroid/os/Process;->myPid()I

    move-result v3

    if-eq v0, v3, :cond_0

    goto :goto_0

    .line 22
    :cond_0
    const/4 v0, 0x0

    aget-object v3, p2, v0

    invoke-static {v3}, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;

    move-result-object v3

    .line 23
    const-string v4, "android.permission.INTERNET"

    invoke-virtual {v4, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-nez v4, :cond_1

    .line 24
    const-string v4, "android.permission.ACCESS_NETWORK_STATE"

    invoke-virtual {v4, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-nez v3, :cond_1

    return-object v1

    .line 25
    :cond_1
    const-string v3, "top.niunaijun.blackbox.app.BActivityThread"

    invoke-static {v3}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v3

    const-string v4, "getBUid"

    new-array v5, v0, [Ljava/lang/Class;

    invoke-virtual {v3, v4, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v3

    new-array v4, v0, [Ljava/lang/Object;

    invoke-virtual {v3, v1, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ljava/lang/Integer;

    invoke-virtual {v3}, Ljava/lang/Integer;->intValue()I

    move-result v3

    .line 26
    aget-object v4, p2, v2

    check-cast v4, Ljava/lang/Integer;

    invoke-virtual {v4}, Ljava/lang/Integer;->intValue()I

    move-result v4

    if-eq v4, v3, :cond_2

    return-object v1

    .line 27
    :cond_2
    invoke-virtual {p2}, [Ljava/lang/Object;->clone()Ljava/lang/Object;

    move-result-object p2

    check-cast p2, [Ljava/lang/Object;

    .line 28
    const-string v3, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v3}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v3

    const-string v4, "getHostUid"

    new-array v5, v0, [Ljava/lang/Class;

    invoke-virtual {v3, v4, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v3

    new-array v0, v0, [Ljava/lang/Object;

    invoke-virtual {v3, v1, v0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    aput-object v0, p2, v2

    .line 30
    :try_start_0
    invoke-virtual {p1, p0, p2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0
    :try_end_0
    .catch Ljava/lang/reflect/InvocationTargetException; {:try_start_0 .. :try_end_0} :catch_0

    return-object p0

    .line 31
    :catch_0
    move-exception p0

    invoke-virtual {p0}, Ljava/lang/reflect/InvocationTargetException;->getCause()Ljava/lang/Throwable;

    move-result-object p0

    throw p0

    .line 21
    :cond_3
    :goto_0
    return-object v1
.end method
