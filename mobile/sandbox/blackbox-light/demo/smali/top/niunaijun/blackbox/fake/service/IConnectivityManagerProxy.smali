.class public Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy;
.super Ltop/niunaijun/blackbox/fake/hook/BinderInvocationStub;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString19;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString18;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString17;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString16;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString15;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString14;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString13;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString12;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString11;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString10;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString9;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString8;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString7;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString6;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString5;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString4;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString3;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString2;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithString;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithInt;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfoWithNetwork;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$UnregisterNetworkCallback;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$RegisterNetworkCallbackWithRequest;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkForType;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$IsActiveNetworkMetered;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$RemoveDefaultNetworkActiveListener;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$AddDefaultNetworkActiveListener;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetActiveNetworkInfoForUid;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$RegisterDefaultNetworkCallback;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$RegisterNetworkCallback;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$RequestNetwork;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$IsNetworkValidated;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetDnsServers;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$IsPrivateDnsActive;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetPrivateDnsServerName;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetLinkProperties;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetActiveNetworkInfo;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetActiveNetwork;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkCapabilities;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetAllNetworks;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetAllNetworkInfo;,
        Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy$GetNetworkInfo;
    }
.end annotation

.annotation runtime Ltop/niunaijun/blackbox/fake/hook/ScanClass;
    value = {
        Ltop/niunaijun/blackbox/fake/service/VpnCommonProxy;
    }
.end annotation


# static fields
.field public static final TAG:Ljava/lang/String; = "IConnectivityManagerProxy"


# direct methods
.method public constructor <init>()V
    .locals 2

    .line 1
    invoke-static {}, Lh5/d;->a()Lblack/android/os/ServiceManagerStatic;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    const-string v1, "connectivity"

    .line 6
    .line 7
    invoke-interface {v0, v1}, Lblack/android/os/ServiceManagerStatic;->getService(Ljava/lang/String;)Landroid/os/IBinder;

    .line 8
    .line 9
    .line 10
    move-result-object v0

    .line 11
    invoke-direct {p0, v0}, Ltop/niunaijun/blackbox/fake/hook/BinderInvocationStub;-><init>(Landroid/os/IBinder;)V

    .line 12
    .line 13
    .line 14
    return-void
.end method

.method public static bridge synthetic a()Ljava/lang/Object;
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy;->createLinkProperties()Ljava/lang/Object;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    return-object v0
.end method

.method public static bridge synthetic b()Ljava/lang/Object;
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy;->createNetworkCapabilities()Ljava/lang/Object;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    return-object v0
.end method

.method public static bridge synthetic c()Ljava/lang/Object;
    .locals 4

    .line 1
    const-string v0, "WIFI"

    .line 2
    .line 3
    const-string v1, ""

    .line 4
    .line 5
    const/4 v2, 0x1

    .line 6
    const/4 v3, 0x0

    .line 7
    invoke-static {v2, v3, v0, v1}, Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy;->createNetworkInfo(IILjava/lang/String;Ljava/lang/String;)Ljava/lang/Object;

    .line 8
    .line 9
    .line 10
    move-result-object v0

    .line 11
    return-object v0
.end method

