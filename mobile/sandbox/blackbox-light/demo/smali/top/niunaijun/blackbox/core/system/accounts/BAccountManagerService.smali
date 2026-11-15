.class public Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;
.super Ltop/niunaijun/blackbox/core/system/accounts/IBAccountManagerService$Stub;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"

# interfaces
.implements Ltop/niunaijun/blackbox/core/system/ISystemService;
.implements Ltop/niunaijun/blackbox/core/system/pm/PackageMonitor;


# annotations
.annotation build Landroid/annotation/SuppressLint;
    value = {
        "InlinedApi"
    }
.end annotation

.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;,
        Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorInfo;,
        Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$GetAccountsByTypeAndFeatureSession;,
        Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$RemoveAccountSession;,
        Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;
    }
.end annotation


# static fields
.field private static final EMPTY_ACCOUNT_ARRAY:[Landroid/accounts/Account;

.field private static final MESSAGE_COPY_SHARED_ACCOUNT:I = 0x4

.field private static final MESSAGE_TIMED_OUT:I = 0x3

.field private static final TAG:Ljava/lang/String; = "AccountManagerService"

.field private static sService:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;


# instance fields
.field private final mAuthenticatorCache:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;

.field private final mContext:Landroid/content/Context;

.field private final mHandler:Landroid/os/Handler;

.field private final mPms:Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;

.field private final mSessions:Ljava/util/LinkedHashMap;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/LinkedHashMap<",
            "Ljava/lang/String;",
            "Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;",
            ">;"
        }
    .end annotation
.end field

.field private final mTokenCaches:Ljava/util/LinkedList;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/LinkedList<",
            "Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;",
            ">;"
        }
    .end annotation
.end field

.field private final mUserAccountsMap:Ljava/util/Map;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/Map<",
            "Ljava/lang/Integer;",
            "Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;",
            ">;"
        }
    .end annotation
.end field


