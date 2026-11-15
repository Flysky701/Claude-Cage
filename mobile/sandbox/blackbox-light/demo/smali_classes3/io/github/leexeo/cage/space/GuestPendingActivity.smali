.class public final Lio/github/leexeo/cage/space/GuestPendingActivity;
.super Ljava/lang/Object;
.source "GuestPendingActivity.java"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lio/github/leexeo/cage/space/GuestPendingActivity$Route;
    }
.end annotation


# static fields
.field private static final ACTION:Ljava/lang/String; = "com.google.android.gms.auth.api.credentials.ASSISTED_SIGNIN"

.field private static final ACTIVITY:Ljava/lang/String; = "org.microg.gms.auth.signin.AssistedSignInActivity"

.field private static final AUTHORITY:Ljava/lang/String; = "top.niunaijun.microdem.blackbox.SystemCallProvider"

.field private static final CALLER:Ljava/lang/String; = "androidx.credentials.playservices.controllers.identityauth.HiddenActivity"

.field private static final CLAUDE:Ljava/lang/String; = "com.anthropic.claude"

.field private static final GMS:Ljava/lang/String; = "com.google.android.gms"

.field private static final HOST:Ljava/lang/String; = "top.niunaijun.microdem"

.field private static final IDENTITY_ACTIVITY:Ljava/lang/String; = "org.microg.gms.auth.credentials.identity.IdentityCredentialChooserActivity"

.field private static final IDENTITY_FLAGS:I = 0x4a000000

.field private static final IDENTITY_PACKAGE:Ljava/lang/String; = "org.microg.gms.identitycredentials.EXTRA_CALLING_PACKAGE"

.field private static final IDENTITY_REQUEST:Ljava/lang/String; = "org.microg.gms.identitycredentials.EXTRA_GET_REQUEST"

.field private static final LIFETIME_MS:J = 0x1d4c0L

.field private static final MARKER:Ljava/lang/String; = "io.github.leexeo.cage.space.GOOGLE_PENDING"

.field private static final METHOD:Ljava/lang/String; = "cage_demo_google_pending"

.field private static final REQUIRED_FLAGS:I = 0x44000000

.field private static final ROUTES:Ljava/util/Map;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/Map<",
            "Landroid/os/IBinder;",
            "Lio/github/leexeo/cage/space/GuestPendingActivity$Route;",
            ">;"
        }
    .end annotation
.end field

.field private static final SCHEME:Ljava/lang/String; = "cage-private-google-pending"


# direct methods
.method static constructor <clinit>()V
    .locals 1

    .line 56
    new-instance v0, Ljava/util/HashMap;

    invoke-direct {v0}, Ljava/util/HashMap;-><init>()V

    sput-object v0, Lio/github/leexeo/cage/space/GuestPendingActivity;->ROUTES:Ljava/util/Map;

    return-void
.end method

