.class abstract Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;
.super Landroid/accounts/IAccountAuthenticatorResponse$Stub;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"

# interfaces
.implements Landroid/os/IBinder$DeathRecipient;
.implements Landroid/content/ServiceConnection;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x401
    name = "Session"
.end annotation


# instance fields
.field final mAccountName:Ljava/lang/String;

.field final mAccountType:Ljava/lang/String;

.field protected final mAccounts:Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

.field final mAuthDetailsRequired:Z

.field mAuthenticator:Landroid/accounts/IAccountAuthenticator;

.field final mCreationTime:J

.field final mExpectActivityLaunch:Z

.field private mNumErrors:I

.field private mNumRequestContinued:I

.field public mNumResults:I

.field mResponse:Landroid/accounts/IAccountManagerResponse;

.field private final mStripAuthTokenFromResult:Z

.field final mUpdateLastAuthenticatedTime:Z

.field final synthetic this$0:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;


# direct methods
.method public constructor <init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;ZZLjava/lang/String;Z)V
    .locals 10

    const/4 v9, 0x0

    move-object v0, p0

    move-object v1, p1

    move-object v2, p2

    move-object v3, p3

    move-object v4, p4

    move v5, p5

    move/from16 v6, p6

    move-object/from16 v7, p7

    move/from16 v8, p8

    .line 1
    invoke-direct/range {v0 .. v9}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;ZZLjava/lang/String;ZZ)V

    return-void
.end method

