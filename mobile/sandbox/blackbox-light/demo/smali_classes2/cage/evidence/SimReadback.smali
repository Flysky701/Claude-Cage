.class public final Lcage/evidence/SimReadback;
.super Ljava/lang/Object;
.source "SimReadback.java"


# static fields
.field private static final EXPECTED:[Ljava/lang/String;


# direct methods
.method static constructor <clinit>()V
    .locals 13

    .line 12
    const-string v11, "6cf3b57c284e9f940c1eb91e96c4d04b6ba1b17c27a6a9c940f260078b6910d5"

    const-string v12, "853eee3d6b83195333086a6ddf84ec95e58923b1ba1e7aa7c6694a2b2ee0e3dd"

    const-string v0, "e9b4f7063afb3a5a78a4a6f9c22c1dff0344e1547b6464f431f2c7cb37a82963"

    const-string v1, "9eda28fbc9d00b7f0109f264df8a152467e5280c0243103937bcd6ce8e9e4db2"

    const-string v2, "7092e91b07abdbbd53b972d2005f36d49508006c4faf977a228c8a9033aec00e"

    const-string v3, "944d775500429d1102bd2e44a3cd92046971c8e8cfb345dc90b5d4e7f1543921"

    const-string v4, "1d5af230dd780ada98e374713eaeaa704b038c91fe0273c0ee45071aeae2e4de"

    const-string v5, "3f98e94c3bd7c80bc73914beed3067762d379900a6f46d33c5f54b927275703b"

    const-string v6, "cfd26758fb841cfc0c35d9d32f75662b67181423a8e717b578581ba368cd49a8"

    const-string v7, "1f718dcbf9be90ba45864ea307ac9c7c186ac42f2d3f82650c01238664c0c6bd"

    const-string v8, "d176c47ba718a5d6797099948bc833dc997c4ddc806e0916ee7acda72ae0cc2f"

    const-string v9, "f22c9f08f2f1ff655131ba80b891af32ffd95383fe16c1e788b958892c1e7276"

    const-string v10, "69a32eba9752c8989f680cd949ea3b1844eaa527d91a223c81afc6c7b6ddff41"

    filled-new-array/range {v0 .. v12}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lcage/evidence/SimReadback;->EXPECTED:[Ljava/lang/String;

    return-void
.end method

.method public constructor <init>()V
    .locals 0

    .line 11
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method private static inspect(Landroid/view/View;)Z
    .locals 13
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 36
    instance-of v0, p0, Landroid/widget/TextView;

    const/4 v1, 0x1

    const/4 v2, 0x0

    if-eqz v0, :cond_8

    .line 37
    check-cast p0, Landroid/widget/TextView;

    invoke-virtual {p0}, Landroid/widget/TextView;->getText()Ljava/lang/CharSequence;

    move-result-object p0

    invoke-interface {p0}, Ljava/lang/CharSequence;->toString()Ljava/lang/String;

    move-result-object p0

    .line 38
    const-string v0, "\u9ed8\u8ba4 SIM \u00b7 "

    invoke-virtual {p0, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_7

    const-string v0, "\n\u6d3b\u52a8\u8ba2\u9605 \u00b7 "

    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result v0

    if-nez v0, :cond_0

    goto/16 :goto_6

    .line 39
    :cond_0
    const-string v0, "\n"

    invoke-virtual {p0, v0}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object p0

    .line 40
    array-length v0, p0

    sget-object v3, Lcage/evidence/SimReadback;->EXPECTED:[Ljava/lang/String;

    array-length v3, v3

    if-eq v0, v3, :cond_1

    return v2

    .line 41
    :cond_1
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    .line 42
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    .line 43
    nop

    .line 44
    const-string v4, "unclassified"

    move v5, v2

    :goto_0
    array-length v6, p0

    if-ge v5, v6, :cond_6

    .line 45
    const-string v6, "SHA-256"

    invoke-static {v6}, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;

    move-result-object v6

    new-instance v7, Ljava/lang/StringBuilder;

    invoke-direct {v7}, Ljava/lang/StringBuilder;-><init>()V

    const-string v8, "c367429511c5ffe019e3eea4238155fe72d5fd646a510f36"

    invoke-virtual {v7, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v7

    aget-object v8, p0, v5

    invoke-virtual {v7, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v7

    invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v7

    sget-object v8, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-virtual {v7, v8}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object v7

    invoke-virtual {v6, v7}, Ljava/security/MessageDigest;->digest([B)[B

    move-result-object v6

    .line 46
    new-instance v7, Ljava/lang/StringBuilder;

    invoke-direct {v7}, Ljava/lang/StringBuilder;-><init>()V

    .line 47
    array-length v8, v6

    move v9, v2

    :goto_1
    if-ge v9, v8, :cond_2

    aget-byte v10, v6, v9

    sget-object v11, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    and-int/lit16 v10, v10, 0xff

    invoke-static {v10}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v10

    filled-new-array {v10}, [Ljava/lang/Object;

    move-result-object v10

    const-string v12, "%02x"

    invoke-static {v11, v12, v10}, Ljava/lang/String;->format(Ljava/util/Locale;Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/String;

    move-result-object v10

    invoke-virtual {v7, v10}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    add-int/lit8 v9, v9, 0x1

    goto :goto_1

    .line 48
    :cond_2
    sget-object v6, Lcage/evidence/SimReadback;->EXPECTED:[Ljava/lang/String;

    aget-object v6, v6, v5

    invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v7

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_3

    const/16 v6, 0x31

    goto :goto_2

    :cond_3
    const/16 v6, 0x30

    :goto_2
    invoke-virtual {v0, v6}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 49
    aget-object v6, p0, v5

    aget-object v7, p0, v5

    const-string v8, " \u00b7 "

    invoke-virtual {v7, v8}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result v7

    const/4 v8, 0x3

    add-int/2addr v7, v8

    invoke-virtual {v6, v7}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v6

    .line 50
    if-ne v5, v1, :cond_4

    const-string v7, "[0-9]+\uff1a(\u5c31\u7eea|\u65e0\u5361|\u672a\u77e5|\u6743\u9650\u53d7\u9650|\u7cfb\u7edf\u72b6\u6001 [0-9]+|\u7cfb\u7edf\u672a\u8fd4\u56de|\u7cfb\u7edf\u4e0d\u652f\u6301\u6216\u6682\u65f6\u4e0d\u53ef\u7528)(\uff0c[0-9]+\uff1a(\u5c31\u7eea|\u65e0\u5361|\u672a\u77e5|\u6743\u9650\u53d7\u9650|\u7cfb\u7edf\u72b6\u6001 [0-9]+|\u7cfb\u7edf\u672a\u8fd4\u56de|\u7cfb\u7edf\u4e0d\u652f\u6301\u6216\u6682\u65f6\u4e0d\u53ef\u7528))*"

    invoke-virtual {v6, v7}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v7

    if-eqz v7, :cond_4

    .line 51
    move-object v4, v6

    .line 53
    :cond_4
    invoke-virtual {v6}, Ljava/lang/String;->hashCode()I

    move-result v7

    sparse-switch v7, :sswitch_data_0

    :cond_5
    goto :goto_3

    :sswitch_0
    const-string v7, "\u7cfb\u7edf\u4e0d\u652f\u6301\u6216\u6682\u65f6\u4e0d\u53ef\u7528"

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_5

    const/4 v8, 0x6

    goto :goto_4

    :sswitch_1
    const-string v7, "\u8ba2\u9605\u670d\u52a1\u4e0d\u53ef\u7528"

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_5

    const/4 v8, 0x7

    goto :goto_4

    :sswitch_2
    const-string v7, "\u6743\u9650\u53d7\u9650"

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_5

    const/4 v8, 0x4

    goto :goto_4

    :sswitch_3
    const-string v7, "\u7cfb\u7edf\u672a\u8fd4\u56de"

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_5

    const/4 v8, 0x5

    goto :goto_4

    :sswitch_4
    const-string v7, "\u65e0\u5361"

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_5

    move v8, v2

    goto :goto_4

    :sswitch_5
    const-string v7, "0 \u9879"

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_5

    goto :goto_4

    :sswitch_6
    const-string v7, "\u65e0\u6709\u6548\u8ba2\u9605"

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_5

    const/4 v8, 0x2

    goto :goto_4

    :sswitch_7
    const-string v7, "0 \u4e2a\u6d3b\u52a8\u5361\u69fd"

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_5

    move v8, v1

    goto :goto_4

    :goto_3
    const/4 v8, -0x1

    :goto_4
    packed-switch v8, :pswitch_data_0

    .line 58
    const/16 v6, 0x56

    invoke-virtual {v3, v6}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    goto :goto_5

    .line 57
    :pswitch_0
    const/16 v6, 0x55

    invoke-virtual {v3, v6}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    goto :goto_5

    .line 56
    :pswitch_1
    const/16 v6, 0x4e

    invoke-virtual {v3, v6}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    goto :goto_5

    .line 55
    :pswitch_2
    const/16 v6, 0x44

    invoke-virtual {v3, v6}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    goto :goto_5

    .line 54
    :pswitch_3
    const/16 v6, 0x45

    invoke-virtual {v3, v6}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 44
    :goto_5
    add-int/lit8 v5, v5, 0x1

    goto/16 :goto_0

    .line 61
    :cond_6
    new-instance p0, Ljava/lang/StringBuilder;

    invoke-direct {p0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "hostMatches="

    invoke-virtual {p0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, " states="

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, " slots="

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    const-string v0, "CageSimReadback"

    invoke-static {v0, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 62
    return v1

    .line 38
    :cond_7
    :goto_6
    return v2

    .line 64
    :cond_8
    instance-of v0, p0, Landroid/view/ViewGroup;

    if-eqz v0, :cond_a

    .line 65
    check-cast p0, Landroid/view/ViewGroup;

    .line 66
    move v0, v2

    :goto_7
    invoke-virtual {p0}, Landroid/view/ViewGroup;->getChildCount()I

    move-result v3

    if-ge v0, v3, :cond_a

    invoke-virtual {p0, v0}, Landroid/view/ViewGroup;->getChildAt(I)Landroid/view/View;

    move-result-object v3

    invoke-static {v3}, Lcage/evidence/SimReadback;->inspect(Landroid/view/View;)Z

    move-result v3

    if-eqz v3, :cond_9

    return v1

    :cond_9
    add-int/lit8 v0, v0, 0x1

    goto :goto_7

    .line 68
    :cond_a
    return v2

    nop

    :sswitch_data_0
    .sparse-switch
        -0x5dd8967d -> :sswitch_7
        -0x340187de -> :sswitch_6
        0x15089 -> :sswitch_5
        0xca981 -> :sswitch_4
        0x1c74ae70 -> :sswitch_3
        0x312fad86 -> :sswitch_2
        0x4e3e836f -> :sswitch_1
        0x7124cfd7 -> :sswitch_0
    .end sparse-switch

    :pswitch_data_0
    .packed-switch 0x0
        :pswitch_3
        :pswitch_3
        :pswitch_3
        :pswitch_3
        :pswitch_2
        :pswitch_1
        :pswitch_0
        :pswitch_0
    .end packed-switch
.end method

.method public static observe(Landroid/app/Activity;)V
    .locals 6

    .line 14
    const-string v0, "CageRegionReadback"

    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/Class;->getName()Ljava/lang/String;

    move-result-object v1

    const-string v2, "io.github.leexeo.cage.sandbox.SandboxActivity"

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_0

    return-void

    .line 16
    :cond_0
    :try_start_0
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v1

    const-string v2, "snapshot"

    const/4 v3, 0x0

    new-array v4, v3, [Ljava/lang/Class;

    invoke-virtual {v1, v2, v4}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    .line 17
    const/4 v2, 0x1

    invoke-virtual {v1, v2}, Ljava/lang/reflect/Method;->setAccessible(Z)V

    .line 18
    new-array v2, v3, [Ljava/lang/Object;

    invoke-virtual {v1, p0, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Ljava/lang/String;

    .line 19
    const-string v2, "\n"

    invoke-virtual {v1, v2}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object v1

    array-length v2, v1

    :goto_0
    if-ge v3, v2, :cond_3

    aget-object v4, v1, v3

    .line 20
    const-string v5, "\u7cfb\u7edf\u8bed\u8a00 \u00b7 "

    invoke-virtual {v4, v5}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v5

    if-nez v5, :cond_1

    const-string v5, "\u65f6\u533a \u00b7 "

    invoke-virtual {v4, v5}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v5

    if-nez v5, :cond_1

    const-string v5, "\u5f53\u524d\u7f51\u7edc \u00b7 "

    invoke-virtual {v4, v5}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v5

    if-eqz v5, :cond_2

    .line 21
    :cond_1
    invoke-static {v0, v4}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 19
    :cond_2
    add-int/lit8 v3, v3, 0x1

    goto :goto_0

    .line 24
    :cond_3
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "offsetMinutes="

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    .line 25
    invoke-static {}, Ljava/util/TimeZone;->getDefault()Ljava/util/TimeZone;

    move-result-object v2

    invoke-static {}, Ljava/lang/System;->currentTimeMillis()J

    move-result-wide v3

    invoke-virtual {v2, v3, v4}, Ljava/util/TimeZone;->getOffset(J)I

    move-result v2

    const v3, 0xea60

    div-int/2addr v2, v3

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    .line 24
    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_1
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    .line 28
    goto :goto_2

    .line 26
    :catch_0
    move-exception v1

    goto :goto_1

    :catch_1
    move-exception v1

    .line 27
    :goto_1
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "unavailable: "

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 30
    :goto_2
    :try_start_1
    invoke-virtual {p0}, Landroid/app/Activity;->getWindow()Landroid/view/Window;

    move-result-object p0

    invoke-virtual {p0}, Landroid/view/Window;->getDecorView()Landroid/view/View;

    move-result-object p0

    invoke-static {p0}, Lcage/evidence/SimReadback;->inspect(Landroid/view/View;)Z
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_2

    .line 33
    goto :goto_3

    .line 31
    :catch_2
    move-exception p0

    .line 32
    const-string p0, "CageSimReadback"

    const-string v0, "readback unavailable"

    invoke-static {p0, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 34
    :goto_3
    return-void
.end method