# direct methods
.method static constructor <clinit>()V
    .locals 1

    .line 1
    new-instance v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 2
    .line 3
    invoke-direct {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;-><init>()V

    .line 4
    .line 5
    .line 6
    sput-object v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->sService:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 7
    .line 8
    const/4 v0, 0x0

    .line 9
    new-array v0, v0, [Landroid/accounts/Account;

    .line 10
    .line 11
    sput-object v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->EMPTY_ACCOUNT_ARRAY:[Landroid/accounts/Account;

    .line 12
    .line 13
    return-void
.end method

.method public constructor <init>()V
    .locals 2

    .line 1
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/IBAccountManagerService$Stub;-><init>()V

    .line 2
    .line 3
    .line 4
    new-instance v0, Ljava/util/HashMap;

    .line 5
    .line 6
    invoke-direct {v0}, Ljava/util/HashMap;-><init>()V

    .line 7
    .line 8
    .line 9
    iput-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 10
    .line 11
    new-instance v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;

    .line 12
    .line 13
    const/4 v1, 0x0

    .line 14
    invoke-direct {v0, v1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;-><init>(I)V

    .line 15
    .line 16
    .line 17
    iput-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mAuthenticatorCache:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;

    .line 18
    .line 19
    new-instance v0, Ljava/util/LinkedList;

    .line 20
    .line 21
    invoke-direct {v0}, Ljava/util/LinkedList;-><init>()V

    .line 22
    .line 23
    .line 24
    iput-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mTokenCaches:Ljava/util/LinkedList;

    .line 25
    .line 26
    new-instance v0, Ljava/util/LinkedHashMap;

    .line 27
    .line 28
    invoke-direct {v0}, Ljava/util/LinkedHashMap;-><init>()V

    .line 29
    .line 30
    .line 31
    iput-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mSessions:Ljava/util/LinkedHashMap;

    .line 32
    .line 33
    new-instance v0, Landroid/os/Handler;

    .line 34
    .line 35
    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;

    .line 36
    .line 37
    .line 38
    move-result-object v1

    .line 39
    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    .line 40
    .line 41
    .line 42
    iput-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mHandler:Landroid/os/Handler;

    .line 43
    .line 44
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getContext()Landroid/content/Context;

    .line 45
    .line 46
    .line 47
    move-result-object v0

    .line 48
    iput-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mContext:Landroid/content/Context;

    .line 49
    .line 50
    invoke-static {}, Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;->get()Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;

    .line 51
    .line 52
    .line 53
    move-result-object v0

    .line 54
    iput-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mPms:Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;

    .line 55
    .line 56
    return-void
.end method

.method public static bridge synthetic a(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;
    .locals 0

    .line 1
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mAuthenticatorCache:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;

    .line 2
    .line 3
    return-object p0
.end method

.method private addAccountInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;Ljava/util/Map;)Z
    .locals 4
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;",
            "Landroid/accounts/Account;",
            "Ljava/lang/String;",
            "Landroid/os/Bundle;",
            "Ljava/util/Map<",
            "Ljava/lang/String;",
            "Ljava/lang/Integer;",
            ">;)Z"
        }
    .end annotation

    .line 1
    const-string v0, "skipping since insertExtra failed for key "

    .line 2
    .line 3
    if-nez p1, :cond_0

    .line 4
    .line 5
    new-instance p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 6
    .line 7
    invoke-direct {p1}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;-><init>()V

    .line 8
    .line 9
    .line 10
    :cond_0
    iget-object v1, p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 11
    .line 12
    monitor-enter v1

    .line 13
    :try_start_0
    invoke-virtual {p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAccount(Landroid/accounts/Account;)Ltop/niunaijun/blackbox/core/system/accounts/BAccount;

    .line 14
    .line 15
    .line 16
    move-result-object v2

    .line 17
    if-eqz v2, :cond_1

    .line 18
    .line 19
    const-string p1, "AccountManagerService"

    .line 20
    .line 21
    new-instance p3, Ljava/lang/StringBuilder;

    .line 22
    .line 23
    invoke-direct {p3, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 24
    .line 25
    .line 26
    invoke-virtual {p3, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 27
    .line 28
    .line 29
    invoke-virtual {p3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 30
    .line 31
    .line 32
    move-result-object p2

    .line 33
    invoke-static {p1, p2}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 34
    .line 35
    .line 36
    monitor-exit v1

    .line 37
    const/4 p1, 0x0

    .line 38
    return p1

    .line 39
    :catchall_0
    move-exception p1

    .line 40
    goto :goto_2

    .line 41
    :cond_1
    invoke-virtual {p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->addAccount(Landroid/accounts/Account;)Ltop/niunaijun/blackbox/core/system/accounts/BAccount;

    .line 42
    .line 43
    .line 44
    move-result-object v0

    .line 45
    iput-object p3, v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccount;->password:Ljava/lang/String;

    .line 46
    .line 47
    if-eqz p4, :cond_2

    .line 48
    .line 49
    invoke-virtual {p4}, Landroid/os/BaseBundle;->keySet()Ljava/util/Set;

    .line 50
    .line 51
    .line 52
    move-result-object p3

    .line 53
    invoke-interface {p3}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    .line 54
    .line 55
    .line 56
    move-result-object p3

    .line 57
    :goto_0
    invoke-interface {p3}, Ljava/util/Iterator;->hasNext()Z

    .line 58
    .line 59
    .line 60
    move-result v2

    .line 61
    if-eqz v2, :cond_2

    .line 62
    .line 63
    invoke-interface {p3}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 64
    .line 65
    .line 66
    move-result-object v2

    .line 67
    check-cast v2, Ljava/lang/String;

    .line 68
    .line 69
    invoke-virtual {p4, v2}, Landroid/os/BaseBundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    .line 70
    .line 71
    .line 72
    move-result-object v3

    .line 73
    invoke-virtual {v0, v2, v3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccount;->insertExtra(Ljava/lang/String;Ljava/lang/String;)V

    .line 74
    .line 75
    .line 76
    goto :goto_0

    .line 77
    :cond_2
    if-eqz p5, :cond_3

    .line 78
    .line 79
    invoke-interface {p5}, Ljava/util/Map;->entrySet()Ljava/util/Set;

    .line 80
    .line 81
    .line 82
    move-result-object p3

    .line 83
    invoke-interface {p3}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    .line 84
    .line 85
    .line 86
    move-result-object p3

    .line 87
    :goto_1
    invoke-interface {p3}, Ljava/util/Iterator;->hasNext()Z

    .line 88
    .line 89
    .line 90
    move-result p4

    .line 91
    if-eqz p4, :cond_3

    .line 92
    .line 93
    invoke-interface {p3}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 94
    .line 95
    .line 96
    move-result-object p4

    .line 97
    check-cast p4, Ljava/util/Map$Entry;

    .line 98
    .line 99
    invoke-interface {p4}, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;

    .line 100
    .line 101
    .line 102
    move-result-object p5

    .line 103
    check-cast p5, Ljava/lang/String;

    .line 104
    .line 105
    invoke-interface {p4}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    .line 106
    .line 107
    .line 108
    move-result-object p4

    .line 109
    check-cast p4, Ljava/lang/Integer;

    .line 110
    .line 111
    invoke-virtual {p4}, Ljava/lang/Integer;->intValue()I

    .line 112
    .line 113
    .line 114
    move-result p4

    .line 115
    invoke-direct {p0, p2, p5, p4, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->setAccountVisibility(Landroid/accounts/Account;Ljava/lang/String;ILtop/niunaijun/blackbox/core/system/accounts/BUserAccounts;)Z

    .line 116
    .line 117
    .line 118
    goto :goto_1

    .line 119
    :cond_3
    monitor-exit v1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 120
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->saveAllAccounts()V

    .line 121
    .line 122
    .line 123
    const/4 p1, 0x1

    .line 124
    return p1

    .line 125
    :goto_2
    :try_start_1
    monitor-exit v1
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 126
    throw p1
.end method

.method public static bridge synthetic b(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Landroid/content/Context;
    .locals 0

    .line 1
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mContext:Landroid/content/Context;

    .line 2
    .line 3
    return-object p0
.end method

.method public static bridge synthetic c(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Landroid/os/Handler;
    .locals 0

    .line 1
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mHandler:Landroid/os/Handler;

    .line 2
    .line 3
    return-object p0
.end method

.method private completeCloningAccount(Landroid/accounts/IAccountManagerResponse;Landroid/os/Bundle;Landroid/accounts/Account;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;I)V
    .locals 12

    .line 1
    new-instance v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$8;

    .line 2
    .line 3
    iget-object v4, p3, Landroid/accounts/Account;->type:Ljava/lang/String;

    .line 4
    .line 5
    iget-object v7, p3, Landroid/accounts/Account;->name:Ljava/lang/String;

    .line 6
    .line 7
    const/4 v6, 0x0

    .line 8
    const/4 v8, 0x0

    .line 9
    const/4 v5, 0x0

    .line 10
    move-object v1, p0

    .line 11
    move-object v3, p1

    .line 12
    move-object v11, p2

    .line 13
    move-object v9, p3

    .line 14
    move-object/from16 v2, p4

    .line 15
    .line 16
    move/from16 v10, p5

    .line 17
    .line 18
    invoke-direct/range {v0 .. v11}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$8;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;ZZLjava/lang/String;ZLandroid/accounts/Account;ILandroid/os/Bundle;)V

    .line 19
    .line 20
    .line 21
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->bind()V

    .line 22
    .line 23
    .line 24
    return-void
.end method

.method public static bridge synthetic d(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;
    .locals 0

    .line 1
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mPms:Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;

    .line 2
    .line 3
    return-object p0
.end method

.method public static bridge synthetic e(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;)Ljava/util/LinkedHashMap;
    .locals 0

    .line 1
    iget-object p0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mSessions:Ljava/util/LinkedHashMap;

    .line 2
    .line 3
    return-object p0
.end method

.method public static bridge synthetic f(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Landroid/accounts/IAccountManagerResponse;Landroid/os/Bundle;Landroid/accounts/Account;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;I)V
    .locals 0

    .line 1
    invoke-direct/range {p0 .. p5}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->completeCloningAccount(Landroid/accounts/IAccountManagerResponse;Landroid/os/Bundle;Landroid/accounts/Account;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;I)V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method private filterAccounts(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;[Landroid/accounts/Account;Ljava/lang/String;Z)[Landroid/accounts/Account;
    .locals 8

    .line 1
    new-instance v0, Ljava/util/LinkedHashMap;

    .line 2
    .line 3
    invoke-direct {v0}, Ljava/util/LinkedHashMap;-><init>()V

    .line 4
    .line 5
    .line 6
    array-length v1, p2

    .line 7
    const/4 v2, 0x0

    .line 8
    move v3, v2

    .line 9
    :goto_0
    if-ge v3, v1, :cond_2

    .line 10
    .line 11
    aget-object v4, p2, v3

    .line 12
    .line 13
    invoke-direct {p0, v4, p3, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->resolveAccountVisibility(Landroid/accounts/Account;Ljava/lang/String;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;)Ljava/lang/Integer;

    .line 14
    .line 15
    .line 16
    move-result-object v5

    .line 17
    invoke-virtual {v5}, Ljava/lang/Integer;->intValue()I

    .line 18
    .line 19
    .line 20
    move-result v6

    .line 21
    const/4 v7, 0x1

    .line 22
    if-eq v6, v7, :cond_0

    .line 23
    .line 24
    const/4 v7, 0x2

    .line 25
    if-eq v6, v7, :cond_0

    .line 26
    .line 27
    if-eqz p4, :cond_1

    .line 28
    .line 29
    const/4 v7, 0x4

    .line 30
    if-ne v6, v7, :cond_1

    .line 31
    .line 32
    :cond_0
    invoke-interface {v0, v4, v5}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 33
    .line 34
    .line 35
    :cond_1
    add-int/lit8 v3, v3, 0x1

    .line 36
    .line 37
    goto :goto_0

    .line 38
    :cond_2
    invoke-virtual {v0}, Ljava/util/LinkedHashMap;->keySet()Ljava/util/Set;

    .line 39
    .line 40
    .line 41
    move-result-object p1

    .line 42
    new-array p2, v2, [Landroid/accounts/Account;

    .line 43
    .line 44
    invoke-interface {p1, p2}, Ljava/util/Set;->toArray([Ljava/lang/Object;)[Ljava/lang/Object;

    .line 45
    .line 46
    .line 47
    move-result-object p1

    .line 48
    check-cast p1, [Landroid/accounts/Account;

    .line 49
    .line 50
    return-object p1
.end method

.method public static bridge synthetic g(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Landroid/accounts/IAccountManagerResponse;[Landroid/accounts/Account;Ljava/lang/String;I)V
    .locals 0

    .line 1
    invoke-direct {p0, p1, p2, p3, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->handleGetAccountsResult(Landroid/accounts/IAccountManagerResponse;[Landroid/accounts/Account;Ljava/lang/String;I)V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method private generateServicesMap(Ljava/util/List;Ljava/util/Map;Ltop/niunaijun/blackbox/core/system/accounts/RegisteredServicesParser;)V
    .locals 5
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/util/List<",
            "Landroid/content/pm/ResolveInfo;",
            ">;",
            "Ljava/util/Map<",
            "Ljava/lang/String;",
            "Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorInfo;",
            ">;",
            "Ltop/niunaijun/blackbox/core/system/accounts/RegisteredServicesParser;",
            ")V"
        }
    .end annotation

    .line 1
    invoke-interface {p1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    .line 2
    .line 3
    .line 4
    move-result-object p1

    .line 5
    :cond_0
    :goto_0
    invoke-interface {p1}, Ljava/util/Iterator;->hasNext()Z

    .line 6
    .line 7
    .line 8
    move-result v0

    .line 9
    if-eqz v0, :cond_2

    .line 10
    .line 11
    invoke-interface {p1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 12
    .line 13
    .line 14
    move-result-object v0

    .line 15
    check-cast v0, Landroid/content/pm/ResolveInfo;

    .line 16
    .line 17
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mContext:Landroid/content/Context;

    .line 18
    .line 19
    iget-object v2, v0, Landroid/content/pm/ResolveInfo;->serviceInfo:Landroid/content/pm/ServiceInfo;

    .line 20
    .line 21
    const-string v3, "android.accounts.AccountAuthenticator"

    .line 22
    .line 23
    invoke-virtual {p3, v1, v2, v3}, Ltop/niunaijun/blackbox/core/system/accounts/RegisteredServicesParser;->getParser(Landroid/content/Context;Landroid/content/pm/ServiceInfo;Ljava/lang/String;)Landroid/content/res/XmlResourceParser;

    .line 24
    .line 25
    .line 26
    move-result-object v1

    .line 27
    if-eqz v1, :cond_0

    .line 28
    .line 29
    :try_start_0
    invoke-static {v1}, Landroid/util/Xml;->asAttributeSet(Lorg/xmlpull/v1/XmlPullParser;)Landroid/util/AttributeSet;

    .line 30
    .line 31
    .line 32
    move-result-object v2

    .line 33
    :goto_1
    invoke-interface {v1}, Lorg/xmlpull/v1/XmlPullParser;->next()I

    .line 34
    .line 35
    .line 36
    move-result v3

    .line 37
    const/4 v4, 0x1

    .line 38
    if-eq v3, v4, :cond_1

    .line 39
    .line 40
    const/4 v4, 0x2

    .line 41
    if-eq v3, v4, :cond_1

    .line 42
    .line 43
    goto :goto_1

    .line 44
    :cond_1
    const-string v3, "account-authenticator"

    .line 45
    .line 46
    invoke-interface {v1}, Lorg/xmlpull/v1/XmlPullParser;->getName()Ljava/lang/String;

    .line 47
    .line 48
    .line 49
    move-result-object v1

    .line 50
    invoke-virtual {v3, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 51
    .line 52
    .line 53
    move-result v1

    .line 54
    if-eqz v1, :cond_0

    .line 55
    .line 56
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mContext:Landroid/content/Context;

    .line 57
    .line 58
    iget-object v3, v0, Landroid/content/pm/ResolveInfo;->serviceInfo:Landroid/content/pm/ServiceInfo;

    .line 59
    .line 60
    iget-object v3, v3, Landroid/content/pm/ServiceInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    .line 61
    .line 62
    invoke-virtual {p3, v1, v3}, Ltop/niunaijun/blackbox/core/system/accounts/RegisteredServicesParser;->getResources(Landroid/content/Context;Landroid/content/pm/ApplicationInfo;)Landroid/content/res/Resources;

    .line 63
    .line 64
    .line 65
    move-result-object v1

    .line 66
    iget-object v3, v0, Landroid/content/pm/ResolveInfo;->serviceInfo:Landroid/content/pm/ServiceInfo;

    .line 67
    .line 68
    iget-object v3, v3, Landroid/content/pm/ServiceInfo;->packageName:Ljava/lang/String;

    .line 69
    .line 70
    invoke-static {v1, v3, v2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->parseAuthenticatorDescription(Landroid/content/res/Resources;Ljava/lang/String;Landroid/util/AttributeSet;)Landroid/accounts/AuthenticatorDescription;

    .line 71
    .line 72
    .line 73
    move-result-object v1

    .line 74
    if-eqz v1, :cond_0

    .line 75
    .line 76
    iget-object v2, v1, Landroid/accounts/AuthenticatorDescription;->type:Ljava/lang/String;

    .line 77
    .line 78
    new-instance v3, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorInfo;

    .line 79
    .line 80
    iget-object v0, v0, Landroid/content/pm/ResolveInfo;->serviceInfo:Landroid/content/pm/ServiceInfo;

    .line 81
    .line 82
    invoke-direct {v3, v1, v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorInfo;-><init>(Landroid/accounts/AuthenticatorDescription;Landroid/content/pm/ServiceInfo;)V

    .line 83
    .line 84
    .line 85
    invoke-interface {p2, v2, v3}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 86
    .line 87
    .line 88
    goto :goto_0

    .line 89
    :catch_0
    move-exception v0

    .line 90
    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V

    .line 91
    .line 92
    .line 93
    goto :goto_0

    .line 94
    :cond_2
    return-void
.end method

.method public static get()Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;
    .locals 1

    .line 1
    sget-object v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->sService:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;

    .line 2
    .line 3
    return-object v0
.end method

.method private getAccountVisibilityFromCache(Landroid/accounts/Account;Ljava/lang/String;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;)I
    .locals 1

    .line 1
    iget-object v0, p3, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 2
    .line 3
    monitor-enter v0

    .line 4
    :try_start_0
    invoke-direct {p0, p1, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getPackagesAndVisibilityForAccountLocked(Landroid/accounts/Account;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;)Ljava/util/Map;

    .line 5
    .line 6
    .line 7
    move-result-object p1

    .line 8
    invoke-interface {p1, p2}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 9
    .line 10
    .line 11
    move-result-object p1

    .line 12
    check-cast p1, Ljava/lang/Integer;

    .line 13
    .line 14
    if-eqz p1, :cond_0

    .line 15
    .line 16
    invoke-virtual {p1}, Ljava/lang/Integer;->intValue()I

    .line 17
    .line 18
    .line 19
    move-result p1

    .line 20
    goto :goto_0

    .line 21
    :catchall_0
    move-exception p1

    .line 22
    goto :goto_1

    .line 23
    :cond_0
    const/4 p1, 0x0

    .line 24
    :goto_0
    monitor-exit v0

    .line 25
    return p1

    .line 26
    :goto_1
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 27
    throw p1
.end method

.method private getCallingPackageName()Ljava/lang/String;
    .locals 3

    .line 1
    invoke-static {}, Landroid/os/Binder;->getCallingPid()I

    .line 2
    .line 3
    .line 4
    move-result v0

    .line 5
    invoke-static {}, Ltop/niunaijun/blackbox/core/system/BProcessManagerService;->get()Ltop/niunaijun/blackbox/core/system/BProcessManagerService;

    .line 6
    .line 7
    .line 8
    move-result-object v1

    .line 9
    invoke-virtual {v1, v0}, Ltop/niunaijun/blackbox/core/system/BProcessManagerService;->findProcessByPid(I)Ltop/niunaijun/blackbox/core/system/ProcessRecord;

    .line 10
    .line 11
    .line 12
    move-result-object v1

    .line 13
    if-eqz v1, :cond_0

    .line 14
    .line 15
    invoke-virtual {v1}, Ltop/niunaijun/blackbox/core/system/ProcessRecord;->getPackageName()Ljava/lang/String;

    .line 16
    .line 17
    .line 18
    move-result-object v0

    .line 19
    return-object v0

    .line 20
    :cond_0
    new-instance v1, Ljava/lang/IllegalArgumentException;

    .line 21
    .line 22
    const-string v2, "ProcessRecord is null, PID: "

    .line 23
    .line 24
    invoke-static {v0, v2}, Landroidx/fragment/app/x0;->e(ILjava/lang/String;)Ljava/lang/String;

    .line 25
    .line 26
    .line 27
    move-result-object v0

    .line 28
    invoke-direct {v1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 29
    .line 30
    .line 31
    throw v1
.end method

.method private getPackagesAndVisibilityForAccountLocked(Landroid/accounts/Account;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;)Ljava/util/Map;
    .locals 0
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Landroid/accounts/Account;",
            "Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;",
            ")",
            "Ljava/util/Map<",
            "Ljava/lang/String;",
            "Ljava/lang/Integer;",
            ">;"
        }
    .end annotation

    .line 1
    invoke-virtual {p2, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getVisibility(Landroid/accounts/Account;)Ljava/util/Map;

    .line 2
    .line 3
    .line 4
    move-result-object p1

    .line 5
    return-object p1
.end method

.method public static bridge synthetic h(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ljava/lang/String;Ljava/lang/String;I)Z
    .locals 0

    .line 1
    invoke-direct {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->isAccountPresentForCaller(Ljava/lang/String;Ljava/lang/String;I)Z

    .line 2
    .line 3
    .line 4
    move-result p0

    .line 5
    return p0
.end method

.method private handleGetAccountsResult(Landroid/accounts/IAccountManagerResponse;[Landroid/accounts/Account;Ljava/lang/String;I)V
    .locals 2

    .line 1
    invoke-direct {p0, p2, p3, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->needToStartChooseAccountActivity([Landroid/accounts/Account;Ljava/lang/String;I)Z

    .line 2
    .line 3
    .line 4
    move-result p3

    .line 5
    if-eqz p3, :cond_0

    .line 6
    .line 7
    return-void

    .line 8
    :cond_0
    array-length p3, p2

    .line 9
    const/4 p4, 0x1

    .line 10
    if-ne p3, p4, :cond_1

    .line 11
    .line 12
    new-instance p3, Landroid/os/Bundle;

    .line 13
    .line 14
    invoke-direct {p3}, Landroid/os/Bundle;-><init>()V

    .line 15
    .line 16
    .line 17
    const/4 p4, 0x0

    .line 18
    aget-object v0, p2, p4

    .line 19
    .line 20
    iget-object v0, v0, Landroid/accounts/Account;->name:Ljava/lang/String;

    .line 21
    .line 22
    const-string v1, "authAccount"

    .line 23
    .line 24
    invoke-virtual {p3, v1, v0}, Landroid/os/BaseBundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    .line 25
    .line 26
    .line 27
    aget-object p2, p2, p4

    .line 28
    .line 29
    iget-object p2, p2, Landroid/accounts/Account;->type:Ljava/lang/String;

    .line 30
    .line 31
    const-string p4, "accountType"

    .line 32
    .line 33
    invoke-virtual {p3, p4, p2}, Landroid/os/BaseBundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    .line 34
    .line 35
    .line 36
    invoke-direct {p0, p1, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->onResult(Landroid/accounts/IAccountManagerResponse;Landroid/os/Bundle;)V

    .line 37
    .line 38
    .line 39
    return-void

    .line 40
    :cond_1
    new-instance p2, Landroid/os/Bundle;

    .line 41
    .line 42
    invoke-direct {p2}, Landroid/os/Bundle;-><init>()V

    .line 43
    .line 44
    .line 45
    invoke-direct {p0, p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->onResult(Landroid/accounts/IAccountManagerResponse;Landroid/os/Bundle;)V

    .line 46
    .line 47
    .line 48
    return-void
.end method

.method public static bridge synthetic i(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;)V
    .locals 0

    .line 1
    invoke-direct {p0, p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->removeAccountInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;)Z

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method private isAccountPresentForCaller(Ljava/lang/String;Ljava/lang/String;I)Z
    .locals 2

    .line 1
    invoke-virtual {p0, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 2
    .line 3
    .line 4
    move-result-object p3

    .line 5
    const/4 v0, 0x0

    .line 6
    if-eqz p3, :cond_0

    .line 7
    .line 8
    new-instance v1, Landroid/accounts/Account;

    .line 9
    .line 10
    invoke-direct {v1, p1, p2}, Landroid/accounts/Account;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    .line 11
    .line 12
    .line 13
    invoke-virtual {p3, v1}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAccount(Landroid/accounts/Account;)Ltop/niunaijun/blackbox/core/system/accounts/BAccount;

    .line 14
    .line 15
    .line 16
    move-result-object p1

    .line 17
    if-eqz p1, :cond_0

    .line 18
    .line 19
    const/4 p1, 0x1

    .line 20
    return p1

    .line 21
    :cond_0
    return v0
.end method

.method public static bridge synthetic j(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;)V
    .locals 0

    .line 1
    invoke-direct {p0, p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->updateLastAuthenticatedTime(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;)Z

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method private loadAccounts()V
    .locals 11

    .line 1
    invoke-static {}, Landroid/os/Parcel;->obtain()Landroid/os/Parcel;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    const/4 v1, 0x1

    .line 6
    const/4 v2, 0x0

    .line 7
    const/4 v3, 0x0

    .line 8
    :try_start_0
    invoke-static {}, Ltop/niunaijun/blackbox/core/env/BEnvironment;->getAccountsConf()Ljava/io/File;

    .line 9
    .line 10
    .line 11
    move-result-object v4

    .line 12
    invoke-virtual {v4}, Ljava/io/File;->exists()Z

    .line 13
    .line 14
    .line 15
    move-result v4
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_1
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    .line 16
    if-nez v4, :cond_0

    .line 17
    .line 18
    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    .line 19
    .line 20
    .line 21
    filled-new-array {v3}, [Ljava/io/Closeable;

    .line 22
    .line 23
    .line 24
    move-result-object v0

    .line 25
    invoke-static {v0}, Ltop/niunaijun/blackbox/utils/CloseUtils;->close([Ljava/io/Closeable;)V

    .line 26
    .line 27
    .line 28
    return-void

    .line 29
    :cond_0
    :try_start_1
    new-instance v4, Ljava/io/FileInputStream;

    .line 30
    .line 31
    invoke-static {}, Ltop/niunaijun/blackbox/core/env/BEnvironment;->getAccountsConf()Ljava/io/File;

    .line 32
    .line 33
    .line 34
    move-result-object v5

    .line 35
    invoke-direct {v4, v5}, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_2

    .line 36
    .line 37
    .line 38
    :try_start_2
    invoke-static {v4}, Ltop/niunaijun/blackbox/utils/FileUtils;->toByteArray(Ljava/io/InputStream;)[B

    .line 39
    .line 40
    .line 41
    move-result-object v3

    .line 42
    array-length v5, v3

    .line 43
    invoke-virtual {v0, v3, v2, v5}, Landroid/os/Parcel;->unmarshall([BII)V

    .line 44
    .line 45
    .line 46
    invoke-virtual {v0, v2}, Landroid/os/Parcel;->setDataPosition(I)V

    .line 47
    .line 48
    .line 49
    const-class v3, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 50
    .line 51
    invoke-virtual {v3}, Ljava/lang/Class;->getClassLoader()Ljava/lang/ClassLoader;

    .line 52
    .line 53
    .line 54
    move-result-object v3

    .line 55
    invoke-virtual {v0, v3}, Landroid/os/Parcel;->readHashMap(Ljava/lang/ClassLoader;)Ljava/util/HashMap;

    .line 56
    .line 57
    .line 58
    move-result-object v3
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_0
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    .line 59
    if-nez v3, :cond_1

    .line 60
    .line 61
    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    .line 62
    .line 63
    .line 64
    new-array v0, v1, [Ljava/io/Closeable;

    .line 65
    .line 66
    aput-object v4, v0, v2

    .line 67
    .line 68
    invoke-static {v0}, Ltop/niunaijun/blackbox/utils/CloseUtils;->close([Ljava/io/Closeable;)V

    .line 69
    .line 70
    .line 71
    return-void

    .line 72
    :cond_1
    :try_start_3
    iget-object v5, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 73
    .line 74
    monitor-enter v5
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_0
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    .line 75
    :try_start_4
    iget-object v6, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 76
    .line 77
    invoke-interface {v6}, Ljava/util/Map;->clear()V

    .line 78
    .line 79
    .line 80
    invoke-virtual {v3}, Ljava/util/HashMap;->keySet()Ljava/util/Set;

    .line 81
    .line 82
    .line 83
    move-result-object v6

    .line 84
    invoke-interface {v6}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    .line 85
    .line 86
    .line 87
    move-result-object v6

    .line 88
    :goto_0
    invoke-interface {v6}, Ljava/util/Iterator;->hasNext()Z

    .line 89
    .line 90
    .line 91
    move-result v7

    .line 92
    if-eqz v7, :cond_2

    .line 93
    .line 94
    invoke-interface {v6}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 95
    .line 96
    .line 97
    move-result-object v7

    .line 98
    check-cast v7, Ljava/lang/Integer;

    .line 99
    .line 100
    iget-object v8, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 101
    .line 102
    invoke-virtual {v3, v7}, Ljava/util/HashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 103
    .line 104
    .line 105
    move-result-object v9

    .line 106
    check-cast v9, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 107
    .line 108
    invoke-interface {v8, v7, v9}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 109
    .line 110
    .line 111
    goto :goto_0

    .line 112
    :catchall_0
    move-exception v3

    .line 113
    goto :goto_1

    .line 114
    :cond_2
    monitor-exit v5
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_0

    .line 115
    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    .line 116
    .line 117
    .line 118
    new-array v0, v1, [Ljava/io/Closeable;

    .line 119
    .line 120
    aput-object v4, v0, v2

    .line 121
    .line 122
    invoke-static {v0}, Ltop/niunaijun/blackbox/utils/CloseUtils;->close([Ljava/io/Closeable;)V

    .line 123
    .line 124
    .line 125
    return-void

    .line 126
    :goto_1
    :try_start_5
    monitor-exit v5
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_0

    .line 127
    :try_start_6
    throw v3
    :try_end_6
    .catch Ljava/lang/Exception; {:try_start_6 .. :try_end_6} :catch_0
    .catchall {:try_start_6 .. :try_end_6} :catchall_1

    .line 128
    :catchall_1
    move-exception v3

    .line 129
    goto :goto_3

    .line 130
    :catch_0
    move-exception v3

    .line 131
    goto :goto_2

    .line 132
    :catchall_2
    move-exception v4

    .line 133
    move-object v10, v4

    .line 134
    move-object v4, v3

    .line 135
    move-object v3, v10

    .line 136
    goto :goto_3

    .line 137
    :catch_1
    move-exception v4

    .line 138
    move-object v10, v4

    .line 139
    move-object v4, v3

    .line 140
    move-object v3, v10

    .line 141
    :goto_2
    :try_start_7
    invoke-virtual {v3}, Ljava/lang/Throwable;->printStackTrace()V
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_1

    .line 142
    .line 143
    .line 144
    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    .line 145
    .line 146
    .line 147
    new-array v0, v1, [Ljava/io/Closeable;

    .line 148
    .line 149
    aput-object v4, v0, v2

    .line 150
    .line 151
    invoke-static {v0}, Ltop/niunaijun/blackbox/utils/CloseUtils;->close([Ljava/io/Closeable;)V

    .line 152
    .line 153
    .line 154
    return-void

    .line 155
    :goto_3
    invoke-virtual {v0}, Landroid/os/Parcel;->recycle()V

    .line 156
    .line 157
    .line 158
    new-array v0, v1, [Ljava/io/Closeable;

    .line 159
    .line 160
    aput-object v4, v0, v2

    .line 161
    .line 162
    invoke-static {v0}, Ltop/niunaijun/blackbox/utils/CloseUtils;->close([Ljava/io/Closeable;)V

    .line 163
    .line 164
    .line 165
    throw v3
.end method

.method private needToStartChooseAccountActivity([Landroid/accounts/Account;Ljava/lang/String;I)Z
    .locals 3

    .line 1
    array-length v0, p1

    .line 2
    const/4 v1, 0x0

    .line 3
    const/4 v2, 0x1

    .line 4
    if-ge v0, v2, :cond_0

    .line 5
    .line 6
    return v1

    .line 7
    :cond_0
    array-length v0, p1

    .line 8
    if-le v0, v2, :cond_1

    .line 9
    .line 10
    return v2

    .line 11
    :cond_1
    aget-object p1, p1, v1

    .line 12
    .line 13
    invoke-virtual {p0, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 14
    .line 15
    .line 16
    move-result-object p3

    .line 17
    invoke-direct {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->resolveAccountVisibility(Landroid/accounts/Account;Ljava/lang/String;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;)Ljava/lang/Integer;

    .line 18
    .line 19
    .line 20
    move-result-object p1

    .line 21
    invoke-virtual {p1}, Ljava/lang/Integer;->intValue()I

    .line 22
    .line 23
    .line 24
    move-result p1

    .line 25
    const/4 p2, 0x4

    .line 26
    if-ne p1, p2, :cond_2

    .line 27
    .line 28
    return v2

    .line 29
    :cond_2
    return v1
.end method

.method private onResult(Landroid/accounts/IAccountManagerResponse;Landroid/os/Bundle;)V
    .locals 4

    .line 1
    const-string v0, "AccountManagerService"

    .line 2
    .line 3
    if-nez p2, :cond_0

    .line 4
    .line 5
    new-instance v1, Ljava/lang/Exception;

    .line 6
    .line 7
    invoke-direct {v1}, Ljava/lang/Exception;-><init>()V

    .line 8
    .line 9
    .line 10
    const-string v2, "the result is unexpectedly null"

    .line 11
    .line 12
    invoke-static {v0, v2, v1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 13
    .line 14
    .line 15
    :cond_0
    const/4 v1, 0x2

    .line 16
    invoke-static {v0, v1}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 17
    .line 18
    .line 19
    move-result v2

    .line 20
    if-eqz v2, :cond_1

    .line 21
    .line 22
    new-instance v2, Ljava/lang/StringBuilder;

    .line 23
    .line 24
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    .line 25
    .line 26
    .line 27
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 28
    .line 29
    .line 30
    move-result-object v3

    .line 31
    invoke-virtual {v3}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    .line 32
    .line 33
    .line 34
    move-result-object v3

    .line 35
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 36
    .line 37
    .line 38
    const-string v3, " calling onResult() on response "

    .line 39
    .line 40
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 41
    .line 42
    .line 43
    invoke-virtual {v2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 44
    .line 45
    .line 46
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 47
    .line 48
    .line 49
    move-result-object v2

    .line 50
    invoke-static {v0, v2}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 51
    .line 52
    .line 53
    :cond_1
    :try_start_0
    invoke-interface {p1, p2}, Landroid/accounts/IAccountManagerResponse;->onResult(Landroid/os/Bundle;)V
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
    invoke-static {v0, v1}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 59
    .line 60
    .line 61
    move-result p2

    .line 62
    if-eqz p2, :cond_2

    .line 63
    .line 64
    const-string p2, "failure while notifying response"

    .line 65
    .line 66
    invoke-static {v0, p2, p1}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 67
    .line 68
    .line 69
    :cond_2
    return-void
.end method

.method private static parseAuthenticatorDescription(Landroid/content/res/Resources;Ljava/lang/String;Landroid/util/AttributeSet;)Landroid/accounts/AuthenticatorDescription;
    .locals 9

    .line 1
    invoke-static {}, Lh5/u;->d()Lblack/com/android/internal/RstyleableStatic;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    invoke-interface {v0}, Lblack/com/android/internal/RstyleableStatic;->AccountAuthenticator()[I

    .line 6
    .line 7
    .line 8
    move-result-object v1

    .line 9
    invoke-virtual {p0, p2, v1}, Landroid/content/res/Resources;->obtainAttributes(Landroid/util/AttributeSet;[I)Landroid/content/res/TypedArray;

    .line 10
    .line 11
    .line 12
    move-result-object p0

    .line 13
    :try_start_0
    invoke-interface {v0}, Lblack/com/android/internal/RstyleableStatic;->AccountAuthenticator_accountType()Ljava/lang/Integer;

    .line 14
    .line 15
    .line 16
    move-result-object p2

    .line 17
    invoke-virtual {p2}, Ljava/lang/Integer;->intValue()I

    .line 18
    .line 19
    .line 20
    move-result p2

    .line 21
    invoke-virtual {p0, p2}, Landroid/content/res/TypedArray;->getString(I)Ljava/lang/String;

    .line 22
    .line 23
    .line 24
    move-result-object v2

    .line 25
    invoke-interface {v0}, Lblack/com/android/internal/RstyleableStatic;->AccountAuthenticator_label()Ljava/lang/Integer;

    .line 26
    .line 27
    .line 28
    move-result-object p2

    .line 29
    invoke-virtual {p2}, Ljava/lang/Integer;->intValue()I

    .line 30
    .line 31
    .line 32
    move-result p2

    .line 33
    const/4 v1, 0x0

    .line 34
    invoke-virtual {p0, p2, v1}, Landroid/content/res/TypedArray;->getResourceId(II)I

    .line 35
    .line 36
    .line 37
    move-result v4

    .line 38
    invoke-interface {v0}, Lblack/com/android/internal/RstyleableStatic;->AccountAuthenticator_icon()Ljava/lang/Integer;

    .line 39
    .line 40
    .line 41
    move-result-object p2

    .line 42
    invoke-virtual {p2}, Ljava/lang/Integer;->intValue()I

    .line 43
    .line 44
    .line 45
    move-result p2

    .line 46
    invoke-virtual {p0, p2, v1}, Landroid/content/res/TypedArray;->getResourceId(II)I

    .line 47
    .line 48
    .line 49
    move-result v5

    .line 50
    invoke-interface {v0}, Lblack/com/android/internal/RstyleableStatic;->AccountAuthenticator_smallIcon()Ljava/lang/Integer;

    .line 51
    .line 52
    .line 53
    move-result-object p2

    .line 54
    invoke-virtual {p2}, Ljava/lang/Integer;->intValue()I

    .line 55
    .line 56
    .line 57
    move-result p2

    .line 58
    invoke-virtual {p0, p2, v1}, Landroid/content/res/TypedArray;->getResourceId(II)I

    .line 59
    .line 60
    .line 61
    move-result v6

    .line 62
    invoke-interface {v0}, Lblack/com/android/internal/RstyleableStatic;->AccountAuthenticator_accountPreferences()Ljava/lang/Integer;

    .line 63
    .line 64
    .line 65
    move-result-object p2

    .line 66
    invoke-virtual {p2}, Ljava/lang/Integer;->intValue()I

    .line 67
    .line 68
    .line 69
    move-result p2

    .line 70
    invoke-virtual {p0, p2, v1}, Landroid/content/res/TypedArray;->getResourceId(II)I

    .line 71
    .line 72
    .line 73
    move-result v7

    .line 74
    invoke-interface {v0}, Lblack/com/android/internal/RstyleableStatic;->AccountAuthenticator_customTokens()Ljava/lang/Integer;

    .line 75
    .line 76
    .line 77
    move-result-object p2

    .line 78
    invoke-virtual {p2}, Ljava/lang/Integer;->intValue()I

    .line 79
    .line 80
    .line 81
    move-result p2

    .line 82
    invoke-virtual {p0, p2, v1}, Landroid/content/res/TypedArray;->getBoolean(IZ)Z

    .line 83
    .line 84
    .line 85
    move-result v8

    .line 86
    invoke-static {v2}, Landroid/text/TextUtils;->isEmpty(Ljava/lang/CharSequence;)Z

    .line 87
    .line 88
    .line 89
    move-result p2
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 90
    if-eqz p2, :cond_0

    .line 91
    .line 92
    invoke-virtual {p0}, Landroid/content/res/TypedArray;->recycle()V

    .line 93
    .line 94
    .line 95
    const/4 p0, 0x0

    .line 96
    return-object p0

    .line 97
    :cond_0
    :try_start_1
    new-instance v1, Landroid/accounts/AuthenticatorDescription;

    .line 98
    .line 99
    move-object v3, p1

    .line 100
    invoke-direct/range {v1 .. v8}, Landroid/accounts/AuthenticatorDescription;-><init>(Ljava/lang/String;Ljava/lang/String;IIIIZ)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 101
    .line 102
    .line 103
    invoke-virtual {p0}, Landroid/content/res/TypedArray;->recycle()V

    .line 104
    .line 105
    .line 106
    return-object v1

    .line 107
    :catchall_0
    move-exception v0

    .line 108
    move-object p1, v0

    .line 109
    invoke-virtual {p0}, Landroid/content/res/TypedArray;->recycle()V

    .line 110
    .line 111
    .line 112
    throw p1
.end method

.method private readUserDataInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;Ljava/lang/String;)Ljava/lang/String;
    .locals 1

    .line 1
    if-nez p1, :cond_0

    .line 2
    .line 3
    const/4 p1, 0x0

    .line 4
    return-object p1

    .line 5
    :cond_0
    iget-object v0, p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 6
    .line 7
    monitor-enter v0

    .line 8
    :try_start_0
    invoke-virtual {p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAccountUserData(Landroid/accounts/Account;)Ljava/util/Map;

    .line 9
    .line 10
    .line 11
    move-result-object p1

    .line 12
    invoke-interface {p1, p3}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 13
    .line 14
    .line 15
    move-result-object p1

    .line 16
    check-cast p1, Ljava/lang/String;

    .line 17
    .line 18
    monitor-exit v0

    .line 19
    return-object p1

    .line 20
    :catchall_0
    move-exception p1

    .line 21
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 22
    throw p1
.end method

.method private removeAccountInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;)Z
    .locals 1

    .line 1
    iget-object v0, p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 2
    .line 3
    monitor-enter v0

    .line 4
    :try_start_0
    invoke-virtual {p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->delAccount(Landroid/accounts/Account;)Z

    .line 5
    .line 6
    .line 7
    move-result p1

    .line 8
    if-eqz p1, :cond_0

    .line 9
    .line 10
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->saveAllAccounts()V

    .line 11
    .line 12
    .line 13
    goto :goto_0

    .line 14
    :catchall_0
    move-exception p1

    .line 15
    goto :goto_1

    .line 16
    :cond_0
    :goto_0
    monitor-exit v0

    .line 17
    return p1

    .line 18
    :goto_1
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 19
    throw p1
.end method

.method private resolveAccountVisibility(Landroid/accounts/Account;Ljava/lang/String;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;)Ljava/lang/Integer;
    .locals 2

    .line 1
    const/4 v0, 0x3

    .line 2
    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 3
    .line 4
    .line 5
    move-result-object v0

    .line 6
    if-nez p3, :cond_0

    .line 7
    .line 8
    return-object v0

    .line 9
    :cond_0
    invoke-virtual {p3, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAccount(Landroid/accounts/Account;)Ltop/niunaijun/blackbox/core/system/accounts/BAccount;

    .line 10
    .line 11
    .line 12
    move-result-object v1

    .line 13
    if-nez v1, :cond_1

    .line 14
    .line 15
    return-object v0

    .line 16
    :cond_1
    invoke-direct {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getAccountVisibilityFromCache(Landroid/accounts/Account;Ljava/lang/String;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;)I

    .line 17
    .line 18
    .line 19
    move-result p1

    .line 20
    if-eqz p1, :cond_2

    .line 21
    .line 22
    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 23
    .line 24
    .line 25
    move-result-object p1

    .line 26
    return-object p1

    .line 27
    :cond_2
    return-object v0
.end method

.method private saveAllAccounts()V
    .locals 7

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 2
    .line 3
    monitor-enter v0

    .line 4
    :try_start_0
    invoke-static {}, Landroid/os/Parcel;->obtain()Landroid/os/Parcel;

    .line 5
    .line 6
    .line 7
    move-result-object v1

    .line 8
    new-instance v2, Landroidx/emoji2/text/u;

    .line 9
    .line 10
    invoke-static {}, Ltop/niunaijun/blackbox/core/env/BEnvironment;->getAccountsConf()Ljava/io/File;

    .line 11
    .line 12
    .line 13
    move-result-object v3

    .line 14
    invoke-direct {v2, v3}, Landroidx/emoji2/text/u;-><init>(Ljava/io/File;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    .line 15
    .line 16
    .line 17
    :try_start_1
    iget-object v3, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 18
    .line 19
    invoke-virtual {v1, v3}, Landroid/os/Parcel;->writeMap(Ljava/util/Map;)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 20
    .line 21
    .line 22
    const/4 v3, 0x0

    .line 23
    const/4 v4, 0x1

    .line 24
    const/4 v5, 0x0

    .line 25
    :try_start_2
    invoke-virtual {v2}, Landroidx/emoji2/text/u;->K()Ljava/io/FileOutputStream;

    .line 26
    .line 27
    .line 28
    move-result-object v5

    .line 29
    invoke-static {v1, v5}, Ltop/niunaijun/blackbox/utils/FileUtils;->writeParcelToOutput(Landroid/os/Parcel;Ljava/io/FileOutputStream;)V

    .line 30
    .line 31
    .line 32
    invoke-virtual {v2, v5}, Landroidx/emoji2/text/u;->n(Ljava/io/FileOutputStream;)V
    :try_end_2
    .catch Ljava/io/IOException; {:try_start_2 .. :try_end_2} :catch_0
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    .line 33
    .line 34
    .line 35
    :try_start_3
    new-array v2, v4, [Ljava/io/Closeable;

    .line 36
    .line 37
    aput-object v5, v2, v3

    .line 38
    .line 39
    invoke-static {v2}, Ltop/niunaijun/blackbox/utils/CloseUtils;->close([Ljava/io/Closeable;)V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 40
    .line 41
    .line 42
    goto :goto_0

    .line 43
    :catchall_0
    move-exception v2

    .line 44
    goto :goto_2

    .line 45
    :catchall_1
    move-exception v2

    .line 46
    goto :goto_1

    .line 47
    :catch_0
    move-exception v6

    .line 48
    :try_start_4
    invoke-virtual {v6}, Ljava/lang/Throwable;->printStackTrace()V

    .line 49
    .line 50
    .line 51
    invoke-virtual {v2, v5}, Landroidx/emoji2/text/u;->m(Ljava/io/FileOutputStream;)V
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_1

    .line 52
    .line 53
    .line 54
    :try_start_5
    new-array v2, v4, [Ljava/io/Closeable;

    .line 55
    .line 56
    aput-object v5, v2, v3

    .line 57
    .line 58
    invoke-static {v2}, Ltop/niunaijun/blackbox/utils/CloseUtils;->close([Ljava/io/Closeable;)V
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_0

    .line 59
    .line 60
    .line 61
    :goto_0
    :try_start_6
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 62
    .line 63
    .line 64
    monitor-exit v0
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_2

    .line 65
    return-void

    .line 66
    :catchall_2
    move-exception v1

    .line 67
    goto :goto_3

    .line 68
    :goto_1
    :try_start_7
    new-array v4, v4, [Ljava/io/Closeable;

    .line 69
    .line 70
    aput-object v5, v4, v3

    .line 71
    .line 72
    invoke-static {v4}, Ltop/niunaijun/blackbox/utils/CloseUtils;->close([Ljava/io/Closeable;)V

    .line 73
    .line 74
    .line 75
    throw v2
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_0

    .line 76
    :goto_2
    :try_start_8
    invoke-virtual {v1}, Landroid/os/Parcel;->recycle()V

    .line 77
    .line 78
    .line 79
    throw v2

    .line 80
    :goto_3
    monitor-exit v0
    :try_end_8
    .catchall {:try_start_8 .. :try_end_8} :catchall_2

    .line 81
    throw v1
.end method

.method private setAccountVisibility(Landroid/accounts/Account;Ljava/lang/String;ILtop/niunaijun/blackbox/core/system/accounts/BUserAccounts;)Z
    .locals 1

    .line 5
    iget-object v0, p4, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    monitor-enter v0

    .line 6
    :try_start_0
    invoke-virtual {p4, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAccount(Landroid/accounts/Account;)Ltop/niunaijun/blackbox/core/system/accounts/BAccount;

    move-result-object p1

    if-nez p1, :cond_0

    .line 7
    monitor-exit v0

    const/4 p1, 0x0

    return p1

    :catchall_0
    move-exception p1

    goto :goto_0

    .line 8
    :cond_0
    iget-object p1, p1, Ltop/niunaijun/blackbox/core/system/accounts/BAccount;->visibility:Ljava/util/HashMap;

    invoke-static {p3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p3

    invoke-virtual {p1, p2, p3}, Ljava/util/HashMap;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 9
    monitor-exit v0

    const/4 p1, 0x1

    return p1

    .line 10
    :goto_0
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    throw p1
.end method

.method private updateLastAuthenticatedTime(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;)Z
    .locals 0

    .line 1
    invoke-virtual {p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->updateLastAuthenticatedTime(Landroid/accounts/Account;)V

    .line 2
    .line 3
    .line 4
    const/4 p1, 0x1

    .line 5
    return p1
.end method


# virtual methods
.method public accountAuthenticated(Landroid/accounts/Account;I)Z
    .locals 1

    .line 1
    const-string v0, "account cannot be null"

    .line 2
    .line 3
    invoke-static {p1, v0}, Ljava/util/Objects;->requireNonNull(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    .line 4
    .line 5
    .line 6
    invoke-virtual {p0, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 7
    .line 8
    .line 9
    move-result-object p2

    .line 10
    if-nez p2, :cond_0

    .line 11
    .line 12
    const/4 p1, 0x0

    .line 13
    return p1

    .line 14
    :cond_0
    invoke-direct {p0, p2, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->updateLastAuthenticatedTime(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;)Z

    .line 15
    .line 16
    .line 17
    move-result p1

    .line 18
    return p1
.end method

.method public addAccount(Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;ZLandroid/os/Bundle;I)V
    .locals 15

    if-eqz p1, :cond_0

    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mContext:Landroid/content/Context;

    move-object/from16 v1, p2

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes;->cannotAddAccount(Landroid/content/Context;Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_0

    const-string v0, "Cage cannot call the Google account authenticator on this Android version"

    sget v1, Landroid/accounts/AccountManager;->ERROR_CODE_UNSUPPORTED_OPERATION:I

    move-object/from16 v2, p1

    invoke-interface {v2, v1, v0}, Landroid/accounts/IAccountManagerResponse;->onError(ILjava/lang/String;)V

    return-void

    .line 1
    :cond_0
    if-eqz p1, :cond_3

    .line 2
    .line 3
    if-eqz p2, :cond_2

    .line 4
    .line 5
    if-nez p6, :cond_1

    .line 6
    .line 7
    new-instance v0, Landroid/os/Bundle;

    .line 8
    .line 9
    invoke-direct {v0}, Landroid/os/Bundle;-><init>()V

    .line 10
    .line 11
    .line 12
    move-object v13, v0

    .line 13
    :goto_0
    move/from16 v0, p7

    .line 14
    .line 15
    goto :goto_1

    .line 16
    :cond_1
    move-object/from16 v13, p6

    .line 17
    .line 18
    goto :goto_0

    .line 19
    :goto_1
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 20
    .line 21
    .line 22
    move-result-object v3

    .line 23
    new-instance v1, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$4;

    .line 24
    .line 25
    const/4 v9, 0x0

    .line 26
    const/4 v10, 0x1

    .line 27
    const/4 v7, 0x1

    .line 28
    const/4 v8, 0x0

    .line 29
    move-object/from16 v14, p2

    .line 30
    .line 31
    move-object v2, p0

    .line 32
    move-object/from16 v4, p1

    .line 33
    .line 34
    move-object/from16 v5, p2

    .line 35
    .line 36
    move-object/from16 v11, p3

    .line 37
    .line 38
    move-object/from16 v12, p4

    .line 39
    .line 40
    move/from16 v6, p5

    .line 41
    .line 42
    invoke-direct/range {v1 .. v14}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$4;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;ZZLjava/lang/String;ZZLjava/lang/String;[Ljava/lang/String;Landroid/os/Bundle;Ljava/lang/String;)V

    .line 43
    .line 44
    .line 45
    invoke-virtual {v1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->bind()V

    .line 46
    .line 47
    .line 48
    return-void

    .line 49
    :cond_2
    new-instance v0, Ljava/lang/IllegalArgumentException;

    .line 50
    .line 51
    const-string v1, "accountType is null"

    .line 52
    .line 53
    invoke-direct {v0, v1}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 54
    .line 55
    .line 56
    throw v0

    .line 57
    :cond_3
    new-instance v0, Ljava/lang/IllegalArgumentException;

    .line 58
    .line 59
    const-string v1, "response is null"

    .line 60
    .line 61
    invoke-direct {v0, v1}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 62
    .line 63
    .line 64
    throw v0
.end method

.method public addAccountAsUser(Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;ZLandroid/os/Bundle;I)V
    .locals 0

    .line 1
    return-void
.end method

.method public addAccountExplicitly(Landroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;I)Z
    .locals 6

    move/from16 v0, p4

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

    .line 1
    const/4 v4, 0x0

    .line 2
    move-object v0, p0

    .line 3
    move-object v1, p1

    .line 4
    move-object v2, p2

    .line 5
    move-object v3, p3

    .line 6
    move v5, p4

    .line 7
    invoke-virtual/range {v0 .. v5}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->addAccountExplicitlyWithVisibility(Landroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;Ljava/util/Map;I)Z

    .line 8
    .line 9
    .line 10
    move-result p1

    .line 11
    return p1
.end method

.method public addAccountExplicitlyWithVisibility(Landroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;Ljava/util/Map;I)Z
    .locals 6

    move/from16 v0, p5

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

    .line 1
    invoke-virtual {p0, p5}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 2
    .line 3
    .line 4
    move-result-object v1

    .line 5
    move-object v0, p0

    .line 6
    move-object v2, p1

    .line 7
    move-object v3, p2

    .line 8
    move-object v4, p3

    .line 9
    move-object v5, p4

    .line 10
    invoke-direct/range {v0 .. v5}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->addAccountInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;Ljava/util/Map;)Z

    .line 11
    .line 12
    .line 13
    move-result p1

    if-eqz p1, :cond_0

    invoke-static {p0, v2, p5}, Lio/github/leexeo/cage/space/GuestAccounts;->accountAdded(Ljava/lang/Object;Landroid/accounts/Account;I)V

    .line 14
    :cond_0
    return p1
.end method

.method public clearPassword(Landroid/accounts/Account;I)V
    .locals 1

    move/from16 v0, p2

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

    .line 1
    const/4 v0, 0x0

    .line 2
    invoke-virtual {p0, p1, v0, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->setPassword(Landroid/accounts/Account;Ljava/lang/String;I)V

    .line 3
    .line 4
    .line 5
    return-void
.end method

.method public confirmCredentialsAsUser(Landroid/accounts/IAccountManagerResponse;Landroid/accounts/Account;Landroid/os/Bundle;ZI)V
    .locals 0

    .line 1
    return-void
.end method

.method public copyAccountToUser(Landroid/accounts/IAccountManagerResponse;Landroid/accounts/Account;II)V
    .locals 13

    .line 1
    move/from16 v12, p3

    .line 2
    .line 3
    move/from16 v0, p4

    .line 4
    .line 5
    invoke-virtual {p0, v12}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 6
    .line 7
    .line 8
    move-result-object v2

    .line 9
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 10
    .line 11
    .line 12
    move-result-object v11

    .line 13
    const-string v1, "AccountManagerService"

    .line 14
    .line 15
    if-eqz v2, :cond_1

    .line 16
    .line 17
    if-nez v11, :cond_0

    .line 18
    .line 19
    goto :goto_0

    .line 20
    :cond_0
    new-instance v3, Ljava/lang/StringBuilder;

    .line 21
    .line 22
    const-string v4, "Copying account "

    .line 23
    .line 24
    invoke-direct {v3, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 25
    .line 26
    .line 27
    invoke-virtual {p2}, Landroid/accounts/Account;->toString()Ljava/lang/String;

    .line 28
    .line 29
    .line 30
    move-result-object v4

    .line 31
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 32
    .line 33
    .line 34
    const-string v4, " from user "

    .line 35
    .line 36
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 37
    .line 38
    .line 39
    invoke-virtual {v3, v12}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 40
    .line 41
    .line 42
    const-string v4, " to user "

    .line 43
    .line 44
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 45
    .line 46
    .line 47
    invoke-virtual {v3, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 48
    .line 49
    .line 50
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 51
    .line 52
    .line 53
    move-result-object v0

    .line 54
    invoke-static {v1, v0}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 55
    .line 56
    .line 57
    new-instance v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$2;

    .line 58
    .line 59
    iget-object v4, p2, Landroid/accounts/Account;->type:Ljava/lang/String;

    .line 60
    .line 61
    iget-object v7, p2, Landroid/accounts/Account;->name:Ljava/lang/String;

    .line 62
    .line 63
    const/4 v6, 0x0

    .line 64
    const/4 v8, 0x0

    .line 65
    const/4 v5, 0x0

    .line 66
    move-object v10, p1

    .line 67
    move-object v1, p0

    .line 68
    move-object v3, p1

    .line 69
    move-object v9, p2

    .line 70
    invoke-direct/range {v0 .. v12}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$2;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;ZZLjava/lang/String;ZLandroid/accounts/Account;Landroid/accounts/IAccountManagerResponse;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;I)V

    .line 71
    .line 72
    .line 73
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->bind()V

    .line 74
    .line 75
    .line 76
    return-void

    .line 77
    :cond_1
    :goto_0
    if-eqz p1, :cond_2

    .line 78
    .line 79
    new-instance p2, Landroid/os/Bundle;

    .line 80
    .line 81
    invoke-direct {p2}, Landroid/os/Bundle;-><init>()V

    .line 82
    .line 83
    .line 84
    const-string v0, "booleanResult"

    .line 85
    .line 86
    const/4 v2, 0x0

    .line 87
    invoke-virtual {p2, v0, v2}, Landroid/os/BaseBundle;->putBoolean(Ljava/lang/String;Z)V

    .line 88
    .line 89
    .line 90
    :try_start_0
    invoke-interface {p1, p2}, Landroid/accounts/IAccountManagerResponse;->onResult(Landroid/os/Bundle;)V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    .line 91
    .line 92
    .line 93
    return-void

    .line 94
    :catch_0
    move-exception v0

    .line 95
    move-object p1, v0

    .line 96
    new-instance p2, Ljava/lang/StringBuilder;

    .line 97
    .line 98
    const-string v0, "Failed to report error back to the client."

    .line 99
    .line 100
    invoke-direct {p2, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 101
    .line 102
    .line 103
    invoke-virtual {p2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 104
    .line 105
    .line 106
    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 107
    .line 108
    .line 109
    move-result-object p1

    .line 110
    invoke-static {v1, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 111
    .line 112
    .line 113
    :cond_2
    return-void
.end method

.method public editProperties(Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;ZI)V
    .locals 10

    .line 1
    if-eqz p1, :cond_1

    .line 2
    .line 3
    if-eqz p2, :cond_0

    .line 4
    .line 5
    invoke-virtual {p0, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 6
    .line 7
    .line 8
    move-result-object v2

    .line 9
    new-instance v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$6;

    .line 10
    .line 11
    const/4 v7, 0x0

    .line 12
    const/4 v8, 0x0

    .line 13
    const/4 v6, 0x1

    .line 14
    move-object v9, p2

    .line 15
    move-object v1, p0

    .line 16
    move-object v3, p1

    .line 17
    move-object v4, p2

    .line 18
    move v5, p3

    .line 19
    invoke-direct/range {v0 .. v9}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$6;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;ZZLjava/lang/String;ZLjava/lang/String;)V

    .line 20
    .line 21
    .line 22
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->bind()V

    .line 23
    .line 24
    .line 25
    return-void

    .line 26
    :cond_0
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 27
    .line 28
    const-string p2, "accountType is null"

    .line 29
    .line 30
    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 31
    .line 32
    .line 33
    throw p1

    .line 34
    :cond_1
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 35
    .line 36
    const-string p2, "response is null"

    .line 37
    .line 38
    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 39
    .line 40
    .line 41
    throw p1
.end method

.method public getAccountByTypeAndFeatures(Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;[Ljava/lang/String;I)V
    .locals 9

    .line 1
    if-eqz p1, :cond_2

    .line 2
    .line 3
    if-eqz p2, :cond_1

    .line 4
    .line 5
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getCallingPackageName()Ljava/lang/String;

    .line 6
    .line 7
    .line 8
    move-result-object v7

    .line 9
    invoke-virtual {p0, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 10
    .line 11
    .line 12
    move-result-object v2

    .line 13
    invoke-static {p3}, Ltop/niunaijun/blackbox/utils/ArrayUtils;->isEmpty([Ljava/lang/Object;)Z

    .line 14
    .line 15
    .line 16
    move-result v0

    .line 17
    if-eqz v0, :cond_0

    .line 18
    .line 19
    const/4 p3, 0x1

    .line 20
    invoke-virtual {p0, v2, p2, v7, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getAccountsFromCache(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Ljava/lang/String;Ljava/lang/String;Z)[Landroid/accounts/Account;

    .line 21
    .line 22
    .line 23
    move-result-object p2

    .line 24
    invoke-direct {p0, p1, p2, v7, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->handleGetAccountsResult(Landroid/accounts/IAccountManagerResponse;[Landroid/accounts/Account;Ljava/lang/String;I)V

    .line 25
    .line 26
    .line 27
    return-void

    .line 28
    :cond_0
    new-instance v3, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$1;

    .line 29
    .line 30
    invoke-direct {v3, p0, p1, v7, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$1;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;I)V

    .line 31
    .line 32
    .line 33
    new-instance v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$GetAccountsByTypeAndFeatureSession;

    .line 34
    .line 35
    const/4 v8, 0x1

    .line 36
    move-object v1, p0

    .line 37
    move-object v4, p2

    .line 38
    move-object v5, p3

    .line 39
    move v6, p4

    .line 40
    invoke-direct/range {v0 .. v8}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$GetAccountsByTypeAndFeatureSession;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;[Ljava/lang/String;ILjava/lang/String;Z)V

    .line 41
    .line 42
    .line 43
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->bind()V

    .line 44
    .line 45
    .line 46
    return-void

    .line 47
    :cond_1
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 48
    .line 49
    const-string p2, "accountType is null"

    .line 50
    .line 51
    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 52
    .line 53
    .line 54
    throw p1

    .line 55
    :cond_2
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 56
    .line 57
    const-string p2, "response is null"

    .line 58
    .line 59
    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 60
    .line 61
    .line 62
    throw p1
.end method

.method public getAccountVisibility(Landroid/accounts/Account;Ljava/lang/String;I)I
    .locals 1

    invoke-static {p0, p1, p2, p3}, Lio/github/leexeo/cage/space/GuestAccounts;->visibility(Ljava/lang/Object;Landroid/accounts/Account;Ljava/lang/String;I)I

    move-result v0

    return v0
.end method

.method public getAccounts(ILjava/lang/String;)[Landroid/accounts/Account;
    .locals 0

    .line 1
    invoke-virtual {p0, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 2
    .line 3
    .line 4
    move-result-object p1

    .line 5
    iget-object p1, p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->accounts:Ljava/util/List;

    .line 6
    .line 7
    const/4 p2, 0x0

    .line 8
    new-array p2, p2, [Landroid/accounts/Account;

    .line 9
    .line 10
    invoke-interface {p1, p2}, Ljava/util/List;->toArray([Ljava/lang/Object;)[Ljava/lang/Object;

    .line 11
    .line 12
    .line 13
    move-result-object p1

    .line 14
    check-cast p1, [Landroid/accounts/Account;

    .line 15
    .line 16
    return-object p1
.end method

.method public getAccountsAndVisibilityForPackage(Ljava/lang/String;Ljava/lang/String;I)Ljava/util/Map;
    .locals 1

    invoke-static {p0, p1, p2, p3}, Lio/github/leexeo/cage/space/GuestAccounts;->accountVisibility(Ljava/lang/Object;Ljava/lang/String;Ljava/lang/String;I)Ljava/util/Map;

    move-result-object v0

    return-object v0
.end method

.method public getAccountsAsUser(Ljava/lang/String;I)[Landroid/accounts/Account;
    .locals 1

    const/4 v0, 0x0

    invoke-static {p0, p1, p2, v0}, Lio/github/leexeo/cage/space/GuestAccounts;->accounts(Ljava/lang/Object;Ljava/lang/String;ILjava/lang/String;)[Landroid/accounts/Account;

    move-result-object v0

    return-object v0
.end method

.method public getAccountsByFeatures(Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;[Ljava/lang/String;I)V
    .locals 9

    .line 1
    if-eqz p1, :cond_3

    .line 2
    .line 3
    if-eqz p2, :cond_2

    .line 4
    .line 5
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getCallingPackageName()Ljava/lang/String;

    .line 6
    .line 7
    .line 8
    move-result-object v7

    .line 9
    invoke-virtual {p0, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 10
    .line 11
    .line 12
    move-result-object v2

    .line 13
    if-eqz p3, :cond_0

    .line 14
    .line 15
    array-length v0, p3

    .line 16
    if-nez v0, :cond_1

    .line 17
    .line 18
    :cond_0
    move-object v1, p0

    .line 19
    move-object v3, p1

    .line 20
    move-object v4, p2

    .line 21
    goto :goto_0

    .line 22
    :cond_1
    new-instance v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$GetAccountsByTypeAndFeatureSession;

    .line 23
    .line 24
    const/4 v8, 0x0

    .line 25
    move-object v1, p0

    .line 26
    move-object v3, p1

    .line 27
    move-object v4, p2

    .line 28
    move-object v5, p3

    .line 29
    move v6, p4

    .line 30
    invoke-direct/range {v0 .. v8}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$GetAccountsByTypeAndFeatureSession;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;[Ljava/lang/String;ILjava/lang/String;Z)V

    .line 31
    .line 32
    .line 33
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->bind()V

    .line 34
    .line 35
    .line 36
    return-void

    .line 37
    :goto_0
    const/4 p1, 0x0

    .line 38
    invoke-virtual {p0, v2, v4, v7, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getAccountsFromCache(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Ljava/lang/String;Ljava/lang/String;Z)[Landroid/accounts/Account;

    .line 39
    .line 40
    .line 41
    move-result-object p1

    .line 42
    new-instance p2, Landroid/os/Bundle;

    .line 43
    .line 44
    invoke-direct {p2}, Landroid/os/Bundle;-><init>()V

    .line 45
    .line 46
    .line 47
    const-string p3, "accounts"

    .line 48
    .line 49
    invoke-virtual {p2, p3, p1}, Landroid/os/Bundle;->putParcelableArray(Ljava/lang/String;[Landroid/os/Parcelable;)V

    .line 50
    .line 51
    .line 52
    invoke-direct {p0, v3, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->onResult(Landroid/accounts/IAccountManagerResponse;Landroid/os/Bundle;)V

    .line 53
    .line 54
    .line 55
    return-void

    .line 56
    :cond_2
    move-object v1, p0

    .line 57
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 58
    .line 59
    const-string p2, "accountType is null"

    .line 60
    .line 61
    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 62
    .line 63
    .line 64
    throw p1

    .line 65
    :cond_3
    move-object v1, p0

    .line 66
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 67
    .line 68
    const-string p2, "response is null"

    .line 69
    .line 70
    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 71
    .line 72
    .line 73
    throw p1
.end method

.method public getAccountsByTypeForPackage(Ljava/lang/String;Ljava/lang/String;I)[Landroid/accounts/Account;
    .locals 1

    const/4 v0, 0x0

    invoke-static {p0, p1, p3, p2}, Lio/github/leexeo/cage/space/GuestAccounts;->accounts(Ljava/lang/Object;Ljava/lang/String;ILjava/lang/String;)[Landroid/accounts/Account;

    move-result-object v0

    return-object v0
.end method

.method public getAccountsForPackage(Ljava/lang/String;II)[Landroid/accounts/Account;
    .locals 1

    const/4 v0, 0x0

    invoke-static {p0, v0, p3, p1}, Lio/github/leexeo/cage/space/GuestAccounts;->accounts(Ljava/lang/Object;Ljava/lang/String;ILjava/lang/String;)[Landroid/accounts/Account;

    move-result-object v0

    return-object v0
.end method

.method public getAccountsFromCache(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Ljava/lang/String;Ljava/lang/String;Z)[Landroid/accounts/Account;
    .locals 6

    .line 1
    if-eqz p2, :cond_1

    .line 2
    .line 3
    iget-object v0, p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 4
    .line 5
    monitor-enter v0

    .line 6
    :try_start_0
    invoke-virtual {p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAccountsByType(Ljava/lang/String;)[Landroid/accounts/Account;

    .line 7
    .line 8
    .line 9
    move-result-object p2

    .line 10
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 11
    if-nez p2, :cond_0

    .line 12
    .line 13
    sget-object p1, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->EMPTY_ACCOUNT_ARRAY:[Landroid/accounts/Account;

    .line 14
    .line 15
    return-object p1

    .line 16
    :cond_0
    array-length v0, p2

    .line 17
    invoke-static {p2, v0}, Ljava/util/Arrays;->copyOf([Ljava/lang/Object;I)[Ljava/lang/Object;

    .line 18
    .line 19
    .line 20
    move-result-object p2

    .line 21
    check-cast p2, [Landroid/accounts/Account;

    .line 22
    .line 23
    invoke-direct {p0, p1, p2, p3, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->filterAccounts(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;[Landroid/accounts/Account;Ljava/lang/String;Z)[Landroid/accounts/Account;

    .line 24
    .line 25
    .line 26
    move-result-object p1

    .line 27
    return-object p1

    .line 28
    :catchall_0
    move-exception p1

    .line 29
    :try_start_1
    monitor-exit v0
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 30
    throw p1

    .line 31
    :cond_1
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 32
    .line 33
    monitor-enter p2

    .line 34
    :try_start_2
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 35
    .line 36
    invoke-interface {v0}, Ljava/util/Map;->values()Ljava/util/Collection;

    .line 37
    .line 38
    .line 39
    move-result-object v0

    .line 40
    invoke-interface {v0}, Ljava/util/Collection;->iterator()Ljava/util/Iterator;

    .line 41
    .line 42
    .line 43
    move-result-object v0

    .line 44
    const/4 v1, 0x0

    .line 45
    move v2, v1

    .line 46
    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    .line 47
    .line 48
    .line 49
    move-result v3

    .line 50
    if-eqz v3, :cond_2

    .line 51
    .line 52
    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 53
    .line 54
    .line 55
    move-result-object v3

    .line 56
    check-cast v3, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 57
    .line 58
    invoke-virtual {v3}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->toAccounts()[Landroid/accounts/Account;

    .line 59
    .line 60
    .line 61
    move-result-object v3

    .line 62
    array-length v3, v3

    .line 63
    add-int/2addr v2, v3

    .line 64
    goto :goto_0

    .line 65
    :catchall_1
    move-exception p1

    .line 66
    goto :goto_2

    .line 67
    :cond_2
    if-nez v2, :cond_3

    .line 68
    .line 69
    sget-object p1, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->EMPTY_ACCOUNT_ARRAY:[Landroid/accounts/Account;

    .line 70
    .line 71
    monitor-exit p2

    .line 72
    return-object p1

    .line 73
    :cond_3
    new-array v0, v2, [Landroid/accounts/Account;

    .line 74
    .line 75
    iget-object v2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 76
    .line 77
    invoke-interface {v2}, Ljava/util/Map;->values()Ljava/util/Collection;

    .line 78
    .line 79
    .line 80
    move-result-object v2

    .line 81
    invoke-interface {v2}, Ljava/util/Collection;->iterator()Ljava/util/Iterator;

    .line 82
    .line 83
    .line 84
    move-result-object v2

    .line 85
    move v3, v1

    .line 86
    :goto_1
    invoke-interface {v2}, Ljava/util/Iterator;->hasNext()Z

    .line 87
    .line 88
    .line 89
    move-result v4

    .line 90
    if-eqz v4, :cond_4

    .line 91
    .line 92
    invoke-interface {v2}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 93
    .line 94
    .line 95
    move-result-object v4

    .line 96
    check-cast v4, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 97
    .line 98
    invoke-virtual {v4}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->toAccounts()[Landroid/accounts/Account;

    .line 99
    .line 100
    .line 101
    move-result-object v4

    .line 102
    array-length v5, v4

    .line 103
    invoke-static {v4, v1, v0, v3, v5}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 104
    .line 105
    .line 106
    array-length v4, v4

    .line 107
    add-int/2addr v3, v4

    .line 108
    goto :goto_1

    .line 109
    :cond_4
    monitor-exit p2
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    .line 110
    invoke-direct {p0, p1, v0, p3, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->filterAccounts(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;[Landroid/accounts/Account;Ljava/lang/String;Z)[Landroid/accounts/Account;

    .line 111
    .line 112
    .line 113
    move-result-object p1

    .line 114
    return-object p1

    .line 115
    :goto_2
    :try_start_3
    monitor-exit p2
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    .line 116
    throw p1
.end method

.method public getAuthToken(Landroid/accounts/IAccountManagerResponse;Landroid/accounts/Account;Ljava/lang/String;ZZLandroid/os/Bundle;I)V
    .locals 15

    move-object/from16 v0, p0

    move-object/from16 v1, p2

    move-object/from16 v2, p6

    move/from16 v3, p7

    invoke-static {v0, v1, v2, v3}, Lio/github/leexeo/cage/space/GuestAccounts;->authorize(Ljava/lang/Object;Landroid/accounts/Account;Landroid/os/Bundle;I)Landroid/os/Bundle;

    move-result-object v0

    move-object/from16 p6, v0

    .line 1
    move-object/from16 v3, p1

    .line 2
    .line 3
    move-object/from16 v10, p2

    .line 4
    .line 5
    move-object/from16 v11, p3

    .line 6
    .line 7
    move-object/from16 v9, p6

    .line 8
    .line 9
    const/4 v0, 0x0

    .line 10
    const/4 v1, 0x1

    .line 11
    if-eqz v3, :cond_0

    .line 12
    .line 13
    move v2, v1

    .line 14
    goto :goto_0

    .line 15
    :cond_0
    move v2, v0

    .line 16
    :goto_0
    const-string v4, "response cannot be null"

    .line 17
    .line 18
    invoke-static {v4, v2}, Le5/a;->f(Ljava/lang/String;Z)V

    .line 19
    .line 20
    .line 21
    const/4 v2, 0x7

    .line 22
    const-string v4, "AccountManagerService"

    .line 23
    .line 24
    if-nez v10, :cond_1

    .line 25
    .line 26
    :try_start_0
    const-string v0, "getAuthToken called with null account"

    .line 27
    .line 28
    invoke-static {v4, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 29
    .line 30
    .line 31
    const-string v0, "account is null"

    .line 32
    .line 33
    invoke-interface {v3, v2, v0}, Landroid/accounts/IAccountManagerResponse;->onError(ILjava/lang/String;)V

    .line 34
    .line 35
    .line 36
    return-void

    .line 37
    :catch_0
    move-exception v0

    .line 38
    goto :goto_1

    .line 39
    :cond_1
    if-nez v11, :cond_2

    .line 40
    .line 41
    const-string v0, "getAuthToken called with null authTokenType"

    .line 42
    .line 43
    invoke-static {v4, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 44
    .line 45
    .line 46
    const-string v0, "authTokenType is null"

    .line 47
    .line 48
    invoke-interface {v3, v2, v0}, Landroid/accounts/IAccountManagerResponse;->onError(ILjava/lang/String;)V
    :try_end_0
    .catch Landroid/os/RemoteException; {:try_start_0 .. :try_end_0} :catch_0

    .line 49
    .line 50
    .line 51
    return-void

    .line 52
    :goto_1
    new-instance v1, Ljava/lang/StringBuilder;

    .line 53
    .line 54
    const-string v2, "Failed to report error back to the client."

    .line 55
    .line 56
    invoke-direct {v1, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 57
    .line 58
    .line 59
    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 60
    .line 61
    .line 62
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 63
    .line 64
    .line 65
    move-result-object v0

    .line 66
    invoke-static {v4, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 67
    .line 68
    .line 69
    return-void

    .line 70
    :cond_2
    move/from16 v2, p7

    .line 71
    .line 72
    invoke-virtual {p0, v2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 73
    .line 74
    .line 75
    move-result-object v2

    .line 76
    iget-object v5, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mAuthenticatorCache:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;

    .line 77
    .line 78
    iget-object v5, v5, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;->authenticators:Ljava/util/Map;

    .line 79
    .line 80
    iget-object v6, v10, Landroid/accounts/Account;->type:Ljava/lang/String;

    .line 81
    .line 82
    invoke-interface {v5, v6}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 83
    .line 84
    .line 85
    move-result-object v5

    .line 86
    check-cast v5, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorInfo;

    .line 87
    .line 88
    if-eqz v5, :cond_3

    .line 89
    .line 90
    iget-object v5, v5, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorInfo;->desc:Landroid/accounts/AuthenticatorDescription;

    .line 91
    .line 92
    iget-boolean v5, v5, Landroid/accounts/AuthenticatorDescription;->customTokens:Z

    .line 93
    .line 94
    if-eqz v5, :cond_3

    .line 95
    .line 96
    move v13, v1

    .line 97
    goto :goto_2

    .line 98
    :cond_3
    move v13, v0

    .line 99
    :goto_2
    const-string v0, "androidPackageName"

    .line 100
    .line 101
    invoke-virtual {v9, v0}, Landroid/os/BaseBundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    .line 102
    .line 103
    .line 104
    move-result-object v14

    .line 105
    invoke-static {}, Lio/github/leexeo/cage/space/GuestAccounts;->callerUid()I

    .line 106
    .line 107
    .line 108
    move-result v0

    .line 109
    const-string v5, "callerUid"

    .line 110
    .line 111
    invoke-virtual {v9, v5, v0}, Landroid/os/BaseBundle;->putInt(Ljava/lang/String;I)V

    .line 112
    .line 113
    .line 114
    invoke-static {}, Landroid/os/Binder;->getCallingPid()I

    .line 115
    .line 116
    .line 117
    move-result v0

    .line 118
    const-string v5, "callerPid"

    .line 119
    .line 120
    invoke-virtual {v9, v5, v0}, Landroid/os/BaseBundle;->putInt(Ljava/lang/String;I)V

    .line 121
    .line 122
    .line 123
    if-eqz p4, :cond_4

    .line 124
    .line 125
    const-string v0, "notifyOnAuthFailure"

    .line 126
    .line 127
    invoke-virtual {v9, v0, v1}, Landroid/os/BaseBundle;->putBoolean(Ljava/lang/String;Z)V

    .line 128
    .line 129
    .line 130
    :cond_4
    const-string v0, "accountType"

    .line 131
    .line 132
    const-string v1, "authAccount"

    .line 133
    .line 134
    const-string v5, "authtoken"

    .line 135
    .line 136
    if-nez v13, :cond_5

    .line 137
    .line 138
    invoke-virtual {p0, v2, v10, v11}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->readAuthTokenInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;Ljava/lang/String;)Ljava/lang/String;

    .line 139
    .line 140
    .line 141
    move-result-object v6

    .line 142
    if-eqz v6, :cond_5

    .line 143
    .line 144
    new-instance v2, Landroid/os/Bundle;

    .line 145
    .line 146
    invoke-direct {v2}, Landroid/os/Bundle;-><init>()V

    .line 147
    .line 148
    .line 149
    invoke-virtual {v2, v5, v6}, Landroid/os/BaseBundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    .line 150
    .line 151
    .line 152
    iget-object v4, v10, Landroid/accounts/Account;->name:Ljava/lang/String;

    .line 153
    .line 154
    invoke-virtual {v2, v1, v4}, Landroid/os/BaseBundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    .line 155
    .line 156
    .line 157
    iget-object v1, v10, Landroid/accounts/Account;->type:Ljava/lang/String;

    .line 158
    .line 159
    invoke-virtual {v2, v0, v1}, Landroid/os/BaseBundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    .line 160
    .line 161
    .line 162
    invoke-direct {p0, v3, v2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->onResult(Landroid/accounts/IAccountManagerResponse;Landroid/os/Bundle;)V

    .line 163
    .line 164
    .line 165
    return-void

    .line 166
    :cond_5
    if-eqz v13, :cond_7

    .line 167
    .line 168
    invoke-virtual {p0, v2, v10, v11, v14}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->readCachedTokenInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    .line 169
    .line 170
    .line 171
    move-result-object v6

    .line 172
    if-eqz v6, :cond_7

    .line 173
    .line 174
    const/4 v2, 0x2

    .line 175
    invoke-static {v4, v2}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 176
    .line 177
    .line 178
    move-result v2

    .line 179
    if-eqz v2, :cond_6

    .line 180
    .line 181
    const-string v2, "getAuthToken: cache hit ofr custom token authenticator."

    .line 182
    .line 183
    invoke-static {v4, v2}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 184
    .line 185
    .line 186
    :cond_6
    new-instance v2, Landroid/os/Bundle;

    .line 187
    .line 188
    invoke-direct {v2}, Landroid/os/Bundle;-><init>()V

    .line 189
    .line 190
    .line 191
    invoke-virtual {v2, v5, v6}, Landroid/os/BaseBundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    .line 192
    .line 193
    .line 194
    iget-object v4, v10, Landroid/accounts/Account;->name:Ljava/lang/String;

    .line 195
    .line 196
    invoke-virtual {v2, v1, v4}, Landroid/os/BaseBundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    .line 197
    .line 198
    .line 199
    iget-object v1, v10, Landroid/accounts/Account;->type:Ljava/lang/String;

    .line 200
    .line 201
    invoke-virtual {v2, v0, v1}, Landroid/os/BaseBundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    .line 202
    .line 203
    .line 204
    invoke-direct {p0, v3, v2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->onResult(Landroid/accounts/IAccountManagerResponse;Landroid/os/Bundle;)V

    .line 205
    .line 206
    .line 207
    return-void

    .line 208
    :cond_7
    new-instance v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$3;

    .line 209
    .line 210
    iget-object v4, v10, Landroid/accounts/Account;->type:Ljava/lang/String;

    .line 211
    .line 212
    iget-object v7, v10, Landroid/accounts/Account;->name:Ljava/lang/String;

    .line 213
    .line 214
    const/4 v6, 0x0

    .line 215
    const/4 v8, 0x0

    .line 216
    move-object v1, p0

    .line 217
    move/from16 v12, p4

    .line 218
    .line 219
    move/from16 v5, p5

    .line 220
    .line 221
    invoke-direct/range {v0 .. v14}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$3;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;ZZLjava/lang/String;ZLandroid/os/Bundle;Landroid/accounts/Account;Ljava/lang/String;ZZLjava/lang/String;)V

    .line 222
    .line 223
    .line 224
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->bind()V

    .line 225
    .line 226
    .line 227
    return-void
.end method

.method public getAuthTokenLabel(Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;Ljava/lang/String;I)V
    .locals 11

    .line 1
    const/4 v0, 0x0

    .line 2
    const/4 v1, 0x1

    .line 3
    if-eqz p2, :cond_0

    .line 4
    .line 5
    move v2, v1

    .line 6
    goto :goto_0

    .line 7
    :cond_0
    move v2, v0

    .line 8
    :goto_0
    const-string v3, "accountType cannot be null"

    .line 9
    .line 10
    invoke-static {v3, v2}, Le5/a;->f(Ljava/lang/String;Z)V

    .line 11
    .line 12
    .line 13
    if-eqz p3, :cond_1

    .line 14
    .line 15
    move v0, v1

    .line 16
    :cond_1
    const-string v1, "authTokenType cannot be null"

    .line 17
    .line 18
    invoke-static {v1, v0}, Le5/a;->f(Ljava/lang/String;Z)V

    .line 19
    .line 20
    .line 21
    invoke-virtual {p0, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 22
    .line 23
    .line 24
    move-result-object v2

    .line 25
    new-instance v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$7;

    .line 26
    .line 27
    const/4 v7, 0x0

    .line 28
    const/4 v8, 0x0

    .line 29
    const/4 v5, 0x0

    .line 30
    const/4 v6, 0x0

    .line 31
    move-object v9, p2

    .line 32
    move-object v1, p0

    .line 33
    move-object v3, p1

    .line 34
    move-object v4, p2

    .line 35
    move-object v10, p3

    .line 36
    invoke-direct/range {v0 .. v10}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$7;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;ZZLjava/lang/String;ZLjava/lang/String;Ljava/lang/String;)V

    .line 37
    .line 38
    .line 39
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->bind()V

    .line 40
    .line 41
    .line 42
    return-void
.end method

.method public getAuthenticatorTypes(I)[Landroid/accounts/AuthenticatorDescription;
    .locals 1

    invoke-static {}, Landroid/os/Binder;->getCallingPid()I

    move-result v0

    invoke-static {p1, v0}, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes;->forCaller(II)[Landroid/accounts/AuthenticatorDescription;

    move-result-object v0

    return-object v0
.end method

.method public getPackagesAndVisibilityForAccount(Landroid/accounts/Account;I)Ljava/util/Map;
    .locals 1

    invoke-static {p0, p1, p2}, Lio/github/leexeo/cage/space/GuestAccounts;->ownerVisibility(Ljava/lang/Object;Landroid/accounts/Account;I)Ljava/util/Map;

    move-result-object v0

    return-object v0
.end method

.method public getPassword(Landroid/accounts/Account;I)Ljava/lang/String;
    .locals 3

    move/from16 v0, p2

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

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
    const-string v2, "getPassword: "

    .line 13
    .line 14
    invoke-direct {v0, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 15
    .line 16
    .line 17
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 18
    .line 19
    .line 20
    const-string v2, ", caller\'s uid "

    .line 21
    .line 22
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 23
    .line 24
    .line 25
    invoke-static {}, Landroid/os/Binder;->getCallingUid()I

    .line 26
    .line 27
    .line 28
    move-result v2

    .line 29
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 30
    .line 31
    .line 32
    const-string v2, ", pid "

    .line 33
    .line 34
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 35
    .line 36
    .line 37
    invoke-static {}, Landroid/os/Binder;->getCallingPid()I

    .line 38
    .line 39
    .line 40
    move-result v2

    .line 41
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 42
    .line 43
    .line 44
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 45
    .line 46
    .line 47
    move-result-object v0

    .line 48
    invoke-static {v1, v0}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 49
    .line 50
    .line 51
    :cond_0
    if-eqz p1, :cond_1

    .line 52
    .line 53
    invoke-virtual {p0, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 54
    .line 55
    .line 56
    move-result-object p2

    .line 57
    invoke-virtual {p0, p2, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->readPasswordInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;)Ljava/lang/String;

    .line 58
    .line 59
    .line 60
    move-result-object p1

    .line 61
    return-object p1

    .line 62
    :cond_1
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 63
    .line 64
    const-string p2, "account is null"

    .line 65
    .line 66
    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 67
    .line 68
    .line 69
    throw p1
.end method

.method public getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;
    .locals 4

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 2
    .line 3
    monitor-enter v0

    .line 4
    :try_start_0
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 5
    .line 6
    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 7
    .line 8
    .line 9
    move-result-object v2

    .line 10
    invoke-interface {v1, v2}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 11
    .line 12
    .line 13
    move-result-object v1

    .line 14
    check-cast v1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 15
    .line 16
    if-nez v1, :cond_0

    .line 17
    .line 18
    new-instance v1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 19
    .line 20
    invoke-direct {v1}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;-><init>()V

    .line 21
    .line 22
    .line 23
    iget-object v2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 24
    .line 25
    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 26
    .line 27
    .line 28
    move-result-object v3

    .line 29
    invoke-interface {v2, v3, v1}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 30
    .line 31
    .line 32
    goto :goto_0

    .line 33
    :catchall_0
    move-exception p1

    .line 34
    goto :goto_1

    .line 35
    :cond_0
    :goto_0
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mUserAccountsMap:Ljava/util/Map;

    .line 36
    .line 37
    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 38
    .line 39
    .line 40
    move-result-object p1

    .line 41
    invoke-interface {v1, p1}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 42
    .line 43
    .line 44
    move-result-object p1

    .line 45
    check-cast p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 46
    .line 47
    monitor-exit v0

    .line 48
    return-object p1

    .line 49
    :goto_1
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 50
    throw p1
.end method

.method public getUserData(Landroid/accounts/Account;Ljava/lang/String;I)Ljava/lang/String;
    .locals 3

    move/from16 v0, p3

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

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
    invoke-static {}, Landroid/os/Binder;->getCallingUid()I

    .line 11
    .line 12
    .line 13
    move-result v0

    .line 14
    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 15
    .line 16
    .line 17
    move-result-object v0

    .line 18
    invoke-static {}, Landroid/os/Binder;->getCallingPid()I

    .line 19
    .line 20
    .line 21
    move-result v2

    .line 22
    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 23
    .line 24
    .line 25
    move-result-object v2

    .line 26
    filled-new-array {p1, p2, v0, v2}, [Ljava/lang/Object;

    .line 27
    .line 28
    .line 29
    move-result-object v0

    .line 30
    const-string v2, "getUserData( account: %s, key: %s, callerUid: %s, pid: %s"

    .line 31
    .line 32
    invoke-static {v2, v0}, Ljava/lang/String;->format(Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/String;

    .line 33
    .line 34
    .line 35
    move-result-object v0

    .line 36
    invoke-static {v1, v0}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 37
    .line 38
    .line 39
    :cond_0
    const-string v0, "account cannot be null"

    .line 40
    .line 41
    invoke-static {p1, v0}, Ljava/util/Objects;->requireNonNull(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    .line 42
    .line 43
    .line 44
    const-string v0, "key cannot be null"

    .line 45
    .line 46
    invoke-static {p2, v0}, Ljava/util/Objects;->requireNonNull(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    .line 47
    .line 48
    .line 49
    invoke-virtual {p0, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 50
    .line 51
    .line 52
    move-result-object p3

    .line 53
    invoke-direct {p0, p3, p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->readUserDataInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;Ljava/lang/String;)Ljava/lang/String;

    .line 54
    .line 55
    .line 56
    move-result-object p1

    .line 57
    return-object p1
.end method

.method public invalidateAuthToken(Ljava/lang/String;Ljava/lang/String;I)V
    .locals 5

    .line 1
    invoke-virtual {p0, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    iget-object v1, v0, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 6
    .line 7
    monitor-enter v1

    .line 8
    :try_start_0
    iget-object v0, v0, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->accounts:Ljava/util/List;

    .line 9
    .line 10
    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    .line 11
    .line 12
    .line 13
    move-result-object v0

    .line 14
    const/4 v2, 0x0

    .line 15
    :cond_0
    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    .line 16
    .line 17
    .line 18
    move-result v3

    .line 19
    if-eqz v3, :cond_1

    .line 20
    .line 21
    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 22
    .line 23
    .line 24
    move-result-object v3

    .line 25
    check-cast v3, Ltop/niunaijun/blackbox/core/system/accounts/BAccount;

    .line 26
    .line 27
    iget-object v4, v3, Ltop/niunaijun/blackbox/core/system/accounts/BAccount;->account:Landroid/accounts/Account;

    .line 28
    .line 29
    iget-object v4, v4, Landroid/accounts/Account;->type:Ljava/lang/String;

    .line 30
    .line 31
    invoke-virtual {v4, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 32
    .line 33
    .line 34
    move-result v4

    .line 35
    if-eqz v4, :cond_0

    .line 36
    .line 37
    iget-object v2, v3, Ltop/niunaijun/blackbox/core/system/accounts/BAccount;->accountUserData:Ljava/util/HashMap;

    .line 38
    .line 39
    invoke-virtual {v2}, Ljava/util/HashMap;->values()Ljava/util/Collection;

    .line 40
    .line 41
    .line 42
    move-result-object v2

    .line 43
    invoke-interface {v2, p2}, Ljava/util/Collection;->remove(Ljava/lang/Object;)Z

    .line 44
    .line 45
    .line 46
    const/4 v2, 0x1

    .line 47
    goto :goto_0

    .line 48
    :catchall_0
    move-exception p1

    .line 49
    goto :goto_3

    .line 50
    :cond_1
    if-eqz v2, :cond_2

    .line 51
    .line 52
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->saveAllAccounts()V

    .line 53
    .line 54
    .line 55
    :cond_2
    monitor-exit v1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 56
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mTokenCaches:Ljava/util/LinkedList;

    .line 57
    .line 58
    monitor-enter v0

    .line 59
    :try_start_1
    iget-object v1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mTokenCaches:Ljava/util/LinkedList;

    .line 60
    .line 61
    invoke-virtual {v1}, Ljava/util/AbstractCollection;->iterator()Ljava/util/Iterator;

    .line 62
    .line 63
    .line 64
    move-result-object v1

    .line 65
    :cond_3
    :goto_1
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    .line 66
    .line 67
    .line 68
    move-result v2

    .line 69
    if-eqz v2, :cond_4

    .line 70
    .line 71
    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 72
    .line 73
    .line 74
    move-result-object v2

    .line 75
    check-cast v2, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;

    .line 76
    .line 77
    iget-object v3, v2, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;->account:Landroid/accounts/Account;

    .line 78
    .line 79
    iget-object v3, v3, Landroid/accounts/Account;->type:Ljava/lang/String;

    .line 80
    .line 81
    invoke-virtual {v3, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 82
    .line 83
    .line 84
    move-result v3

    .line 85
    if-eqz v3, :cond_3

    .line 86
    .line 87
    iget v3, v2, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;->userId:I

    .line 88
    .line 89
    if-ne v3, p3, :cond_3

    .line 90
    .line 91
    iget-object v2, v2, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;->authToken:Ljava/lang/String;

    .line 92
    .line 93
    invoke-virtual {v2, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 94
    .line 95
    .line 96
    move-result v2

    .line 97
    if-eqz v2, :cond_3

    .line 98
    .line 99
    invoke-interface {v1}, Ljava/util/Iterator;->remove()V

    .line 100
    .line 101
    .line 102
    goto :goto_1

    .line 103
    :catchall_1
    move-exception p1

    .line 104
    goto :goto_2

    .line 105
    :cond_4
    monitor-exit v0

    .line 106
    return-void

    .line 107
    :goto_2
    monitor-exit v0
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    .line 108
    throw p1

    .line 109
    :goto_3
    :try_start_2
    monitor-exit v1
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    .line 110
    throw p1
.end method

.method public loadAuthenticatorCache(Ljava/lang/String;)V
    .locals 3

    .line 1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mAuthenticatorCache:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;

    .line 2
    .line 3
    iget-object v0, v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;->authenticators:Ljava/util/Map;

    .line 4
    .line 5
    invoke-interface {v0}, Ljava/util/Map;->clear()V

    .line 6
    .line 7
    .line 8
    new-instance v0, Landroid/content/Intent;

    .line 9
    .line 10
    const-string v1, "android.accounts.AccountAuthenticator"

    .line 11
    .line 12
    invoke-direct {v0, v1}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V

    .line 13
    .line 14
    .line 15
    if-eqz p1, :cond_0

    .line 16
    .line 17
    invoke-virtual {v0, p1}, Landroid/content/Intent;->setPackage(Ljava/lang/String;)Landroid/content/Intent;

    .line 18
    .line 19
    .line 20
    :cond_0
    iget-object p1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mPms:Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;

    .line 21
    .line 22
    const/16 v1, 0x80

    .line 23
    .line 24
    const/4 v2, -0x1

    .line 25
    invoke-virtual {p1, v0, v1, v2}, Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;->queryIntentServices(Landroid/content/Intent;II)Ljava/util/List;

    .line 26
    .line 27
    .line 28
    move-result-object p1

    .line 29
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mAuthenticatorCache:Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;

    .line 30
    .line 31
    iget-object v0, v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$AuthenticatorCache;->authenticators:Ljava/util/Map;

    .line 32
    .line 33
    new-instance v1, Ltop/niunaijun/blackbox/core/system/accounts/RegisteredServicesParser;

    .line 34
    .line 35
    invoke-direct {v1}, Ltop/niunaijun/blackbox/core/system/accounts/RegisteredServicesParser;-><init>()V

    .line 36
    .line 37
    .line 38
    invoke-direct {p0, p1, v0, v1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->generateServicesMap(Ljava/util/List;Ljava/util/Map;Ltop/niunaijun/blackbox/core/system/accounts/RegisteredServicesParser;)V

    .line 39
    .line 40
    .line 41
    return-void
.end method

.method public onPackageInstalled(Ljava/lang/String;I)V
    .locals 0

    .line 1
    invoke-virtual {p0, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->loadAuthenticatorCache(Ljava/lang/String;)V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method public onPackageUninstalled(Ljava/lang/String;ZI)V
    .locals 0

    .line 1
    const/4 p1, 0x0

    .line 2
    invoke-virtual {p0, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->loadAuthenticatorCache(Ljava/lang/String;)V

    .line 3
    .line 4
    .line 5
    return-void
.end method

.method public peekAuthToken(Landroid/accounts/Account;Ljava/lang/String;I)Ljava/lang/String;
    .locals 1

    move/from16 v0, p3

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

    .line 1
    const-string v0, "account cannot be null"

    .line 2
    .line 3
    invoke-static {p1, v0}, Ljava/util/Objects;->requireNonNull(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    .line 4
    .line 5
    .line 6
    const-string v0, "authTokenType cannot be null"

    .line 7
    .line 8
    invoke-static {p2, v0}, Ljava/util/Objects;->requireNonNull(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    .line 9
    .line 10
    .line 11
    invoke-virtual {p0, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 12
    .line 13
    .line 14
    move-result-object p3

    .line 15
    if-nez p3, :cond_0

    .line 16
    .line 17
    const/4 p1, 0x0

    .line 18
    return-object p1

    .line 19
    :cond_0
    iget-object v0, p3, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 20
    .line 21
    monitor-enter v0

    .line 22
    :try_start_0
    invoke-virtual {p3, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAuthToken(Landroid/accounts/Account;)Ljava/util/Map;

    .line 23
    .line 24
    .line 25
    move-result-object p1

    .line 26
    invoke-interface {p1, p2}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 27
    .line 28
    .line 29
    move-result-object p1

    .line 30
    check-cast p1, Ljava/lang/String;

    .line 31
    .line 32
    monitor-exit v0

    .line 33
    return-object p1

    .line 34
    :catchall_0
    move-exception p1

    .line 35
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 36
    throw p1
.end method

.method public readAuthTokenInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;Ljava/lang/String;)Ljava/lang/String;
    .locals 1

    .line 1
    if-nez p1, :cond_0

    .line 2
    .line 3
    const/4 p1, 0x0

    .line 4
    return-object p1

    .line 5
    :cond_0
    iget-object v0, p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 6
    .line 7
    monitor-enter v0

    .line 8
    :try_start_0
    invoke-virtual {p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAuthToken(Landroid/accounts/Account;)Ljava/util/Map;

    .line 9
    .line 10
    .line 11
    move-result-object p1

    .line 12
    invoke-interface {p1, p3}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 13
    .line 14
    .line 15
    move-result-object p1

    .line 16
    check-cast p1, Ljava/lang/String;

    .line 17
    .line 18
    monitor-exit v0

    .line 19
    return-object p1

    .line 20
    :catchall_0
    move-exception p1

    .line 21
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 22
    throw p1
.end method

.method public readCachedTokenInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .locals 7

    .line 1
    invoke-static {}, Ljava/lang/System;->currentTimeMillis()J

    .line 2
    .line 3
    .line 4
    move-result-wide v0

    .line 5
    iget-object v2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mTokenCaches:Ljava/util/LinkedList;

    .line 6
    .line 7
    monitor-enter v2

    .line 8
    :try_start_0
    iget-object v3, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mTokenCaches:Ljava/util/LinkedList;

    .line 9
    .line 10
    invoke-virtual {v3}, Ljava/util/AbstractCollection;->iterator()Ljava/util/Iterator;

    .line 11
    .line 12
    .line 13
    move-result-object v3

    .line 14
    :cond_0
    :goto_0
    invoke-interface {v3}, Ljava/util/Iterator;->hasNext()Z

    .line 15
    .line 16
    .line 17
    move-result v4

    .line 18
    if-eqz v4, :cond_2

    .line 19
    .line 20
    invoke-interface {v3}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 21
    .line 22
    .line 23
    move-result-object v4

    .line 24
    check-cast v4, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;

    .line 25
    .line 26
    iget v5, v4, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;->userId:I

    .line 27
    .line 28
    iget v6, p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->userId:I

    .line 29
    .line 30
    if-ne v5, v6, :cond_0

    .line 31
    .line 32
    iget-object v5, v4, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;->account:Landroid/accounts/Account;

    .line 33
    .line 34
    invoke-virtual {v5, p2}, Landroid/accounts/Account;->equals(Ljava/lang/Object;)Z

    .line 35
    .line 36
    .line 37
    move-result v5

    .line 38
    if-eqz v5, :cond_0

    .line 39
    .line 40
    iget-object v5, v4, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;->authTokenType:Ljava/lang/String;

    .line 41
    .line 42
    invoke-virtual {v5, p3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 43
    .line 44
    .line 45
    move-result v5

    .line 46
    if-eqz v5, :cond_0

    .line 47
    .line 48
    iget-object v5, v4, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;->packageName:Ljava/lang/String;

    .line 49
    .line 50
    invoke-virtual {v5, p4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 51
    .line 52
    .line 53
    move-result v5

    .line 54
    if-eqz v5, :cond_0

    .line 55
    .line 56
    iget-wide v5, v4, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;->expiryEpochMillis:J

    .line 57
    .line 58
    cmp-long v5, v5, v0

    .line 59
    .line 60
    if-lez v5, :cond_1

    .line 61
    .line 62
    iget-object p1, v4, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;->authToken:Ljava/lang/String;

    .line 63
    .line 64
    monitor-exit v2

    .line 65
    return-object p1

    .line 66
    :catchall_0
    move-exception p1

    .line 67
    goto :goto_1

    .line 68
    :cond_1
    invoke-interface {v3}, Ljava/util/Iterator;->remove()V

    .line 69
    .line 70
    .line 71
    goto :goto_0

    .line 72
    :cond_2
    monitor-exit v2

    .line 73
    const/4 p1, 0x0

    .line 74
    return-object p1

    .line 75
    :goto_1
    monitor-exit v2
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 76
    throw p1
.end method

.method public readPasswordInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;)Ljava/lang/String;
    .locals 2

    .line 1
    const/4 v0, 0x0

    .line 2
    if-nez p1, :cond_0

    .line 3
    .line 4
    return-object v0

    .line 5
    :cond_0
    iget-object v1, p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 6
    .line 7
    monitor-enter v1

    .line 8
    :try_start_0
    invoke-virtual {p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAccount(Landroid/accounts/Account;)Ltop/niunaijun/blackbox/core/system/accounts/BAccount;

    .line 9
    .line 10
    .line 11
    move-result-object p1

    .line 12
    if-nez p1, :cond_1

    .line 13
    .line 14
    monitor-exit v1

    .line 15
    return-object v0

    .line 16
    :catchall_0
    move-exception p1

    .line 17
    goto :goto_0

    .line 18
    :cond_1
    iget-object p1, p1, Ltop/niunaijun/blackbox/core/system/accounts/BAccount;->password:Ljava/lang/String;

    .line 19
    .line 20
    monitor-exit v1

    .line 21
    return-object p1

    .line 22
    :goto_0
    monitor-exit v1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 23
    throw p1
.end method

.method public registerAccountListener([Ljava/lang/String;Ljava/lang/String;I)V
    .locals 0

    .line 1
    return-void
.end method

.method public removeAccountAsUser(Landroid/accounts/IAccountManagerResponse;Landroid/accounts/Account;ZI)V
    .locals 8

    move/from16 v0, p4

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

    .line 1
    const/4 v0, 0x0

    .line 2
    const/4 v1, 0x1

    .line 3
    if-eqz p2, :cond_0

    .line 4
    .line 5
    move v2, v1

    .line 6
    goto :goto_0

    .line 7
    :cond_0
    move v2, v0

    .line 8
    :goto_0
    const-string v3, "account cannot be null"

    .line 9
    .line 10
    invoke-static {v3, v2}, Le5/a;->f(Ljava/lang/String;Z)V

    .line 11
    .line 12
    .line 13
    if-eqz p1, :cond_1

    .line 14
    .line 15
    move v0, v1

    .line 16
    :cond_1
    const-string v1, "response cannot be null"

    .line 17
    .line 18
    invoke-static {v1, v0}, Le5/a;->f(Ljava/lang/String;Z)V

    .line 19
    .line 20
    .line 21
    invoke-virtual {p0, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 22
    .line 23
    .line 24
    move-result-object v4

    .line 25
    new-instance v2, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$RemoveAccountSession;

    .line 26
    .line 27
    move-object v3, p0

    .line 28
    move-object v5, p1

    .line 29
    move-object v6, p2

    .line 30
    move v7, p3

    .line 31
    invoke-direct/range {v2 .. v7}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$RemoveAccountSession;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Landroid/accounts/Account;Z)V

    .line 32
    .line 33
    .line 34
    invoke-virtual {v2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->bind()V

    .line 35
    .line 36
    .line 37
    return-void
.end method

.method public removeAccountExplicitly(Landroid/accounts/Account;I)Z
    .locals 4

    move/from16 v0, p2

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

    .line 1
    invoke-static {}, Landroid/os/Binder;->getCallingUid()I

    .line 2
    .line 3
    .line 4
    move-result v0

    .line 5
    const/4 v1, 0x2

    .line 6
    const-string v2, "AccountManagerService"

    .line 7
    .line 8
    invoke-static {v2, v1}, Landroid/util/Log;->isLoggable(Ljava/lang/String;I)Z

    .line 9
    .line 10
    .line 11
    move-result v1

    .line 12
    if-eqz v1, :cond_0

    .line 13
    .line 14
    new-instance v1, Ljava/lang/StringBuilder;

    .line 15
    .line 16
    const-string v3, "removeAccountExplicitly: "

    .line 17
    .line 18
    invoke-direct {v1, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 19
    .line 20
    .line 21
    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 22
    .line 23
    .line 24
    const-string v3, ", caller\'s uid "

    .line 25
    .line 26
    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 27
    .line 28
    .line 29
    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 30
    .line 31
    .line 32
    const-string v0, ", pid "

    .line 33
    .line 34
    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 35
    .line 36
    .line 37
    invoke-static {}, Landroid/os/Binder;->getCallingPid()I

    .line 38
    .line 39
    .line 40
    move-result v0

    .line 41
    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 42
    .line 43
    .line 44
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 45
    .line 46
    .line 47
    move-result-object v0

    .line 48
    invoke-static {v2, v0}, Landroid/util/Log;->v(Ljava/lang/String;Ljava/lang/String;)I

    .line 49
    .line 50
    .line 51
    :cond_0
    if-nez p1, :cond_1

    .line 52
    .line 53
    const-string p1, "account is null"

    .line 54
    .line 55
    invoke-static {v2, p1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 56
    .line 57
    .line 58
    const/4 p1, 0x0

    .line 59
    return p1

    .line 60
    :cond_1
    invoke-virtual {p0, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 61
    .line 62
    .line 63
    move-result-object p2

    .line 64
    invoke-direct {p0, p2, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->removeAccountInternal(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;)Z

    .line 65
    .line 66
    .line 67
    move-result p1

    .line 68
    return p1
.end method

.method public saveAuthTokenToDatabase(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;Ljava/lang/String;Ljava/lang/String;)V
    .locals 1

    .line 1
    if-nez p1, :cond_0

    .line 2
    .line 3
    return-void

    .line 4
    :cond_0
    iget-object v0, p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 5
    .line 6
    monitor-enter v0

    .line 7
    :try_start_0
    invoke-virtual {p1, p2}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAuthToken(Landroid/accounts/Account;)Ljava/util/Map;

    .line 8
    .line 9
    .line 10
    move-result-object p1

    .line 11
    invoke-interface {p1, p3, p4}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 12
    .line 13
    .line 14
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->saveAllAccounts()V

    .line 15
    .line 16
    .line 17
    monitor-exit v0

    .line 18
    return-void

    .line 19
    :catchall_0
    move-exception p1

    .line 20
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 21
    throw p1
.end method

.method public saveCachedToken(Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/Account;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;J)V
    .locals 8

    .line 1
    if-eqz p2, :cond_1

    .line 2
    .line 3
    if-eqz p4, :cond_1

    .line 4
    .line 5
    if-nez p3, :cond_0

    .line 6
    .line 7
    goto :goto_0

    .line 8
    :cond_0
    new-instance v0, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;

    .line 9
    .line 10
    iget v1, p1, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->userId:I

    .line 11
    .line 12
    move-object v2, p2

    .line 13
    move-object v3, p3

    .line 14
    move-object v4, p4

    .line 15
    move-object v5, p5

    .line 16
    move-wide v6, p6

    .line 17
    invoke-direct/range {v0 .. v7}, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;-><init>(ILandroid/accounts/Account;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;J)V

    .line 18
    .line 19
    .line 20
    iget-object p1, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mTokenCaches:Ljava/util/LinkedList;

    .line 21
    .line 22
    monitor-enter p1

    .line 23
    :try_start_0
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mTokenCaches:Ljava/util/LinkedList;

    .line 24
    .line 25
    invoke-virtual {p2, v0}, Ljava/util/LinkedList;->add(Ljava/lang/Object;)Z

    .line 26
    .line 27
    .line 28
    monitor-exit p1

    .line 29
    return-void

    .line 30
    :catchall_0
    move-exception v0

    .line 31
    move-object p2, v0

    .line 32
    monitor-exit p1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 33
    throw p2

    .line 34
    :cond_1
    :goto_0
    return-void
.end method

.method public setAccountVisibility(Landroid/accounts/Account;Ljava/lang/String;II)Z
    .locals 1

    move/from16 v0, p4

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

    .line 1
    const-string v0, "account cannot be null"

    invoke-static {p1, v0}, Ljava/util/Objects;->requireNonNull(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    .line 2
    const-string v0, "packageName cannot be null"

    invoke-static {p2, v0}, Ljava/util/Objects;->requireNonNull(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    .line 3
    invoke-virtual {p0, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    move-result-object p4

    if-nez p4, :cond_0

    const/4 p1, 0x0

    return p1

    .line 4
    :cond_0
    invoke-direct {p0, p1, p2, p3, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->setAccountVisibility(Landroid/accounts/Account;Ljava/lang/String;ILtop/niunaijun/blackbox/core/system/accounts/BUserAccounts;)Z

    move-result p1

    return p1
.end method

.method public setAuthToken(Landroid/accounts/Account;Ljava/lang/String;Ljava/lang/String;I)V
    .locals 1

    move/from16 v0, p4

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

    .line 1
    const-string v0, "account cannot be null"

    .line 2
    .line 3
    invoke-static {p1, v0}, Ljava/util/Objects;->requireNonNull(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    .line 4
    .line 5
    .line 6
    const-string v0, "authTokenType cannot be null"

    .line 7
    .line 8
    invoke-static {p2, v0}, Ljava/util/Objects;->requireNonNull(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    .line 9
    .line 10
    .line 11
    invoke-virtual {p0, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 12
    .line 13
    .line 14
    move-result-object p4

    .line 15
    if-nez p4, :cond_0

    .line 16
    .line 17
    return-void

    .line 18
    :cond_0
    iget-object v0, p4, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 19
    .line 20
    monitor-enter v0

    .line 21
    :try_start_0
    invoke-virtual {p4, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAuthToken(Landroid/accounts/Account;)Ljava/util/Map;

    .line 22
    .line 23
    .line 24
    move-result-object p1

    .line 25
    invoke-interface {p1, p2, p3}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 26
    .line 27
    .line 28
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->saveAllAccounts()V

    .line 29
    .line 30
    .line 31
    monitor-exit v0

    .line 32
    return-void

    .line 33
    :catchall_0
    move-exception p1

    .line 34
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 35
    throw p1
.end method

.method public setPassword(Landroid/accounts/Account;Ljava/lang/String;I)V
    .locals 3

    move/from16 v0, p3

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

    .line 1
    const-string v0, "account cannot be null"

    .line 2
    .line 3
    invoke-static {p1, v0}, Ljava/util/Objects;->requireNonNull(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    .line 4
    .line 5
    .line 6
    invoke-virtual {p0, p3}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 7
    .line 8
    .line 9
    move-result-object v0

    .line 10
    if-nez v0, :cond_0

    .line 11
    .line 12
    return-void

    .line 13
    :cond_0
    iget-object v1, v0, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 14
    .line 15
    monitor-enter v1

    .line 16
    :try_start_0
    invoke-virtual {v0, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAccount(Landroid/accounts/Account;)Ltop/niunaijun/blackbox/core/system/accounts/BAccount;

    .line 17
    .line 18
    .line 19
    move-result-object v0

    .line 20
    iput-object p2, v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccount;->password:Ljava/lang/String;

    .line 21
    .line 22
    iget-object p2, v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccount;->authTokens:Ljava/util/HashMap;

    .line 23
    .line 24
    invoke-virtual {p2}, Ljava/util/HashMap;->clear()V

    .line 25
    .line 26
    .line 27
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->saveAllAccounts()V

    .line 28
    .line 29
    .line 30
    monitor-exit v1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    .line 31
    iget-object p2, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mTokenCaches:Ljava/util/LinkedList;

    .line 32
    .line 33
    monitor-enter p2

    .line 34
    :try_start_1
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mTokenCaches:Ljava/util/LinkedList;

    .line 35
    .line 36
    invoke-virtual {v0}, Ljava/util/AbstractCollection;->iterator()Ljava/util/Iterator;

    .line 37
    .line 38
    .line 39
    move-result-object v0

    .line 40
    :cond_1
    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    .line 41
    .line 42
    .line 43
    move-result v1

    .line 44
    if-eqz v1, :cond_2

    .line 45
    .line 46
    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 47
    .line 48
    .line 49
    move-result-object v1

    .line 50
    check-cast v1, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;

    .line 51
    .line 52
    iget-object v2, v1, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;->account:Landroid/accounts/Account;

    .line 53
    .line 54
    invoke-virtual {v2, p1}, Landroid/accounts/Account;->equals(Ljava/lang/Object;)Z

    .line 55
    .line 56
    .line 57
    move-result v2

    .line 58
    if-eqz v2, :cond_1

    .line 59
    .line 60
    iget v1, v1, Ltop/niunaijun/blackbox/core/system/accounts/TokenCache;->userId:I

    .line 61
    .line 62
    if-ne v1, p3, :cond_1

    .line 63
    .line 64
    invoke-interface {v0}, Ljava/util/Iterator;->remove()V

    .line 65
    .line 66
    .line 67
    goto :goto_0

    .line 68
    :catchall_0
    move-exception p1

    .line 69
    goto :goto_1

    .line 70
    :cond_2
    monitor-exit p2

    .line 71
    return-void

    .line 72
    :goto_1
    monitor-exit p2
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 73
    throw p1

    .line 74
    :catchall_1
    move-exception p1

    .line 75
    :try_start_2
    monitor-exit v1
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    .line 76
    throw p1
.end method

.method public setUserData(Landroid/accounts/Account;Ljava/lang/String;Ljava/lang/String;I)V
    .locals 1

    move/from16 v0, p4

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestAccounts;->requireOwner(I)V

    .line 1
    if-eqz p2, :cond_2

    .line 2
    .line 3
    if-eqz p1, :cond_1

    .line 4
    .line 5
    invoke-virtual {p0, p4}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 6
    .line 7
    .line 8
    move-result-object p4

    .line 9
    if-nez p4, :cond_0

    .line 10
    .line 11
    return-void

    .line 12
    :cond_0
    iget-object v0, p4, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->lock:Ljava/lang/Object;

    .line 13
    .line 14
    monitor-enter v0

    .line 15
    :try_start_0
    invoke-virtual {p4, p1}, Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;->getAccountUserData(Landroid/accounts/Account;)Ljava/util/Map;

    .line 16
    .line 17
    .line 18
    move-result-object p1

    .line 19
    invoke-interface {p1, p2, p3}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 20
    .line 21
    .line 22
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->saveAllAccounts()V

    .line 23
    .line 24
    .line 25
    monitor-exit v0

    .line 26
    return-void

    .line 27
    :catchall_0
    move-exception p1

    .line 28
    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 29
    throw p1

    .line 30
    :cond_1
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 31
    .line 32
    const-string p2, "account is null"

    .line 33
    .line 34
    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 35
    .line 36
    .line 37
    throw p1

    .line 38
    :cond_2
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 39
    .line 40
    const-string p2, "key is null"

    .line 41
    .line 42
    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 43
    .line 44
    .line 45
    throw p1
.end method

.method public systemReady()V
    .locals 1

    .line 1
    invoke-direct {p0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->loadAccounts()V

    .line 2
    .line 3
    .line 4
    const/4 v0, 0x0

    .line 5
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->loadAuthenticatorCache(Ljava/lang/String;)V

    .line 6
    .line 7
    .line 8
    iget-object v0, p0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->mPms:Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;

    .line 9
    .line 10
    invoke-virtual {v0, p0}, Ltop/niunaijun/blackbox/core/system/pm/BPackageManagerService;->addPackageMonitor(Ltop/niunaijun/blackbox/core/system/pm/PackageMonitor;)V

    .line 11
    .line 12
    .line 13
    return-void
.end method

.method public unregisterAccountListener([Ljava/lang/String;Ljava/lang/String;I)V
    .locals 0

    .line 1
    return-void
.end method

.method public updateAppPermission(Landroid/accounts/Account;Ljava/lang/String;IZ)V
    .locals 0

    .line 1
    return-void
.end method

.method public updateCredentials(Landroid/accounts/IAccountManagerResponse;Landroid/accounts/Account;Ljava/lang/String;ZLandroid/os/Bundle;I)V
    .locals 13

    .line 1
    if-eqz p1, :cond_1

    .line 2
    .line 3
    if-eqz p2, :cond_0

    .line 4
    .line 5
    invoke-static {}, Landroid/os/Binder;->clearCallingIdentity()J

    .line 6
    .line 7
    .line 8
    move/from16 v0, p6

    .line 9
    .line 10
    invoke-virtual {p0, v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;->getUserAccounts(I)Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;

    .line 11
    .line 12
    .line 13
    move-result-object v2

    .line 14
    new-instance v0, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$5;

    .line 15
    .line 16
    iget-object v4, p2, Landroid/accounts/Account;->type:Ljava/lang/String;

    .line 17
    .line 18
    iget-object v7, p2, Landroid/accounts/Account;->name:Ljava/lang/String;

    .line 19
    .line 20
    const/4 v8, 0x0

    .line 21
    const/4 v9, 0x1

    .line 22
    const/4 v6, 0x1

    .line 23
    move-object v1, p0

    .line 24
    move-object v3, p1

    .line 25
    move-object v10, p2

    .line 26
    move-object/from16 v11, p3

    .line 27
    .line 28
    move/from16 v5, p4

    .line 29
    .line 30
    move-object/from16 v12, p5

    .line 31
    .line 32
    invoke-direct/range {v0 .. v12}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$5;-><init>(Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService;Ltop/niunaijun/blackbox/core/system/accounts/BUserAccounts;Landroid/accounts/IAccountManagerResponse;Ljava/lang/String;ZZLjava/lang/String;ZZLandroid/accounts/Account;Ljava/lang/String;Landroid/os/Bundle;)V

    .line 33
    .line 34
    .line 35
    invoke-virtual {v0}, Ltop/niunaijun/blackbox/core/system/accounts/BAccountManagerService$Session;->bind()V

    .line 36
    .line 37
    .line 38
    return-void

    .line 39
    :cond_0
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 40
    .line 41
    const-string p2, "account is null"

    .line 42
    .line 43
    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 44
    .line 45
    .line 46
    throw p1

    .line 47
    :cond_1
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 48
    .line 49
    const-string p2, "response is null"

    .line 50
    .line 51
    invoke-direct {p1, p2}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 52
    .line 53
    .line 54
    throw p1
.end method