.method private static createLinkProperties()Ljava/lang/Object;
    .locals 8

    .line 1
    const-string v0, "IConnectivityManagerProxy"

    .line 2
    .line 3
    const-string v1, "Could not set DNS servers: "

    .line 4
    .line 5
    const/4 v2, 0x0

    .line 6
    :try_start_0
    const-string v3, "android.net.LinkProperties"

    .line 7
    .line 8
    invoke-static {v3}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    .line 9
    .line 10
    .line 11
    move-result-object v3

    .line 12
    invoke-virtual {v3, v2}, Ljava/lang/Class;->getDeclaredConstructor([Ljava/lang/Class;)Ljava/lang/reflect/Constructor;

    .line 13
    .line 14
    .line 15
    move-result-object v3

    .line 16
    const/4 v4, 0x1

    .line 17
    invoke-virtual {v3, v4}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 18
    .line 19
    .line 20
    invoke-virtual {v3, v2}, Ljava/lang/reflect/Constructor;->newInstance([Ljava/lang/Object;)Ljava/lang/Object;

    .line 21
    .line 22
    .line 23
    move-result-object v3

    .line 24
    new-instance v4, Ljava/util/ArrayList;

    .line 25
    .line 26
    invoke-direct {v4}, Ljava/util/ArrayList;-><init>()V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_1

    .line 27
    .line 28
    .line 29
    :try_start_1
    const-string v5, "8.8.8.8"

    .line 30
    .line 31
    invoke-static {v5}, Ljava/net/InetAddress;->getByName(Ljava/lang/String;)Ljava/net/InetAddress;

    .line 32
    .line 33
    .line 34
    move-result-object v5

    .line 35
    invoke-virtual {v4, v5}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    .line 36
    .line 37
    .line 38
    const-string v5, "8.8.4.4"

    .line 39
    .line 40
    invoke-static {v5}, Ljava/net/InetAddress;->getByName(Ljava/lang/String;)Ljava/net/InetAddress;

    .line 41
    .line 42
    .line 43
    move-result-object v5

    .line 44
    invoke-virtual {v4, v5}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    .line 45
    .line 46
    .line 47
    invoke-virtual {v3}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 48
    .line 49
    .line 50
    move-result-object v5

    .line 51
    const-string v6, "setDnsServers"

    .line 52
    .line 53
    const-class v7, Ljava/util/List;

    .line 54
    .line 55
    filled-new-array {v7}, [Ljava/lang/Class;

    .line 56
    .line 57
    .line 58
    move-result-object v7

    .line 59
    invoke-virtual {v5, v6, v7}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    .line 60
    .line 61
    .line 62
    move-result-object v5

    .line 63
    filled-new-array {v4}, [Ljava/lang/Object;

    .line 64
    .line 65
    .line 66
    move-result-object v4

    .line 67
    invoke-virtual {v5, v3, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 68
    .line 69
    .line 70
    return-object v3

    .line 71
    :catch_0
    move-exception v4

    .line 72
    :try_start_2
    new-instance v5, Ljava/lang/StringBuilder;

    .line 73
    .line 74
    invoke-direct {v5, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 75
    .line 76
    .line 77
    invoke-virtual {v4}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 78
    .line 79
    .line 80
    move-result-object v1

    .line 81
    invoke-virtual {v5, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 82
    .line 83
    .line 84
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 85
    .line 86
    .line 87
    move-result-object v1

    .line 88
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_1

    .line 89
    .line 90
    .line 91
    return-object v3

    .line 92
    :catch_1
    move-exception v1

    .line 93
    const-string v3, "Failed to create LinkProperties via reflection: "

    .line 94
    .line 95
    invoke-static {v3, v1, v0}, Landroidx/fragment/app/x0;->n(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 96
    .line 97
    .line 98
    return-object v2
.end method

.method private static createNetworkCapabilities()Ljava/lang/Object;
    .locals 10

    .line 1
    sget-object v0, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    .line 2
    .line 3
    const-string v1, "IConnectivityManagerProxy"

    .line 4
    .line 5
    const-string v2, "Could not add capabilities: "

    .line 6
    .line 7
    const-string v3, "Could not add transport types: "

    .line 8
    .line 9
    const/4 v4, 0x0

    .line 10
    :try_start_0
    const-string v5, "android.net.NetworkCapabilities"

    .line 11
    .line 12
    invoke-static {v5}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    .line 13
    .line 14
    .line 15
    move-result-object v5

    .line 16
    invoke-virtual {v5, v4}, Ljava/lang/Class;->getDeclaredConstructor([Ljava/lang/Class;)Ljava/lang/reflect/Constructor;

    .line 17
    .line 18
    .line 19
    move-result-object v5

    .line 20
    const/4 v6, 0x1

    .line 21
    invoke-virtual {v5, v6}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 22
    .line 23
    .line 24
    invoke-virtual {v5, v4}, Ljava/lang/reflect/Constructor;->newInstance([Ljava/lang/Object;)Ljava/lang/Object;

    .line 25
    .line 26
    .line 27
    move-result-object v5
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_2

    .line 28
    :try_start_1
    invoke-virtual {v5}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 29
    .line 30
    .line 31
    move-result-object v7

    .line 32
    const-string v8, "addTransportType"

    .line 33
    .line 34
    filled-new-array {v0}, [Ljava/lang/Class;

    .line 35
    .line 36
    .line 37
    move-result-object v9

    .line 38
    invoke-virtual {v7, v8, v9}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    .line 39
    .line 40
    .line 41
    move-result-object v7

    .line 42
    invoke-static {v6}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 43
    .line 44
    .line 45
    move-result-object v6

    .line 46
    filled-new-array {v6}, [Ljava/lang/Object;

    .line 47
    .line 48
    .line 49
    move-result-object v6

    .line 50
    invoke-virtual {v7, v5, v6}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 51
    .line 52
    .line 53
    const/4 v6, 0x0

    .line 54
    invoke-static {v6}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 55
    .line 56
    .line 57
    move-result-object v6

    .line 58
    filled-new-array {v6}, [Ljava/lang/Object;

    .line 59
    .line 60
    .line 61
    move-result-object v6

    .line 62
    invoke-virtual {v7, v5, v6}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 63
    .line 64
    .line 65
    goto :goto_0

    .line 66
    :catch_0
    move-exception v6

    .line 67
    :try_start_2
    new-instance v7, Ljava/lang/StringBuilder;

    .line 68
    .line 69
    invoke-direct {v7, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 70
    .line 71
    .line 72
    invoke-virtual {v6}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 73
    .line 74
    .line 75
    move-result-object v3

    .line 76
    invoke-virtual {v7, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 77
    .line 78
    .line 79
    invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 80
    .line 81
    .line 82
    move-result-object v3

    .line 83
    invoke-static {v1, v3}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_2

    .line 84
    .line 85
    .line 86
    :goto_0
    :try_start_3
    invoke-virtual {v5}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 87
    .line 88
    .line 89
    move-result-object v3

    .line 90
    const-string v6, "addCapability"

    .line 91
    .line 92
    filled-new-array {v0}, [Ljava/lang/Class;

    .line 93
    .line 94
    .line 95
    move-result-object v0

    .line 96
    invoke-virtual {v3, v6, v0}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    .line 97
    .line 98
    .line 99
    move-result-object v0

    .line 100
    const/16 v3, 0xc

    .line 101
    .line 102
    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 103
    .line 104
    .line 105
    move-result-object v3

    .line 106
    filled-new-array {v3}, [Ljava/lang/Object;

    .line 107
    .line 108
    .line 109
    move-result-object v3

    .line 110
    invoke-virtual {v0, v5, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 111
    .line 112
    .line 113
    const/16 v3, 0x10

    .line 114
    .line 115
    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 116
    .line 117
    .line 118
    move-result-object v3

    .line 119
    filled-new-array {v3}, [Ljava/lang/Object;

    .line 120
    .line 121
    .line 122
    move-result-object v3

    .line 123
    invoke-virtual {v0, v5, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 124
    .line 125
    .line 126
    const/16 v3, 0xe

    .line 127
    .line 128
    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 129
    .line 130
    .line 131
    move-result-object v3

    .line 132
    filled-new-array {v3}, [Ljava/lang/Object;

    .line 133
    .line 134
    .line 135
    move-result-object v3

    .line 136
    invoke-virtual {v0, v5, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 137
    .line 138
    .line 139
    const/16 v3, 0xd

    .line 140
    .line 141
    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 142
    .line 143
    .line 144
    move-result-object v3

    .line 145
    filled-new-array {v3}, [Ljava/lang/Object;

    .line 146
    .line 147
    .line 148
    move-result-object v3

    .line 149
    invoke-virtual {v0, v5, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 150
    .line 151
    .line 152
    const/16 v3, 0xf

    .line 153
    .line 154
    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 155
    .line 156
    .line 157
    move-result-object v3

    .line 158
    filled-new-array {v3}, [Ljava/lang/Object;

    .line 159
    .line 160
    .line 161
    move-result-object v3

    .line 162
    invoke-virtual {v0, v5, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 163
    .line 164
    .line 165
    const/16 v3, 0x14

    .line 166
    .line 167
    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 168
    .line 169
    .line 170
    move-result-object v3

    .line 171
    filled-new-array {v3}, [Ljava/lang/Object;

    .line 172
    .line 173
    .line 174
    move-result-object v3

    .line 175
    invoke-virtual {v0, v5, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_1

    .line 176
    .line 177
    .line 178
    goto :goto_1

    .line 179
    :catch_1
    move-exception v0

    .line 180
    :try_start_4
    new-instance v3, Ljava/lang/StringBuilder;

    .line 181
    .line 182
    invoke-direct {v3, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 183
    .line 184
    .line 185
    invoke-virtual {v0}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 186
    .line 187
    .line 188
    move-result-object v0

    .line 189
    invoke-virtual {v3, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 190
    .line 191
    .line 192
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 193
    .line 194
    .line 195
    move-result-object v0

    .line 196
    invoke-static {v1, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_4
    .catch Ljava/lang/Exception; {:try_start_4 .. :try_end_4} :catch_2

    .line 197
    .line 198
    .line 199
    :goto_1
    return-object v5

    .line 200
    :catch_2
    move-exception v0

    .line 201
    const-string v2, "Failed to create NetworkCapabilities via reflection: "

    .line 202
    .line 203
    invoke-static {v2, v0, v1}, Landroidx/fragment/app/x0;->n(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 204
    .line 205
    .line 206
    return-object v4
.end method

.method private static createNetworkInfo(IILjava/lang/String;Ljava/lang/String;)Ljava/lang/Object;
    .locals 7

    .line 1
    const-string v0, "IConnectivityManagerProxy"

    .line 2
    .line 3
    const-class v1, Ljava/lang/String;

    .line 4
    .line 5
    const-string v2, "Failed to create NetworkInfo via reflection: "

    .line 6
    .line 7
    const/4 v3, 0x0

    .line 8
    :try_start_0
    sget v4, Landroid/os/Build$VERSION;->SDK_INT:I

    .line 9
    .line 10
    const/16 v5, 0x1e

    .line 11
    .line 12
    if-lt v4, v5, :cond_0

    .line 13
    .line 14
    new-instance v1, Landroid/net/NetworkInfo;

    .line 15
    .line 16
    invoke-static {p0, p1, p2, p3}, Lm0/h1;->b(IILjava/lang/String;Ljava/lang/String;)Landroid/net/NetworkInfo;

    .line 17
    .line 18
    .line 19
    move-result-object p0

    .line 20
    sget-object p1, Landroid/net/NetworkInfo$DetailedState;->CONNECTED:Landroid/net/NetworkInfo$DetailedState;

    .line 21
    .line 22
    invoke-static {p0}, Lm0/h1;->d(Landroid/net/NetworkInfo;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 23
    .line 24
    .line 25
    return-object p0

    .line 26
    :catch_0
    move-exception p0

    .line 27
    goto :goto_0

    .line 28
    :cond_0
    :try_start_1
    const-string v4, "android.net.NetworkInfo"

    .line 29
    .line 30
    invoke-static {v4}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    .line 31
    .line 32
    .line 33
    move-result-object v4

    .line 34
    sget-object v5, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    .line 35
    .line 36
    filled-new-array {v5, v5, v1, v1}, [Ljava/lang/Class;

    .line 37
    .line 38
    .line 39
    move-result-object v5

    .line 40
    invoke-virtual {v4, v5}, Ljava/lang/Class;->getDeclaredConstructor([Ljava/lang/Class;)Ljava/lang/reflect/Constructor;

    .line 41
    .line 42
    .line 43
    move-result-object v5

    .line 44
    const/4 v6, 0x1

    .line 45
    invoke-virtual {v5, v6}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 46
    .line 47
    .line 48
    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 49
    .line 50
    .line 51
    move-result-object p0

    .line 52
    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 53
    .line 54
    .line 55
    move-result-object p1

    .line 56
    filled-new-array {p0, p1, p2, p3}, [Ljava/lang/Object;

    .line 57
    .line 58
    .line 59
    move-result-object p0

    .line 60
    invoke-virtual {v5, p0}, Ljava/lang/reflect/Constructor;->newInstance([Ljava/lang/Object;)Ljava/lang/Object;

    .line 61
    .line 62
    .line 63
    move-result-object p0

    .line 64
    const-string p1, "setDetailedState"

    .line 65
    .line 66
    const-class p2, Landroid/net/NetworkInfo$DetailedState;

    .line 67
    .line 68
    filled-new-array {p2, v1, v1}, [Ljava/lang/Class;

    .line 69
    .line 70
    .line 71
    move-result-object p2

    .line 72
    invoke-virtual {v4, p1, p2}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    .line 73
    .line 74
    .line 75
    move-result-object p1

    .line 76
    sget-object p2, Landroid/net/NetworkInfo$DetailedState;->CONNECTED:Landroid/net/NetworkInfo$DetailedState;

    .line 77
    .line 78
    filled-new-array {p2, v3, v3}, [Ljava/lang/Object;

    .line 79
    .line 80
    .line 81
    move-result-object p2

    .line 82
    invoke-virtual {p1, p0, p2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

    .line 83
    .line 84
    .line 85
    return-object p0

    .line 86
    :catch_1
    move-exception p0

    .line 87
    :try_start_2
    new-instance p1, Ljava/lang/StringBuilder;

    .line 88
    .line 89
    invoke-direct {p1, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 90
    .line 91
    .line 92
    invoke-virtual {p0}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 93
    .line 94
    .line 95
    move-result-object p0

    .line 96
    invoke-virtual {p1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 97
    .line 98
    .line 99
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 100
    .line 101
    .line 102
    move-result-object p0

    .line 103
    invoke-static {v0, p0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_0

    .line 104
    .line 105
    .line 106
    return-object v3

    .line 107
    :goto_0
    const-string p1, "Failed to create NetworkInfo: "

    .line 108
    .line 109
    invoke-static {p1, p0, v0}, Landroidx/fragment/app/x0;->k(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 110
    .line 111
    .line 112
    return-object v3
.end method

.method private static createNetworkInfoArray()Ljava/lang/Object;
    .locals 14

    .line 1
    const-string v0, "IConnectivityManagerProxy"

    .line 2
    .line 3
    const-class v1, Ljava/lang/String;

    .line 4
    .line 5
    const-string v2, "MOBILE"

    .line 6
    .line 7
    const-string v3, "WIFI"

    .line 8
    .line 9
    const-string v4, ""

    .line 10
    .line 11
    const/4 v5, 0x0

    .line 12
    invoke-static {v5}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 13
    .line 14
    .line 15
    move-result-object v6

    .line 16
    const-string v7, "Failed to create NetworkInfo array via reflection: "

    .line 17
    .line 18
    :try_start_0
    sget v8, Landroid/os/Build$VERSION;->SDK_INT:I

    .line 19
    .line 20
    const/16 v9, 0x1e

    .line 21
    .line 22
    if-lt v8, v9, :cond_0

    .line 23
    .line 24
    new-instance v1, Landroid/net/NetworkInfo;

    .line 25
    .line 26
    invoke-static {}, Lm0/h1;->a()Landroid/net/NetworkInfo;

    .line 27
    .line 28
    .line 29
    move-result-object v1

    .line 30
    sget-object v2, Landroid/net/NetworkInfo$DetailedState;->CONNECTED:Landroid/net/NetworkInfo$DetailedState;

    .line 31
    .line 32
    invoke-static {v1}, Lm0/h1;->d(Landroid/net/NetworkInfo;)V

    .line 33
    .line 34
    .line 35
    new-instance v2, Landroid/net/NetworkInfo;

    .line 36
    .line 37
    invoke-static {}, Lm0/h1;->g()Landroid/net/NetworkInfo;

    .line 38
    .line 39
    .line 40
    move-result-object v2

    .line 41
    invoke-static {v2}, Lm0/h1;->d(Landroid/net/NetworkInfo;)V

    .line 42
    .line 43
    .line 44
    filled-new-array {v1, v2}, [Landroid/net/NetworkInfo;

    .line 45
    .line 46
    .line 47
    move-result-object v0
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 48
    return-object v0

    .line 49
    :catch_0
    move-exception v1

    .line 50
    goto :goto_0

    .line 51
    :cond_0
    :try_start_1
    const-string v8, "android.net.NetworkInfo"

    .line 52
    .line 53
    invoke-static {v8}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    .line 54
    .line 55
    .line 56
    move-result-object v8

    .line 57
    sget-object v9, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    .line 58
    .line 59
    filled-new-array {v9, v9, v1, v1}, [Ljava/lang/Class;

    .line 60
    .line 61
    .line 62
    move-result-object v9

    .line 63
    invoke-virtual {v8, v9}, Ljava/lang/Class;->getDeclaredConstructor([Ljava/lang/Class;)Ljava/lang/reflect/Constructor;

    .line 64
    .line 65
    .line 66
    move-result-object v9

    .line 67
    const/4 v10, 0x1

    .line 68
    invoke-virtual {v9, v10}, Ljava/lang/reflect/AccessibleObject;->setAccessible(Z)V

    .line 69
    .line 70
    .line 71
    invoke-static {v10}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 72
    .line 73
    .line 74
    move-result-object v11

    .line 75
    filled-new-array {v11, v6, v3, v4}, [Ljava/lang/Object;

    .line 76
    .line 77
    .line 78
    move-result-object v3

    .line 79
    invoke-virtual {v9, v3}, Ljava/lang/reflect/Constructor;->newInstance([Ljava/lang/Object;)Ljava/lang/Object;

    .line 80
    .line 81
    .line 82
    move-result-object v3

    .line 83
    const-string v11, "setDetailedState"

    .line 84
    .line 85
    const-class v12, Landroid/net/NetworkInfo$DetailedState;

    .line 86
    .line 87
    filled-new-array {v12, v1, v1}, [Ljava/lang/Class;

    .line 88
    .line 89
    .line 90
    move-result-object v1

    .line 91
    invoke-virtual {v8, v11, v1}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    .line 92
    .line 93
    .line 94
    move-result-object v1

    .line 95
    sget-object v11, Landroid/net/NetworkInfo$DetailedState;->CONNECTED:Landroid/net/NetworkInfo$DetailedState;

    .line 96
    .line 97
    const/4 v12, 0x0

    .line 98
    filled-new-array {v11, v12, v12}, [Ljava/lang/Object;

    .line 99
    .line 100
    .line 101
    move-result-object v13

    .line 102
    invoke-virtual {v1, v3, v13}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 103
    .line 104
    .line 105
    filled-new-array {v6, v6, v2, v4}, [Ljava/lang/Object;

    .line 106
    .line 107
    .line 108
    move-result-object v2

    .line 109
    invoke-virtual {v9, v2}, Ljava/lang/reflect/Constructor;->newInstance([Ljava/lang/Object;)Ljava/lang/Object;

    .line 110
    .line 111
    .line 112
    move-result-object v2

    .line 113
    filled-new-array {v11, v12, v12}, [Ljava/lang/Object;

    .line 114
    .line 115
    .line 116
    move-result-object v4

    .line 117
    invoke-virtual {v1, v2, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 118
    .line 119
    .line 120
    const/4 v1, 0x2

    .line 121
    invoke-static {v8, v1}, Ljava/lang/reflect/Array;->newInstance(Ljava/lang/Class;I)Ljava/lang/Object;

    .line 122
    .line 123
    .line 124
    move-result-object v1

    .line 125
    check-cast v1, [Ljava/lang/Object;

    .line 126
    .line 127
    invoke-static {v1, v5, v3}, Ljava/lang/reflect/Array;->set(Ljava/lang/Object;ILjava/lang/Object;)V

    .line 128
    .line 129
    .line 130
    invoke-static {v1, v10, v2}, Ljava/lang/reflect/Array;->set(Ljava/lang/Object;ILjava/lang/Object;)V
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

    .line 131
    .line 132
    .line 133
    return-object v1

    .line 134
    :catch_1
    move-exception v1

    .line 135
    :try_start_2
    new-instance v2, Ljava/lang/StringBuilder;

    .line 136
    .line 137
    invoke-direct {v2, v7}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 138
    .line 139
    .line 140
    invoke-virtual {v1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 141
    .line 142
    .line 143
    move-result-object v1

    .line 144
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 145
    .line 146
    .line 147
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 148
    .line 149
    .line 150
    move-result-object v1

    .line 151
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 152
    .line 153
    .line 154
    new-array v0, v5, [Ljava/lang/Object;
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_0

    .line 155
    .line 156
    return-object v0

    .line 157
    :goto_0
    const-string v2, "Failed to create fallback NetworkInfo array: "

    .line 158
    .line 159
    invoke-static {v2, v1, v0}, Landroidx/fragment/app/x0;->k(Ljava/lang/String;Ljava/lang/Exception;Ljava/lang/String;)V

    .line 160
    .line 161
    .line 162
    new-array v0, v5, [Ljava/lang/Object;

    .line 163
    .line 164
    return-object v0
.end method

.method public static bridge synthetic d()Ljava/lang/Object;
    .locals 1

    .line 1
    invoke-static {}, Ltop/niunaijun/blackbox/fake/service/IConnectivityManagerProxy;->createNetworkInfoArray()Ljava/lang/Object;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    return-object v0
.end method


# virtual methods
.method public getWho()Ljava/lang/Object;
    .locals 3

    .line 1
    const/4 v0, 0x0

    .line 2
    const/4 v1, 0x0

    .line 3
    const-class v2, Lblack/android/net/IConnectivityManagerStubStatic;

    .line 4
    .line 5
    invoke-static {v2, v0, v1}, Ltop/niunaijun/blackreflection/BlackReflection;->create(Ljava/lang/Class;Ljava/lang/Object;Z)Ljava/lang/Object;

    .line 6
    .line 7
    .line 8
    move-result-object v0

    .line 9
    check-cast v0, Lblack/android/net/IConnectivityManagerStubStatic;

    .line 10
    .line 11
    invoke-static {}, Lh5/d;->a()Lblack/android/os/ServiceManagerStatic;

    .line 12
    .line 13
    .line 14
    move-result-object v1

    .line 15
    const-string v2, "connectivity"

    .line 16
    .line 17
    invoke-interface {v1, v2}, Lblack/android/os/ServiceManagerStatic;->getService(Ljava/lang/String;)Landroid/os/IBinder;

    .line 18
    .line 19
    .line 20
    move-result-object v1

    .line 21
    invoke-interface {v0, v1}, Lblack/android/net/IConnectivityManagerStubStatic;->asInterface(Landroid/os/IBinder;)Landroid/os/IInterface;

    .line 22
    .line 23
    .line 24
    move-result-object v0

    .line 25
    return-object v0
.end method

.method public inject(Ljava/lang/Object;Ljava/lang/Object;)V
    .locals 0

    .line 1
    const-string p1, "connectivity"

    .line 2
    .line 3
    invoke-virtual {p0, p1}, Ltop/niunaijun/blackbox/fake/hook/BinderInvocationStub;->replaceSystemService(Ljava/lang/String;)V

    .line 4
    .line 5
    .line 6
    return-void
.end method

.method public invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 1

    invoke-virtual {p0}, Ltop/niunaijun/blackbox/fake/hook/ClassInvocationStub;->getBase()Ljava/lang/Object;

    move-result-object v0

    invoke-static {v0, p2, p3}, Lio/github/leexeo/cage/space/GuestNetwork;->invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

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
