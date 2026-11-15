.class public final Lio/github/leexeo/cage/space/GuestCredentialResult;
.super Ljava/lang/Object;
.source "GuestCredentialResult.java"


# static fields
.field private static final CHOOSER:Ljava/lang/String; = "org.microg.gms.auth.credentials.identity.IdentityCredentialChooserActivity"

.field private static final EXCEPTION:Ljava/lang/String; = "android.service.credentials.extra.GET_CREDENTIAL_EXCEPTION"

.field private static final RESPONSE:Ljava/lang/String; = "android.service.credentials.extra.GET_CREDENTIAL_RESPONSE"


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 20
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static finish([Ljava/lang/Object;)V
    .locals 11

    .line 23
    const-string v0, "android.service.credentials.extra.GET_CREDENTIAL_EXCEPTION"

    const-string v1, "android.service.credentials.extra.GET_CREDENTIAL_RESPONSE"

    const-string v2, "com.anthropic.claude"

    const-string v3, "CageDemo"

    sget v4, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v5, 0x22

    if-lt v4, v5, :cond_e

    if-eqz p0, :cond_e

    array-length v4, p0

    const/4 v5, 0x4

    if-ne v4, v5, :cond_e

    const/4 v4, 0x0

    aget-object v5, p0, v4

    instance-of v5, v5, Landroid/os/IBinder;

    if-eqz v5, :cond_e

    .line 24
    const/4 v5, -0x1

    invoke-static {v5}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v5

    const/4 v6, 0x1

    aget-object v6, p0, v6

    invoke-virtual {v5, v6}, Ljava/lang/Integer;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_e

    const/4 v5, 0x2

    aget-object v6, p0, v5

    instance-of v6, v6, Landroid/content/Intent;

    if-eqz v6, :cond_e

    const/4 v6, 0x3

    aget-object v6, p0, v6

    instance-of v6, v6, Ljava/lang/Integer;

    if-nez v6, :cond_0

    goto/16 :goto_8

    .line 27
    :cond_0
    :try_start_0
    const-string v6, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v6}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v6

    .line 28
    const-string v7, "getContext"

    new-array v8, v4, [Ljava/lang/Class;

    invoke-virtual {v6, v7, v8}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v7

    new-array v8, v4, [Ljava/lang/Object;

    const/4 v9, 0x0

    invoke-virtual {v7, v9, v8}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v7

    check-cast v7, Landroid/content/Context;

    .line 29
    const-string v8, "top.niunaijun.microdem"

    invoke-virtual {v7}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v7

    invoke-virtual {v8, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v7

    if-eqz v7, :cond_d

    const-string v7, "isBlackProcess"

    new-array v8, v4, [Ljava/lang/Class;

    .line 30
    invoke-virtual {v6, v7, v8}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v7

    const-string v8, "get"

    new-array v10, v4, [Ljava/lang/Class;

    invoke-virtual {v6, v8, v10}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v6

    new-array v8, v4, [Ljava/lang/Object;

    invoke-virtual {v6, v9, v8}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v6

    new-array v8, v4, [Ljava/lang/Object;

    invoke-virtual {v7, v6, v8}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v6

    check-cast v6, Ljava/lang/Boolean;

    invoke-virtual {v6}, Ljava/lang/Boolean;->booleanValue()Z

    move-result v6

    if-nez v6, :cond_1

    goto/16 :goto_6

    .line 31
    :cond_1
    const-string v6, "top.niunaijun.blackbox.app.BActivityThread"

    invoke-static {v6}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v6

    .line 32
    const-string v7, "com.google.android.gms"

    const-string v8, "getAppPackageName"

    new-array v10, v4, [Ljava/lang/Class;

    invoke-virtual {v6, v8, v10}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v8

    new-array v10, v4, [Ljava/lang/Object;

    invoke-virtual {v8, v9, v10}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v8

    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v7

    if-eqz v7, :cond_c

    const-string v7, "getUserId"

    new-array v8, v4, [Ljava/lang/Class;

    .line 33
    invoke-virtual {v6, v7, v8}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v7

    new-array v8, v4, [Ljava/lang/Object;

    invoke-virtual {v7, v9, v8}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v7

    check-cast v7, Ljava/lang/Integer;

    invoke-virtual {v7}, Ljava/lang/Integer;->intValue()I

    move-result v7

    if-eqz v7, :cond_2

    goto/16 :goto_5

    .line 34
    :cond_2
    const-string v7, "getActivityByToken"

    const-class v8, Landroid/os/IBinder;

    filled-new-array {v8}, [Ljava/lang/Class;

    move-result-object v8

    invoke-virtual {v6, v7, v8}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v6

    aget-object v4, p0, v4

    filled-new-array {v4}, [Ljava/lang/Object;

    move-result-object v4

    invoke-virtual {v6, v9, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Landroid/app/Activity;

    .line 35
    if-eqz v4, :cond_b

    invoke-virtual {v4}, Landroid/app/Activity;->isDestroyed()Z

    move-result v6

    if-nez v6, :cond_b

    const-string v6, "org.microg.gms.auth.credentials.identity.IdentityCredentialChooserActivity"

    invoke-virtual {v4}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v7

    invoke-virtual {v7}, Ljava/lang/Class;->getName()Ljava/lang/String;

    move-result-object v7

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_b

    new-instance v6, Landroid/content/ComponentName;

    const-string v7, "androidx.credentials.playservices.controllers.identityauth.HiddenActivity"

    invoke-direct {v6, v2, v7}, Landroid/content/ComponentName;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    .line 38
    invoke-virtual {v4}, Landroid/app/Activity;->getCallingActivity()Landroid/content/ComponentName;

    move-result-object v7

    invoke-virtual {v6, v7}, Landroid/content/ComponentName;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_b

    .line 39
    invoke-virtual {v4}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;

    move-result-object v4

    const-string v6, "org.microg.gms.identitycredentials.EXTRA_CALLING_PACKAGE"

    .line 40
    invoke-virtual {v4, v6}, Landroid/content/Intent;->getStringExtra(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v4

    .line 39
    invoke-virtual {v2, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_3

    goto/16 :goto_4

    .line 41
    :cond_3
    aget-object v2, p0, v5

    check-cast v2, Landroid/content/Intent;

    .line 42
    invoke-virtual {v2}, Landroid/content/Intent;->getExtras()Landroid/os/Bundle;

    move-result-object v4

    .line 43
    if-nez v4, :cond_4

    return-void

    .line 44
    :cond_4
    invoke-virtual {v4, v1}, Landroid/os/Bundle;->get(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v6

    invoke-virtual {v4, v0}, Landroid/os/Bundle;->get(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v4

    .line 45
    new-instance v7, Landroid/content/Intent;

    invoke-direct {v7, v2}, Landroid/content/Intent;-><init>(Landroid/content/Intent;)V

    .line 46
    instance-of v2, v6, Landroid/os/Bundle;

    if-eqz v2, :cond_7

    if-nez v4, :cond_7

    .line 47
    check-cast v6, Landroid/os/Bundle;

    .line 48
    const-string v0, "androidx.credentials.provider.extra.EXTRA_CREDENTIAL_TYPE"

    invoke-virtual {v6, v0}, Landroid/os/Bundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    .line 49
    const-string v2, "androidx.credentials.provider.extra.EXTRA_CREDENTIAL_DATA"

    invoke-virtual {v6, v2}, Landroid/os/Bundle;->getBundle(Ljava/lang/String;)Landroid/os/Bundle;

    move-result-object v2

    .line 50
    invoke-virtual {v6}, Landroid/os/Bundle;->size()I

    move-result v4

    if-ne v4, v5, :cond_6

    if-eqz v0, :cond_6

    invoke-virtual {v0}, Ljava/lang/String;->isEmpty()Z

    move-result v4

    if-nez v4, :cond_6

    if-nez v2, :cond_5

    goto :goto_0

    .line 52
    :cond_5
    new-instance v4, Landroid/credentials/GetCredentialResponse;

    new-instance v6, Landroid/credentials/Credential;

    invoke-direct {v6, v0, v2}, Landroid/credentials/Credential;-><init>(Ljava/lang/String;Landroid/os/Bundle;)V

    invoke-direct {v4, v6}, Landroid/credentials/GetCredentialResponse;-><init>(Landroid/credentials/Credential;)V

    invoke-virtual {v7, v1, v4}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Landroid/os/Parcelable;)Landroid/content/Intent;

    .line 53
    aput-object v7, p0, v5

    .line 54
    const-string p0, "Private Google result container adapted for Android 14+"

    invoke-static {v3, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    goto :goto_2

    .line 50
    :cond_6
    :goto_0
    return-void

    .line 55
    :cond_7
    instance-of v1, v4, Landroid/os/Bundle;

    if-eqz v1, :cond_a

    if-nez v6, :cond_a

    .line 56
    check-cast v4, Landroid/os/Bundle;

    .line 57
    const-string v1, "androidx.credentials.provider.extra.CREATE_CREDENTIAL_EXCEPTION_TYPE"

    invoke-virtual {v4, v1}, Landroid/os/Bundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v1

    .line 58
    const-string v2, "androidx.credentials.provider.extra.CREATE_CREDENTIAL_EXCEPTION_MESSAGE"

    invoke-virtual {v4, v2}, Landroid/os/Bundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v2

    .line 59
    if-eqz v1, :cond_9

    invoke-virtual {v1}, Ljava/lang/String;->isEmpty()Z

    move-result v4

    if-eqz v4, :cond_8

    goto :goto_1

    .line 60
    :cond_8
    new-instance v4, Landroid/credentials/GetCredentialException;

    invoke-direct {v4, v1, v2}, Landroid/credentials/GetCredentialException;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    invoke-virtual {v7, v0, v4}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Ljava/io/Serializable;)Landroid/content/Intent;

    .line 61
    aput-object v7, p0, v5

    .line 62
    const-string p0, "Private Google error container adapted for Android 14+"

    invoke-static {v3, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_3

    .line 59
    :cond_9
    :goto_1
    return-void

    .line 55
    :cond_a
    :goto_2
    nop

    .line 67
    :goto_3
    goto :goto_7

    .line 40
    :cond_b
    :goto_4
    return-void

    .line 33
    :cond_c
    :goto_5
    return-void

    .line 30
    :cond_d
    :goto_6
    return-void

    .line 64
    :catch_0
    move-exception p0

    .line 66
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "Private Google result container unavailable: "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    invoke-static {v3, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 68
    :goto_7
    return-void

    .line 25
    :cond_e
    :goto_8
    return-void
.end method
