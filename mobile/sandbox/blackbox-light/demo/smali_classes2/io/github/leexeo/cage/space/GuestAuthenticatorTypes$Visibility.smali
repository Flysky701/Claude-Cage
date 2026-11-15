.class final Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;
.super Ljava/lang/Object;
.source "GuestAuthenticatorTypes.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/GuestAuthenticatorTypes;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Visibility"
.end annotation


# instance fields
.field final allPackages:Z

.field final caller:Landroid/content/pm/PackageInfo;

.field final packages:Ljava/util/Set;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/Set<",
            "Ljava/lang/String;",
            ">;"
        }
    .end annotation
.end field

.field queriesAuthenticators:Z


# direct methods
.method constructor <init>(Landroid/content/Context;Landroid/content/pm/PackageInfo;)V
    .locals 12
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Landroid/content/pm/PackageManager$NameNotFoundException;,
            Ljava/io/IOException;,
            Lorg/xmlpull/v1/XmlPullParserException;
        }
    .end annotation

    .line 104
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 100
    new-instance v0, Ljava/util/HashSet;

    invoke-direct {v0}, Ljava/util/HashSet;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->packages:Ljava/util/Set;

    .line 105
    iput-object p2, p0, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->caller:Landroid/content/pm/PackageInfo;

    .line 106
    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/4 v1, 0x1

    const/4 v2, 0x0

    const/16 v3, 0x1e

    if-lt v0, v3, :cond_1

    iget-object v0, p2, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget v0, v0, Landroid/content/pm/ApplicationInfo;->targetSdkVersion:I

    if-lt v0, v3, :cond_1

    iget-object v0, p2, Landroid/content/pm/PackageInfo;->requestedPermissions:[Ljava/lang/String;

    if-eqz v0, :cond_0

    iget-object v0, p2, Landroid/content/pm/PackageInfo;->requestedPermissions:[Ljava/lang/String;

    .line 107
    invoke-static {v0}, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;

    move-result-object v0

    .line 108
    const-string v3, "android.permission.QUERY_ALL_PACKAGES"

    invoke-interface {v0, v3}, Ljava/util/List;->contains(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_0

    goto :goto_0

    :cond_0
    move v0, v2

    goto :goto_1

    :cond_1
    :goto_0
    move v0, v1

    :goto_1
    iput-boolean v0, p0, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->allPackages:Z

    .line 109
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->allPackages:Z

    if-eqz v0, :cond_2

    return-void

    .line 110
    :cond_2
    invoke-virtual {p1}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object p1

    iget-object p2, p2, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    invoke-virtual {p1, p2}, Landroid/content/pm/PackageManager;->getResourcesForApplication(Landroid/content/pm/ApplicationInfo;)Landroid/content/res/Resources;

    move-result-object p1

    .line 112
    invoke-virtual {p1}, Landroid/content/res/Resources;->getAssets()Landroid/content/res/AssetManager;

    move-result-object p1

    const-string p2, "AndroidManifest.xml"

    invoke-virtual {p1, p2}, Landroid/content/res/AssetManager;->openXmlResourceParser(Ljava/lang/String;)Landroid/content/res/XmlResourceParser;

    move-result-object p1

    .line 113
    move p2, v2

    move v0, p2

    move v3, v0

    move v4, v3

    .line 114
    :goto_2
    :try_start_0
    invoke-interface {p1}, Landroid/content/res/XmlResourceParser;->next()I

    move-result v5

    if-eq v5, v1, :cond_c

    .line 115
    invoke-interface {p1}, Landroid/content/res/XmlResourceParser;->getName()Ljava/lang/String;

    move-result-object v6

    .line 116
    invoke-interface {p1}, Landroid/content/res/XmlResourceParser;->getDepth()I

    move-result v7

    .line 117
    const/4 v8, 0x2

    const/4 v9, 0x3

    if-ne v5, v8, :cond_8

    .line 118
    if-ne v7, v8, :cond_3

    const-string p2, "queries"

    invoke-virtual {p2, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 119
    :cond_3
    if-nez p2, :cond_4

    goto :goto_2

    .line 120
    :cond_4
    const-string v5, "name"

    const-string v8, "http://schemas.android.com/apk/res/android"

    if-ne v7, v9, :cond_5

    :try_start_1
    const-string v10, "package"

    invoke-virtual {v10, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v10

    if-eqz v10, :cond_5

    iget-object v10, p0, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->packages:Ljava/util/Set;

    invoke-interface {p1, v8, v5}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v11

    invoke-interface {v10, v11}, Ljava/util/Set;->add(Ljava/lang/Object;)Z

    .line 121
    :cond_5
    if-ne v7, v9, :cond_6

    const-string v0, "intent"

    invoke-virtual {v0, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    move v3, v2

    move v4, v3

    .line 122
    :cond_6
    if-eqz v0, :cond_b

    const/4 v9, 0x4

    if-ne v7, v9, :cond_b

    .line 123
    const-string v7, "action"

    invoke-virtual {v7, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_7

    const-string v6, "android.accounts.AccountAuthenticator"

    invoke-interface {p1, v8, v5}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v6, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    or-int/2addr v3, v5

    goto :goto_4

    .line 124
    :cond_7
    move v4, v1

    goto :goto_4

    .line 126
    :cond_8
    if-ne v5, v9, :cond_b

    .line 127
    if-eqz p2, :cond_a

    if-eqz v0, :cond_a

    if-ne v7, v9, :cond_a

    .line 128
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->queriesAuthenticators:Z

    if-eqz v3, :cond_9

    if-nez v4, :cond_9

    move v5, v1

    goto :goto_3

    :cond_9
    move v5, v2

    :goto_3
    or-int/2addr v0, v5

    iput-boolean v0, p0, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->queriesAuthenticators:Z
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 129
    move v0, v2

    .line 131
    :cond_a
    if-ne v7, v8, :cond_b

    move p2, v2

    .line 133
    :cond_b
    :goto_4
    goto :goto_2

    .line 134
    :cond_c
    if-eqz p1, :cond_d

    invoke-interface {p1}, Landroid/content/res/XmlResourceParser;->close()V

    .line 135
    :cond_d
    return-void

    .line 112
    :catchall_0
    move-exception p2

    if-eqz p1, :cond_e

    :try_start_2
    invoke-interface {p1}, Landroid/content/res/XmlResourceParser;->close()V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    goto :goto_5

    :catchall_1
    move-exception p1

    invoke-virtual {p2, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_e
    :goto_5
    throw p2
.end method


# virtual methods
.method includes(Landroid/content/pm/ServiceInfo;)Z
    .locals 2

    .line 140
    iget-object v0, p1, Landroid/content/pm/ServiceInfo;->packageName:Ljava/lang/String;

    iget-object v1, p0, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->caller:Landroid/content/pm/PackageInfo;

    iget-object v1, v1, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    iget-boolean v0, p0, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->allPackages:Z

    if-nez v0, :cond_1

    iget-object v0, p0, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->packages:Ljava/util/Set;

    iget-object v1, p1, Landroid/content/pm/ServiceInfo;->packageName:Ljava/lang/String;

    .line 141
    invoke-interface {v0, v1}, Ljava/util/Set;->contains(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    iget-boolean v0, p0, Lio/github/leexeo/cage/space/GuestAuthenticatorTypes$Visibility;->queriesAuthenticators:Z

    if-eqz v0, :cond_0

    iget-boolean p1, p1, Landroid/content/pm/ServiceInfo;->exported:Z

    if-eqz p1, :cond_0

    goto :goto_0

    :cond_0
    const/4 p1, 0x0

    goto :goto_1

    :cond_1
    :goto_0
    const/4 p1, 0x1

    .line 140
    :goto_1
    return p1
.end method