.method public constructor <init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;ZZLjava/lang/String;ZZ)V
    .locals 2

    .line 2
    iput-object p1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->this$0:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 3
    invoke-direct {p0}, Landroid/accounts/IAccountAuthenticatorResponse$Stub;-><init>()V

    const/4 v0, 0x0

    .line 4
    iput v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumResults:I

    .line 5
    iput v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumRequestContinued:I

    .line 6
    iput v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumErrors:I

    const/4 v1, 0x0

    .line 7
    iput-object v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAuthenticator:Landroid/accounts/IAccountAuthenticator;

    if-eqz p4, :cond_1

    .line 8
    iput-object p2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccounts:Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 9
    iput-boolean p6, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mStripAuthTokenFromResult:Z

    .line 10
    iput-object p3, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mResponse:Landroid/accounts/IAccountManagerResponse;

    .line 11
    iput-object p4, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccountType:Ljava/lang/String;

    .line 12
    iput-boolean p5, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mExpectActivityLaunch:Z

    .line 13
    invoke-static {}, Landroid/os/SystemClock;->elapsedRealtime()J

    move-result-wide p4

    iput-wide p4, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mCreationTime:J

    .line 14
    iput-object p7, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccountName:Ljava/lang/String;

    .line 15
    iput-boolean p8, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAuthDetailsRequired:Z

    .line 16
    iput-boolean p9, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mUpdateLastAuthenticatedTime:Z

    .line 17
    invoke-static {p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->e(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Ljava/util/LinkedHashMap;

    move-result-object p2

    monitor-enter p2

    .line 18
    :try_start_0
    invoke-static {p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->e(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Ljava/util/LinkedHashMap;

    move-result-object p1

    invoke-virtual {p0}, Ljava/lang/Object;->toString()Ljava/lang/String;

    move-result-object p4

    invoke-virtual {p1, p4, p0}, Ljava/util/AbstractMap;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 19
    monitor-exit p2
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    if-eqz p3, :cond_0

    .line 20
    :try_start_1
    invoke-interface {p3}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    move-result-object p1

    invoke-interface {p1, p0, v0}, Landroid/os/IBinder;->linkToDeath(Landroid/os/IBinder$DeathRecipient;I)V
    :try_end_1
    .catch Landroid/os/RemoteException; {:try_start_1 .. :try_end_1} :catch_0

    return-void

    .line 21
    :catch_0
    iput-object v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mResponse:Landroid/accounts/IAccountManagerResponse;

    .line 22
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->binderDied()V

    :cond_0
    return-void

    :catchall_0
    move-exception p1

    .line 23
    :try_start_2
    monitor-exit p2
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    throw p1

    .line 24
    :cond_1
    new-instance p1, Ljava/lang/IllegalArgumentException;

    const-string p2, "accountType is null"

    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

.method private bindToAuthenticator(Ljava/lang/String;)Z
    .locals 6

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->this$0:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 2
    .line 3
    invoke-static {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->a(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;

    .line 4
    .line 5
    .line 6
    move-result-object v0

    .line 7
    iget-object v0, v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;->authenticators:Ljava/util/Map;

    .line 8
    .line 9
    invoke-interface {v0, p1}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 10
    .line 11
    .line 12
    move-result-object v0

    .line 13
    check-cast v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorInfo;

    .line 14
    .line 15
    const/4 v1, 0x0

    .line 16
    const/4 v2, 0x2

    .line 17
    const-string v3, "AccountManagerService"

    .line 18
    .line 19
    if-nez v0, :cond_0

    .line 20
    .line 21
    invoke-static {v3, v2}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 22
    .line 23
    .line 24
    move-result v0

    .line 25
    if-eqz v0, :cond_2

    .line 26
    .line 27
    new-instance v0, Ljava/lang/StringBuilder;

    .line 28
    .line 29
    const-string v2, "there is no authenticator for "

    .line 30
    .line 31
    invoke-direct {v0, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 32
    .line 33
    .line 34
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 35
    .line 36
    .line 37
    const-string p1, ", bailing out"

    .line 38
    .line 39
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 40
    .line 41
    .line 42
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 43
    .line 44
    .line 45
    move-result-object p1

    .line 46
    invoke-static {v3, p1}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 47
    .line 48
    .line 49
    return v1

    .line 50
    :cond_0
    new-instance p1, Landroid/content/Intent;

    .line 51
    .line 52
    invoke-direct {p1}, Landroid/content/Intent;-><init>()V

    .line 53
    .line 54
    .line 55
    const-string v4, "android.accounts.AccountAuthenticator"

    .line 56
    .line 57
    invoke-virtual {p1, v4}, Landroid/content/Intent;->setAction(Ljava/lang/String;)Landroid/content/Intent;

    .line 58
    .line 59
    .line 60
    new-instance v4, Landroid/content/ComponentName;

    .line 61
    .line 62
    iget-object v0, v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorInfo;->serviceInfo:Landroid/content/pm/ServiceInfo;

    .line 63
    .line 64
    iget-object v5, v0, Landroid/content/pm/ServiceInfo;->packageName:Ljava/lang/String;

    .line 65
    .line 66
    iget-object v0, v0, Landroid/content/pm/ServiceInfo;->name:Ljava/lang/String;

    .line 67
    .line 68
    invoke-direct {v4, v5, v0}, Landroid/content/ComponentName;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    .line 69
    .line 70
    .line 71
    invoke-virtual {p1, v4}, Landroid/content/Intent;->setComponent(Landroid/content/ComponentName;)Landroid/content/Intent;

    .line 72
    .line 73
    .line 74
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccounts:Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 75
    .line 76
    iget v0, v0, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->userId:I

    .line 77
    .line 78
    const-string v5, "_B_|_UserId"

    .line 79
    .line 80
    invoke-virtual {p1, v5, v0}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;

    .line 81
    .line 82
    .line 83
    invoke-static {v3, v2}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 84
    .line 85
    .line 86
    move-result v0

    .line 87
    if-eqz v0, :cond_1

    .line 88
    .line 89
    new-instance v0, Ljava/lang/StringBuilder;

    .line 90
    .line 91
    const-string v5, "performing bindService to "

    .line 92
    .line 93
    invoke-direct {v0, v5}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 94
    .line 95
    .line 96
    invoke-virtual {v0, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 97
    .line 98
    .line 99
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 100
    .line 101
    .line 102
    move-result-object v0

    .line 103
    invoke-static {v3, v0}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 104
    .line 105
    .line 106
    :cond_1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->this$0:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 107
    .line 108
    invoke-static {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->b(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Landroid/content/Context;

    .line 109
    .line 110
    .line 111
    move-result-object v0

    .line 112
    const/4 v5, 0x1

    .line 113
    invoke-virtual {v0, p1, p0, v5}, Landroid/content/Context;->bindService(Landroid/content/Intent;Landroid/content/ServiceConnection;I)Z

    .line 114
    .line 115
    .line 116
    move-result p1

    .line 117
    if-nez p1, :cond_3

    .line 118
    .line 119
    invoke-static {v3, v2}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 120
    .line 121
    .line 122
    move-result p1

    .line 123
    if-eqz p1, :cond_2

    .line 124
    .line 125
    new-instance p1, Ljava/lang/StringBuilder;

    .line 126
    .line 127
    const-string v0, "bindService to "

    .line 128
    .line 129
    invoke-direct {p1, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 130
    .line 131
    .line 132
    invoke-virtual {p1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 133
    .line 134
    .line 135
    const-string v0, " failed"

    .line 136
    .line 137
    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 138
    .line 139
    .line 140
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 141
    .line 142
    .line 143
    move-result-object p1

    .line 144
    invoke-static {v3, p1}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 145
    .line 146
    .line 147
    :cond_2
    return v1

    .line 148
    :cond_3
    return v5
.end method

.method private close()V
    .locals 3

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->this$0:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 2
    .line 3
    invoke-static {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->e(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Ljava/util/LinkedHashMap;

    .line 4
    .line 5
    .line 6
    move-result-object v0

    .line 7
    monitor-enter v0

    .line 8
    :try_start_0
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->this$0:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 9
    .line 10
    invoke-static {v1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->e(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Ljava/util/LinkedHashMap;

    .line 11
    .line 12
    .line 13
    move-result-object v1

    .line 14
    invoke-virtual {p0}, Ljava/lang/Object;->toString()Ljava/lang/String;

    .line 15
    .line 16
    .line 17
    move-result-object v2

    .line 18
    invoke-virtual {v1, v2}, Ljava/util/AbstractMap;->remove(Ljava/lang/Object;)Ljava/lang/Object;

    .line 19
    .line 20
    .line 21
    move-result-object v1

    .line 22
    if-nez v1, :cond_0

    .line 23
    .line 24
    monitor-exit v0

    .line 25
    return-void

    .line 26
    :catchall_0
    move-exception v1

    .line 27
    goto :goto_0

    .line 28
    :cond_0
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 29
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mResponse:Landroid/accounts/IAccountManagerResponse;

    .line 30
    .line 31
    if-eqz v0, :cond_1

    .line 32
    .line 33
    invoke-interface {v0}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    .line 34
    .line 35
    .line 36
    move-result-object v0

    .line 37
    const/4 v1, 0x0

    .line 38
    invoke-interface {v0, p0, v1}, Landroid/os/IBinder;->unlinkToDeath(Landroid/os/IBinder$DeathRecipient;I)Z

    .line 39
    .line 40
    .line 41
    const/4 v0, 0x0

    .line 42
    iput-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mResponse:Landroid/accounts/IAccountManagerResponse;

    .line 43
    .line 44
    :cond_1
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->cancelTimeout()V

    .line 45
    .line 46
    .line 47
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->unbind()V

    .line 48
    .line 49
    .line 50
    return-void

    .line 51
    :goto_0
    :try_start_1
    monitor-exit v0
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 52
    throw v1
.end method

.method private unbind()V
    .locals 1

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAuthenticator:Landroid/accounts/IAccountAuthenticator;

    .line 2
    .line 3
    if-eqz v0, :cond_0

    .line 4
    .line 5
    const/4 v0, 0x0

    .line 6
    iput-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAuthenticator:Landroid/accounts/IAccountAuthenticator;

    .line 7
    .line 8
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->this$0:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 9
    .line 10
    invoke-static {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->b(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Landroid/content/Context;

    .line 11
    .line 12
    .line 13
    move-result-object v0

    .line 14
    invoke-virtual {v0, p0}, Landroid/content/Context;->unbindService(Landroid/content/ServiceConnection;)V

    .line 15
    .line 16
    .line 17
    :cond_0
    return-void
.end method


# virtual methods
.method public bind()V
    .locals 3

    .line 1
    const/4 v0, 0x2

    .line 2
    const-string v1, "AccountManagerService"

    .line 3
    .line 4
    invoke-static {v1, v0}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 5
    .line 6
    .line 7
    move-result v0

    .line 8
    if-eqz v0, :cond_0

    .line 9
    .line 10
    new-instance v0, Ljava/lang/StringBuilder;

    .line 11
    .line 12
    const-string v2, "initiating bind to authenticator type "

    .line 13
    .line 14
    invoke-direct {v0, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 15
    .line 16
    .line 17
    iget-object v2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccountType:Ljava/lang/String;

    .line 18
    .line 19
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 20
    .line 21
    .line 22
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 23
    .line 24
    .line 25
    move-result-object v0

    .line 26
    invoke-static {v1, v0}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 27
    .line 28
    .line 29
    :cond_0
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccountType:Ljava/lang/String;

    .line 30
    .line 31
    invoke-direct {p0, v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->bindToAuthenticator(Ljava/lang/String;)Z

    .line 32
    .line 33
    .line 34
    move-result v0

    .line 35
    if-nez v0, :cond_1

    .line 36
    .line 37
    new-instance v0, Ljava/lang/StringBuilder;

    .line 38
    .line 39
    const-string v2, "bind attempt failed for "

    .line 40
    .line 41
    invoke-direct {v0, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 42
    .line 43
    .line 44
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->toDebugString()Ljava/lang/String;

    .line 45
    .line 46
    .line 47
    move-result-object v2

    .line 48
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 49
    .line 50
    .line 51
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 52
    .line 53
    .line 54
    move-result-object v0

    .line 55
    invoke-static {v1, v0}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 56
    .line 57
    .line 58
    const/4 v0, 0x1

    .line 59
    const-string v1, "bind failure"

    .line 60
    .line 61
    invoke-virtual {p0, v0, v1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->onError(ILjava/lang/String;)V

    .line 62
    .line 63
    .line 64
    :cond_1
    return-void
.end method

.method public binderDied()V
    .locals 1

    .line 1
    const/4 v0, 0x0

    .line 2
    iput-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mResponse:Landroid/accounts/IAccountManagerResponse;

    .line 3
    .line 4
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->close()V

    .line 5
    .line 6
    .line 7
    return-void
.end method

.method public cancelTimeout()V
    .locals 2

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->this$0:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 2
    .line 3
    invoke-static {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->c(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Landroid/os/Handler;

    .line 4
    .line 5
    .line 6
    move-result-object v0

    .line 7
    const/4 v1, 0x3

    .line 8
    invoke-virtual {v0, v1, p0}, Landroid/os/Handler;->removeMessages(ILjava/lang/Object;)V

    .line 9
    .line 10
    .line 11
    return-void
.end method

.method public checkKeyIntent(ILandroid/content/Intent;)Z
    .locals 5

    .line 1
    invoke-virtual {p2}, Landroid/content/Intent;->getClipData()Landroid/content/ClipData;

    .line 2
    .line 3
    .line 4
    move-result-object p1

    .line 5
    const/4 v0, 0x0

    .line 6
    if-nez p1, :cond_0

    .line 7
    .line 8
    invoke-static {v0, v0}, Landroid/content/ClipData;->newPlainText(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Landroid/content/ClipData;

    .line 9
    .line 10
    .line 11
    move-result-object p1

    .line 12
    invoke-virtual {p2, p1}, Landroid/content/Intent;->setClipData(Landroid/content/ClipData;)V

    .line 13
    .line 14
    .line 15
    :cond_0
    invoke-virtual {p2}, Landroid/content/Intent;->getFlags()I

    .line 16
    .line 17
    .line 18
    move-result p1

    .line 19
    and-int/lit16 p1, p1, -0xc4

    .line 20
    .line 21
    invoke-virtual {p2, p1}, Landroid/content/Intent;->setFlags(I)Landroid/content/Intent;

    .line 22
    .line 23
    .line 24
    invoke-static {}, Landroid/os/Binder;->clearCallingIdentity()J

    .line 25
    .line 26
    .line 27
    move-result-wide v1

    .line 28
    :try_start_0
    iget-object p1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->this$0:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 29
    .line 30
    invoke-static {p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->d(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;

    .line 31
    .line 32
    .line 33
    move-result-object p1

    .line 34
    iget-object v3, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccounts:Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 35
    .line 36
    iget v3, v3, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->userId:I

    .line 37
    .line 38
    const/4 v4, 0x0

    .line 39
    invoke-virtual {p1, p2, v4, v0, v3}, Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;->resolveActivity(Landroid/content/Intent;ILjava/lang/String;I)Landroid/content/pm/ResolveInfo;

    .line 40
    .line 41
    .line 42
    move-result-object p1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 43
    if-nez p1, :cond_1

    .line 44
    .line 45
    invoke-static {v1, v2}, Landroid/os/Binder;->restoreCallingIdentity(J)V

    .line 46
    .line 47
    .line 48
    return v4

    .line 49
    :cond_1
    invoke-static {v1, v2}, Landroid/os/Binder;->restoreCallingIdentity(J)V

    .line 50
    .line 51
    .line 52
    const/4 p1, 0x1

    .line 53
    return p1

    .line 54
    :catchall_0
    move-exception p1

    .line 55
    invoke-static {v1, v2}, Landroid/os/Binder;->restoreCallingIdentity(J)V

    .line 56
    .line 57
    .line 58
    throw p1
.end method

.method public getResponseAndClose()Landroid/accounts/IAccountManagerResponse;
    .locals 1

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mResponse:Landroid/accounts/IAccountManagerResponse;

    .line 2
    .line 3
    if-nez v0, :cond_0

    .line 4
    .line 5
    const/4 v0, 0x0

    .line 6
    return-object v0

    .line 7
    :cond_0
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->close()V

    .line 8
    .line 9
    .line 10
    return-object v0
.end method

.method public onError(ILjava/lang/String;)V
    .locals 5

    .line 1
    iget v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumErrors:I

    .line 2
    .line 3
    add-int/lit8 v0, v0, 0x1

    .line 4
    .line 5
    iput v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumErrors:I

    .line 6
    .line 7
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->getResponseAndClose()Landroid/accounts/IAccountManagerResponse;

    .line 8
    .line 9
    .line 10
    move-result-object v0

    .line 11
    const/4 v1, 0x2

    .line 12
    const-string v2, "AccountManagerService"

    .line 13
    .line 14
    if-eqz v0, :cond_1

    .line 15
    .line 16
    invoke-static {v2, v1}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 17
    .line 18
    .line 19
    move-result v3

    .line 20
    if-eqz v3, :cond_0

    .line 21
    .line 22
    new-instance v3, Ljava/lang/StringBuilder;

    .line 23
    .line 24
    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    .line 25
    .line 26
    .line 27
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 28
    .line 29
    .line 30
    move-result-object v4

    .line 31
    invoke-virtual {v4}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    .line 32
    .line 33
    .line 34
    move-result-object v4

    .line 35
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 36
    .line 37
    .line 38
    const-string v4, " calling onError() on response "

    .line 39
    .line 40
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 41
    .line 42
    .line 43
    invoke-virtual {v3, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 44
    .line 45
    .line 46
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 47
    .line 48
    .line 49
    move-result-object v3

    .line 50
    invoke-static {v2, v3}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 51
    .line 52
    .line 53
    :cond_0
    :try_start_0
    invoke-interface {v0, p1, p2}, Landroid/accounts/IAccountManagerResponse;->onError(ILjava/lang/String;)V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    .line 54
    .line 55
    .line 56
    return-void

    .line 57
    :catch_0
    move-exception p1

    .line 58
    invoke-static {v2, v1}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 59
    .line 60
    .line 61
    move-result p2

    .line 62
    if-eqz p2, :cond_2

    .line 63
    .line 64
    const-string p2, "Session.onError: caught RemoteException while responding"

    .line 65
    .line 66
    invoke-static {v2, p2, p1}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 67
    .line 68
    .line 69
    goto :goto_0

    .line 70
    :cond_1
    invoke-static {v2, v1}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 71
    .line 72
    .line 73
    move-result p1

    .line 74
    if-eqz p1, :cond_2

    .line 75
    .line 76
    const-string p1, "Session.onError: already closed"

    .line 77
    .line 78
    invoke-static {v2, p1}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 79
    .line 80
    .line 81
    :cond_2
    :goto_0
    return-void
.end method

.method public onRequestContinued()V
    .locals 1

    .line 1
    iget v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumRequestContinued:I

    .line 2
    .line 3
    add-int/lit8 v0, v0, 0x1

    .line 4
    .line 5
    iput v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumRequestContinued:I

    .line 6
    .line 7
    return-void
.end method

.method public onResult(Landroid/os/Bundle;)V
    .locals 9

    .line 1
    const-string v0, "errorCode"

    .line 2
    .line 3
    iget v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumResults:I

    .line 4
    .line 5
    const/4 v2, 0x1

    .line 6
    add-int/2addr v1, v2

    .line 7
    iput v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumResults:I

    .line 8
    .line 9
    const-string v1, "accountType"

    .line 10
    .line 11
    const-string v3, "authAccount"

    .line 12
    .line 13
    if-eqz p1, :cond_6

    .line 14
    .line 15
    const-string v4, "booleanResult"

    .line 16
    .line 17
    const/4 v5, 0x0

    .line 18
    invoke-virtual {p1, v4, v5}, Landroid/os/BaseBundle;->getBoolean(Ljava/lang/String;Z)Z

    .line 19
    .line 20
    .line 21
    move-result v4

    .line 22
    invoke-virtual {p1, v3}, Landroid/os/BaseBundle;->containsKey(Ljava/lang/String;)Z

    .line 23
    .line 24
    .line 25
    move-result v6

    .line 26
    if-eqz v6, :cond_0

    .line 27
    .line 28
    invoke-virtual {p1, v1}, Landroid/os/BaseBundle;->containsKey(Ljava/lang/String;)Z

    .line 29
    .line 30
    .line 31
    move-result v6

    .line 32
    if-eqz v6, :cond_0

    .line 33
    .line 34
    move v6, v2

    .line 35
    goto :goto_0

    .line 36
    :cond_0
    move v6, v5

    .line 37
    :goto_0
    iget-boolean v7, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mUpdateLastAuthenticatedTime:Z

    .line 38
    .line 39
    if-eqz v7, :cond_1

    .line 40
    .line 41
    if-nez v4, :cond_2

    .line 42
    .line 43
    if-eqz v6, :cond_1

    .line 44
    .line 45
    goto :goto_1

    .line 46
    :cond_1
    move v2, v5

    .line 47
    :cond_2
    :goto_1
    if-nez v2, :cond_3

    .line 48
    .line 49
    iget-boolean v4, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAuthDetailsRequired:Z

    .line 50
    .line 51
    if-eqz v4, :cond_6

    .line 52
    .line 53
    :cond_3
    iget-object v4, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->this$0:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 54
    .line 55
    iget-object v5, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccountName:Ljava/lang/String;

    .line 56
    .line 57
    iget-object v6, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccountType:Ljava/lang/String;

    .line 58
    .line 59
    iget-object v7, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccounts:Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 60
    .line 61
    iget v7, v7, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->userId:I

    .line 62
    .line 63
    invoke-static {v4, v5, v6, v7}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->h(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ljava/lang/String;Ljava/lang/String;I)Z

    .line 64
    .line 65
    .line 66
    move-result v4

    .line 67
    if-eqz v2, :cond_4

    .line 68
    .line 69
    if-eqz v4, :cond_4

    .line 70
    .line 71
    iget-object v2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->this$0:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 72
    .line 73
    iget-object v5, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccounts:Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 74
    .line 75
    new-instance v6, Landroid/accounts/Account;

    .line 76
    .line 77
    iget-object v7, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccountName:Ljava/lang/String;

    .line 78
    .line 79
    iget-object v8, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccountType:Ljava/lang/String;

    .line 80
    .line 81
    invoke-direct {v6, v7, v8}, Landroid/accounts/Account;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    .line 82
    .line 83
    .line 84
    invoke-static {v2, v5, v6}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->j(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;)V

    .line 85
    .line 86
    .line 87
    :cond_4
    iget-boolean v2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAuthDetailsRequired:Z

    .line 88
    .line 89
    if-eqz v2, :cond_6

    .line 90
    .line 91
    if-eqz v4, :cond_5

    .line 92
    .line 93
    iget-object v2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccounts:Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 94
    .line 95
    new-instance v4, Landroid/accounts/Account;

    .line 96
    .line 97
    iget-object v5, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccountName:Ljava/lang/String;

    .line 98
    .line 99
    iget-object v6, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAccountType:Ljava/lang/String;

    .line 100
    .line 101
    invoke-direct {v4, v5, v6}, Landroid/accounts/Account;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    .line 102
    .line 103
    .line 104
    invoke-virtual {v2, v4}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->findAccountLastAuthenticatedTime(Landroid/accounts/Account;)J

    .line 105
    .line 106
    .line 107
    move-result-wide v4

    .line 108
    goto :goto_2

    .line 109
    :cond_5
    const-wide/16 v4, -0x1

    .line 110
    .line 111
    :goto_2
    const-string v2, "lastAuthenticatedTime"

    .line 112
    .line 113
    invoke-virtual {p1, v2, v4, v5}, Landroid/os/BaseBundle;->putLong(Ljava/lang/String;J)V

    .line 114
    .line 115
    .line 116
    :cond_6
    const/4 v2, 0x5

    .line 117
    const-string v4, "intent"

    .line 118
    .line 119
    if-eqz p1, :cond_7

    .line 120
    .line 121
    invoke-virtual {p1, v4}, Landroid/os/Bundle;->getParcelable(Ljava/lang/String;)Landroid/os/Parcelable;

    .line 122
    .line 123
    .line 124
    move-result-object v5

    .line 125
    check-cast v5, Landroid/content/Intent;

    .line 126
    .line 127
    if-eqz v5, :cond_8

    .line 128
    .line 129
    invoke-static {}, Landroid/os/Binder;->getCallingUid()I

    .line 130
    .line 131
    .line 132
    move-result v6

    .line 133
    invoke-virtual {p0, v6, v5}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->checkKeyIntent(ILandroid/content/Intent;)Z

    .line 134
    .line 135
    .line 136
    move-result v6

    .line 137
    if-nez v6, :cond_8

    .line 138
    .line 139
    const-string p1, "invalid intent in bundle returned"

    .line 140
    .line 141
    invoke-virtual {p0, v2, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->onError(ILjava/lang/String;)V

    .line 142
    .line 143
    .line 144
    return-void

    .line 145
    :cond_7
    const/4 v5, 0x0

    .line 146
    :cond_8
    const-string v6, "authtoken"

    .line 147
    .line 148
    if-eqz p1, :cond_9

    .line 149
    .line 150
    invoke-virtual {p1, v6}, Landroid/os/BaseBundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    .line 151
    .line 152
    .line 153
    move-result-object v7

    .line 154
    invoke-static {v7}, Landroid/text/TextUtils;->isEmpty(Ljava/lang/CharSequence;)Z

    .line 155
    .line 156
    .line 157
    move-result v7

    .line 158
    if-nez v7, :cond_9

    .line 159
    .line 160
    invoke-virtual {p1, v3}, Landroid/os/BaseBundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    .line 161
    .line 162
    .line 163
    move-result-object v3

    .line 164
    invoke-virtual {p1, v1}, Landroid/os/BaseBundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    .line 165
    .line 166
    .line 167
    move-result-object v1

    .line 168
    invoke-static {v3}, Landroid/text/TextUtils;->isEmpty(Ljava/lang/CharSequence;)Z

    .line 169
    .line 170
    .line 171
    move-result v7

    .line 172
    if-nez v7, :cond_9

    .line 173
    .line 174
    invoke-static {v1}, Landroid/text/TextUtils;->isEmpty(Ljava/lang/CharSequence;)Z

    .line 175
    .line 176
    .line 177
    move-result v7

    .line 178
    if-nez v7, :cond_9

    .line 179
    .line 180
    new-instance v7, Landroid/accounts/Account;

    .line 181
    .line 182
    invoke-direct {v7, v3, v1}, Landroid/accounts/Account;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    .line 183
    .line 184
    .line 185
    :cond_9
    iget-boolean v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mExpectActivityLaunch:Z

    .line 186
    .line 187
    if-eqz v1, :cond_a

    .line 188
    .line 189
    if-eqz p1, :cond_a

    .line 190
    .line 191
    invoke-virtual {p1, v4}, Landroid/os/BaseBundle;->containsKey(Ljava/lang/String;)Z

    .line 192
    .line 193
    .line 194
    move-result v1

    .line 195
    if-eqz v1, :cond_a

    .line 196
    .line 197
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mResponse:Landroid/accounts/IAccountManagerResponse;

    .line 198
    .line 199
    goto :goto_3

    .line 200
    :cond_a
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->getResponseAndClose()Landroid/accounts/IAccountManagerResponse;

    .line 201
    .line 202
    .line 203
    move-result-object v1

    .line 204
    :goto_3
    if-eqz v1, :cond_10

    .line 205
    .line 206
    const/4 v3, 0x2

    .line 207
    const-string v4, "AccountManagerService"

    .line 208
    .line 209
    if-nez p1, :cond_c

    .line 210
    .line 211
    :try_start_0
    invoke-static {v4, v3}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 212
    .line 213
    .line 214
    move-result p1

    .line 215
    if-eqz p1, :cond_b

    .line 216
    .line 217
    new-instance p1, Ljava/lang/StringBuilder;

    .line 218
    .line 219
    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    .line 220
    .line 221
    .line 222
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 223
    .line 224
    .line 225
    move-result-object v0

    .line 226
    invoke-virtual {v0}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    .line 227
    .line 228
    .line 229
    move-result-object v0

    .line 230
    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 231
    .line 232
    .line 233
    const-string v0, " calling onError() on response "

    .line 234
    .line 235
    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 236
    .line 237
    .line 238
    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 239
    .line 240
    .line 241
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 242
    .line 243
    .line 244
    move-result-object p1

    .line 245
    invoke-static {v4, p1}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 246
    .line 247
    .line 248
    goto :goto_4

    .line 249
    :catch_0
    move-exception p1

    .line 250
    goto :goto_5

    .line 251
    :cond_b
    :goto_4
    const-string p1, "null bundle returned"

    .line 252
    .line 253
    invoke-interface {v1, v2, p1}, Landroid/accounts/IAccountManagerResponse;->onError(ILjava/lang/String;)V

    .line 254
    .line 255
    .line 256
    return-void

    .line 257
    :cond_c
    iget-boolean v2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mStripAuthTokenFromResult:Z

    .line 258
    .line 259
    if-eqz v2, :cond_d

    .line 260
    .line 261
    invoke-virtual {p1, v6}, Landroid/os/Bundle;->remove(Ljava/lang/String;)V

    .line 262
    .line 263
    .line 264
    :cond_d
    invoke-static {v4, v3}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 265
    .line 266
    .line 267
    move-result v2

    .line 268
    if-eqz v2, :cond_e

    .line 269
    .line 270
    new-instance v2, Ljava/lang/StringBuilder;

    .line 271
    .line 272
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    .line 273
    .line 274
    .line 275
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 276
    .line 277
    .line 278
    move-result-object v6

    .line 279
    invoke-virtual {v6}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    .line 280
    .line 281
    .line 282
    move-result-object v6

    .line 283
    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 284
    .line 285
    .line 286
    const-string v6, " calling onResult() on response "

    .line 287
    .line 288
    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 289
    .line 290
    .line 291
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 292
    .line 293
    .line 294
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 295
    .line 296
    .line 297
    move-result-object v2

    .line 298
    invoke-static {v4, v2}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 299
    .line 300
    .line 301
    :cond_e
    const/4 v2, -0x1

    .line 302
    invoke-virtual {p1, v0, v2}, Landroid/os/BaseBundle;->getInt(Ljava/lang/String;I)I

    .line 303
    .line 304
    .line 305
    move-result v2

    .line 306
    if-lez v2, :cond_f

    .line 307
    .line 308
    if-nez v5, :cond_f

    .line 309
    .line 310
    invoke-virtual {p1, v0}, Landroid/os/BaseBundle;->getInt(Ljava/lang/String;)I

    .line 311
    .line 312
    .line 313
    move-result v0

    .line 314
    const-string v2, "errorMessage"

    .line 315
    .line 316
    invoke-virtual {p1, v2}, Landroid/os/BaseBundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    .line 317
    .line 318
    .line 319
    move-result-object p1

    .line 320
    invoke-interface {v1, v0, p1}, Landroid/accounts/IAccountManagerResponse;->onError(ILjava/lang/String;)V

    .line 321
    .line 322
    .line 323
    return-void

    .line 324
    :cond_f
    invoke-interface {v1, p1}, Landroid/accounts/IAccountManagerResponse;->onResult(Landroid/os/Bundle;)V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    .line 325
    .line 326
    .line 327
    return-void

    .line 328
    :goto_5
    invoke-static {v4, v3}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 329
    .line 330
    .line 331
    move-result v0

    .line 332
    if-eqz v0, :cond_10

    .line 333
    .line 334
    const-string v0, "failure while notifying response"

    .line 335
    .line 336
    invoke-static {v4, v0, p1}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 337
    .line 338
    .line 339
    :cond_10
    return-void
.end method

.method public onServiceConnected(Landroid/content/ComponentName;Landroid/os/IBinder;)V
    .locals 0

    invoke-static {p1, p2}, Lio/github/leexeo/cage/space/AccountTransport;->wrap(Landroid/content/ComponentName;Landroid/os/IBinder;)Landroid/os/IBinder;

    move-result-object p2

    .line 1
    invoke-static {p2}, Landroid/accounts/IAccountAuthenticator$Stub;->asInterface(Landroid/os/IBinder;)Landroid/accounts/IAccountAuthenticator;

    .line 2
    .line 3
    .line 4
    move-result-object p1

    .line 5
    iput-object p1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAuthenticator:Landroid/accounts/IAccountAuthenticator;

    .line 6
    .line 7
    :try_start_0
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->run()V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    .line 8
    .line 9
    .line 10
    return-void

    .line 11
    :catch_0
    const/4 p1, 0x1

    .line 12
    const-string p2, "remote exception"

    .line 13
    .line 14
    invoke-virtual {p0, p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->onError(ILjava/lang/String;)V

    .line 15
    .line 16
    .line 17
    return-void
.end method

.method public onServiceDisconnected(Landroid/content/ComponentName;)V
    .locals 2

    .line 1
    const/4 p1, 0x0

    .line 2
    iput-object p1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAuthenticator:Landroid/accounts/IAccountAuthenticator;

    .line 3
    .line 4
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->getResponseAndClose()Landroid/accounts/IAccountManagerResponse;

    .line 5
    .line 6
    .line 7
    move-result-object p1

    .line 8
    if-eqz p1, :cond_0

    .line 9
    .line 10
    :try_start_0
    const-string v0, "disconnected"

    .line 11
    .line 12
    const/4 v1, 0x1

    .line 13
    invoke-interface {p1, v1, v0}, Landroid/accounts/IAccountManagerResponse;->onError(ILjava/lang/String;)V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    .line 14
    .line 15
    .line 16
    return-void

    .line 17
    :catch_0
    move-exception p1

    .line 18
    const/4 v0, 0x2

    .line 19
    const-string v1, "AccountManagerService"

    .line 20
    .line 21
    invoke-static {v1, v0}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 22
    .line 23
    .line 24
    move-result v0

    .line 25
    if-eqz v0, :cond_0

    .line 26
    .line 27
    const-string v0, "Session.onServiceDisconnected: caught RemoteException while responding"

    .line 28
    .line 29
    invoke-static {v1, v0, p1}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 30
    .line 31
    .line 32
    :cond_0
    return-void
.end method

.method public onTimedOut()V
    .locals 3

    .line 1
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->getResponseAndClose()Landroid/accounts/IAccountManagerResponse;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    if-eqz v0, :cond_0

    .line 6
    .line 7
    :try_start_0
    const-string v1, "timeout"

    .line 8
    .line 9
    const/4 v2, 0x1

    .line 10
    invoke-interface {v0, v2, v1}, Landroid/accounts/IAccountManagerResponse;->onError(ILjava/lang/String;)V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    .line 11
    .line 12
    .line 13
    return-void

    .line 14
    :catch_0
    move-exception v0

    .line 15
    const/4 v1, 0x2

    .line 16
    const-string v2, "AccountManagerService"

    .line 17
    .line 18
    invoke-static {v2, v1}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 19
    .line 20
    .line 21
    move-result v1

    .line 22
    if-eqz v1, :cond_0

    .line 23
    .line 24
    const-string v1, "Session.onTimedOut: caught RemoteException while responding"

    .line 25
    .line 26
    invoke-static {v2, v1, v0}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 27
    .line 28
    .line 29
    :cond_0
    return-void
.end method

.method public abstract run()V
.end method

.method public toDebugString()Ljava/lang/String;
    .locals 2

    .line 1
    invoke-static {}, Landroid/os/SystemClock;->elapsedRealtime()J

    move-result-wide v0

    invoke-virtual {p0, v0, v1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->toDebugString(J)Ljava/lang/String;

    move-result-object v0

    return-object v0
.end method

.method public toDebugString(J)Ljava/lang/String;
    .locals 3

    .line 2
    new-instance v0, Ljava/lang/StringBuilder;

    const-string v1, "Session: expectLaunch "

    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    iget-boolean v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mExpectActivityLaunch:Z

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    const-string v1, ", connected "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mAuthenticator:Landroid/accounts/IAccountAuthenticator;

    if-eqz v1, :cond_0

    const/4 v1, 0x1

    goto :goto_0

    :cond_0
    const/4 v1, 0x0

    :goto_0
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    const-string v1, ", stats ("

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    iget v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumResults:I

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    const-string v1, "/"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    iget v2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumRequestContinued:I

    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    iget v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mNumErrors:I

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    const-string v1, "), lifetime "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    iget-wide v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->mCreationTime:J

    sub-long/2addr p1, v1

    long-to-double p1, p1

    const-wide v1, 0x408f400000000000L    # 1000.0

    div-double/2addr p1, v1

    invoke-virtual {v0, p1, p2}, Ljava/lang/StringBuilder;->append(D)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    return-object p1
.end method
