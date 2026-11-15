.class final Lio/github/leexeo/cage/space/SpacePackages;
.super Ljava/lang/Object;
.source "SpacePackages.java"


# static fields
.field static final CLAUDE:Ljava/lang/String; = "com.anthropic.claude"

.field static final DEMO_SPACE:Ljava/lang/String; = "top.niunaijun.microdem"

.field static final FRAMEWORK:Ljava/lang/String; = "com.google.android.gsf"

.field static final GOOGLE:[Ljava/lang/String;

.field static final MICROG:[Ljava/lang/String;

.field private static final MICROG_SIGNER:Ljava/lang/String; = "9bd06727e62796c0130eb6dab39b73157451582cbd138e86c468acc395d14165"

.field static final MICROG_SPACE:Ljava/lang/String; = "top.niunaijun.microbox"

.field private static final ROOT:Ljava/lang/String; = "top.niunaijun.blackbox."

.field static final SERVICES:Ljava/lang/String; = "com.google.android.gms"

.field static final STORE:Ljava/lang/String; = "com.android.vending"

.field private static final USER:I


# instance fields
.field private final api:Ljava/lang/Class;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/lang/Class<",
            "*>;"
        }
    .end annotation
.end field

.field private final context:Landroid/content/Context;

.field private final core:Ljava/lang/Object;

.field private final service:Ljava/lang/Object;


# direct methods
.method static constructor <clinit>()V
    .locals 3

    .line 25
    const-string v0, "com.google.android.gsf"

    const-string v1, "com.google.android.gms"

    const-string v2, "com.android.vending"

    filled-new-array {v0, v1, v2}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lio/github/leexeo/cage/space/SpacePackages;->GOOGLE:[Ljava/lang/String;

    .line 26
    filled-new-array {v1, v2}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lio/github/leexeo/cage/space/SpacePackages;->MICROG:[Ljava/lang/String;

    return-void
.end method

.method constructor <init>(Landroid/content/Context;)V
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 39
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 40
    iput-object p1, p0, Lio/github/leexeo/cage/space/SpacePackages;->context:Landroid/content/Context;

    .line 41
    const-string p1, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {p1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p1

    .line 42
    const/4 v0, 0x0

    new-array v1, v0, [Ljava/lang/Class;

    const-string v2, "get"

    invoke-virtual {p1, v2, v1}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v2, v0, [Ljava/lang/Object;

    const/4 v3, 0x0

    invoke-virtual {v1, v3, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    iput-object v1, p0, Lio/github/leexeo/cage/space/SpacePackages;->core:Ljava/lang/Object;

    .line 43
    const-string v1, "getBPackageManager"

    new-array v2, v0, [Ljava/lang/Class;

    invoke-virtual {p1, v1, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p1

    new-array v1, v0, [Ljava/lang/Object;

    invoke-virtual {p1, v3, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    .line 44
    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v1

    const-string v2, "getService"

    new-array v3, v0, [Ljava/lang/Class;

    invoke-virtual {v1, v2, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v0, v0, [Ljava/lang/Object;

    invoke-virtual {v1, p1, v0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    iput-object p1, p0, Lio/github/leexeo/cage/space/SpacePackages;->service:Ljava/lang/Object;

    .line 45
    iget-object p1, p0, Lio/github/leexeo/cage/space/SpacePackages;->service:Ljava/lang/Object;

    if-eqz p1, :cond_0

    .line 47
    const-string p1, "top.niunaijun.blackbox.core.system.pm.IBPackageManagerService"

    invoke-static {p1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object p1

    iput-object p1, p0, Lio/github/leexeo/cage/space/SpacePackages;->api:Ljava/lang/Class;

    .line 48
    return-void

    .line 45
    :cond_0
    new-instance p1, Ljava/io/IOException;

    const-string v0, "\u7a7a\u95f4\u670d\u52a1\u6b63\u5728\u542f\u52a8\uff0c\u8bf7\u91cd\u8bd5\u3002"

    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

.method static google(Ljava/lang/String;)Z
    .locals 1

    .line 65
    const-string v0, "com.google.android.gsf"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, "com.google.android.gms"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, "com.android.vending"

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    goto :goto_0

    :cond_0
    const/4 p0, 0x0

    goto :goto_1

    :cond_1
    :goto_0
    const/4 p0, 0x1

    :goto_1
    return p0
.end method

.method static inspect(Landroid/content/Context;Ljava/io/File;)Landroid/content/pm/PackageInfo;
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 80
    invoke-virtual {p0}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object v0

    invoke-virtual {p1}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v1

    .line 81
    nop

    .line 80
    const/high16 v2, 0x8000000

    invoke-virtual {v0, v1, v2}, Landroid/content/pm/PackageManager;->getPackageArchiveInfo(Ljava/lang/String;I)Landroid/content/pm/PackageInfo;

    move-result-object v0

    .line 82
    invoke-static {p0}, Lio/github/leexeo/cage/space/SpacePackages;->microG(Landroid/content/Context;)Z

    move-result v1

    .line 83
    const-string v2, "com.google.android.gms"

    if-eqz v1, :cond_1

    if-eqz v0, :cond_0

    iget-object v3, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-nez v3, :cond_1

    const-string v3, "com.android.vending"

    iget-object v4, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v3, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_0

    goto :goto_0

    .line 84
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u8bf7\u9009\u62e9\u4e0a\u6e38 microG Services \u6216 Google \u7b7e\u540d\u7684\u539f\u7248 Play \u5546\u5e97\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 85
    :cond_1
    :goto_0
    if-eqz v0, :cond_d

    iget-object v3, v0, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    if-eqz v3, :cond_d

    iget-object v3, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-static {v3}, Lio/github/leexeo/cage/space/SpacePackages;->google(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_d

    .line 87
    iget-object v3, v0, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget v3, v3, Landroid/content/pm/ApplicationInfo;->minSdkVersion:I

    sget v4, Landroid/os/Build$VERSION;->SDK_INT:I

    if-gt v3, v4, :cond_c

    .line 89
    iget-object v3, v0, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget-object v4, v0, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    invoke-virtual {p1}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object p1

    iput-object p1, v4, Landroid/content/pm/ApplicationInfo;->publicSourceDir:Ljava/lang/String;

    iput-object p1, v3, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    .line 90
    invoke-virtual {p0}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object p0

    iget-object p1, v0, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    invoke-virtual {p0, p1}, Landroid/content/pm/PackageManager;->getResourcesForApplication(Landroid/content/pm/ApplicationInfo;)Landroid/content/res/Resources;

    move-result-object p0

    .line 91
    invoke-virtual {p0}, Landroid/content/res/Resources;->getAssets()Landroid/content/res/AssetManager;

    move-result-object p0

    const-string p1, "AndroidManifest.xml"

    invoke-virtual {p0, p1}, Landroid/content/res/AssetManager;->openXmlResourceParser(Ljava/lang/String;)Landroid/content/res/XmlResourceParser;

    move-result-object p0

    .line 92
    :try_start_0
    const-string p1, "http://schemas.android.com/apk/res/android"

    .line 93
    :goto_1
    invoke-interface {p0}, Landroid/content/res/XmlResourceParser;->next()I

    move-result v3

    const/4 v4, 0x0

    const/4 v5, 0x1

    if-eq v3, v5, :cond_5

    .line 94
    const/4 v6, 0x2

    if-eq v3, v6, :cond_2

    goto :goto_1

    .line 95
    :cond_2
    invoke-interface {p0}, Landroid/content/res/XmlResourceParser;->getDepth()I

    move-result v3

    if-ne v3, v5, :cond_3

    const-string v3, "split"

    invoke-interface {p0, v4, v3}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    if-nez v3, :cond_4

    :cond_3
    const-string v3, "isSplitRequired"

    .line 96
    const/4 v4, 0x0

    invoke-interface {p0, p1, v3, v4}, Landroid/content/res/XmlResourceParser;->getAttributeBooleanValue(Ljava/lang/String;Ljava/lang/String;Z)Z

    move-result v3

    if-nez v3, :cond_4

    const-string v3, "requiredSplitTypes"

    .line 97
    invoke-interface {p0, p1, v3}, Landroid/content/res/XmlResourceParser;->getAttributeValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    if-nez v3, :cond_4

    const-string v3, "uses-split"

    .line 98
    invoke-interface {p0}, Landroid/content/res/XmlResourceParser;->getName()Ljava/lang/String;

    move-result-object v4

    invoke-virtual {v3, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-nez v3, :cond_4

    goto :goto_1

    .line 99
    :cond_4
    new-instance p1, Ljava/io/IOException;

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    iget-object v0, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-static {v0}, Lio/github/leexeo/cage/space/SpacePackages;->label(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, " \u662f\u5206\u62c6\u5b89\u88c5\u5305\uff0c\u8bf7\u9009\u62e9\u540c\u7248\u672c\u7684\u5b8c\u6574 APK\u3002"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-direct {p1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 101
    :cond_5
    if-eqz p0, :cond_6

    invoke-interface {p0}, Landroid/content/res/XmlResourceParser;->close()V

    .line 104
    :cond_6
    nop

    .line 105
    iget-object p0, v0, Landroid/content/pm/PackageInfo;->signingInfo:Landroid/content/pm/SigningInfo;

    if-eqz p0, :cond_8

    iget-object p0, v0, Landroid/content/pm/PackageInfo;->signingInfo:Landroid/content/pm/SigningInfo;

    invoke-virtual {p0}, Landroid/content/pm/SigningInfo;->hasMultipleSigners()Z

    move-result p0

    if-eqz p0, :cond_7

    goto :goto_2

    .line 106
    :cond_7
    iget-object p0, v0, Landroid/content/pm/PackageInfo;->signingInfo:Landroid/content/pm/SigningInfo;

    invoke-virtual {p0}, Landroid/content/pm/SigningInfo;->getSigningCertificateHistory()[Landroid/content/pm/Signature;

    move-result-object v4

    goto :goto_3

    :cond_8
    :goto_2
    nop

    .line 110
    :goto_3
    iget-object p0, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-static {p0, v4, v1}, Lio/github/leexeo/cage/space/SpacePackages;->trusted(Ljava/lang/String;[Landroid/content/pm/Signature;Z)Z

    move-result p0

    if-nez p0, :cond_a

    .line 111
    if-eqz v1, :cond_9

    iget-object p0, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v2, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_9

    .line 112
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u6b64\u7a7a\u95f4\u9700\u8981 microG \u5b98\u65b9\u53d1\u5e03\u7684 Services \u5b89\u88c5\u5305\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 113
    :cond_9
    new-instance p0, Ljava/io/IOException;

    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    iget-object v0, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-static {v0}, Lio/github/leexeo/cage/space/SpacePackages;->label(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v0, " \u7684 Google \u7b7e\u540d\u672a\u901a\u8fc7\u9a8c\u8bc1\u3002"

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 115
    :cond_a
    return-object v0

    .line 90
    :catchall_0
    move-exception p1

    if-eqz p0, :cond_b

    :try_start_1
    invoke-interface {p0}, Landroid/content/res/XmlResourceParser;->close()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    goto :goto_4

    :catchall_1
    move-exception p0

    invoke-virtual {p1, p0}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_b
    :goto_4
    throw p1

    .line 88
    :cond_c
    new-instance p0, Ljava/io/IOException;

    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    iget-object v0, v0, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-static {v0}, Lio/github/leexeo/cage/space/SpacePackages;->label(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v0, " \u9700\u8981\u66f4\u9ad8\u7684 Android \u7248\u672c\u3002"

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 86
    :cond_d
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u8bf7\u9009\u62e9 Google \u670d\u52a1\u6846\u67b6\u3001Play \u670d\u52a1\u6216 Play \u5546\u5e97\u7684\u5b8c\u6574 APK\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static label(Ljava/lang/String;)Ljava/lang/String;
    .locals 1

    .line 56
    invoke-virtual {p0}, Ljava/lang/String;->hashCode()I

    move-result v0

    sparse-switch v0, :sswitch_data_0

    :cond_0
    goto :goto_0

    :sswitch_0
    const-string v0, "com.google.android.gsf"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    const/4 p0, 0x0

    goto :goto_1

    :sswitch_1
    const-string v0, "com.google.android.gms"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    const/4 p0, 0x1

    goto :goto_1

    :sswitch_2
    const-string v0, "com.android.vending"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    const/4 p0, 0x2

    goto :goto_1

    :goto_0
    const/4 p0, -0x1

    :goto_1
    packed-switch p0, :pswitch_data_0

    .line 60
    const-string p0, "Claude"

    return-object p0

    .line 59
    :pswitch_0
    const-string p0, "Play \u5546\u5e97"

    return-object p0

    .line 58
    :pswitch_1
    const-string p0, "Google Play \u670d\u52a1"

    return-object p0

    .line 57
    :pswitch_2
    const-string p0, "Google \u670d\u52a1\u6846\u67b6"

    return-object p0

    :sswitch_data_0
    .sparse-switch
        -0x3e676dcf -> :sswitch_2
        0x136ddda6 -> :sswitch_1
        0x136dde53 -> :sswitch_0
    .end sparse-switch

    :pswitch_data_0
    .packed-switch 0x0
        :pswitch_2
        :pswitch_1
        :pswitch_0
    .end packed-switch
.end method

.method static microG(Landroid/content/Context;)Z
    .locals 2

    .line 30
    const-string v0, "top.niunaijun.microbox"

    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, "top.niunaijun.microdem"

    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    goto :goto_0

    :cond_0
    const/4 p0, 0x0

    goto :goto_1

    :cond_1
    :goto_0
    const/4 p0, 0x1

    :goto_1
    return p0
.end method

.method private static trusted(Ljava/lang/String;[Landroid/content/pm/Signature;Z)Z
    .locals 11
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 119
    invoke-static {p0}, Lio/github/leexeo/cage/space/SpacePackages;->google(Ljava/lang/String;)Z

    move-result v0

    const/4 v1, 0x0

    if-eqz v0, :cond_6

    if-nez p1, :cond_0

    goto/16 :goto_3

    .line 120
    :cond_0
    const-string v0, "SHA-256"

    invoke-static {v0}, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;

    move-result-object v0

    .line 121
    array-length v2, p1

    move v3, v1

    :goto_0
    if-ge v3, v2, :cond_5

    aget-object v4, p1, v3

    .line 122
    new-instance v5, Ljava/lang/StringBuilder;

    const/16 v6, 0x40

    invoke-direct {v5, v6}, Ljava/lang/StringBuilder;-><init>(I)V

    .line 123
    invoke-virtual {v4}, Landroid/content/pm/Signature;->toByteArray()[B

    move-result-object v4

    invoke-virtual {v0, v4}, Ljava/security/MessageDigest;->digest([B)[B

    move-result-object v4

    array-length v6, v4

    move v7, v1

    :goto_1
    if-ge v7, v6, :cond_1

    aget-byte v8, v4, v7

    .line 124
    shr-int/lit8 v9, v8, 0x4

    and-int/lit8 v9, v9, 0xf

    const/16 v10, 0x10

    invoke-static {v9, v10}, Ljava/lang/Character;->forDigit(II)C

    move-result v9

    invoke-virtual {v5, v9}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    move-result-object v9

    and-int/lit8 v8, v8, 0xf

    invoke-static {v8, v10}, Ljava/lang/Character;->forDigit(II)C

    move-result v8

    invoke-virtual {v9, v8}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 123
    add-int/lit8 v7, v7, 0x1

    goto :goto_1

    .line 126
    :cond_1
    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v4

    .line 127
    const-string v5, "com.google.android.gms"

    const/4 v6, 0x1

    if-eqz p2, :cond_2

    invoke-virtual {v5, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v7

    if-eqz v7, :cond_2

    .line 128
    const-string v5, "9bd06727e62796c0130eb6dab39b73157451582cbd138e86c468acc395d14165"

    invoke-virtual {v5, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_3

    return v6

    .line 132
    :cond_2
    const-string v7, "f0fd6c5b410f25cb25c3b53346c8972fae30f8ee7411df910480ad6b2d60db83"

    invoke-virtual {v4, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v7

    if-nez v7, :cond_4

    .line 133
    const-string v7, "7ce83c1b71f3d572fed04c8d40c5cb10ff75e6d87d9df6fbd53f0468c2905053"

    invoke-virtual {v4, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v7

    if-nez v7, :cond_4

    .line 134
    invoke-virtual {v5, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_3

    const-string v5, "5f2391277b1dbd489000467e4c2fa6af802430080457dce2f618992e9dfb5402"

    invoke-virtual {v4, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_3

    goto :goto_2

    .line 121
    :cond_3
    add-int/lit8 v3, v3, 0x1

    goto :goto_0

    .line 134
    :cond_4
    :goto_2
    return v6

    .line 136
    :cond_5
    return v1

    .line 119
    :cond_6
    :goto_3
    return v1
.end method

.method static version(Landroid/content/pm/PackageInfo;)J
    .locals 2

    .line 69
    invoke-virtual {p0}, Landroid/content/pm/PackageInfo;->getLongVersionCode()J

    move-result-wide v0

    return-wide v0
.end method


# virtual methods
.method install(Ljava/io/File;Landroid/content/pm/PackageInfo;)V
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 140
    iget-object v0, p2, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/space/SpacePackages;->installed(Ljava/lang/String;)Landroid/content/pm/PackageInfo;

    move-result-object v0

    .line 141
    if-eqz v0, :cond_1

    invoke-static {v0}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v1

    invoke-static {p2}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v3

    cmp-long v1, v1, v3

    if-gtz v1, :cond_0

    goto :goto_0

    .line 142
    :cond_0
    new-instance p1, Ljava/io/IOException;

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    iget-object p2, p2, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-static {p2}, Lio/github/leexeo/cage/space/SpacePackages;->label(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p2

    invoke-virtual {v0, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    const-string v0, " \u5df2\u6709\u66f4\u9ad8\u7248\u672c\u3002"

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    invoke-direct {p1, p2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1

    .line 143
    :cond_1
    :goto_0
    if-eqz v0, :cond_3

    invoke-static {v0}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v1

    invoke-static {p2}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v3

    cmp-long v1, v1, v3

    if-nez v1, :cond_3

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/space/SpacePackages;->privateCopy(Landroid/content/pm/PackageInfo;)Z

    move-result v1

    if-eqz v1, :cond_3

    .line 145
    :try_start_0
    iget-object v1, p0, Lio/github/leexeo/cage/space/SpacePackages;->context:Landroid/content/Context;

    new-instance v2, Ljava/io/File;

    iget-object v0, v0, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget-object v0, v0, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    invoke-direct {v2, v0}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-static {v1, v2}, Lio/github/leexeo/cage/space/SpacePackages;->inspect(Landroid/content/Context;Ljava/io/File;)Landroid/content/pm/PackageInfo;

    move-result-object v0

    invoke-static {v0}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v0

    invoke-static {p2}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v2
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    cmp-long v0, v0, v2

    if-nez v0, :cond_2

    return-void

    .line 146
    :catch_0
    move-exception v0

    :cond_2
    nop

    .line 150
    :cond_3
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpacePackages;->core:Ljava/lang/Object;

    invoke-virtual {v0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v0

    const-class v1, Landroid/net/Uri;

    sget-object v2, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v1, v2}, [Ljava/lang/Class;

    move-result-object v1

    const-string v2, "installPackageAsUser"

    invoke-virtual {v0, v2, v1}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    iget-object v1, p0, Lio/github/leexeo/cage/space/SpacePackages;->core:Ljava/lang/Object;

    .line 151
    invoke-static {p1}, Landroid/net/Uri;->fromFile(Ljava/io/File;)Landroid/net/Uri;

    move-result-object p1

    const/4 v2, 0x0

    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    filled-new-array {p1, v2}, [Ljava/lang/Object;

    move-result-object p1

    invoke-virtual {v0, v1, p1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    .line 152
    iget-object v0, p2, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/space/SpacePackages;->installed(Ljava/lang/String;)Landroid/content/pm/PackageInfo;

    move-result-object v0

    .line 153
    if-eqz p1, :cond_4

    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v1

    const-string v2, "success"

    invoke-virtual {v1, v2}, Ljava/lang/Class;->getField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v1

    invoke-virtual {v1, p1}, Ljava/lang/reflect/Field;->getBoolean(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_4

    .line 154
    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/space/SpacePackages;->privateCopy(Landroid/content/pm/PackageInfo;)Z

    move-result p1

    if-eqz p1, :cond_4

    invoke-static {v0}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v0

    invoke-static {p2}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v2

    cmp-long p1, v0, v2

    if-nez p1, :cond_4

    .line 156
    return-void

    .line 155
    :cond_4
    new-instance p1, Ljava/io/IOException;

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    iget-object p2, p2, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-static {p2}, Lio/github/leexeo/cage/space/SpacePackages;->label(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p2

    invoke-virtual {v0, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    const-string v0, " \u672a\u5b8c\u6210\u5b89\u88c5\uff0c\u8bf7\u91cd\u8bd5\u3002"

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    invoke-direct {p1, p2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

.method installed(Ljava/lang/String;)Landroid/content/pm/PackageInfo;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 51
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpacePackages;->api:Ljava/lang/Class;

    const-class v1, Ljava/lang/String;

    sget-object v2, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    sget-object v3, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v1, v2, v3}, [Ljava/lang/Class;

    move-result-object v1

    const-string v2, "getPackageInfo"

    invoke-virtual {v0, v2, v1}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    iget-object v1, p0, Lio/github/leexeo/cage/space/SpacePackages;->service:Ljava/lang/Object;

    .line 52
    const/4 v2, 0x0

    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    filled-new-array {p1, v2, v2}, [Ljava/lang/Object;

    move-result-object p1

    invoke-virtual {v0, v1, p1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Landroid/content/pm/PackageInfo;

    .line 51
    return-object p1
.end method

.method open(Ljava/lang/String;Z)Z
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 159
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpacePackages;->context:Landroid/content/Context;

    invoke-virtual {v0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v0

    const-string v1, "top.niunaijun.microdem"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    const/4 v1, 0x0

    if-eqz v0, :cond_0

    const-string v0, "com.anthropic.claude"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_0

    .line 160
    const-string v0, "io.github.leexeo.cage.space.GuestSplits"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    const-class v2, Landroid/content/Context;

    filled-new-array {v2}, [Ljava/lang/Class;

    move-result-object v2

    const-string v3, "verify"

    invoke-virtual {v0, v3, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    iget-object v2, p0, Lio/github/leexeo/cage/space/SpacePackages;->context:Landroid/content/Context;

    filled-new-array {v2}, [Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {v0, v1, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 162
    :cond_0
    const-string v0, "com.google.android.gms"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_1

    iget-object v0, p0, Lio/github/leexeo/cage/space/SpacePackages;->context:Landroid/content/Context;

    invoke-static {v0}, Lio/github/leexeo/cage/space/SpacePackages;->microG(Landroid/content/Context;)Z

    move-result v0

    if-eqz v0, :cond_1

    .line 163
    new-instance v0, Landroid/content/Intent;

    const-string v2, "android.intent.action.APPLICATION_PREFERENCES"

    invoke-direct {v0, v2}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V

    const-string v2, "android.intent.category.DEFAULT"

    invoke-virtual {v0, v2}, Landroid/content/Intent;->addCategory(Ljava/lang/String;)Landroid/content/Intent;

    move-result-object v0

    goto :goto_1

    .line 165
    :cond_1
    if-eqz p2, :cond_2

    new-instance v0, Landroid/content/Intent;

    const-string v2, "market://details?id=com.anthropic.claude"

    invoke-static {v2}, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;

    move-result-object v2

    const-string v3, "android.intent.action.VIEW"

    invoke-direct {v0, v3, v2}, Landroid/content/Intent;-><init>(Ljava/lang/String;Landroid/net/Uri;)V

    goto :goto_0

    .line 166
    :cond_2
    new-instance v0, Landroid/content/Intent;

    const-string v2, "android.intent.action.MAIN"

    invoke-direct {v0, v2}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V

    const-string v2, "android.intent.category.LAUNCHER"

    invoke-virtual {v0, v2}, Landroid/content/Intent;->addCategory(Ljava/lang/String;)Landroid/content/Intent;

    move-result-object v0

    :goto_0
    nop

    .line 168
    :goto_1
    invoke-virtual {v0, p1}, Landroid/content/Intent;->setPackage(Ljava/lang/String;)Landroid/content/Intent;

    .line 171
    iget-object v2, p0, Lio/github/leexeo/cage/space/SpacePackages;->api:Ljava/lang/Class;

    const-class v3, Landroid/content/Intent;

    sget-object v4, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    const-class v5, Ljava/lang/String;

    sget-object v6, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v3, v4, v5, v6}, [Ljava/lang/Class;

    move-result-object v3

    const-string v4, "queryIntentActivities"

    invoke-virtual {v2, v4, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    iget-object v3, p0, Lio/github/leexeo/cage/space/SpacePackages;->service:Ljava/lang/Object;

    .line 173
    const/4 v4, 0x0

    if-eqz p2, :cond_3

    const/high16 p2, 0x10000

    goto :goto_2

    :cond_3
    move p2, v4

    :goto_2
    invoke-static {p2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p2

    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v5

    filled-new-array {v0, p2, v1, v5}, [Ljava/lang/Object;

    move-result-object p2

    .line 172
    invoke-virtual {v2, v3, p2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p2

    check-cast p2, Ljava/util/List;

    .line 174
    if-eqz p2, :cond_6

    invoke-interface {p2}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v1

    :cond_4
    :goto_3
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :cond_6

    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Landroid/content/pm/ResolveInfo;

    .line 175
    iget-object v3, v2, Landroid/content/pm/ResolveInfo;->activityInfo:Landroid/content/pm/ActivityInfo;

    if-eqz v3, :cond_4

    iget-object v3, v2, Landroid/content/pm/ResolveInfo;->activityInfo:Landroid/content/pm/ActivityInfo;

    iget-object v3, v3, Landroid/content/pm/ActivityInfo;->packageName:Ljava/lang/String;

    invoke-virtual {p1, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_4

    iget-object v3, v2, Landroid/content/pm/ResolveInfo;->activityInfo:Landroid/content/pm/ActivityInfo;

    iget-boolean v3, v3, Landroid/content/pm/ActivityInfo;->exported:Z

    if-eqz v3, :cond_4

    iget-object v3, v2, Landroid/content/pm/ResolveInfo;->activityInfo:Landroid/content/pm/ActivityInfo;

    iget-boolean v3, v3, Landroid/content/pm/ActivityInfo;->enabled:Z

    if-nez v3, :cond_5

    .line 176
    goto :goto_3

    .line 177
    :cond_5
    new-instance p2, Landroid/content/ComponentName;

    iget-object v1, v2, Landroid/content/pm/ResolveInfo;->activityInfo:Landroid/content/pm/ActivityInfo;

    iget-object v1, v1, Landroid/content/pm/ActivityInfo;->name:Ljava/lang/String;

    invoke-direct {p2, p1, v1}, Landroid/content/ComponentName;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    invoke-virtual {v0, p2}, Landroid/content/Intent;->setComponent(Landroid/content/ComponentName;)Landroid/content/Intent;

    move-result-object p1

    const/high16 p2, 0x10000000

    invoke-virtual {p1, p2}, Landroid/content/Intent;->addFlags(I)Landroid/content/Intent;

    .line 178
    iget-object p1, p0, Lio/github/leexeo/cage/space/SpacePackages;->core:Ljava/lang/Object;

    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object p1

    const-class p2, Landroid/content/Intent;

    sget-object v1, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {p2, v1}, [Ljava/lang/Class;

    move-result-object p2

    const-string v1, "startActivity"

    invoke-virtual {p1, v1, p2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p1

    iget-object p2, p0, Lio/github/leexeo/cage/space/SpacePackages;->core:Ljava/lang/Object;

    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    filled-new-array {v0, v1}, [Ljava/lang/Object;

    move-result-object v0

    invoke-virtual {p1, p2, v0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 179
    const/4 p1, 0x1

    return p1

    .line 181
    :cond_6
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "No eligible guest activity for "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v0, ", matches="

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    if-nez p2, :cond_7

    move p2, v4

    goto :goto_4

    :cond_7
    invoke-interface {p2}, Ljava/util/List;->size()I

    move-result p2

    :goto_4
    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string p2, "CageSpace"

    invoke-static {p2, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 182
    return v4
.end method

.method privateCopy(Landroid/content/pm/PackageInfo;)Z
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 73
    const/4 v0, 0x0

    if-eqz p1, :cond_2

    iget-object v1, p1, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    if-eqz v1, :cond_2

    iget-object v1, p1, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget-object v1, v1, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    if-nez v1, :cond_0

    goto :goto_0

    .line 74
    :cond_0
    new-instance v1, Ljava/io/File;

    iget-object v2, p1, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget-object v2, v2, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    invoke-direct {v1, v2}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/io/File;->getCanonicalFile()Ljava/io/File;

    move-result-object v1

    .line 75
    new-instance v2, Ljava/io/File;

    iget-object v3, p0, Lio/github/leexeo/cage/space/SpacePackages;->context:Landroid/content/Context;

    invoke-virtual {v3}, Landroid/content/Context;->getDataDir()Ljava/io/File;

    move-result-object v3

    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    const-string v5, "blackbox/data/app/"

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    iget-object p1, p1, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    invoke-virtual {v4, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v4, "/base.apk"

    invoke-virtual {p1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {v2, v3, p1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    .line 76
    invoke-virtual {v2}, Ljava/io/File;->getCanonicalFile()Ljava/io/File;

    move-result-object p1

    invoke-virtual {v1, p1}, Ljava/io/File;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_1

    invoke-virtual {v1}, Ljava/io/File;->isFile()Z

    move-result p1

    if-eqz p1, :cond_1

    const/4 v0, 0x1

    :cond_1
    return v0

    .line 73
    :cond_2
    :goto_0
    return v0
.end method