.method private constructor <init>()V
    .locals 0

    .line 58
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method private static blocked(Ljava/lang/String;Ljava/lang/Exception;)Ljava/lang/SecurityException;
    .locals 2

    .line 451
    nop

    .line 452
    instance-of v0, p1, Ljava/lang/reflect/InvocationTargetException;

    if-eqz v0, :cond_0

    invoke-virtual {p1}, Ljava/lang/Exception;->getCause()Ljava/lang/Throwable;

    move-result-object v0

    if-eqz v0, :cond_0

    .line 453
    invoke-virtual {p1}, Ljava/lang/Exception;->getCause()Ljava/lang/Throwable;

    move-result-object p1

    .line 455
    :cond_0
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "Private Google pending blocked at "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, ": "

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    const-string p1, "CageDemo"

    invoke-static {p1, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 456
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    return-object p0
.end method

.method public static call(Landroid/content/ContentProvider;Ljava/lang/String;Ljava/lang/String;Landroid/os/Bundle;)Landroid/os/Bundle;
    .locals 6

    .line 113
    const-string v0, "cage_demo_google_pending"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    const/4 v0, 0x0

    if-nez p1, :cond_0

    return-object v0

    .line 114
    :cond_0
    const-string p1, "provider-caller"

    .line 116
    :try_start_0
    invoke-virtual {p0}, Landroid/content/ContentProvider;->getContext()Landroid/content/Context;

    move-result-object p0

    .line 117
    if-eqz p0, :cond_a

    const-string v1, "top.niunaijun.microdem"

    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_a

    if-eqz p3, :cond_a

    .line 118
    invoke-static {}, Landroid/os/Binder;->getCallingUid()I

    move-result v1

    invoke-virtual {p0}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;

    move-result-object v2

    iget v2, v2, Landroid/content/pm/ApplicationInfo;->uid:I

    if-ne v1, v2, :cond_a

    .line 119
    invoke-static {}, Landroid/os/Binder;->getCallingPid()I

    move-result v1

    invoke-static {v1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->process(I)Ljava/lang/Object;

    move-result-object v1

    .line 120
    const-string v2, "info"

    invoke-static {v1, v2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Landroid/content/pm/ApplicationInfo;

    .line 121
    const-string v3, "userId"

    invoke-static {v1, v3}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ljava/lang/Integer;

    invoke-virtual {v3}, Ljava/lang/Integer;->intValue()I

    move-result v3

    if-nez v3, :cond_9

    .line 122
    const-string v3, "sender"

    invoke-virtual {p3, v3}, Landroid/os/Bundle;->getBinder(Ljava/lang/String;)Landroid/os/IBinder;

    move-result-object v3

    .line 123
    if-eqz v3, :cond_8

    invoke-interface {v3}, Landroid/os/IBinder;->isBinderAlive()Z

    move-result v4

    if-eqz v4, :cond_8

    .line 124
    const-string p1, "provider-system-owner"

    .line 125
    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/GuestPendingActivity;->requireRealSenderOwner(Landroid/content/Context;Landroid/os/IBinder;)Z

    move-result v4

    .line 126
    const-string v5, "register"

    invoke-virtual {v5, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_4

    .line 127
    const-string p1, "register-shape"

    .line 128
    const-string p2, "com.google.android.gms"

    iget-object v2, v2, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    invoke-virtual {p2, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2

    if-eqz p2, :cond_3

    .line 129
    const-string p2, "wrapper"

    invoke-virtual {p3, p2}, Landroid/os/Bundle;->getParcelable(Ljava/lang/String;)Landroid/os/Parcelable;

    move-result-object p2

    check-cast p2, Landroid/content/Intent;

    .line 130
    invoke-static {p2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->marker(Landroid/content/Intent;)V

    .line 131
    const-string p3, "top.niunaijun.blackbox.proxy.ProxyManifest"

    invoke-static {p3}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p3

    const-string v2, "getProxyPendingActivity"

    sget-object v5, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v5}, [Ljava/lang/Class;

    move-result-object v5

    .line 132
    invoke-virtual {p3, v2, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p3

    const-string v2, "bpid"

    invoke-static {v1, v2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v2

    filled-new-array {v2}, [Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {p3, v0, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p3

    check-cast p3, Ljava/lang/String;

    .line 133
    new-instance v0, Landroid/content/ComponentName;

    const-string v2, "top.niunaijun.microdem"

    invoke-direct {v0, v2, p3}, Landroid/content/ComponentName;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    invoke-virtual {p2}, Landroid/content/Intent;->getComponent()Landroid/content/ComponentName;

    move-result-object p3

    invoke-virtual {v0, p3}, Landroid/content/ComponentName;->equals(Ljava/lang/Object;)Z

    move-result p3

    if-eqz p3, :cond_2

    const-string p3, "_B_|_P_user_id_"

    .line 134
    const/4 v0, -0x1

    invoke-virtual {p2, p3, v0}, Landroid/content/Intent;->getIntExtra(Ljava/lang/String;I)I

    move-result p3

    if-nez p3, :cond_2

    .line 135
    invoke-static {p2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->inner(Landroid/content/Intent;)Landroid/content/Intent;

    move-result-object p2

    .line 136
    invoke-static {p2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->targetShape(Landroid/content/Intent;)V

    .line 137
    const-string p1, "register-mutability"

    .line 138
    invoke-static {p2, v4}, Lio/github/leexeo/cage/space/GuestPendingActivity;->requireMutability(Landroid/content/Intent;Z)V

    .line 139
    const-string p1, "register-private-target"

    .line 140
    invoke-static {p0, p2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->privateTarget(Landroid/content/Context;Landroid/content/Intent;)V

    .line 141
    sget-object p0, Lio/github/leexeo/cage/space/GuestPendingActivity;->ROUTES:Ljava/util/Map;

    monitor-enter p0
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 142
    :try_start_1
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->expire()V

    .line 143
    sget-object p3, Lio/github/leexeo/cage/space/GuestPendingActivity;->ROUTES:Ljava/util/Map;

    invoke-interface {p3}, Ljava/util/Map;->size()I

    move-result p3

    const/16 v0, 0x10

    if-ge p3, v0, :cond_1

    sget-object p3, Lio/github/leexeo/cage/space/GuestPendingActivity;->ROUTES:Ljava/util/Map;

    invoke-interface {p3, v3}, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z

    move-result p3

    if-nez p3, :cond_1

    .line 144
    sget-object p3, Lio/github/leexeo/cage/space/GuestPendingActivity;->ROUTES:Ljava/util/Map;

    new-instance v0, Lio/github/leexeo/cage/space/GuestPendingActivity$Route;

    invoke-direct {v0, p2, v1}, Lio/github/leexeo/cage/space/GuestPendingActivity$Route;-><init>(Landroid/content/Intent;Ljava/lang/Object;)V

    invoke-interface {p3, v3, v0}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 145
    monitor-exit p0
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 146
    :try_start_2
    new-instance p0, Landroid/os/Bundle;

    invoke-direct {p0}, Landroid/os/Bundle;-><init>()V

    .line 147
    const-string p2, "registered"

    const/4 p3, 0x1

    invoke-virtual {p0, p2, p3}, Landroid/os/Bundle;->putBoolean(Ljava/lang/String;Z)V

    .line 148
    const-string p2, "CageDemo"

    const-string p3, "Google pending: registered"

    invoke-static {p2, p3}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_0

    .line 149
    return-object p0

    .line 143
    :cond_1
    :try_start_3
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p2

    throw p2

    .line 145
    :catchall_0
    move-exception p2

    monitor-exit p0
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    :try_start_4
    throw p2

    .line 134
    :cond_2
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 128
    :cond_3
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 151
    :cond_4
    const-string v0, "claim"

    invoke-virtual {v0, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2

    if-eqz p2, :cond_7

    const-string p2, "com.anthropic.claude"

    iget-object v0, v2, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    invoke-virtual {p2, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2

    if-eqz p2, :cond_7

    .line 152
    const-string p2, "resultTo"

    invoke-virtual {p3, p2}, Landroid/os/Bundle;->getBinder(Ljava/lang/String;)Landroid/os/IBinder;

    move-result-object p2

    .line 153
    const-string v0, "caller"

    invoke-virtual {p3, v0}, Landroid/os/Bundle;->getBinder(Ljava/lang/String;)Landroid/os/IBinder;

    move-result-object p3

    .line 154
    const-string v0, "appThread"

    invoke-static {v1, v0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v0

    instance-of v0, v0, Landroid/os/IInterface;

    if-eqz v0, :cond_6

    const-string v0, "appThread"

    .line 155
    invoke-static {v1, v0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/os/IInterface;

    invoke-interface {v0}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    move-result-object v0

    invoke-virtual {v0, p3}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    move-result p3

    if-eqz p3, :cond_6

    .line 156
    const-string p1, "claim-result-owner"

    .line 157
    invoke-static {v1, p2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->verifyResultOwner(Ljava/lang/Object;Landroid/os/IBinder;)V

    .line 159
    sget-object p2, Lio/github/leexeo/cage/space/GuestPendingActivity;->ROUTES:Ljava/util/Map;

    monitor-enter p2
    :try_end_4
    .catch Ljava/lang/Exception; {:try_start_4 .. :try_end_4} :catch_0

    .line 160
    :try_start_5
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->expire()V

    .line 161
    sget-object p3, Lio/github/leexeo/cage/space/GuestPendingActivity;->ROUTES:Ljava/util/Map;

    invoke-interface {p3, v3}, Ljava/util/Map;->remove(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p3

    check-cast p3, Lio/github/leexeo/cage/space/GuestPendingActivity$Route;

    .line 162
    monitor-exit p2
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_1

    .line 163
    if-eqz p3, :cond_5

    :try_start_6
    iget-object p2, p3, Lio/github/leexeo/cage/space/GuestPendingActivity$Route;->creator:Ljava/lang/Object;

    const-string v0, "pid"

    invoke-static {p2, v0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object p2

    check-cast p2, Ljava/lang/Integer;

    invoke-virtual {p2}, Ljava/lang/Integer;->intValue()I

    move-result p2

    invoke-static {p2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->process(I)Ljava/lang/Object;

    move-result-object p2

    iget-object v0, p3, Lio/github/leexeo/cage/space/GuestPendingActivity$Route;->creator:Ljava/lang/Object;

    if-ne p2, v0, :cond_5

    .line 164
    new-instance p2, Landroid/content/Intent;

    iget-object p3, p3, Lio/github/leexeo/cage/space/GuestPendingActivity$Route;->target:Landroid/content/Intent;

    invoke-direct {p2, p3}, Landroid/content/Intent;-><init>(Landroid/content/Intent;)V

    .line 165
    const-string p1, "claim-mutability"

    .line 166
    invoke-static {p2, v4}, Lio/github/leexeo/cage/space/GuestPendingActivity;->requireMutability(Landroid/content/Intent;Z)V

    .line 167
    const-string p1, "claim-private-target"

    .line 168
    invoke-static {p0, p2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->privateTarget(Landroid/content/Context;Landroid/content/Intent;)V

    .line 169
    new-instance p0, Landroid/os/Bundle;

    invoke-direct {p0}, Landroid/os/Bundle;-><init>()V

    .line 170
    const-string p3, "target"

    invoke-virtual {p0, p3, p2}, Landroid/os/Bundle;->putParcelable(Ljava/lang/String;Landroid/os/Parcelable;)V

    .line 171
    const-string p2, "CageDemo"

    const-string p3, "Google pending: claimed"

    invoke-static {p2, p3}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 172
    return-object p0

    .line 163
    :cond_5
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
    :try_end_6
    .catch Ljava/lang/Exception; {:try_start_6 .. :try_end_6} :catch_0

    .line 162
    :catchall_1
    move-exception p0

    :try_start_7
    monitor-exit p2
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_1

    :try_start_8
    throw p0

    .line 155
    :cond_6
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 151
    :cond_7
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 123
    :cond_8
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 121
    :cond_9
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 118
    :cond_a
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
    :try_end_8
    .catch Ljava/lang/Exception; {:try_start_8 .. :try_end_8} :catch_0

    .line 173
    :catch_0
    move-exception p0

    invoke-static {p1, p0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->blocked(Ljava/lang/String;Ljava/lang/Exception;)Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method private static candidate(Landroid/content/Intent;)Z
    .locals 2

    .line 375
    if-eqz p0, :cond_1

    const-string v0, "com.google.android.gms.auth.api.credentials.ASSISTED_SIGNIN"

    invoke-virtual {p0}, Landroid/content/Intent;->getAction()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_0

    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->identity(Landroid/content/Intent;)Z

    move-result p0

    if-eqz p0, :cond_1

    :cond_0
    const/4 p0, 0x1

    goto :goto_0

    :cond_1
    const/4 p0, 0x0

    :goto_0
    return p0
.end method

.method public static created(Landroid/os/IInterface;Ljava/lang/reflect/Method;[Ljava/lang/Object;)V
    .locals 2

    .line 88
    const-string v0, "com.google.android.gms"

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->guest(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_0

    return-void

    .line 89
    :cond_0
    invoke-static {p2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->wrapper([Ljava/lang/Object;)Landroid/content/Intent;

    move-result-object v0

    .line 90
    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->inner(Landroid/content/Intent;)Landroid/content/Intent;

    move-result-object v1

    invoke-static {v1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->candidate(Landroid/content/Intent;)Z

    move-result v1

    if-nez v1, :cond_1

    return-void

    .line 92
    :cond_1
    :try_start_0
    invoke-static {p1, p2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->creationShape(Ljava/lang/reflect/Method;[Ljava/lang/Object;)V

    .line 93
    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->marker(Landroid/content/Intent;)V

    .line 94
    if-eqz p0, :cond_3

    invoke-interface {p0}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    move-result-object p1

    if-eqz p1, :cond_3

    .line 95
    new-instance p1, Landroid/os/Bundle;

    invoke-direct {p1}, Landroid/os/Bundle;-><init>()V

    .line 96
    const-string p2, "sender"

    invoke-interface {p0}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    move-result-object v1

    invoke-virtual {p1, p2, v1}, Landroid/os/Bundle;->putBinder(Ljava/lang/String;Landroid/os/IBinder;)V

    .line 97
    const-string p2, "wrapper"

    new-instance v1, Landroid/content/Intent;

    invoke-direct {v1, v0}, Landroid/content/Intent;-><init>(Landroid/content/Intent;)V

    invoke-virtual {p1, p2, v1}, Landroid/os/Bundle;->putParcelable(Ljava/lang/String;Landroid/os/Parcelable;)V

    .line 98
    const-string p2, "register"

    invoke-static {p2, p1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->request(Ljava/lang/String;Landroid/os/Bundle;)Landroid/os/Bundle;

    move-result-object p1

    .line 99
    if-eqz p1, :cond_2

    const-string p2, "registered"

    invoke-virtual {p1, p2}, Landroid/os/Bundle;->getBoolean(Ljava/lang/String;)Z

    move-result p1

    if-eqz p1, :cond_2

    .line 108
    nop

    .line 109
    return-void

    .line 99
    :cond_2
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p1

    throw p1

    .line 94
    :cond_3
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p1

    throw p1
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 100
    :catch_0
    move-exception p1

    .line 103
    if-eqz p0, :cond_4

    :try_start_1
    const-string p2, "android.app.IActivityManager"

    invoke-static {p2}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p2

    const-string v0, "cancelIntentSender"

    const-string v1, "android.content.IIntentSender"

    .line 104
    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    filled-new-array {v1}, [Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {p2, v0, v1}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p2

    .line 105
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->realActivityManager()Ljava/lang/Object;

    move-result-object v0

    filled-new-array {p0}, [Ljava/lang/Object;

    move-result-object p0

    invoke-virtual {p2, v0, p0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

    goto :goto_0

    .line 106
    :catch_1
    move-exception p0

    :cond_4
    :goto_0
    nop

    .line 107
    const-string p0, "register-client"

    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->blocked(Ljava/lang/String;Ljava/lang/Exception;)Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method private static creationShape(Ljava/lang/reflect/Method;[Ljava/lang/Object;)V
    .locals 4

    .line 409
    const-string v0, "getIntentSender"

    invoke-virtual {p0}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_0

    const-string v0, "getIntentSenderWithFeature"

    invoke-virtual {p0}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_0

    .line 410
    invoke-virtual {p0}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v0

    const-string v1, "getIntentSenderWithSourceToken"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_8

    :cond_0
    if-eqz p1, :cond_8

    array-length v0, p1

    .line 411
    invoke-virtual {p0}, Ljava/lang/reflect/Method;->getParameterTypes()[Ljava/lang/Class;

    move-result-object v1

    array-length v1, v1

    if-ne v0, v1, :cond_8

    const/4 v0, 0x2

    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    const/4 v1, 0x0

    aget-object v2, p1, v1

    invoke-virtual {v0, v2}, Ljava/lang/Integer;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_8

    .line 412
    nop

    .line 413
    invoke-virtual {p0}, Ljava/lang/reflect/Method;->getParameterTypes()[Ljava/lang/Class;

    move-result-object p0

    .line 414
    const/4 v0, -0x1

    :goto_0
    array-length v2, p0

    if-ge v1, v2, :cond_3

    aget-object v2, p0, v1

    const-class v3, [Landroid/content/Intent;

    if-ne v2, v3, :cond_2

    .line 415
    if-gez v0, :cond_1

    .line 416
    move v0, v1

    goto :goto_1

    .line 415
    :cond_1
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 414
    :cond_2
    :goto_1
    add-int/lit8 v1, v1, 0x1

    goto :goto_0

    .line 418
    :cond_3
    if-ltz v0, :cond_7

    add-int/lit8 v1, v0, 0x2

    array-length v2, p1

    if-ge v1, v2, :cond_7

    add-int/lit8 v0, v0, 0x1

    aget-object v0, p0, v0

    const-class v2, [Ljava/lang/String;

    if-ne v0, v2, :cond_7

    aget-object p0, p0, v1

    sget-object v0, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    if-ne p0, v0, :cond_7

    aget-object p0, p1, v1

    instance-of p0, p0, Ljava/lang/Integer;

    if-eqz p0, :cond_7

    .line 420
    aget-object p0, p1, v1

    check-cast p0, Ljava/lang/Integer;

    invoke-virtual {p0}, Ljava/lang/Integer;->intValue()I

    move-result p0

    .line 421
    invoke-static {p1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->wrapper([Ljava/lang/Object;)Landroid/content/Intent;

    move-result-object p1

    invoke-static {p1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->inner(Landroid/content/Intent;)Landroid/content/Intent;

    move-result-object p1

    invoke-static {p1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->identity(Landroid/content/Intent;)Z

    move-result p1

    if-eqz p1, :cond_5

    .line 422
    const/high16 p1, 0x4a000000    # 2097152.0f

    if-ne p0, p1, :cond_4

    goto :goto_2

    :cond_4
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 423
    :cond_5
    const/high16 p1, 0x44000000    # 512.0f

    and-int v0, p0, p1

    if-ne v0, p1, :cond_6

    const p1, -0x4c000001

    and-int/2addr p0, p1

    if-nez p0, :cond_6

    .line 425
    :goto_2
    return-void

    .line 424
    :cond_6
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 419
    :cond_7
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 411
    :cond_8
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method private static denied()Ljava/lang/SecurityException;
    .locals 2

    .line 448
    new-instance v0, Ljava/lang/SecurityException;

    const-string v1, "Private Google sign-in result route unavailable"

    invoke-direct {v0, v1}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    return-object v0
.end method

.method private static expire()V
    .locals 8

    .line 440
    invoke-static {}, Landroid/os/SystemClock;->elapsedRealtime()J

    move-result-wide v0

    .line 441
    sget-object v2, Lio/github/leexeo/cage/space/GuestPendingActivity;->ROUTES:Ljava/util/Map;

    invoke-interface {v2}, Ljava/util/Map;->entrySet()Ljava/util/Set;

    move-result-object v2

    invoke-interface {v2}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    move-result-object v2

    .line 442
    :goto_0
    invoke-interface {v2}, Ljava/util/Iterator;->hasNext()Z

    move-result v3

    if-eqz v3, :cond_2

    .line 443
    invoke-interface {v2}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ljava/util/Map$Entry;

    .line 444
    invoke-interface {v3}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Lio/github/leexeo/cage/space/GuestPendingActivity$Route;

    iget-wide v4, v4, Lio/github/leexeo/cage/space/GuestPendingActivity$Route;->created:J

    sub-long v4, v0, v4

    const-wide/32 v6, 0x1d4c0

    cmp-long v4, v4, v6

    if-gtz v4, :cond_0

    invoke-interface {v3}, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Landroid/os/IBinder;

    invoke-interface {v3}, Landroid/os/IBinder;->isBinderAlive()Z

    move-result v3

    if-nez v3, :cond_1

    :cond_0
    invoke-interface {v2}, Ljava/util/Iterator;->remove()V

    .line 445
    :cond_1
    goto :goto_0

    .line 446
    :cond_2
    return-void
.end method

.method private static field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 296
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v0

    invoke-virtual {v0, p1}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object p1

    .line 297
    const/4 v0, 0x1

    invoke-virtual {p1, v0}, Ljava/lang/reflect/Field;->setAccessible(Z)V

    .line 298
    invoke-virtual {p1, p0}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    return-object p0
.end method

.method public static finishProxy(Landroid/app/Activity;)Z
    .locals 5

    .line 235
    invoke-virtual {p0}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;

    move-result-object v0

    .line 236
    const/4 v1, 0x1

    const/4 v2, 0x0

    if-eqz v0, :cond_1

    const-string v3, "io.github.leexeo.cage.space.GOOGLE_PENDING"

    invoke-virtual {v0, v3}, Landroid/content/Intent;->hasExtra(Ljava/lang/String;)Z

    move-result v3

    if-nez v3, :cond_0

    .line 237
    invoke-virtual {v0}, Landroid/content/Intent;->getData()Landroid/net/Uri;

    move-result-object v3

    if-eqz v3, :cond_1

    invoke-virtual {v0}, Landroid/content/Intent;->getData()Landroid/net/Uri;

    move-result-object v3

    invoke-virtual {v3}, Landroid/net/Uri;->getScheme()Ljava/lang/String;

    move-result-object v3

    const-string v4, "cage-private-google-pending"

    invoke-virtual {v4, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_1

    :cond_0
    move v3, v1

    goto :goto_0

    :cond_1
    move v3, v2

    .line 238
    :goto_0
    if-nez v3, :cond_3

    const-string v3, "com.google.android.gms"

    invoke-static {v3}, Lio/github/leexeo/cage/space/GuestPendingActivity;->guest(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_2

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->inner(Landroid/content/Intent;)Landroid/content/Intent;

    move-result-object v0

    invoke-static {v0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->candidate(Landroid/content/Intent;)Z

    move-result v0

    if-nez v0, :cond_3

    :cond_2
    return v2

    .line 240
    :cond_3
    invoke-virtual {p0}, Landroid/app/Activity;->finish()V

    .line 241
    const-string p0, "CageDemo"

    const-string v0, "Google pending: trampolineSuppressed"

    invoke-static {p0, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 242
    return v1
.end method

.method private static guest(Ljava/lang/String;)Z
    .locals 6

    .line 302
    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v1, 0x22

    const/4 v2, 0x0

    if-ge v0, v1, :cond_0

    return v2

    .line 304
    :cond_0
    :try_start_0
    const-string v0, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    .line 305
    const-string v1, "getContext"

    new-array v3, v2, [Ljava/lang/Class;

    invoke-virtual {v0, v1, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v3, v2, [Ljava/lang/Object;

    const/4 v4, 0x0

    invoke-virtual {v1, v4, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Landroid/content/Context;

    .line 306
    const-string v3, "top.niunaijun.microdem"

    invoke-virtual {v1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v3, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_3

    const-string v1, "isBlackProcess"

    new-array v3, v2, [Ljava/lang/Class;

    .line 307
    invoke-virtual {v0, v1, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    const-string v3, "get"

    new-array v5, v2, [Ljava/lang/Class;

    invoke-virtual {v0, v3, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    new-array v3, v2, [Ljava/lang/Object;

    invoke-virtual {v0, v4, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    new-array v3, v2, [Ljava/lang/Object;

    invoke-virtual {v1, v0, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/lang/Boolean;

    invoke-virtual {v0}, Ljava/lang/Boolean;->booleanValue()Z

    move-result v0

    if-nez v0, :cond_1

    goto :goto_1

    .line 308
    :cond_1
    const-string v0, "top.niunaijun.blackbox.app.BActivityThread"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    .line 309
    const-string v1, "getAppPackageName"

    new-array v3, v2, [Ljava/lang/Class;

    invoke-virtual {v0, v1, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v3, v2, [Ljava/lang/Object;

    invoke-virtual {v1, v4, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_2

    const-string p0, "getUserId"

    new-array v1, v2, [Ljava/lang/Class;

    .line 310
    invoke-virtual {v0, p0, v1}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    new-array v0, v2, [Ljava/lang/Object;

    invoke-virtual {p0, v4, v0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Ljava/lang/Integer;

    invoke-virtual {p0}, Ljava/lang/Integer;->intValue()I

    move-result p0
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_0

    if-nez p0, :cond_2

    const/4 v2, 0x1

    goto :goto_0

    :cond_2
    nop

    .line 309
    :goto_0
    return v2

    .line 307
    :cond_3
    :goto_1
    return v2

    .line 311
    :catch_0
    move-exception p0

    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method private static identity(Landroid/content/Intent;)Z
    .locals 3

    .line 379
    if-eqz p0, :cond_0

    new-instance v0, Landroid/content/ComponentName;

    const-string v1, "com.google.android.gms"

    const-string v2, "org.microg.gms.auth.credentials.identity.IdentityCredentialChooserActivity"

    invoke-direct {v0, v1, v2}, Landroid/content/ComponentName;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    invoke-virtual {p0}, Landroid/content/Intent;->getComponent()Landroid/content/ComponentName;

    move-result-object p0

    invoke-virtual {v0, p0}, Landroid/content/ComponentName;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    const/4 p0, 0x1

    goto :goto_0

    :cond_0
    const/4 p0, 0x0

    :goto_0
    return p0
.end method

.method private static inner(Landroid/content/Intent;)Landroid/content/Intent;
    .locals 1

    .line 371
    if-nez p0, :cond_0

    const/4 p0, 0x0

    goto :goto_0

    :cond_0
    const-string v0, "_B_|_P_target_"

    invoke-virtual {p0, v0}, Landroid/content/Intent;->getParcelableExtra(Ljava/lang/String;)Landroid/os/Parcelable;

    move-result-object p0

    check-cast p0, Landroid/content/Intent;

    :goto_0
    return-object p0
.end method

.method private static marker(Landroid/content/Intent;)V
    .locals 3

    .line 401
    if-eqz p0, :cond_2

    .line 402
    const-string v0, "io.github.leexeo.cage.space.GOOGLE_PENDING"

    invoke-virtual {p0, v0}, Landroid/content/Intent;->getStringExtra(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    .line 403
    if-eqz v0, :cond_1

    const-string v1, "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"

    invoke-virtual {v0, v1}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_1

    .line 404
    new-instance v1, Landroid/net/Uri$Builder;

    invoke-direct {v1}, Landroid/net/Uri$Builder;-><init>()V

    const-string v2, "cage-private-google-pending"

    invoke-virtual {v1, v2}, Landroid/net/Uri$Builder;->scheme(Ljava/lang/String;)Landroid/net/Uri$Builder;

    move-result-object v1

    const-string v2, "request"

    invoke-virtual {v1, v2}, Landroid/net/Uri$Builder;->authority(Ljava/lang/String;)Landroid/net/Uri$Builder;

    move-result-object v1

    invoke-virtual {v1, v0}, Landroid/net/Uri$Builder;->appendPath(Ljava/lang/String;)Landroid/net/Uri$Builder;

    move-result-object v0

    invoke-virtual {v0}, Landroid/net/Uri$Builder;->build()Landroid/net/Uri;

    move-result-object v0

    .line 405
    invoke-virtual {p0}, Landroid/content/Intent;->getData()Landroid/net/Uri;

    move-result-object p0

    invoke-virtual {v0, p0}, Landroid/net/Uri;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    .line 406
    return-void

    .line 405
    :cond_0
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 403
    :cond_1
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 401
    :cond_2
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method public static prepare(Ljava/lang/reflect/Method;[Ljava/lang/Object;)V
    .locals 4

    .line 69
    const-string v0, "io.github.leexeo.cage.space.GOOGLE_PENDING"

    const-string v1, "com.google.android.gms"

    invoke-static {v1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->guest(Ljava/lang/String;)Z

    move-result v1

    if-nez v1, :cond_0

    return-void

    .line 70
    :cond_0
    invoke-static {p1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->wrapper([Ljava/lang/Object;)Landroid/content/Intent;

    move-result-object v1

    .line 71
    invoke-static {v1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->inner(Landroid/content/Intent;)Landroid/content/Intent;

    move-result-object v2

    .line 72
    invoke-static {v2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->candidate(Landroid/content/Intent;)Z

    move-result v3

    if-nez v3, :cond_1

    return-void

    .line 74
    :cond_1
    :try_start_0
    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->creationShape(Ljava/lang/reflect/Method;[Ljava/lang/Object;)V

    .line 75
    invoke-static {v2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->targetShape(Landroid/content/Intent;)V

    .line 76
    invoke-virtual {v1}, Landroid/content/Intent;->getData()Landroid/net/Uri;

    move-result-object p0

    if-nez p0, :cond_2

    invoke-virtual {v1, v0}, Landroid/content/Intent;->hasExtra(Ljava/lang/String;)Z

    move-result p0

    if-nez p0, :cond_2

    .line 77
    invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;

    move-result-object p0

    invoke-virtual {p0}, Ljava/util/UUID;->toString()Ljava/lang/String;

    move-result-object p0

    .line 78
    invoke-virtual {v1, v0, p0}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;

    .line 81
    new-instance p1, Landroid/net/Uri$Builder;

    invoke-direct {p1}, Landroid/net/Uri$Builder;-><init>()V

    const-string v0, "cage-private-google-pending"

    invoke-virtual {p1, v0}, Landroid/net/Uri$Builder;->scheme(Ljava/lang/String;)Landroid/net/Uri$Builder;

    move-result-object p1

    const-string v0, "request"

    invoke-virtual {p1, v0}, Landroid/net/Uri$Builder;->authority(Ljava/lang/String;)Landroid/net/Uri$Builder;

    move-result-object p1

    invoke-virtual {p1, p0}, Landroid/net/Uri$Builder;->appendPath(Ljava/lang/String;)Landroid/net/Uri$Builder;

    move-result-object p0

    invoke-virtual {p0}, Landroid/net/Uri$Builder;->build()Landroid/net/Uri;

    move-result-object p0

    invoke-virtual {v1, p0}, Landroid/content/Intent;->setData(Landroid/net/Uri;)Landroid/content/Intent;

    .line 82
    const-string p0, "CageDemo"

    const-string p1, "Google pending: prepared"

    invoke-static {p0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 83
    nop

    .line 84
    return-void

    .line 76
    :cond_2
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 83
    :catch_0
    move-exception p0

    const-string p1, "prepare"

    invoke-static {p1, p0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->blocked(Ljava/lang/String;Ljava/lang/Exception;)Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method private static privateTarget(Landroid/content/Context;Landroid/content/Intent;)V
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 268
    invoke-static {p1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->targetShape(Landroid/content/Intent;)V

    .line 269
    invoke-static {p1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->identity(Landroid/content/Intent;)Z

    move-result v0

    .line 270
    if-eqz v0, :cond_0

    const-string v1, "org.microg.gms.auth.credentials.identity.IdentityCredentialChooserActivity"

    goto :goto_0

    :cond_0
    const-string v1, "org.microg.gms.auth.signin.AssistedSignInActivity"

    .line 271
    :goto_0
    const-string v2, "top.niunaijun.blackbox.core.system.pm.BPackageManagerService"

    invoke-static {v2}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v2

    .line 272
    const-class v3, Landroid/content/Intent;

    sget-object v4, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    const-class v5, Ljava/lang/String;

    sget-object v6, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v3, v4, v5, v6}, [Ljava/lang/Class;

    move-result-object v3

    const-string v4, "resolveActivity"

    invoke-virtual {v2, v4, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v3

    const/4 v4, 0x0

    new-array v5, v4, [Ljava/lang/Class;

    .line 273
    const-string v6, "get"

    invoke-virtual {v2, v6, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    new-array v5, v4, [Ljava/lang/Object;

    const/4 v6, 0x0

    invoke-virtual {v2, v6, v5}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v5

    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v4

    filled-new-array {p1, v5, v6, v4}, [Ljava/lang/Object;

    move-result-object v4

    invoke-virtual {v3, v2, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Landroid/content/pm/ResolveInfo;

    .line 274
    if-nez v2, :cond_1

    goto :goto_1

    :cond_1
    iget-object v6, v2, Landroid/content/pm/ResolveInfo;->activityInfo:Landroid/content/pm/ActivityInfo;

    .line 277
    :goto_1
    if-eqz v6, :cond_3

    iget-object v2, v6, Landroid/content/pm/ActivityInfo;->packageName:Ljava/lang/String;

    const-string v3, "com.google.android.gms"

    invoke-virtual {v3, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_3

    iget-object v2, v6, Landroid/content/pm/ActivityInfo;->name:Ljava/lang/String;

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_3

    iget-boolean v2, v6, Landroid/content/pm/ActivityInfo;->enabled:Z

    if-eqz v2, :cond_3

    iget-boolean v2, v6, Landroid/content/pm/ActivityInfo;->exported:Z

    if-eq v2, v0, :cond_3

    .line 279
    new-instance v0, Lio/github/leexeo/cage/space/SpacePackages;

    invoke-direct {v0, p0}, Lio/github/leexeo/cage/space/SpacePackages;-><init>(Landroid/content/Context;)V

    .line 280
    invoke-virtual {v0, v3}, Lio/github/leexeo/cage/space/SpacePackages;->installed(Ljava/lang/String;)Landroid/content/pm/PackageInfo;

    move-result-object v2

    .line 281
    invoke-virtual {v0, v2}, Lio/github/leexeo/cage/space/SpacePackages;->privateCopy(Landroid/content/pm/PackageInfo;)Z

    move-result v0

    if-eqz v0, :cond_2

    iget-object v0, v6, Landroid/content/pm/ActivityInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    if-eqz v0, :cond_2

    new-instance v0, Ljava/io/File;

    iget-object v4, v2, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget-object v4, v4, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    invoke-direct {v0, v4}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    .line 282
    invoke-virtual {v0}, Ljava/io/File;->getCanonicalFile()Ljava/io/File;

    move-result-object v0

    new-instance v4, Ljava/io/File;

    iget-object v5, v6, Landroid/content/pm/ActivityInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget-object v5, v5, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    invoke-direct {v4, v5}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    .line 283
    invoke-virtual {v4}, Ljava/io/File;->getCanonicalFile()Ljava/io/File;

    move-result-object v4

    invoke-virtual {v0, v4}, Ljava/io/File;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_2

    .line 284
    new-instance v0, Ljava/io/File;

    iget-object v2, v2, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget-object v2, v2, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    invoke-direct {v0, v2}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/SpacePackages;->inspect(Landroid/content/Context;Ljava/io/File;)Landroid/content/pm/PackageInfo;

    .line 285
    new-instance p0, Landroid/content/ComponentName;

    invoke-direct {p0, v3, v1}, Landroid/content/ComponentName;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    invoke-virtual {p1, p0}, Landroid/content/Intent;->setComponent(Landroid/content/ComponentName;)Landroid/content/Intent;

    .line 286
    return-void

    .line 283
    :cond_2
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 278
    :cond_3
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method private static process(I)Ljava/lang/Object;
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 289
    const-string v0, "top.niunaijun.blackbox.core.system.BProcessManagerService"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    .line 290
    sget-object v1, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v1}, [Ljava/lang/Class;

    move-result-object v1

    const-string v2, "findProcessByPid"

    invoke-virtual {v0, v2, v1}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    const/4 v2, 0x0

    new-array v3, v2, [Ljava/lang/Class;

    const-string v4, "get"

    invoke-virtual {v0, v4, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    const/4 v3, 0x0

    new-array v2, v2, [Ljava/lang/Object;

    invoke-virtual {v0, v3, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    filled-new-array {v2}, [Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {v1, v0, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    .line 291
    if-eqz v0, :cond_0

    const-string v1, "pid"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Ljava/lang/Integer;

    invoke-virtual {v1}, Ljava/lang/Integer;->intValue()I

    move-result v1

    if-ne v1, p0, :cond_0

    .line 292
    return-object v0

    .line 291
    :cond_0
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method private static realActivityManager()Ljava/lang/Object;
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 345
    const-string v0, "android.os.ServiceManager"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    const-class v1, Ljava/lang/String;

    filled-new-array {v1}, [Ljava/lang/Class;

    move-result-object v1

    .line 346
    const-string v2, "getService"

    invoke-virtual {v0, v2, v1}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    const-string v1, "activity"

    filled-new-array {v1}, [Ljava/lang/Object;

    move-result-object v1

    const/4 v2, 0x0

    invoke-virtual {v0, v2, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/os/IBinder;

    .line 347
    const-string v1, "top.niunaijun.blackbox.fake.hook.BinderInvocationStub"

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    .line 348
    const-string v3, "mBaseBinder"

    invoke-virtual {v1, v3}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v3

    .line 349
    const/4 v4, 0x1

    invoke-virtual {v3, v4}, Ljava/lang/reflect/Field;->setAccessible(Z)V

    .line 350
    const/4 v4, 0x0

    :goto_0
    const/4 v5, 0x4

    if-ge v4, v5, :cond_0

    invoke-virtual {v1, v0}, Ljava/lang/Class;->isInstance(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_0

    .line 351
    invoke-virtual {v3, v0}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/os/IBinder;

    .line 350
    add-int/lit8 v4, v4, 0x1

    goto :goto_0

    .line 352
    :cond_0
    if-eqz v0, :cond_2

    invoke-virtual {v0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/Class;->getName()Ljava/lang/String;

    move-result-object v1

    const-string v3, "android.os.BinderProxy"

    invoke-virtual {v3, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_2

    .line 353
    invoke-interface {v0}, Landroid/os/IBinder;->isBinderAlive()Z

    move-result v1

    if-eqz v1, :cond_2

    .line 354
    const-string v1, "android.app.IActivityManager$Stub"

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    const-class v3, Landroid/os/IBinder;

    filled-new-array {v3}, [Ljava/lang/Class;

    move-result-object v3

    .line 355
    const-string v4, "asInterface"

    invoke-virtual {v1, v4, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    filled-new-array {v0}, [Ljava/lang/Object;

    move-result-object v3

    invoke-virtual {v1, v2, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    .line 356
    instance-of v2, v1, Landroid/os/IInterface;

    if-eqz v2, :cond_1

    invoke-virtual {v1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v2

    invoke-static {v2}, Ljava/lang/reflect/Proxy;->isProxyClass(Ljava/lang/Class;)Z

    move-result v2

    if-nez v2, :cond_1

    move-object v2, v1

    check-cast v2, Landroid/os/IInterface;

    .line 357
    invoke-interface {v2}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    move-result-object v2

    invoke-virtual {v0, v2}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_1

    .line 358
    return-object v1

    .line 357
    :cond_1
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object v0

    throw v0

    .line 353
    :cond_2
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object v0

    throw v0
.end method

.method private static request(Ljava/lang/String;Landroid/os/Bundle;)Landroid/os/Bundle;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 315
    const-string v0, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    const/4 v1, 0x0

    new-array v2, v1, [Ljava/lang/Class;

    const-string v3, "getContext"

    invoke-virtual {v0, v3, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    const/4 v2, 0x0

    new-array v1, v1, [Ljava/lang/Object;

    invoke-virtual {v0, v2, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/content/Context;

    .line 316
    invoke-virtual {v0}, Landroid/content/Context;->getContentResolver()Landroid/content/ContentResolver;

    move-result-object v0

    const-string v1, "content://top.niunaijun.microdem.blackbox.SystemCallProvider"

    invoke-static {v1}, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;

    move-result-object v1

    const-string v2, "cage_demo_google_pending"

    invoke-virtual {v0, v1, v2, p0, p1}, Landroid/content/ContentResolver;->call(Landroid/net/Uri;Ljava/lang/String;Ljava/lang/String;Landroid/os/Bundle;)Landroid/os/Bundle;

    move-result-object p0

    return-object p0
.end method

.method private static requireMutability(Landroid/content/Intent;Z)V
    .locals 0

    .line 340
    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->identity(Landroid/content/Intent;)Z

    move-result p0

    xor-int/lit8 p0, p0, 0x1

    if-ne p1, p0, :cond_0

    .line 341
    return-void

    .line 340
    :cond_0
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method private static requireRealSenderOwner(Landroid/content/Context;Landroid/os/IBinder;)Z
    .locals 9
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 320
    const-string v0, "android.content.IIntentSender"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    .line 321
    const-string v1, "android.content.IIntentSender$Stub"

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    const-class v2, Landroid/os/IBinder;

    filled-new-array {v2}, [Ljava/lang/Class;

    move-result-object v2

    .line 322
    const-string v3, "asInterface"

    invoke-virtual {v1, v3, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    const/4 v2, 0x0

    filled-new-array {p1}, [Ljava/lang/Object;

    move-result-object p1

    invoke-virtual {v1, v2, p1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    .line 323
    const-string v1, "android.app.IActivityManager"

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    filled-new-array {v0}, [Ljava/lang/Class;

    move-result-object v0

    .line 324
    const-string v2, "getInfoForIntentSender"

    invoke-virtual {v1, v2, v0}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->realActivityManager()Ljava/lang/Object;

    move-result-object v1

    filled-new-array {p1}, [Ljava/lang/Object;

    move-result-object p1

    invoke-virtual {v0, v1, p1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    .line 325
    const-string v0, "getIntentSenderType"

    const-string v1, "isImmutable"

    const-string v2, "getCreatorUid"

    const-string v3, "getCreatorPackage"

    const/4 v4, 0x0

    if-eqz p1, :cond_0

    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    const-string v6, "Google pending owner: package="

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    .line 326
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v6

    new-array v7, v4, [Ljava/lang/Class;

    invoke-virtual {v6, v3, v7}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v6

    new-array v7, v4, [Ljava/lang/Object;

    invoke-virtual {v6, p1, v7}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v6

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v5

    const-string v6, " uidMatches="

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    .line 327
    invoke-virtual {p0}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;

    move-result-object v6

    iget v6, v6, Landroid/content/pm/ApplicationInfo;->uid:I

    invoke-static {v6}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v6

    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v7

    new-array v8, v4, [Ljava/lang/Class;

    invoke-virtual {v7, v2, v8}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v7

    new-array v8, v4, [Ljava/lang/Object;

    invoke-virtual {v7, p1, v8}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v7

    invoke-virtual {v6, v7}, Ljava/lang/Integer;->equals(Ljava/lang/Object;)Z

    move-result v6

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object v5

    const-string v6, " immutable="

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    .line 328
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v6

    new-array v7, v4, [Ljava/lang/Class;

    invoke-virtual {v6, v1, v7}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v6

    new-array v7, v4, [Ljava/lang/Object;

    invoke-virtual {v6, p1, v7}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v6

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v5

    const-string v6, " type="

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    .line 329
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v6

    new-array v7, v4, [Ljava/lang/Class;

    invoke-virtual {v6, v0, v7}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v6

    new-array v7, v4, [Ljava/lang/Object;

    invoke-virtual {v6, p1, v7}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v6

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v5

    .line 325
    const-string v6, "CageDemo"

    invoke-static {v6, v5}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 330
    :cond_0
    if-eqz p1, :cond_2

    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v5

    new-array v6, v4, [Ljava/lang/Class;

    invoke-virtual {v5, v3, v6}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v3

    new-array v5, v4, [Ljava/lang/Object;

    invoke-virtual {v3, p1, v5}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v3

    const-string v5, "top.niunaijun.microdem"

    invoke-virtual {v5, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_2

    .line 331
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v3

    new-array v5, v4, [Ljava/lang/Class;

    invoke-virtual {v3, v2, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    new-array v3, v4, [Ljava/lang/Object;

    invoke-virtual {v2, p1, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Ljava/lang/Integer;

    invoke-virtual {v2}, Ljava/lang/Integer;->intValue()I

    move-result v2

    invoke-virtual {p0}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;

    move-result-object p0

    iget p0, p0, Landroid/content/pm/ApplicationInfo;->uid:I

    if-ne v2, p0, :cond_2

    .line 332
    const/4 p0, 0x2

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0

    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v2

    new-array v3, v4, [Ljava/lang/Class;

    invoke-virtual {v2, v0, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    new-array v2, v4, [Ljava/lang/Object;

    invoke-virtual {v0, p1, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    invoke-virtual {p0, v0}, Ljava/lang/Integer;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_2

    .line 333
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object p0

    new-array v0, v4, [Ljava/lang/Class;

    invoke-virtual {p0, v1, v0}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    new-array v0, v4, [Ljava/lang/Object;

    invoke-virtual {p0, p1, v0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    .line 334
    instance-of p1, p0, Ljava/lang/Boolean;

    if-eqz p1, :cond_1

    .line 335
    check-cast p0, Ljava/lang/Boolean;

    invoke-virtual {p0}, Ljava/lang/Boolean;->booleanValue()Z

    move-result p0

    return p0

    .line 334
    :cond_1
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 332
    :cond_2
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method public static start(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 19

    .line 181
    const-string v0, "CageDemo"

    const-string v1, "startActivityIntentSender"

    invoke-virtual/range {p1 .. p1}, Ljava/lang/reflect/Method;->getName()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    const/4 v2, 0x0

    if-eqz v1, :cond_5

    const-string v1, "com.anthropic.claude"

    invoke-static {v1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->guest(Ljava/lang/String;)Z

    move-result v1

    if-nez v1, :cond_0

    goto/16 :goto_2

    .line 182
    :cond_0
    const-string v1, "start-shape"

    .line 184
    const/16 v3, -0x60

    :try_start_0
    invoke-static/range {p1 .. p2}, Lio/github/leexeo/cage/space/GuestPendingActivity;->startShape(Ljava/lang/reflect/Method;[Ljava/lang/Object;)V

    .line 185
    const/4 v4, 0x1

    aget-object v4, p2, v4

    check-cast v4, Landroid/os/IInterface;

    .line 186
    new-instance v5, Landroid/os/Bundle;

    invoke-direct {v5}, Landroid/os/Bundle;-><init>()V

    .line 187
    const-string v6, "sender"

    invoke-interface {v4}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    move-result-object v4

    invoke-virtual {v5, v6, v4}, Landroid/os/Bundle;->putBinder(Ljava/lang/String;Landroid/os/IBinder;)V

    .line 188
    const-string v4, "caller"

    const/4 v6, 0x0

    aget-object v7, p2, v6

    check-cast v7, Landroid/os/IInterface;

    invoke-interface {v7}, Landroid/os/IInterface;->asBinder()Landroid/os/IBinder;

    move-result-object v7

    invoke-virtual {v5, v4, v7}, Landroid/os/Bundle;->putBinder(Ljava/lang/String;Landroid/os/IBinder;)V

    .line 189
    const-string v4, "resultTo"

    const/4 v7, 0x5

    aget-object v8, p2, v7

    check-cast v8, Landroid/os/IBinder;

    invoke-virtual {v5, v4, v8}, Landroid/os/Bundle;->putBinder(Ljava/lang/String;Landroid/os/IBinder;)V

    .line 190
    const-string v1, "start-claim"

    .line 191
    const-string v4, "claim"

    invoke-static {v4, v5}, Lio/github/leexeo/cage/space/GuestPendingActivity;->request(Ljava/lang/String;Landroid/os/Bundle;)Landroid/os/Bundle;

    move-result-object v4

    .line 192
    if-nez v4, :cond_1

    move-object v9, v2

    goto :goto_0

    :cond_1
    const-string v5, "target"

    invoke-virtual {v4, v5}, Landroid/os/Bundle;->getParcelable(Ljava/lang/String;)Landroid/os/Parcelable;

    move-result-object v4

    check-cast v4, Landroid/content/Intent;

    move-object v9, v4

    .line 193
    :goto_0
    invoke-static {v9}, Lio/github/leexeo/cage/space/GuestPendingActivity;->targetShape(Landroid/content/Intent;)V

    .line 199
    invoke-virtual/range {p2 .. p2}, [Ljava/lang/Object;->clone()Ljava/lang/Object;

    move-result-object v4

    check-cast v4, [Ljava/lang/Object;

    .line 200
    aput-object v2, v4, v7

    .line 201
    const/4 v5, 0x6

    aput-object v2, v4, v5

    .line 202
    const/4 v8, -0x1

    invoke-static {v8}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v8

    const/4 v10, 0x7

    aput-object v8, v4, v10

    .line 203
    const-string v1, "system-send"

    .line 204
    move-object/from16 v8, p0

    move-object/from16 v11, p1

    invoke-virtual {v11, v8, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Ljava/lang/Integer;

    invoke-virtual {v4}, Ljava/lang/Integer;->intValue()I

    move-result v4

    .line 208
    if-eqz v4, :cond_3

    if-gez v4, :cond_2

    goto :goto_1

    :cond_2
    move v4, v3

    :goto_1
    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    return-object v0

    .line 209
    :cond_3
    const-string v4, "Google pending: systemAccepted"

    invoke-static {v0, v4}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 212
    const-string v1, "private-service"

    .line 213
    const-string v4, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v4}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v4

    .line 214
    const-string v8, "getBActivityManager"

    new-array v11, v6, [Ljava/lang/Class;

    invoke-virtual {v4, v8, v11}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v4

    new-array v8, v6, [Ljava/lang/Object;

    invoke-virtual {v4, v2, v8}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    .line 215
    invoke-virtual {v2}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v4

    const-string v8, "getService"

    new-array v11, v6, [Ljava/lang/Class;

    invoke-virtual {v4, v8, v11}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v4

    new-array v8, v6, [Ljava/lang/Object;

    invoke-virtual {v4, v2, v8}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    .line 216
    if-eqz v2, :cond_4

    .line 217
    const-string v4, "top.niunaijun.blackbox.core.system.am.IBActivityManagerService"

    invoke-static {v4}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v4

    const-string v8, "startActivityAms"

    sget-object v11, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    const-class v12, Landroid/content/Intent;

    const-class v13, Ljava/lang/String;

    const-class v14, Landroid/os/IBinder;

    const-class v15, Ljava/lang/String;

    sget-object v16, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    sget-object v17, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    const-class v18, Landroid/os/Bundle;

    filled-new-array/range {v11 .. v18}, [Ljava/lang/Class;

    move-result-object v11

    .line 218
    invoke-virtual {v4, v8, v11}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v4

    .line 221
    const-string v1, "private-dispatch"

    .line 222
    invoke-static {v6}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v8

    const/4 v11, 0x4

    aget-object v11, p2, v11

    aget-object v7, p2, v7

    aget-object v12, p2, v5

    aget-object v13, p2, v10

    invoke-static {v6}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v14

    const/16 v5, 0xa

    aget-object v15, p2, v5

    move-object v10, v11

    move-object v11, v7

    filled-new-array/range {v8 .. v15}, [Ljava/lang/Object;

    move-result-object v5

    invoke-virtual {v4, v2, v5}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    .line 223
    const-string v4, "Google pending: privateDispatched"

    invoke-static {v0, v4}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 224
    return-object v2

    .line 216
    :cond_4
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object v0

    throw v0
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 225
    :catch_0
    move-exception v0

    .line 226
    invoke-static {v1, v0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->blocked(Ljava/lang/String;Ljava/lang/Exception;)Ljava/lang/SecurityException;

    .line 229
    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    return-object v0

    .line 181
    :cond_5
    :goto_2
    return-object v2
.end method

.method private static startShape(Ljava/lang/reflect/Method;[Ljava/lang/Object;)V
    .locals 11

    .line 428
    const-string v9, "int"

    const-string v10, "android.os.Bundle"

    const-string v0, "android.app.IApplicationThread"

    const-string v1, "android.content.IIntentSender"

    const-string v2, "android.os.IBinder"

    const-string v3, "android.content.Intent"

    const-string v4, "java.lang.String"

    const-string v5, "android.os.IBinder"

    const-string v6, "java.lang.String"

    const-string v7, "int"

    const-string v8, "int"

    filled-new-array/range {v0 .. v10}, [Ljava/lang/String;

    move-result-object v0

    .line 430
    invoke-virtual {p0}, Ljava/lang/reflect/Method;->getParameterTypes()[Ljava/lang/Class;

    move-result-object v1

    .line 431
    if-eqz p1, :cond_4

    array-length v2, p1

    const/16 v3, 0xb

    if-ne v2, v3, :cond_4

    array-length v2, v1

    if-ne v2, v3, :cond_4

    invoke-virtual {p0}, Ljava/lang/reflect/Method;->getReturnType()Ljava/lang/Class;

    move-result-object p0

    sget-object v2, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    if-ne p0, v2, :cond_4

    .line 432
    const/4 p0, 0x0

    move v2, p0

    :goto_0
    if-ge v2, v3, :cond_1

    aget-object v4, v0, v2

    aget-object v5, v1, v2

    invoke-virtual {v5}, Ljava/lang/Class;->getName()Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v4, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_0

    add-int/lit8 v2, v2, 0x1

    goto :goto_0

    :cond_0
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 433
    :cond_1
    aget-object v0, p1, p0

    instance-of v0, v0, Landroid/os/IInterface;

    if-eqz v0, :cond_3

    const/4 v0, 0x1

    aget-object v0, p1, v0

    instance-of v0, v0, Landroid/os/IInterface;

    if-eqz v0, :cond_3

    const/4 v0, 0x2

    aget-object v0, p1, v0

    if-nez v0, :cond_3

    const/4 v0, 0x3

    aget-object v0, p1, v0

    if-nez v0, :cond_3

    const/4 v0, 0x4

    aget-object v0, p1, v0

    if-nez v0, :cond_3

    const/4 v0, 0x5

    aget-object v0, p1, v0

    instance-of v0, v0, Landroid/os/IBinder;

    if-eqz v0, :cond_3

    const/4 v0, 0x6

    aget-object v1, p1, v0

    if-eqz v1, :cond_2

    aget-object v0, p1, v0

    instance-of v0, v0, Ljava/lang/String;

    if-eqz v0, :cond_3

    :cond_2
    const/4 v0, 0x7

    aget-object v1, p1, v0

    instance-of v1, v1, Ljava/lang/Integer;

    if-eqz v1, :cond_3

    aget-object v1, p1, v0

    check-cast v1, Ljava/lang/Integer;

    .line 435
    invoke-virtual {v1}, Ljava/lang/Integer;->intValue()I

    move-result v1

    if-ltz v1, :cond_3

    aget-object v0, p1, v0

    check-cast v0, Ljava/lang/Integer;

    invoke-virtual {v0}, Ljava/lang/Integer;->intValue()I

    move-result v0

    const v1, 0xffff

    if-gt v0, v1, :cond_3

    .line 436
    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    const/16 v1, 0x8

    aget-object v1, p1, v1

    invoke-virtual {v0, v1}, Ljava/lang/Integer;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_3

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0

    const/16 v0, 0x9

    aget-object v0, p1, v0

    invoke-virtual {p0, v0}, Ljava/lang/Integer;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_3

    const/16 p0, 0xa

    aget-object p0, p1, p0

    if-nez p0, :cond_3

    .line 437
    return-void

    .line 436
    :cond_3
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 431
    :cond_4
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method private static targetShape(Landroid/content/Intent;)V
    .locals 4

    .line 383
    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->candidate(Landroid/content/Intent;)Z

    move-result v0

    if-eqz v0, :cond_4

    invoke-virtual {p0}, Landroid/content/Intent;->getData()Landroid/net/Uri;

    move-result-object v0

    if-nez v0, :cond_4

    invoke-virtual {p0}, Landroid/content/Intent;->getType()Ljava/lang/String;

    move-result-object v0

    if-nez v0, :cond_4

    .line 384
    invoke-virtual {p0}, Landroid/content/Intent;->getSelector()Landroid/content/Intent;

    move-result-object v0

    if-nez v0, :cond_4

    invoke-virtual {p0}, Landroid/content/Intent;->getClipData()Landroid/content/ClipData;

    move-result-object v0

    if-nez v0, :cond_4

    invoke-virtual {p0}, Landroid/content/Intent;->getFlags()I

    move-result v0

    if-nez v0, :cond_4

    .line 385
    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->identity(Landroid/content/Intent;)Z

    move-result v0

    const-string v1, "com.anthropic.claude"

    if-eqz v0, :cond_1

    .line 386
    invoke-virtual {p0}, Landroid/content/Intent;->getExtras()Landroid/os/Bundle;

    move-result-object v0

    .line 387
    invoke-virtual {p0}, Landroid/content/Intent;->getAction()Ljava/lang/String;

    move-result-object v2

    if-nez v2, :cond_0

    invoke-virtual {p0}, Landroid/content/Intent;->getPackage()Ljava/lang/String;

    move-result-object v2

    if-nez v2, :cond_0

    invoke-virtual {p0}, Landroid/content/Intent;->getCategories()Ljava/util/Set;

    move-result-object v2

    if-nez v2, :cond_0

    .line 388
    const-string v2, "org.microg.gms.identitycredentials.EXTRA_CALLING_PACKAGE"

    invoke-virtual {p0, v2}, Landroid/content/Intent;->getStringExtra(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_0

    if-eqz v0, :cond_0

    .line 389
    invoke-virtual {v0}, Landroid/os/Bundle;->size()I

    move-result v0

    const/4 v1, 0x2

    if-ne v0, v1, :cond_0

    const-string v0, "org.microg.gms.identitycredentials.EXTRA_GET_REQUEST"

    invoke-virtual {p0, v0}, Landroid/content/Intent;->getBundleExtra(Ljava/lang/String;)Landroid/os/Bundle;

    move-result-object p0

    if-eqz p0, :cond_0

    .line 392
    return-void

    .line 389
    :cond_0
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 394
    :cond_1
    invoke-virtual {p0}, Landroid/content/Intent;->getPackage()Ljava/lang/String;

    move-result-object v0

    const-string v2, "com.google.android.gms"

    invoke-virtual {v2, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_3

    .line 395
    invoke-virtual {p0}, Landroid/content/Intent;->getComponent()Landroid/content/ComponentName;

    move-result-object v0

    if-eqz v0, :cond_2

    new-instance v0, Landroid/content/ComponentName;

    const-string v3, "org.microg.gms.auth.signin.AssistedSignInActivity"

    invoke-direct {v0, v2, v3}, Landroid/content/ComponentName;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    invoke-virtual {p0}, Landroid/content/Intent;->getComponent()Landroid/content/ComponentName;

    move-result-object v2

    invoke-virtual {v0, v2}, Landroid/content/ComponentName;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_3

    .line 396
    :cond_2
    const-string v0, "client_package_name"

    invoke-virtual {p0, v0}, Landroid/content/Intent;->getStringExtra(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_3

    .line 397
    const-string v0, "get_sign_in_intent_request"

    invoke-virtual {p0, v0}, Landroid/content/Intent;->hasExtra(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_3

    const-string v0, "google_sign_in_options"

    invoke-virtual {p0, v0}, Landroid/content/Intent;->hasExtra(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_3

    .line 398
    return-void

    .line 397
    :cond_3
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 384
    :cond_4
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method private static verifyResultOwner(Ljava/lang/Object;Landroid/os/IBinder;)V
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 246
    if-eqz p1, :cond_2

    invoke-interface {p1}, Landroid/os/IBinder;->isBinderAlive()Z

    move-result v0

    if-eqz v0, :cond_2

    .line 247
    const-string v0, "top.niunaijun.blackbox.core.system.am.BActivityManagerService"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    const-string v1, "get"

    const/4 v2, 0x0

    new-array v3, v2, [Ljava/lang/Class;

    .line 248
    invoke-virtual {v0, v1, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    const/4 v1, 0x0

    new-array v3, v2, [Ljava/lang/Object;

    invoke-virtual {v0, v1, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    .line 249
    const-string v1, "mUserSpace"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/util/Map;

    .line 251
    monitor-enter v0

    :try_start_0
    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    invoke-interface {v0, v1}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    monitor-exit v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    .line 252
    if-eqz v1, :cond_1

    .line 253
    const-string v0, "mStack"

    invoke-static {v1, v0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v0

    .line 254
    monitor-enter v0

    .line 255
    :try_start_1
    const-string v1, "mTasks"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v1

    .line 256
    monitor-enter v1
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    .line 257
    :try_start_2
    invoke-virtual {v0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v3

    const-string v4, "findActivityRecordByToken"

    sget-object v5, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    const-class v6, Landroid/os/IBinder;

    filled-new-array {v5, v6}, [Ljava/lang/Class;

    move-result-object v5

    invoke-virtual {v3, v4, v5}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v3

    .line 258
    const/4 v4, 0x1

    invoke-virtual {v3, v4}, Ljava/lang/reflect/Method;->setAccessible(Z)V

    .line 259
    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    filled-new-array {v2, p1}, [Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {v3, v0, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    .line 260
    if-eqz v2, :cond_0

    sget-object v3, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    const-string v4, "finished"

    invoke-static {v2, v4}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v4

    invoke-virtual {v3, v4}, Ljava/lang/Boolean;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_0

    const-string v3, "processRecord"

    .line 261
    invoke-static {v2, v3}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v3

    if-ne v3, p0, :cond_0

    const-string p0, "token"

    invoke-static {v2, p0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object p0

    invoke-virtual {p1, p0}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    new-instance p0, Landroid/content/ComponentName;

    const-string p1, "com.anthropic.claude"

    const-string v3, "androidx.credentials.playservices.controllers.identityauth.HiddenActivity"

    invoke-direct {p0, p1, v3}, Landroid/content/ComponentName;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    const-string p1, "component"

    .line 262
    invoke-static {v2, p1}, Lio/github/leexeo/cage/space/GuestPendingActivity;->field(Ljava/lang/Object;Ljava/lang/String;)Ljava/lang/Object;

    move-result-object p1

    invoke-virtual {p0, p1}, Landroid/content/ComponentName;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    .line 263
    monitor-exit v1
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    .line 264
    :try_start_3
    monitor-exit v0
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    .line 265
    return-void

    .line 262
    :cond_0
    :try_start_4
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 263
    :catchall_0
    move-exception p0

    monitor-exit v1
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_0

    :try_start_5
    throw p0

    .line 264
    :catchall_1
    move-exception p0

    monitor-exit v0
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_1

    throw p0

    .line 252
    :cond_1
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0

    .line 251
    :catchall_2
    move-exception p0

    :try_start_6
    monitor-exit v0
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_2

    throw p0

    .line 246
    :cond_2
    invoke-static {}, Lio/github/leexeo/cage/space/GuestPendingActivity;->denied()Ljava/lang/SecurityException;

    move-result-object p0

    throw p0
.end method

.method private static wrapper([Ljava/lang/Object;)Landroid/content/Intent;
    .locals 6

    .line 362
    const/4 v0, 0x0

    if-nez p0, :cond_0

    return-object v0

    .line 363
    :cond_0
    array-length v1, p0

    const/4 v2, 0x0

    move v3, v2

    :goto_0
    if-ge v3, v1, :cond_3

    aget-object v4, p0, v3

    instance-of v5, v4, [Landroid/content/Intent;

    if-eqz v5, :cond_2

    .line 364
    check-cast v4, [Landroid/content/Intent;

    .line 365
    array-length p0, v4

    const/4 v1, 0x1

    if-ne p0, v1, :cond_1

    aget-object v0, v4, v2

    :cond_1
    return-object v0

    .line 363
    :cond_2
    add-int/lit8 v3, v3, 0x1

    goto :goto_0

    .line 367
    :cond_3
    return-object v0
.end method
