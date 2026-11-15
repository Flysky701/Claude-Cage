.class public final Lio/github/leexeo/cage/space/GuestAuthenticatorTypes;
.super Ljava/lang/Object;
.source "GuestAuthenticatorTypes.java"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;
    }
.end annotation


# static fields
.field private static final ANDROID:Ljava/lang/String; = "http://schemas.android.com/apk/res/android"

.field private static final AUTH:Ljava/lang/String; = "android.accounts.AccountAuthenticator"

.field private static final ROOT:Ljava/lang/String; = "top.niunaijun.blackbox."


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 25
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static cannotAddAccount(Landroid/content/Context;Ljava/lang/String;)Z
    .locals 1

    const/4 v0, 0x0

    return v0
.end method

.method public static forCaller(II)[Landroid/accounts/AuthenticatorDescription;
    .locals 9

    .line 37
    const-string v0, "get"

    new-instance v1, Ljava/util/LinkedHashMap;

    invoke-direct {v1}, Ljava/util/LinkedHashMap;-><init>()V

    .line 40
    const/4 v2, 0x0

    :try_start_0
    const-string v3, "top.niunaijun.blackbox.core.system.BProcessManagerService"

    invoke-static {v3}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v3

    .line 41
    const-string v4, "findProcessByPid"

    sget-object v5, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v5}, [Ljava/lang/Class;

    move-result-object v5

    invoke-virtual {v3, v4, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v4

    new-array v5, v2, [Ljava/lang/Class;

    .line 42
    invoke-virtual {v3, v0, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v3

    new-array v5, v2, [Ljava/lang/Object;

    const/4 v6, 0x0

    invoke-virtual {v3, v6, v5}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v3

    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p1

    filled-new-array {p1}, [Ljava/lang/Object;

    move-result-object p1

    invoke-virtual {v4, v3, p1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    .line 43
    if-eqz p1, :cond_7

    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v3

    const-string v4, "userId"

    invoke-virtual {v3, v4}, Ljava/lang/Class;->getField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v3

    invoke-virtual {v3, p1}, Ljava/lang/reflect/Field;->getInt(Ljava/lang/Object;)I

    move-result v3

    if-eq v3, p0, :cond_0

    goto/16 :goto_2

    .line 45
    :cond_0
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v3

    const-string v4, "info"

    invoke-virtual {v3, v4}, Ljava/lang/Class;->getField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v3

    invoke-virtual {v3, p1}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Landroid/content/pm/ApplicationInfo;

    .line 46
    const-string v3, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v3}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v3

    const-string v4, "getContext"

    new-array v5, v2, [Ljava/lang/Class;

    invoke-virtual {v3, v4, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v3

    new-array v4, v2, [Ljava/lang/Object;

    invoke-virtual {v3, v6, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Landroid/content/Context;

    .line 47
    const-string v4, "top.niunaijun.blackbox.core.system.pm.BPackageManagerService"

    invoke-static {v4}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v4

    .line 48
    new-array v5, v2, [Ljava/lang/Class;

    invoke-virtual {v4, v0, v5}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    new-array v5, v2, [Ljava/lang/Object;

    invoke-virtual {v0, v6, v5}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    .line 49
    const-string v5, "getPackageInfo"

    const-class v6, Ljava/lang/String;

    sget-object v7, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    sget-object v8, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v6, v7, v8}, [Ljava/lang/Class;

    move-result-object v6

    invoke-virtual {v4, v5, v6}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v5

    iget-object p1, p1, Landroid/content/pm/ApplicationInfo;->packageName:Ljava/lang/String;

    .line 50
    const/16 v6, 0x1000

    invoke-static {v6}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v6

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v7

    filled-new-array {p1, v6, v7}, [Ljava/lang/Object;

    move-result-object p1

    invoke-virtual {v5, v0, p1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Landroid/content/pm/PackageInfo;

    .line 51
    if-eqz p1, :cond_6

    iget-object v5, p1, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    if-nez v5, :cond_1

    goto :goto_1

    .line 52
    :cond_1
    new-instance v5, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;

    invoke-direct {v5, v3, p1}, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;-><init>(Landroid/content/Context;Landroid/content/pm/PackageInfo;)V

    .line 54
    const-string p1, "queryIntentServices"

    const-class v6, Landroid/content/Intent;

    sget-object v7, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    sget-object v8, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v6, v7, v8}, [Ljava/lang/Class;

    move-result-object v6

    invoke-virtual {v4, p1, v6}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p1

    new-instance v4, Landroid/content/Intent;

    const-string v6, "android.accounts.AccountAuthenticator"

    invoke-direct {v4, v6}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V

    .line 55
    const/16 v6, 0x80

    invoke-static {v6}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v6

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p0

    filled-new-array {v4, v6, p0}, [Ljava/lang/Object;

    move-result-object p0

    invoke-virtual {p1, v0, p0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Ljava/util/List;

    .line 56
    invoke-interface {p0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object p0

    :cond_2
    :goto_0
    invoke-interface {p0}, Ljava/util/Iterator;->hasNext()Z

    move-result p1

    if-eqz p1, :cond_5

    invoke-interface {p0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Landroid/content/pm/ResolveInfo;

    .line 57
    iget-object p1, p1, Landroid/content/pm/ResolveInfo;->serviceInfo:Landroid/content/pm/ServiceInfo;

    .line 58
    if-eqz p1, :cond_2

    iget-object v0, p1, Landroid/content/pm/ServiceInfo;->metaData:Landroid/os/Bundle;

    if-eqz v0, :cond_2

    iget-boolean v0, p1, Landroid/content/pm/ServiceInfo;->enabled:Z

    if-eqz v0, :cond_2

    iget-object v0, p1, Landroid/content/pm/ServiceInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget-boolean v0, v0, Landroid/content/pm/ApplicationInfo;->enabled:Z

    if-eqz v0, :cond_2

    .line 59
    invoke-virtual {v5, p1}, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->includes(Landroid/content/pm/ServiceInfo;)Z

    move-result v0

    if-nez v0, :cond_3

    goto :goto_0

    .line 60
    :cond_3
    invoke-static {v3, p1}, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes;->readDescription(Landroid/content/Context;Landroid/content/pm/ServiceInfo;)Landroid/accounts/AuthenticatorDescription;

    move-result-object p1

    .line 61
    if-eqz p1, :cond_4

    iget-object v0, p1, Landroid/accounts/AuthenticatorDescription;->type:Ljava/lang/String;

    invoke-virtual {v1, v0}, Ljava/util/LinkedHashMap;->containsKey(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_4

    .line 62
    iget-object v0, p1, Landroid/accounts/AuthenticatorDescription;->type:Ljava/lang/String;

    invoke-virtual {v1, v0, p1}, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 63
    :cond_4
    goto :goto_0

    .line 67
    :cond_5
    goto :goto_4

    .line 51
    :cond_6
    :goto_1
    new-array p0, v2, [Landroid/accounts/AuthenticatorDescription;

    return-object p0

    .line 44
    :cond_7
    :goto_2
    new-array p0, v2, [Landroid/accounts/AuthenticatorDescription;
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_4
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_3
    .catch Lorg/xmlpull/v1/XmlPullParserException; {:try_start_0 .. :try_end_0} :catch_2
    .catch Landroid/content/pm/PackageManager$NameNotFoundException; {:try_start_0 .. :try_end_0} :catch_1
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    return-object p0

    .line 64
    :catch_0
    move-exception p0

    goto :goto_3

    :catch_1
    move-exception p0

    goto :goto_3

    :catch_2
    move-exception p0

    goto :goto_3

    :catch_3
    move-exception p0

    goto :goto_3

    :catch_4
    move-exception p0

    .line 66
    :goto_3
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "Guest authenticator discovery unavailable: "

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

    const-string p1, "CageSpace"

    invoke-static {p1, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 68
    :goto_4
    invoke-virtual {v1}, Ljava/util/LinkedHashMap;->values()Ljava/util/Collection;

    move-result-object p0

    new-array p1, v2, [Landroid/accounts/AuthenticatorDescription;

    invoke-interface {p0, p1}, Ljava/util/Collection;->toArray([Ljava/lang/Object;)[Ljava/lang/Object;

    move-result-object p0

    check-cast p0, [Landroid/accounts/AuthenticatorDescription;

    return-object p0
.end method

.method private static readDescription(Landroid/content/Context;Landroid/content/pm/ServiceInfo;)Landroid/accounts/AuthenticatorDescription;
    .locals 13

    .line 72
    const-string v0, "accountType"

    const-string v1, "http://schemas.android.com/apk/res/android"

    iget-object v2, p1, Landroid/content/pm/ServiceInfo;->metaData:Landroid/os/Bundle;

    const-string v3, "android.accounts.AccountAuthenticator"

    invoke-virtual {v2, v3}, Landroid/os/Bundle;->getInt(Ljava/lang/String;)I

    move-result v2

    .line 73
    const/4 v3, 0x0

    if-nez v2, :cond_0

    return-object v3

    .line 75
    :cond_0
    :try_start_0
    invoke-virtual {p0}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object p0

    iget-object v4, p1, Landroid/content/pm/ServiceInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    invoke-virtual {p0, v4}, Landroid/content/pm/PackageManager;->getResourcesForApplication(Landroid/content/pm/ApplicationInfo;)Landroid/content/res/Resources;

    move-result-object p0

    .line 76
    invoke-virtual {p0, v2}, Landroid/content/res/Resources;->getXml(I)Landroid/content/res/XmlResourceParser;

    move-result-object v2
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_3
    .catch Lorg/xmlpull/v1/XmlPullParserException; {:try_start_0 .. :try_end_0} :catch_2
    .catch Landroid/content/pm/PackageManager$NameNotFoundException; {:try_start_0 .. :try_end_0} :catch_1
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    .line 77
    :goto_0
    :try_start_1
    invoke-interface {v2}, Landroid/content/res/XmlResourceParser;->next()I

    move-result v4

    const/4 v5, 0x1

    if-eq v4, v5, :cond_9

    .line 78
    invoke-interface {v2}, Landroid/content/res/XmlResourceParser;->getEventType()I

    move-result v4

    const/4 v5, 0x2

    if-eq v4, v5, :cond_1

    goto :goto_0

    .line 79
    :cond_1
    const-string v4, "account-authenticator"

    invoke-interface {v2}, Landroid/content/res/XmlResourceParser;->getName()Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v4, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    if-nez v4, :cond_3

    .line 90
    if-eqz v2, :cond_2

    :try_start_2
    invoke-interface {v2}, Landroid/content/res/XmlResourceParser;->close()V
    :try_end_2
    .catch Ljava/io/IOException; {:try_start_2 .. :try_end_2} :catch_3
    .catch Lorg/xmlpull/v1/XmlPullParserException; {:try_start_2 .. :try_end_2} :catch_2
    .catch Landroid/content/pm/PackageManager$NameNotFoundException; {:try_start_2 .. :try_end_2} :catch_1
    .catch Ljava/lang/RuntimeException; {:try_start_2 .. :try_end_2} :catch_0

    .line 79
    :cond_2
    return-object v3

    .line 80
    :cond_3
    const/4 v4, 0x0

    :try_start_3
    invoke-interface {v2, v1, v0, v4}, Landroid/content/res/XmlResourceParser;->getAttributeResourceValue(Ljava/lang/String;Ljava/lang/String;I)I

    move-result v5

    .line 81
    if-nez v5, :cond_4

    invoke-interface {v2, v1, v0}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    goto :goto_1

    :cond_4
    invoke-virtual {p0, v5}, Landroid/content/res/Resources;->getString(I)Ljava/lang/String;

    move-result-object p0

    :goto_1
    move-object v6, p0

    .line 82
    if-eqz v6, :cond_7

    invoke-virtual {v6}, Ljava/lang/String;->isEmpty()Z

    move-result p0

    if-eqz p0, :cond_5

    goto :goto_2

    .line 83
    :cond_5
    new-instance p0, Landroid/accounts/AuthenticatorDescription;

    iget-object v7, p1, Landroid/content/pm/ServiceInfo;->packageName:Ljava/lang/String;

    const-string p1, "label"

    .line 84
    invoke-interface {v2, v1, p1, v4}, Landroid/content/res/XmlResourceParser;->getAttributeResourceValue(Ljava/lang/String;Ljava/lang/String;I)I

    move-result v8

    const-string p1, "icon"

    .line 85
    invoke-interface {v2, v1, p1, v4}, Landroid/content/res/XmlResourceParser;->getAttributeResourceValue(Ljava/lang/String;Ljava/lang/String;I)I

    move-result v9

    const-string p1, "smallIcon"

    .line 86
    invoke-interface {v2, v1, p1, v4}, Landroid/content/res/XmlResourceParser;->getAttributeResourceValue(Ljava/lang/String;Ljava/lang/String;I)I

    move-result v10

    const-string p1, "accountPreferences"

    .line 87
    invoke-interface {v2, v1, p1, v4}, Landroid/content/res/XmlResourceParser;->getAttributeResourceValue(Ljava/lang/String;Ljava/lang/String;I)I

    move-result v11

    const-string p1, "customTokens"

    .line 88
    invoke-interface {v2, v1, p1, v4}, Landroid/content/res/XmlResourceParser;->getAttributeBooleanValue(Ljava/lang/String;Ljava/lang/String;Z)Z

    move-result v12

    move-object v5, p0

    invoke-direct/range {v5 .. v12}, Landroid/accounts/AuthenticatorDescription;-><init>(Ljava/lang/String;Ljava/lang/String;IIIIZ)V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 90
    if-eqz v2, :cond_6

    :try_start_4
    invoke-interface {v2}, Landroid/content/res/XmlResourceParser;->close()V

    .line 83
    :cond_6
    return-object p0

    .line 90
    :cond_7
    :goto_2
    if-eqz v2, :cond_8

    invoke-interface {v2}, Landroid/content/res/XmlResourceParser;->close()V

    .line 82
    :cond_8
    return-object v3

    .line 90
    :cond_9
    if-eqz v2, :cond_a

    invoke-interface {v2}, Landroid/content/res/XmlResourceParser;->close()V
    :try_end_4
    .catch Ljava/io/IOException; {:try_start_4 .. :try_end_4} :catch_3
    .catch Lorg/xmlpull/v1/XmlPullParserException; {:try_start_4 .. :try_end_4} :catch_2
    .catch Landroid/content/pm/PackageManager$NameNotFoundException; {:try_start_4 .. :try_end_4} :catch_1
    .catch Ljava/lang/RuntimeException; {:try_start_4 .. :try_end_4} :catch_0

    .line 93
    :cond_a
    goto :goto_5

    .line 76
    :catchall_0
    move-exception p0

    if-eqz v2, :cond_b

    :try_start_5
    invoke-interface {v2}, Landroid/content/res/XmlResourceParser;->close()V
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_1

    goto :goto_3

    :catchall_1
    move-exception p1

    :try_start_6
    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_b
    :goto_3
    throw p0
    :try_end_6
    .catch Ljava/io/IOException; {:try_start_6 .. :try_end_6} :catch_3
    .catch Lorg/xmlpull/v1/XmlPullParserException; {:try_start_6 .. :try_end_6} :catch_2
    .catch Landroid/content/pm/PackageManager$NameNotFoundException; {:try_start_6 .. :try_end_6} :catch_1
    .catch Ljava/lang/RuntimeException; {:try_start_6 .. :try_end_6} :catch_0

    .line 91
    :catch_0
    move-exception p0

    goto :goto_4

    :catch_1
    move-exception p0

    goto :goto_4

    :catch_2
    move-exception p0

    goto :goto_4

    :catch_3
    move-exception p0

    .line 92
    :goto_4
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "Unreadable guest authenticator metadata: "

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

    const-string p1, "CageSpace"

    invoke-static {p1, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 94
    :goto_5
    return-object v3
.end method
